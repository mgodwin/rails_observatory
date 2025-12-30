require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "it records events for a request" do
    get posts_path
    assert_response :success

    trace = RailsObservatory::RequestTrace.find(request.request_id)
    assert_equal 25, trace.events.size
    assert_equal "GET", trace.http_method
  end
end
