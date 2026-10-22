# Rotas e bônus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Caminhadas com tempo, passos e subida; rotas salvas com um mapinha no estilo do jogo gerado a partir do print do Samsung Health; desafios da semana e bônus do dia no lugar da missão que cobra.

**Architecture:**
- `Walk` ganha colunas novas e uma `Route` opcional.
- `Route` guarda o print (Active Storage) e um `trace` JSON normalizado. Quem gera o trace é um controller Stimulus no navegador, e um helper Ruby desenha o SVG a partir dele.
- Os desafios vêm de `challenges` estruturados nas semanas do YAML. O replay de `User::Journey` atribui cada dia à semana em que o viajante estava no começo do dia e calcula progresso, XP e as conquistas `week:<fase>:<n>`, sem gravar nada.

**Tech Stack:** Rails 8.1, Ruby 4.0.6 (`mise exec ruby@4.0.6 --`), SQLite, Hotwire/Stimulus (importmap, `app/frontend/controllers/`), Tailwind 4, Minitest, Selenium. Testes de sistema: `SE_CHROMEDRIVER=/usr/bin/chromedriver`.

**Spec:** `docs/superpowers/specs/2026-10-22-rotas-e-bonus-design.md`

## Global Constraints

- Texto da interface em pt-BR, tom do jogo. Estilo do código: `STYLE.md` (vanilla Rails, `if/else` expandido, sem service objects).
- Progresso, XP, desafios e selos são **calculados** no replay e nunca gravados.
- Nenhuma marca de falha: sem vermelho, sem "não cumprido", sem barra vazia em destaque e sem prazo.
- Bônus nunca movem a posição nem derrubam chefe.
- XP: caminhada do desafio **15** (até N), longão **30**, sessão de escada **15** (até N), semana completa **50**, bônus do dia **`Mission::XP = 20`** (inalterado).
- Ritmo `10'55"/km` e velocidade `5,4 km/h` são calculados, nunca gravados.
- Trace: lista ordenada de `[x, y]` em 0..1, **normalização que preserva a proporção** (divide pelo maior lado da caixa e centraliza o menor), no máximo 300 pontos. Mesma regra em JS e em Ruby.
- O mapinha não usa serviço externo nem mapa de ruas por baixo. Cores só por tokens (`deep`, `panel`, `gold`, `glow`, `muted`).
- Testes de lógica usam o mundo de `test/world/`. Rodar `bin/rails test`, `bin/rails test:system` e `bin/rubocop` verdes ao fim de cada task.

## Review Focus

1. **Dia que cruza a fronteira de semana:** no km 20 da semana 1 (0–22), uma caminhada de 8 km conta pra semana 1. Teste na Task 6.
2. **Chefe esperando:** com o chefe esperando, os dias não contam pra semana nenhuma, e a tela mostra o card do chefe. Teste na Task 6.
3. **Editar ou apagar caminhada:** os desafios e o selo recalculam, e a celebração `week:` some se a semana deixar de estar completa. Isso vem de `forget_unreached_celebrations`. Teste na Task 6.
4. **Tempo digitado de jeitos diferentes:** `38:51`, `1:05:20`, `45` (minutos) e vazio são aceitos; `abc` e `10:75` dão erro de validação, não exceção. Teste na Task 1.
5. **Print que não acha o trajeto** (foto qualquer): a rota salva sem trace e o cartão mostra a arte padrão, sem erro de JS travando o formulário. Testes nas Tasks 3 e 4.

---

### Task 1: Caminhada com tempo, passos e subida

**Files:**
- Create: `db/migrate/*_add_workout_fields_to_walks.rb`
- Modify: `app/models/walk.rb`, `app/controllers/walks_controller.rb`, `app/views/walks/_form.html.erb`, `app/views/walks/index.html.erb`, `test/test_helper.rb`
- Create: `app/helpers/workout_helper.rb`
- Test: `test/models/walk_test.rb`, `test/helpers/workout_helper_test.rb`, `test/controllers/walks_controller_test.rb`

**Interfaces:**
- Produces:
  - Colunas `walks.duration_s` (integer), `walks.steps` (integer) e `walks.elevation_gain_m` (integer), todas nulas.
  - `Walk#duration` (String `"38:51"`/`"1:05:20"` ou nil) e `Walk#duration=(text)`.
  - `Walk#steps=` aceita `"4.507"`.
  - `WorkoutHelper#pace(km, duration_s)` → `"10'55\"/km"` ou nil; `WorkoutHelper#speed(km, duration_s)` → `"5,4 km/h"` ou nil; `WorkoutHelper#duration_text(duration_s)` → `"38:51"`.
  - Helper de teste `walk_on(user, days_ago, km, load_kg: nil, minutes: nil)` (grava `duration_s = minutes * 60`).

- [ ] **Step 1: Testes que falham**
  - `walk_test.rb`:
    - `duration = "38:51"` → `duration_s == 2331`;
    - `"1:05:20"` → 3920;
    - `"45"` → 2700;
    - `""` → nil;
    - `"abc"` e `"10:75"` → inválida, com erro em `:duration` ("não parece um tempo, use 38:51");
    - `steps = "4.507"` → 4507;
    - `elevation_gain_m` negativo é inválido;
    - `duration` lido de volta dá `"38:51"`.
  - `workout_helper_test.rb`:
    - `pace(3.55, 2331) == "10'57\"/km"` (o valor exato vem do cálculo `2331/3.55` s/km, arredondado ao segundo);
    - `speed(3.55, 2331) == "5,5 km/h"` (uma casa, vírgula);
    - nil quando `duration_s` é nil.
  - `walks_controller_test.rb`: POST com `duration: "38:51", steps: "4.507", elevation_gain_m: 32` grava os três valores; o histórico mostra `38:51`, o ritmo e `4.507 passos`.
- [ ] **Step 2:** Rodar `bin/rails test test/models/walk_test.rb test/helpers/workout_helper_test.rb test/controllers/walks_controller_test.rb`. Esperado: FAIL.
- [ ] **Step 3: Implementar**
  - Criar a migração.
  - Em `Walk#duration=`, aceitar `m`, `m:ss` ou `h:mm:ss` (segundos e minutos < 60); texto inválido guarda o texto cru num ivar e a validação reporta.
  - Permitir `:duration, :steps, :elevation_gain_m` nos params.
  - Adicionar ao formulário, depois de "Quando?", três campos: "Tempo (opcional)" (`placeholder: "38:51"`, `inputmode: "numeric"`), "Passos (opcional)" e "Subida em metros (opcional)".
  - No histórico, a legenda da caminhada ganha `· 38:51 · 10'57"/km · 4.507 passos · 32 m de subida`, só com os campos presentes.
- [ ] **Step 4:** Rodar os testes acima e depois `bin/rails test`. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: caminhada guarda tempo, passos e subida`.

### Task 2: Rotas (cadastro, lista, escolher no registro)

**Files:**
- Run: `bin/rails active_storage:install`, depois `db:migrate`. Isso gera a migração e o `config/storage.yml`.
- Create: migração `routes` e `walks.route_id`, `app/models/route.rb`, `app/controllers/routes_controller.rb`, `app/views/routes/{index,new,edit,_form,_route}.html.erb`, `app/frontend/controllers/route_select_controller.js`
- Modify: `config/routes.rb`, `app/models/user.rb`, `app/models/walk.rb`, `app/controllers/walks_controller.rb`, `app/views/walks/_form.html.erb`, `app/views/menus/show.html.erb`, `config/environments/{development,test,production}.rb` (`config.active_storage.service`: `:local` em dev e prod, `:test` em test)
- Test: `test/models/route_test.rb`, `test/controllers/routes_controller_test.rb`, `test/controllers/walks_controller_test.rb`, `test/controllers/menus_controller_test.rb`, `test/system/routes_test.rb`

**Interfaces:**
- Consumes: `Walk#duration=`/`#duration` e `WorkoutHelper` (Task 1).
- Produces:
  - `Route`:
    - `belongs_to :user`, `has_many :walks, dependent: :nullify`, `has_one_attached :photo`;
    - `name` (obrigatório, até 40), `km` (decimal 5,2, > 0, aceita vírgula), `duration_s` (com `duration`/`duration=` iguais aos de `Walk`; extrair a lógica para um concern `HasDuration`), `note`, `trace` (json, nulo), `trace_source` (string, nula; `"photo"` quando há trace);
    - `scope :by_distance` (km crescente e depois nome).
  - `User has_many :routes, dependent: :destroy`.
  - `Walk belongs_to :route, optional: true`, com validação de que a rota é do mesmo usuário.
  - Rotas `resources :routes, except: :show`.
  - Partial `routes/_route` (cartão) com `data-route-card`. Nesta task o lugar do mapa mostra a arte padrão; a Task 3 troca pelo mapinha.

- [ ] **Step 1: Testes que falham**
  - Model:
    - validações;
    - `by_distance`;
    - apagar a rota mantém a caminhada com `route_id` nil e os mesmos km;
    - rota de outro usuário torna a caminhada inválida.
  - Controller:
    - index lista em ordem de distância;
    - create com foto (`fixture_file_upload("rota_guanabara.png", "image/png")`) anexa a foto;
    - update e destroy;
    - rota de outro usuário dá 404.
  - Walks:
    - o form mostra o select "Rota" só quando há rotas, com `data-km` em cada option;
    - create com `route_id` grava a rota;
    - o link "Salvar um caminho novo como rota" aponta para `new_route_path`.
  - Menu: botão "Rotas" → `routes_path`.
  - Sistema: escolher a rota "Volta do Guanabara" (3,55 km) no registro preenche "Quantos km?" com `3.55`, e dá pra trocar o valor antes de salvar.
- [ ] **Step 2:** Rodar esses testes. Esperado: FAIL.
- [ ] **Step 3: Implementar**
  - Rodar o `active_storage:install` e criar a migração `routes` com as colunas acima, mais `references :route, foreign_key: { on_delete: :nullify }` em `walks`.
  - `route_select_controller.js`: no `change` do select, copiar `option.dataset.km` para o campo km.
  - Lista vazia: "Nenhuma rota ainda. Faça um caminho e salve aqui." com o botão "Nova rota".
  - No menu, a grade 2×2 vira 2×3 com "Rotas" na primeira posição.
  - O form da rota tem um file field `photo` (`accept: "image/*"`). O campo do trace entra na Task 4.
- [ ] **Step 4:** Rodar `bin/rails test` e `bin/rails test:system`. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: rotas salvas e escolhidas no registro`.

### Task 3: Mapinha da rota (SVG a partir do trace)

**Files:**
- Create: `app/models/route/trace.rb`, `app/helpers/route_map_helper.rb`, `app/assets/images/art/routes/placeholder.svg`
- Modify: `app/models/route.rb`, `app/views/routes/_route.html.erb`, `app/assets/tailwind/application.css` (se precisar de classe para o mapinha)
- Test: `test/models/route/trace_test.rb`, `test/helpers/route_map_helper_test.rb`, `test/models/route_test.rb`

**Interfaces:**
- Consumes: `Route#trace` e `#km` (Task 2), `WorkoutHelper` (Task 1), `art_tag` (existente).
- Produces:
  - `Route::Trace.normalize(points) → Array<[Float, Float]>`: proporção preservada, idempotente, `[]` para menos de 2 pontos.
  - `Route::Trace.valid?(value)`: Array de 2 a 300 pares numéricos.
  - `Route` valida o `trace` com `Route::Trace.valid?` quando presente; se o trace for inválido, grava nil em vez de dar erro (um trace ruim nunca bloqueia salvar a rota).
  - `RouteMapHelper#route_map(route)` → SVG inline com `viewBox="0 0 200 140"`:
    - fundo `deep` com um degradê pra `panel`;
    - a polilinha do trace (padding de 14) em `gold`, `stroke-width` 4, `stroke-linejoin="round"`, com filtro de brilho em `glow`;
    - um círculo de início no primeiro ponto;
    - `role="img"` e `aria-label="Mapa da rota <nome>"`.
    - Sem trace, devolve `art_tag :routes, :placeholder, label: "Rota <nome>"`.
  - Os ids de `<defs>` levam o id da rota, porque vários mapinhas aparecem na mesma página.

- [ ] **Step 1: Testes que falham**
  - `trace_test`:
    - `normalize([[0,0],[100,0],[100,50],[0,50]]) == [[0,0.25],[1,0.25],[1,0.75],[0,0.75]]`;
    - normalizar duas vezes dá o mesmo resultado;
    - 1 ponto vira `[]`;
    - `valid?` recusa 301 pontos, recusa `[["a",1]]` e recusa um Hash.
  - Helper:
    - com trace, o SVG tem `polyline` com tantos pares quanto o trace e `aria-label` com o nome;
    - sem trace, tem `img[src*='art/routes/placeholder']`;
    - duas rotas na mesma página não repetem ids.
  - Model: um trace inválido salva como nil.
- [ ] **Step 2:** Rodar. Esperado: FAIL.
- [ ] **Step 3: Implementar**
  - `placeholder.svg`: fundo do crepúsculo, uma trilha sinuosa tracejada em `muted` e um marco; ver os SVGs de `art/stamps/` como referência de estilo.
  - O cartão usa `route_map(route)` no topo e, embaixo, nome, km, tempo e ritmo (`pace`), mais os botões Editar e Excluir.
- [ ] **Step 4:** Rodar `bin/rails test`. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: mapinha da rota no estilo do jogo`.

### Task 4: Traçado automático a partir do print

**Files:**
- Create: `app/frontend/controllers/route_trace_controller.js`
- Modify: `app/views/routes/_form.html.erb`, `app/controllers/routes_controller.rb` (params `trace`)
- Test: `test/system/routes_test.rb`, `test/controllers/routes_controller_test.rb`

**Interfaces:**
- Consumes: `Route::Trace` (Task 3), `route[trace]` (string JSON no form, decodificada no controller com `JSON.parse` e com `JSON::ParserError` virando nil).
- Produces:
  - Targets do `route_trace_controller`: `file`, `canvas` (prévia do print, onde dá pra tocar), `preview` (SVG desenhado no JS com o mesmo visual do helper), `field` (hidden `route[trace]`), `retry` (o aviso "Tocar na linha do trajeto").
  - Depois de cada extração, o elemento do controller ganha `data-trace-bounds="minX,minY,maxX,maxY"` em pixels da imagem original e `data-trace-status="ok|empty"`.

**Algoritmo** (o mesmo arquivo; tudo em pixels da imagem original):
1. Carregar o arquivo num `Image` e desenhar num canvas fora da tela, escalado para 360 px de largura (fator `s`).
2. Ignorar os 12% de baixo (faixa de números) e os 9% de cima (logo e data).
3. Máscara padrão: pixel com HSV `s >= 0.55`, `v >= 0.45` e matiz em `[0°, 45°] ∪ [340°, 360°]` (o laranja e o vermelho do trajeto). Com uma cor tocada, a máscara passa a ser a distância RGB `< 70` dessa cor.
4. Grade de células de 4×4 px: a célula fica ligada com ≥ 3 pixels da máscara. Descartar componentes conectados (vizinhança de 8) com menos de 12 células; isso tira texto e manchas.
5. Ordenar: começar pela célula ligada mais perto do canto inferior esquerdo e seguir sempre pra vizinha ligada não visitada mais próxima. Parar quando a mais próxima estiver a mais de 4 células.
6. Simplificar com Ramer–Douglas–Peucker (epsilon de 1 célula) e cortar em 300 pontos.
7. Converter de volta para pixels da imagem original (÷ `s`), calcular os bounds, normalizar com a mesma regra de `Route::Trace.normalize` e gravar o JSON no `field`.
8. Se der menos de 2 pontos: `status=empty`, `field` vazio e o aviso `retry` aparece. Com `status=ok`, o aviso também fica visível, mais discreto: "Saiu errado? Toque na linha do trajeto."
9. Tocar no `canvas` lê a cor do pixel tocado e refaz os passos 3 a 8.

- [ ] **Step 1: Testes que falham** (sistema; `attach_file` no campo "Print do mapa")
  - Anexar `test/fixtures/files/rota_guanabara.png`:
    - `data-trace-status="ok"`;
    - bounds com `minX` em 215±40, `maxX` em 815±40, `minY` em 230±40 e `maxY` em 750±40 (o quadrilátero do Jardim Guanabara; o rio vai até x=0 e y≈85 e ficaria fora dessas faixas);
    - salvar e ver o cartão com `polyline`.
  - Tocar no canvas num ponto da linha (pixel 800,460 da imagem, convertido pra coordenada da tela pela largura exibida): o status continua `ok`.
  - Anexar uma imagem lisa, só cinza (gerar no teste com `ChunkyPNG`, se já estiver no bundle, ou commitar um PNG pequeno em `test/fixtures/files/cinza.png`): `status=empty`, a rota salva e o cartão mostra o placeholder.
  - Controller: `trace: "não é json"` salva a rota com trace nil.
- [ ] **Step 2:** Rodar `bin/rails test:system TEST=test/system/routes_test.rb`. Esperado: FAIL.
- [ ] **Step 3:** Implementar o controller e o form.
  - A prévia no JS replica o SVG do helper: mesmo `viewBox`, padding e cores. As cores vêm de variáveis CSS (`var(--color-gold)`).
  - Se os bounds ficarem fora da faixa por causa das constantes, o implementador ajusta os limiares, mas não os bounds do teste.
- [ ] **Step 4:** Rodar `bin/rails test` e `bin/rails test:system`. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: traçado da rota tirado do print do Samsung Health`.

### Task 5: Desafios estruturados no plano

**Files:**
- Create: `app/models/world/challenge.rb`
- Modify: `app/models/world/week.rb`, `app/models/world/phase.rb` (passa `phase:` para a Week), `config/world/01_vento_austral.yml`, `test/world/01_alpha.yml`
- Test: `test/models/world/week_test.rb` (criar se não existir), `test/models/world_content_test.rb`

**Interfaces:**
- Produces:
  - `World::Challenge = Data.define(:kind, :count, :min_minutes, :km, :load_kg)`:
    - `kind` em `:walks`, `:long_walk` ou `:stairs`;
    - `#label` → "3 caminhadas de 40 min", "Longão de 8 km", "Longão de 15 km com 8 kg", "1 sessão de escada" ou "2 sessões de escada";
    - `#max_xp` → `count*15`, 30 ou `count*15`.
  - `World::Week#challenges` (Array, na ordem walks, long_walk, stairs) e `World::Week#phase`.
  - Uma chave desconhecida em `challenges` levanta `World::Invalid`.

**Valores para o YAML real** (`walks: {count, min_minutes}`, `long_walk: {km, load_kg?}`, `stairs: {count}?`):

| fase | sem | walks | long_walk | stairs |
|---|---|---|---|---|
| primeiros_passos | 1 | 3, 40 | 8 | — |
| primeiros_passos | 2 | 3, 40 | 10 | — |
| primeiros_passos | 3 | 3, 40 | 12 | — |
| primeiros_passos | 4 | 3, 40 | 8 | — |
| carga_leve | 1 | 3, 50 | 12, 4 | 1 |
| carga_leve | 2 | 3, 50 | 14, 4 | 1 |
| carga_leve | 3 | 3, 50 | 15, 5 | 1 |
| carga_leve | 4 | 3, 50 | 12, 4 | 1 |
| a_subida | 1 | 3, 50 | 15, 6 | 1 |
| a_subida | 2 | 3, 50 | 17, 6 | 2 |
| a_subida | 3 | 3, 60 | 18, 7 | 2 |
| a_subida | 4 | 3, 50 | 15, 6 | 1 |
| dois_dias | 1 | 2, 60 | 13, 8 | 2 |
| dois_dias | 2 | 2, 60 | 14, 8 | 2 |
| dois_dias | 3 | 2, 60 | 15, 8 | 2 |
| dois_dias | 4 | 2, 60 | 12, 8 | 2 |
| o_pico | 1 | 2, 60 | 16, 10 | 2 |
| o_pico | 2 | 2, 60 | 17, 10 | 2 |
| o_pico | 3 | 2, 60 | 18, 10 | 2 |
| o_pico | 4 | 2, 60 | 15, 10 | 2 |
| patagonia | 1 | 2, 45 | 15, 8 | 1 |
| patagonia | 2 | 2, 45 | 15, 9 | 1 |
| patagonia | 3 | 2, 45 | 12, 8 | 1 |
| patagonia | 4 | 2, 45 | 10, 8 | — |

**Mundo de teste**, nas 4 semanas de `a2`:

```yaml
challenges: { walks: { count: 2, min_minutes: 40 }, long_walk: { km: 3 } }
```

Na semana 2 de `a2`, acrescentar `stairs: { count: 1 }` e `long_walk: { km: 3, load_kg: 5 }`.

- [ ] **Step 1: Testes que falham**
  - Labels e `max_xp`.
  - `primeiros_passos` semana 1 tem `[walks 3×40, long_walk 8]`.
  - `dois_dias` semana 1 tem long_walk 13 com 8 kg e stairs 2.
  - Toda semana do mundo real tem `walks` e `long_walk`.
  - A chave `foo` em `challenges` levanta `World::Invalid`.
- [ ] **Step 2:** Rodar `bin/rails test test/models`. Esperado: FAIL.
- [ ] **Step 3:** Implementar e preencher os dois YAMLs.
- [ ] **Step 4:** Rodar `bin/rails test`. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: desafios estruturados nas semanas do plano`.

### Task 6: Progresso dos desafios no replay

**Files:**
- Create: `app/models/user/week_progress.rb`
- Modify: `app/models/user/journey.rb`, `app/models/achievement.rb`, `app/models/world.rb` (se precisar de `World#week(phase_key, number)`)
- Create: `app/views/celebrations/_week.html.erb`, `app/assets/images/art/seals/week.svg`
- Test: `test/models/user/journey_test.rb`, `test/models/user/week_progress_test.rb`, `test/models/achievement_test.rb`, `test/controllers/celebrations_controller_test.rb`

**Interfaces:**
- Consumes: `World::Week#challenges`/`#phase` (Task 5), `Walk#duration_s` (Task 1), helper de teste `walk_on(..., minutes:)`.
- Produces:
  - `User::Journey#week_progress(week) → User::WeekProgress`. Dá um progresso vazio se nenhum dia caiu naquela semana.
  - `User::Journey#completed_weeks → Array<World::Week>`, na ordem do mundo.
  - `User::WeekProgress`:
    - `#done(challenge) → Integer`: caminhadas qualificadas até o `count`, 0 ou 1 para o longão, e sessões até o `count`;
    - `#done?(challenge)`, `#complete?`, `#xp` (soma dos desafios + 50 se completa);
    - constantes `WALK_XP = 15`, `LONG_WALK_XP = 30`, `STAIRS_XP = 15`, `COMPLETE_XP = 50`.
  - `Journey#xp` soma o `xp` de todas as semanas.
  - `Journey#achievement_keys` inclui `"week:<phase_key>:<n>"` para cada semana completa, depois das chaves atuais.
  - `Achievement.subject_for("week", "dois_dias:2")` → a `World::Week`.

**Regra de atribuição** (dentro de `replay`, antes de somar os km do dia):
- Calcular `pos = [total_km, gate&.end_km || world.total_km].min`, a posição no começo do dia.
- Se `gate && pos >= gate.end_km`, o chefe está esperando e o dia não tem semana.
- Senão, a fase é a primeira com `pos < phase.end_km`, e a semana é a primeira com `pos - phase.start_km < week.end_km`.
- Guardar `@week_dates[week] << date`. O `WeekProgress` olha os registros do `@log` nessas datas:
  - caminhada qualificada: `duration_s >= min_minutes*60`;
  - longão: `km >= km` e, se pedido, `load_kg >= load_kg`;
  - escada: cada `StairSession`.

- [ ] **Step 1: Testes que falham** (mundo de teste; a fase `a2` começa no km 10 e as semanas têm 5 km)
  - Duas caminhadas de 2 km com 40 min na semana 1 de a2 → `walks` com 2/2. Uma de 39 min não conta, e uma sem tempo também não.
  - Uma caminhada de 3 km com 45 min conta pra `walks` e pro `long_walk`.
  - **Fronteira:** posição no km 14 de manhã (a2, semana 1) e caminhada de 3 km com 40 min → conta pra semana 1, mesmo terminando o dia no km 17.
  - Semana 2 com longão de 3 km sem carga não conta; com `load_kg: 5` conta. Uma sessão de escada → stairs 1/1.
  - Semana 1 completa:
    - `xp` = 2×15 + 30 + 50;
    - `achievement_keys` inclui `week:a2:1`;
    - `completed_weeks` tem a semana 1.
  - **Chefe esperando:** com a2 completa (km 30) e o chefe esperando, caminhadas de 40 min não entram em semana nenhuma.
  - Apagar uma caminhada que fechava a semana: a chave some e `forget_unreached_celebrations` apaga a celebração.
  - `Journey#xp` de um cenário sem desafios fica igual ao de antes (regressão).
  - O controller de celebrações mostra "Semana completa!", o nome da fase e "+50 XP".
- [ ] **Step 2:** Rodar `bin/rails test test/models test/controllers/celebrations_controller_test.rb`. Esperado: FAIL.
- [ ] **Step 3: Implementar**
  - `WeekProgress.new(week, walks:, stair_sessions:)`.
  - `seals/week.svg`: um selo redondo dourado com uma bota, para receber o número da semana sobreposto em HTML.
  - `_week.html.erb`: "Semana completa!", a fase, "Semana N", o selo e `stat 50, unit: "XP", prefix: "+"`.
- [ ] **Step 4:** Rodar `bin/rails test`. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: progresso dos desafios da semana no replay`.

### Task 7: Tela da fase e Diário

**Files:**
- Create: `app/views/phases/_challenges.html.erb`
- Delete: `app/views/phases/_week.html.erb`
- Modify: `app/views/phases/show.html.erb`, `app/controllers/phases_controller.rb`, `app/views/journals/show.html.erb`, `app/controllers/journals_controller.rb`
- Test: `test/controllers/phases_controller_test.rb`, `test/controllers/journals_controller_test.rb`, `test/system/journey_flow_test.rb` (ajustar o que depender da Missão)

**Interfaces:**
- Consumes: `Journey#week_progress`, `WeekProgress`, `Challenge#label`/`#max_xp` e `Journey#completed_weeks` (Task 6).

- [ ] **Step 1: Testes que falham**
  - Fase, mundo real, viajante novo:
    - `[data-testid=challenges]` com o título "Desafios da semana" e o texto "Semana 1 de 4";
    - linhas "3 caminhadas de 40 min" com "0/3" e "Longão de 8 km";
    - `phase.note` presente;
    - "Caminhadas curtas:" ausente.
  - Com uma caminhada de 40 min, a linha mostra "1/3" e um ✓ parcial não é exibido; o ✓ aparece só com `done?`.
  - Desafio cumprido: `[data-done=true]` com "✓" e "+30 XP".
  - Desafio não cumprido: `[data-done=false]` com "☐", sem classe de alerta e sem `text-ember`.
  - `[data-testid=mission]` ausente. `[data-testid=daily-bonus]`:
    - sem caminhada hoje: "Hoje: 0 km · bônus do dia em 3 km" (meta do fixture);
    - com 3,55 km e meta 5: "Hoje: 3,55 km · bônus do dia em 5 km";
    - batendo a meta: "✓ bônus do dia +20 XP".
  - Com o chefe esperando, aparece o card do chefe e não aparece `challenges`.
  - Diário:
    - o stat `missions` vira "bônus do dia";
    - seção "Semanas completas" ausente quando não há nenhuma;
    - com uma semana completa, mostra um selo com "Semana 1" e o nome da fase, e não mostra placeholder de semana não feita.
- [ ] **Step 2:** Rodar. Esperado: FAIL.
- [ ] **Step 3: Implementar**
  - `PhasesController` expõe `@week_progress = @journey.week_progress(@week)` quando há `@week`.
  - A linha do bônus do dia fica logo acima de "Registrar caminhada", com a classe `caption`, e só fica `text-gold` quando cumprida.
  - O km do dia é formatado com `number_with_precision ..., precision: 2, strip_insignificant_zeros: true`.
- [ ] **Step 4:** Rodar `bin/rails test`, `bin/rails test:system` e `bin/rubocop`. Esperado: tudo verde.
- [ ] **Step 5:** Commit `feat: desafios da semana e bônus do dia na tela da fase`.
