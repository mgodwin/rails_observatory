require_relative "lib/observatory/version"

Gem::Specification.new do |spec|
  spec.name        = "observatory-rails"
  spec.version     = Observatory::VERSION
  spec.authors     = ["Mark Godwin"]
  spec.email       = ["godwin.mark@gmail.com"]
  spec.homepage    = "https://github.com/mgodwin/observatory-rails"
  spec.summary     = "Metrics Tracking for Rails Apps"
  spec.description = "Metrics Tracking for Rails Apps"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mgodwin/observatory-rails"
  spec.metadata["changelog_uri"] = "https://github.com/mgodwin/observatory-rails/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.6"
  spec.add_dependency "redis-time-series", "~> 0.8.0"
end
