require "test_helper"

class WalksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "formulário vem com a data de hoje" do
    get new_walk_url

    assert_response :success
    assert_select "input[name='walk[walked_on]'][value=?]", Date.current.iso8601
    assert_select "input[name='walk[km]'][inputmode=decimal]"
  end

  test "registrar mostra o xp ganho" do
    assert_difference -> { users(:viajante).walks.count }, 1 do
      post walks_url, params: { walk: { km: "2", walked_on: Date.current.iso8601 } }
    end

    assert_redirected_to root_url
    assert_equal "+20 XP", flash[:notice]
  end

  test "subir de nível aparece no aviso" do
    post walks_url, params: { walk: { km: "5", walked_on: Date.current.iso8601 } }   # 50 + missão 20 = 70 xp → nível 2

    assert_equal "+70 XP · Nível 2!", flash[:notice]
  end

  test "vencer um marco leva pra celebração" do
    post walks_url, params: { walk: { km: "20", walked_on: Date.current.iso8601 } }

    assert_redirected_to celebration_url
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
    walk = users(:viajante).walks.create!(km: 3, walked_on: Date.current, note: "Parque")

    get walks_url
    assert_select "li", text: /Parque/

    patch walk_url(walk), params: { walk: { km: "4" } }
    assert_redirected_to walks_url
    assert_equal 4, walk.reload.km

    delete walk_url(walk)
    assert_redirected_to walks_url
    assert_not Walk.exists?(walk.id)
  end

  test "não mexe na caminhada de outro viajante" do
    other = users(:novato).walks.create!(km: 1, walked_on: Date.current)

    patch walk_url(other), params: { walk: { km: "9" } }

    assert_response :not_found
  end
end
