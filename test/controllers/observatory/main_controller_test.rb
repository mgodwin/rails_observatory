require "test_helper"

module Observatory
  class MainControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "the truth" do
      assert true
    end
  end
end
