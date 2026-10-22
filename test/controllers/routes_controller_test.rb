require "test_helper"

class RoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :viajante
    @user = users(:viajante)
  end

  test "lista em ordem de distância" do
    @user.routes.create!(name: "Longa", km: 8)
    @user.routes.create!(name: "Curta", km: 2)

    get routes_url

    assert_response :success
    assert_equal [ "Curta", "Longa" ], css_select("[data-route-card] h2").map { it.text.strip }
  end

  test "tempo da rota abre o teclado com separador" do
    get new_route_url

    assert_select "input[name='route[duration]'][inputmode=decimal]"
  end

  test "lista vazia convida a criar" do
    get routes_url

    assert_select "*", text: "Nenhuma rota ainda. Faça um caminho e salve aqui."
    assert_select "a[href=?]", new_route_path, text: "Nova rota"
  end

  test "cria com foto" do
    assert_difference -> { @user.routes.count }, 1 do
      post routes_url, params: { route: { name: "Volta do Guanabara", km: "3,55", duration: "38:51",
        photo: fixture_file_upload("rota_guanabara.png", "image/png") } }
    end

    route = @user.routes.last
    assert_redirected_to routes_url
    assert route.photo.attached?
    assert_equal 2331, route.duration_s
  end

  test "cria com o traçado tirado do print" do
    post routes_url, params: { route: { name: "Volta", km: 3, trace: "[[0,0],[0.5,1],[1,0.2]]" } }

    route = @user.routes.last
    assert_equal [ [ 0, 0 ], [ 0.5, 1 ], [ 1, 0.2 ] ], route.trace
    assert_equal "photo", route.trace_source
  end

  test "traçado que não é json salva a rota sem traçado" do
    assert_difference -> { @user.routes.count }, 1 do
      post routes_url, params: { route: { name: "Volta", km: 3, trace: "não é json" } }
    end

    route = @user.routes.last
    assert_nil route.trace
    assert_nil route.trace_source
  end

  test "editar sem print novo mantém o traçado" do
    route = @user.routes.create!(name: "Volta", km: 3, trace: [ [ 0, 0 ], [ 1, 1 ] ], trace_source: "photo")

    patch route_url(route), params: { route: { name: "Volta nova", trace: "" } }

    assert_equal [ [ 0, 0 ], [ 1, 1 ] ], route.reload.trace
  end

  test "editar com print sem trajeto apaga o traçado antigo" do
    route = @user.routes.create!(name: "Volta", km: 3, trace: [ [ 0, 0 ], [ 1, 1 ] ], trace_source: "photo")

    patch route_url(route), params: { route: { name: "Volta", trace: "[]" } }

    route.reload
    assert_nil route.trace
    assert_nil route.trace_source
  end

  test "não cria sem nome" do
    assert_no_difference -> { Route.count } do
      post routes_url, params: { route: { name: "", km: 3 } }
    end

    assert_response :unprocessable_entity
  end

  test "atualiza" do
    route = @user.routes.create!(name: "Volta", km: 3)

    patch route_url(route), params: { route: { name: "Volta nova", km: "4,2" } }

    assert_redirected_to routes_url
    assert_equal "Volta nova", route.reload.name
    assert_equal BigDecimal("4.2"), route.km
  end

  test "apaga e mantém as caminhadas" do
    route = @user.routes.create!(name: "Volta", km: 3)
    walk = @user.walks.create!(km: 3, walked_on: Date.current, route: route)

    assert_difference -> { Route.count }, -1 do
      delete route_url(route)
    end

    assert_redirected_to routes_url
    assert_nil walk.reload.route_id
  end

  test "rota de outro usuário dá 404" do
    route = users(:novato).routes.create!(name: "Alheia", km: 2)

    get edit_route_url(route)
    assert_response :not_found

    patch route_url(route), params: { route: { name: "X" } }
    assert_response :not_found

    delete route_url(route)
    assert_response :not_found
  end
end
