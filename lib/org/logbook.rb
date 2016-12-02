require 'org/object'

module Org
  class Logbook < Org::Object # :nodoc:
    def clocked_time(options = {})
      options = options.merge(offset: beginning, limit: ending)
      time = 0
      clock = file.find_clock(options)
      while clock
        time += clock.time
        clock = file.find_clock(options.merge(offset: clock.ending))
      end
      time
    end

    def headline
      file.find_headline(offset: beginning, reverse: true)
    end

    def ancestor_if(&block)
      file.find_ancestor_if(offset: beginning, &block)
    end
  end
end
