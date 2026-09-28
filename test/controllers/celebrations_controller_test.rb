require "test_helper"

class CelebrationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "sem pendência volta pro início" do
    get celebration_url

    assert_redirected_to root_url
  end

  test "sequência: carimbo, carimbo, insígnia, e depois início" do
    post walks_url, params: { walk: { km: "25", walked_on: Date.current.iso8601 } }

    get celebration_url
    assert_select "h1", text: /Carimbo conquistado/
    assert_select "*", text: /Convento do Penhasco/
    post celebration_url, params: { key: "landmark:convento_do_penhasco" }
    assert_redirected_to celebration_url

    get celebration_url
    assert_select "*", text: /Orla da Costa Velha/
    post celebration_url, params: { key: "landmark:orla_da_costa_velha" }

    get celebration_url
    assert_select "h1", text: /Conquista desbloqueada/
    assert_select "*", text: /Mirante do Convento/
    assert_select "svg[aria-label=?]", "Insígnia Mirante do Convento"
    post celebration_url, params: { key: "phase:mirante_do_convento" }

    get celebration_url
    assert_redirected_to root_url
  end

  test "chefão tem título próprio" do
    log_walks users(:viajante), 60   # passa do fim de As Areias Sem Fim (km 53)
    users(:viajante).pending_celebration_keys.excluding("phase:areias_sem_fim").each { users(:viajante).celebrate(it) }

    get celebration_url

    assert_select "h1", text: /Chefão derrotado/
    assert_select "*", text: /As Areias Sem Fim/
  end

  test "região completa mostra a próxima e depois o título" do
    log_walks users(:viajante), 100   # 100 km: fim da Costa do Missionário
    user = users(:viajante)
    user.pending_celebration_keys.excluding("region:costa_do_missionario", "title:andarilho").each { user.celebrate(it) }

    get celebration_url
    assert_select "h1", text: /NÍVEL COMPLETO/
    assert_select "*", text: /100 km/
    assert_select "*", text: /Estrada da Promessa/   # a Task 2 troca pra Trilha do Primeiro Raio
    post celebration_url, params: { key: "region:costa_do_missionario" }

    get celebration_url
    assert_select "h1", text: /Novo título/
    assert_select "*", text: /Andarilho/
  end

  test "clique duplo ou chave estranha não quebra" do
    post walks_url, params: { walk: { km: "4", walked_on: Date.current.iso8601 } }

    post celebration_url, params: { key: "landmark:convento_do_penhasco" }
    post celebration_url, params: { key: "landmark:convento_do_penhasco" }
    post celebration_url, params: { key: "phase:santuario_da_luz" }
    post celebration_url, params: { key: "qualquer coisa" }

    assert_redirected_to celebration_url
    assert_equal [ "landmark:convento_do_penhasco" ], users(:viajante).celebrations.pluck(:key)
  end
end
