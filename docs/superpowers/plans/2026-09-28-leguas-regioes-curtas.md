# Léguas: regiões curtas no começo do mundo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de escrever código Rails, carregue o skill `superpowers-ruby:37signals-style`.

**Goal:** Reorganizar o mundo do MVP em 3 regiões: Costa do Missionário (nova, 4 fases), Trilha do Primeiro Raio (nova, 6 fases) e Estrada da Promessa (já existente, que passa a ser a Região 3).

**Architecture:** A mudança é quase toda de conteúdo. São YAMLs novos em `config/world/` e grades novas em `app/pixel_art/`, e o carregador do mundo já ordena as regiões pelo nome do arquivo. O código muda em dois pontos:
- a `Walk` passa a esquecer celebrações que deixaram de valer também quando uma caminhada é **criada**, o que conserta dados antigos depois de uma reorganização do mundo
- a mensagem de fim do mundo agora avisa que novas regiões virão

Os testes acoplados à Estrada da Promessa como primeira região são atualizados.

**Tech Stack:** Rails 8.1, Ruby 4.0.6 (comandos com prefixo `mise exec ruby@4.0.6 --`), SQLite, Minitest, Capybara + Selenium (Chromium em `/usr/bin/chromium`).

**Spec:** `docs/superpowers/specs/2026-09-25-leguas-design.md`, seções "Mundo, regiões e fases" e "Conteúdo". Pesquisa: `docs/research/2026-09-28-distancias-regioes-curtas.md`.

## Global Constraints

- **Ordem do mundo do MVP:** `01_costa_do_missionario.yml` (4 fases, 100 km), `02_trilha_do_primeiro_raio.yml` (6 fases, 177 km), `03_estrada_da_promessa.yml` (6 fases, 322 km). O total é 599 km.
- **Chefões (rarity: rare, insígnia 20×20):** `areias_sem_fim` (Região 1, fase 2) e `guardiao_do_ceu` (Região 2, fase 6). A Estrada da Promessa continua com `gigante_de_pedra`.
- **Pixel art:** insígnia comum 16×16, rara 20×20, carimbo 12×12 com moldura `K` e fundo `W`. `.` é transparente. Só letras de `app/pixel_art/palette.yml`.
- **Textos:** pt-BR, tom de jogo e sem linguagem de falha. Os nomes das fases e dos marcos são fictícios. A trilha real só aparece em `inspired_by`.
- **Estilo:** o do `STYLE.md`, com `if/else` expandido e `private` indentado.
- **Commits:** Conventional Commits em pt-BR, terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Sem push.
- **Chaves:** todas as chaves de região, fase e marco precisam ser únicas no mundo inteiro, incluindo as da Estrada da Promessa.

## Review Focus

1. **Celebração vista que ficou fora do lugar depois da reorganização.** Quem registrou 34 km antes da mudança já celebrou `phase:vale_das_aguas`. Agora ela fica no km 311 do mundo e não é mais alcançada. A gravação tem que ser apagada pra celebrar de novo quando chegar lá, e isso deve acontecer na próxima caminhada registrada, sem depender de editar nada. Teste na Task 1.
2. **A primeira conquista chega rápido:** o primeiro carimbo sai com 4 km. Testado pela sequência de celebração e pelo teste de sistema da Task 1.
3. **Fim do mundo conhecido:** chegando aos 599 km, o início e a celebração da última região não podem dizer "completou o mundo" como se fosse definitivo. Devem dizer que novas regiões estão a caminho. Teste na Task 2.
4. **Transição entre regiões:** o excedente que passa da Região 1 pra Região 2 cai na fase certa, e a celebração da região mostra a próxima região pelo nome. Teste na Task 1 (celebração) e na Task 2 (início na Região 2).
5. **Arte legível:** 10 insígnias e 15 carimbos novos. O teste de conteúdo garante tamanho e paleta, e uma pessoa confere a aparência pelo `tmp/arte.html`.

---

### Task 1: Costa do Missionário como Região 1

**Files:**
- Rename: `config/world/01_estrada_da_promessa.yml` → `config/world/03_estrada_da_promessa.yml` (`git mv`, sem mudar o conteúdo)
- Create: `config/world/01_costa_do_missionario.yml`
- Create: `app/pixel_art/insignias/{mirante_do_convento,areias_sem_fim,areias_que_curam,chegada_do_missionario}.txt`
- Create: `app/pixel_art/stamps/{convento_do_penhasco,orla_da_costa_velha,vila_do_camarao,lagoas_da_restinga,praia_do_morro_dourado,tres_enseadas,vila_dos_pescadores,praia_dos_navegantes}.txt`
- Modify: `app/models/walk.rb` (callback de esquecer em create também)
- Modify tests: `test/models/world_content_test.rb`, `test/models/user/celebrations_test.rb`, `test/controllers/home_controller_test.rb`, `test/controllers/walks_controller_test.rb`, `test/controllers/celebrations_controller_test.rb`, `test/system/journey_flow_test.rb`

**Interfaces:**
- Consumes: `World.load(World::ROOT)`, que ordena os YAMLs pelo nome do arquivo; `PixelArt.find(kind, key).validate(size:)`; `User#forget_unreached_celebrations`; `log_walks(user, *kms)`; `with_world(world) { }`; `test_world`.
- Produces: `World.current.regions.first.key == "costa_do_missionario"`. As chaves dos marcos, na ordem do caminho, são `convento_do_penhasco` (km 4 do mundo), `orla_da_costa_velha` (10), `vila_do_camarao` (40), `lagoas_da_restinga` (47), `praia_do_morro_dourado` (61), `tres_enseadas` (71), `vila_dos_pescadores` (85) e `praia_dos_navegantes` (92). Os fins de fase ficam nos km 25, 53, 77 e 100.

- [ ] **Step 1: Teste do esquecimento na criação (Review Focus 1)**

Acrescente em `test/models/user/celebrations_test.rb`:

```ruby
  test "registrar caminhada esquece celebração gravada que o mundo não alcança mais" do
    with_world test_world do
      log_walks @user, 12
      @user.pending_celebration_keys.each { |key| @user.celebrate(key) }
      @user.celebrations.create!(key: "phase:b1")   # gravada antes de uma reorganização do mundo

      @user.walks.create!(km: 1, walked_on: Date.current - 1)

      assert_not_includes @user.celebrations.pluck(:key), "phase:b1"
      assert_includes @user.celebrations.pluck(:key), "phase:a1"
    end
  end
```

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/user/celebrations_test.rb`
Expected: FAIL, porque `phase:b1` continua gravada.

- [ ] **Step 2: Esquecer em toda mudança de caminhada**

Em `app/models/walk.rb`, troque

```ruby
  after_commit :forget_unreached_celebrations, on: %i[ update destroy ]
```

por

```ruby
  after_commit :forget_unreached_celebrations
```

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/user/celebrations_test.rb`
Expected: PASS

- [ ] **Step 3: Atualizar o teste de conteúdo (vermelho)**

Em `test/models/world_content_test.rb`, troque os dois primeiros testes por:

```ruby
  test "regiões e número de fases" do
    assert_equal [ [ "costa_do_missionario", 4 ], [ "estrada_da_promessa", 6 ] ], @world.regions.map { [ it.key, it.phases.size ] }
  end

  test "km de cada região" do
    assert_equal 100, @world.region("costa_do_missionario").km
    assert_equal 322, @world.region("estrada_da_promessa").km
  end
```

(A Task 2 insere a Trilha do Primeiro Raio no meio.)

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/world_content_test.rb`
Expected: FAIL (a região `costa_do_missionario` não existe)

- [ ] **Step 4: Renomear a Promessa e criar o YAML da Região 1**

```bash
git mv config/world/01_estrada_da_promessa.yml config/world/03_estrada_da_promessa.yml
```

`config/world/01_costa_do_missionario.yml`:

```yaml
key: costa_do_missionario
name: Costa do Missionário
inspired_by: Passos de Anchieta
trophy_name: Missionário
phases:
  - key: mirante_do_convento
    name: Mirante do Convento
    inspired_by: Vitória → Barra do Jucu
    km: 25
    symbol: convento no alto do morro
    landmarks:
      - key: convento_do_penhasco
        name: Convento do Penhasco
        at_km: 4
        story: >
          Lá no alto de um morro de pedra fica um convento do século XVI. Ele é o destino
          da maior romaria do estado que inspira esta região.
      - key: orla_da_costa_velha
        name: Orla da Costa Velha
        at_km: 10
        story: >
          Uma orla comprida de cidade grande, cheia de gente correndo cedo. A areia ainda
          é fácil de pisar. Aproveita, viajante.

  - key: areias_sem_fim
    name: As Areias Sem Fim
    inspired_by: Barra do Jucu → Setiba
    km: 28
    rarity: rare
    symbol: pegada na areia sob o sol
    landmarks:
      - key: vila_do_camarao
        name: Vila do Camarão
        at_km: 15
        story: >
          Uma vila de pescadores famosa pelos restaurantes de camarão. Boa hora de parar,
          porque o trecho que vem é longo e quase sem sombra.
      - key: lagoas_da_restinga
        name: Lagoas da Restinga
        at_km: 22
        story: >
          Uma restinga protegida, com lagoas escuras de água doce entre a areia e o mato
          baixo. Falta pouco pra vencer as areias.

  - key: areias_que_curam
    name: Praia das Areias que Curam
    inspired_by: Setiba → Meaípe
    km: 24
    symbol: concha brilhando
    landmarks:
      - key: praia_do_morro_dourado
        name: Praia do Morro Dourado
        at_km: 8
        story: >
          As areias escuras desta praia já foram procuradas por quem acreditava que elas
          curavam. A ciência nunca confirmou, mas os banhistas continuam vindo.
      - key: tres_enseadas
        name: Três Enseadas
        at_km: 18
        story: >
          Três praias pequenas, uma colada na outra, com piscinas naturais quando a maré
          baixa.

  - key: chegada_do_missionario
    name: Chegada do Missionário
    inspired_by: Meaípe → Anchieta
    km: 23
    symbol: cajado com cruz
    landmarks:
      - key: vila_dos_pescadores
        name: Vila dos Pescadores
        at_km: 8
        story: >
          Barcos coloridos na areia e rede secando no sol. O missionário que inspira esta
          região passou por muitas vilas assim.
      - key: praia_dos_navegantes
        name: Praia dos Navegantes
        at_km: 15
        story: >
          Pedras, mar aberto e vento. Daqui já dá pra imaginar o santuário no fim da
          estrada.
```

- [ ] **Step 5: Insígnias da Região 1 (4 arquivos)**

Todas com contorno `K`, sem texto e legíveis em 64 px:

| Arquivo | Tamanho | Símbolo | Cores |
|---|---|---|---|
| `mirante_do_convento.txt` | 16×16 | igreja pequena no alto de um morro | morro `S`/`s`, paredes `W`, telhado `M`, cruz `G` |
| `areias_sem_fim.txt` | 20×20 (rara) | pegada na areia com o sol em cima | areia `G`/`g`, pegada `M`/`m`, sol `O`; moldura laranja `O` nas bordas, como `gigante_de_pedra.txt` |
| `areias_que_curam.txt` | 16×16 | concha (vieira) com brilho | concha `W`/`O`, brilho `G` |
| `chegada_do_missionario.txt` | 16×16 | cajado com pequena cruz no topo | cajado `M`/`m`, cruz `G` |

Use `app/pixel_art/insignias/gigante_de_pedra.txt` como referência de moldura rara e `vale_das_aguas.txt` como referência de estilo.

- [ ] **Step 6: Carimbos da Região 1 (8 arquivos, 12×12)**

Todos com moldura `K` na borda, fundo `W` e símbolo simples no miolo (use `app/pixel_art/stamps/pico_do_primeiro_folego.txt` como referência):

| Arquivo | Símbolo |
|---|---|
| `convento_do_penhasco` | igrejinha `W`/`M` sobre pedra `S` (contorno `K` na parede) |
| `orla_da_costa_velha` | linha de prédios `s` sobre faixa de areia `G` |
| `vila_do_camarao` | camarão `O`/`o` |
| `lagoas_da_restinga` | lagoa `B`/`b` com mato `V` |
| `praia_do_morro_dourado` | morro `g` com praia `G` |
| `tres_enseadas` | três arcos de mar `B` |
| `vila_dos_pescadores` | barquinho `R` com vela `W` e contorno `K` |
| `praia_dos_navegantes` | onda `B` batendo em pedra `S` |

- [ ] **Step 7: Rodar o teste de conteúdo**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/world_content_test.rb`
Expected: PASS, com 0 avisos na saída.

- [ ] **Step 8: Atualizar os testes que assumiam a Promessa como primeira região**

`test/controllers/home_controller_test.rb`, teste "fase atual e próximo marco":

```ruby
  test "fase atual e próximo marco" do
    users(:viajante).walks.create!(km: 5, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Mirante do Convento/
      assert_select "*", text: %r{5 / 25 km}
      assert_select "*", text: /Orla da Costa Velha/
      assert_select "*", text: /faltam 5 km/
    end
  end
```

`test/controllers/walks_controller_test.rb` (o primeiro marco agora está no km 4):

```ruby
  test "subir de nível aparece no aviso" do
    post walks_url, params: { walk: { km: "3", walked_on: Date.current.iso8601 } }   # 30 + missão 20 = 50 xp → nível 2

    assert_equal "+50 XP · Nível 2!", flash[:notice]
  end

  test "vencer um marco leva pra celebração" do
    post walks_url, params: { walk: { km: "4", walked_on: Date.current.iso8601 } }

    assert_redirected_to celebration_url
    assert_match(/\A\+\d+ XP/, flash[:notice])
  end
```

(O teste "registrar mostra o xp ganho", com 2 km, continua igual: 2 km não alcança o marco do km 4 e a missão de 3 km não é cumprida.)

`test/controllers/celebrations_controller_test.rb`: substitua os quatro testes que dependem de conteúdo por:

```ruby
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
```

Conferência dos XPs:
- 25 km dá 250 + 2 marcos (50) + fase (100) + missão (20) = 420 XP, nível 4. Nenhum título aparece.
- 100 km dá 1.000 + 8 marcos (200) + 3 fases comuns (300) + chefão (250) + região (500) + missão (20) = 2.270 XP, nível 8. Aparece só o título Andarilho.

`test/system/journey_flow_test.rb`: renomeie o teste pra `"novo viajante entra, caminha 25 km e ganha a primeira insígnia"` e troque o trecho depois de `assert_text "Boa jornada, Nina!"` por:

```ruby
    assert_text "Mirante do Convento"

    click_on "Registrar caminhada", match: :first
    fill_in "Quantos km?", with: "25"
    click_on "Registrar caminhada"

    assert_text "Carimbo conquistado!"
    assert_text "Convento do Penhasco"
    click_on "Continuar"
    assert_text "Orla da Costa Velha"
    click_on "Continuar"
    assert_text "Conquista desbloqueada!"
    assert_text "Mirante do Convento"
    click_on "Continuar"

    assert_text "As Areias Sem Fim"
    assert_text "Missão cumprida!"
```

- [ ] **Step 9: Suíte inteira, sistema e lint**

Run: `mise exec ruby@4.0.6 -- bin/rails test && mise exec ruby@4.0.6 -- bin/rails test:system && mise exec ruby@4.0.6 -- bin/rubocop`
Expected: tudo verde e sem ofensas. Se algum outro teste depender de chaves ou km da Promessa, ajuste-o com a mesma lógica (a primeira região agora é a Costa do Missionário) e descreva no relatório.

- [ ] **Step 10: Consertar os dados de desenvolvimento e gerar a prévia da arte**

```bash
mise exec ruby@4.0.6 -- bin/rails runner 'User.find_each(&:forget_unreached_celebrations)'
mise exec ruby@4.0.6 -- bin/rails runner 'include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper, PixelArtHelper; html = World.current.phases.map { pixel_art_tag(PixelArt.find(:insignias, it.key), size: 96, label: it.name) }.join + World.current.landmarks.map { pixel_art_tag(PixelArt.find(:stamps, it.key), size: 72, label: it.name) }.join; File.write("tmp/arte.html", "<body style=background:#1B1F3B>#{html}</body>")'
```

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "feat: Costa do Missionário como Região 1; Estrada da Promessa vira Região 3

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Trilha do Primeiro Raio como Região 2 e fim do mundo conhecido

**Files:**
- Create: `config/world/02_trilha_do_primeiro_raio.yml`
- Create: `app/pixel_art/insignias/{vale_das_quedas,vale_do_silencio,estacao_esquecida,colinas_do_cafe,portal_da_serra,guardiao_do_ceu}.txt`
- Create: `app/pixel_art/stamps/{vila_do_carimbo,gruta_sagrada,mata_calada,trilhos_antigos,alto_do_jacu,vila_do_portal,acampamento_das_nuvens}.txt`
- Modify: `app/views/home/show.html.erb`, `app/views/celebrations/_region.html.erb` (mensagem de fim)
- Modify tests: `test/models/world_content_test.rb`, `test/controllers/celebrations_controller_test.rb`, `test/controllers/home_controller_test.rb`

**Interfaces:**
- Consumes: tudo da Task 1.
- Produces: o mundo com 3 regiões (`costa_do_missionario`, `trilha_do_primeiro_raio`, `estrada_da_promessa`), 599 km no total. A Trilha começa no km 100 e termina no km 277.

- [ ] **Step 1: Testes vermelhos**

Em `test/models/world_content_test.rb`, substitua os dois primeiros testes por:

```ruby
  test "regiões e número de fases" do
    assert_equal [ [ "costa_do_missionario", 4 ], [ "trilha_do_primeiro_raio", 6 ], [ "estrada_da_promessa", 6 ] ],
      @world.regions.map { [ it.key, it.phases.size ] }
  end

  test "km de cada região e do mundo" do
    assert_equal [ 100, 177, 322 ], @world.regions.map { it.km.to_i }
    assert_equal 599, @world.total_km
  end
```

Em `test/controllers/celebrations_controller_test.rb`, no teste "região completa mostra a próxima e depois o título", troque
`assert_select "*", text: /Estrada da Promessa/   # a Task 2 troca pra Trilha do Primeiro Raio`
por
`assert_select "*", text: /Trilha do Primeiro Raio/`.

Ainda nesse arquivo, acrescente:

```ruby
  test "última região fala do mundo conhecido" do
    log_walks users(:viajante), 100, 100, 100, 100, 100, 99   # 599 km: fim do mundo do MVP
    user = users(:viajante)
    user.pending_celebration_keys.excluding("region:estrada_da_promessa").each { user.celebrate(it) }

    get celebration_url

    assert_select "h1", text: /NÍVEL COMPLETO/
    assert_select "*", text: /fim do mundo conhecido/
    assert_select "*", text: /completou o mundo inteiro/, count: 0
  end
```

Em `test/controllers/home_controller_test.rb`, acrescente:

```ruby
  test "excedente da Região 1 cai na Região 2" do
    log_walks users(:viajante), 100, 10

    get root_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Trilha do Primeiro Raio/
      assert_select "*", text: /Vale das Quedas/
      assert_select "*", text: %r{10 / 44 km}
    end
  end

  test "fim do mundo conhecido no início" do
    log_walks users(:viajante), 100, 100, 100, 100, 100, 99

    get root_url

    assert_select "[data-testid=phase]", text: /fim do mundo conhecido/
  end
```

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/world_content_test.rb test/controllers/celebrations_controller_test.rb test/controllers/home_controller_test.rb`
Expected: FAIL (a região não existe e a mensagem ainda é a antiga)

- [ ] **Step 2: YAML da Região 2**

`config/world/02_trilha_do_primeiro_raio.yml`:

```yaml
key: trilha_do_primeiro_raio
name: Trilha do Primeiro Raio
inspired_by: Caminho da Luz
trophy_name: Primeiro Raio
phases:
  - key: vale_das_quedas
    name: Vale das Quedas
    inspired_by: Tombos → Pedra Dourada
    km: 44
    symbol: cachoeira
    landmarks:
      - key: vila_do_carimbo
        name: Vila do Carimbo
        at_km: 25
        story: >
          Um distrito rural onde os peregrinos do caminho real costumam carimbar a
          credencial. Aqui você ganha o seu carimbo também.
      - key: gruta_sagrada
        name: Gruta Sagrada
        at_km: 35
        story: >
          Uma gruta que os caminhantes tratam como lugar de oração. Fala baixo lá dentro.

  - key: vale_do_silencio
    name: Vale do Silêncio
    inspired_by: Pedra Dourada → Faria Lemos
    km: 25
    symbol: lua sobre a mata
    landmarks:
      - key: mata_calada
        name: Mata Calada
        at_km: 12
        story: >
          Um trecho de mata tão quieto que dá pra ouvir os próprios passos. Os peregrinos
          dizem que é o lugar mais silencioso do caminho.

  - key: estacao_esquecida
    name: Estação Esquecida
    inspired_by: Faria Lemos → Carangola
    km: 23
    symbol: trilho de trem
    landmarks:
      - key: trilhos_antigos
        name: Trilhos Antigos
        at_km: 11
        story: >
          Restos de uma linha de trem centenária que ligava as cidades da região. Hoje o
          mato cobre quase tudo.

  - key: colinas_do_cafe
    name: Colinas do Café
    inspired_by: Carangola → Espera Feliz
    km: 33
    symbol: grão de café
    landmarks:
      - key: alto_do_jacu
        name: Alto do Jacu
        at_km: 20
        story: >
          Um alto de pouco mais de mil metros no meio das fazendas de café. O ar já
          começa a esfriar.

  - key: portal_da_serra
    name: Portal da Serra
    inspired_by: Espera Feliz → Alto Caparaó
    km: 34
    symbol: portal de pedra
    landmarks:
      - key: vila_do_portal
        name: Vila do Portal
        at_km: 20
        story: >
          A última vila antes da serra grande. Daqui pra frente, o caminho é todo subida.

  - key: guardiao_do_ceu
    name: O Guardião do Céu
    inspired_by: Alto Caparaó → cume do Pico da Bandeira
    km: 18
    rarity: rare
    symbol: pico com o sol nascendo
    landmarks:
      - key: acampamento_das_nuvens
        name: Acampamento das Nuvens
        at_km: 9
        story: >
          Um descampado no meio da subida onde muita gente acampa pra chegar ao cume antes
          do sol nascer. É esse primeiro raio que dá nome à trilha.
```

- [ ] **Step 3: Insígnias da Região 2 (6 arquivos)**

| Arquivo | Tamanho | Símbolo | Cores |
|---|---|---|---|
| `vale_das_quedas.txt` | 16×16 | cachoeira caindo de uma pedra | pedra `S`/`s`, água `B`/`b`, espuma `W` |
| `vale_do_silencio.txt` | 16×16 | lua crescente sobre copas de árvore | lua `W`/`G`, mata `V`/`v` |
| `estacao_esquecida.txt` | 16×16 | trilho em perspectiva com dormentes | trilho `S`/`s`, dormentes `M`/`m` |
| `colinas_do_cafe.txt` | 16×16 | grão de café com o sulco no meio | grão `M`/`m`, sulco `K`, brilho `W` |
| `portal_da_serra.txt` | 16×16 | arco de pedra com montanha ao fundo | pedra `S`/`s`, montanha `v` |
| `guardiao_do_ceu.txt` | 20×20 (rara) | pico com o sol nascendo atrás | pico `S`/`s`, neve `W`, sol `G`/`O`; moldura laranja `O` nas bordas |

- [ ] **Step 4: Carimbos da Região 2 (7 arquivos, 12×12, moldura `K`, fundo `W`)**

| Arquivo | Símbolo |
|---|---|
| `vila_do_carimbo` | carimbo de borracha `M` com marca `R` |
| `gruta_sagrada` | boca de gruta `s`/`K` com vela `G` |
| `mata_calada` | três árvores `V`/`v` |
| `trilhos_antigos` | trilho `S` com mato `V` |
| `alto_do_jacu` | colina `v` com pés de café `V` e grãos `R` |
| `vila_do_portal` | casinha `R`/`W` com montanha `S` atrás |
| `acampamento_das_nuvens` | barraca `O` com nuvem `B`/`W` |

- [ ] **Step 5: Mensagem de fim do mundo conhecido**

Em `app/views/home/show.html.erb`, troque

```erb
    <p class="text-gold">Você completou o mundo, viajante!</p>
```

por

```erb
    <p class="text-gold">Você chegou ao fim do mundo conhecido, viajante! Novas regiões estão a caminho.</p>
```

Em `app/views/celebrations/_region.html.erb`, troque

```erb
  <p>Você completou o mundo inteiro, viajante.</p>
```

por

```erb
  <p>Você chegou ao fim do mundo conhecido, viajante. Novas regiões estão a caminho.</p>
```

- [ ] **Step 6: Rodar os testes**

Run: `mise exec ruby@4.0.6 -- bin/rails test && mise exec ruby@4.0.6 -- bin/rails test:system && mise exec ruby@4.0.6 -- bin/rubocop`
Expected: tudo verde, sem avisos e sem ofensas.

- [ ] **Step 7: Regenerar a prévia e consertar os dados de desenvolvimento**

Rode de novo os dois comandos do Step 10 da Task 1 (o `forget_unreached_celebrations` e a geração de `tmp/arte.html`).

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: Trilha do Primeiro Raio como Região 2 e aviso de fim do mundo conhecido

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
