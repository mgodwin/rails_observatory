module RailsObservatory

  class RedisTimeSeries
    module Insertion

      def distribution(name, value, at: Time.now, labels: {})
        prefixed_name = begin
                          if defined?(self::PREFIX)
                            [self::PREFIX, name].join('.')
                          else
                            name
                          end
                        end
        timestamp = (at.to_f * 1000).to_i
        RedisScripts::Timing.call(prefixed_name, value, timestamp, labels.to_a.flatten.map(&:to_s))
      end
      alias_method :record_timing, :distribution

      def increment(name, at: Time.now, labels: {})

        prefixed_name = begin
                          if defined?(self::PREFIX)
                            [self::PREFIX, name].join('.')
                          else
                            name
                          end
                        end
        timestamp = (at.to_f * 1000).to_i
        RedisScripts::Increment.call(prefixed_name, timestamp, labels.to_a.flatten.map(&:to_s))
      end
      alias_method :record_occurrence, :increment
    end
  end
end