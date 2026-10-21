require "test_helper"

class CelebrationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "sem pendência volta pro início" do
    get celebration_url

    assert_redirected_to root_url
  end

  test "sequência: carimbo e depois início" do
    post walks_url, params: { walk: { km: "8", walked_on: Date.current.iso8601 } }

    get celebration_url
    assert_select "h1", text: /Carimbo conquistado/
    assert_select "*", text: /Ponta das Areias/
    assert_select "svg[aria-label=?]", "Carimbo Ponta das Areias"
    post celebration_url, params: { key: "landmark:ponta_das_areias" }
    assert_redirected_to celebration_url

    get celebration_url
    assert_redirected_to root_url
  end

  test "região completa é o fim do mundo conhecido" do
    travel_whole_world users(:viajante)
    user = users(:viajante)
    user.pending_celebration_keys.excluding("region:vento_austral").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /NÍVEL COMPLETO/
    assert_select "*", text: /A Trilha do Vento Austral/
    assert_select "*", text: /810 km/
    assert_select "svg[aria-label=?]", "Patagônia"
    assert_select "*", text: /fim do mundo conhecido/
  end

  test "clique duplo ou chave estranha não quebra" do
    post walks_url, params: { walk: { km: "8", walked_on: Date.current.iso8601 } }

    post celebration_url, params: { key: "landmark:ponta_das_areias" }
    post celebration_url, params: { key: "landmark:ponta_das_areias" }
    post celebration_url, params: { key: "phase:patagonia" }
    post celebration_url, params: { key: "qualquer coisa" }

    assert_redirected_to celebration_url
    assert_equal [ "landmark:ponta_das_areias" ], users(:viajante).celebrations.pluck(:key)
  end
end
