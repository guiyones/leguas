require "test_helper"

class AchievementTest < ActiveSupport::TestCase
  setup { @world = test_world }

  test "resolve cada tipo de chave" do
    assert_equal "Marco A1", Achievement.find("landmark:a1_mark", world: @world).subject.name
    assert_equal "Fase A2", Achievement.find("phase:a2", world: @world).subject.name
    assert_equal "Região Beta", Achievement.find("region:beta", world: @world).subject.name
    assert_equal "Andarilho", Achievement.find("title:andarilho", world: @world).subject.name
    assert_equal "phase", Achievement.find("phase:a2", world: @world).kind
  end

  test "chave desconhecida vira nil" do
    assert_nil Achievement.find("phase:nao_existe", world: @world)
    assert_nil Achievement.find("bobagem", world: @world)
  end
end
