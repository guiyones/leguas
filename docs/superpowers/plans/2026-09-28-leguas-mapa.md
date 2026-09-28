# Léguas: tela do Mapa — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de escrever código Rails, carregue o skill `superpowers-ruby:37signals-style`.

**Goal:** Uma aba **Mapa** que mostra, numa tela só e em trilha vertical, todas as regiões e fases do mundo com o progresso do viajante.

**Architecture:** `User::Journey` ganha três perguntas de status: situação da região, situação da fase e se um marco foi alcançado. Assim a view não repete as regras de km. `MapsController#show` só expõe a jornada. A view desenha a trilha com HTML e CSS, usando `<details>` pra abrir cada fase sem JavaScript. A navegação inferior passa a ter 4 itens.

**Tech Stack:** Rails 8.1, Ruby 4.0.6 (comandos com prefixo `mise exec ruby@4.0.6 --`), Minitest, Tailwind 4.

**Spec:** `docs/superpowers/specs/2026-09-25-leguas-design.md`, tabela "Telas e rotas" (linha **Mapa**) e "Estilo visual" (parágrafo **Mapa**).

## Global Constraints

- Rota: `resource :map, only: :show` (`/map`), com login e onboarding exigidos como o resto do app.
- **Situação da região:**
  - `:completed` quando `region.end_km <= total_km`
  - senão `:current` se for a região da fase atual
  - senão `:locked`
- **Situação da fase:**
  - `:completed` quando `phase.end_km <= total_km`
  - senão `:current` se for a fase atual
  - senão `:upcoming`
- **Marco alcançado:** `landmark.world_km <= total_km`.
- **Região bloqueada:** mostra número, nome e km, e cada fase aparece como "???" com silhueta genérica. Nada do nome, da insígnia, do trecho real ou dos marcos dela aparece.
- **Marco não alcançado** numa região liberada: aparece como "???" com o km dentro da fase.
- **Fase atual:** tem `id="atual"` e fica aberta. A aba Mapa aponta pra `map_path(anchor: "atual")`.
- **Visual:** linha contínua dourada até a fase atual e tracejada depois dela. O chefão tem nó maior com borda laranja.
- **Números:** use o helper `stat(value, unit:, total:, prefix:, color:)`. Todo texto de apoio usa a classe `caption`, e nada fica abaixo de `text-[0.7rem]` em Press Start 2P.
- Textos em pt-BR, sem linguagem de falha, com estilo `STYLE.md`. Commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, sem push.

## Review Focus

1. **Fronteira exata.** Com exatamente 100 km, a Costa do Missionário está concluída e a Trilha do Primeiro Raio é a atual, na fase 1 com 0 km. Nenhuma região deve aparecer como atual e bloqueada ao mesmo tempo. Teste na Task 1 (mundo de teste, 30 km) e na Task 2 (100 km no mundo real).
2. **Mundo completo.** Com 599 km, as 3 regiões aparecem concluídas e nenhuma fase tem `id="atual"`. Como a jornada devolve a última fase como "atual", o status `:completed` tem que vencer. Teste nas Tasks 1 e 2.
3. **Spoiler.** O HTML de uma região bloqueada não pode conter o nome das fases nem dos marcos dela. Teste na Task 2.
4. **Viajante sem caminhadas.** Com 0 km, a primeira fase é a atual, com 0 / 25 km, e o resto aparece como futuro ou bloqueado. Teste na Task 2.
5. **Legibilidade no celular (390 px).** A trilha não pode estourar a largura e os números usam `stat`. Isso se confere por screenshot na Task 2.

---

### Task 1: Status de região, fase e marco na jornada

**Files:**
- Modify: `app/models/user/journey.rb`
- Test: `test/models/user/journey_test.rb`

**Interfaces:**
- Consumes: `World::Region#end_km`, `World::Phase#end_km`, `World::Landmark#world_km`, `User::Journey#current_phase`, `#current_region`, `#total_km`.
- Produces: `User::Journey#region_status(region)` → `:completed | :current | :locked`; `#phase_status(phase)` → `:completed | :current | :upcoming`; `#landmark_reached?(landmark)` → Boolean.

- [ ] **Step 1: Testes (mundo de teste: alpha 0–30 km com a1 0–10 e a2 10–30; beta 30–100 com b1 30–60 e b2 60–100; marcos a1_mark no km 4, a2_mark no 15 e b2_mark no 70)**

Acrescente em `test/models/user/journey_test.rb`:

```ruby
  test "status no meio da primeira região" do
    log_walks @user, 12
    journey = @user.journey(world: @world)

    assert_equal :current, journey.region_status(@world.region("alpha"))
    assert_equal :locked, journey.region_status(@world.region("beta"))
    assert_equal :completed, journey.phase_status(@world.phase("a1"))
    assert_equal :current, journey.phase_status(@world.phase("a2"))
    assert_equal :upcoming, journey.phase_status(@world.phase("b1"))
    assert journey.landmark_reached?(@world.landmark("a1_mark"))
    assert_not journey.landmark_reached?(@world.landmark("a2_mark"))
  end

  test "status na fronteira exata entre regiões" do
    log_walks @user, 30
    journey = @user.journey(world: @world)

    assert_equal :completed, journey.region_status(@world.region("alpha"))
    assert_equal :current, journey.region_status(@world.region("beta"))
    assert_equal :completed, journey.phase_status(@world.phase("a2"))
    assert_equal :current, journey.phase_status(@world.phase("b1"))
  end

  test "mundo completo: tudo concluído, nenhuma fase atual" do
    log_walks @user, 60, 50
    journey = @user.journey(world: @world)

    assert_equal [ :completed, :completed ], @world.regions.map { journey.region_status(it) }
    assert_equal [ :completed ], @world.phases.map { journey.phase_status(it) }.uniq
    assert journey.landmark_reached?(@world.landmark("b2_mark"))
  end

  test "sem caminhadas: primeira fase atual" do
    journey = @user.journey(world: @world)

    assert_equal :current, journey.phase_status(@world.phase("a1"))
    assert_equal :upcoming, journey.phase_status(@world.phase("a2"))
    assert_equal :locked, journey.region_status(@world.region("beta"))
  end
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/user/journey_test.rb`
Expected: FAIL com `undefined method 'region_status'`.

- [ ] **Step 3: Implementar**

Em `app/models/user/journey.rb`, depois de `completed_phases`:

```ruby
  def region_status(region)
    if region.end_km <= total_km
      :completed
    elsif region == current_region
      :current
    else
      :locked
    end
  end

  def phase_status(phase)
    if phase.end_km <= total_km
      :completed
    elsif phase == current_phase
      :current
    else
      :upcoming
    end
  end

  def landmark_reached?(landmark)
    landmark.world_km <= total_km
  end
```

- [ ] **Step 4: Rodar e ver passar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/user/journey_test.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/models/user/journey.rb test/models/user/journey_test.rb
git commit -m "feat: status de região, fase e marco na jornada

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Tela do Mapa e aba na navegação

**Files:**
- Create: `app/controllers/maps_controller.rb`, `app/views/maps/show.html.erb`, `app/views/maps/_region.html.erb`, `app/views/maps/_phase.html.erb`, `app/views/maps/_locked_phase.html.erb`
- Modify: `config/routes.rb`, `app/views/layouts/_nav.html.erb`, `app/assets/tailwind/components.css`
- Test: `test/controllers/maps_controller_test.rb`

**Interfaces:**
- Consumes: `User::Journey#region_status`, `#phase_status`, `#landmark_reached?`, `#km_in_phase`, `#phase_progress`, `#world`; `pixel_art_tag(art, size:, label:, silhouette:)`; `stat(...)`; `segmented_progress(fraction)`.
- Produces: a rota `map_path` e os data-attributes `data-region`/`data-phase`/`data-status` usados nos testes.

- [ ] **Step 1: Testes do controller (mundo real)**

`test/controllers/maps_controller_test.rb`:

```ruby
require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "mostra as regiões em ordem com a situação de cada uma" do
    log_walks users(:viajante), 20, 10   # 30 km: fase 2 da Costa do Missionário

    get map_url

    assert_response :success
    assert_select "[data-region]", 3
    assert_select "[data-region=costa_do_missionario][data-status=current]"
    assert_select "[data-region=trilha_do_primeiro_raio][data-status=locked]"
    assert_select "[data-region=estrada_da_promessa][data-status=locked]"
  end

  test "fases concluída, atual e futura" do
    log_walks users(:viajante), 20, 10

    get map_url

    assert_select "[data-phase=mirante_do_convento][data-status=completed]" do
      assert_select "svg[aria-label=?]", "Insígnia Mirante do Convento"
      assert_select "*", text: /Convento do Penhasco/   # marco alcançado aparece pelo nome
    end
    assert_select "#atual[data-phase=areias_sem_fim][data-status=current]" do
      assert_select "*", text: %r{5 / 28 km}
      assert_select "*", text: /km 15/                  # Vila do Camarão ainda não alcançada
    end
    assert_select "[data-phase=areias_que_curam][data-status=upcoming]"
  end

  test "região bloqueada não revela fases nem marcos" do
    get map_url

    assert_select "[data-region=trilha_do_primeiro_raio]" do
      assert_select "*", text: /Trilha do Primeiro Raio/
      assert_select "*", text: /\?\?\?/
    end
    assert_no_match(/Vale das Quedas|Vila do Carimbo|Gigante de Pedra/, response.body)
  end

  test "sem caminhadas a primeira fase é a atual" do
    get map_url

    assert_select "#atual[data-phase=mirante_do_convento]", text: %r{0 / 25 km}
    assert_select "*", text: /Vila do Camarão/, count: 0
  end

  test "fronteira de 100 km libera a Região 2" do
    log_walks users(:viajante), 100

    get map_url

    assert_select "[data-region=costa_do_missionario][data-status=completed]"
    assert_select "[data-region=trilha_do_primeiro_raio][data-status=current]"
    assert_select "#atual[data-phase=vale_das_quedas]"
  end

  test "mundo completo não tem fase atual" do
    log_walks users(:viajante), 100, 100, 100, 100, 100, 99

    get map_url

    assert_select "[data-region][data-status=completed]", 3
    assert_select "#atual", 0
  end

  test "aba Mapa na navegação" do
    get root_url

    assert_select "nav a[href=?]", map_path(anchor: "atual"), text: "Mapa"
  end
end
```

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers/maps_controller_test.rb`
Expected: FAIL (`undefined local variable or method 'map_url'`).

- [ ] **Step 2: Rota e controller**

Em `config/routes.rb`, junto dos outros recursos:

```ruby
  resource :map, only: :show
```

`app/controllers/maps_controller.rb`:

```ruby
class MapsController < ApplicationController
  def show
    @journey = Current.user.journey
  end
end
```

- [ ] **Step 3: Estilo da trilha**

Acrescente em `app/assets/tailwind/components.css`, dentro de `@layer components`:

```css
  .trail {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    padding-left: 1.25rem;
    border-left: 4px dashed var(--color-silhouette);
  }

  .trail--done {
    border-left-style: solid;
    border-left-color: var(--color-gold);
  }

  .trail-node {
    position: relative;
    background: var(--color-panel);
    border: 4px solid var(--color-ink);
    padding: 0.75rem;
  }

  .trail-node::before {
    content: "";
    position: absolute;
    left: calc(-1.25rem - 10px);
    top: 1.25rem;
    width: 16px;
    height: 16px;
    background: var(--color-silhouette);
    border: 3px solid var(--color-ink);
  }

  .trail-node--completed::before { background: var(--color-gold); }
  .trail-node--current::before { background: var(--color-xp); }
  .trail-node--boss { border-color: var(--color-boss); }
  .trail-node--boss::before { width: 22px; height: 22px; left: calc(-1.25rem - 13px); }

  .trail-node > summary {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    cursor: pointer;
    list-style: none;
  }

  .trail-node > summary::-webkit-details-marker { display: none; }
```

A linha da trilha é uma borda por **fase**, não por região. A `.trail` de cada região tem `trail--done` só se a região estiver concluída. Dentro da região atual, as fases concluídas e a atual ficam num `.trail.trail--done` e as futuras num `.trail` tracejado. O partial `_region` faz essa divisão.

- [ ] **Step 4: Views**

`app/views/maps/show.html.erb`:

```erb
<% @page_title = "Mapa" %>

<h1 class="text-gold text-center">Mapa do mundo</h1>

<% @journey.world.regions.each do |region| %>
  <%= render "maps/region", region: region, journey: @journey %>
<% end %>
```

`app/views/maps/_region.html.erb`:

```erb
<% status = journey.region_status(region) %>
<section class="panel flex flex-col gap-4" data-region="<%= region.key %>" data-status="<%= status %>">
  <header class="flex flex-col gap-1">
    <p class="caption">Região <%= region.number %> · <%= region.km.to_i %> km ·
      <%= { completed: "Concluída", current: "Em andamento", locked: "Bloqueada" }.fetch(status) %></p>
    <h2 class="<%= status == :locked ? "opacity-60" : "text-gold" %>"><%= region.name %></h2>
  </header>

  <% if status == :locked %>
    <div class="trail">
      <% region.phases.each do |phase| %>
        <%= render "maps/locked_phase", phase: phase %>
      <% end %>
    </div>
  <% else %>
    <% walked, ahead = region.phases.partition { journey.phase_status(it) != :upcoming } %>
    <% if walked.any? %>
      <div class="trail trail--done">
        <% walked.each do |phase| %>
          <%= render "maps/phase", phase: phase, journey: journey %>
        <% end %>
      </div>
    <% end %>
    <% if ahead.any? %>
      <div class="trail">
        <% ahead.each do |phase| %>
          <%= render "maps/phase", phase: phase, journey: journey %>
        <% end %>
      </div>
    <% end %>
  <% end %>
</section>
```

`app/views/maps/_locked_phase.html.erb`:

```erb
<div class="trail-node <%= "trail-node--boss" if phase.boss? %> flex items-center gap-3 opacity-60" data-status="locked">
  <span class="block bg-silhouette" style="width: 40px; height: 40px"></span>
  <span class="font-display text-[0.75rem]">???</span>
</div>
```

`app/views/maps/_phase.html.erb`:

```erb
<% status = journey.phase_status(phase) %>
<%= tag.details id: ("atual" if status == :current), open: status == :current,
      class: [ "trail-node", "trail-node--#{status}", ("trail-node--boss" if phase.boss?) ],
      data: { phase: phase.key, status: status } do %>
  <summary>
    <%= pixel_art_tag PixelArt.find(:insignias, phase.key), size: phase.boss? ? 60 : 48,
          label: "Insígnia #{phase.name}", silhouette: status == :upcoming %>
    <div class="flex-1 flex flex-col gap-1">
      <p class="caption">Fase <%= phase.number %><%= " · Chefão" if phase.boss? %></p>
      <p class="font-display text-[0.75rem] <%= phase.boss? ? "text-boss" : "text-gold" %>"><%= phase.name %></p>
    </div>
    <% if status == :current %>
      <%= pixel_art_tag PixelArt.find(:avatars, journey.user.avatar), size: 40, label: journey.user.name %>
    <% end %>
  </summary>

  <div class="flex flex-col gap-2 mt-3">
    <% if status == :current %>
      <%= segmented_progress journey.phase_progress %>
      <%= stat journey.km_in_phase, total: phase.km, unit: "km" %>
    <% else %>
      <%= stat phase.km, unit: "km" %>
    <% end %>
    <p class="caption">Trecho real: <%= phase.inspired_by %></p>

    <% if phase.landmarks.any? %>
      <ul class="flex flex-col gap-2">
        <% phase.landmarks.each do |landmark| %>
          <li class="flex items-center gap-2">
            <% if journey.landmark_reached?(landmark) %>
              <%= pixel_art_tag PixelArt.find(:stamps, landmark.key), size: 32, label: "Carimbo #{landmark.name}" %>
              <span><%= landmark.name %></span>
            <% else %>
              <span class="block bg-silhouette" style="width: 32px; height: 32px"></span>
              <span class="caption">??? · km <%= number_with_precision landmark.at_km, precision: 1, strip_insignificant_zeros: true %></span>
            <% end %>
          </li>
        <% end %>
      </ul>
    <% end %>
  </div>
<% end %>
```

(`bg-silhouette` e `opacity-60` vêm do Tailwind, porque `--color-silhouette` está no `@theme`.)

- [ ] **Step 5: Aba na navegação**

`app/views/layouts/_nav.html.erb`:

```erb
<nav class="fixed inset-x-0 bottom-0 border-t-4 border-ink bg-panel" aria-label="Navegação principal">
  <ul class="mx-auto max-w-md grid grid-cols-4 items-end text-center font-display text-[0.7rem]">
    <li><%= link_to "Início", root_path, class: "block py-4" %></li>
    <li><%= link_to "Mapa", map_path(anchor: "atual"), class: "block py-4" %></li>
    <li><%= link_to "Registrar", new_walk_path, class: "btn-game -translate-y-3 w-full px-1" %></li>
    <li><%= link_to "Histórico", walks_path, class: "block py-4" %></li>
  </ul>
</nav>
```

- [ ] **Step 6: Rodar os testes**

Run: `mise exec ruby@4.0.6 -- bin/rails tailwindcss:build && mise exec ruby@4.0.6 -- bin/rails test && mise exec ruby@4.0.6 -- bin/rails test:system && mise exec ruby@4.0.6 -- bin/rubocop`
Expected: tudo verde, sem avisos. Se um system test existente clicar em "Registrar" de um jeito que a nova aba atrapalhe, ajuste o seletor e descreva no relatório.

- [ ] **Step 7: Conferir no tamanho de celular (Review Focus 5)**

Crie temporariamente `test/system/zz_mapa_screenshot_test.rb`: logue o `viajante` com 30 km, visite `map_url`, redimensione a janela pra 390×2400 e salve `page.save_screenshot("tmp/mapa.png")`. Rode, apague o arquivo de teste e olhe `tmp/mapa.png`. Nada pode estourar a largura, e "5 / 28 km" tem que estar legível. Ajuste o CSS se precisar e descreva no relatório.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: tela do Mapa com a trilha vertical de regiões e fases

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
