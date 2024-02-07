module RailsObservatory
  class MailersController < ApplicationController

    def index

      MailDelivery.ensure_index
      @deliveries = MailDelivery.all

    end
  end
end
