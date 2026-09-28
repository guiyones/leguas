require "test_helper"

class CelebrationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "sem pendência volta pro início" do
    get celebration_url

    assert_redirected_to root_url
  end

  test "sequência: carimbo, carimbo, insígnia, e depois início" do
    post walks_url, params: { walk: { km: "34", walked_on: Date.current.iso8601 } }

    get celebration_url
    assert_select "h1", text: /Carimbo conquistado/
    assert_select "*", text: /Pico do Primeiro Fôlego/
    post celebration_url, params: { key: "landmark:pico_do_primeiro_folego" }
    assert_redirected_to celebration_url

    get celebration_url
    assert_select "*", text: /Vinhedos do Vale/
    post celebration_url, params: { key: "landmark:vinhedos_do_vale" }

    get celebration_url
    assert_select "h1", text: /Conquista desbloqueada/
    assert_select "*", text: /Vale das Águas/
    assert_select "svg[aria-label=?]", "Insígnia Vale das Águas"
    post celebration_url, params: { key: "phase:vale_das_aguas" }

    get celebration_url
    assert_redirected_to root_url
  end

  test "chefão tem título próprio" do
    log_walks users(:viajante), 100, 100, 50, 30   # 280 km: passa do Gigante de Pedra (km 250)
    users(:viajante).pending_celebration_keys.excluding("phase:gigante_de_pedra").each { users(:viajante).celebrate(it) }

    get celebration_url

    assert_select "h1", text: /Chefão derrotado/
  end

  test "região completa e título" do
    log_walks users(:viajante), 100, 100, 100, 22   # 322 km: fim da Região 1
    user = users(:viajante)
    user.pending_celebration_keys.excluding("region:estrada_da_promessa", "title:andarilho").each { user.celebrate(it) }

    get celebration_url
    assert_select "h1", text: /NÍVEL COMPLETO/
    assert_select "*", text: /322 km/
    post celebration_url, params: { key: "region:estrada_da_promessa" }

    get celebration_url
    assert_select "h1", text: /Novo título/
    assert_select "*", text: /Andarilho/
  end

  test "clique duplo ou chave estranha não quebra" do
    post walks_url, params: { walk: { km: "20", walked_on: Date.current.iso8601 } }

    post celebration_url, params: { key: "landmark:pico_do_primeiro_folego" }
    post celebration_url, params: { key: "landmark:pico_do_primeiro_folego" }
    post celebration_url, params: { key: "phase:santuario_da_luz" }
    post celebration_url, params: { key: "qualquer coisa" }

    assert_redirected_to celebration_url
    assert_equal [ "landmark:pico_do_primeiro_folego" ], users(:viajante).celebrations.pluck(:key)
  end
end
