require "test_helper"

class User::CelebrationsTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "pendentes seguem a ordem do caminho" do
    with_world test_world do
      log_walks @user, 12

      assert_equal %w[ landmark:a1_mark phase:a1 ], @user.pending_celebration_keys
      assert_equal "landmark:a1_mark", @user.next_celebration_key
    end
  end

  test "celebrar tira da lista e é idempotente" do
    with_world test_world do
      log_walks @user, 12

      @user.celebrate("landmark:a1_mark")
      @user.celebrate("landmark:a1_mark")

      assert_equal %w[ phase:a1 ], @user.pending_celebration_keys
      assert_equal 1, @user.celebrations.count
    end
  end

  test "editar caminhada esquece conquistas que deixaram de valer" do
    with_world test_world do
      log_walks @user, 12
      @user.pending_celebration_keys.each { @user.celebrate(it) }

      @user.walks.first.update!(km: 5)

      assert_equal %w[ landmark:a1_mark ], @user.celebrations.pluck(:key)
    end
  end

  test "reconquistar mostra de novo" do
    with_world test_world do
      log_walks @user, 12
      @user.pending_celebration_keys.each { @user.celebrate(it) }

      @user.walks.first.destroy
      log_walks @user, 12

      assert_equal %w[ landmark:a1_mark phase:a1 ], @user.pending_celebration_keys
    end
  end

  test "registrar caminhada esquece celebração gravada que o mundo não alcança mais" do
    with_world test_world do
      log_walks @user, 12
      @user.pending_celebration_keys.each { |key| @user.celebrate(key) }
      @user.celebrations.create!(key: "phase:b1")   # gravada antes de uma reorganização do mundo

      @user.walks.create!(km: 1, walked_on: Date.current - 1)

      assert_not_includes @user.celebrations.pluck(:key), "phase:b1"
      assert_includes @user.celebrations.pluck(:key), "phase:a1"
    end
  end

  test "chefe que apareceu vem antes da insígnia" do
    with_world test_world do
      walk_steady @user, 30, until_days_ago: 2

      assert_equal "boss:a2", @user.pending_celebration_keys.last
      assert_not_includes @user.pending_celebration_keys, "phase:a2"

      @user.pending_celebration_keys.each { @user.celebrate(it) }
      walk_on @user, 1, 12

      assert_equal %w[ phase:a2 region:alpha ], @user.pending_celebration_keys.first(2)
    end
  end

  test "diminuir os degraus esquece o chefe de escada" do
    with_world test_world do
      walk_steady @user, 60, until_days_ago: 3   # a2 aparece em 30
      walk_on @user, 2, 12                        # derruba a2; b1 aparece
      climb_on @user, 1, 12                       # 12 × 50 × 0,17 = 102 m: derruba b1
      @user.pending_celebration_keys.each { @user.celebrate(it) }
      assert_includes @user.celebrations.pluck(:key), "phase:b1"

      @user.update!(stair_steps: 40)              # 12 × 40 × 0,17 = 81,6 m

      assert_not_includes @user.celebrations.pluck(:key), "phase:b1"
      assert_includes @user.celebrations.pluck(:key), "boss:b1"
      assert_includes @user.celebrations.pluck(:key), "phase:a2"
    end
  end

  test "excluir a sessão de escada do feito esquece a insígnia" do
    with_world test_world do
      walk_steady @user, 60, until_days_ago: 3
      walk_on @user, 2, 12
      session = climb_on @user, 1, 12
      @user.pending_celebration_keys.each { @user.celebrate(it) }

      session.destroy

      assert_not_includes @user.celebrations.pluck(:key), "phase:b1"
      assert_includes @user.celebrations.pluck(:key), "boss:b1"
    end
  end
end
