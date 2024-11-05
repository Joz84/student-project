require "test_helper"

class Teacher::TeamsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get teacher_teams_index_url
    assert_response :success
  end

  test "should get show" do
    get teacher_teams_show_url
    assert_response :success
  end
end
