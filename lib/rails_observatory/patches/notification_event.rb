module RailsObservatory
  module EventPatch
    def self.prepended(base)
      base.attr_accessor :start_time, :end_time
    end
    def start!
      super
      @start_time = Time.now
    end

    def finish!
      super
      @end_time = Time.now
    end
  end
end

ActiveSupport::Notifications::Event.prepend(RailsObservatory::EventPatch)