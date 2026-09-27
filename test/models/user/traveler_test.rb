require "test_helper"

class User::TravelerTest < ActiveSupport::TestCase
  test "viajante tem nome" do
    assert users(:viajante).traveler?
    assert_not users(:novato).traveler?
  end

  test "no contexto traveler exige nome, avatar e meta válidos" do
    user = users(:novato)
    user.assign_attributes(name: "", avatar: "dragão", daily_goal_km: 4)

    assert_not user.valid?(:traveler)
    assert user.errors.of_kind?(:name, :blank)
    assert user.errors.of_kind?(:avatar, :inclusion)
    assert user.errors.of_kind?(:daily_goal_km, :inclusion)
  end

  test "nome até 20 caracteres" do
    user = users(:novato)
    user.assign_attributes(name: "A" * 21, avatar: "romeira", daily_goal_km: 3)

    assert_not user.valid?(:traveler)
  end

  test "sem contexto, usuário sem nome é válido (acabou de pedir código)" do
    assert users(:novato).valid?
  end
end
