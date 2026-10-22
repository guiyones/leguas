require "test_helper"

class CelebrationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "sem pendência volta pro início" do
    get celebration_url

    assert_redirected_to phase_url
  end

  test "sequência: carimbo e depois início" do
    post walks_url, params: { walk: { km: "8", walked_on: Date.current.iso8601 } }

    get celebration_url
    assert_select "h1", text: /Carimbo conquistado/
    assert_select "*", text: /Ponta das Areias/
    assert_select "img[alt=?][src*='art/stamps/ponta_das_areias']", "Carimbo Ponta das Areias"
    assert_select "img[alt^='Carimbo']"
    assert_select "button", text: "Continuar"
    post celebration_url, params: { key: "landmark:ponta_das_areias" }
    assert_redirected_to celebration_url

    get celebration_url
    assert_redirected_to phase_url
  end

  test "fase vencida mostra a insígnia" do
    walk_steady users(:viajante), 90, until_days_ago: 1
    walk_on users(:viajante), 0, 12   # derruba O Primeiro Horizonte
    user = users(:viajante)
    user.pending_celebration_keys.excluding("phase:primeiros_passos").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /Chefe derrotado!/
    assert_select "*", text: /Primeiros Passos/
    assert_select "img[alt=?][src*='art/insignias/primeiros_passos']", "Insígnia Primeiros Passos"
  end

  test "título novo mostra o retrato" do
    walk_steady users(:viajante), 90, until_days_ago: 1
    user = users(:viajante)
    user.pending_celebration_keys.excluding("title:andarilho").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /Novo título!/
    assert_select "img[alt=?][src*='art/avatar/portrait']", "Tião"
  end

  test "chefe apareceu antes da insígnia" do
    user = users(:viajante)
    walk_steady user, 90, until_days_ago: 1
    user.pending_celebration_keys.excluding("boss:primeiros_passos").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /Um chefe apareceu!/
    assert_select "*", text: /O Primeiro Horizonte/
    assert_select "*", text: /Caminhar 12 km sem parar/
    assert_select "*", text: /Ele espera o tempo que for preciso/
    assert_select "img[alt=?][src*='art/bosses/primeiros_passos']", "O Primeiro Horizonte"
    assert_select "button", text: "Aceitar o desafio"
    assert_select "button", text: "Continuar", count: 0
    post celebration_url, params: { key: "boss:primeiros_passos" }
    get celebration_url
    assert_redirected_to phase_url
  end

  test "chefe derrotado mostra a insígnia" do
    user = users(:viajante)
    walk_steady user, 90, until_days_ago: 1
    user.pending_celebration_keys.each { user.celebrate(it) }
    walk_on user, 0, 12

    get celebration_url

    assert_select "h1", text: /Chefe derrotado!/
    assert_select "*", text: /Pegada do Viajante/
  end

  test "região completa é o fim do mundo conhecido" do
    travel_whole_world users(:viajante)
    user = users(:viajante)
    user.pending_celebration_keys.excluding("region:vento_austral").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /NÍVEL COMPLETO/
    assert_select "*", text: /A Trilha do Vento Austral/
    assert_select "*", text: /810 km/
    assert_select "img[alt=?][src*='art/insignias/patagonia']", "Patagônia"
    assert_select "*", text: /fim do mundo conhecido/
    assert_select "*", text: /completou o mundo inteiro/, count: 0
  end

  test "semana completa mostra o selo" do
    user = users(:viajante)
    3.downto(1) { walk_on user, it, 3, minutes: 40 }
    walk_on user, 0, 8                            # longão da semana 1
    user.pending_celebration_keys.excluding("week:primeiros_passos:1").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /Trecho completo!/
    assert_select "*", text: /Primeiros Passos/
    assert_select "*", text: /Trecho 1/
    assert_select "img[src*='art/seals/week']"
    assert_select ".stat", text: /\+50\s+XP/
    assert_select "button", text: "Continuar"
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
