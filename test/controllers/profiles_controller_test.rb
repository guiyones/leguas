require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "edita meta e avatar" do
    get edit_profile_url
    assert_response :success
    assert_select "input[name='user[name]']:not([autofocus])"

    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "8" } }

    assert_redirected_to root_url
    assert_equal "romeira", users(:viajante).reload.avatar
    assert_equal 8, users(:viajante).daily_goal_km
  end

  test "salva os degraus da escada" do
    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "3", stair_steps: "62" } }

    assert_equal 62, users(:viajante).reload.stair_steps
  end

  test "não aceita meta fora das opções" do
    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "50" } }

    assert_response :unprocessable_entity
  end

  test "mais degraus que derrubam A Torre de Degraus levam à celebração" do
    user = users(:viajante)
    walk_steady user, 90, until_days_ago: 30      # O Primeiro Horizonte aparece
    walk_on user, 29, 12                          # e cai (102)
    walk_steady user, 88, until_days_ago: 20      # 190
    walk_on user, 19, 15, load_kg: 5              # 205: O Fardo do Caminhante aparece e cai
    walk_steady user, 125, until_days_ago: 3      # 330: A Torre de Degraus aparece
    climb_on user, 2, 30                          # 30 × 50 × 0,17 = 255 m
    user.journey.achievement_keys.each { user.celebrate(it) }

    patch profile_url, params: { user: { name: "Tião", avatar: "tropeiro", daily_goal_km: "3", stair_steps: "60" } }

    assert_redirected_to celebration_url
    assert_includes user.reload.pending_celebration_keys, "phase:a_subida"
  end

  test "não apaga os degraus de quem já registrou escada" do
    climb_on users(:viajante), 1, 5

    patch profile_url, params: { user: { name: "Tião", avatar: "tropeiro", daily_goal_km: "3", stair_steps: "" } }

    assert_response :unprocessable_entity
    assert_select ".field-error", text: /Degraus/
    assert_equal 50, users(:viajante).reload.stair_steps
  end
end
