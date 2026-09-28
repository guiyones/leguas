require "test_helper"

class StatHelperTest < ActionView::TestCase
  test "valor em destaque e o resto como unidade" do
    html = Nokogiri::HTML(stat(BigDecimal("5"), total: 28, unit: "km"))

    assert_equal "5", html.at(".stat__value").text
    assert_equal "/ 28 km", html.at(".stat__unit").text
    assert_equal "5 / 28 km", html.at(".stat").text.squish
  end

  test "decimais com vírgula e sem zeros sobrando" do
    html = Nokogiri::HTML(stat(BigDecimal("1.5"), total: BigDecimal("3.0"), unit: "km"))

    assert_equal "1,5 / 3 km", html.at(".stat").text.squish
  end

  test "sem total mostra só a unidade" do
    html = Nokogiri::HTML(stat(25, unit: "XP", prefix: "+", color: :xp))

    assert_equal "+25 XP", html.at(".stat").text.squish
    assert_includes html.at(".stat__value")["class"], "text-xp"
  end
end
