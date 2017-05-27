require 'ostruct'

class OrgRedmine
  attr_reader :filename, :file, :redmine_host, :redmine_key, :redmine_user
  attr_reader :trackers, :cache

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

    @cache = OrgRedmine::Cache.new("/home/arthur/.org_redmine.cache.json")

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

  def tracker_tag(tracker)
    "@#{tracker.downcase}"
  end

  def clean_issue(issue)
    issue.select do |key, value|
      %i(id version_id project_id tracker_id subject).include?(key)
    end
  end

  def extract_activity(tags)
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
    return 'Bug' if tag.nil?
    @tracker_ids.keys.find do |key|
      key.downcase.include?(tag[1..-1])
    end
  end

  def create_new_issues
    headline = file.find_headline(with: { title: /# - .*/ })
    while headline do
      project = headline.ancestor_if(&:redmine_project?)
      version = headline.ancestor_if(&:redmine_version?)
      parent = headline.ancestor_if(&:redmine_issue?)

      if project.nil?
        puts 'Missing project ancestor for new issue headline:'
        puts headline.string
        exit
      end

      issue = {
        project: project.redmine_project_id,
        tracker: extract_tracker(headline.tags),
        version: version&.sanitized_title || 'n/a',
        subject: headline.sanitized_title,
        parent_issue: parent&.redmine_issue_id,
        assigned_to: "#{@user.firstname} #{@user.lastname}"
      }

      Formatador.display_table([issue], %i(project tracker version subject parent_issue assigned_to))

      exit unless agree('Should this issue be synced to Redmine? [y/n]', true)

      issue = RedmineApi::Issue.create(
        project_id: @project_ids[project.redmine_project_id],
        tracker_id: @tracker_ids[extract_tracker(headline.tags)],
        fixed_version_id: version.andand.redmine_version_id,
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

  def get_local_issues
    issues = []
    headline = file.find_headline(with: { title: /#(\d+) - .*/ })
    while headline
      issue = {}
      issue[:id] = headline.redmine_issue_id if headline.redmine_issue_id
      issue[:subject] = headline.sanitized_title
      issue[:tracker_id] = @tracker_ids[extract_tracker(headline.tags)]

      # TODO: add status_id with proper mapping
      # TODO: add assigned_to_id with proper mapping

      parent = headline.ancestor_if(&:redmine_issue?)
      issue[:parent_issue] = parent.redmine_issue_id if parent&.redmine_issue_id
      project = headline.ancestor_if(&:redmine_project?)
      issue[:project_id] = @project_ids[project.redmine_project_id] if project&.redmine_project_id
      version = headline.ancestor_if(&:redmine_version?)
      issue[:version_id] = version.redmine_version_id.to_i if version&.redmine_version_id
      issues.push(issue)
      headline = file.find_headline(offset: headline.ending, with: { title: /#(\d+) - .*/ })
    end
    issues
  end

  def get_remote_issues(last_sync_at = nil)
    issues = []
    issues_query = RedmineApi::Issue.find(
      :all,
      params: {
        status_id: 'open',
        assigned_to_id: @user.id,
        limit: 100,
        sort: 'id'
      }
    )
    issues.push(*issues_query)
    while issues_query.next_page?
      issues_query = issues_query.next_page
      issues.push(*issues_query)
    end
    issues.map do |issue|
      {
        id: issue.id,
        project_id: issue.project.id.to_i,
        tracker_id: issue.tracker.id.to_i,
        status_id: issue.status.id.to_i,
        subject: issue.subject,
        version_id: issue.try(:fixed_version).andand.id,
        assigned_to_id: issue.try(:assigned_to).id.to_i,
        start_date: issue.try(:start_date),
        due_date: issue.try(:due_date),
        parent_issue: issue.try(:parent)&.id&.to_i
      }
    end
  end

  def sync_issues
    local_issues = get_local_issues.select { |issue| issue[:id].present? }
    ap(local_issues: local_issues)
    ap(remote_issues: get_remote_issues)
    ap(
      local_cache: cache.issues,
      local_issues: local_issues
    )

    cache_issues = cache.issues.map(&method(:clean_issue))
    local_issues_diff = OrgRedmine::Issue.diff_issues(cache_issues, local_issues.map(&method(:clean_issue)))
    remote_issues_diff = OrgRedmine::Issue.diff_issues(cache_issues, get_remote_issues.map(&method(:clean_issue)))
    binding.pry
    ap(local_issues_diff: local_issues_diff)
    ap(remote_issues_diff: remote_issues_diff)

    merged_issues_diff = OrgRedmine::Issue.merge_diff(local_issues_diff, remote_issues_diff).map do |issue|
      issue.map do |key, value|
        if value.is_a?(Array)
          puts "Resolve conflict:"
          Formatador.display_table([{ field: key,
                                      local_value: value[0],
                                      remote_value: value[1]
                                    }],
                                   %i(field local_value remote_value))
          keep = nil
          choose do |menu|
            menu.choice('Keep Local') { keep = 0 }
            menu.choice('Keep Remote') { keep = 1 }
          end
          [key, value[keep]]
        else
          [key, value]
        end
      end.to_h
    end

    # 1. apply merged_diff to local
    merged_issues_diff.each do |issue|
      issue_headline = file.find_headline(with: { title: /##{issue[:id]} - .*/ })
      if issue_headline
        issue_headline.title = "##{issue[:id]} - #{issue[:subject]}" if issue[:subject]
        issue_headline.redmine_tracker = @trackers[issue[:tracker_id]].name.downcase if issue[:tracker_id]
      else
        parent_headline = nil
        parent_headline = file.find_version_headline(issue[:version_id]) if issue[:version_id]
        parent_headline ||= file.find_project_headline(issue[:project_id])

        parent_headline.add_subheadline(title: "##{issue[:id]} - #{issue[:subject]}", todo: 'TODO')
      end
    end
    file.save

    ap(merged_issues_diff: merged_issues_diff)

    # 2. apply merged_diff to remote
    merged_issues_diff.each do |issue|
      redmine_issue =
        RedmineApi::Issue.find(issue[:id])
      redmine_issue.subject = issue[:subject] if issue[:subject]
      redmine_issue.tracker_id = issue[:tracker_id] if issue[:tracker_id]
      redmine_issue.save!
    end

    # 3. apply merged_diff to cache and save cache
    cache.apply_issues_diff(merged_issues_diff)
    cache.save
  end

  def get_local_versions
    versions = []
    headline = file.find_headline(with: { tags: %i(milestone) })
    while headline
      version = {}
      version[:id] = headline.properties[:redmine_version_id].andand.to_i
      version[:name] = headline.sanitized_title
      version[:status] = 'open'
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
      cache.add_version(
        id: created_version.id,
        name: created_version.name,
        project_id: created_version.project.id,
        status: created_version.status
      )
    end
    cache.save
  end

  def sync_versions
    local_versions = get_local_versions.select { |v| v[:id].present? }
    local_versions_diff = OrgRedmine::Issue.diff_issues(cache.versions, local_versions)
    remote_versions_diff = OrgRedmine::Issue.diff_issues(cache.versions, get_remote_versions)

    merged_versions_diff = OrgRedmine::Issue.merge_diff(local_versions_diff, remote_versions_diff).map do |version|
      version.map do |key, value|
        if value.is_a?(Array)
          puts "Resolve conflict:"
          Formatador.display_table([{ field: key,
                                      local_value: value[0],
                                      remote_value: value[1]
                                    }],
                                   %i(field local_value remote_value))
          keep = nil
          choose do |menu|
            menu.choice('Keep Local') { keep = 0 }
            menu.choice('Keep Remote') { keep = 1 }
          end
          [key, value[keep]]
        else
          [key, value]
        end
      end.to_h
    end

    # 1. apply merged_diff to local
    merged_versions_diff.each do |version|
      version_headline = file.find_version(version[:id])
      if version_headline
        version_headline.title = version[:name] if version[:name]
      else
        project_headline = file.find_project_headline(@project_ids.key(version[:project_id]))
        project_headline.add_subheadline(
          title: version[:name],
          todo: 'TODO',
          tags: %i(milestone)
        ) do |headline|
          headline.properties[:redmine_version_id] = version[:id]
        end
      end
    end
    file.save

    # 2. apply merged_diff to remote
    merged_versions_diff.each do |version|
      redmine_version =
        RedmineApi::Version
          .project_id(@project_ids.key(version[:project_id]))
          .find(version[:id])
      redmine_version.name = version[:name] if version[:name]
      redmine_version.save!
    end

    # 3. apply merged_diff to cache and save cache
    cache.apply_versions_diff(merged_versions_diff)
    cache.save
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
