require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "mostra a região com a situação dela" do
    log_walks users(:viajante), 20, 10

    get map_url

    assert_response :success
    assert_select "[data-region]", 1
    assert_select "[data-region=vento_austral][data-status=current]"
  end

  test "fases concluída, atual e futura" do
    walk_steady users(:viajante), 90, until_days_ago: 2
    walk_on users(:viajante), 1, 12   # derruba O Primeiro Horizonte

    get map_url

    assert_select "[data-phase=primeiros_passos][data-status=completed]" do
      assert_select "svg[aria-label=?]", "Insígnia Primeiros Passos"
      assert_select "*", text: /Ponta das Areias/   # marco alcançado aparece pelo nome
    end
    assert_select "#atual[data-phase=carga_leve][data-status=current]" do
      assert_select "*", text: %r{12 / 115 km}
      assert_select "*", text: /km 20/                # Estrada da Estepe ainda não alcançada
    end
    assert_select "[data-phase=a_subida][data-status=upcoming]"
  end

  test "sem caminhadas a primeira fase é a atual" do
    get map_url

    assert_select "#atual[data-phase=primeiros_passos]", text: %r{0 / 90 km}
    assert_select "*", text: /Estrada da Estepe/, count: 0
  end

  test "mundo completo não tem fase atual" do
    travel_whole_world users(:viajante)

    get map_url

    assert_select "[data-region=vento_austral][data-status=completed]"
    assert_select "#atual", 0
  end

  test "fase com chefe esperando" do
    walk_steady users(:viajante), 100

    get map_url

    assert_select "#atual[data-phase=primeiros_passos][data-status=boss]" do
      assert_select "[data-boss=waiting]", text: /O Primeiro Horizonte/
    end
  end

  test "detalhes da fase mostram foco, chefe, bônus e semanas" do
    user = users(:viajante)
    walk_steady user, 90, until_days_ago: 60
    walk_on user, 59, 15, load_kg: 5
    walk_steady user, 100, until_days_ago: 45
    walk_on user, 44, 15, load_kg: 5

    get map_url

    assert_select "[data-phase=a_subida]" do
      assert_select "*", text: /Ganhar desnível/
      assert_select "[data-boss]", text: /A Torre de Degraus/
      assert_select "*", text: /Pico Agudo/
      assert_select "[data-week]", 4
      assert_select "[data-week='2']", text: /escada: 2× 30 min/
    end
  end

  test "chefe de fase futura fica escondido" do
    get map_url

    assert_select "[data-phase=o_pico] [data-boss=hidden]"
    assert_select "[data-phase=o_pico] [data-boss=hidden]", text: /\?\?\?/
    assert_not_includes response.body, "O Cume"
  end

  test "aba Mapa na navegação" do
    get root_url

    assert_select "nav a[href=?]", map_path(anchor: "atual"), text: "Mapa"
  end
end
