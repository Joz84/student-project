require "test_helper"

class AttemptsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get attempts_create_url
    assert_response :success
  end
end
