module RailsObservatory
  class UsageController < ApplicationController
    def index
      @usage_stats = UsageStats.new
    end
  end
end
