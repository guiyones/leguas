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

  test "aba Mapa na navegação" do
    get root_url

    assert_select "nav a[href=?]", map_path(anchor: "atual"), text: "Mapa"
  end
end
