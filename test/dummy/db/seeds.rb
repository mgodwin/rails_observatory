# frozen_string_literal: true

puts "Seeding test data..."

# Generate some outbound emails
puts "Generating outbound emails..."
5.times do |i|
  NewUserMailer.welcome_email("user#{i}@example.com").deliver_now
  sleep 0.1 # Small delay to ensure distinct timestamps
end

# Generate some inbound emails
puts "Generating inbound emails..."
5.times do |i|
  inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
    From: sender#{i}@example.com
    To: support@example.com
    Subject: Test Inbound Email #{i + 1}
    Date: #{Time.now.rfc2822}
    Message-ID: <inbound-#{i}-#{SecureRandom.uuid}@example.com>

    This is a test inbound email message number #{i + 1}.

    It can contain multiple lines of text.
  EMAIL

  # Process the inbound email
  inbound_email.deliver
  sleep 0.1 # Small delay to ensure distinct timestamps
end

puts "Done! Created 5 outbound and 5 inbound emails."
