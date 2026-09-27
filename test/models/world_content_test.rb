require "test_helper"

class WorldContentTest < ActiveSupport::TestCase
  setup { @world = World.load(World::ROOT) }

  test "regiões e número de fases" do
    assert_equal [ [ "estrada_da_promessa", 6 ] ], @world.regions.map { [ it.key, it.phases.size ] }
  end

  test "Região 1 soma 322 km" do
    assert_equal 322, @world.region("estrada_da_promessa").km
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
