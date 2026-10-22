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
      assert_select "img[alt=?][src*='art/insignias/primeiros_passos']", "Insígnia Primeiros Passos"
      assert_select "img[alt=?][src*='art/stamps/ponta_das_areias']", "Carimbo Ponta das Areias"
      assert_select "*", text: /Ponta das Areias/   # marco alcançado aparece pelo nome
    end
    assert_select "#atual[data-phase=carga_leve][data-status=current]" do
      assert_select "*", text: %r{12 / 115 km}
      assert_select "img[alt=?][src*='art/avatar/traveler']", "Tião"
      assert_select "*", text: /km 20/                # Estrada da Estepe ainda não alcançada
      assert_select ".stamp-unknown", text: "?"
      assert_select "img[src*='art/stamps/estrada_da_estepe']", count: 0
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
      assert_select "[data-week='2']" do
        assert_select "dt", text: "Escada"
        assert_select "dd", text: "2× 30 min"
      end
    end
  end

  test "semana sem escada não lista escada" do
    get map_url

    assert_select "[data-phase=primeiros_passos] [data-week='1']" do
      assert_select "*", text: /Trecho 1/
      assert_select "dt", text: "Longão"
      assert_select "dd", text: "8 km"
      assert_select "dt", text: "Escada", count: 0
    end
  end

  test "chefe de fase futura fica escondido" do
    get map_url

    assert_select "[data-phase=o_pico] [data-boss=hidden]"
    assert_select "[data-phase=o_pico] [data-boss=hidden]", text: /\?\?\?/
    assert_not_includes response.body, "O Cume"
  end

  test "mapa do mundo com seis nós" do
    walk_steady users(:viajante), 90, until_days_ago: 2
    walk_on users(:viajante), 1, 12

    get map_url

    assert_select "[data-testid=world]" do
      assert_select "[data-world-phase]", 6
      assert_select "[data-world-phase=primeiros_passos][data-status=completed][href='#fase-primeiros_passos']" do
        assert_select "image[href*='art/insignias/primeiros_passos']"
      end
      assert_select "[data-world-phase=carga_leve][data-status=current]"
      assert_select "[data-world-phase=a_subida][data-status=upcoming]", text: /A Subida/
    end
    assert_select "#fase-a_subida [data-phase=a_subida]"
  end

  test "todo nó tem anel de foco" do
    walk_steady users(:viajante), 40

    get map_url

    assert_select "[data-world-phase] .world-map__focus-ring", 6
  end

  test "nó da fase atual diz você está aqui" do
    walk_steady users(:viajante), 40

    get map_url

    assert_select "[data-world-phase=primeiros_passos][data-status=current]", text: /você está aqui/
    assert_select "[data-world-phase]", text: /você está aqui/, count: 1
  end

  test "chefe esperando faz o nó pulsar" do
    walk_steady users(:viajante), 100

    get map_url

    assert_select "[data-world-phase=primeiros_passos][data-status=boss] .world-map__ember"
  end

  test "fase futura não mostra nome do chefe nem na ilustração" do
    walk_steady users(:viajante), 90, until_days_ago: 2
    walk_on users(:viajante), 1, 12

    get map_url

    assert_match "O Primeiro Horizonte", response.body
    [ "A Torre de Degraus", "Sol e Lua", "O Cume", "O Vento Austral" ].each do |boss|
      assert_no_match boss, response.body
    end
  end

  test "patagônia lendária" do
    get map_url

    assert_select "[data-world-phase=patagonia].world-map__node--legend", text: /Patagônia/
  end

  test "mundo completo mostra todas as fases vencidas" do
    travel_whole_world users(:viajante)

    get map_url

    assert_select "[data-world-phase][data-status=completed]", 6
    assert_select "[data-world-phase]", text: /você está aqui/, count: 0
  end

  test "aba Mapa na navegação" do
    get phase_url

    assert_select "nav a[href=?]", map_path, text: "Mapa"
  end
end
