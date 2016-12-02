require 'org/object'

module Org
  class Property < Org::Object # :nodoc:
    REGEXP = /^:[^:\n]+: +[^\n]+/

    def name
      var_ending = string.index(':', 1)
      string[1...var_ending].strip
    end

    def value
      value_beginning = string.index(':', 1) + 1
      string[value_beginning...-1].strip
    end
  end
end
