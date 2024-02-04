require_relative "lib/rails_observatory/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_observatory"
  spec.version     = RailsObservatory::VERSION
  spec.authors     = ["Mark Godwin"]
  spec.email       = ["godwin.mark@gmail.com"]
  spec.homepage    = "https://github.com/mgodwin/observatory-rails"
  spec.summary     = "Observability for Rails Apps"
  spec.description = "Observability for Rails Apps"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mgodwin/observatory-rails"
  spec.metadata["changelog_uri"] = "https://github.com/mgodwin/observatory-rails/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_development_dependency "faker"
  spec.add_dependency "rails", ">= 7.1.0"
  spec.add_dependency 'redis-client', "~> 0.19"
  spec.add_dependency 'zeitwerk'
  spec.add_dependency 'rouge'
end
