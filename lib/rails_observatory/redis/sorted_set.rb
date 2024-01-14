module RailsObservatory
  class SortedSet

    attr_reader :name
    def redis
      Rails.configuration.rails_observatory.redis
    end

    def initialize(name)
      @name = name
    end

    def add(value, score)
      if value.is_a?(Hash)
        redis.call('ZADD', @name, score, JSON.generate(value))
      else
        redis.call('ZADD', @name, score, value)
      end
    end

    def all
      LimitOffsetEnumerator.new(self)
    end
  end

  class LimitOffsetEnumerator
    include Enumerable
    def initialize(set, &blk)
      @set = set
      @limit = nil
      @offset = nil
      @order = :asc
      @blk = blk
    end

    def limit(limit)
      @limit = limit
      self
    end

    def offset(offset)
      @offset = offset
      self
    end

    def order(order)
      @order = order
      self
    end

    def each
      limit = @limit || -1
      offset = @offset || 0
      order = @order == :desc ? 'REV' : nil
      args = [offset, limit, order].compact
      @set.redis.call('ZRANGE', @set.name, *args, 'WITHSCORES').each do |value, score|
        if @blk
          yield @blk.call(value)
        else
          yield value
        end
      end
    end
  end

end