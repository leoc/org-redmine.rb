module Org
  class Buffer
    extend Forwardable

    attr_reader(:positions, :string)

    def_delegators :@string, :[], :[]=, :length, :index, :rindex, :slice

    def initialize(string)
      @string = string
      @positions = []
    end

    def position(position)
      find_position(position) || insert_position(position)
    end

    def insert(pos, str)
      pre = string[0...pos]
      post = string[pos...string.length]
      @string = pre + str + post
      offset_positions(pos, str.length)
    end

    def delete(pos1, pos2)
      string[pos1...pos2] = ''
      remove_positions(pos1, pos2)
      offset_positions(pos2, pos1 - pos2)
    end

    def replace(pos1, pos2, str)
      string[pos1...pos2] = str
      remove_positions(pos1, pos2)
      offset_positions(pos2, str.length - (pos2 - pos1))
    end

    def find_position(position)
      found_at = positions.find_index { |pos| pos.value == position }
      positions[found_at] if found_at
    end

    def insert_position(new_position)
      insert_at = positions.index { |pos| pos.value > new_position }
      new_position = Position.new(self, new_position)
      positions.insert(insert_at || positions.length, new_position)
    end

    private

    def remove_positions(lower, upper)
      positions.reject! { |pos| lower <= pos.value && pos.value < upper }
    end

    def offset_positions(anchor, offset)
      positions.map! do |pos|
        pos.value += offset if pos.value >= anchor
        pos
      end
    end
  end
end
