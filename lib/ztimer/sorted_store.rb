# frozen_string_literal: true

class Ztimer
  # Implements a performant sorted store for time slots, which uses binary search to optimize
  # new items insertion and items retrievement.
  class SortedStore
    def initialize
      @store = []
    end

    def <<(value)
      @store.insert(position_for(value), value)

      self
    end

    def delete(value)
      index = index_of(value)

      index.nil? ? nil : @store.delete_at(index)
    end

    def [](index)
      @store[index]
    end

    def first
      @store.first
    end

    def last
      @store.last
    end

    def shift
      @store.shift
    end

    def pop
      @store.pop
    end

    def index_of(value, start = 0, stop = [@store.count - 1, 0].max)
      return nil if start > stop
      return value == @store[start] ? start : nil if start == stop

      position = ((stop + start) / 2).to_i

      case value <=> @store[position]
      when -1 then index_of(value, start, position)
      when  0 then position
      when  1 then index_of(value, position + 1, stop)
      end
    end

    def count
      @store.count
    end

    def size
      @store.size
    end

    def empty?
      @store.empty?
    end

    def clear
      @store.clear
    end

    def to_a
      @store.dup
    end

    protected

    def position_for(item, start = 0, stop = [@store.count - 1, 0].max)
      raise "Invalid range (#{start}, #{stop})" if start > stop

      if start == stop
        element = @store[start]
        element.nil? || ((item <=> element) <= 0) ? start : start + 1
      else
        position = ((stop + start) / 2).to_i
        case item <=> @store[position]
        when -1 then position_for(item, start, position)
        when  0 then position
        when  1 then position_for(item, position + 1, stop)
        end
      end
    end
  end
end
