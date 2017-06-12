module Org
  class Object # :nodoc:
    attr_reader :file, :beginning, :ending

    def initialize(file, beginning, ending)
      @file = file
      @beginning = file.position(beginning)
      @ending = file.position(ending)
    end

    def string
      file.buffer.substring(beginning, ending)
    end

    def string=(string)
      file.buffer.replace(beginning, ending, string)
    end
  end
end
