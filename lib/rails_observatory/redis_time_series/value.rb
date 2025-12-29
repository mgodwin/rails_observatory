module RailsObservatory
  class RedisTimeSeries
    class Value
      attr_reader :name, :labels, :value

      def initialize(labels:, value:)
        @labels = labels
        @name = labels['name']
        @value = value
      end

      def pretty_print(pp)
        pp.object_address_group(self) do
          pp.breakable
          pp.text "@name="
          pp.pp name

          pp.breakable
          pp.text "@labels="
          pp.nest(2) do
            pp.breakable
            pp.pp labels
          end

          pp.breakable
          pp.text "@value="
          pp.pp value
        end
      end
    end
  end
end
