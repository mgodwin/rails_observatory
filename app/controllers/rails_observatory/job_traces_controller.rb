module RailsObservatory
  class JobTracesController < ApplicationController
    include RecentTraces

    layout "rails_observatory/traces/job", only: :show

    def recent
      load_recent_traces(JobTrace)
      render partial: "rails_observatory/job_traces/recent_traces_page", layout: false
    end

    def index
    end

    def show
      @trace = JobTrace.find(params[:id])
      @events = @trace.events
      @event = params[:event] ? @events.find(params[:event]) : @events.first
    end

    def filter_params
      params.slice(:event, :sort).permit!
    end
    helper_method :filter_params

    def current_tab
      params[:tab].presence_in(%w[overview events logs mail jobs errors]) || "overview"
    end
    helper_method :current_tab
  end
end
