require "test_helper"

class User::LevelTest < ActiveSupport::TestCase
  test "curva 40 × (n−1)²" do
    assert_equal [ 0, 40, 160, 360 ], (1..4).map { User::Level.xp_for(it) }
  end

  test "nível pelo xp, nas fronteiras" do
    assert_equal 1, User::Level.new(0).number
    assert_equal 1, User::Level.new(39).number
    assert_equal 2, User::Level.new(40).number
    assert_equal 2, User::Level.new(159).number
    assert_equal 3, User::Level.new(160).number
    assert_equal 25, User::Level.new(23_040).number
  end

  test "títulos por nível" do
    assert_equal "Caminhante", User::Level.new(User::Level.xp_for(4)).title.name
    assert_equal "Andarilho", User::Level.new(User::Level.xp_for(5)).title.name
    assert_equal "Lenda das Léguas", User::Level.new(User::Level.xp_for(30)).title.name
  end

  test "títulos alcançados não incluem Caminhante" do
    assert_equal [], User::Level.new(0).reached_titles
    assert_equal %w[ andarilho aventureiro ], User::Level.new(User::Level.xp_for(10)).reached_titles.map(&:key)
  end

  test "progresso dentro do nível" do
    level = User::Level.new(100)   # nível 2: 40..160

    assert_in_delta 0.5, level.progress
    assert_equal 60, level.xp_to_next
  end

  test "busca título pela chave" do
    assert_equal "Peregrino", User::Level.title("peregrino").name
  end
end
