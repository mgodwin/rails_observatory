# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
# if ActiveSupport::TestCase.respond_to?(:fixture_path=)
ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_paths.first + "/files"
puts ActiveSupport::TestCase.fixture_paths
ActiveSupport::TestCase.fixtures :all
# end

Rails.configuration.rails_observatory.redis.call("FLUSHALL")
RailsObservatory::RequestTrace.ensure_index