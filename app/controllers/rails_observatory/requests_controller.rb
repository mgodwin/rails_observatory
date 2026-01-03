module RailsObservatory
  class RequestsController < ApplicationController

    before_action :ensure_indexed, only: :index
    layout 'rails_observatory/application_time_slice'

    def index
      @time_range = (duration.seconds.ago..)

      if params[:controller_action].blank?
        @count_by_controller = RedisTimeSeries.query_value('request.count', :sum)
                                              .where(action: true)
                                              .group('action')
                                              .select { _1.value > 0 }
                                              .sort_by(&:value)
                                              .reverse

        @latency_by_controller = RedisTimeSeries.query_value('request.latency', :avg)
                                                .where(action: true)
                                                .group('action')
                                                .to_a
                                                .index_by { _1.labels['action'] }
      end
    end

    def recent
      @traces = RequestTrace.all.where(time: 5.seconds.ago..).limit(20)
      render partial: 'rails_observatory/requests/recent_requests', layout: false
    end

    private

    def ensure_indexed
      RequestTrace.ensure_index
    end

  end
end
