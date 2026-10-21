require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "HUD com nome, nível, título e xp" do
    get root_url

    assert_select "[data-testid=hud]" do
      assert_select "*", text: /Tião/
      assert_select "*", text: /Nível 1/
      assert_select "*", text: /Caminhante/
    end
  end

  test "fase atual e próximo marco" do
    users(:viajante).walks.create!(km: 5, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Primeiros Passos/
      assert_select "*", text: %r{5 / 90 km}
      assert_select "*", text: /Ponta das Areias/
      assert_select "*", text: /faltam 3 km/
    end
  end

  test "missão do dia com a meta e o feito" do
    users(:viajante).walks.create!(km: 1.5, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=mission]", text: %r{1,5 / 3 km}
  end

  test "missão do dia usa a meta congelada, não a meta atual do viajante" do
    users(:viajante).walks.create!(km: 1, walked_on: Date.current)
    users(:viajante).update!(daily_goal_km: 8)

    get root_url

    assert_select "[data-testid=mission]", text: %r{1 / 3 km}
  end

  test "missão cumprida" do
    users(:viajante).walks.create!(km: 3, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=mission]", text: /Missão cumprida/
  end

  test "botão grande de registrar" do
    get root_url

    assert_select "a[href=?]", new_walk_path, text: "Registrar caminhada"
  end

  test "com o km completo a fase espera o chefe" do
    walk_steady users(:viajante), 100

    get root_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Primeiros Passos/
      assert_select "*", text: %r{90 / 90 km}
    end
  end

  test "fim do mundo conhecido no início" do
    travel_whole_world users(:viajante)

    get root_url

    assert_select "[data-testid=phase]", text: /fim do mundo conhecido/
  end

  test "sugestão da semana pelo km da fase" do
    log_walks users(:viajante), 5, 20

    get root_url

    assert_select "[data-testid=week]", text: /Semana 2 de 4/
    assert_select "[data-testid=week]", text: /Desça prédios de elevador/
    assert_select "[data-testid=boss]", 0
  end

  test "semana leve" do
    log_walks users(:viajante), 30, 30, 15

    get root_url

    assert_select "[data-testid=week]", text: /semana leve/i
  end

  test "foco da fase perto do nome" do
    get root_url

    assert_select "[data-testid=phase]", text: /Criar o hábito/
    assert_no_match(/Chefão:/, response.body)
  end

  test "chefe esperando com km guardados, sem cobrança" do
    walk_steady users(:viajante), 100

    get root_url

    assert_select "[data-testid=boss]", text: /O Primeiro Horizonte/
    assert_select "[data-testid=boss]", text: /Caminhar 12 km sem parar/
    assert_select "[data-testid=boss]", text: /Ele espera o tempo que for preciso/
    assert_select "[data-testid=boss]", text: /10 km guardados/
    assert_select "[data-testid=week]", 0
    assert_select "[data-testid=phase]", text: /Próximo marco/, count: 0
    assert_no_match(/atras|perdeu|falhou|prazo/i, response.body)
  end

  test "chefe esperando sem km guardados" do
    walk_steady users(:viajante), 90

    get root_url

    assert_select "[data-testid=boss]", text: /O Primeiro Horizonte/
    assert_select "[data-testid=boss]", text: /guardados/, count: 0
  end

  test "fim do mundo sem semana nem chefe" do
    travel_whole_world users(:viajante)

    get root_url

    assert_select "[data-testid=week]", 0
    assert_select "[data-testid=boss]", 0
  end

  test "desnível acumulado no total" do
    walk_on users(:viajante), 1, 5
    climb_on users(:viajante), 1, 100

    get root_url

    assert_select "[data-testid=phase]", text: /m subidos/
  end

  test "dica do plano" do
    get root_url

    tips = World.current.regions.first.tips
    assert_select "[data-testid=tip]" do |nodes|
      assert_includes tips, nodes.first.text.strip
    end
  end
end
