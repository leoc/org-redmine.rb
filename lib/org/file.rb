require 'org/headline'
require 'org/properties'
require 'org/property'
require 'org/logbook'
require 'org/clock'

module Org
  class File # :nodoc:
    extend Forwardable
    attr_accessor :filename, :redmine_trackers
    attr_reader :buffer

    def_delegators :@buffer, :insert, :delete, :replace, :length, :slice, :position

    def initialize(filename)
      @filename = filename
      @buffer = Org::Buffer.new(::File.read(::File.expand_path(filename)))

      load_redmine_tracker_associations
    end

    def load_redmine_tracker_associations
      @redmine_trackers = {}
      beginning = buffer.index(/^#\+ORG_REDMINE_TRACKERS:/)
      return unless beginning
      ending = buffer.index("\n", beginning)
      value = buffer[beginning + '#+ORG_REDMINE_TRACKERS:'.length ... ending].strip
      value.split(' ').each do |pair|
        tag, id = pair.split(':')
        @redmine_trackers[nil] = id.to_i if tag[0] == '!'
        @redmine_trackers[tag.gsub(/^!/, '')] = id.to_i
      end
    end

    def save
      ::File.open(filename, 'w') do |file|
        file.write(@buffer.string)
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

    def headlines(with: {})
      headlines = []
      headline = find_headline(with: with)
      while headline
        block_match = true
        block_match = yield(headline) if block_given?
        tags_match = true
        tags_match = headline.tags?(with[:tags]) if with[:tags]

        headlines.push(headline) if block_match && tags_match

        headline = find_headline(offset: headline.ending, with: with)
      end
      headlines
    end

    def find_headline(options = {})
      options = options.pick(:level, :offset, :limit, :reverse, :with)
      regexp = Org::Headline.finder_regexp(options)
      beginning = scan(regexp, options)
      return unless beginning
      ending = scan("\n", offset: beginning)
      Org::Headline.new(self, beginning, ending || file.length)
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

    def find_version_headline(id, options = {})
      version_id_pos = scan(":redmine_version_id: #{id}", options)
      return if version_id_pos.nil?
      options = options.merge(
        offset: version_id_pos,
        reverse: true
      )
      find_headline(options)
    end
    alias_method :find_version, :find_version_headline

    def find_project_headline(id, options = {})
      project_id_pos = scan(":redmine_project_id: #{id}", options)
      return if project_id_pos.nil?
      options = options.merge(
        offset: project_id_pos,
        reverse: true
      )
      find_headline(options)
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

    def scan(obj, options = {})
      if options[:reverse]
        scan_backward(obj, options)
      else
        scan_forward(obj, options)
      end
    end

    def scan_forward(obj, options = {})
      offset = options[:offset] || 0
      pos = buffer.index(obj, offset.to_i || 0)
      return if pos && options[:limit] && pos > options[:limit].to_i
      return buffer.length if pos && pos >= buffer.length
      pos
    end

    def scan_backward(obj, options = {})
      offset = options[:offset] || buffer.length
      pos = buffer.rindex(obj, offset.to_i || buffer.length)
      return if pos && options[:limit] && pos < options[:limit].to_i
      return 0 if pos && pos <= 0
      pos
    end
  end
end
