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

      @available_tabs = compute_available_tabs
      redirect_to_overview_if_tab_unavailable
    end

    def filter_params
      params.slice(:event, :sort).permit!
    end
    helper_method :filter_params

    def current_tab
      params[:tab].presence_in(%w[overview events logs mail jobs errors]) || "overview"
    end
    helper_method :current_tab

    private

    def compute_available_tabs
      tabs = %w[overview events logs]
      tabs << "mail" if @trace.mail_events.any?
      tabs << "jobs" if @trace.job_events.any?
      tabs << "errors" if @trace.has_errors?
      tabs
    end

    def redirect_to_overview_if_tab_unavailable
      unless @available_tabs.include?(current_tab)
        redirect_to filter_params.merge(tab: "overview"), status: :see_other
      end
    end
  end
end
