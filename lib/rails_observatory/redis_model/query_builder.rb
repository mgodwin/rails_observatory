module RailsObservatory
  class RedisModel
    class QueryBuilder
      include RedisConnection
      include Enumerable

      def initialize(model_class)
        @conditions = {}
        @order = {}
        @limit = 10
        @offset = 0
        @model_class = model_class
      end

      def where(conditions)
        clone = self.clone
        clone.instance_variable_set(:@conditions, @conditions.merge(conditions))
        clone
      end

      def limit(limit)
        clone = self.clone
        clone.instance_variable_set(:@limit, limit)
        clone
      end

      def offset(offset)
        clone = self.clone
        clone.instance_variable_set(:@offset, offset)
        clone
      end

      def order(order)
        clone = self.clone
        clone.instance_variable_set(:@order, @order.merge(order))
        clone
      end

      def count
        total, *_rest = redis.call("FT.SEARCH", @model_class.index_name, *build_query_conditions, "LIMIT", '0', '0')
        total
      end

      def each
        _total, *results = redis.call("FT.SEARCH", @model_class.index_name, *build_query_conditions, "SORTBY", "time", "DESC", "LIMIT", @offset, @limit)
        Hash[*results].values.map(&:last).map { JSON.parse(_1) }.each do
          yield @model_class.new(_1)
        end
      end

      def to_query_a
        ["FT.SEARCH", @model_class.index_name, *build_query_conditions]
      end

      def to_query_s
        ["FT.SEARCH", @model_class.index_name, *build_query_conditions.map { "\"#{_1}\""}]
      end

      private

      def build_query_conditions
        query_conditions = @conditions.map do |field, condition|
          "@#{field}:#{condition_to_s(field, condition)}"
        end
        query_conditions << '*' if query_conditions.empty?
        query_conditions
      end

      def condition_to_s(field, condition)
        if condition.is_a? Range
          range_start = condition.begin.nil? ? '-inf' : type_cast_value(condition.begin, field)
          range_end = condition.end.nil? ? '+inf' : type_cast_value(condition.end, field)
          "[#{range_start} #{range_end}]"
        else
          type_cast_value(condition.to_s, field)
        end
      end

      def type_cast_value(value, field)
        @model_class.attribute_types[field.to_s].cast(value)
      end
    end
  end
end