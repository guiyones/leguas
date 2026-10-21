require "test_helper"

class WorldContentTest < ActiveSupport::TestCase
  setup { @world = World.load(World::ROOT) }

  test "região e fases" do
    assert_equal [ [ "vento_austral", 6 ] ], @world.regions.map { [ it.key, it.phases.size ] }
    assert_equal %w[ primeiros_passos carga_leve a_subida dois_dias o_pico patagonia ], @world.phases.map(&:key)
  end

  test "km de cada fase e do mundo" do
    assert_equal [ 90, 115, 125, 150, 180, 150 ], @world.phases.map { it.km.to_i }
    assert_equal 810, @world.total_km
  end

  test "toda fase tem chefe, 4 semanas e insígnia nomeada" do
    @world.phases.each do |phase|
      assert phase.boss?, "#{phase.key} sem chefe"
      assert_equal 4, phase.weeks.size, "#{phase.key} sem 4 semanas"
      assert phase.insignia_name.present?, "#{phase.key} sem nome de insígnia"
      assert phase.focus.present?, "#{phase.key} sem foco"
    end
  end

  test "raridades" do
    assert_equal %w[ rare rare rare rare rare legendary ], @world.phases.map(&:rarity)
  end

  test "marcos espaçados" do
    @world.phases.each do |phase|
      assert_includes 3..5, phase.landmarks.size, "#{phase.key} com #{phase.landmarks.size} marcos"
    end
    assert_operator @world.phases.first.landmarks.first.at_km, :<=, 10

    stops = ([ 0 ] + @world.landmarks.map(&:world_km) + @world.phases.map(&:end_km)).sort
    gaps = stops.each_cons(2).map { |a, b| b - a }
    assert_operator gaps.max, :<=, 35
  end

  test "o mundo inteiro pode ser vencido, chefe por chefe" do
    travel_whole_world users(:viajante), world: @world
    journey = User::Journey.new(users(:viajante), world: @world)

    assert journey.finished?
    assert_equal @world.total_km, journey.position_km
  end

  test "troféu 32x32" do
    assert_nothing_raised { PixelArt.find(:trophies, "vento_austral").validate(size: 32) }
  end

  test "dicas da região" do
    assert_operator @world.regions.first.tips.size, :>=, 3
  end

  test "toda fase tem insígnia válida no tamanho da raridade" do
    @world.phases.each do |phase|
      assert_nothing_raised { PixelArt.find(:insignias, phase.key).validate(size: phase.insignia_size) }
    end
  end

  test "todo marco tem carimbo 12x12 e história" do
    @world.landmarks.each do |landmark|
      PixelArt.find(:stamps, landmark.key).validate(size: 12)
      assert landmark.story.present?, "#{landmark.key} sem história"
    end
  end

  test "todo avatar é 16x16" do
    User::Traveler::AVATARS.each do |avatar|
      assert_nothing_raised { PixelArt.find(:avatars, avatar).validate(size: 16) }
    end
  end
end
