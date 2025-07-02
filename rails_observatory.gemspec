require_relative "lib/rails_observatory/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_observatory"
  spec.version     = RailsObservatory::VERSION
  spec.authors     = ["Mark Godwin"]
  spec.email       = ["mark.godwin@hey.com"]
  spec.homepage    = "https://github.com/mgodwin/rails_observatory"
  spec.summary     = "See what's happening in your Rails App"
  spec.description = "See what's happening in your Rails App"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mgodwin/rails_observatory"
  spec.metadata["changelog_uri"] = "https://github.com/mgodwin/rails_observatory/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.0"
  spec.add_dependency 'redis-client', "~> 0.19"
  spec.add_dependency "importmap-rails", ">= 1.2.1"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "stimulus-rails"
  spec.add_dependency 'rouge'

  spec.add_development_dependency "faker"
  spec.add_development_dependency "propshaft"
end
