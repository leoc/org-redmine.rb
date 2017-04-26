require 'ostruct'

class OrgRedmine
  attr_reader :filename, :file, :redmine_host, :redmine_key, :redmine_user
  attr_reader :trackers

  def initialize(options = {})
    @filename = options[:filename]
    @file = Org::File.new(@filename)

    @redmine_host = options[:redmine_host]
    @redmine_key = options[:redmine_key]
    @redmine_user = options[:redmine_user]

    RedmineApi::Base.configure do |c|
      c.site = @redmine_host
      c.token @redmine_key
    end

    @user = RedmineApi::User.find(:first, params: { login: @redmine_user })
    @project_ids =
      begin
        hash = {}
        RedmineApi::Project.find(:all, params: { limit: 100 }).each do |project|
          hash[project.identifier] = project.id
        end
        hash
      end
    @activity_ids =
      begin
        hash = {}
        RedmineApi::TimeEntryActivity.find(:all, params: { limit: 100 }).each do |activity|
          hash[activity.name] = activity.id
        end
        hash
      end

    trackers = RedmineApi::Tracker.find(:all, params: { limit: 100 })
    @trackers = trackers.map { |t| [t.id.to_i, t] }.to_h
    @tracker_ids = trackers.map { |t| [t.name, t.id.to_i] }.to_h
  end

  def extract_activity(tags)
    ap tags
    tags = tags.select { |tag| tag[0] == '#' }
    tags = %w(#development) if tags.empty?
    keys = @activity_ids.keys
    tags.each do |tag|
      keys.select! do |key|
        key.downcase.include?(tag[1..-1])
      end
    end
    keys.first
  end

  def extract_tracker(tags)
    tag = tags.find { |tag| tag[0] == '@' }
    return 'Task' if tag.nil?
    @tracker_ids.keys.find do |key|
      key.downcase.include?(tag[1..-1])
    end
  end

  def create_new_issues
    headline = file.find_headline(with: { title: /# - .*/ })
    while headline do
      project = headline.ancestor_if(&:redmine_project?)
      parent = headline.ancestor_if(&:redmine_issue?)

      if project.nil?
        puts 'Missing project ancestor for new issue headline:'
        puts headline.string
        exit
      end

      issue = {
        project: project.redmine_project_id,
        tracker: extract_tracker(headline.tags),
        subject: headline.sanitized_title,
        parent_issue: parent&.redmine_issue_id,
        assigned_to: "#{@user.firstname} #{@user.lastname}"
      }

      Formatador.display_table([issue], %i(project tracker subject parent_issue assigned_to))

      exit unless agree('Should this issue be synced to Redmine? [y/n]', true)

      issue = RedmineApi::Issue.create(
        project_id: @project_ids[project.redmine_project_id],
        tracker_id: @tracker_ids[extract_tracker(headline.tags)],
        subject: headline.sanitized_title,
        parent_issue_id: parent&.redmine_issue_id,
        assigned_to_id: @user.id
      )
      if issue.errors.empty?
        headline.redmine_issue_id = issue.id
        file.save
      end

      headline = file.find_headline(offset: headline.ending, with: { title: /# - .*/ })
    end
  end

  def extract_time_entries(date)
    clocks = []
    logbook = file.find_logbook(at: date)
    while logbook
      clock_total = logbook.clocked_time(at: date)

      headline = logbook.headline
      issue = logbook.ancestor_if(&:redmine_issue?)
      project = logbook.ancestor_if(&:redmine_project?)

      tags = headline.tags
      tags = %w(#communication) if headline.sanitized_title =~ /^Appear.in|^Tel|^Skype|^Meeting|^Mail/

      clock = {}
      clock[:spent_on] = date.strftime('%Y-%m-%d')
      clock[:hours] = (clock_total / 60 * 100).ceil / 100.0
      clock[:activity] = extract_activity(tags)
      clock[:project] = project.redmine_project_id if project
      if issue
        clock[:issue_id] = issue.redmine_issue_id
        clock[:issue] = issue.sanitized_title
      end
      if headline == issue
        clock[:comments] = 'see issue'
      else
        clock[:comments] = headline.sanitized_title
      end
      clocks.push(clock)

      logbook = file.find_logbook(offset: logbook.ending, at: date)
    end
    clocks
  end

  def transfer_time_entries(clocks)
    clocks.each do |clock|
      time_entry = RedmineApi::TimeEntry.find(
        :first, params: {
          issue_id: clock[:issue_id],
          user_id: @user.id,
          comments: clock[:comments],
          spent_on: clock[:spent_on]
        }
      )
      if time_entry
        time_entry.hours = clock[:hours]
        time_entry.activity_id = @activity_ids[clock[:activity]]
        time_entry.save
      else
        time_entry = RedmineApi::TimeEntry.create(
          user_id: @user.id,
          issue_id: clock[:issue_id],
          project_id: @project_ids[clock[:project]],
          comments: clock[:comments],
          hours: clock[:hours],
          activity_id: @activity_ids[clock[:activity]],
          spent_on: clock[:spent_on]
        )
        binding.pry unless time_entry.errors.empty?
      end
    end
  end

  def sync_time(date)
    clocks = extract_time_entries(date)
    if clocks.empty?
      puts "No clocks to sync for #{date}..."
      return
    end
    Formatador.
      display_table(clocks, %i(spent_on hours activity project comments issue))
    return unless agree('Should those clocks be synced to Redmine? [y/n]', true)
    transfer_time_entries(clocks)
  end


  def get_local_versions
    versions = []
    headline = file.find_headline(with: { tags: %i(milestone) })
    while headline
      version = {}
      version[:id] = headline.properties[:redmine_version_id].andand.to_i
      version[:name] = headline.sanitized_title
      project = headline.ancestor_if(&:redmine_project?)
      version[:project_id] = @project_ids[project.redmine_project_id] if project&.redmine_project_id
      versions.push(version)
      headline = file.find_headline(offset: headline.ending, with: { tags: %i(milestone) })
    end
    versions
  end

  def get_remote_versions
    file.projects.map do |project|
      RedmineApi::Version
        .project_id(project.redmine_project_id)
        .find_all(params: { limit: 100 })
        .map do |version|
        {
          id: version.id,
          project_id: version.project.id.to_i,
          name: version.name,
          status: version.status,
        }
      end
    end.flatten
  end

  def create_new_versions
    new_local_versions = get_local_versions.select { |v| v[:id].blank? }
    new_local_versions.each do |version|
      created_version =
        RedmineApi::Version
          .project_id(@project_ids.key(version[:project_id]))
          .create(name: version[:name])
      fail created_version.errors unless created_version.errors.empty?

      version_headline = file.find_headlines_with(title: /#{version[:name]}/) do |headline|
        headline.ancestor_if { |h| @project_ids[h.redmine_project_id] == version[:project_id] }
      end.first
      version_headline.properties[:redmine_version_id] = created_version.id
      file.save
    end
  end

  class << self
    def config
      @config ||= OpenStruct.new(
        redmine_host: nil,
        redmine_key: nil,
        filename: nil,
        tags_exclude_from_inheritance: []
      )
    end

    def configure
      yield(config)
    end
  end
end
