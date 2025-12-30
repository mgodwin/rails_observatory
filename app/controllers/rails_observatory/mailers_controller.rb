module RailsObservatory
  class MailersController < ApplicationController
    layout 'rails_observatory/application_time_slice'

    def index
      MailDelivery.ensure_index
      @time_range = (duration.seconds.ago..)

      # For "By Mailer" table
      @count_by_mailer = RedisTimeSeries.query_value('mailer.delivery_count', :sum)
                                        .where(mailer: true)
                                        .group('mailer')
                                        .select { _1.value > 0 }
                                        .sort_by(&:value)
                                        .reverse

      # Recent deliveries (static, no lazy loading)
      @deliveries = MailDelivery.all.limit(20)
    end
  end
end
