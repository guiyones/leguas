require "test_helper"

class PhasesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "título da página" do
    get phase_url

    assert_select "title", "Fase · Léguas"
  end

  test "HUD com nome, nível, título e xp" do
    get phase_url

    assert_select "[data-testid=hud]" do
      assert_select "*", text: /Tião/
      assert_select "*", text: /Nível 1/
      assert_select "*", text: /Caminhante/
      assert_select "img[alt=?][src*='art/avatar/portrait']", "Tião"
    end
  end

  test "fase atual e próximo marco" do
    users(:viajante).walks.create!(km: 5, walked_on: Date.current)

    get phase_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Primeiros Passos/
      assert_select "*", text: %r{5 / 90 km}
      assert_select "*", text: /Ponta das Areias/
      assert_select "*", text: /faltam 3 km/
    end
  end

  test "perto do fim da fase, avisa quando o chefe aparece" do
    walk_steady users(:viajante), 80

    get phase_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /O chefe da fase aparece em 10 km/
      assert_select "*", text: /Próximo marco: Primeiros Passos/, count: 0
    end
  end

  test "região sem dicas esconde o painel de dica" do
    with_world test_world do
      walk_steady users(:viajante), 30, until_days_ago: 6
      walk_on users(:viajante), 5, 12               # derruba a2: Região Beta, sem dicas

      get phase_url
    end

    assert_select "[data-testid=phase]", text: /Fase B1/
    assert_select "[data-testid=tip]", 0
  end

  test "fase lendária com o nome em cor de lenda" do
    with_world test_world do
      walk_steady users(:viajante), 30, until_days_ago: 20
      walk_on users(:viajante), 19, 12
      walk_steady users(:viajante), 18, until_days_ago: 16
      climb_on users(:viajante), 15, 12             # derruba b1: chega em B2, lendária

      get phase_url
    end

    assert_select "[data-testid=phase] h2.text-legend", text: "Fase B2"
  end

  test "missão do dia com a meta e o feito" do
    users(:viajante).walks.create!(km: 1.5, walked_on: Date.current)

    get phase_url

    assert_select "[data-testid=mission]", text: %r{1,5 / 3 km}
  end

  test "missão do dia usa a meta congelada, não a meta atual do viajante" do
    users(:viajante).walks.create!(km: 1, walked_on: Date.current)
    users(:viajante).update!(daily_goal_km: 8)

    get phase_url

    assert_select "[data-testid=mission]", text: %r{1 / 3 km}
  end

  test "missão cumprida" do
    users(:viajante).walks.create!(km: 3, walked_on: Date.current)

    get phase_url

    assert_select "[data-testid=mission]", text: /Missão cumprida/
  end

  test "botão grande de registrar" do
    get phase_url

    assert_select "a[href=?]", new_walk_path, text: "Registrar caminhada"
  end

  test "botão de registrar escada" do
    get phase_url

    assert_select "a.btn-game--secondary[href=?]", new_stair_session_path, text: "Registrar escada"
  end

  test "com o km completo a fase espera o chefe" do
    walk_steady users(:viajante), 100

    get phase_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Primeiros Passos/
      assert_select "*", text: %r{90 / 90 km}
    end
  end

  test "fim do mundo conhecido no início" do
    travel_whole_world users(:viajante)

    get phase_url

    assert_select "[data-testid=phase]", text: /fim do mundo conhecido/
  end

  test "sugestão da semana pelo km da fase" do
    log_walks users(:viajante), 5, 20

    get phase_url

    assert_select "[data-testid=week]", text: /Semana 2 de 4/
    assert_select "[data-testid=week]", text: /Desça prédios de elevador/
    assert_select "[data-testid=boss]", 0
  end

  test "semana leve" do
    log_walks users(:viajante), 30, 30, 15

    get phase_url

    assert_select "[data-testid=week]", text: /semana leve/i
  end

  test "foco da fase perto do nome" do
    get phase_url

    assert_select "[data-testid=phase]", text: /Criar o hábito/
    assert_no_match(/Chefão:/, response.body)
  end

  test "chefe esperando com km guardados, sem cobrança" do
    walk_steady users(:viajante), 100

    get phase_url

    assert_select "[data-testid=boss]", text: /O Primeiro Horizonte/
    assert_select "[data-testid=boss]", text: /Caminhar 12 km sem parar/
    assert_select "[data-testid=boss]", text: /Ele espera o tempo que for preciso/
    assert_select "[data-testid=boss]", text: /10 km guardados/
    assert_select "[data-testid=boss] img[alt=?][src*='art/bosses/primeiros_passos']", "O Primeiro Horizonte"
    assert_select "[data-testid=week]", 0
    assert_select "[data-testid=phase]", text: /Próximo marco/, count: 0
    assert_no_match(/atras|perdeu|falhou|prazo/i, response.body)
  end

  test "chefe esperando sem km guardados" do
    walk_steady users(:viajante), 90

    get phase_url

    assert_select "[data-testid=boss]", text: /O Primeiro Horizonte/
    assert_select "[data-testid=boss]", text: /guardados/, count: 0
  end

  test "fim do mundo sem semana nem chefe" do
    travel_whole_world users(:viajante)

    get phase_url

    assert_select "[data-testid=week]", 0
    assert_select "[data-testid=boss]", 0
  end

  test "desnível acumulado no total" do
    walk_on users(:viajante), 1, 5
    climb_on users(:viajante), 1, 100

    get phase_url

    assert_select "[data-testid=phase]", text: /m subidos/
  end

  test "dica do plano" do
    get phase_url

    tips = World.current.regions.first.tips
    assert_select "[data-testid=tip]" do |nodes|
      assert_includes tips, nodes.first.text.strip
    end
  end

  test "barra com Fase, Mapa, Diário e Menu" do
    get phase_url

    assert_select "nav[aria-label=?]", "Navegação principal" do
      assert_select "a[href=?]", phase_path
      assert_select "a[href=?]", map_path
      assert_select "a[href=?]", root_path
      assert_select "a[href=?]", journal_path, text: "Diário"
      assert_select "a", text: "Registrar", count: 0
    end
  end

  test "cena da fase com viajante na posição" do
    log_walks users(:viajante), 45

    get phase_url

    assert_select "[data-testid=scene] [data-traveler][data-fraction=?]", "0.5"
  end

  test "zero km: viajante no começo" do
    get phase_url

    assert_select "[data-testid=scene] [data-traveler][data-fraction=?]", "0.0"
  end

  test "marcos alcançados com nome, futuros sem nome" do
    log_walks users(:viajante), 10

    get phase_url

    assert_select "[data-testid=scene]" do
      assert_select "[data-landmark=ponta_das_areias][data-reached=true]", text: /Ponta das Areias/
      assert_select "[data-reached=false]", 3
      assert_select "[data-landmark=estreito_do_navegante]", text: /\?\?\?/
      assert_select "*", text: /Estreito do Navegante/, count: 0
    end
    assert_no_match(/Forte do Estreito|Ilha dos Pinguins/, response.body)
  end

  test "chefe pulsa quando espera" do
    walk_steady users(:viajante), 100

    get phase_url

    assert_select "[data-testid=scene] [data-scene-boss=waiting]", text: /Chefe/
    assert_no_match(/#\h{6}/, css_select("[data-testid=scene]").to_s)
  end

  test "chefe escondido na cena sem o nome" do
    get phase_url

    assert_select "[data-testid=scene] [data-scene-boss=hidden]" do
      assert_select "*", text: /O Primeiro Horizonte/, count: 0
    end
  end
end
