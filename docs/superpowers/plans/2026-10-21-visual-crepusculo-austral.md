# Léguas: visual Crepúsculo austral — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de escrever código Rails, carregue o skill `superpowers-ruby:37signals-style`.

**Goal:** Trocar o visual do Léguas inteiro pelo estilo Crepúsculo austral (ilustração vetorial, luz quente), com menu de jogo, tela da fase em mapa, mapa do mundo, Diário, Troféus e toda a arte em SVG.

**Architecture:**
- O que o app calcula e as regras do jogo não mudam.
- Entram rotas novas: `menu` como root, `phase` no lugar de `home`, `journal` e `trophies`.
- O sistema visual vira tokens e componentes em Tailwind 4. As classes atuais (`.panel`, `.btn-game`, `.field`…) mantêm o nome e ganham o estilo novo.
- A arte estática fica em SVGs autocontidos em `app/assets/images/art/` e é renderizada por um helper `art_tag`.
- As cenas com dados (trilha da fase, mapa do mundo e troféu) são partials com SVG inline, montados com o PORO `Trail`, que faz a geometria da trilha.
- `PixelArt` sai.

**Tech Stack:** Rails 8.1, Ruby 4.0.6 (prefixo `mise exec ruby@4.0.6 --`), Minitest, Hotwire, Tailwind 4 (tailwindcss-rails), Propshaft. System tests precisam de `SE_CHROMEDRIVER=/usr/bin/chromedriver`.

**Spec:** `docs/superpowers/specs/2026-10-21-visual-crepusculo-austral-design.md`. Os mockups ficam em `docs/superpowers/specs/assets/2026-10-21-visual/`, e eles são a referência visual (paleta 2 apenas).

## Global Constraints

- Paleta (tokens em `@theme`): `--color-deep #0D1726`, `--color-panel #16263B`, `--color-ridge #1C2E44`, `--color-ridge-2 #132235`, `--color-ridge-3 #0E1A2A`, `--color-sky #29435E`, `--color-horizon #E2A05A`, `--color-ice #CFE3EE`, `--color-lake #5F9BB8`, `--color-text #E8EEF2`, `--color-muted #9FB8C9`, `--color-gold #F2C46D`, `--color-ember #E98A3C`, `--color-glow #FFE6B0`, `--color-legend #B98CFF`. Os tokens antigos (`night`, `ink`, `xp`, `boss`, `cream`, `silhouette`) saem. XP usa gradiente gold→ember e a missão do dia usa `lake`.
- Fontes: **Cinzel** 600/800 (`--font-display`: títulos, nomes de fase, chefe, lugar e logotipo) e **Nunito** 600/700/800 (`--font-body`). Press Start 2P e Jersey 10 saem do layout.
- Sem rosa ou lilás como base, sem contorno preto grosso e sem pixel art.
- Arte: SVG escrito à mão, autocontido (gradientes e filtros dentro do arquivo), `viewBox` sem `width`/`height` fixos, renderizado com `role="img"` e `aria-label`. Formas suaves, gradientes, brilho radial quente e só a paleta acima, mais tons de pele, madeira e couro.
- Avatar único: retrato e viajante conforme `avatar-v3.html` (óculos **redondos**, alça da mochila **curva sobre o ombro**, braço esquerdo segurando o bastão pela empunhadura com o bastão inclinado até o chão).
- Navegação inferior: **Fase · Mapa · Diário · Menu**. O menu não tem barra.
- `prefers-reduced-motion` desliga pulso e brilho animado. Mobile first a 390 px, sem rolagem horizontal.
- Comportamento e regras do jogo sem mudança. Textos em pt-BR, sem linguagem de falha. Estilo `STYLE.md`. Commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, sem push.

## Review Focus

1. **Spoiler no SVG.** A cena da fase e o mapa do mundo não podem trazer no HTML (nem em `<title>` ou `aria-label`) o nome de marcos não alcançados nem de chefes de fases futuras. Teste nas Tasks 6 e 7.
2. **Posições extremas na trilha.** Com 0 km, com o km da fase completo e o chefe esperando, e no fim do mundo, o viajante e os nós ficam dentro do `viewBox`, e a trilha percorrida é vazia ou inteira. Teste na Task 5 (`Trail`) e na Task 6.
3. **Contraste do texto sobre a cena.** Texto nunca fica solto sobre o céu: fica sempre dentro de card ou rótulo com sombra. Conferir por screenshot na Task 10.
4. **Fluxos que mudaram de destino.** Login, onboarding, registrar, editar e excluir terminam no lugar certo: menu depois do login/onboarding, fase depois de registrar, histórico depois de editar ou excluir. Teste na Task 1.
5. **Arte faltando.** Uma chave de conteúdo sem SVG quebra a página. O teste de conteúdo exige todos os arquivos (Tasks 3 e 4).

---

### Task 1: Rotas e navegação (menu, fase)

**Files:**
- Create: `app/controllers/menus_controller.rb`, `app/views/menus/show.html.erb`
- Move: `app/controllers/home_controller.rb` → `app/controllers/phases_controller.rb`, `app/views/home/*` → `app/views/phases/*`, `app/helpers/home_helper.rb` → `app/helpers/phases_helper.rb` (e os testes correspondentes)
- Modify: `config/routes.rb`, `app/controllers/concerns/progress_redirect.rb`, `app/views/layouts/_nav.html.erb`, `app/views/layouts/application.html.erb`
- Test: `test/controllers/menus_controller_test.rb`, `test/controllers/phases_controller_test.rb` (vindo de `home_controller_test.rb`), testes que usam `root_url`

**Interfaces:**
- Produces:
  - rotas `root "menus#show"`, `resource :menu, only: :show`, `resource :phase, only: :show`;
  - `PhasesController#show` (o antigo `HomeController#show`, mesmos ivars);
  - `ProgressRedirect#redirect_after_progress` → `phase_path`;
  - layout com `@hide_nav` respeitado no menu.

- [ ] **Step 1: Testes que falham**
  - `menus_controller_test.rb`:
    - `"menu é a tela inicial"`: `get root_url` → `a[href=?]` `phase_path` com texto "Continuar jornada", mais links "Histórico" (`walks_path`) e "Perfil" (`edit_profile_path`); sem `nav[aria-label="Navegação principal"]`;
    - `"cartão com nível e fase atual"`: texto "Primeiros Passos" e "/ 90 km".
  - Renomeie `home_controller_test.rb` → `phases_controller_test.rb`, trocando `root_url` por `phase_url`.
  - Em `walks_controller_test.rb` e `stair_sessions_controller_test.rb`, registrar redireciona pra `phase_url`; editar e excluir continuam em `walks_url`.
  - `travelers_controller_test.rb` e `sessions_flow_test.rb` continuam indo pro `root_url`, que agora é o menu.
  - `"barra com Fase, Mapa, Diário e Menu"` em `phases_controller_test.rb`: links `phase_path`, `map_path(anchor: "atual")`, `root_path` e o texto "Diário". O link do Diário aponta pra `journal_path` só na Task 8; até lá, `href="#"` com `aria-disabled="true"`.
  - O teste de aba do Mapa em `maps_controller_test.rb` usa `phase_url`.
- [ ] **Step 2: Rodar e ver falhar.** Run: `mise exec ruby@4.0.6 -- bin/rails test` → FAIL
- [ ] **Step 3: Implementar.** O menu usa ainda o estilo atual (o visual vem na Task 2). `celebration#show` sem pendência redireciona pra `phase_path`; atualize o teste. O link "Registrar" sai da barra.
- [ ] **Step 4: Rodar tudo.** Run: `mise exec ruby@4.0.6 -- bin/rails test && SE_CHROMEDRIVER=/usr/bin/chromedriver mise exec ruby@4.0.6 -- bin/rails test:system` → PASS (atualize o system test: depois de entrar, "Continuar jornada")
- [ ] **Step 5: Commit** `feat: menu de jogo como tela inicial e rota da fase`

---

### Task 2: Sistema visual

**Files:**
- Modify: `app/assets/tailwind/application.css`, `app/assets/tailwind/components.css`, `app/views/layouts/application.html.erb`, `app/helpers/progress_helper.rb`, `app/helpers/stat_helper.rb`, todas as views que usam `segmented_progress`, `text-xp` e `text-boss`
- Test: `test/helpers/progress_helper_test.rb`, `test/controllers/menus_controller_test.rb`

**Interfaces:**
- Produces:
  - tokens da paleta;
  - `--font-display` Cinzel e `--font-body` Nunito;
  - componentes: `.panel` (card), `.btn-game`, `.btn-game--secondary`, `.field`, `.caption`, `.eyebrow`, `.stat`, `.progress`, `.glow` (brilho radial atrás de um elemento), `.nav-tab--active`;
  - `progress_bar(fraction, color: :gold | :lake) → <div class="progress progress--gold" role="progressbar" aria-valuenow…>`, que substitui `segmented_progress` (remover).

- [ ] **Step 1: Testes que falham**
  - `progress_helper_test.rb`: `"barra contínua com valor e cor"`, `progress_bar(0.39)` com `aria-valuenow="39"` e classe `progress--gold`; `"limita entre 0 e 1"`.
  - Em `menus_controller_test.rb`: `"carrega Cinzel e Nunito"`, com `link[href*="Cinzel"][href*="Nunito"]` e nenhum `Press+Start`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar o sistema visual conforme a seção "Sistema visual" do spec e os mockups.**
  - Body com fundo `deep` e texto `text`.
  - Cards translúcidos com `backdrop-filter` e borda gold a ~50%.
  - Botão principal com gradiente gold→ember e sombra de degrau.
  - Barra arredondada com brilho.
  - Flash vira card.
  - `theme-color` passa a `#0D1726`.
  - Restyle das telas simples (login, código, boas-vindas, formulários, histórico e perfil) só via componentes, sem mudar marcação além de troca de classe.
  - O menu ganha o layout do mockup `menu-diario-trofeus.html`, com a paisagem como `art_tag` vazio por enquanto: use um gradiente CSS de céu. A paisagem vem na Task 3.
- [ ] **Step 4: Rodar tudo** (test + system) → PASS
- [ ] **Step 5: Commit** `feat: sistema visual Crepúsculo austral`

---

### Task 3: Arte base, avatar único e fim da escolha de avatar

**Files:**
- Create: `app/helpers/art_helper.rb`, `app/assets/images/art/avatar/{portrait,traveler}.svg`, `app/assets/images/art/scenes/menu.svg`
- Create: `db/migrate/*_remove_avatar_from_users.rb`
- Modify: `app/models/user/traveler.rb`, `app/controllers/travelers_controller.rb`, `app/controllers/profiles_controller.rb`, `app/views/travelers/_fields.html.erb`, `app/views/menus/show.html.erb`, `app/views/phases/show.html.erb`, `app/views/maps/_phase.html.erb`, `test/fixtures/users.yml`, `test/system/onboarding_test.rb`, `test/system/journey_flow_test.rb`
- Test: `test/helpers/art_helper_test.rb`, `test/models/user/traveler_test.rb`, `test/controllers/travelers_controller_test.rb`

**Interfaces:**
- Produces:
  - `art_tag(kind, key, label:, size: nil, **options) → <img src="/assets/art/<kind>/<key>-<digest>.svg" role="img" alt=label …>`;
  - `ArtHelper::ROOT = Rails.root.join("app/assets/images/art")`;
  - `art_path_for(kind, key) → Pathname` (pra teste de existência);
  - `users.avatar` removida e `User::Traveler::AVATARS` removido.

- [ ] **Step 1: Testes que falham**
  - `art_helper_test.rb`: `"renderiza svg com rótulo"`, `art_tag(:avatar, :portrait, label: "Tião")` com `img[alt="Tião"][src*="art/avatar/portrait"]`; `"chave sem arquivo levanta erro"` (`ArgumentError`).
  - `traveler_test.rb`: o viajante é válido só com nome e meta, sem avatar.
  - `travelers_controller_test.rb`: o formulário não tem `input[name="user[avatar]"]`.
  - System `onboarding_test.rb`: 2 passos (nome e meta).
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.**
  - Porte o SVG do retrato e do viajante de `docs/superpowers/specs/assets/2026-10-21-visual/avatar-v3.html` para arquivos autocontidos (ids de gradiente únicos por arquivo).
  - Desenhe `scenes/menu.svg` (o pôr do sol com as Três Torres nevadas do mockup do menu).
  - Use o retrato no HUD da fase, no cartão do menu e no perfil, e o viajante no nó atual do mapa.
  - Tire o passo de avatar de `_fields`; o controller de passos continua funcionando com 2 passos.
- [ ] **Step 4: Rodar tudo** → PASS. Rode também `bin/rails db:migrate` em development.
- [ ] **Step 5: Commit** `feat: avatar único em SVG e arte do menu`

---

### Task 4: Arte da trilha e fim do PixelArt

**Files:**
- Create: `app/assets/images/art/insignias/<phase_key>.svg` (6), `app/assets/images/art/stamps/<landmark_key>.svg` (25), `app/assets/images/art/bosses/<phase_key>.svg` (6), `app/assets/images/art/trophies/vento_austral.svg`
- Move: `app/pixel_art/{insignias,stamps,trophies}/<chaves das regiões brasileiras>.txt` e `palette.yml` → `config/world/standby/pixel_art/`
- Delete: `app/models/pixel_art.rb`, `app/helpers/pixel_art_helper.rb`, `test/models/pixel_art_test.rb`, `test/helpers/pixel_art_helper_test.rb`, as grades `.txt` da trilha e dos avatares, `app/pixel_art/`
- Modify: `app/views/maps/_phase.html.erb`, `app/views/celebrations/_{landmark,phase,region,title}.html.erb`, `test/models/world_content_test.rb`

**Interfaces:**
- Consumes: `art_tag` (Task 3).
- Produces: arte em `art/insignias`, `art/stamps`, `art/bosses` e `art/trophies`, indexada pelas chaves do YAML.

- [ ] **Step 1: Teste de conteúdo que falha**
  - Em `world_content_test.rb`, troque os testes de `PixelArt` por `"toda fase tem insígnia e chefe em svg"`, `"todo marco tem carimbo em svg e história"`, `"troféu em svg"` e `"avatar em svg"`.
  - Cada um com `assert art_path_for(kind, key).exist?` e o arquivo começando com `<svg` e contendo `viewBox`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Desenhar.**
  - **Insígnias:** medalhão com aro dourado (gradiente `#FFE0A0`→`#C98A3A`), fundo `sky`, desenho do plano (ver `docs/research/2026-10-21-plano-vento-austral.yml`, campo `desenho`); `patagonia` com aro `legend`.
  - **Carimbos:** selo circular com borda gold tracejada, fundo `panel`/`sky` e o lugar dentro, conforme o nome e a história de cada marco em `config/world/01_vento_austral.yml`.
  - **Chefes:** figura/paisagem do feito, com brilho de brasa:
    - O Primeiro Horizonte: horizonte com sol nascendo;
    - O Fardo do Caminhante: mochila pesada;
    - A Torre de Degraus: escadaria em espiral;
    - Sol e Lua: os dois astros;
    - O Cume: pico com 10 kg de pedra/bandeira;
    - O Vento Austral: as Três Torres no vendaval.
  - **Troféu:** três torres de granito com neve sobre a base de rocha com moldura dourada e 6 encaixes vazios (círculos), pra servir de fundo na Task 9.
  - Use os traços dos mockups de `menu-diario-trofeus.html` como ponto de partida.
- [ ] **Step 4: Trocar os usos e apagar o PixelArt.** Mapa e celebrações passam a usar `art_tag`. Marco não alcançado fica como círculo vazio com "?", em CSS. Mova as grades brasileiras.
- [ ] **Step 5: Rodar tudo** (test + system) → PASS. `grep -rn "PixelArt\|pixel_art" app test` vazio.
- [ ] **Step 6: Commit** `feat: arte da trilha em svg; adeus PixelArt`

---

### Task 5: Geometria da trilha (`Trail`)

**Files:**
- Create: `app/models/trail.rb`
- Test: `test/models/trail_test.rb`

**Interfaces:**
- Produces:
  - `Trail.new(points)`, com `points` sendo `[[x, y], …]` (≥ 2) em coordenadas do `viewBox`;
  - `#point_at(fraction) → [x, y]`: fração do comprimento total, limitada a 0..1, com interpolação linear por segmento;
  - `#path_d(from: 0, to: 1) → String`: SVG `d` do trecho entre as frações, como polilinha suavizada (`M … Q …` com pontos médios). O trecho é construído a partir de `point_at` em amostras, pra que `from`/`to` cortem no lugar certo.
  - `Trail::PHASE` (≈8 pontos, de baixo-esquerda até alto-direita, `viewBox 0 0 280 420`) e `Trail::WORLD` (≈10 pontos serpenteando de baixo pra cima, `viewBox 0 0 280 600`) como constantes.

- [ ] **Step 1: Testes que falham**

```ruby
test "pontas e meio de uma reta" do
  trail = Trail.new([ [ 0, 0 ], [ 100, 0 ] ])
  assert_equal [ 0, 0 ], trail.point_at(0)
  assert_equal [ 50, 0 ], trail.point_at(0.5)
  assert_equal [ 100, 0 ], trail.point_at(1)
end

test "fração fora de 0..1 fica na ponta" do
  trail = Trail.new([ [ 0, 0 ], [ 100, 0 ] ])
  assert_equal [ 0, 0 ], trail.point_at(-1)
  assert_equal [ 100, 0 ], trail.point_at(2)
end

test "comprimento conta por segmento" do
  trail = Trail.new([ [ 0, 0 ], [ 30, 0 ], [ 30, 70 ] ])   # total 100
  assert_equal [ 30, 20 ], trail.point_at(0.5)
end

test "path_d começa no ponto de from" do
  d = Trail.new([ [ 0, 0 ], [ 100, 0 ] ]).path_d(from: 0.25)
  assert_match(/\AM ?25(\.0)?[ ,]0/, d)
end

test "trilhas prontas cabem no viewBox"   # todo ponto de PHASE em 0..280 × 0..420 e de WORLD em 0..280 × 0..600
```

- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar** (números arredondados a 1 casa no `d`).
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `feat: geometria da trilha para as cenas`

---

### Task 6: Tela da fase como mapa

**Files:**
- Create: `app/views/phases/_scene.html.erb`, `app/helpers/scene_helper.rb`
- Modify: `app/views/phases/show.html.erb`, `app/views/phases/_week.html.erb`, `app/views/phases/_boss.html.erb`, `app/assets/tailwind/components.css`
- Test: `test/controllers/phases_controller_test.rb`, `test/helpers/scene_helper_test.rb`

**Interfaces:**
- Consumes: `Trail::PHASE` (Task 5), `art_tag` (Task 3), `Journey#km_in_phase/#phase_progress/#landmark_reached?/#boss_status/#finished?`.
- Produces:
  - `scene_palette(phase) → Hash` (cores de céu e montanha por `phase.number`, 6 variantes dentro da paleta);
  - a cena com `[data-testid=scene]`, `[data-landmark=<key>][data-reached=true|false]`, `[data-scene-boss=hidden|waiting|defeated]` e `[data-traveler]` com atributo `data-fraction` = `journey.phase_progress.to_f.round(2)` (ex.: `0.5`, `0.0`, `1.0`).

- [ ] **Step 1: Testes que falham** (todos em `phases_controller_test.rb`)
  - `"cena da fase com viajante na posição"`: `log_walks` 45 km → `[data-traveler][data-fraction="0.5"]`.
  - `"marcos alcançados com nome, futuros sem nome"`: 10 km → o primeiro marco `data-reached=true` com o nome; os outros `data-reached=false`, e o nome deles não aparece no HTML.
  - `"chefe pulsa quando espera"`: `walk_steady` 100 → `[data-scene-boss=waiting]`.
  - `"zero km: viajante no começo"`: `data-fraction="0.0"`.
  - Os testes atuais de semana, chefe, km guardados, dica, missão, total e fim do mundo continuam passando.
  - `scene_helper_test.rb`: `"seis paletas distintas"`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.**
  - **Cena:** SVG inline (`viewBox 0 0 280 420`) com céu em gradiente, camadas de montanha com as Torres no horizonte (mesmo desenho base de `scenes/menu.svg`, com cores de `scene_palette`), lago e colinas.
  - **Trilha:** `Trail::PHASE` dourada até `phase_progress` e tracejada depois.
  - **Marcos e chefe:** marcos em `point_at(at_km / km)`; chefe em `point_at(1)` com brilho de brasa pulsando quando `:waiting`.
  - **Viajante:** embutido via `<image href="<%= asset_path "art/avatar/traveler.svg" %>">`, com brilho radial atrás.
  - **Layout:** HUD compacto no topo e card da fase embaixo (eyebrow "Fase N de 6 · foco", nome em Cinzel, barra, km), depois semana/chefe, dica, missão e os botões. Layout de `mescla-paletas.html` (paleta 2, tela da fase).
  - **Rótulos** de texto sobre a cena levam sombra de texto (Review Focus 3).
- [ ] **Step 4: Rodar tudo** → PASS
- [ ] **Step 5: Commit** `feat: tela da fase como mapa da fase`

---

### Task 7: Mapa do mundo

**Files:**
- Create: `app/views/maps/_world.html.erb`
- Modify: `app/views/maps/show.html.erb`, `app/views/maps/_phase.html.erb`, `app/views/maps/_region.html.erb`, `app/assets/tailwind/components.css`
- Test: `test/controllers/maps_controller_test.rb`

**Interfaces:**
- Consumes: `Trail::WORLD`, `art_tag`, `Journey#phase_status/#boss_status`.
- Produces:
  - `[data-testid=world]` com um nó por fase `[data-world-phase=<key>][data-status=…]`;
  - `#atual` continua no nó/painel da fase atual;
  - os `<details data-phase>` atuais viram a lista de painéis abaixo da ilustração, mantendo `data-phase`, `data-status`, `data-boss` e `data-week`.

- [ ] **Step 1: Testes que falham**
  - `"mapa do mundo com seis nós"`.
  - `"nó da fase atual diz você está aqui"`.
  - `"fase futura não mostra nome do chefe nem na ilustração"`: `assert_no_match` com os nomes dos chefes das fases futuras.
  - `"patagônia lendária"`: o nó tem a classe de `legend`.
  - Os testes atuais do mapa continuam.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.**
  - **Ilustração:** SVG inline com `viewBox 0 0 280 600` (gradiente de céu, Torres nevadas no topo, lago, colinas em camadas).
  - **Trilha:** `Trail::WORLD` dourada até a fase atual e tracejada depois.
  - **Nós:** em `point_at(i / 5.0)`, cada um com o nome em Cinzel. Vencidas mostram a insígnia pequena; a atual é maior, com brilho; com o chefe esperando, o nó pulsa em brasa; futuras ficam apagadas.
  - **Painel:** tocar num nó leva ao painel (`<details>`) daquela fase, via âncora `#fase-<key>`.
  - Layout: `mescla-paletas.html`, paleta 2, mapa do mundo.
- [ ] **Step 4: Rodar tudo** → PASS
- [ ] **Step 5: Commit** `feat: mapa do mundo ilustrado`

---

### Task 8: Diário

**Files:**
- Create: `app/controllers/journals_controller.rb`, `app/views/journals/show.html.erb`
- Modify: `config/routes.rb`, `app/views/layouts/_nav.html.erb`, `app/views/menus/show.html.erb`
- Test: `test/controllers/journals_controller_test.rb`

**Interfaces:**
- Consumes: `Journey#total_km/#leagues/#climbed_m/#landmark_reached?/#phase_status`, `user.missions.accomplished.count`, `art_tag(:stamps, …)`.
- Produces: `resource :journal, only: :show`. A aba Diário e o botão do menu passam a apontar pra `journal_path`.

- [ ] **Step 1: Testes que falham**
  - `"números da jornada"`: com `log_walks` 5 e 3, aparecem `8` km, `1` légua e `2` missões (meta 3).
  - `"carimbos alcançados com nome e história"`: o primeiro marco, depois de 10 km, mostra `img[alt="Carimbo <nome>"]` e a história em `<details>`.
  - `"marcos não alcançados como ?, sem nome"`: o "km N" da fase atual e "fase N" das futuras; nenhum nome de marco futuro no HTML.
  - `"aba e menu levam ao diário"`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar** conforme `menu-diario-trofeus.html`: card de números e grade de 3 colunas de selos na ordem do caminho.
- [ ] **Step 4: Rodar tudo** → PASS
- [ ] **Step 5: Commit** `feat: diário de carimbos`

---

### Task 9: Troféus e certificado

**Files:**
- Create: `app/controllers/trophies_controller.rb`, `app/views/trophies/show.html.erb`, `app/views/trophies/_trophy.html.erb`
- Modify: `config/routes.rb`, `app/views/menus/show.html.erb`
- Test: `test/controllers/trophies_controller_test.rb`

**Interfaces:**
- Consumes: `Journey#phase_completed?/#phase_status/#boss_defeated_on/#finished?/#total_km`, `user.training_log.dates.first`, `art_tag(:insignias|:trophies, …)`.
- Produces: `resource :trophies, only: :show`, com encaixes `[data-slot=<phase_key>][data-state=filled|current|empty]`.

- [ ] **Step 1: Testes que falham**
  - `"encaixes refletem as fases"`: com a fase 1 vencida (`walk_steady` 90 + `walk_on` 12), `primeiros_passos` fica `filled`, `carga_leve` fica `current` e o resto `empty`.
  - `"insígnia com data do chefe derrotado"`: "Pegada do Viajante" e "Fase 1 vencida · <data em l(:short)>".
  - `"certificado desabilitado antes do fim"`: "ao completar a trilha".
  - `"certificado no fim"`: com `travel_whole_world`, aparecem nome, "A Trilha do Vento Austral", km total, data do primeiro registro e data do último chefe.
  - `"menu leva aos troféus"`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.** `_trophy`: SVG inline com o `trophies/vento_austral.svg` de fundo (`<image>`) e as insígnias como `<image>` nos 6 encaixes. A posição dos encaixes fica numa constante no partial, alinhada com o desenho da Task 4.
- [ ] **Step 4: Rodar tudo** → PASS
- [ ] **Step 5: Commit** `feat: troféus e certificado`

---

### Task 10: Celebrações e conferência final

**Files:**
- Modify: `app/views/celebrations/show.html.erb`, `app/views/celebrations/_{landmark,boss,phase,region,title}.html.erb`, `app/assets/tailwind/components.css`
- Test: `test/controllers/celebrations_controller_test.rb`, `test/system/journey_flow_test.rb`

**Interfaces:**
- Consumes: `art_tag(:stamps|:bosses|:insignias|:trophies, …)`.

- [ ] **Step 1: Testes que falham**
  - Em `celebrations_controller_test.rb`: o chefe que apareceu mostra `img[alt="O Primeiro Horizonte"]` e o botão "Aceitar o desafio"; o carimbo mostra `img[alt^="Carimbo"]`.
  - Os testes atuais de sequência continuam.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.** Tela cheia escura com brilho radial no centro, arte grande, nome em Cinzel e botão principal. "Continuar" nos outros tipos e "Aceitar o desafio" no chefe.
- [ ] **Step 4: Rodar a suíte inteira e o lint.** Run: `mise exec ruby@4.0.6 -- bin/rails test && SE_CHROMEDRIVER=/usr/bin/chromedriver mise exec ruby@4.0.6 -- bin/rails test:system && mise exec ruby@4.0.6 -- bin/rubocop` → tudo PASS
- [ ] **Step 5: Conferir no celular (390 px).**
  - Escreva um system test temporário, sem commit, que tira screenshot do menu, da fase (semana e chefe esperando), do mapa, do diário, dos troféus, de uma celebração e do registrar.
  - Confira que `document.documentElement.scrollWidth <= window.innerWidth` e que nenhum texto fica solto sobre a cena.
  - Corrija o que aparecer e apague o teste.
- [ ] **Step 6: Commit** `feat: celebrações no visual novo`
