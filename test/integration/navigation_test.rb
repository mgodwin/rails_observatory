require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "it records events for a request" do
    assert_difference -> { RailsObservatory::RequestTrace.count }, 1 do
      get posts_path
      assert_response :success
    end
    trace = RailsObservatory::RequestTrace.find(request.request_id)
    assert_equal 26, trace.events.size
    assert_equal "GET", trace.http_method
  end
end
