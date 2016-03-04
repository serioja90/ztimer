
module Ztimer
  class SortedStore

    def initialize
      @store = []
    end

    def <<(value)
      @store.insert(position_for(value), value)
      return self
    end

    def delete(value)
      index = index_of(value)
      if index
        @store.delete_at(index)
      else
        return nil
      end
    end

    def [](index)
      return @store[index]
    end

    def first
      return @store.first
    end

    def last
      return @store.last
    end

    def shift
      return @store.shift
    end

    def pop
      return @store.pop
    end

    def index_of(value, start = 0, stop = [@store.count - 1, 0].max)
      if start > stop
        return nil
      elsif start == stop
        return value == @store[start] ? start : nil
      else
        position = ((stop + start)/ 2).to_i
        case value <=> @store[position]
        when -1 then return index_of(value, start, position - 1)
        when  0 then return position
        when  1 then return index_of(value, position + 1, stop)
        end
      end
    end

    def count
      return @store.count
    end

    def size
      return @store.size
    end

    def empty?
      return @store.empty?
    end

    def clear
      return @store.clear
    end

    def to_a
      return @store.dup
    end


    protected

    def position_for(item, start = 0, stop = [@store.count - 1, 0].max)
      if start > stop
        raise "Invalid range (#{start}, #{stop})"
      elsif start == stop
        element = @store[start]
        return element.nil? || ((item <=> element) <= 0) ? start : start + 1
      else
        position = ((stop + start)/ 2).to_i
        case item <=> @store[position]
        when -1 then return position_for(item, start, position - 1)
        when  0 then return position
        when  1 then return position_for(item, position + 1, stop)
        end
      end
    end
  end
end