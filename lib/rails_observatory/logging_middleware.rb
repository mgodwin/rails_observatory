module RailsObservatory
  module LoggingMiddleware
    def connect(redis_config)
      puts "[Redis] CONNECT"
      super
    end

    def call(command, redis_config)
      if command.first == "SCRIPT"
        puts "[Redis] #{command.first}"
      else
        puts "[Redis] #{command.first} #{command[1..-1].join(" ")}"
      end
      super
    end

    def call_pipelined(commands, redis_config)
      puts "[Redis] [Pipelined] #{commands.join("\n")}"
      super
    end
  end
end