require "test_helper"

class PixelArtHelperTest < ActionView::TestCase
  setup { @art = PixelArt.find(:insignias, "gota", root: Rails.root.join("test/pixel_art")) }

  test "gera svg nítido com um rect por corrida" do
    svg = Nokogiri::HTML(pixel_art_tag(@art, size: 64, label: "Gota")).at("svg")

    assert_equal "0 0 4 4", svg["viewbox"]
    assert_equal "crispEdges", svg["shape-rendering"]
    assert_equal "Gota", svg["aria-label"]
    assert_equal @art.runs.size, svg.css("rect").size
  end

  test "silhueta pinta tudo com a cor de silhueta" do
    svg = Nokogiri::HTML(pixel_art_tag(@art, size: 64, label: "?", silhouette: true))

    assert_equal [ "var(--color-ridge)" ], svg.css("rect").map { it["fill"] }.uniq
  end
end
