require "test_helper"

class ArtHelperTest < ActionView::TestCase
  test "renderiza svg com rótulo" do
    img = Nokogiri::HTML(art_tag(:avatar, :portrait, label: "Tião")).at("img")

    assert_equal "Tião", img["alt"]
    assert_equal "img", img["role"]
    assert_match "art/avatar/portrait", img["src"]
  end

  test "tamanho vira largura e altura" do
    img = Nokogiri::HTML(art_tag(:avatar, :portrait, label: "Tião", size: 44)).at("img")

    assert_equal "44", img["width"]
    assert_equal "44", img["height"]
  end

  test "chave sem arquivo levanta erro" do
    assert_raises(ArgumentError) { art_tag(:avatar, :dragao, label: "?") }
  end

  test "toda arte base existe" do
    [ [ :avatar, :portrait ], [ :avatar, :traveler ], [ :scenes, :menu ] ].each do |kind, key|
      assert art_path_for(kind, key).exist?, "falta art/#{kind}/#{key}.svg"
    end
  end
end
