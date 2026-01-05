module RailsObservatory
  class MailersController < ApplicationController
    layout "rails_observatory/application_time_slice"

    PER_PAGE = 20

    def index
      MailDelivery.ensure_index
    end

    def recent
      MailDelivery.ensure_index
      @page = [params[:page].to_i, 1].max
      @per_page = PER_PAGE
      query = MailDelivery.all
      @total_count = query.count
      @total_pages = (@total_count.to_f / @per_page).ceil
      @total_pages = 1 if @total_pages < 1
      @deliveries = query.offset((@page - 1) * @per_page).limit(@per_page)
      render partial: "recent_deliveries", layout: false
    end
  end
end
