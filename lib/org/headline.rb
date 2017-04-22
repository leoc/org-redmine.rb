require 'org/object'

module Org
  class Headline < Org::Object # :nodoc:
    TODO_KEYWORDS = %w(TODO NEXT DONE WAITING HOLD SOMEDAY CANCELLED READ FINISHED REJECTED).freeze
    REGEXP = /^(?<stars>\*+) (?<todo>#{TODO_KEYWORDS.join('|')})? ?(?<title>.*?)\s*(\s*:(?<tags>.+):)?$/

    def ==(other)
      return false unless other.is_a?(Org::Headline)
      other.beginning == beginning && other.ending == ending
    end

    def self.finder_regexp(options = {})
      re = REGEXP.source
      re.gsub!('(?<stars>\*+)', "(\\\*{#{options[:level]}})") if options[:level]
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
        .gsub(/^#(\d)? - /, '')
        .strip
    end

    def title
      match[:title]
    end

    def title=(new_title)
      new_string = string.gsub(title, new_title)
      self.string = new_string
    end

    def direct_tags
      match[:tags]
    end

    def tags
      tags = direct_tags
      each_ancestor do |headline|
        tags.concat(headline.direct_tags - OrgRedmine.config.tags_exclude_from_inheritance)
      end
      tags.uniq
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

    def redmine_tracker
      tracker_tag = tags.find { |tag| tag[0] == '@' }
      file.redmine_trackers[tracker_tag]
    end

    def contents_beginning
      ending
    end

    def contents_ending
      next_headline = file.find_headline(offset: ending)
      if next_headline
        next_headline.ending
      else
        file.length
      end
    end

    def contents
      file[contents_beginning...contents_ending]
    end

    def tag?(*tags)
      tags = tags.flat_map { |tag| Array(tag) }
      self.tags & tags == tags
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
  end
end
