module RailsObservatory
  class LogEvent

    def level
      payload[:level]
    end

    def labels
      { level: }
    end

    def process
      LogTimeSeries.increment('count', labels: labels)
    end

  end
end