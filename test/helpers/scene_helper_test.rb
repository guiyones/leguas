require "test_helper"

class SceneHelperTest < ActionView::TestCase
  test "seis paletas distintas" do
    palettes = World.current.regions.first.phases.map { scene_palette(it) }

    assert_equal 6, palettes.size
    assert_equal 6, palettes.uniq.size
  end

  test "rótulo perto da borda não sai da cena" do
    assert_equal "start", scene_label_anchor(28)
    assert_equal "middle", scene_label_anchor(140)
    assert_equal "end", scene_label_anchor(250)
  end
end
