module RailsObservatory
  class TracesController < ApplicationController

    layout 'rails_observatory/traces/request', only: :show
    def recent
      @traces = trace_class.all.where(time: 1.hour.ago..).limit(20)
      render partial: 'rails_observatory/traces/recent_traces_page', layout: false
    end

    def index
    end
    def show
      @trace = trace_class.find(params[:id])
      @events = @trace.events.flatten_middleware
      @event = params[:event] ? @events.find(params[:event]) : @events.first
    end

    def filter_params
      params.slice(:event, :sort).permit!
    end
    helper_method :filter_params

    def current_tab
      params[:tab].presence_in( %w(details logs mail jobs errors)) || 'details'
    end
    helper_method :current_tab

    private

    def trace_class
      klass = possible_trace_classes.find { it.key_prefix == params[:type] }
      raise "Invalid type" unless klass
      klass
    end

    def possible_trace_classes
      [RequestTrace, JobTrace]
    end
  end
end