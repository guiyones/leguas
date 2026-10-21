require "test_helper"

class World::BossTest < ActiveSupport::TestCase
  FakeLog = Struct.new(:walks, :sessions) do
    def walks_on(date) = walks.fetch(date, [])
    def stair_sessions_on(date) = sessions.fetch(date, [])
  end

  test "distance: uma caminhada só, 6 + 6 não vale" do
    boss = boss(kind: "distance", km: 12)
    assert boss.defeated_on?(today, log: log(today => [ walk(12) ]), since: today)
    assert_not boss.defeated_on?(today, log: log(today => [ walk(6), walk(6) ]), since: today)
  end

  test "distance_with_load: mochila vazia não vale" do
    boss = boss(kind: "distance_with_load", km: 15, load_kg: 5)
    assert boss.defeated_on?(today, log: log(today => [ walk(15, 5) ]), since: today)
    assert_not boss.defeated_on?(today, log: log(today => [ walk(15) ]), since: today)
    assert_not boss.defeated_on?(today, log: log(today => [ walk(15, 4.9) ]), since: today)
  end

  test "climb soma as sessões do dia; climb_with_load só as com carga" do
    # 50 degraus × 0,17 = 8,5 m por subida
    assert boss(kind: "climb", climb_m: 100).defeated_on?(today, log: log(today => [ climb(6), climb(6) ]), since: today)
    with_load = boss(kind: "climb_with_load", climb_m: 100, load_kg: 10)
    assert_not with_load.defeated_on?(today, log: log(today => [ climb(6, 10), climb(6) ]), since: today)
    assert with_load.defeated_on?(today, log: log(today => [ climb(6, 10), climb(6, 12) ]), since: today)
  end

  test "feito antes de since não vale" do
    assert_not boss(kind: "distance", km: 12).defeated_on?(today - 1, log: log(today - 1 => [ walk(12) ]), since: today)
  end

  test "consecutive_days: cada dia com carga, soma de todas as caminhadas" do
    boss = boss(kind: "consecutive_days", days: 2, km: 10, load_kg: 5)
    entries = { today - 1 => [ walk(4, 5) ], today => [ walk(3, 5), walk(3) ] }
    assert boss.defeated_on?(today, log: log(entries), since: today - 1)
    assert_not boss.defeated_on?(today, log: log(entries), since: today)
    assert_not boss.defeated_on?(today, log: log(today - 2 => [ walk(5, 5) ], today => [ walk(5, 5) ]), since: today - 2)
    assert_not boss.defeated_on?(today, log: log(today - 1 => [ walk(5) ], today => [ walk(5, 5) ]), since: today - 1)
  end

  private
    def today = Date.new(2026, 10, 21)

    def boss(**data) = World::Boss.new({ "name" => "Chefe", "description" => "x" }.merge(data.stringify_keys), phase: nil)
    def walk(km, load_kg = nil) = Walk.new(km: km, load_kg: load_kg)
    def climb(climbs, load_kg = nil) = StairSession.new(climbs: climbs, load_kg: load_kg, user: User.new(stair_steps: 50))

    def log(entries)
      FakeLog.new(entries.transform_values { it.grep(Walk) }, entries.transform_values { it.grep(StairSession) })
    end
end
