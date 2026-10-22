require "test_helper"

class User::JourneyTest < ActiveSupport::TestCase
  setup do
    @user = users(:viajante)   # meta diária 3 km, 50 degraus
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
    assert_equal :current, journey.phase_status(@world.phase("a1"))
    assert_equal :upcoming, journey.phase_status(@world.phase("a2"))
    assert_equal :hidden, journey.boss_status(@world.phase("a2"))
    assert_equal :locked, journey.region_status(@world.region("beta"))
  end

  test "fase sem chefe é vencida pelo km e atravessa sem parar" do
    walk_on @user, 1, 17

    journey = @user.journey(world: @world)

    assert_equal "a2", journey.current_phase.key
    assert_equal 7, journey.km_in_phase
    assert_in_delta 0.35, journey.phase_progress
    assert_equal :defeated, journey.boss_status(@world.phase("a1"))
    assert journey.phase_completed?(@world.phase("a1"))
    assert_equal %w[ landmark:a1_mark phase:a1 landmark:a2_mark ], journey.achievement_keys
  end

  test "chefe aparece quando o km da fase fecha e espera" do
    walk_steady @user, 30, until_days_ago: 2     # 3 × 10 km, chega no fim de a2 (30)
    journey = @user.journey(world: @world)

    assert_equal :waiting, journey.boss_status(@world.phase("a2"))
    assert_equal Date.current - 2, journey.boss_appeared_on(@world.phase("a2"))
    assert_nil journey.boss_defeated_on(@world.phase("a2"))
    assert_equal :boss, journey.phase_status(@world.phase("a2"))
    assert_includes journey.achievement_keys, "boss:a2"
    assert_not_includes journey.achievement_keys, "phase:a2"
    assert_nil journey.current_week
    assert_equal "a2", journey.current_phase.key
    assert_equal 1, journey.phase_progress
  end

  test "a caminhada que fecha o km e cumpre o feito derruba o chefe no mesmo dia" do
    walk_on @user, 2, 18
    walk_on @user, 1, 12                          # 30 km, e é uma caminhada de 12

    journey = @user.journey(world: @world)

    assert_equal :defeated, journey.boss_status(@world.phase("a2"))
    assert_equal Date.current - 1, journey.boss_defeated_on(@world.phase("a2"))
    assert_equal :completed, journey.phase_status(@world.phase("a2"))
    assert_equal "b1", journey.current_phase.key
  end

  test "feito antes do chefe aparecer não vale" do
    walk_on @user, 5, 12
    walk_on @user, 4, 9
    walk_on @user, 4, 9                           # chefe aparece aqui (30), nenhuma caminhada de 12 depois

    assert_equal :waiting, @user.journey(world: @world).boss_status(@world.phase("a2"))
  end

  test "km guardados esperam o chefe e entram de uma vez" do
    walk_steady @user, 40, until_days_ago: 2     # 10 km guardados, 4 missões cumpridas
    journey = @user.journey(world: @world)

    assert_equal [ 30, 10, 40 ], [ journey.position_km, journey.banked_km, journey.total_km ]
    assert_equal 400 + 25 + 100 + 25 + 0 + 2 * 30, journey.xp - 4 * Mission::XP   # km pelo total; a2 e região ainda não; longões das semanas 1 e 3

    walk_on @user, 1, 12
    journey = @user.journey(world: @world)

    assert_equal [ 52, 0 ], [ journey.position_km, journey.banked_km ]
    assert_equal "b1", journey.current_phase.key
  end

  test "um chefe por dia: km guardados que fecham a próxima fase deixam o chefe pro dia seguinte" do
    walk_steady @user, 70, until_days_ago: 2     # para em 30 (a2), 40 guardados
    climb_on @user, 1, 12                         # 102 m: feito de b1, mas b1 ainda não apareceu
    walk_on @user, 1, 12                          # derruba a2; posição vai a 60 (fim de b1), b1 aparece hoje
    journey = @user.journey(world: @world)

    assert_equal :defeated, journey.boss_status(@world.phase("a2"))
    assert_equal :waiting, journey.boss_status(@world.phase("b1"))
    assert_equal Date.current - 1, journey.boss_appeared_on(@world.phase("b1"))
    assert_equal [ 60, 22 ], [ journey.position_km, journey.banked_km ]

    climb_on @user, 0, 12

    assert_equal :defeated, @user.journey(world: @world).boss_status(@world.phase("b1"))
  end

  test "mudar os degraus do perfil derruba ou devolve um chefe de escada" do
    walk_steady @user, 30, until_days_ago: 6     # a2 aparece
    walk_on @user, 5, 12                          # derruba a2 (42)
    walk_steady @user, 18, until_days_ago: 3     # 60: b1 aparece
    climb_on @user, 1, 12                         # 12 × 50 × 0,17 = 102 m
    b1 = @world.phase("b1")

    assert_equal :defeated, @user.journey(world: @world).boss_status(b1)

    @user.update!(stair_steps: 40)                # 81,6 m
    assert_equal :waiting, @user.journey(world: @world).boss_status(b1)

    @user.update!(stair_steps: 50)
    assert_equal :defeated, @user.journey(world: @world).boss_status(b1)
  end

  test "semana atual pelo km dentro da fase" do
    walk_on @user, 1, 17                          # a2 com 7 km → semana 2 (5–10)

    assert_equal 2, @user.journey(world: @world).current_week.number
  end

  test "fase sem semanas não tem semana atual" do
    walk_on @user, 1, 3

    assert_nil @user.journey(world: @world).current_week
  end

  test "excluir a caminhada do feito faz o chefe voltar a esperar" do
    walk_steady @user, 30, until_days_ago: 2
    feat = walk_on @user, 1, 12
    feat.destroy

    journey = @user.journey(world: @world)

    assert_equal :waiting, journey.boss_status(@world.phase("a2"))
    assert_equal 0, journey.banked_km
  end

  test "mundo completo" do
    complete_world

    journey = @user.journey(world: @world)

    assert journey.finished?
    assert_equal "b2", journey.current_phase.key
    assert_equal 1, journey.phase_progress
    assert_equal [ 100, 10, 110 ], [ journey.position_km, journey.banked_km, journey.total_km ]
    assert_nil journey.next_milestone
    assert_nil journey.km_to_next
    assert_equal [ :completed ], @world.phases.map { journey.phase_status(it) }.uniq
    assert_equal [ :completed ], @world.regions.map { journey.region_status(it) }.uniq
    assert_equal [ :defeated ], @world.phases.map { journey.boss_status(it) }.uniq
    assert journey.landmark_reached?(@world.landmark("b2_mark"))
    assert_equal Date.current - 6, journey.boss_defeated_on(@world.phase("b2"))
  end

  test "títulos entram nas conquistas depois dos milestones" do
    complete_world

    keys = @user.journey(world: @world).achievement_keys

    assert_equal "region:beta", keys[keys.index("title:andarilho") - 1]
  end

  test "xp de escada" do
    climb_on @user, 1, 12                         # 12 × 50 × 0,17 = 102 m

    journey = @user.journey(world: @world)

    assert_equal 102, journey.climbed_m
    assert_equal 20, journey.xp
    assert_equal 0, journey.total_km
  end

  test "status de região e fase com chefe esperando" do
    walk_steady @user, 35, until_days_ago: 2
    journey = @user.journey(world: @world)

    assert_equal :current, journey.region_status(@world.region("alpha"))
    assert_equal :locked, journey.region_status(@world.region("beta"))
    assert_equal :completed, journey.phase_status(@world.phase("a1"))
    assert_equal :boss, journey.phase_status(@world.phase("a2"))
    assert_equal :upcoming, journey.phase_status(@world.phase("b1"))
    assert_equal :hidden, journey.boss_status(@world.phase("b1"))
    assert journey.landmark_reached?(@world.landmark("a2_mark"))
    assert_not journey.finished?
  end

  test "caminhadas com tempo contam pra semana em que o dia começou" do
    walk_on @user, 5, 10                          # a1, sem semanas
    walk_on @user, 4, 1, minutes: 40
    walk_on @user, 3, 1, minutes: 39
    walk_on @user, 3, 1                           # sem tempo
    journey = @user.journey(world: @world)
    week1 = @world.phase("a2").weeks.first
    walks = week1.challenges.find { it.kind == :walks }

    assert_equal 1, journey.week_progress(week1).done(walks)

    walk_on @user, 2, 1, minutes: 40              # km 13 de manhã
    journey = @user.journey(world: @world)

    assert_equal 2, journey.week_progress(week1).done(walks)
    assert_not journey.week_progress(week1).complete?
    assert_empty journey.completed_weeks
  end

  test "caminhada de 3 km com 45 min conta pras caminhadas e pro longão" do
    walk_on @user, 2, 10
    walk_on @user, 1, 3, minutes: 45
    progress = @user.journey(world: @world).week_progress(@world.phase("a2").weeks.first)

    assert_equal [ 1, 1 ], progress.week.challenges.map { progress.done(it) }
  end

  test "fronteira: o dia conta pra semana da posição de manhã" do
    walk_on @user, 3, 10
    walk_on @user, 2, 4                           # km 14: a2, semana 1
    walk_on @user, 1, 3, minutes: 40              # termina no km 17, semana 2
    journey = @user.journey(world: @world)
    week1, week2 = @world.phase("a2").weeks.first(2)

    assert_equal 1, journey.week_progress(week1).done(week1.challenges.first)
    assert_equal 0, journey.week_progress(week2).done(week2.challenges.first)
  end

  test "semana sem nenhum dia tem progresso vazio" do
    week = @world.phase("a2").weeks.last
    progress = @user.journey(world: @world).week_progress(week)

    assert_equal [ 0, 0 ], week.challenges.map { progress.done(it) }
    assert_equal 0, progress.xp
  end

  test "longão da semana 2 pede carga e escada conta sessão" do
    walk_on @user, 4, 15                          # km 15: semana 2 de a2
    walk_on @user, 3, 3
    climb_on @user, 3, 2
    journey = @user.journey(world: @world)
    week2 = @world.phase("a2").weeks.second
    long_walk, stairs = week2.challenges.values_at(1, 2)

    assert_equal 0, journey.week_progress(week2).done(long_walk)
    assert_equal 1, journey.week_progress(week2).done(stairs)

    walk_on @user, 2, 3, load_kg: 5

    assert_equal 1, @user.journey(world: @world).week_progress(week2).done(long_walk)
  end

  test "semana completa dá xp, conquista e entra nas completas" do
    walk_on @user, 4, 10
    walk_on @user, 3, 2, minutes: 40
    walk_on @user, 2, 2, minutes: 40
    walk_on @user, 1, 3                           # km 14 de manhã: longão da semana 1
    journey = @user.journey(world: @world)
    week1 = @world.phase("a2").weeks.first

    assert_equal 2 * 15 + 30 + 50, journey.week_progress(week1).xp
    assert_equal 2 * 15 + 30 + 50, journey.xp - base_xp(journey)
    assert_equal [ week1 ], journey.completed_weeks
    assert_equal "week:a2:1", journey.achievement_keys.last
  end

  test "chefe esperando: o dia não cai em semana nenhuma" do
    walk_steady @user, 30, until_days_ago: 3      # a2 completa, chefe espera
    before = all_weeks_xp(@user.journey(world: @world))

    walk_on @user, 2, 2, minutes: 40              # sem a trava, cairiam na semana 1 de b1
    walk_on @user, 1, 2, minutes: 40
    journey = @user.journey(world: @world)
    b1_week1 = @world.phase("b1").weeks.first

    assert_equal :waiting, journey.boss_status(@world.phase("a2"))
    assert_equal 0, journey.week_progress(b1_week1).done(b1_week1.challenges.first)
    assert_equal before, all_weeks_xp(journey)
  end

  test "manhã depois do chefe cair: km guardados levam o dia pra semana da posição nova" do
    walk_steady @user, 40, until_days_ago: 4      # para em 30, 10 guardados
    walk_on @user, 3, 12                          # derruba a2; o dia ainda é do chefe esperando
    walk_on @user, 2, 1, minutes: 40              # manhã no km 52: semana 3 de b1 (20–30)
    walk_on @user, 1, 1, minutes: 40
    journey = @user.journey(world: @world)
    b1_weeks = @world.phase("b1").weeks

    assert_equal :defeated, journey.boss_status(@world.phase("a2"))
    assert_equal [ 0, 0, 2 ], b1_weeks.map { journey.week_progress(it).done(it.challenges.first) }
    assert_equal [ b1_weeks.third ], journey.completed_weeks
    assert_includes journey.achievement_keys, "week:b1:3"
  end

  test "xp de caminhadas sem desafios não muda" do
    walk_on @user, 1, 9                           # a1 não tem semanas

    assert_equal 90 + 25 + missions_xp, @user.journey(world: @world).xp   # km + Marco A1
  end

  test "léguas: 6 km cada pelo total, arredondando pra baixo" do
    walk_steady @user, 40, until_days_ago: 2

    assert_equal 6, @user.journey(world: @world).leagues
  end

  private
    def all_weeks_xp(journey) = @world.phases.flat_map(&:weeks).sum { journey.week_progress(it).xp }

    def missions_xp = Mission::XP * @user.missions.accomplished.count

    def base_xp(journey)
      journey.total_km * 10 + journey.reached_milestones.sum(&:xp) + missions_xp + (journey.climbed_m / 5).floor
    end

    # Cada fim de fase e o feito de cada chefe num dia próprio.
    def complete_world
      walk_steady @user, 30, until_days_ago: 20    # a2 aparece
      walk_on @user, 19, 12                         # derruba a2 (42)
      walk_steady @user, 18, until_days_ago: 16    # 60: b1 aparece
      climb_on @user, 15, 12                        # derruba b1
      walk_steady @user, 40, until_days_ago: 8     # 100: b2 aparece
      walk_on @user, 7, 5, load_kg: 5
      walk_on @user, 6, 5, load_kg: 5               # dois dias seguidos com carga, 10 km: derruba b2
    end
end
