require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "it records events for a request" do
    assert_difference -> { RailsObservatory::Request.count }, 1 do
      get posts_path
      assert_response :success
    end
    ro_request = RailsObservatory::Request.find(request.request_id)
    assert_equal 27, ro_request.events.size
    assert_equal "GET", ro_request.http_method
  end
end
