require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normaliza o email" do
    user = User.create!(email_address: "  Andarilho@Leguas.TEST ")

    assert_equal "andarilho@leguas.test", user.email_address
  end

  test "email precisa ser válido e único" do
    assert_not User.new(email_address: "sem-arroba").valid?
    assert_not User.new(email_address: users(:viajante).email_address.upcase).valid?
  end

  test "degraus de 1 a 1000" do
    user = users(:novato)
    assert user.update(stair_steps: nil)
    assert user.update(stair_steps: 1)
    assert user.update(stair_steps: 1000)
    assert_not user.update(stair_steps: 0)
    assert_not user.update(stair_steps: 1001)
    assert_not user.update(stair_steps: 2.5)
  end

  test "degraus não somem depois de registrar escada" do
    user = users(:viajante)
    climb_on user, 1, 5

    assert_not user.update(stair_steps: nil)
    assert_equal [ "Degraus não podem sumir depois que você registrou escada. A altura das suas subidas vem deles." ],
      user.errors.full_messages_for(:stair_steps)
  end

  test "a jornada do mundo atual é guardada até a próxima caminhada" do
    user = users(:viajante)
    journey = user.journey

    assert journey.equal?(user.journey)

    user.walks.create!(km: 5, walked_on: Date.current)

    assert_not journey.equal?(user.journey)
    assert_operator user.journey.xp, :>, journey.xp
  end

  test "jornada num mundo escolhido não é guardada" do
    user = users(:viajante)

    world = test_world
    assert_not user.journey(world: world).equal?(user.journey(world: world))
  end

  test "trocar de mundo troca a jornada guardada" do
    user = users(:viajante)
    journey = user.journey

    with_world(test_world) { assert_equal "a1", user.journey.current_phase.key }
    assert World.current.equal?(user.journey.world)
    assert_not_equal "a1", journey.current_phase.key
  end

  test "mudar os degraus refaz a jornada guardada" do
    user = users(:viajante)

    with_world test_world do
      walk_steady user, 30, until_days_ago: 6
      walk_on user, 5, 12
      walk_steady user, 18, until_days_ago: 3
      climb_on user, 1, 12                        # 102 m: derruba b1
      assert_equal :defeated, user.journey.boss_status(test_world.phase("b1"))

      user.update!(stair_steps: 40)
      assert_equal :waiting, user.journey.boss_status(World.current.phase("b1"))
    end
  end
end
