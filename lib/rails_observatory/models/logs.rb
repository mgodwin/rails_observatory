module RailsObservatory
  module Logs
    extend ActiveSupport::Concern

    included do
      attribute :logs, indexed: false, compressed: true
    end
  end
end
