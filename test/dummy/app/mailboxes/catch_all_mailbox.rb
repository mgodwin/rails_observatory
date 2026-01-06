# frozen_string_literal: true

# CatchAllMailbox processes all inbound emails
# The actual tracking is done by RailsObservatory::ActionMailboxSubscriber
class CatchAllMailbox < ApplicationMailbox
  def process
    # Just process the email - the subscriber will capture it
  end
end
