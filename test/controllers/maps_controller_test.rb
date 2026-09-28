require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "mostra as regiões em ordem com a situação de cada uma" do
    log_walks users(:viajante), 20, 10   # 30 km: fase 2 da Costa do Missionário

    get map_url

    assert_response :success
    assert_select "[data-region]", 3
    assert_select "[data-region=costa_do_missionario][data-status=current]"
    assert_select "[data-region=trilha_do_primeiro_raio][data-status=locked]"
    assert_select "[data-region=estrada_da_promessa][data-status=locked]"
  end

  test "fases concluída, atual e futura" do
    log_walks users(:viajante), 20, 10

    get map_url

    assert_select "[data-phase=mirante_do_convento][data-status=completed]" do
      assert_select "svg[aria-label=?]", "Insígnia Mirante do Convento"
      assert_select "*", text: /Convento do Penhasco/   # marco alcançado aparece pelo nome
    end
    assert_select "#atual[data-phase=areias_sem_fim][data-status=current]" do
      assert_select "*", text: %r{5 / 28 km}
      assert_select "*", text: /km 15/                  # Vila do Camarão ainda não alcançada
    end
    assert_select "[data-phase=areias_que_curam][data-status=upcoming]"
  end

  test "região bloqueada não revela fases nem marcos" do
    get map_url

    assert_select "[data-region=trilha_do_primeiro_raio]" do
      assert_select "*", text: /Trilha do Primeiro Raio/
      assert_select "*", text: /\?\?\?/
    end
    assert_no_match(/Vale das Quedas|Vila do Carimbo|Gigante de Pedra/, response.body)
  end

  test "sem caminhadas a primeira fase é a atual" do
    get map_url

    assert_select "#atual[data-phase=mirante_do_convento]", text: %r{0 / 25 km}
    assert_select "*", text: /Vila do Camarão/, count: 0
  end

  test "fronteira de 100 km libera a Região 2" do
    log_walks users(:viajante), 100

    get map_url

    assert_select "[data-region=costa_do_missionario][data-status=completed]"
    assert_select "[data-region=trilha_do_primeiro_raio][data-status=current]"
    assert_select "#atual[data-phase=vale_das_quedas]"
  end

  test "mundo completo não tem fase atual" do
    log_walks users(:viajante), 100, 100, 100, 100, 100, 99

    get map_url

    assert_select "[data-region][data-status=completed]", 3
    assert_select "#atual", 0
  end

  test "aba Mapa na navegação" do
    get root_url

    assert_select "nav a[href=?]", map_path(anchor: "atual"), text: "Mapa"
  end
end
