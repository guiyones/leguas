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
end
