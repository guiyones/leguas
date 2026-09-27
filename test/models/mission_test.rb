require "test_helper"

class MissionTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "meta fica congelada no primeiro registro do dia" do
    @user.walks.create!(km: 1, walked_on: Date.current)
    @user.update!(daily_goal_km: 8)
    @user.walks.create!(km: 1, walked_on: Date.current)

    assert_equal 3, @user.missions.find_by(date: Date.current).goal_km
  end

  test "cumprida quando a soma do dia alcança a meta" do
    @user.walks.create!(km: 1.5, walked_on: Date.current)
    mission = @user.missions.find_by(date: Date.current)
    assert_not mission.accomplished?

    @user.walks.create!(km: 1.5, walked_on: Date.current)
    assert mission.accomplished?
    assert_equal 3, mission.walked_km
  end

  test "scope conta só as cumpridas" do
    @user.walks.create!(km: 5, walked_on: Date.current)
    @user.walks.create!(km: 1, walked_on: Date.current - 1)

    assert_equal 1, @user.missions.accomplished.count
  end

  test "mudar a data da caminhada cria a missão da nova data" do
    walk = @user.walks.create!(km: 5, walked_on: Date.current)

    walk.update!(walked_on: Date.current - 2)

    assert @user.missions.find_by(date: Date.current - 2).accomplished?
    assert_not @user.missions.find_by(date: Date.current).accomplished?
  end
end
