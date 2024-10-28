require "test_helper"

class CwNicknamesControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get cw_nicknames_edit_url
    assert_response :success
  end
end
