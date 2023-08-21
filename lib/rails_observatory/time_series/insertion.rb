module RailsObservatory
  module TimeSeries::Insertion
    def timing(name, value, labels: {})
      label_combinations(labels).each do |label_slice|
        upsert_ts(name, label_slice, [:avg, :min, :max])
        $redis.call("TS.ADD", ts_key(name, label_slice), "*", value)
      end
    end

    def increment(name, labels: {})
      label_combinations(labels).each do |label_slice|
        upsert_ts(name, label_slice, [:sum])
        $redis.call("TS.INCRBY", ts_key(name, labels), 1)
      end
    end

    private

    def create_compacted_series(name, labels, compaction, retention_sec)
      key = ts_key(name, labels)
      compaction_key = [key, compaction].join('_')
      if $redis.call("EXISTS", compaction_key) == 0
        $redis.call("TS.CREATE", compaction_key, "RETENTION", to_ms(retention_sec), "LABELS", *labels.merge(name: name, type: compaction).entries.flatten)
        $redis.call("TS.CREATERULE", key, compaction_key, "AGGREGATION", compaction.to_s, to_ms(10))
      end
    end

    def upsert_ts(name, labels, compactions)
      key = ts_key(name, labels)
      $redis.call("TS.CREATE", key, "RETENTION", to_ms(10)) if $redis.call("EXISTS", key) == 0
      compactions.each { |compaction| create_compacted_series(name, labels, compaction, 1.year) }
    end

    def ts_key(name, labels)
      [name, *labels.sort.to_h.values].compact.join(':')
    end

    def label_combinations(labels)
      return enum_for(:label_combinations, labels) unless block_given?
      labels.keys.size.times do |n|
        labels.keys.combination(n).each do |label_keys|
          label_slice = labels.slice(*label_keys)
          yield label_slice
        end
      end
    end
  end
end