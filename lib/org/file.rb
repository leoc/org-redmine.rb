require 'org/headline'
require 'org/properties'
require 'org/property'
require 'org/logbook'
require 'org/clock'

module Org
  class File # :nodoc:
    attr_accessor :filename, :redmine_trackers

    def initialize(filename)
      @filename = filename
      @file = ::File.read(filename)

      load_redmine_tracker_associations
    end

    def load_redmine_tracker_associations
      beginning = @file.index(/^#\+ORG_REDMINE_TRACKERS:/)
      return unless beginning
      ending = @file.index("\n", beginning)
      value = @file[beginning + '#+ORG_REDMINE_TRACKERS:'.length ... ending].strip
      @redmine_trackers = {}
      value.split(" ").each do |pair|
        tag, id = pair.split(':')
        @redmine_trackers[nil] = id.to_i if tag[0] == '!'
        @redmine_trackers[tag.gsub(/^!/, '')] = id.to_i
      end
    end

    def [](*args)
      file[*args]
    end

    def length
      file.length
    end

    def replace(beginning, ending, str)
      pre = file[0...beginning]
      post = file[ending...-1]
      @file = pre + str + post
    end

    def save
      ::File.open(filename, 'w') do |file|
        file.write(@file)
      end
    end

    def each_ancestor(options = {}, &block)
      options = options.pick(:offset, :limit, :level).merge(reverse: true)
      headline = find_headline(options)
      return unless headline
      yield(headline)
      return if headline.level <= 1
      each_ancestor(
        options.merge(
          offset: headline.beginning,
          level: (headline.level - 1)
        ), &block
      )
    end

    def find_ancestor_if(options = {}, &block)
      options = options.pick(:offset, :limit, :level).merge(reverse: true)
      headline = find_headline(options)
      return unless headline
      return headline if yield(headline)
      return if headline.level <= 1
      find_ancestor_if(
        options.merge(
          offset: headline.beginning,
          level: (headline.level - 1)
        ),
        &block
      )
    end

    def find_headlines_with(filters = {})
      headlines = []
      headline = find_headline(with: filters)
      while headline
        block_match = true
        block_match = yield(headline) if block_given?
        tags_match = true
        tags_match = headline.tags?(filters[:tags]) if filters[:tags]

        headlines.push(headline) if block_match && tags_match

        headline = find_headline(offset: headline.contents_ending, with: filters)
      end
      headlines
    end

    def find_headline(options = {})
      options = options.pick(:level, :offset, :limit, :reverse, :with)
      regexp = Org::Headline.finder_regexp(options)
      beginning = scan(regexp, options)
      return unless beginning
      ending = scan("\n", offset: beginning)
      Org::Headline.new(self, beginning, ending)
    end

    def projects
      headlines = []
      headline = find_headline
      while headline
        headlines.push(headline) if headline.redmine_project?
        headline = find_headline(offset: headline.ending)
      end
      headlines
    end

    def find_headline_properties(options = {})
      options = options.pick(:offset, :limit)
      beginning = scan(Org::Properties::OPENING, options)
      return Org::Properties.new(self, options[:offset], options[:offset]) unless beginning
      ending = scan(Org::Properties::CLOSING, options.merge(offset: beginning))
      return Org::Properties.new(self, options[:offset], options[:offset]) unless ending
      Org::Properties.new(self, beginning, ending + Org::Properties::CLOSING.length)
    end

    def find_property(options = {})
      return if options[:offset] == options[:limit]
      options = options.pick(:offset, :limit)
      beginning = scan(Org::Property::REGEXP, options)
      return unless beginning
      ending = scan(Org::Property::REGEXP, options.merge(offset: (beginning + 1)))
      ending ||= options[:limit]
      return unless ending
      Org::Property.new(self, beginning, ending)
    end

    def find_logbook(options = {})
      if options[:at]
        find_clock(options).andand.logbook
      else
        beginning = scan(':LOGBOOK:', options.pick(:offset, :limit, :reverse))
        return unless beginning
        ending = scan(':END:', options.pick(:limit).merge(offset: beginning))
        Org::Logbook.new(self, beginning, ending)
      end
    end

    def find_clock(options = {})
      options = options.pick(:at, :offset, :limit, :reverse)
      beginning = scan(Clock.finder_regexp(options), options)
      return unless beginning
      ending = scan("\n", options.merge(offset: beginning))
      Org::Clock.new(self, beginning, ending)
    end

    private

    attr_reader :file

    def scan(obj, options = {})
      if options[:reverse]
        scan_backward(obj, options)
      else
        scan_forward(obj, options)
      end
    end

    def scan_forward(obj, options = {})
      offset = options[:offset] || 0
      pos = file.index(obj, offset || 0)
      return if pos && options[:limit] && pos > options[:limit]
      pos
    end

    def scan_backward(obj, options = {})
      offset = options[:offset] || file.length
      pos = file.rindex(obj, offset || file.length)
      return if pos && options[:limit] && pos < options[:limit]
      pos
    end
  end
end
