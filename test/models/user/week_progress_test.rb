require "test_helper"

class User::WeekProgressTest < ActiveSupport::TestCase
  setup do
    @user = users(:viajante)
    @phase = test_world.phase("a2")
    @week1, @week2 = @phase.weeks.first(2)
  end

  test "caminhadas qualificadas pelo tempo, até o count" do
    progress = progress(@week1, walks: [ walk(2, minutes: 40), walk(2, minutes: 39), walk(2), walk(2, minutes: 50), walk(2, minutes: 60) ])

    assert_equal 2, progress.done(walks_challenge(@week1))
    assert progress.done?(walks_challenge(@week1))
  end

  test "caminhada curta demais não conta" do
    progress = progress(@week1, walks: [ walk(2, minutes: 40), walk(2, minutes: 39), walk(2) ])

    assert_equal 1, progress.done(walks_challenge(@week1))
    assert_not progress.done?(walks_challenge(@week1))
  end

  test "longão pelo km e pela carga" do
    long_walk = @week2.challenges.find { it.kind == :long_walk }

    assert_equal 0, progress(@week2, walks: [ walk(3) ]).done(long_walk)
    assert_equal 0, progress(@week2, walks: [ walk(3, load_kg: 4) ]).done(long_walk)
    assert_equal 1, progress(@week2, walks: [ walk(3, load_kg: 5) ]).done(long_walk)
    assert_equal 1, progress(@week2, walks: [ walk(3, load_kg: 5), walk(4, load_kg: 5) ]).done(long_walk)
    assert_equal 0, progress(@week2, walks: [ walk(2.9, load_kg: 5) ]).done(long_walk)
  end

  test "escada: cada sessão até o count" do
    stairs = @week2.challenges.find { it.kind == :stairs }
    sessions = [ StairSession.new(climbs: 5), StairSession.new(climbs: 5) ]

    assert_equal 1, progress(@week2, stair_sessions: sessions).done(stairs)
    assert_equal 0, progress(@week2).done(stairs)
  end

  test "xp soma os desafios e o bônus da semana completa" do
    incomplete = progress(@week1, walks: [ walk(2, minutes: 40), walk(3) ])
    complete = progress(@week1, walks: [ walk(2, minutes: 40), walk(3, minutes: 45) ])

    assert_not incomplete.complete?
    assert_equal 15 + 30, incomplete.xp
    assert complete.complete?
    assert_equal 2 * 15 + 30 + 50, complete.xp
  end

  test "trecho só é conquistado quando chega no marco do fim com os desafios feitos" do
    walks = [ walk(2, minutes: 40), walk(3, minutes: 45) ]
    on_the_way = progress(@week1, walks: walks, finished: false)

    assert on_the_way.complete?
    assert_not on_the_way.conquered?
    assert_equal 2 * 15 + 30, on_the_way.xp
    assert progress(@week1, walks: walks).conquered?
    assert_not progress(@week1, walks: walks.first(1)).conquered?
  end

  test "semana sem desafios nunca fica completa" do
    week = World::Week.new({ "km" => 5 }, number: 1, start_km: 0, light: false, phase: @phase)

    assert_not progress(week).complete?
    assert_equal 0, progress(week).xp
  end

  private
    def progress(week, walks: [], stair_sessions: [], finished: true)
      User::WeekProgress.new(week, walks: walks, stair_sessions: stair_sessions, finished: finished)
    end

    def walk(km, minutes: nil, load_kg: nil)
      Walk.new(km: km, load_kg: load_kg, duration_s: (minutes * 60 if minutes))
    end

    def walks_challenge(week) = week.challenges.find { it.kind == :walks }
end
