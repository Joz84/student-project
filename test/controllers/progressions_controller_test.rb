require "test_helper"

class ProgressionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get progressions_index_url
    assert_response :success
  end
end
