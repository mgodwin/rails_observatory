module RailsObservatory

  class RedisTimeSeries
    class Range

      attr_reader :name, :data, :labels, :from, :to, :bin_duration
      alias_method :start_time, :from
      alias_method :end_time, :to

      def initialize(labels:, data:, bin_duration: nil, from: nil, to: nil)
        @labels = labels
        @name = @labels['name']
        @source = @labels['__source__']
        @data = data
        @bin_duration = bin_duration
        # Use provided boundaries, fall back to data boundaries
        @from = from || (data.empty? ? nil : Time.at(data.first[0] / 1000))
        @to = to || (data.empty? ? nil : Time.at(data.last[0] / 1000))
      end

      def filled_data(bin_duration: @bin_duration)
        return [] if @from.nil? || @to.nil? || bin_duration.nil?

        start_ms = (@from.to_f * 1000).to_i
        end_ms = (@to.to_f * 1000).to_i
        start_bucket = start_ms - (start_ms % bin_duration)

        data_hash = @data.to_h  # Convert to hash for O(1) lookup

        Enumerator
          .produce(start_bucket) { |t| t + bin_duration }
          .take_while { |t| t <= end_ms }
          .map { |t| [t, data_hash[t]&.to_f || 0.0] }
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
          pp.text "@from="
          pp.pp from

          pp.breakable
          pp.text "@to="
          pp.pp to

          pp.breakable
          pp.text "num_data_points="
          pp.pp data.size
        end
      end

    end
  end

end