require 'org/object'

module Org
  class Planning < Org::Object # :nodoc:
    KEYWORDS = %w[SCHEDULED DEADLINE CLOSED].freeze
    REGEX = /(?<keyword>#{KEYWORDS.join('|')}): (?<timestamp>#{Org::TIMESTAMP_REGEX.source})/.freeze
    LINE_REGEX = /\n(#{REGEX.source} ?)+/

    def initialize(file, beginning, ending)
      line = file.buffer.substring(beginning, ending)
      if line.match(LINE_REGEX)
        super(file, beginning, ending)
      else
        super(file, beginning, beginning)
      end
    end

    def [](keyword)
      timestamp = match[keyword]
      return if timestamp.nil?
      Org.timestamp_to_date(timestamp)
    end

    def []=(keyword, new_date)
      raise "Wrong planning keyword: #{keyword}" unless KEYWORDS.include?(keyword)
      timestamp = Org.format_timestamp(new_date)
      update(match.merge(keyword => timestamp))
    end

    private

    def updated_string(hash)
      return '' if hash.compact.empty?
      "\n" +
        hash
          .compact
          .map { |keyword, timestamp| "#{keyword.upcase}: #{timestamp}" }
          .join(' ')
    end

    def update(hash)
      self.string = updated_string(hash)
    end

    def match
      string
        .to_enum(:scan, REGEX)
        .map { |keyword, timestamp, *_| [keyword, timestamp] }
        .to_h
    end
  end
end
