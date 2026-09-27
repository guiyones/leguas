require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "edita meta e avatar" do
    get edit_profile_url
    assert_response :success

    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "8" } }

    assert_redirected_to root_url
    assert_equal "romeira", users(:viajante).reload.avatar
    assert_equal 8, users(:viajante).daily_goal_km
  end

  test "não aceita meta fora das opções" do
    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "50" } }

    assert_response :unprocessable_entity
  end
end
