require "test_helper"

class User::TrainingLogTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "entries_newest_first mistura e ordena caminhadas e sessões" do
    old_walk = walk_on @user, 3, 5
    climb = climb_on @user, 2, 4
    first_today = walk_on @user, 0, 2
    later_today = climb_on @user, 0, 3
    later_today.update_column(:created_at, first_today.created_at + 1.minute)

    assert_equal [ later_today, first_today, climb, old_walk ], User::TrainingLog.new(@user).entries_newest_first
  end

  test "agrupa por dia" do
    walk_on @user, 2, 5
    walk_on @user, 2, 4.5
    climb_on @user, 1, 10                         # 10 × 50 × 0,17 = 85 m
    climb_on @user, 1, 2                          # 17 m

    log = User::TrainingLog.new(@user)

    assert_equal [ Date.current - 2, Date.current - 1 ], log.dates
    assert_equal 9.5, log.km_on(Date.current - 2)
    assert_equal 0, log.km_on(Date.current - 1)
    assert_equal 2, log.walks_on(Date.current - 2).size
    assert_equal [], log.walks_on(Date.current - 1)
    assert_equal 2, log.stair_sessions_on(Date.current - 1).size
    assert_equal 102, log.climbed_m
  end

  test "memoizado no usuário e renovado quando um registro muda" do
    log = @user.training_log
    assert_same log, @user.training_log

    walk_on @user, 1, 5
    assert_equal [ Date.current - 1 ], @user.training_log.dates

    climb_on @user, 0, 1
    assert_equal [ Date.current - 1, Date.current ], @user.training_log.dates
  end
end
