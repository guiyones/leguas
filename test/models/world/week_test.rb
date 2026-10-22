require "test_helper"

class World::WeekTest < ActiveSupport::TestCase
  test "rótulos dos desafios" do
    assert_equal "3 caminhadas de 40 min", challenge(:walks, count: 3, min_minutes: 40).label
    assert_equal "Longão de 8 km", challenge(:long_walk, km: 8).label
    assert_equal "Longão de 15 km com 8 kg", challenge(:long_walk, km: 15, load_kg: 8).label
    assert_equal "1 sessão de escada", challenge(:stairs, count: 1).label
    assert_equal "2 sessões de escada", challenge(:stairs, count: 2).label
  end

  test "xp máximo de cada desafio" do
    assert_equal 45, challenge(:walks, count: 3, min_minutes: 40).max_xp
    assert_equal 30, challenge(:long_walk, km: 8).max_xp
    assert_equal 30, challenge(:stairs, count: 2).max_xp
  end

  test "xp máximo vem da mesma tabela do progresso da semana" do
    assert_equal 3 * User::WeekProgress::WALK_XP, challenge(:walks, count: 3, min_minutes: 40).max_xp
    assert_equal User::WeekProgress::LONG_WALK_XP, challenge(:long_walk, km: 8).max_xp
    assert_equal 2 * User::WeekProgress::STAIRS_XP, challenge(:stairs, count: 2).max_xp
    assert_not World::Challenge.const_defined?(:XP_PER_SESSION, false)
  end

  test "semana do mundo de teste tem os desafios na ordem" do
    a2 = World.load(Rails.root.join("test/world")).phases.find { it.key == "a2" }

    assert_equal %i[ walks long_walk ], a2.weeks.first.challenges.map(&:kind)
    assert_equal %i[ walks long_walk stairs ], a2.weeks.second.challenges.map(&:kind)
    assert_equal 5, a2.weeks.second.challenges.second.load_kg
    assert_same a2, a2.weeks.first.phase
  end

  test "chave desconhecida em challenges levanta Invalid" do
    assert_raises(World::Invalid) { build_week("foo" => { "count" => 1 }) }
  end

  private
    def challenge(kind, **attrs)
      World::Challenge.new(kind:, count: nil, min_minutes: nil, km: nil, load_kg: nil, **attrs)
    end

    def build_week(challenges)
      World::Week.new({ "km" => 5, "challenges" => challenges }, number: 1, start_km: 0, light: false, phase: nil)
    end
end
