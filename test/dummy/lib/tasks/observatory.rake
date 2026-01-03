namespace :observatory do
  desc "Continuously generate sample requests, jobs, and mailers (Ctrl+C to stop)"
  task seed: :environment do
    require "net/http"

    base_url = ENV.fetch("BASE_URL", "http://localhost:3000")

    # Request scenarios
    requests = [
      {method: :get, path: "/scenarios/success", desc: "GET success (200)"},
      {method: :get, path: "/scenarios/success_json", desc: "GET JSON (200)"},
      {method: :post, path: "/scenarios/create_resource", desc: "POST create (201)"},
      {method: :patch, path: "/scenarios/update_resource", desc: "PATCH update (200)"},
      {method: :delete, path: "/scenarios/delete_resource", desc: "DELETE (204)"},
      {method: :get, path: "/scenarios/not_found", desc: "GET not_found (404)"},
      {method: :post, path: "/scenarios/validation_error", desc: "POST validation (422)"},
      {method: :get, path: "/scenarios/server_error", desc: "GET error (500)"},
      {method: :get, path: "/scenarios/slow_request", desc: "GET slow (2-3s)"},
      {method: :post, path: "/scenarios/unpermitted_params", params: {"post[title]" => "Valid", "post[hacker_field]" => "rejected", "post[admin]" => "true"}, desc: "POST unpermitted params"}
    ]

    # Job scenarios
    jobs = [
      {type: :successful, desc: "SuccessfulJob"},
      {type: :failing, desc: "FailingJob"},
      {type: :slow, desc: "SlowJob"},
      {type: :retry, desc: "RetryJob"}
    ]

    # Mailer scenarios
    mailers = [
      {action: :welcome, args: -> { {user_email: "user#{rand(1000)}@example.com"} }, desc: "welcome"},
      {action: :notification, args: -> { {user_email: "user#{rand(1000)}@example.com", message: "Notification #{rand(1000)}"} }, desc: "notification"},
      {action: :newsletter, args: -> { {recipients: ["list#{rand(100)}@example.com"]} }, desc: "newsletter"}
    ]

    # Helper to make HTTP requests
    make_request = lambda do |method, path, params = {}|
      uri = URI("#{base_url}#{path}")
      case method
      when :get
        Net::HTTP.get_response(uri)
      when :post
        Net::HTTP.post_form(uri, params)
      when :patch
        req = Net::HTTP::Patch.new(uri)
        Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
      when :delete
        req = Net::HTTP::Delete.new(uri)
        Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
      end
    rescue
      nil
    end

    # Helper to run a job
    run_job = lambda do |type|
      case type
      when :successful
        SuccessfulJob.perform_now(name: "Task #{rand(1000)}")
      when :failing
        begin
          FailingJob.perform_now(reason: "Simulated error #{rand(1000)}")
        rescue StandardError
          # Expected
        end
      when :slow
        SlowJob.perform_now(duration: rand(0.5..1.5))
      when :retry
        RetryJob.perform_now(fail_times: rand(1..2))
      end
    end

    running = true
    trap("INT") { running = false }

    puts "Seeding Rails Observatory continuously..."
    puts "Target: #{base_url}"
    puts "Press Ctrl+C to stop"
    puts ""

    count = 0
    while running
      count += 1

      # Pick event type: 60% request, 30% job, 10% mailer
      roll = rand(100)
      if roll < 60
        # Request
        req = requests.sample
        print "[#{count}] REQUEST #{req[:desc]}..."
        response = make_request.call(req[:method], req[:path], req[:params] || {})
        puts response ? " #{response.code}" : " (unreachable)"
      elsif roll < 90
        # Job
        job = jobs.sample
        print "[#{count}] JOB #{job[:desc]}..."
        run_job.call(job[:type])
        puts " done"
      else
        # Mailer
        mailer = mailers.sample
        print "[#{count}] MAIL #{mailer[:desc]}..."
        ScenariosMailer.send(mailer[:action], **mailer[:args].call).deliver_now
        puts " done"
      end

      sleep(rand(0.1..0.5)) if running
    end

    puts ""
    puts "Stopped. Generated #{count} events."
    puts "View results at: #{base_url}/observatory"
  end
end
