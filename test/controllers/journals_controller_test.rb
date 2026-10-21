require "test_helper"

class JournalsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "números da jornada" do
    log_walks users(:viajante), 5, 3

    get journal_url

    assert_response :success
    assert_select "[data-stat=km] .stat__value", "8"
    assert_select "[data-stat=leagues] .stat__value", "1"
    assert_select "[data-stat=missions] .stat__value", "2"
  end

  test "carimbos alcançados com nome e história" do
    log_walks users(:viajante), 10

    get journal_url

    assert_select "summary", text: /Ponta das Areias/ do
      assert_select "img[alt=''][src*='art/stamps/ponta_das_areias']:not([role])"
    end
    assert_select "details", text: /cidade de vento/
  end

  test "marcos não alcançados como ?, sem nome" do
    log_walks users(:viajante), 10
    world = World.current
    current_pending = world.landmarks.find { it.phase.number == 1 && it.at_km > 10 }
    future = world.landmarks.find { it.phase.number > 1 }

    get journal_url

    assert_select ".stamp-unknown", minimum: 1
    assert_select "*", text: /km #{current_pending.at_km.to_i}\b/
    assert_select "*", text: /fase #{future.phase.number}\b/
    assert_no_match current_pending.name, response.body
    assert_no_match future.name, response.body
  end

  test "título da página" do
    get journal_url

    assert_select "title", "Diário · Léguas"
  end

  test "aba e menu levam ao diário" do
    get journal_url
    assert_select "nav[aria-label=?] a.nav-tab--active[href=?]", "Navegação principal", journal_path, text: "Diário"

    get root_url
    assert_select "a[href=?]", journal_path, text: "Diário"
  end
end
