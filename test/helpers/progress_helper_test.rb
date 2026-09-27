require "test_helper"

class ProgressHelperTest < ActionView::TestCase
  test "preenche segmentos proporcionais, arredondando pra baixo" do
    html = segmented_progress(0.46, segments: 10)

    assert_equal 4, Nokogiri::HTML(html).css(".progress-segmented__segment--filled").size
    assert_equal 10, Nokogiri::HTML(html).css(".progress-segmented__segment").size
  end

  test "limita entre 0 e 1" do
    assert_equal 10, Nokogiri::HTML(segmented_progress(1.7)).css(".progress-segmented__segment--filled").size
    assert_equal 0, Nokogiri::HTML(segmented_progress(-1)).css(".progress-segmented__segment--filled").size
  end

  test "expõe o valor pra leitores de tela" do
    assert_includes segmented_progress(0.5), 'aria-valuenow="50"'
  end
end
