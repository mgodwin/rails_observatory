module Observatory
  class Engine < ::Rails::Engine
    isolate_namespace Observatory

  
    initializer "observatory.assets.precompile" do |app|
      app.config.assets.precompile += %w( observatory/application.css )
    end
  end
end
