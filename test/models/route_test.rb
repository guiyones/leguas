require "test_helper"

class RouteTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "nome e km são obrigatórios" do
    assert_not @user.routes.new(km: 3).valid?
    assert_not @user.routes.new(name: "Volta", km: 0).valid?
    assert @user.routes.new(name: "Volta", km: 3).valid?
  end

  test "nome tem até 40 letras" do
    assert @user.routes.new(name: "a" * 40, km: 3).valid?
    assert_not @user.routes.new(name: "a" * 41, km: 3).valid?
  end

  test "aceita vírgula decimal" do
    assert_equal BigDecimal("3.55"), @user.routes.create!(name: "Volta", km: "3,55").reload.km
  end

  test "tempo funciona como o da caminhada" do
    assert_equal 2331, @user.routes.new(duration: "38:51").duration_s
    assert_equal "38:51", @user.routes.new(duration_s: 2331).duration

    route = @user.routes.new(name: "Volta", km: 3, duration: "abc")
    assert_not route.valid?
    assert_includes route.errors[:duration], "não parece um tempo, use 38:51"
  end

  test "trace inválido salva como nil" do
    route = @user.routes.create!(name: "Volta", km: 3, trace: [ [ "a", 1 ] ])

    assert_nil route.reload.trace
  end

  test "trace válido é mantido" do
    route = @user.routes.create!(name: "Volta", km: 3, trace: [ [ 0, 0 ], [ 1, 1 ] ])

    assert_equal [ [ 0, 0 ], [ 1, 1 ] ], route.reload.trace
  end

  test "por distância, depois por nome" do
    longa = @user.routes.create!(name: "Longa", km: 8)
    b = @user.routes.create!(name: "B", km: 3)
    a = @user.routes.create!(name: "A", km: 3)

    assert_equal [ a, b, longa ], @user.routes.by_distance.to_a
  end

  test "apagar a rota mantém a caminhada com os mesmos km" do
    route = @user.routes.create!(name: "Volta", km: 3.55)
    walk = @user.walks.create!(km: 3.55, walked_on: Date.current, route: route)

    route.destroy

    assert_nil walk.reload.route_id
    assert_equal BigDecimal("3.55"), walk.km
  end

  test "rota de outro usuário torna a caminhada inválida" do
    route = users(:novato).routes.create!(name: "Alheia", km: 2)

    assert_not @user.walks.new(km: 2, walked_on: Date.current, route: route).valid?
  end
end
