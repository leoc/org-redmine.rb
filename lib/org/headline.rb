require 'org/object'

module Org
  class Headline < Org::Object # :nodoc:
    TODO_KEYWORDS = %w(TODO NEXT DONE WAITING HOLD SOMEDAY CANCELLED READ FINISHED REJECTED).freeze
    REGEXP = /^(?<stars>\*+) (?<todo>#{TODO_KEYWORDS.join('|')})? ?(?<title>.*?)\s*(\s*:(?<tags>.+):)?$/

    def initialize(file, beginning, ending, options = {})
      super(file, beginning, ending)
      if beginning == ending
        options = { level: 1 }.merge(options)
        todo = options[:todo] ? "#{options[:todo]} " : ''
        tags = options[:tags] ? "  :#{options[:tags].join(':')}:" : ''
        file.insert(beginning, "\n")
        @beginning = beginning + 1
        @ending = beginning + 1
        self.string = "#{'*' * options[:level]} #{todo}#{options[:title]}#{tags}"
      end
    end

    def ==(other)
      return false unless other.is_a?(Org::Headline)
      other.beginning == beginning && other.ending == ending
    end

    def self.finder_regexp(options = {})
      re = REGEXP.source
      case options[:level]
      when Integer then re.gsub!('(?<stars>\*+)', "(\\\*{#{options[:level]}})")
      when Range then re.gsub!('(?<stars>\*+)', "(\\\*{#{options[:level].begin},#{options[:level].end}})")
      end
      if (filters = options[:with])
        re.gsub!("(?<todo>#{TODO_KEYWORDS.join('|')})?", filters[:todo].source) if filters[:todo]
        re.gsub!('(?<title>.*?)', filters[:title].source) if filters[:title]
        re.gsub!('(\s*:(?<tags>.+):)?', "\s*:#{Array(filters[:tags]).join(':')}:") if filters[:tags]
      end
      /#{re}/
    end

    def level
      match[:stars].length
    end

    def match
      match = string.match(REGEXP)
      {
        stars: match[:stars].andand.strip,
        todo: match[:todo].andand.strip,
        title: match[:title].andand.strip,
        tags: Array(match[:tags].andand.strip.andand.split(':'))
      }
    end

    def sanitized_title
      title
        .gsub(/\[\d+-\d+-\d+ ?\w{3}? ?(\d+:\d+)?\]/, '')
        .gsub(/^#(\d+)? - /, '')
        .strip
    end

    def title
      match[:title]
    end

    def title=(new_title)
      new_string = string.gsub(title, new_title)
      self.string = new_string
    end

    def todo
      match[:todo]
    end

    def todo=(new_todo)
      str = string
      if todo
        str[level + 1, todo.length] = new_todo
      else
        str[level + 1, 0] = "#{new_todo} "
      end
      self.string = str
    end

    def direct_tags
      match[:tags]
    end

    def immediate_tags
      match[:tags]
    end

    def inherited_tags
      tags = []
      each_ancestor do |headline|
        tags.concat(headline.direct_tags - OrgRedmine.config.tags_exclude_from_inheritance)
      end
      tags.uniq
    end

    def tags
      (direct_tags + inherited_tags).uniq
    end

    def redmine_issue?
      !match[:title].match(/^#(\d+)? -/).nil?
    end

    def redmine_issue_id
      match[:title].match(/^#(\d+) -/).andand[1].andand.to_i
    end

    def redmine_issue_id=(issue_id)
      new_title = title.gsub(/^#(\d+)? -/, "##{issue_id} -")
      self.title = new_title
    end

    def redmine_project?
      !properties[:redmine_project_id].nil?
    end

    def redmine_project_id
      properties[:redmine_project_id]
    end

    def redmine_version?
      !properties[:redmine_version_id].nil?
    end

    def redmine_version_id
      properties[:redmine_version_id].try(:to_i)
    end

    def redmine_tracker
      tracker_tag = tags.find { |tag| tag[0] == '@' }
      file.redmine_trackers[tracker_tag]
    end

    def redmine_tracker=(tracker)
      tracker_tag =
        if tracker.is_a?(Integer)
          file.redmine_trackers.key(tracker)
        elsif tracker[0] == '@'
          tracker
        else
          "@#{tracker}"
        end
      tags_without_tracker =
        direct_tags.reject { |tag| tag[0] == '@' }
      self.tags = [tracker_tag] + tags_without_tracker
    end

    def tags=(new_tags)
      str = string
      match = str.match(REGEXP)
      new_str = new_tags.map { |t| t.gsub(/[\-]/, ':') }.join(':')
      str[match.begin(:tags)...match.end(:tags)] = new_str
      self.string = str
    end

    def level=(new_level)
      set_level(new_level)
    end

    def set_level(new_level, with_child: true)
      if with_child
        diff = new_level - level
        each_child(any: true) do |child|
          child.set_level(child.level + diff, with_child: false)
        end
      end
      str = string
      match = str.match(REGEXP)
      str[match.begin(:stars)...match.end(:stars)] = '*' * new_level
      self.string = str
    end

    def contents_beginning
      ending
    end

    def contents_ending
      next_headline = file.find_headline(offset: ending)
      if next_headline
        next_headline.beginning - 1
      else
        file.length
      end
    end

    def level_ending
      next_heading =
        file.find_headline(offset: ending, level: (1..level))
      if next_heading
        next_heading.beginning - 1
      else
        file.length
      end
    end

    def contents
      file[contents_beginning + 1...contents_ending]
        .gsub(/:PROPERTIES:.*:END:\n/m, '')
    end

    def tag?(*match_tags)
      options = match_tags.last.is_a?(Hash) ? match_tags.pop : nil
      options ||= { immediate: true, inherited: true }
      current_tags =
        (options[:immediate] ? immediate_tags : []) +
        (options[:inherited] ? inherited_tags : [])
      match_tags = match_tags.flat_map { |tag| Array(tag) }
      current_tags & match_tags == match_tags
    end

    def properties
      file.find_headline_properties(
        offset: contents_beginning,
        limit: contents_ending
      )
    end

    def each_ancestor(&block)
      file.each_ancestor(offset: beginning, level: (level - 1), &block)
    end

    def ancestor_if(&block)
      file.find_ancestor_if(offset: beginning, level: (level - 1), &block)
    end

    def each_child(any: false)
      level = any ? ((self.level + 1)..999) : (self.level + 1)
      limit = level_ending
      child_heading = file.find_headline(offset: ending, limit: limit, level: level)
      while child_heading
        yield(child_heading)
        child_heading = file.find_headline(offset: child_heading.ending, limit: limit, level: level)
      end
    end

    def add_subheadline(options = {}, &block)
      headline = Headline.new(
        file,
        level_ending,
        level_ending,
        options.merge(level: (level + 1))
      )
      yield(headline) if block_given?
    end
  end
end
