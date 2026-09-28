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
      assert_select "*", text: /Vale das Águas/
      assert_select "*", text: %r{5 / 34 km}
      assert_select "*", text: /Pico do Primeiro Fôlego/
      assert_select "*", text: /faltam 15 km/
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
end
