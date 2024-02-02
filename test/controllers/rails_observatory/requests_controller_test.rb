require "test_helper"

module RailsObservatory
  class RequestsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "index renders successfully" do
      get requests_path
      assert_response :success
    end

    test "show renders successfully" do
      get posts_path
      get rails_observatory.request_path(request.request_id)
      assert_response :success
    end
  end
end
