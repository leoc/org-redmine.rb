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
      pos = pos.to_i
      pre = string[0...pos]
      post = string[pos...string.length]
      @string = pre + str + post
      offset_positions(pos, str.length)
    end

    def delete(pos1, pos2)
      pos1, pos2 = pos1.to_i, pos2.to_i
      deletable_string = string[pos1...pos2]
      string[pos1...pos2] = ''
      remove_positions(pos1, pos2)
      offset_positions(pos2, pos1 - pos2)
      deletable_string
    end

    def replace(pos1, pos2, str)
      pos1, pos2 = pos1.to_i, pos2.to_i
      string[pos1...pos2] = str
      remove_positions(pos1, pos2)
      offset_positions(pos2, str.length - (pos2 - pos1))
    end

    def substring(pos1, pos2)
      pos1, pos2 = pos1.to_i, pos2.to_i
      string.slice(pos1...pos2)
    end

    def move(pos1, pos2, new_pos)
      pos1, pos2, new_pos = pos1.to_i, pos2.to_i, new_pos.to_i
      return if pos2 == new_pos
      movable_string = string[pos1...pos2]
      string[pos1...pos2] = ''
      new_pos -= pos2 - pos1 if pos2 < new_pos
      string[new_pos, 0] = movable_string
      move_positions(pos1, pos2, new_pos)
    end

    private

    def find_position(position)
      found_at = positions.find_index { |pos| pos.value == position }
      positions[found_at] if found_at
    end

    def move_positions(pos1, pos2, new_pos)
      movable_positions = positions.select { |pos| pos1 <= pos.value && pos.value < pos2}
      remove_positions(pos1, pos2)
      offset_positions(pos2, pos1 - pos2)
      offset_positions(new_pos, (pos2 - pos1))
      movable_positions.each do |pos|
        pos.value = (pos.value - pos1) + new_pos
        reinsert_position(pos)
      end
    end

    def insert_position(new_position)
      insert_at = positions.index { |pos| pos.value > new_position }
      new_position = Position.new(self, new_position)
      positions.insert(insert_at || positions.length, new_position)
      new_position
    end

    def reinsert_position(position)
      insert_at = positions.index { |pos| pos.value > position.to_i }
      positions.insert(insert_at || positions.length, position)
      position
    end

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
