require "test_helper"

class RouteMapHelperTest < ActionView::TestCase
  include ArtHelper

  setup { @user = users(:viajante) }

  test "com trace desenha a polilinha e rotula com o nome" do
    route = @user.routes.create!(name: "Volta do parque", km: 3, trace: [ [ 0, 0 ], [ 0.5, 1 ], [ 1, 0.2 ] ])
    svg = Nokogiri::HTML5.fragment(route_map(route)).at("svg")

    assert_equal "0 0 200 140", svg["viewBox"]
    assert_equal "img", svg["role"]
    assert_equal "Mapa da rota Volta do parque", svg["aria-label"]
    assert_equal 3, svg.at("polyline")["points"].split.size
  end

  test "sem trace usa a arte de reserva" do
    route = @user.routes.create!(name: "Volta", km: 3)
    img = Nokogiri::HTML5.fragment(route_map(route)).at("img[src*='art/routes/placeholder']")

    assert_equal "Rota Volta", img["alt"]
  end

  test "duas rotas na mesma página não repetem ids" do
    a = @user.routes.create!(name: "A", km: 3, trace: [ [ 0, 0 ], [ 1, 1 ] ])
    b = @user.routes.create!(name: "B", km: 3, trace: [ [ 0, 0 ], [ 1, 1 ] ])
    ids = Nokogiri::HTML5.fragment(route_map(a) + route_map(b)).css("[id]").map { |n| n["id"] }

    assert_equal ids.uniq, ids
    assert_not_empty ids
  end
end
