module Org
  class Position
    attr_accessor :value
    attr_reader :buffer

    def initialize(buffer, value)
      @buffer = buffer
      @value = value
    end

    def <=>(other)
      to_i <=> other.to_i
    end

    def +(other)
      to_i + other.to_i
    end

    def -(other)
      to_i - other.to_i
    end

    def to_i
      @value
    end

    def to_s
      "BufferPosition[#{value}]"
    end
  end
end
