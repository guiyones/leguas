require "test_helper"

class User::JourneyTest < ActiveSupport::TestCase
  setup do
    @user = users(:viajante)   # meta diária 3 km
    @world = test_world
  end

  test "sem caminhadas: início da primeira fase" do
    journey = @user.journey(world: @world)

    assert_equal 0, journey.total_km
    assert_equal "a1", journey.current_phase.key
    assert_equal 0, journey.phase_progress
    assert_equal "landmark:a1_mark", journey.next_milestone.key
    assert_equal 4, journey.km_to_next
    assert_equal 0, journey.xp
  end

  test "posição no meio de uma fase" do
    log_walks @user, 5, 2   # 7 km; duas missões cumpridas? só a de 5 km (meta 3)

    journey = @user.journey(world: @world)

    assert_equal "a1", journey.current_phase.key
    assert_equal 7, journey.km_in_phase
    assert_in_delta 0.7, journey.phase_progress
    assert_equal [ "landmark:a1_mark" ], journey.achievement_keys
  end

  test "xp soma km, milestones e missões" do
    log_walks @user, 5   # 50 + marco 25 + missão 20

    assert_equal 95, @user.journey(world: @world).xp
  end

  test "exatamente no fim da fase conta como vencida" do
    log_walks @user, 10

    journey = @user.journey(world: @world)

    assert_includes journey.achievement_keys, "phase:a1"
    assert_equal "a2", journey.current_phase.key
    assert_equal 0, journey.km_in_phase
    assert_equal [ "a1" ], journey.completed_phases.map(&:key)
  end

  test "excedente atravessa pra próxima região" do
    log_walks @user, 35   # alpha termina em 30

    journey = @user.journey(world: @world)

    assert_equal "beta", journey.current_region.key
    assert_equal "b1", journey.current_phase.key
    assert_equal 5, journey.km_in_phase
    assert_equal %w[ landmark:a1_mark phase:a1 landmark:a2_mark phase:a2 region:alpha ], journey.achievement_keys.first(5)
  end

  test "mundo completo fica na última fase, cheia" do
    log_walks @user, 60, 50

    journey = @user.journey(world: @world)

    assert journey.finished?
    assert_equal "b2", journey.current_phase.key
    assert_equal 1, journey.phase_progress
    assert_nil journey.next_milestone
    assert_nil journey.km_to_next
  end

  test "títulos entram nas conquistas depois dos milestones" do
    log_walks @user, 60, 50   # xp alto o bastante pra Andarilho (640)

    keys = @user.journey(world: @world).achievement_keys

    assert_equal "region:beta", keys[keys.index("title:andarilho") - 1]
  end

  test "léguas: 6 km cada, arredondando pra baixo" do
    log_walks @user, 13

    assert_equal 2, @user.journey(world: @world).leagues
  end

  test "excluir caminhada faz voltar" do
    log_walks @user, 12
    @user.walks.first.destroy

    assert_equal "a1", @user.journey(world: @world).current_phase.key
  end
end
