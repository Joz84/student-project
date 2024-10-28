require "test_helper"

class ExercicesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get exercices_index_url
    assert_response :success
  end
end
