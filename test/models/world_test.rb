require "test_helper"

class WorldTest < ActiveSupport::TestCase
  setup { @world = test_world }

  test "carrega as regiões na ordem dos arquivos" do
    assert_equal %w[ alpha beta ], @world.regions.map(&:key)
    assert_equal [ 1, 2 ], @world.regions.map(&:number)
  end

  test "acumula os km pelo mundo" do
    assert_equal [ 0, 10 ], [ @world.phase("a1").start_km, @world.phase("a1").end_km ]
    assert_equal [ 60, 100 ], [ @world.phase("b2").start_km, @world.phase("b2").end_km ]
    assert_equal 30, @world.region("beta").start_km
    assert_equal 100, @world.total_km
    assert_kind_of BigDecimal, @world.total_km
  end

  test "marco sabe sua posição no mundo" do
    assert_equal 15, @world.landmark("a2_mark").world_km
  end

  test "raridade define xp" do
    assert_equal 100, @world.phase("a1").xp
    assert_equal 250, @world.phase("a2").xp
    assert @world.phase("b2").legendary?
  end

  test "milestones em ordem de caminho: marco, chefe, fim de fase, fim de região" do
    expected = [
      [ "landmark:a1_mark", 4, 25 ], [ "phase:a1", 10, 100 ],
      [ "landmark:a2_mark", 15, 25 ], [ "boss:a2", 30, 0 ], [ "phase:a2", 30, 250 ], [ "region:alpha", 30, 500 ],
      [ "boss:b1", 60, 0 ], [ "phase:b1", 60, 250 ], [ "landmark:b2_mark", 70, 25 ],
      [ "boss:b2", 100, 0 ], [ "phase:b2", 100, 250 ], [ "region:beta", 100, 500 ]
    ]

    assert_equal expected, @world.milestones.map { [ it.key, it.at_km, it.xp ] }
  end

  test "região conhece a próxima e o xp total dela" do
    assert_equal @world.region("beta"), @world.region("alpha").next
    assert_nil @world.region("beta").next
    assert_equal 300 + 25 + 100 + 25 + 250 + 500, @world.region("alpha").xp
  end

  test "marco fora da fase é inválido" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "01.yml"), <<~YAML)
        key: x
        name: X
        inspired_by: x
        trophy_name: X
        phases:
          - { key: x1, name: X1, inspired_by: x, km: 10, symbol: x,
              landmarks: [ { key: m, name: M, at_km: 10, story: s } ] }
      YAML

      assert_raises(World::Invalid) { World.load(dir) }
    end
  end

  test "chave repetida é inválida" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "01.yml"), <<~YAML)
        key: x
        name: X
        inspired_by: x
        trophy_name: X
        phases:
          - { key: dup, name: A, inspired_by: x, km: 10, symbol: x }
          - { key: dup, name: B, inspired_by: x, km: 10, symbol: x }
      YAML

      assert_raises(World::Invalid) { World.load(dir) }
    end
  end

  test "raridade desconhecida é inválida" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "01.yml"), <<~YAML)
        key: x
        name: X
        inspired_by: x
        trophy_name: X
        phases:
          - { key: x1, name: A, inspired_by: x, km: 10, symbol: x, rarity: épica }
      YAML

      assert_raises(World::Invalid) { World.load(dir) }
    end
  end

  test "semanas acumulam km dentro da fase" do
    weeks = @world.phase("a2").weeks

    assert_equal [ 0, 5, 10, 15 ], weeks.map(&:start_km)
    assert_equal [ 5, 10, 15, 20 ], weeks.map(&:end_km)
    assert_equal [ 1, 2, 3, 4 ], weeks.map(&:number)
    assert_equal [ false, false, false, true ], weeks.map(&:light?)
    assert_equal "Curtas 1", weeks.first.short_walks
    assert_empty @world.phase("a1").weeks
  end

  test "fase com chefe e dados extras" do
    phase = @world.phase("a2")

    assert phase.boss?
    assert_equal "Chefe A2", phase.boss.name
    assert_equal phase, phase.boss.phase
    assert_not @world.phase("a1").boss?
    assert_nil @world.phase("a1").boss
    assert_equal [ "Foco A2", "Nota A2", "Insígnia A2" ], [ phase.focus, phase.note, phase.insignia_name ]
    assert_equal "Bônus A2", phase.bonus["name"]
    assert phase.rare?
    assert_not @world.phase("a1").rare?
  end

  test "chefe com tipo desconhecido é inválido" do
    assert_raises(World::Invalid) { load_phase("boss: { name: B, description: x, kind: voar }") }
  end

  test "chefe sem parâmetro obrigatório é inválido" do
    assert_raises(World::Invalid) { load_phase("boss: { name: B, description: x, kind: distance_with_load, km: 10 }") }
    assert_raises(World::Invalid) { load_phase("boss: { name: B, description: x, kind: climb }") }
    assert_raises(World::Invalid) { load_phase("boss: { name: B, description: x, kind: consecutive_days, days: 1, km: 10, load_kg: 5 }") }
  end

  test "semanas que não somam o km da fase são inválidas" do
    assert_raises(World::Invalid) { load_phase("weeks: [ { km: 4 }, { km: 3 } ]") }
  end

  test "dicas da região" do
    assert_equal [ "Dica um.", "Dica dois." ], @world.region("alpha").tips
    assert_equal [], @world.region("beta").tips
  end

  test "achievement boss aponta para a fase" do
    assert_equal @world.phase("a2"), Achievement.find("boss:a2", world: @world).subject
  end

  private
    def load_phase(extra)
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "01.yml"), <<~YAML)
          key: x
          name: X
          inspired_by: x
          trophy_name: X
          phases:
            - { key: x1, name: A, inspired_by: x, km: 8, symbol: x, #{extra} }
        YAML

        World.load(dir)
      end
    end
end
