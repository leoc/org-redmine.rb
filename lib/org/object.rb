module Org
  class Object # :nodoc:
    attr_reader :file, :beginning, :ending

    def initialize(file, beginning, ending)
      @file = file
      @beginning = beginning
      @ending = ending
    end

    def string
      file[beginning...ending]
    end

    def string=(string)
      @file.replace(beginning, ending, string)
      @ending = beginning + string.length
    end
  end
end
