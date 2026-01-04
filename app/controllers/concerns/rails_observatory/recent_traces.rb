module RailsObservatory
  module RecentTraces
    extend ActiveSupport::Concern

    PER_PAGE = 20

    private

    def load_recent_traces(trace_class)
      @page = [params[:page].to_i, 1].max
      @per_page = PER_PAGE
      query = trace_class.all.where(time: 1.hour.ago..)
      @total_count = query.count
      @total_pages = (@total_count.to_f / @per_page).ceil
      @total_pages = 1 if @total_pages < 1
      @traces = query.offset((@page - 1) * @per_page).limit(@per_page)
    end
  end
end
