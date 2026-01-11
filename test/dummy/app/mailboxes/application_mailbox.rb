# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # Route all inbound emails to CatchAll mailbox
  routing :all => :catch_all
end
