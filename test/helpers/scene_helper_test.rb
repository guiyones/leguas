require "test_helper"

class SceneHelperTest < ActionView::TestCase
  test "seis paletas distintas" do
    palettes = World.current.regions.first.phases.map { scene_palette(it) }

    assert_equal 6, palettes.size
    assert_equal 6, palettes.uniq.size
  end

  test "viajante para antes do chefe" do
    assert_equal scene_trail.point_at(0.5), scene_traveler_point(0.5)
    assert_equal scene_trail.point_at(SceneHelper::TRAVELER_MAX), scene_traveler_point(1)
    assert_equal scene_trail.point_at(1), scene_boss_point
  end

  test "paleta vira variáveis com os tokens" do
    style = scene_palette_style(World.current.regions.first.phases.first)

    assert_includes style, "--scene-sky: var(--color-sky)"
    assert_no_match(/#\h{6}/, style)
  end

  test "rótulo perto da borda não sai da cena" do
    assert_equal "start", scene_label_anchor(28)
    assert_equal "middle", scene_label_anchor(140)
    assert_equal "end", scene_label_anchor(250)
  end
end
