require "test_helper"

class WalksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "formulário vem com a data de hoje" do
    get new_walk_url

    assert_response :success
    assert_select "input[name='walk[walked_on]'][value=?]", Date.current.iso8601
    assert_select "input[name='walk[km]'][inputmode=decimal]"
    assert_select "input[name='walk[duration]']", 0
    assert_select "input[name='walk[duration_hours]'][inputmode=numeric]"
    assert_select "input[name='walk[duration_minutes]'][inputmode=numeric]"
    assert_select "input[name='walk[duration_seconds]'][inputmode=numeric]"
    assert_select ".duration-field__unit", %w[h min s].size
  end

  test "registrar mostra o xp ganho" do
    assert_difference -> { users(:viajante).walks.count }, 1 do
      post walks_url, params: { walk: { km: "2", walked_on: Date.current.iso8601 } }
    end

    assert_redirected_to phase_url
    assert_equal "+20 XP", flash[:notice]
  end

  test "subir de nível aparece no aviso" do
    post walks_url, params: { walk: { km: "3", walked_on: Date.current.iso8601 } }   # 30 + missão 20 = 50 xp → nível 2

    assert_equal "+50 XP · Nível 2!", flash[:notice]
  end

  test "vencer um marco leva pra celebração" do
    walk_on users(:viajante), 1, 14
    post walks_url, params: { walk: { km: "8", walked_on: Date.current.iso8601 } }   # km 22: Ponta das Areias

    assert_redirected_to celebration_url
    assert_match(/\A\+\d+ XP/, flash[:notice])
  end

  test "caminhada inválida volta com erro" do
    post walks_url, params: { walk: { km: "0", walked_on: Date.current.iso8601 } }

    assert_response :unprocessable_entity
    assert_select ".field-error"
  end

  test "editar caminhada de 10 dias atrás não bloqueia o campo de data" do
    walk = users(:viajante).walks.create!(km: 3, walked_on: Date.current)

    travel 10.days do
      get edit_walk_url(walk)

      assert_response :success
      assert_select "input[name='walk[walked_on]'][min=?]", walk.walked_on.iso8601
    end
  end

  test "histórico lista, edita e exclui" do
    walk = users(:viajante).walks.create!(km: 1, walked_on: Date.current, note: "Parque")

    get walks_url
    assert_select "li", text: /Parque/

    patch walk_url(walk), params: { walk: { km: "2" } }
    assert_redirected_to walks_url
    assert_equal 2, walk.reload.km

    delete walk_url(walk)
    assert_redirected_to walks_url
    assert_not Walk.exists?(walk.id)
  end

  test "caminhada com mochila" do
    post walks_url, params: { walk: { km: "2", walked_on: Date.current.iso8601, load_kg: "5" } }

    assert_equal 5, users(:viajante).walks.last.load_kg
  end

  test "novo tem link pra escada" do
    get new_walk_url

    assert_select "a[href=?]", new_stair_session_path, text: /Registrar escada/
  end

  test "histórico mistura caminhadas e escada" do
    walk = users(:viajante).walks.create!(km: 1, walked_on: Date.current - 1, note: "Parque")
    stair = users(:viajante).stair_sessions.create!(climbs: 3, climbed_on: Date.current, note: "Prédio")

    get walks_url

    assert_select "section li", 2
    assert_select "section li:first-child", text: /Prédio/
    assert_select "section li:first-child a[href=?]", edit_stair_session_path(stair), text: "Editar"
    assert_select "section li:last-child a[href=?]", edit_walk_path(walk), text: "Editar"
  end

  test "não mexe na caminhada de outro viajante" do
    other = users(:novato).walks.create!(km: 1, walked_on: Date.current)

    patch walk_url(other), params: { walk: { km: "9" } }

    assert_response :not_found
  end

  test "registrar guarda tempo, passos e subida e o histórico mostra" do
    post walks_url, params: { walk: { km: "3,55", walked_on: Date.current.iso8601, duration_hours: "", duration_minutes: "38", duration_seconds: "51", steps: "4.507", elevation_gain_m: 32 } }

    walk = users(:viajante).walks.order(:id).last
    assert_equal [ 2331, 4507, 32 ], [ walk.duration_s, walk.steps, walk.elevation_gain_m ]

    get walks_url
    assert_match "38:51", response.body
    assert_match "10&#39;57&quot;/km", response.body
    assert_match "4.507 passos", response.body
    assert_match "32 m de subida", response.body
  end

  test "formulário sem rotas não mostra o select, mas convida a salvar uma" do
    get new_walk_url

    assert_select "select[name='walk[route_id]']", count: 0
    assert_select "a[href=?]", new_route_path, text: "Salvar um caminho novo como rota"
  end

  test "formulário com rotas mostra o select com km em cada opção" do
    route = users(:viajante).routes.create!(name: "Volta do Guanabara", km: "3,55")
    users(:novato).routes.create!(name: "Alheia", km: 2)

    get new_walk_url

    assert_select "label", text: "Rota"
    assert_select "select[name='walk[route_id]'] option", count: 2
    assert_select "select[name='walk[route_id]'] option[value=?][data-km=?]", route.id.to_s, "3.55", text: "Volta do Guanabara (3,55 km)"
    assert_select "a[href=?]", new_route_path, text: "Salvar um caminho novo como rota"
  end

  test "rota com tempo leva o tempo na opção, sem tempo não" do
    timed = users(:viajante).routes.create!(name: "Volta longa", km: 8, duration: "1:31:20")
    untimed = users(:viajante).routes.create!(name: "Volta curta", km: 2)

    get new_walk_url

    assert_select "option[value=?][data-duration-s=?]", timed.id.to_s, "5480"
    assert_select "option[value=?][data-duration-s]", untimed.id.to_s, 0
  end

  test "registrar com rota grava a rota" do
    route = users(:viajante).routes.create!(name: "Volta", km: 3.55)

    post walks_url, params: { walk: { km: "3,55", walked_on: Date.current.iso8601, route_id: route.id } }

    assert_equal route, users(:viajante).walks.order(:id).last.route
  end

  test "rota de outro usuário não vale" do
    route = users(:novato).routes.create!(name: "Alheia", km: 2)

    assert_no_difference -> { Walk.count } do
      post walks_url, params: { walk: { km: 2, walked_on: Date.current.iso8601, route_id: route.id } }
    end

    assert_response :unprocessable_entity
  end
end
