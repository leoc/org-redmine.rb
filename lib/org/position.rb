module Org
  class Position
    attr_accessor :value

    def initialize(buffer, value)
      @buffer = buffer
      @value = value
    end

    def value=(value)
      @value = value
    end

    def to_i
      @value
    end
  end
end
