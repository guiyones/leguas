require "test_helper"

class User::TravelerTest < ActiveSupport::TestCase
  test "viajante tem nome" do
    assert users(:viajante).traveler?
    assert_not users(:novato).traveler?
  end

  test "no contexto traveler exige nome e meta válidos" do
    user = users(:novato)
    user.assign_attributes(name: "", daily_goal_km: 4)

    assert_not user.valid?(:traveler)
    assert user.errors.of_kind?(:name, :blank)
    assert user.errors.of_kind?(:daily_goal_km, :inclusion)
  end

  test "viajante é válido só com nome e meta, sem avatar" do
    user = users(:novato)
    user.assign_attributes(name: "Zé", daily_goal_km: 5)

    assert user.valid?(:traveler)
    assert_not user.has_attribute?(:avatar)
  end

  test "nome até 20 caracteres" do
    user = users(:novato)
    user.assign_attributes(name: "A" * 21, daily_goal_km: 3)

    assert_not user.valid?(:traveler)
  end

  test "sem contexto, usuário sem nome é válido (acabou de pedir código)" do
    assert users(:novato).valid?
  end
end
