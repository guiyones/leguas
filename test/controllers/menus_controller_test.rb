require "test_helper"

class MenusControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "menu é a tela inicial" do
    get root_url

    assert_response :success
    assert_select "a[href=?]", phase_path, text: "Continuar jornada"
    assert_select "a[href=?]", walks_path, text: "Histórico"
    assert_select "a[href=?]", edit_profile_path, text: "Perfil"
    assert_select "nav[aria-label=?]", "Navegação principal", count: 0
  end

  test "título da página" do
    get root_url

    assert_select "title", "Menu · Léguas"
  end

  test "cartão com nível e fase atual" do
    get root_url

    assert_select "*", text: /Primeiros Passos/
    assert_select "*", text: %r{/ 90 km}
    assert_select "[data-testid=menu-card] img[alt=?][src*='art/avatar/portrait']", "Tião"
  end

  test "paisagem do pôr do sol nas Três Torres" do
    get root_url

    assert_select "img[alt=''][src*='art/scenes/menu']:not([role])"
  end

  test "carrega Cinzel e Nunito" do
    get root_url

    assert_select 'link[href*="Cinzel"][href*="Nunito"]'
    assert_select 'link[href*="Press+Start"]', count: 0
  end
end
