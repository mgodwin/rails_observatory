module RailsObservatory
  class MailersController < ApplicationController

    before_action :set_duration
    def index

      @time_range = (duration.seconds.ago..)

      @count_series = MailerTimeSeries.where(name: 'count').slice(@time_range).downsample(buckets_for_chart, using: :sum)
      @by_mailer_action = MailerTimeSeries.where(name: 'count', mailer_action: '*').slice(@time_range).downsample(1, using: :sum).select(&:value).sort_by(&:value)

      @events = MailersStream.all.lazy.select { _1.type == 'deliver.action_mailer' }.take(25)
    end

    def show
      @mailer_event = MailersStream.find_by_id(params[:id])
      @mail = Mail.new(@mailer_event.payload[:mail])
    end
  end
end
