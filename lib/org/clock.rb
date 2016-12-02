require 'org/object'

module Org
  class Clock < Org::Object # :nodoc:
    REGEXP = /CLOCK:\s+(?<from>\[\d+-\d+-\d+ \w{3} \d+:\d+\])--(?<to>\[\d+-\d+-\d+ \w{3} \d+:\d+\])\s+=>\s+(?<sum>\d+:\d+)/

    def self.finder_regexp(options = {})
      date = options[:at].andand.strftime('%Y-%m-%d') || '\d{4}-\d{2}-\d{2}'
      /CLOCK:\s+\[\d{4}-\d{2}-\d{2} \w{3} \d+:\d+\]--\[#{date} \w{3} \d+:\d+\]/
    end

    def time
      (ends_at.to_time - starts_at.to_time) / 60
    end

    def starts_at
      org_date_to_datetime(match[:from])
    end

    def ends_at
      org_date_to_datetime(match[:to])
    end

    def logbook
      file.find_logbook(offset: beginning, reverse: true)
    end

    def headline
      file.find_headline(offset: beginning, reverse: true)
    end

    private

    def match
      @match ||= string.match(REGEXP)
    end
  end
end
