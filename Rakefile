require "bundler/setup"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

desc "watch with tailwindcss"
task 'tailwindcss:watch' do
  sh "bundle exec tailwindcss -i app/assets/stylesheets/rails_observatory/application.tailwind.css -o app/assets/stylesheets/rails_observatory/builds/tailwind.css -c config/tailwind.config.js --watch"
end
