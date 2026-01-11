module RailsObservatory
  class StorageController < ApplicationController
    layout "rails_observatory/application_time_slice"

    def index
      @time_range = (duration.seconds.ago..)

      @upload_count_by_service = RedisTimeSeries.query_value("storage.upload_count", :sum)
        .where(service: true)
        .group("service")
        .select { it.value > 0 }
        .sort_by(&:value)
        .reverse

      @download_count_by_service = RedisTimeSeries.query_value("storage.download_count", :sum)
        .where(service: true)
        .group("service")
        .select { it.value > 0 }
        .sort_by(&:value)
        .reverse

      @delete_count_by_service = RedisTimeSeries.query_value("storage.delete_count", :sum)
        .where(service: true)
        .group("service")
        .select { it.value > 0 }
        .sort_by(&:value)
        .reverse
    end
  end
end
