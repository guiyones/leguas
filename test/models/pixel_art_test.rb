require "test_helper"

class PixelArtTest < ActiveSupport::TestCase
  ROOT = Rails.root.join("test/pixel_art")

  test "lê a grade e mede" do
    art = PixelArt.find(:insignias, "gota", root: ROOT)

    assert_equal 4, art.width
    assert_equal 4, art.height
  end

  test "agrupa pixels iguais e seguidos em corridas, sem transparentes" do
    art = PixelArt.find(:insignias, "gota", root: ROOT)

    assert_equal [ [ 1, 0, 2, "K" ], [ 0, 1, 1, "K" ], [ 1, 1, 2, "B" ], [ 3, 1, 1, "K" ] ], art.runs.first(4)
  end

  test "valida tamanho e paleta" do
    PixelArt.find(:insignias, "gota", root: ROOT).validate(size: 4)

    assert_raises(PixelArt::Invalid) { PixelArt.find(:insignias, "gota", root: ROOT).validate(size: 16) }
    error = assert_raises(PixelArt::Invalid) { PixelArt.find(:insignias, "torta", root: ROOT).validate(size: 4) }
    assert_match "4x4", error.message
  end

  test "letra fora da paleta é inválida" do
    art = PixelArt.new(ROOT.join("insignias/torta.txt"), palette: PixelArt.palette(root: ROOT))
    art.instance_variable_set(:@rows, [ ".KK.", "KBZK", "KBBK", ".KK." ])

    error = assert_raises(PixelArt::Invalid) { art.validate(size: 4) }
    assert_match "Z", error.message
  end

  test "memoiza a paleta por root, sem reler o YAML a cada find" do
    first = PixelArt.palette(root: ROOT)
    second = PixelArt.palette(root: ROOT)

    assert_same first, second
  end

  test "arquivo inexistente é inválido" do
    assert_raises(PixelArt::Invalid) { PixelArt.find(:insignias, "nao_existe", root: ROOT) }
  end
end
