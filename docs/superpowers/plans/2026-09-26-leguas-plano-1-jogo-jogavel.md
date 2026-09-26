# Léguas, Plano 1: jogo jogável na Região 1

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de escrever código Rails, carregue o skill `superpowers-ruby:37signals-style`.

**Goal:** Um app Rails em que o viajante entra por código no email, escolhe nome/avatar/meta, registra caminhadas e avança pela Região 1 (Estrada da Promessa), ganhando XP, níveis, títulos, carimbos e insígnias, com as telas de celebração.

**Architecture:** Monolito Rails 8 com SQLite. O conteúdo do mundo fica em YAML (`config/world/`) e as grades de pixel art em arquivos texto (`app/pixel_art/`), carregados como POROs. No banco ficam só os dados do viajante. Posição, XP, nível e conquistas são sempre calculados a partir da soma das caminhadas (`User::Journey`). Os padrões de código e de autenticação seguem o beep (`~/Projects/risecode/beep/master`), trazendo só o que se aplica a um app pequeno.

**Tech Stack:** Ruby 4.0.6, Rails 8.1.3.x, SQLite, Hotwire (Turbo + Stimulus), importmap, Propshaft, Tailwind 4 (tailwindcss-rails), Solid Queue, Minitest + fixtures, Capybara + Selenium (headless Chromium em `/usr/bin/chromium`).

**Spec:** `docs/superpowers/specs/2026-09-25-leguas-design.md`. Pesquisa de conteúdo: `docs/research/2026-09-25-distancias.md`.

**Escopo deste plano:** as entregas 1–5 do spec. Ficam pro **Plano 2**:
- mapa do mundo e mapa da região
- diário e troféus com certificado (incluindo as datas do certificado na celebração de região)
- conteúdo das Regiões 2 e 3
- PWA e deploy (Kamal, Resend em produção)

A barra de navegação deste plano tem só **Início · Registrar · Histórico**. O Plano 2 troca pela barra completa.

## Global Constraints

- **Idioma:** toda a interface em pt-BR, com texto escrito direto nas views e nos models (sem `t()`). O viajante é sempre chamado de "viajante".
- **Tempo:** `config.time_zone = "Brasilia"`. Datas sempre via `Date.current` / `Time.current`, nunca `Date.today` / `Time.now`.
- **Filosofia:** sem streak e sem linguagem de falha. Palavras como "falhou", "perdeu" ou "abandonou" não aparecem na interface.
- **XP:**

  | Evento | XP |
  |---|---|
  | km caminhado | 10 (arredondado pra baixo sobre o total) |
  | Marco | 25 |
  | Fase | 100 |
  | Fase rara ou lendária | 250 |
  | Região | 500 |
  | Missão cumprida | 20 |

- **Níveis:** nível *n* exige `40 × (n−1)²` XP. Títulos: 1 Caminhante, 5 Andarilho, 10 Aventureiro, 15 Peregrino, 20 Desbravador, 25 Lenda das Léguas.
- **Caminhada:** km > 0; soma do dia ≤ 100 km; data entre `Date.current - 7` e `Date.current`.
- **Légua:** 1 légua = 6 km.
- **Pixel art:** insígnia comum 16×16, rara e lendária 20×20, carimbo 12×12, avatar 16×16. `.` = transparente; as demais letras vêm de `app/pixel_art/palette.yml`.
- **Paleta:**

  | Uso | Cor |
  |---|---|
  | Fundo | #1B1F3B |
  | Painel | #2A2F5A |
  | Contorno | #0B0D1F |
  | Dourado | #F4C542 |
  | Verde (XP) | #5BC27A |
  | Laranja (chefão) | #FF9F6B |
  | Texto creme | #F2EEDC |
  | Lendária | #B98CFF |

- **Fontes:** "Press Start 2P" só em títulos, rótulos e botões; "Pixelify Sans" no texto corrido.
- **Estilo de código** (STYLE.md do beep):
  - `if/else` expandido em vez de guard clause
  - métodos na ordem de chamada
  - `private` sem linha em branco depois e com os métodos indentados
  - `!` só quando existe par sem `!`
  - recurso novo em vez de action customizada
- **Testes:** TDD sempre, com o teste vermelho antes do código. Minitest + fixtures, sem factories.
- **Commits:** mensagem em Conventional Commits (pt-BR no resumo), terminando com a linha `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Vírgula decimal:** o teclado do celular brasileiro manda "3,5". A caminhada precisa salvar 3.5 km, e não 3 nem erro. O teste fica na Task 9.
2. **Editar caminhada antiga:** mexer só na observação de uma caminhada de 10 dias atrás tem que salvar. A janela de 7 dias só vale quando a data muda. Task 9.
3. **Mudar a data pra um dia cheio:** mover uma caminhada de 20 km pra um dia que já tem 90 km é barrado. Editar a própria caminhada de 60 km pra 70 km, num dia que só tem ela, passa. O limite exclui a própria caminhada. Task 9.
4. **Fuso na virada do dia:** uma caminhada registrada às 23h30 de Brasília (02h30 UTC do dia seguinte) é "hoje" e continua dentro da janela. Task 9.
5. **Clique duplo em "Continuar":** reenviar a mesma chave de celebração, ou uma chave que não está pendente, não gera erro nem registro estranho. Só redireciona. Task 14.

---

## Estrutura de arquivos

```
app/
  controllers/
    application_controller.rb          # inclui Authentication, Onboarding
    concerns/authentication.rb          # sessão por cookie assinado (do beep, simplificado)
    concerns/onboarding.rb              # manda pra travelers#new enquanto não há nome
    sessions_controller.rb              # new (email), destroy (sair)
    auth_tokens_controller.rb           # create: gera e envia o código
    auth_tokens/validations_controller.rb # new/create: confere o código
    travelers_controller.rb             # boas-vindas (nome, avatar, meta)
    profiles_controller.rb              # editar nome, avatar, meta
    home_controller.rb                  # início com HUD
    walks_controller.rb                 # CRUD de caminhadas
    celebrations_controller.rb          # show: próxima pendente; create: marca vista
  models/
    user.rb, user/traveler.rb, user/celebrations.rb, user/journey.rb, user/level.rb
    auth_token.rb, six_digit_code.rb, session.rb, current.rb
    walk.rb, mission.rb, celebration.rb, achievement.rb
    world.rb, world/region.rb, world/phase.rb, world/landmark.rb, world/milestone.rb
    pixel_art.rb
  helpers/pixel_art_helper.rb, helpers/progress_helper.rb
  mailers/auth_token_mailer.rb
  frontend/                             # JS (antigo app/javascript), como no beep
    application.js, controllers/steps_controller.js
  assets/tailwind/application.css, assets/tailwind/components.css
  pixel_art/palette.yml, avatars/*.txt, insignias/*.txt, stamps/*.txt
  views/...
config/world/01_estrada_da_promessa.yml
test/world/01_alpha.yml, test/world/02_beta.yml   # mundo de teste (fora de test/fixtures!)
```

---

### Task 1: Esqueleto Rails, configuração e documentação de estilo

**Files:**
- Create: o app Rails inteiro via `rails new` dentro de `~/Projects/leguas` (repo já existe com `docs/`)
- Create: `STYLE.md`, `CLAUDE.md`
- Modify: `config/application.rb`, `Gemfile`, `config/importmap.rb`, `config/initializers/assets.rb`, `app/assets/tailwind/application.css`
- Move: `app/javascript` → `app/frontend`
- Test: `test/controllers/health_test.rb`

**Interfaces:**
- Produces: app bootável; `bin/rails test` verde; JS em `app/frontend/` pinado como `controllers/*`; locale pt-BR; fuso Brasília.

- [ ] **Step 1: Fixar Ruby e gerar o app**

```bash
cd ~/Projects/leguas
echo "ruby-4.0.6" > .ruby-version
ruby -v        # esperado: ruby 4.0.6
gem list rails | grep "^rails " || gem install rails -v 8.1.3.1
rails _8.1.3.1_ new . --name=leguas --database=sqlite3 --css=tailwind \
  --skip-jbuilder --skip-action-text --skip-action-mailbox --skip-active-storage --skip
```

`--skip` mantém os arquivos que já existem (`.ruby-version`, `docs/`) sem perguntar. Confira que `cat .ruby-version` ainda mostra `ruby-4.0.6` e que `git status` não lista nada de `docs/` como apagado.

- [ ] **Step 2: Adicionar o rails-i18n (traduções pt-BR de datas e erros)**

No `Gemfile`, depois de `gem "rails"`:

```ruby
gem "rails-i18n", "~> 8.0"
```

Run: `bundle install`

- [ ] **Step 3: Configurar fuso e locale**

Em `config/application.rb`, dentro de `class Application`:

```ruby
    config.time_zone = "Brasilia"
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [ :"pt-BR" ]
```

- [ ] **Step 4: Mover o JS pra `app/frontend` (padrão do beep)**

```bash
git mv app/javascript app/frontend 2>/dev/null || mv app/javascript app/frontend
```

`config/importmap.rb` deve ficar:

```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/frontend/controllers", under: "controllers"
```

`config/initializers/assets.rb`: acrescente

```ruby
Rails.application.config.assets.paths << Rails.root.join("app/frontend")
```

Em `app/assets/tailwind/application.css`, logo abaixo de `@import "tailwindcss";`:

```css
@source "../../views";
@source "../../helpers";
@source "../../frontend/controllers";
```

- [ ] **Step 5: Escrever o teste de fumaça**

`test/controllers/health_test.rb`:

```ruby
require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "o app sobe" do
    get rails_health_check_url
    assert_response :success
  end

  test "fuso e idioma" do
    assert_equal "Brasilia", Time.zone.name
    assert_equal :"pt-BR", I18n.default_locale
  end
end
```

- [ ] **Step 6: Rodar os testes e checar o importmap**

Run: `bin/rails test && bin/importmap json | grep controllers/application`
Expected: 2 runs, 0 failures; o JSON mostra `"controllers/application"`.

- [ ] **Step 7: Escrever `STYLE.md` e `CLAUDE.md`**

`STYLE.md`:

````markdown
# Estilo

Segue o estilo "vanilla Rails" do 37signals, como no beep.

- **Condicionais:** prefira `if/else` expandido a guard clause. Guard só no começo de um método cujo corpo não é trivial.
- **Ordem:** métodos de classe, depois públicos (`initialize` primeiro), depois privados. Métodos na ordem em que são chamados.
- **Visibilidade:** sem linha em branco depois de `private`; os métodos privados ficam indentados sob ele.
- **Bang:** `!` só quando existe a versão sem `!`.
- **Controllers:** CRUD. Ação que não é CRUD vira recurso novo (`resource :celebration`, não `post :celebrate`). Controller magro, model rico.
- **Models:** concerns do model em `app/models/<model>/` (`User::Traveler`), incluídos pelo nome curto. POROs no namespace. `app/models/concerns/` só pro que é compartilhado. Sem `app/services`.
- **Texto:** pt-BR escrito direto, tom de jogo mas claro. Nunca "falhou"/"perdeu".
````

`CLAUDE.md`:

````markdown
# Léguas

Jogo de caminhada em pixel art. Spec: `docs/superpowers/specs/2026-09-25-leguas-design.md`. Estilo: `STYLE.md`.

- Rails 8 + SQLite + Hotwire + Tailwind 4. JS em `app/frontend/`.
- Conteúdo do mundo em `config/world/*.yml`, pixel art em `app/pixel_art/`. Nada disso vai pro banco.
- Progresso é sempre calculado da soma das caminhadas (`User::Journey`). Nunca grave posição/XP.
- TDD sempre: `bin/rails test`, `bin/rails test:system`.
- Testes de lógica usam o mundo pequeno de `test/world/` (fora de `test/fixtures`, porque `fixtures :all` carrega subpastas).
````

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: esqueleto Rails 8 com SQLite, Tailwind e JS em app/frontend

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Tema visual, layout e componentes de jogo

**Files:**
- Modify: `app/assets/tailwind/application.css`, `app/views/layouts/application.html.erb`
- Create: `app/assets/tailwind/components.css`, `app/helpers/progress_helper.rb`
- Test: `test/helpers/progress_helper_test.rb`

**Interfaces:**
- Produces:
  - classes CSS `.panel`, `.btn-game`, `.btn-game--secondary`, `.progress-segmented`, `.progress-segmented__segment`, `.progress-segmented__segment--filled`, `.font-display`, `.field`, `.field-error`
  - tokens `--color-night`, `--color-panel`, `--color-ink`, `--color-gold`, `--color-xp`, `--color-boss`, `--color-cream`, `--color-legend`, `--color-silhouette`
  - helper `segmented_progress(fraction, segments: 10, color: :gold)`
  - no layout: as variáveis `@page_title` e `@hide_nav`, que as views atribuem (`<% @hide_nav = true %>`). O layout é renderizado depois da view, então enxerga as duas.

- [ ] **Step 1: Escrever o teste do helper**

`test/helpers/progress_helper_test.rb`:

```ruby
require "test_helper"

class ProgressHelperTest < ActionView::TestCase
  test "preenche segmentos proporcionais, arredondando pra baixo" do
    html = segmented_progress(0.46, segments: 10)

    assert_equal 4, Nokogiri::HTML(html).css(".progress-segmented__segment--filled").size
    assert_equal 10, Nokogiri::HTML(html).css(".progress-segmented__segment").size
  end

  test "limita entre 0 e 1" do
    assert_equal 10, Nokogiri::HTML(segmented_progress(1.7)).css(".progress-segmented__segment--filled").size
    assert_equal 0, Nokogiri::HTML(segmented_progress(-1)).css(".progress-segmented__segment--filled").size
  end

  test "expõe o valor pra leitores de tela" do
    assert_includes segmented_progress(0.5), 'aria-valuenow="50"'
  end
end
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bin/rails test test/helpers/progress_helper_test.rb`
Expected: FAIL com `undefined method 'segmented_progress'`

- [ ] **Step 3: Implementar o helper**

`app/helpers/progress_helper.rb`:

```ruby
module ProgressHelper
  def segmented_progress(fraction, segments: 10, color: :gold)
    fraction = fraction.to_f.clamp(0, 1)
    filled = (fraction * segments).floor

    tag.div class: "progress-segmented progress-segmented--#{color}", role: "progressbar",
      aria: { valuenow: (fraction * 100).round, valuemin: 0, valuemax: 100 } do
      safe_join(segments.times.map { |index| progress_segment(filled: index < filled) })
    end
  end

  private
    def progress_segment(filled:)
      tag.span class: [ "progress-segmented__segment", ("progress-segmented__segment--filled" if filled) ]
    end
end
```

- [ ] **Step 4: Rodar e ver passar**

Run: `bin/rails test test/helpers/progress_helper_test.rb`
Expected: 3 runs, 0 failures

- [ ] **Step 5: Tema e componentes**

`app/assets/tailwind/application.css` (conteúdo completo):

```css
@import "tailwindcss";
@source "../../views";
@source "../../helpers";
@source "../../frontend/controllers";

@theme {
  --color-night: #1B1F3B;
  --color-panel: #2A2F5A;
  --color-ink: #0B0D1F;
  --color-gold: #F4C542;
  --color-xp: #5BC27A;
  --color-boss: #FF9F6B;
  --color-cream: #F2EEDC;
  --color-legend: #B98CFF;
  --color-silhouette: #3A3F6A;
  --font-display: "Press Start 2P", monospace;
  --font-body: "Pixelify Sans", system-ui, sans-serif;
}

@import "./components.css";
```

`app/assets/tailwind/components.css`:

```css
@layer base {
  body {
    background: var(--color-night);
    color: var(--color-cream);
    font-family: var(--font-body);
    font-size: 1.125rem;
  }

  h1, h2, h3, button, label, .font-display {
    font-family: var(--font-display);
    line-height: 1.6;
  }

  h1 { font-size: 1rem; }
  h2 { font-size: 0.8rem; }
}

@layer components {
  .panel {
    background: var(--color-panel);
    border: 4px solid var(--color-ink);
    box-shadow: inset 0 0 0 2px #3A4078;
    padding: 1rem;
  }

  .btn-game {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    min-height: 3rem;
    padding: 0.75rem 1.25rem;
    font-family: var(--font-display);
    font-size: 0.75rem;
    color: var(--color-ink);
    background: var(--color-gold);
    border: 4px solid var(--color-ink);
    box-shadow: 0 6px 0 var(--color-ink);
    cursor: pointer;
    text-decoration: none;
  }

  .btn-game:active {
    transform: translateY(4px);
    box-shadow: 0 2px 0 var(--color-ink);
  }

  .btn-game--secondary {
    background: var(--color-panel);
    color: var(--color-cream);
  }

  .progress-segmented {
    display: grid;
    grid-auto-flow: column;
    gap: 3px;
    padding: 3px;
    background: var(--color-ink);
  }

  .progress-segmented__segment {
    height: 0.9rem;
    background: var(--color-silhouette);
  }

  .progress-segmented--gold .progress-segmented__segment--filled { background: var(--color-gold); }
  .progress-segmented--xp .progress-segmented__segment--filled { background: var(--color-xp); }

  .field {
    width: 100%;
    padding: 0.75rem;
    font-family: var(--font-body);
    font-size: 1.25rem;
    color: var(--color-ink);
    background: var(--color-cream);
    border: 4px solid var(--color-ink);
  }

  .field-error {
    color: var(--color-boss);
    font-size: 1rem;
  }
}
```

- [ ] **Step 6: Layout**

`app/views/layouts/application.html.erb` (substitui o gerado):

```erb
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <title><%= [ @page_title, "Léguas" ].compact.join(" · ") %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="theme-color" content="#1B1F3B">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Pixelify+Sans:wght@400;600&family=Press+Start+2P&display=swap" rel="stylesheet">
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="min-h-dvh">
    <main class="mx-auto max-w-md px-4 pt-4 pb-28 flex flex-col gap-4">
      <% flash.each do |type, message| %>
        <% next if type == "otp_code" %>
        <p class="panel text-center <%= type == "alert" ? "text-boss" : "text-xp" %>" role="status"><%= message %></p>
      <% end %>

      <%= yield %>
    </main>

    <% if authenticated? && !@hide_nav %>
      <%= render "layouts/nav" %>
    <% end %>
  </body>
</html>
```

`app/views/layouts/_nav.html.erb`:

```erb
<nav class="fixed inset-x-0 bottom-0 border-t-4 border-ink bg-panel" aria-label="Navegação principal">
  <ul class="mx-auto max-w-md grid grid-cols-3 items-end text-center font-display text-[0.6rem]">
    <li><%= link_to "Início", root_path, class: "block py-4" %></li>
    <li><%= link_to "Registrar", new_walk_path, class: "btn-game -translate-y-3 w-full" %></li>
    <li><%= link_to "Histórico", walks_path, class: "block py-4" %></li>
  </ul>
</nav>
```

O layout referencia `authenticated?` e as rotas `root_path`, `new_walk_path` e `walks_path`, que só aparecem na Task 4. Nenhum controller renderiza o layout antes disso (o health check responde sem layout), então a suíte continua verde. A checagem visual fica pra Task 4.

- [ ] **Step 7: Rodar a suíte inteira**

Run: `bin/rails test`
Expected: 0 failures

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: tema pixel art, componentes de jogo e barra segmentada

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Models de conta: User, AuthToken, Session, Current

**Files:**
- Create: migrations de `users`, `auth_tokens`, `sessions`
- Create: `app/models/user.rb`, `app/models/auth_token.rb`, `app/models/six_digit_code.rb`, `app/models/session.rb`, `app/models/current.rb`
- Create: `app/mailers/auth_token_mailer.rb`, `app/views/auth_token_mailer/otp.text.erb`
- Create: `test/fixtures/users.yml`
- Test: `test/models/user_test.rb`, `test/models/auth_token_test.rb`, `test/models/session_test.rb`, `test/mailers/auth_token_mailer_test.rb`

**Interfaces:**
- Produces:
  - **User:** `email_address` (normalizado), `name`, `avatar`, `daily_goal_km`; `has_many :auth_tokens, :sessions`
  - **AuthToken:** `AuthToken::EXPIRATION` (15 min); `AuthToken.lookup(email_address:, code:)` → `AuthToken` ou `nil`; `#use!`; `#deliver_later`
  - **Session:** `Session.unexpired`; `Session.start!(user_agent:, ip_address:)` (chamado via `user.sessions`); `#resume(user_agent:, ip_address:)`
  - **Current:** atributos `session` e `user` (atribuir `session` também atribui `user`)
  - **Outros:** `SixDigitCode.generate` → String de 6 dígitos; `AuthTokenMailer.otp(auth_token)`

- [ ] **Step 1: Gerar as migrations**

```bash
bin/rails g migration CreateUsers email_address:string:uniq name:string avatar:string "daily_goal_km:decimal{4,1}"
bin/rails g migration CreateAuthTokens user:references code:string expires_at:datetime used_at:datetime
bin/rails g migration CreateSessions user:references token:string:uniq expires_at:datetime last_active_at:datetime user_agent:string ip_address:string
```

Edite a migration de `users` pra ter `null: false` em `email_address`, `default: 3` em `daily_goal_km` e `t.timestamps`. Edite a de `auth_tokens` pra ter `null: false` em `code` e `expires_at`, e acrescente `add_index :auth_tokens, [ :user_id, :code ]`.

Run: `bin/rails db:migrate`

- [ ] **Step 2: Fixtures**

`test/fixtures/users.yml`:

```yaml
viajante:
  email_address: viajante@leguas.test
  name: Tião
  avatar: tropeiro
  daily_goal_km: 3

novato:
  email_address: novato@leguas.test
  daily_goal_km: 3
```

- [ ] **Step 3: Escrever os testes**

`test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normaliza o email" do
    user = User.create!(email_address: "  Andarilho@Leguas.TEST ")

    assert_equal "andarilho@leguas.test", user.email_address
  end

  test "email precisa ser válido e único" do
    assert_not User.new(email_address: "sem-arroba").valid?
    assert_not User.new(email_address: users(:viajante).email_address.upcase).valid?
  end
end
```

`test/models/auth_token_test.rb`:

```ruby
require "test_helper"

class AuthTokenTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "gera um código de 6 dígitos ao criar" do
    token = @user.auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)

    assert_match(/\A\d{6}\z/, token.code)
  end

  test "lookup encontra token válido pelo email e código" do
    token = @user.auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)

    assert_equal token, AuthToken.lookup(email_address: "VIAJANTE@leguas.test", code: token.code)
  end

  test "lookup ignora token expirado, usado ou código errado" do
    expired = @user.auth_tokens.create!(expires_at: 1.minute.ago)
    used = @user.auth_tokens.create!(expires_at: 10.minutes.from_now, used_at: Time.current)

    assert_nil AuthToken.lookup(email_address: @user.email_address, code: expired.code)
    assert_nil AuthToken.lookup(email_address: @user.email_address, code: used.code)
    assert_nil AuthToken.lookup(email_address: @user.email_address, code: "000000")
    assert_nil AuthToken.lookup(email_address: nil, code: nil)
  end

  test "use! marca como usado e apaga os outros tokens do usuário" do
    token = @user.auth_tokens.create!(expires_at: 10.minutes.from_now)
    other = @user.auth_tokens.create!(expires_at: 10.minutes.from_now)

    token.use!

    assert token.reload.used_at
    assert_not AuthToken.exists?(other.id)
  end
end
```

`test/models/session_test.rb`:

```ruby
require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "start! cria sessão com token" do
    session = users(:viajante).sessions.start!(user_agent: "teste", ip_address: "127.0.0.1")

    assert session.token.present?
    assert session.last_active_at
  end

  test "resume só atualiza depois de uma hora" do
    session = users(:viajante).sessions.start!(user_agent: "a", ip_address: "1.1.1.1")

    session.resume(user_agent: "b", ip_address: "2.2.2.2")
    assert_equal "a", session.reload.user_agent

    travel 2.hours do
      session.resume(user_agent: "b", ip_address: "2.2.2.2")
      assert_equal "b", session.reload.user_agent
    end
  end

  test "Current.session também define Current.user" do
    session = users(:viajante).sessions.start!(user_agent: "a", ip_address: "1.1.1.1")

    Current.session = session

    assert_equal users(:viajante), Current.user
  end
end
```

`test/mailers/auth_token_mailer_test.rb`:

```ruby
require "test_helper"

class AuthTokenMailerTest < ActionMailer::TestCase
  test "envia o código" do
    token = users(:viajante).auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)

    mail = AuthTokenMailer.otp(token)

    assert_equal [ "viajante@leguas.test" ], mail.to
    assert_equal "Seu código pra entrar no Léguas", mail.subject
    assert_includes mail.body.to_s, token.code
  end
end
```

- [ ] **Step 4: Rodar e ver falhar**

Run: `bin/rails test test/models test/mailers`
Expected: FAIL (`uninitialized constant User` / `AuthToken`)

- [ ] **Step 5: Implementar**

`app/models/six_digit_code.rb`:

```ruby
module SixDigitCode
  def self.generate = format("%06d", SecureRandom.random_number(900_000) + 100_000)
end
```

`app/models/user.rb`:

```ruby
class User < ApplicationRecord
  has_many :auth_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: -> { it.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

`app/models/auth_token.rb`:

```ruby
class AuthToken < ApplicationRecord
  EXPIRATION = 15.minutes

  belongs_to :user

  validates_presence_of :code, :expires_at

  before_validation :generate_code, on: :create

  scope :valid, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.lookup(email_address:, code:)
    if email_address.present? && code.present?
      if user = User.find_by(email_address: email_address)
        valid.find_by(user: user, code: code)
      end
    end
  end

  def deliver_later
    AuthTokenMailer.otp(self).deliver_later
  end

  def use!
    update!(used_at: Time.current)
    user.auth_tokens.excluding(self).destroy_all
  end

  private
    def generate_code
      self.code = SixDigitCode.generate
    end
end
```

`app/models/session.rb`:

```ruby
class Session < ApplicationRecord
  ACTIVITY_REFRESH_RATE = 1.hour

  has_secure_token

  belongs_to :user

  scope :unexpired, -> { where(expires_at: nil).or(where(expires_at: Time.current..)) }

  before_create { self.last_active_at ||= Time.current }

  def self.start!(user_agent:, ip_address:)
    create!(user_agent: user_agent, ip_address: ip_address)
  end

  def resume(user_agent:, ip_address:)
    if last_active_at.before?(ACTIVITY_REFRESH_RATE.ago)
      update!(user_agent: user_agent, ip_address: ip_address, last_active_at: Time.current)
    end
  end
end
```

`app/models/current.rb`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  def session=(value)
    super(value)
    self.user = value&.user
  end
end
```

`app/mailers/auth_token_mailer.rb`:

```ruby
class AuthTokenMailer < ApplicationMailer
  def otp(auth_token)
    @code = auth_token.code
    @expires_in = auth_token.expires_at - Time.current

    mail(to: auth_token.user.email_address, subject: "Seu código pra entrar no Léguas")
  end
end
```

`app/views/auth_token_mailer/otp.text.erb`:

```erb
Olá, viajante!

Use este código pra entrar no Léguas: <%= @code %>

Ele vale por <%= distance_of_time_in_words(@expires_in) %>.

Se não foi você que pediu, é só ignorar este email.
```

Em `app/mailers/application_mailer.rb`, troque o `default from:` por:

```ruby
  default from: ENV.fetch("MAIL_FROM", "Léguas <nao-responda@leguas.localhost>")
```

- [ ] **Step 6: Rodar e ver passar**

Run: `bin/rails test test/models test/mailers`
Expected: 0 failures

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: usuário, código de acesso e sessão (padrão beep)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Login por código (controllers, views e helper de teste)

**Files:**
- Create: `app/controllers/concerns/authentication.rb`, `app/controllers/sessions_controller.rb`, `app/controllers/auth_tokens_controller.rb`, `app/controllers/auth_tokens/validations_controller.rb`, `app/controllers/home_controller.rb`
- Create: `app/views/sessions/new.html.erb`, `app/views/auth_tokens/validations/new.html.erb`, `app/views/home/show.html.erb` (provisória)
- Create: `test/test_helpers/session_test_helper.rb`
- Modify: `app/controllers/application_controller.rb`, `config/routes.rb`, `test/test_helper.rb`
- Test: `test/controllers/sessions_flow_test.rb`

**Interfaces:**
- Consumes: `AuthToken.lookup`, `#use!`, `#deliver_later`, `Session.start!` e `Current.session=`, da Task 3.
- Produces:
  - **Macros de controller:** `allow_unauthenticated_access(**)` e `require_unauthenticated_access(**)`
  - **Helpers:** `authenticated?` (também disponível nas views), `start_new_session_for(user)`, `terminate_session`
  - **Rotas:** `new_session_path`, `session_path` (DELETE), `auth_tokens_path` (POST), `new_auth_tokens_validations_path`, `auth_tokens_validations_path` (POST), `root_path`
  - **Teste:** helper `sign_in(user_or_fixture_name)` nos testes de integração

- [ ] **Step 1: Helper de teste**

`test/test_helpers/session_test_helper.rb`:

```ruby
module SessionTestHelper
  def sign_in(user)
    user = users(user) unless user.is_a?(User)

    post auth_tokens_url, params: { email_address: user.email_address }
    post auth_tokens_validations_url, params: { code: user.auth_tokens.order(:created_at).last.code }

    assert cookies[:session_token].present?, "sign_in não abriu sessão"
  end
end
```

No fim de `test/test_helper.rb`:

```ruby
require_relative "test_helpers/session_test_helper"

class ActionDispatch::IntegrationTest
  include SessionTestHelper
end
```

- [ ] **Step 2: Escrever os testes de fluxo**

`test/controllers/sessions_flow_test.rb`:

```ruby
require "test_helper"

class SessionsFlowTest < ActionDispatch::IntegrationTest
  test "sem sessão, manda pro login" do
    get root_url

    assert_redirected_to new_session_url
  end

  test "pedir código cria o usuário se preciso e envia o email" do
    assert_difference -> { User.count } => 1, -> { AuthToken.count } => 1 do
      assert_enqueued_emails 1 do
        post auth_tokens_url, params: { email_address: "nova@leguas.test" }
      end
    end

    assert_redirected_to new_auth_tokens_validations_url
  end

  test "email inválido volta pro login com alerta" do
    post auth_tokens_url, params: { email_address: "nada" }

    assert_redirected_to new_session_url
    assert_equal "Esse email não parece certo, viajante.", flash[:alert]
  end

  test "código certo abre sessão e volta pra página pedida" do
    get root_url
    sign_in :viajante

    assert_redirected_to root_url
  end

  test "código errado volta pra validação" do
    post auth_tokens_url, params: { email_address: users(:viajante).email_address }
    post auth_tokens_validations_url, params: { code: "000000" }

    assert_redirected_to new_auth_tokens_validations_url
    assert_equal "Código inválido ou expirado", flash[:alert]
    assert cookies[:session_token].blank?
  end

  test "sair encerra a sessão" do
    sign_in :viajante

    delete session_url

    assert_redirected_to new_session_url
    get root_url
    assert_redirected_to new_session_url
  end

  test "quem já está logado não vê o login" do
    sign_in :viajante

    get new_session_url

    assert_redirected_to root_url
  end
end
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bin/rails test test/controllers/sessions_flow_test.rb`
Expected: FAIL (`undefined local variable or method 'root_url'`)

- [ ] **Step 4: Rotas**

`config/routes.rb`:

```ruby
Rails.application.routes.draw do
  root "home#show"

  resource :session, only: %i[ new destroy ]
  resources :auth_tokens, only: :create
  namespace :auth_tokens do
    resource :validations, only: %i[ new create ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 5: Concern de autenticação**

`app/controllers/concerns/authentication.rb`:

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_signed_in_user_to_root, **options
    end

    def rate_limit_sign_in(by:)
      rate_limit to: 10, within: 1.minute, only: :create, by: by,
        with: -> { redirect_to new_session_path, alert: "Muitas tentativas. Respira e tenta de novo daqui a um minuto." }
    end
  end

  private
    def authenticated?
      Current.session.present?
    end

    def require_authentication
      restore_authentication || request_authentication
    end

    def restore_authentication
      if user_session = find_session_by_cookie
        user_session.resume(user_agent: request.user_agent, ip_address: request.remote_ip)
        Current.session = user_session
      end
    end

    def find_session_by_cookie
      if token = cookies.signed[:session_token]
        Session.unexpired.find_by(token: token)
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def redirect_signed_in_user_to_root
      if restore_authentication
        redirect_to root_path
      end
    end

    def post_authenticating_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.start!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |user_session|
        Current.session = user_session
        cookies.signed.permanent[:session_token] = {
          value: user_session.token, httponly: true, same_site: :lax, secure: Rails.env.production?
        }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_token)
    end
end
```

`app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
end
```

- [ ] **Step 6: Controllers**

`app/controllers/sessions_controller.rb`:

```ruby
class SessionsController < ApplicationController
  require_unauthenticated_access only: :new

  def new
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
```

`app/controllers/auth_tokens_controller.rb`:

```ruby
class AuthTokensController < ApplicationController
  allow_unauthenticated_access
  rate_limit_sign_in by: -> { params[:email_address].presence || request.remote_ip }

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])

    if user.save
      send_code_to(user)
      redirect_to new_auth_tokens_validations_path
    else
      redirect_to new_session_path, alert: "Esse email não parece certo, viajante."
    end
  end

  private
    def send_code_to(user)
      auth_token = user.auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)
      auth_token.deliver_later
      session[:otp_email_address] = user.email_address
      reveal_code_in_development(auth_token)
    end

    def reveal_code_in_development(auth_token)
      if Rails.env.development?
        flash[:otp_code] = auth_token.code
      end
    end
end
```

`app/controllers/auth_tokens/validations_controller.rb`:

```ruby
class AuthTokens::ValidationsController < ApplicationController
  require_unauthenticated_access only: :new
  allow_unauthenticated_access only: :create
  rate_limit_sign_in by: -> { session[:otp_email_address] || request.remote_ip }

  def new
  end

  def create
    if auth_token = AuthToken.lookup(email_address: session[:otp_email_address], code: params[:code])
      auth_token.use!
      session.delete(:otp_email_address)
      start_new_session_for(auth_token.user)
      redirect_to post_authenticating_url
    else
      redirect_to new_auth_tokens_validations_path, alert: "Código inválido ou expirado"
    end
  end
end
```

`app/controllers/home_controller.rb` (provisório; a Task 12 completa):

```ruby
class HomeController < ApplicationController
  def show
  end
end
```

- [ ] **Step 7: Views**

`app/views/sessions/new.html.erb`:

```erb
<% @page_title = "Entrar" %>
<% @hide_nav = true %>

<section class="panel flex flex-col gap-4 text-center mt-16">
  <h1 class="text-gold">LÉGUAS</h1>
  <p>Digite seu email. Vamos mandar um código pra você entrar.</p>

  <%= form_with url: auth_tokens_path, class: "flex flex-col gap-4" do |form| %>
    <%= form.label :email_address, "Email", class: "text-left text-[0.6rem]" %>
    <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "email", class: "field" %>
    <%= form.submit "Receber código", class: "btn-game" %>
  <% end %>
</section>
```

`app/views/auth_tokens/validations/new.html.erb`:

```erb
<% @page_title = "Código" %>
<% @hide_nav = true %>

<section class="panel flex flex-col gap-4 text-center mt-16">
  <h1 class="text-gold">CÓDIGO</h1>
  <p>Mandamos um código pra <strong><%= session[:otp_email_address] %></strong>.</p>

  <% if Rails.env.development? && flash[:otp_code].present? %>
    <p class="font-display text-xp" data-testid="dev-otp-code">DEV: <%= flash[:otp_code] %></p>
  <% end %>

  <%= form_with url: auth_tokens_validations_path, class: "flex flex-col gap-4" do |form| %>
    <%= form.label :code, "Código de 6 dígitos", class: "text-left text-[0.6rem]" %>
    <%= form.text_field :code, required: true, autofocus: true, inputmode: "numeric",
          autocomplete: "one-time-code", maxlength: 6, class: "field text-center tracking-[0.5em]" %>
    <%= form.submit "Entrar", class: "btn-game" %>
  <% end %>

  <p class="text-sm">Não chegou? <%= link_to "Pedir outro código", new_session_path, class: "underline" %></p>
</section>
```

`app/views/home/show.html.erb` (provisória):

```erb
<h1>Olá, viajante!</h1>
```

A barra de navegação chama `new_walk_path` e `walks_path`, que ainda não existem. Pra não quebrar, crie agora a rota que a Task 11 vai preencher:

```ruby
  resources :walks
```

Crie também um `WalksController` vazio (`class WalksController < ApplicationController; end`), só pra resolver as rotas. A Task 11 completa esse controller.

- [ ] **Step 8: Rodar e ver passar**

Run: `bin/rails test`
Expected: 0 failures

- [ ] **Step 9: Conferir no navegador**

Run: `bin/dev`. Abra http://localhost:3000, digite um email e confira que o código aparece em "DEV:" e que ele loga. Pare o servidor.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: login por código no email

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Pixel art (grade → SVG) e avatares

**Files:**
- Create: `app/models/pixel_art.rb`, `app/helpers/pixel_art_helper.rb`
- Create: `app/pixel_art/palette.yml`, `app/pixel_art/avatars/{tropeiro,romeira,peregrino,exploradora}.txt`
- Create: `test/pixel_art/palette.yml`, `test/pixel_art/insignias/gota.txt`, `test/pixel_art/insignias/torta.txt`
- Test: `test/models/pixel_art_test.rb`, `test/helpers/pixel_art_helper_test.rb`

**Interfaces:**
- Produces:
  - **Classe:** `PixelArt::ROOT`, `PixelArt::Invalid`
  - **Métodos de classe:** `PixelArt.palette(root: ROOT)` → `{"G" => "#F4C542", ...}`; `PixelArt.find(kind, key, root: ROOT)` → `PixelArt`
  - **Métodos de instância:** `#width`, `#height`, `#validate(size:)` (levanta `PixelArt::Invalid`), `#runs` → `[[x, y, largura, char], ...]` (sem `.`)
  - **Helper:** `pixel_art_tag(art, size:, label:, silhouette: false, **options)` → `<svg>`

- [ ] **Step 1: Arquivos de teste**

`test/pixel_art/palette.yml`:

```yaml
K: "#0B0D1F"
B: "#4A90D9"
```

`test/pixel_art/insignias/gota.txt` (4×4):

```
.KK.
KBBK
KBBK
.KK.
```

`test/pixel_art/insignias/torta.txt` (linha curta e uma letra fora da paleta):

```
.KK.
KBZK
KBB
.KK.
```

- [ ] **Step 2: Escrever os testes**

`test/models/pixel_art_test.rb`:

```ruby
require "test_helper"

class PixelArtTest < ActiveSupport::TestCase
  ROOT = Rails.root.join("test/pixel_art")

  test "lê a grade e mede" do
    art = PixelArt.find(:insignias, "gota", root: ROOT)

    assert_equal 4, art.width
    assert_equal 4, art.height
  end

  test "agrupa pixels iguais e seguidos em corridas, sem transparentes" do
    art = PixelArt.find(:insignias, "gota", root: ROOT)

    assert_equal [ [ 1, 0, 2, "K" ], [ 0, 1, 1, "K" ], [ 1, 1, 2, "B" ], [ 3, 1, 1, "K" ] ], art.runs.first(4)
  end

  test "valida tamanho e paleta" do
    PixelArt.find(:insignias, "gota", root: ROOT).validate(size: 4)

    assert_raises(PixelArt::Invalid) { PixelArt.find(:insignias, "gota", root: ROOT).validate(size: 16) }
    error = assert_raises(PixelArt::Invalid) { PixelArt.find(:insignias, "torta", root: ROOT).validate(size: 4) }
    assert_match "4x4", error.message
  end

  test "letra fora da paleta é inválida" do
    art = PixelArt.new(ROOT.join("insignias/torta.txt"), palette: PixelArt.palette(root: ROOT))
    art.instance_variable_set(:@rows, [ ".KK.", "KBZK", "KBBK", ".KK." ])

    error = assert_raises(PixelArt::Invalid) { art.validate(size: 4) }
    assert_match "Z", error.message
  end

  test "arquivo inexistente é inválido" do
    assert_raises(PixelArt::Invalid) { PixelArt.find(:insignias, "nao_existe", root: ROOT) }
  end
end
```

`test/helpers/pixel_art_helper_test.rb`:

```ruby
require "test_helper"

class PixelArtHelperTest < ActionView::TestCase
  setup { @art = PixelArt.find(:insignias, "gota", root: Rails.root.join("test/pixel_art")) }

  test "gera svg nítido com um rect por corrida" do
    svg = Nokogiri::HTML(pixel_art_tag(@art, size: 64, label: "Gota")).at("svg")

    assert_equal "0 0 4 4", svg["viewbox"]
    assert_equal "crispEdges", svg["shape-rendering"]
    assert_equal "Gota", svg["aria-label"]
    assert_equal @art.runs.size, svg.css("rect").size
  end

  test "silhueta pinta tudo com a cor de silhueta" do
    svg = Nokogiri::HTML(pixel_art_tag(@art, size: 64, label: "?", silhouette: true))

    assert_equal [ "var(--color-silhouette)" ], svg.css("rect").map { it["fill"] }.uniq
  end
end
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bin/rails test test/models/pixel_art_test.rb test/helpers/pixel_art_helper_test.rb`
Expected: FAIL (`uninitialized constant PixelArt`)

- [ ] **Step 4: Implementar**

`app/models/pixel_art.rb`:

```ruby
class PixelArt
  class Invalid < StandardError; end

  ROOT = Rails.root.join("app/pixel_art")
  TRANSPARENT = "."

  attr_reader :path, :rows

  def self.palette(root: ROOT)
    YAML.load_file(root.join("palette.yml"))
  end

  def self.find(kind, key, root: ROOT)
    path = root.join(kind.to_s, "#{key}.txt")

    if path.exist?
      new(path, palette: palette(root: root))
    else
      raise Invalid, "#{path}: arquivo não existe"
    end
  end

  def initialize(path, palette:)
    @path = path
    @palette = palette
    @rows = File.readlines(path, chomp: true).reject(&:blank?)
  end

  def width = rows.first.to_s.length
  def height = rows.size

  def validate(size:)
    unless height == size && rows.all? { it.length == size }
      raise Invalid, "#{path}: esperado #{size}x#{size}"
    end

    unknown = rows.join.chars.uniq - [ TRANSPARENT ] - @palette.keys
    if unknown.any?
      raise Invalid, "#{path}: cores fora da paleta: #{unknown.join(", ")}"
    end
  end

  def color(char) = @palette.fetch(char)

  def runs
    rows.each_with_index.flat_map { |row, y| runs_in(row, y) }
  end

  private
    def runs_in(row, y)
      x = 0

      row.chars.chunk_while { |a, b| a == b }.filter_map do |chunk|
        run = [ x, y, chunk.size, chunk.first ]
        x += chunk.size
        run unless chunk.first == TRANSPARENT
      end
    end
end
```

`app/helpers/pixel_art_helper.rb`:

```ruby
module PixelArtHelper
  def pixel_art_tag(art, size:, label:, silhouette: false, **options)
    rects = art.runs.map do |x, y, width, char|
      tag.rect x: x, y: y, width: width, height: 1, fill: silhouette ? "var(--color-silhouette)" : art.color(char)
    end

    tag.svg safe_join(rects), viewBox: "0 0 #{art.width} #{art.height}", width: size, height: size,
      "shape-rendering": "crispEdges", role: "img", "aria-label": label, **options
  end
end
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bin/rails test test/models/pixel_art_test.rb test/helpers/pixel_art_helper_test.rb`
Expected: 7 runs, 0 failures

- [ ] **Step 6: Paleta real e os 4 avatares**

`app/pixel_art/palette.yml`:

```yaml
K: "#0B0D1F"   # contorno
N: "#1B1F3B"   # noite
P: "#2A2F5A"   # painel
G: "#F4C542"   # dourado
g: "#B8902A"   # dourado escuro
W: "#F2EEDC"   # creme
V: "#5BC27A"   # verde
v: "#3A8A55"   # verde escuro
O: "#FF9F6B"   # laranja
o: "#C96A3E"   # laranja escuro
L: "#B98CFF"   # lendária
l: "#7A55C2"   # lendária escura
B: "#4A90D9"   # água
b: "#2B5C99"   # água escura
S: "#8A8FA8"   # pedra
s: "#5A5F78"   # pedra escura
M: "#8B5A2B"   # madeira / couro
m: "#5E3A1A"   # madeira escura
F: "#E8B89A"   # pele clara
f: "#9A6444"   # pele escura
R: "#C0504D"   # vermelho
```

Desenhe os 4 avatares, em 16×16, vistos de frente e de corpo inteiro, com contorno `K`:

| Arquivo | Personagem | Detalhes |
|---|---|---|
| `tropeiro.txt` | Chapéu de abas largas | `M`/`m`, pele `F`, lenço `R`, mochila `M` |
| `romeira.txt` | Lenço na cabeça | `B`, pele `f`, cajado `m` |
| `peregrino.txt` | Capuz | `S`/`s`, pele `F`, cabaça `G` |
| `exploradora.txt` | Boné | `V`/`v`, pele `f`, mochila grande `O` |

Cada linha tem exatamente 16 caracteres, e o fundo é `.`. O teste de conteúdo da Task 7 valida os quatro.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: pixel art em grade renderizada como SVG, com paleta e avatares

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Boas-vindas e perfil (nome, avatar, meta)

**Files:**
- Create: `app/models/user/traveler.rb`, `app/controllers/concerns/onboarding.rb`, `app/controllers/travelers_controller.rb`, `app/controllers/profiles_controller.rb`
- Create: `app/views/travelers/new.html.erb`, `app/views/travelers/_fields.html.erb`, `app/views/profiles/edit.html.erb`, `app/frontend/controllers/steps_controller.js`
- Modify: `app/models/user.rb`, `app/controllers/application_controller.rb`, `app/controllers/sessions_controller.rb`, `config/routes.rb`
- Test: `test/models/user/traveler_test.rb`, `test/controllers/travelers_controller_test.rb`, `test/controllers/profiles_controller_test.rb`

**Interfaces:**
- Consumes: `sign_in`, `Current.user`, `pixel_art_tag` e `PixelArt.find(:avatars, key)`, das Tasks 4–5.
- Produces:
  - **Constantes:** `User::Traveler::AVATARS = %w[ tropeiro romeira peregrino exploradora ]`, `User::Traveler::DAILY_GOALS = [ 2, 3, 5, 8 ]`
  - **Métodos:** `User#traveler?`; `user.save(context: :traveler)` valida `name`, `avatar` e `daily_goal_km`
  - **Macro de controller:** `allow_unnamed_traveler(**)`
  - **Rotas:** `new_traveler_path`, `traveler_path` (POST), `edit_profile_path`, `profile_path` (PATCH)

- [ ] **Step 1: Testes do model**

`test/models/user/traveler_test.rb`:

```ruby
require "test_helper"

class User::TravelerTest < ActiveSupport::TestCase
  test "viajante tem nome" do
    assert users(:viajante).traveler?
    assert_not users(:novato).traveler?
  end

  test "no contexto traveler exige nome, avatar e meta válidos" do
    user = users(:novato)
    user.assign_attributes(name: "", avatar: "dragão", daily_goal_km: 4)

    assert_not user.valid?(:traveler)
    assert user.errors.of_kind?(:name, :blank)
    assert user.errors.of_kind?(:avatar, :inclusion)
    assert user.errors.of_kind?(:daily_goal_km, :inclusion)
  end

  test "nome até 20 caracteres" do
    user = users(:novato)
    user.assign_attributes(name: "A" * 21, avatar: "romeira", daily_goal_km: 3)

    assert_not user.valid?(:traveler)
  end

  test "sem contexto, usuário sem nome é válido (acabou de pedir código)" do
    assert users(:novato).valid?
  end
end
```

- [ ] **Step 2: Testes de controller**

`test/controllers/travelers_controller_test.rb`:

```ruby
require "test_helper"

class TravelersControllerTest < ActionDispatch::IntegrationTest
  test "viajante sem nome é mandado pras boas-vindas" do
    sign_in :novato

    get root_url

    assert_redirected_to new_traveler_url
  end

  test "boas-vindas pergunta o nome" do
    sign_in :novato

    get new_traveler_url

    assert_response :success
    assert_select "h1", text: /Qual o seu nome, viajante\?/
    assert_select "input[type=radio][name='user[avatar]']", 4
  end

  test "salvar leva pro início" do
    sign_in :novato

    post traveler_url, params: { user: { name: "Zé", avatar: "peregrino", daily_goal_km: "5" } }

    assert_redirected_to root_url
    assert_equal "Zé", users(:novato).reload.name
    assert_equal 5, users(:novato).daily_goal_km
  end

  test "sem nome volta com erro" do
    sign_in :novato

    post traveler_url, params: { user: { name: "", avatar: "peregrino", daily_goal_km: "5" } }

    assert_response :unprocessable_entity
  end

  test "quem já tem nome não vê as boas-vindas de novo" do
    sign_in :viajante

    get new_traveler_url

    assert_redirected_to root_url
  end

  test "sem nome ainda consegue sair" do
    sign_in :novato

    delete session_url

    assert_redirected_to new_session_url
  end
end
```

`test/controllers/profiles_controller_test.rb`:

```ruby
require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "edita meta e avatar" do
    get edit_profile_url
    assert_response :success

    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "8" } }

    assert_redirected_to root_url
    assert_equal "romeira", users(:viajante).reload.avatar
    assert_equal 8, users(:viajante).daily_goal_km
  end

  test "não aceita meta fora das opções" do
    patch profile_url, params: { user: { name: "Tião", avatar: "romeira", daily_goal_km: "50" } }

    assert_response :unprocessable_entity
  end
end
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bin/rails test test/models/user test/controllers/travelers_controller_test.rb test/controllers/profiles_controller_test.rb`
Expected: FAIL

- [ ] **Step 4: Model**

`app/models/user/traveler.rb`:

```ruby
module User::Traveler
  extend ActiveSupport::Concern

  AVATARS = %w[ tropeiro romeira peregrino exploradora ].freeze
  DAILY_GOALS = [ 2, 3, 5, 8 ].freeze

  included do
    with_options on: :traveler do
      validates :name, presence: true, length: { maximum: 20 }
      validates :avatar, inclusion: { in: AVATARS }
      validates :daily_goal_km, inclusion: { in: DAILY_GOALS }
    end
  end

  def traveler?
    name.present?
  end
end
```

Em `app/models/user.rb`, logo após `class User < ApplicationRecord`:

```ruby
  include Traveler
```

- [ ] **Step 5: Concern de onboarding e controllers**

`app/controllers/concerns/onboarding.rb`:

```ruby
module Onboarding
  extend ActiveSupport::Concern

  included do
    before_action :require_traveler
  end

  class_methods do
    def allow_unnamed_traveler(**options)
      skip_before_action :require_traveler, **options
    end
  end

  private
    def require_traveler
      if Current.user && !Current.user.traveler?
        redirect_to new_traveler_path
      end
    end
end
```

`app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication, Onboarding

  allow_browser versions: :modern
end
```

Em `app/controllers/sessions_controller.rb`, abaixo de `require_unauthenticated_access only: :new`:

```ruby
  allow_unnamed_traveler only: :destroy
```

`app/controllers/travelers_controller.rb`:

```ruby
class TravelersController < ApplicationController
  allow_unnamed_traveler
  before_action :redirect_known_traveler

  def new
    @user = Current.user
    @user.avatar ||= User::Traveler::AVATARS.first
  end

  def create
    @user = Current.user
    @user.assign_attributes(traveler_params)

    if @user.save(context: :traveler)
      redirect_to root_path, notice: "Boa jornada, #{@user.name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirect_known_traveler
      if Current.user.traveler?
        redirect_to root_path
      end
    end

    def traveler_params
      params.expect(user: [ :name, :avatar, :daily_goal_km ])
    end
end
```

`app/controllers/profiles_controller.rb`:

```ruby
class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    @user.assign_attributes(params.expect(user: [ :name, :avatar, :daily_goal_km ]))

    if @user.save(context: :traveler)
      redirect_to root_path, notice: "Perfil atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

Rotas (acrescente em `config/routes.rb`):

```ruby
  resource :traveler, only: %i[ new create ]
  resource :profile, only: %i[ edit update ]
```

- [ ] **Step 6: Views e Stimulus**

`app/views/travelers/_fields.html.erb` (recebe `form` e `user`):

```erb
<fieldset data-steps-target="step" class="flex flex-col gap-4">
  <%= form.label :name, "Seu nome de viajante", class: "text-[0.6rem]" %>
  <%= form.text_field :name, required: true, maxlength: 20, autofocus: true, class: "field" %>
  <% user.errors.full_messages_for(:name).each do |message| %>
    <p class="field-error"><%= message %></p>
  <% end %>
</fieldset>

<fieldset data-steps-target="step" class="flex flex-col gap-4">
  <legend class="font-display text-[0.6rem] mb-2">Escolha seu viajante</legend>
  <div class="grid grid-cols-2 gap-3">
    <% User::Traveler::AVATARS.each do |avatar| %>
      <label class="panel flex flex-col items-center gap-2 has-checked:border-gold cursor-pointer">
        <%= form.radio_button :avatar, avatar, class: "sr-only" %>
        <%= pixel_art_tag PixelArt.find(:avatars, avatar), size: 64, label: avatar.humanize %>
        <span class="text-[0.55rem]"><%= avatar.humanize %></span>
      </label>
    <% end %>
  </div>
</fieldset>

<fieldset data-steps-target="step" class="flex flex-col gap-4">
  <legend class="font-display text-[0.6rem] mb-2">Quanto você costuma andar por dia?</legend>
  <div class="grid grid-cols-4 gap-2">
    <% User::Traveler::DAILY_GOALS.each do |km| %>
      <label class="panel text-center has-checked:border-gold cursor-pointer">
        <%= form.radio_button :daily_goal_km, km, checked: user.daily_goal_km.to_i == km, class: "sr-only" %>
        <span class="font-display text-xs"><%= km %> km</span>
      </label>
    <% end %>
  </div>
  <p class="text-sm">Essa é a sua missão do dia. Dá pra mudar depois no perfil.</p>
</fieldset>
```

`app/views/travelers/new.html.erb`:

```erb
<% @page_title = "Boas-vindas" %>
<% @hide_nav = true %>

<section class="panel flex flex-col gap-6 mt-8" data-controller="steps">
  <h1 class="text-gold text-center">Qual o seu nome, viajante?</h1>

  <%= form_with model: @user, url: traveler_path, method: :post, class: "flex flex-col gap-6" do |form| %>
    <%= render "travelers/fields", form: form, user: @user %>

    <div class="flex gap-3 justify-between">
      <button type="button" class="btn-game btn-game--secondary" data-steps-target="back" data-action="steps#back">Voltar</button>
      <button type="button" class="btn-game" data-steps-target="next" data-action="steps#next">Próximo</button>
      <%= form.submit "Começar jornada", class: "btn-game", data: { steps_target: "submit" } %>
    </div>
  <% end %>
</section>
```

`app/views/profiles/edit.html.erb`:

```erb
<% @page_title = "Perfil" %>

<section class="panel flex flex-col gap-6">
  <h1 class="text-gold">Perfil</h1>

  <%= form_with model: @user, url: profile_path, method: :patch, class: "flex flex-col gap-6" do |form| %>
    <%= render "travelers/fields", form: form, user: @user %>
    <%= form.submit "Salvar", class: "btn-game" %>
  <% end %>

  <%= button_to "Sair", session_path, method: :delete, class: "btn-game btn-game--secondary w-full" %>
</section>
```

`app/frontend/controllers/steps_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "step", "back", "next", "submit" ]

  connect() {
    this.show(this.firstStepWithError())
  }

  next() {
    if (this.currentStepIsValid()) this.show(this.index + 1)
  }

  back() {
    this.show(this.index - 1)
  }

  show(index) {
    this.index = Math.max(0, Math.min(index, this.stepTargets.length - 1))
    this.stepTargets.forEach((step, i) => step.hidden = i !== this.index)

    const last = this.index === this.stepTargets.length - 1
    this.backTarget.hidden = this.index === 0
    this.nextTarget.hidden = last
    this.submitTarget.hidden = !last
  }

  currentStepIsValid() {
    return [ ...this.stepTargets[this.index].querySelectorAll("input") ].every(input => input.reportValidity())
  }

  firstStepWithError() {
    const index = this.stepTargets.findIndex(step => step.querySelector(".field-error"))
    return index === -1 ? 0 : index
  }
}
```

A view de perfil não usa `data-controller="steps"`, então os três fieldsets aparecem juntos. É isso mesmo que se quer no perfil.

- [ ] **Step 7: Rodar e ver passar**

Run: `bin/rails test`
Expected: 0 failures

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: boas-vindas do viajante e perfil (nome, avatar, meta)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: O mundo: carregador, regiões, fases, marcos e milestones

**Files:**
- Create: `app/models/world.rb`, `app/models/world/region.rb`, `app/models/world/phase.rb`, `app/models/world/landmark.rb`, `app/models/world/milestone.rb`
- Create: `test/world/01_alpha.yml`, `test/world/02_beta.yml`
- Modify: `test/test_helper.rb`
- Test: `test/models/world_test.rb`

**Interfaces:**
- Produces:
  - **World (classe):** `World::ROOT`, `World::Invalid`; `World.load(path)` → `World`; `World.current` (memoizado); `World.current = world` (troca, pra testes)
  - **World (instância):** `#regions`, `#phases`, `#landmarks`, `#milestones` (ordenados), `#total_km` (BigDecimal), `#region(key)`, `#phase(key)`, `#landmark(key)`
  - **World::Region:** `key`, `name`, `inspired_by`, `trophy_name`, `number`, `phases`, `start_km`, `end_km`, `km`, `xp`, `milestones`, `next` (a próxima região ou `nil`)
  - **World::Phase:** `key`, `name`, `inspired_by`, `symbol`, `rarity`, `number`, `region`, `landmarks`, `km`, `start_km`, `end_km`, `boss?`, `legendary?`, `xp`, `insignia_size`, `milestones`
  - **World::Landmark:** `key`, `name`, `story`, `at_km` (dentro da fase), `phase`, `world_km`, `xp` (25), `milestone`
  - **World::Milestone:** `Data.define(:key, :kind, :at_km, :xp, :subject)`, com `kind` em `:landmark | :phase | :region`
  - **Teste:** helpers `test_world` e `with_world(world) { }`

- [ ] **Step 1: Mundo de teste**

`test/world/01_alpha.yml`:

```yaml
key: alpha
name: Região Alfa
inspired_by: Trilha de teste A
trophy_name: Alfa
phases:
  - key: a1
    name: Fase A1
    inspired_by: Ponto 0 → Ponto 10
    km: 10
    symbol: teste
    landmarks:
      - key: a1_mark
        name: Marco A1
        at_km: 4
        story: História do marco A1.
  - key: a2
    name: Fase A2
    inspired_by: Ponto 10 → Ponto 30
    km: 20
    rarity: rare
    symbol: teste
    landmarks:
      - key: a2_mark
        name: Marco A2
        at_km: 5
        story: História do marco A2.
```

`test/world/02_beta.yml`:

```yaml
key: beta
name: Região Beta
inspired_by: Trilha de teste B
trophy_name: Beta
phases:
  - key: b1
    name: Fase B1
    inspired_by: Ponto 30 → Ponto 60
    km: 30
    symbol: teste
  - key: b2
    name: Fase B2
    inspired_by: Ponto 60 → Ponto 100
    km: 40
    rarity: legendary
    symbol: teste
    landmarks:
      - key: b2_mark
        name: Marco B2
        at_km: 10
        story: História do marco B2.
```

Em `test/test_helper.rb`, dentro de `class ActiveSupport::TestCase` (e depois de `fixtures :all`):

```ruby
    def test_world
      World.load(Rails.root.join("test/world"))
    end

    def with_world(world)
      previous = World.current
      World.current = world
      yield
    ensure
      World.current = previous
    end
```

- [ ] **Step 2: Escrever os testes**

`test/models/world_test.rb`:

```ruby
require "test_helper"

class WorldTest < ActiveSupport::TestCase
  setup { @world = test_world }

  test "carrega as regiões na ordem dos arquivos" do
    assert_equal %w[ alpha beta ], @world.regions.map(&:key)
    assert_equal [ 1, 2 ], @world.regions.map(&:number)
  end

  test "acumula os km pelo mundo" do
    assert_equal [ 0, 10 ], [ @world.phase("a1").start_km, @world.phase("a1").end_km ]
    assert_equal [ 60, 100 ], [ @world.phase("b2").start_km, @world.phase("b2").end_km ]
    assert_equal 30, @world.region("beta").start_km
    assert_equal 100, @world.total_km
    assert_kind_of BigDecimal, @world.total_km
  end

  test "marco sabe sua posição no mundo" do
    assert_equal 15, @world.landmark("a2_mark").world_km
  end

  test "raridade define xp e tamanho da insígnia" do
    assert_equal [ 100, 16 ], [ @world.phase("a1").xp, @world.phase("a1").insignia_size ]
    assert_equal [ 250, 20 ], [ @world.phase("a2").xp, @world.phase("a2").insignia_size ]
    assert @world.phase("b2").legendary?
  end

  test "milestones em ordem de caminho: marco, fim de fase, fim de região" do
    expected = [
      [ "landmark:a1_mark", 4, 25 ], [ "phase:a1", 10, 100 ],
      [ "landmark:a2_mark", 15, 25 ], [ "phase:a2", 30, 250 ], [ "region:alpha", 30, 500 ],
      [ "phase:b1", 60, 100 ], [ "landmark:b2_mark", 70, 25 ], [ "phase:b2", 100, 250 ], [ "region:beta", 100, 500 ]
    ]

    assert_equal expected, @world.milestones.map { [ it.key, it.at_km, it.xp ] }
  end

  test "região conhece a próxima e o xp total dela" do
    assert_equal @world.region("beta"), @world.region("alpha").next
    assert_nil @world.region("beta").next
    assert_equal 300 + 25 + 100 + 25 + 250 + 500, @world.region("alpha").xp
  end

  test "marco fora da fase é inválido" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "01.yml"), <<~YAML)
        key: x
        name: X
        inspired_by: x
        trophy_name: X
        phases:
          - { key: x1, name: X1, inspired_by: x, km: 10, symbol: x,
              landmarks: [ { key: m, name: M, at_km: 10, story: s } ] }
      YAML

      assert_raises(World::Invalid) { World.load(dir) }
    end
  end

  test "chave repetida é inválida" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "01.yml"), <<~YAML)
        key: x
        name: X
        inspired_by: x
        trophy_name: X
        phases:
          - { key: dup, name: A, inspired_by: x, km: 10, symbol: x }
          - { key: dup, name: B, inspired_by: x, km: 10, symbol: x }
      YAML

      assert_raises(World::Invalid) { World.load(dir) }
    end
  end

  test "raridade desconhecida é inválida" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "01.yml"), <<~YAML)
        key: x
        name: X
        inspired_by: x
        trophy_name: X
        phases:
          - { key: x1, name: A, inspired_by: x, km: 10, symbol: x, rarity: épica }
      YAML

      assert_raises(World::Invalid) { World.load(dir) }
    end
  end
end
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bin/rails test test/models/world_test.rb`
Expected: FAIL (`uninitialized constant World`)

- [ ] **Step 4: Implementar**

`app/models/world.rb`:

```ruby
class World
  class Invalid < StandardError; end

  ROOT = Rails.root.join("config/world")

  attr_reader :regions

  class << self
    attr_writer :current

    def current
      @current ||= load(ROOT)
    end

    def load(path)
      new(Dir[File.join(path, "*.yml")].sort.map { YAML.load_file(it) })
    end
  end

  def initialize(regions_data)
    @regions = build_regions(regions_data)
    validate_unique_keys
  end

  def phases = regions.flat_map(&:phases)
  def landmarks = phases.flat_map(&:landmarks)
  def milestones = @milestones ||= regions.flat_map(&:milestones)
  def total_km = regions.last.end_km

  def region(key) = regions.find { it.key == key }
  def phase(key) = phases.find { it.key == key }
  def landmark(key) = landmarks.find { it.key == key }

  private
    def build_regions(regions_data)
      start_km = BigDecimal(0)

      regions_data.map.with_index(1) do |data, number|
        Region.new(data, world: self, number: number, start_km: start_km).tap { start_km = it.end_km }
      end
    end

    def validate_unique_keys
      duplicated = (regions + phases + landmarks).map(&:key).tally.select { |_, count| count > 1 }.keys

      if duplicated.any?
        raise Invalid, "chaves repetidas no mundo: #{duplicated.join(", ")}"
      end
    end
end
```

`app/models/world/milestone.rb`:

```ruby
World::Milestone = Data.define(:key, :kind, :at_km, :xp, :subject)
```

`app/models/world/region.rb`:

```ruby
class World::Region
  XP = 500

  attr_reader :key, :name, :inspired_by, :trophy_name, :number, :phases, :start_km

  def initialize(data, world:, number:, start_km:)
    @world = world
    @key, @name, @inspired_by, @trophy_name = data.values_at("key", "name", "inspired_by", "trophy_name")
    @number = number
    @start_km = start_km
    @phases = build_phases(data.fetch("phases"))
  end

  def end_km = phases.last.end_km
  def km = end_km - start_km
  def next = @world.regions[number]

  def milestones
    phases.flat_map(&:milestones) + [ World::Milestone.new(key: "region:#{key}", kind: :region, at_km: end_km, xp: XP, subject: self) ]
  end

  def xp
    (km * 10).floor + milestones.sum(&:xp)
  end

  private
    def build_phases(phases_data)
      phase_start = start_km

      phases_data.map.with_index(1) do |data, number|
        World::Phase.new(data, region: self, number: number, start_km: phase_start).tap { phase_start = it.end_km }
      end
    end
end
```

`app/models/world/phase.rb`:

```ruby
class World::Phase
  RARITIES = %w[ common rare legendary ].freeze

  attr_reader :key, :name, :inspired_by, :symbol, :rarity, :number, :region, :start_km, :km, :landmarks

  def initialize(data, region:, number:, start_km:)
    @key, @name, @inspired_by, @symbol = data.values_at("key", "name", "inspired_by", "symbol")
    @rarity = data.fetch("rarity", "common")
    @km = BigDecimal(data.fetch("km").to_s)
    @region = region
    @number = number
    @start_km = start_km
    @landmarks = Array(data["landmarks"]).map { World::Landmark.new(it, phase: self) }.sort_by(&:at_km)

    validate
  end

  def end_km = start_km + km
  def boss? = rarity != "common"
  def legendary? = rarity == "legendary"
  def xp = boss? ? 250 : 100
  def insignia_size = boss? ? 20 : 16

  def milestones
    landmarks.map(&:milestone) + [ World::Milestone.new(key: "phase:#{key}", kind: :phase, at_km: end_km, xp: xp, subject: self) ]
  end

  private
    def validate
      if RARITIES.exclude?(rarity)
        raise World::Invalid, "fase #{key}: raridade desconhecida #{rarity}"
      end

      if landmarks.any? { !(it.at_km > 0 && it.at_km < km) }
        raise World::Invalid, "fase #{key}: marco precisa ficar entre 0 e #{km.to_s("F")} km (exclusivo)"
      end
    end
end
```

`app/models/world/landmark.rb`:

```ruby
class World::Landmark
  XP = 25

  attr_reader :key, :name, :story, :at_km, :phase

  def initialize(data, phase:)
    @key, @name, @story = data.values_at("key", "name", "story")
    @at_km = BigDecimal(data.fetch("at_km").to_s)
    @phase = phase
  end

  def world_km = phase.start_km + at_km
  def xp = XP

  def milestone
    World::Milestone.new(key: "landmark:#{key}", kind: :landmark, at_km: world_km, xp: xp, subject: self)
  end
end
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bin/rails test test/models/world_test.rb`
Expected: 9 runs, 0 failures

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: mundo carregado de YAML com regiões, fases, marcos e milestones

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Conteúdo da Região 1 (Estrada da Promessa) e teste de conteúdo

**Files:**
- Create: `config/world/01_estrada_da_promessa.yml`
- Create: `app/pixel_art/insignias/{vale_das_aguas,colinas_douradas,planicie_dos_viajantes,estrada_luminosa,gigante_de_pedra,santuario_da_luz}.txt`
- Create: `app/pixel_art/stamps/<cada landmark key>.txt` (12 arquivos)
- Test: `test/models/world_content_test.rb`

**Interfaces:**
- Consumes: `World.load`, `PixelArt.find` e `#validate`, das Tasks 5 e 7.
- Produces: o conteúdo real que `World.current` carrega. As chaves das fases e dos marcos estão no YAML abaixo.

- [ ] **Step 1: Teste de conteúdo**

`test/models/world_content_test.rb`:

```ruby
require "test_helper"

class WorldContentTest < ActiveSupport::TestCase
  setup { @world = World.load(World::ROOT) }

  test "regiões e número de fases" do
    assert_equal [ [ "estrada_da_promessa", 6 ] ], @world.regions.map { [ it.key, it.phases.size ] }
  end

  test "Região 1 soma 322 km" do
    assert_equal 322, @world.region("estrada_da_promessa").km
  end

  test "toda fase tem insígnia válida no tamanho da raridade" do
    @world.phases.each do |phase|
      PixelArt.find(:insignias, phase.key).validate(size: phase.insignia_size)
    end
  end

  test "todo marco tem carimbo 12x12 e história" do
    @world.landmarks.each do |landmark|
      PixelArt.find(:stamps, landmark.key).validate(size: 12)
      assert landmark.story.present?, "#{landmark.key} sem história"
    end
  end

  test "todo avatar é 16x16" do
    User::Traveler::AVATARS.each { PixelArt.find(:avatars, it).validate(size: 16) }
  end
end
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bin/rails test test/models/world_content_test.rb`
Expected: FAIL (nenhuma região / arquivo não existe)

- [ ] **Step 3: YAML da Região 1**

`config/world/01_estrada_da_promessa.yml`:

```yaml
key: estrada_da_promessa
name: Estrada da Promessa
inspired_by: Caminho da Fé (ramal principal)
trophy_name: Promessa
phases:
  - key: vale_das_aguas
    name: Vale das Águas
    inspired_by: Águas da Prata → Andradas
    km: 34
    symbol: gota d'água
    landmarks:
      - key: pico_do_primeiro_folego
        name: Pico do Primeiro Fôlego
        at_km: 20
        story: >
          A primeira subida de verdade chega perto dos 1.375 metros. Quem passa por aqui
          descobre cedo que a estrada não vai ser plana.
      - key: vinhedos_do_vale
        name: Vinhedos do Vale
        at_km: 30
        story: >
          A cidade que inspira o fim desta fase é conhecida como a Capital Mineira do Vinho.
          Os parreirais começam a aparecer pouco antes da chegada.

  - key: colinas_douradas
    name: Colinas Douradas
    inspired_by: Andradas → Inconfidentes
    km: 53
    symbol: colinas
    landmarks:
      - key: serra_dos_limoeiros
        name: Serra dos Limoeiros
        at_km: 15
        story: >
          Um alto de serra a 1.221 metros. Olhando pra trás, dá pra ver o vale inteiro
          que você já atravessou.
      - key: vila_crisalida
        name: Vila Crisálida
        at_km: 36
        story: >
          Um distrito pequeno no meio do caminho, inspirado em Crisólia. Bom lugar pra
          encher a garrafa d'água.
      - key: porteira_do_ouro_miudo
        name: Porteira do Ouro Miúdo
        at_km: 43
        story: >
          Inspirada em Ouro Fino, a cidade da "estrada de Ouro Fino" que aparece na
          música Menino da Porteira.

  - key: planicie_dos_viajantes
    name: Planície dos Viajantes
    inspired_by: Inconfidentes → Estiva
    km: 59
    symbol: pegadas
    landmarks:
      - key: vila_dos_pijamas
        name: Vila dos Pijamas
        at_km: 20
        story: >
          Inspirada em Borda da Mata, que se apresenta como a capital nacional do pijama.
          Tem loja de pijama pra todo lado.
      - key: pico_do_toco
        name: Pico do Toco
        at_km: 38
        story: >
          Logo depois do vilarejo que inspira este marco vem um pico de 1.324 metros.
          Respira fundo, viajante.

  - key: estrada_luminosa
    name: Estrada Luminosa
    inspired_by: Estiva → Luminosa
    km: 66
    symbol: estrela
    landmarks:
      - key: vila_consolo
        name: Vila Consolo
        at_km: 20
        story: >
          Um vilarejo a pouco mais de mil metros de altitude, inspirado em Consolação.
          O nome já diz: aqui a subida dá uma trégua.
      - key: vila_paraiso
        name: Vila Paraíso
        at_km: 42
        story: >
          Inspirada em Paraisópolis. É dela que sai o ramal mais curto do caminho real,
          com 134 km até o santuário.

  - key: gigante_de_pedra
    name: O Gigante de Pedra
    inspired_by: Luminosa → Campos do Jordão (Serra da Mantiqueira)
    km: 38
    rarity: rare
    symbol: montanha com pico nevado
    landmarks:
      - key: teto_do_caminho
        name: Teto do Caminho
        at_km: 17
        story: >
          1.820 metros. O ponto mais alto de todo o caminho que inspira esta região.
          Daqui pra frente, o gigante começa a ceder.

  - key: santuario_da_luz
    name: Santuário da Luz
    inspired_by: Campos do Jordão → Aparecida
    km: 72
    symbol: santuário com cruz
    landmarks:
      - key: mirante_da_descida
        name: Mirante da Descida
        at_km: 30
        story: >
          Começa a longa descida da serra rumo ao vale do rio Paraíba. Os joelhos vão
          lembrar deste trecho.
      - key: vila_potira
        name: Vila Potira
        at_km: 47
        story: >
          Já no vale, perto do fim. As torres do santuário estão a menos de um dia de
          caminhada.
```

- [ ] **Step 4: Insígnias (6 arquivos)**

Todas com contorno `K`, sem texto e com leitura clara em 64 px:

| Arquivo | Tamanho | Símbolo | Cores |
|---|---|---|---|
| `vale_das_aguas.txt` | 16×16 | gota d'água | `B`/`b` com brilho `W` (exemplo abaixo, use tal qual) |
| `colinas_douradas.txt` | 16×16 | duas colinas sobrepostas | `G`/`g`, céu vazio |
| `planicie_dos_viajantes.txt` | 16×16 | duas pegadas na diagonal | `M`/`m` |
| `estrada_luminosa.txt` | 16×16 | estrela de 5 pontas | `G` com miolo `W` |
| `gigante_de_pedra.txt` | 20×20 (rara) | montanha | `S`/`s` com pico nevado `W`, moldura laranja `O` nas bordas |
| `santuario_da_luz.txt` | 16×16 | igrejinha com cruz no topo | parede `W`, telhado `M`, cruz `G` |

Exemplo, `app/pixel_art/insignias/vale_das_aguas.txt`:

```
................
.......KK.......
......KBBK......
......KBBK......
.....KBBBBK.....
.....KBWBBK.....
....KBWBBBBK....
....KBWBBBBK....
...KBBBBBBBBK...
...KBBBBBBBBK...
...KBBBBBBBbK...
...KBBBBBBBbK...
....KBBBBBbK....
....KbbBBbbK....
.....KKbbKK.....
......KKKK......
```

- [ ] **Step 5: Carimbos (12 arquivos, 12×12)**

Todo carimbo tem moldura `K` na borda, fundo `W` e um símbolo simples no miolo:

| Arquivo | Símbolo |
|---|---|
| `pico_do_primeiro_folego` | pico `S`/`s` (exemplo abaixo) |
| `vinhedos_do_vale` | cacho de uva `l` com folha `V` |
| `serra_dos_limoeiros` | limão `G` com folha `V` |
| `vila_crisalida` | casulo `M` |
| `porteira_do_ouro_miudo` | porteira `M` |
| `vila_dos_pijamas` | lua `G` |
| `pico_do_toco` | toco de árvore `M`/`m` |
| `vila_consolo` | casinha `R`/`W` |
| `vila_paraiso` | palmeira `V`/`M` |
| `teto_do_caminho` | bandeira `R` no pico `S` |
| `mirante_da_descida` | seta pra baixo `O` |
| `vila_potira` | rio `B` |

Exemplo, `app/pixel_art/stamps/pico_do_primeiro_folego.txt`:

```
KKKKKKKKKKKK
KWWWWWWWWWWK
KWWWWWWWWWWK
KWWWWSWWWWWK
KWWWSSSWWWWK
KWWSSsSSWWWK
KWSSsSSSSWWK
KWSsSSSSSSWK
KWWWWWWWWWWK
KWVVVVVVVVWK
KWWWWWWWWWWK
KKKKKKKKKKKK
```

- [ ] **Step 6: Rodar e ver passar**

Run: `bin/rails test test/models/world_content_test.rb`
Expected: 5 runs, 0 failures. Se uma grade falhar, a mensagem diz o arquivo e o problema (tamanho ou cor).

- [ ] **Step 7: Conferir a arte no navegador**

Run: `bin/rails runner 'include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper, PixelArtHelper; html = World.current.phases.map { pixel_art_tag(PixelArt.find(:insignias, it.key), size: 96, label: it.name) }.join + World.current.landmarks.map { pixel_art_tag(PixelArt.find(:stamps, it.key), size: 72, label: it.name) }.join; File.write("tmp/arte.html", "<body style=background:#1B1F3B>#{html}</body>")'`

Abra `tmp/arte.html` no navegador e ajuste qualquer grade ilegível.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: conteúdo da Região 1 (Estrada da Promessa) com insígnias e carimbos

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Caminhadas e missões (models)

**Files:**
- Create: migrations de `walks` e `missions`
- Create: `app/models/walk.rb`, `app/models/mission.rb`
- Modify: `app/models/user.rb`
- Test: `test/models/walk_test.rb`, `test/models/mission_test.rb`

**Interfaces:**
- Produces:
  - **Walk:** `Walk::DAILY_LIMIT_KM` (100), `Walk::RETROACTIVE_DAYS` (7); `user.walks`; `Walk.newest_first`; ao salvar, garante `Mission` da data
  - **Mission:** `user.missions`; `Mission.accomplished` (scope); `Mission#accomplished?`; `Mission#walked_km`
- A Task 13 acrescenta à `Walk` o callback que esquece celebrações.

- [ ] **Step 1: Migrations**

```bash
bin/rails g migration CreateWalks user:references walked_on:date "km:decimal{5,2}" note:string
bin/rails g migration CreateMissions user:references date:date "goal_km:decimal{4,1}"
```

Edite as migrations:
- `walks`: `null: false` em `walked_on` e `km`, `t.timestamps` e `add_index :walks, [ :user_id, :walked_on ]`
- `missions`: `null: false` em `date` e `goal_km`, `t.timestamps` e `add_index :missions, [ :user_id, :date ], unique: true`

Run: `bin/rails db:migrate`

- [ ] **Step 2: Testes da caminhada**

`test/models/walk_test.rb`:

```ruby
require "test_helper"

class WalkTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "km precisa ser maior que zero" do
    assert_not @user.walks.new(km: 0, walked_on: Date.current).valid?
    assert_not @user.walks.new(km: -2, walked_on: Date.current).valid?
    assert @user.walks.new(km: 0.5, walked_on: Date.current).valid?
  end

  test "aceita vírgula decimal do teclado brasileiro" do
    walk = @user.walks.create!(km: "3,5", walked_on: Date.current)

    assert_equal BigDecimal("3.5"), walk.reload.km
  end

  test "data vai de hoje até 7 dias atrás" do
    assert @user.walks.new(km: 1, walked_on: Date.current - 7).valid?
    assert_not @user.walks.new(km: 1, walked_on: Date.current - 8).valid?
    assert_not @user.walks.new(km: 1, walked_on: Date.current + 1).valid?
  end

  test "às 23h30 de Brasília ainda é hoje" do
    travel_to Time.zone.local(2026, 9, 26, 23, 30) do
      walk = @user.walks.create!(km: 2, walked_on: Date.current)

      assert_equal Date.new(2026, 9, 26), walk.walked_on
      assert @user.walks.new(km: 1, walked_on: Date.new(2026, 9, 19)).valid?
    end
  end

  test "soma do dia não passa de 100 km" do
    @user.walks.create!(km: 90, walked_on: Date.current)

    walk = @user.walks.new(km: 11, walked_on: Date.current)

    assert_not walk.valid?
    assert_includes walk.errors[:km].join, "Essa distância parece exagerada, viajante."
    assert @user.walks.new(km: 10, walked_on: Date.current).valid?
  end

  test "editar a própria caminhada não conta ela duas vezes no limite" do
    walk = @user.walks.create!(km: 60, walked_on: Date.current)

    assert walk.update(km: 70)
  end

  test "mudar a data pra um dia cheio respeita o limite" do
    @user.walks.create!(km: 90, walked_on: Date.current)
    walk = @user.walks.create!(km: 20, walked_on: Date.current - 1)

    assert_not walk.update(walked_on: Date.current)
  end

  test "caminhada antiga pode ter a observação editada" do
    walk = @user.walks.create!(km: 5, walked_on: Date.current)

    travel 10.days do
      assert walk.update(note: "Com chuva")
    end
  end

  test "caminhada antiga não pode ir pra outra data fora da janela" do
    walk = @user.walks.create!(km: 5, walked_on: Date.current)

    travel 10.days do
      assert_not walk.update(walked_on: Date.current - 9)
    end
  end

  test "salvar cria a missão do dia com a meta atual" do
    assert_difference -> { @user.missions.count }, 1 do
      @user.walks.create!(km: 1, walked_on: Date.current)
    end

    assert_equal 3, @user.missions.find_by(date: Date.current).goal_km
  end
end
```

- [ ] **Step 3: Testes da missão**

`test/models/mission_test.rb`:

```ruby
require "test_helper"

class MissionTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "meta fica congelada no primeiro registro do dia" do
    @user.walks.create!(km: 1, walked_on: Date.current)
    @user.update!(daily_goal_km: 8)
    @user.walks.create!(km: 1, walked_on: Date.current)

    assert_equal 3, @user.missions.find_by(date: Date.current).goal_km
  end

  test "cumprida quando a soma do dia alcança a meta" do
    @user.walks.create!(km: 1.5, walked_on: Date.current)
    mission = @user.missions.find_by(date: Date.current)
    assert_not mission.accomplished?

    @user.walks.create!(km: 1.5, walked_on: Date.current)
    assert mission.accomplished?
    assert_equal 3, mission.walked_km
  end

  test "scope conta só as cumpridas" do
    @user.walks.create!(km: 5, walked_on: Date.current)
    @user.walks.create!(km: 1, walked_on: Date.current - 1)

    assert_equal 1, @user.missions.accomplished.count
  end

  test "mudar a data da caminhada cria a missão da nova data" do
    walk = @user.walks.create!(km: 5, walked_on: Date.current)

    walk.update!(walked_on: Date.current - 2)

    assert @user.missions.find_by(date: Date.current - 2).accomplished?
    assert_not @user.missions.find_by(date: Date.current).accomplished?
  end
end
```

- [ ] **Step 4: Rodar e ver falhar**

Run: `bin/rails test test/models/walk_test.rb test/models/mission_test.rb`
Expected: FAIL (`undefined method 'walks'`)

- [ ] **Step 5: Implementar**

Em `app/models/user.rb`:

```ruby
class User < ApplicationRecord
  include Traveler

  has_many :auth_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :walks, dependent: :destroy
  has_many :missions, dependent: :destroy

  normalizes :email_address, with: -> { it.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

`app/models/walk.rb`:

```ruby
class Walk < ApplicationRecord
  DAILY_LIMIT_KM = 100
  RETROACTIVE_DAYS = 7

  belongs_to :user

  validates :walked_on, presence: true
  validates :km, numericality: { greater_than: 0 }
  validate :walked_on_within_window, :daily_limit_respected

  after_save :ensure_mission

  scope :newest_first, -> { order(walked_on: :desc, created_at: :desc) }

  def km=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  private
    def walked_on_within_window
      if walked_on && walked_on_changed? && !walked_on.between?(Date.current - RETROACTIVE_DAYS, Date.current)
        errors.add(:walked_on, "precisa ser de hoje ou dos últimos #{RETROACTIVE_DAYS} dias")
      end
    end

    def daily_limit_respected
      if km && walked_on && km + km_already_walked_that_day > DAILY_LIMIT_KM
        errors.add(:km, "passa de #{DAILY_LIMIT_KM} km no dia. Essa distância parece exagerada, viajante.")
      end
    end

    def km_already_walked_that_day
      user.walks.where(walked_on: walked_on).excluding(self).sum(:km)
    end

    def ensure_mission
      user.missions.find_or_create_by!(date: walked_on) { it.goal_km = user.daily_goal_km }
    end
end
```

`app/models/mission.rb`:

```ruby
class Mission < ApplicationRecord
  XP = 20

  belongs_to :user

  scope :accomplished, -> {
    where(<<~SQL)
      missions.goal_km <= (
        SELECT COALESCE(SUM(walks.km), 0) FROM walks
        WHERE walks.user_id = missions.user_id AND walks.walked_on = missions.date
      )
    SQL
  }

  def walked_km
    user.walks.where(walked_on: date).sum(:km)
  end

  def accomplished?
    walked_km >= goal_km
  end
end
```

- [ ] **Step 6: Rodar e ver passar**

Run: `bin/rails test test/models/walk_test.rb test/models/mission_test.rb`
Expected: 14 runs, 0 failures

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: caminhadas com limites e missão do dia com meta congelada

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Níveis, títulos e a jornada calculada

**Files:**
- Create: `app/models/user/level.rb`, `app/models/user/journey.rb`
- Modify: `app/models/user.rb`, `test/test_helper.rb`
- Test: `test/models/user/level_test.rb`, `test/models/user/journey_test.rb`

**Interfaces:**
- Consumes: `World` (Task 7) e `user.walks` / `user.missions.accomplished` (Task 9).
- Produces:
  - **User::Level (classe):** `User::Level::TITLES` (array de `User::Level::Title = Data.define(:key, :name, :from_level)`); `User::Level.xp_for(number)`; `User::Level.title(key)`
  - **User::Level (instância):** `User::Level.new(xp)`, com `#xp`, `#number`, `#title`, `#reached_titles` (sem Caminhante), `#progress` (0..1), `#xp_to_next`
  - **User::Journey:** `User::Journey::LEAGUE_KM` (6); `user.journey(world: World.current)`
  - **Métodos da jornada:** `#total_km`, `#leagues`, `#finished?`, `#current_phase`, `#current_region`, `#km_in_phase`, `#phase_progress`, `#next_milestone`, `#km_to_next`, `#reached_milestones`, `#completed_phases`, `#xp`, `#level`, `#achievement_keys`
  - **Teste:** helper `log_walks(user, *kms)` cria caminhadas em dias consecutivos pra trás, a partir de hoje

- [ ] **Step 1: Helper de teste**

Em `test/test_helper.rb`, dentro de `class ActiveSupport::TestCase`:

```ruby
    def log_walks(user, *kms)
      kms.each_with_index { |km, days_ago| user.walks.create!(km: km, walked_on: Date.current - days_ago) }
    end
```

- [ ] **Step 2: Testes de nível**

`test/models/user/level_test.rb`:

```ruby
require "test_helper"

class User::LevelTest < ActiveSupport::TestCase
  test "curva 40 × (n−1)²" do
    assert_equal [ 0, 40, 160, 360 ], (1..4).map { User::Level.xp_for(it) }
  end

  test "nível pelo xp, nas fronteiras" do
    assert_equal 1, User::Level.new(0).number
    assert_equal 1, User::Level.new(39).number
    assert_equal 2, User::Level.new(40).number
    assert_equal 2, User::Level.new(159).number
    assert_equal 3, User::Level.new(160).number
    assert_equal 25, User::Level.new(23_040).number
  end

  test "títulos por nível" do
    assert_equal "Caminhante", User::Level.new(User::Level.xp_for(4)).title.name
    assert_equal "Andarilho", User::Level.new(User::Level.xp_for(5)).title.name
    assert_equal "Lenda das Léguas", User::Level.new(User::Level.xp_for(30)).title.name
  end

  test "títulos alcançados não incluem Caminhante" do
    assert_equal [], User::Level.new(0).reached_titles
    assert_equal %w[ andarilho aventureiro ], User::Level.new(User::Level.xp_for(10)).reached_titles.map(&:key)
  end

  test "progresso dentro do nível" do
    level = User::Level.new(100)   # nível 2: 40..160

    assert_in_delta 0.5, level.progress
    assert_equal 60, level.xp_to_next
  end

  test "busca título pela chave" do
    assert_equal "Peregrino", User::Level.title("peregrino").name
  end
end
```

- [ ] **Step 3: Testes da jornada**

`test/models/user/journey_test.rb`:

```ruby
require "test_helper"

class User::JourneyTest < ActiveSupport::TestCase
  setup do
    @user = users(:viajante)   # meta diária 3 km
    @world = test_world
  end

  test "sem caminhadas: início da primeira fase" do
    journey = @user.journey(world: @world)

    assert_equal 0, journey.total_km
    assert_equal "a1", journey.current_phase.key
    assert_equal 0, journey.phase_progress
    assert_equal "landmark:a1_mark", journey.next_milestone.key
    assert_equal 4, journey.km_to_next
    assert_equal 0, journey.xp
  end

  test "posição no meio de uma fase" do
    log_walks @user, 5, 2   # 7 km; duas missões cumpridas? só a de 5 km (meta 3)

    journey = @user.journey(world: @world)

    assert_equal "a1", journey.current_phase.key
    assert_equal 7, journey.km_in_phase
    assert_in_delta 0.7, journey.phase_progress
    assert_equal [ "landmark:a1_mark" ], journey.achievement_keys
  end

  test "xp soma km, milestones e missões" do
    log_walks @user, 5   # 50 + marco 25 + missão 20

    assert_equal 95, @user.journey(world: @world).xp
  end

  test "exatamente no fim da fase conta como vencida" do
    log_walks @user, 10

    journey = @user.journey(world: @world)

    assert_includes journey.achievement_keys, "phase:a1"
    assert_equal "a2", journey.current_phase.key
    assert_equal 0, journey.km_in_phase
    assert_equal [ "a1" ], journey.completed_phases.map(&:key)
  end

  test "excedente atravessa pra próxima região" do
    log_walks @user, 35   # alpha termina em 30

    journey = @user.journey(world: @world)

    assert_equal "beta", journey.current_region.key
    assert_equal "b1", journey.current_phase.key
    assert_equal 5, journey.km_in_phase
    assert_equal %w[ landmark:a1_mark phase:a1 landmark:a2_mark phase:a2 region:alpha ], journey.achievement_keys.first(5)
  end

  test "mundo completo fica na última fase, cheia" do
    log_walks @user, 60, 50

    journey = @user.journey(world: @world)

    assert journey.finished?
    assert_equal "b2", journey.current_phase.key
    assert_equal 1, journey.phase_progress
    assert_nil journey.next_milestone
    assert_nil journey.km_to_next
  end

  test "títulos entram nas conquistas depois dos milestones" do
    log_walks @user, 60, 50   # xp alto o bastante pra Andarilho (640)

    keys = @user.journey(world: @world).achievement_keys

    assert_equal "region:beta", keys[keys.index("title:andarilho") - 1]
  end

  test "léguas: 6 km cada, arredondando pra baixo" do
    log_walks @user, 13

    assert_equal 2, @user.journey(world: @world).leagues
  end

  test "excluir caminhada faz voltar" do
    log_walks @user, 12
    @user.walks.first.destroy

    assert_equal "a1", @user.journey(world: @world).current_phase.key
  end
end
```

- [ ] **Step 4: Rodar e ver falhar**

Run: `bin/rails test test/models/user`
Expected: FAIL (`uninitialized constant User::Level`)

- [ ] **Step 5: Implementar**

`app/models/user/level.rb`:

```ruby
class User::Level
  Title = Data.define(:key, :name, :from_level)

  TITLES = [
    Title.new(key: "caminhante", name: "Caminhante", from_level: 1),
    Title.new(key: "andarilho", name: "Andarilho", from_level: 5),
    Title.new(key: "aventureiro", name: "Aventureiro", from_level: 10),
    Title.new(key: "peregrino", name: "Peregrino", from_level: 15),
    Title.new(key: "desbravador", name: "Desbravador", from_level: 20),
    Title.new(key: "lenda", name: "Lenda das Léguas", from_level: 25)
  ].freeze

  attr_reader :xp

  def self.xp_for(number)
    40 * (number - 1)**2
  end

  def self.title(key)
    TITLES.find { it.key == key }
  end

  def initialize(xp)
    @xp = xp.to_i
  end

  def number
    Integer.sqrt(xp / 40) + 1
  end

  def title
    TITLES.reverse.find { it.from_level <= number }
  end

  def reached_titles
    TITLES.select { it.from_level <= number }.drop(1)
  end

  def progress
    floor = self.class.xp_for(number)
    (xp - floor).fdiv(self.class.xp_for(number + 1) - floor)
  end

  def xp_to_next
    self.class.xp_for(number + 1) - xp
  end
end
```

`app/models/user/journey.rb`:

```ruby
class User::Journey
  LEAGUE_KM = 6
  XP_PER_KM = 10

  attr_reader :user, :world, :total_km

  def initialize(user, world:)
    @user = user
    @world = world
    @total_km = user.walks.sum(:km)
  end

  def leagues = (total_km / LEAGUE_KM).floor
  def finished? = total_km >= world.total_km

  def current_phase
    world.phases.find { total_km < it.end_km } || world.phases.last
  end

  def current_region = current_phase.region

  def km_in_phase
    [ total_km - current_phase.start_km, current_phase.km ].min
  end

  def phase_progress
    km_in_phase / current_phase.km
  end

  def next_milestone
    world.milestones.find { it.at_km > total_km }
  end

  def km_to_next
    if milestone = next_milestone
      milestone.at_km - total_km
    end
  end

  def reached_milestones
    world.milestones.select { it.at_km <= total_km }
  end

  def completed_phases
    world.phases.select { it.end_km <= total_km }
  end

  def xp
    @xp ||= (total_km * XP_PER_KM).floor + reached_milestones.sum(&:xp) + Mission::XP * user.missions.accomplished.count
  end

  def level
    User::Level.new(xp)
  end

  def achievement_keys
    reached_milestones.map(&:key) + level.reached_titles.map { "title:#{it.key}" }
  end
end
```

Em `app/models/user.rb`, acrescente:

```ruby
  def journey(world: World.current)
    Journey.new(self, world: world)
  end
```

- [ ] **Step 6: Rodar e ver passar**

Run: `bin/rails test test/models`
Expected: 0 failures

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: níveis, títulos e jornada calculada a partir das caminhadas

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Registrar, editar e excluir caminhadas (controller e telas)

**Files:**
- Modify: `app/controllers/walks_controller.rb` (o esqueleto da Task 4)
- Create: `app/views/walks/new.html.erb`, `app/views/walks/edit.html.erb`, `app/views/walks/_form.html.erb`, `app/views/walks/index.html.erb`
- Test: `test/controllers/walks_controller_test.rb`

**Interfaces:**
- Consumes: `Walk`, `user.journey` e `#level`, das Tasks 9–10.
- Produces: `WalksController#create`, que redireciona pra `celebration_path` quando houver celebração pendente (a partir da Task 13) e, senão, pro `root_path` com um flash "+N XP". Nesta task, `create` sempre vai pro início. A Task 13 troca a condição.

- [ ] **Step 1: Testes**

`test/controllers/walks_controller_test.rb`:

```ruby
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

  test "caminhada inválida volta com erro" do
    post walks_url, params: { walk: { km: "0", walked_on: Date.current.iso8601 } }

    assert_response :unprocessable_entity
    assert_select ".field-error"
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
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bin/rails test test/controllers/walks_controller_test.rb`
Expected: FAIL (`The action 'new' could not be found`)

- [ ] **Step 3: Controller**

`app/controllers/walks_controller.rb`:

```ruby
class WalksController < ApplicationController
  before_action :set_walk, only: %i[ edit update destroy ]

  def index
    @walks = Current.user.walks.newest_first
  end

  def new
    @walk = Current.user.walks.new(walked_on: Date.current)
  end

  def create
    @walk = Current.user.walks.new(walk_params)
    xp_before = Current.user.journey.xp

    if @walk.save
      redirect_after_progress(xp_before)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @walk.update(walk_params)
      redirect_to walks_path, notice: "Caminhada atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @walk.destroy
    redirect_to walks_path, notice: "Caminhada removida."
  end

  private
    def set_walk
      @walk = Current.user.walks.find(params[:id])
    end

    def walk_params
      params.expect(walk: [ :km, :walked_on, :note ])
    end

    def redirect_after_progress(xp_before)
      redirect_to root_path, notice: progress_notice(xp_before, Current.user.journey.xp)
    end

    def progress_notice(xp_before, xp_after)
      level_before = User::Level.new(xp_before).number
      level_after = User::Level.new(xp_after).number

      if level_after > level_before
        "+#{xp_after - xp_before} XP · Nível #{level_after}!"
      else
        "+#{xp_after - xp_before} XP"
      end
    end
end
```

- [ ] **Step 4: Views**

`app/views/walks/_form.html.erb`:

```erb
<%= form_with model: walk, class: "flex flex-col gap-4" do |form| %>
  <div class="flex flex-col gap-2">
    <%= form.label :km, "Quantos km?", class: "text-[0.6rem]" %>
    <%= form.text_field :km, value: walk.km&.to_s("F"), required: true, inputmode: "decimal",
          autocomplete: "off", autofocus: walk.new_record?, class: "field text-center text-3xl" %>
    <% if walk.new_record? %>
      <div class="grid grid-cols-3 gap-2">
        <% [ 2, 3, 5 ].each do |km| %>
          <button type="button" class="btn-game btn-game--secondary"
                  onclick="this.form.elements['walk[km]'].value = '<%= km %>'"><%= km %> km</button>
        <% end %>
      </div>
    <% end %>
    <% walk.errors.full_messages_for(:km).each do |message| %>
      <p class="field-error"><%= message %></p>
    <% end %>
  </div>

  <div class="flex flex-col gap-2">
    <%= form.label :walked_on, "Quando?", class: "text-[0.6rem]" %>
    <%= form.date_field :walked_on, min: Date.current - Walk::RETROACTIVE_DAYS, max: Date.current, required: true, class: "field" %>
    <% walk.errors.full_messages_for(:walked_on).each do |message| %>
      <p class="field-error"><%= message %></p>
    <% end %>
  </div>

  <div class="flex flex-col gap-2">
    <%= form.label :note, "Observação (opcional)", class: "text-[0.6rem]" %>
    <%= form.text_field :note, maxlength: 140, class: "field" %>
  </div>

  <%= form.submit walk.new_record? ? "Registrar caminhada" : "Salvar", class: "btn-game" %>
<% end %>
```

`app/views/walks/new.html.erb`:

```erb
<% @page_title = "Registrar" %>

<section class="panel flex flex-col gap-4">
  <h1 class="text-gold">Registrar caminhada</h1>
  <%= render "form", walk: @walk %>
</section>
```

`app/views/walks/edit.html.erb`:

```erb
<% @page_title = "Editar caminhada" %>

<section class="panel flex flex-col gap-4">
  <h1 class="text-gold">Editar caminhada</h1>
  <%= render "form", walk: @walk %>
</section>
```

`app/views/walks/index.html.erb`:

```erb
<% @page_title = "Histórico" %>

<section class="panel flex flex-col gap-4">
  <h1 class="text-gold">Histórico</h1>

  <% if @walks.any? %>
    <ul class="flex flex-col gap-3">
      <% @walks.each do |walk| %>
        <li class="flex items-center justify-between gap-3 border-b-2 border-ink pb-3">
          <div>
            <p class="font-display text-xs text-gold"><%= walk.km.to_s("F") %> km</p>
            <p class="text-sm"><%= l walk.walked_on, format: :long %><%= " · #{walk.note}" if walk.note.present? %></p>
          </div>
          <div class="flex gap-2">
            <%= link_to "Editar", edit_walk_path(walk), class: "btn-game btn-game--secondary text-[0.5rem] min-h-0 py-2 px-3" %>
            <%= button_to "Excluir", walk_path(walk), method: :delete,
                  class: "btn-game btn-game--secondary text-[0.5rem] min-h-0 py-2 px-3",
                  form: { data: { turbo_confirm: "Excluir essa caminhada? Seu progresso vai ser recalculado." } } %>
          </div>
        </li>
      <% end %>
    </ul>
  <% else %>
    <p>Nenhuma caminhada ainda. A estrada tá esperando, viajante.</p>
    <%= link_to "Registrar caminhada", new_walk_path, class: "btn-game" %>
  <% end %>
</section>
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bin/rails test test/controllers/walks_controller_test.rb`
Expected: 6 runs, 0 failures

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: registrar, editar e excluir caminhadas

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Início com HUD, fase atual e missão do dia

**Files:**
- Modify: `app/controllers/home_controller.rb`, `app/views/home/show.html.erb`
- Test: `test/controllers/home_controller_test.rb`

**Interfaces:**
- Consumes: `user.journey`, `User::Level`, `Mission` e os helpers `pixel_art_tag` e `segmented_progress`.
- Produces: a tela inicial. Sem API nova.

- [ ] **Step 1: Testes**

`test/controllers/home_controller_test.rb`:

```ruby
require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "HUD com nome, nível, título e xp" do
    get root_url

    assert_select "[data-testid=hud]" do
      assert_select "*", text: /Tião/
      assert_select "*", text: /Nível 1/
      assert_select "*", text: /Caminhante/
    end
  end

  test "fase atual e próximo marco" do
    users(:viajante).walks.create!(km: 5, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=phase]" do
      assert_select "*", text: /Vale das Águas/
      assert_select "*", text: %r{5 / 34 km}
      assert_select "*", text: /Pico do Primeiro Fôlego/
      assert_select "*", text: /faltam 15 km/
    end
  end

  test "missão do dia com a meta e o feito" do
    users(:viajante).walks.create!(km: 1.5, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=mission]", text: %r{1,5 / 3 km}
  end

  test "missão cumprida" do
    users(:viajante).walks.create!(km: 3, walked_on: Date.current)

    get root_url

    assert_select "[data-testid=mission]", text: /Missão cumprida/
  end

  test "botão grande de registrar" do
    get root_url

    assert_select "a[href=?]", new_walk_path, text: "Registrar caminhada"
  end
end
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bin/rails test test/controllers/home_controller_test.rb`
Expected: FAIL

- [ ] **Step 3: Controller**

`app/controllers/home_controller.rb`:

```ruby
class HomeController < ApplicationController
  def show
    @journey = Current.user.journey
    @level = @journey.level
    @mission_goal = Current.user.missions.find_by(date: Date.current)&.goal_km || Current.user.daily_goal_km
    @walked_today = Current.user.walks.where(walked_on: Date.current).sum(:km)
  end
end
```

- [ ] **Step 4: View**

`app/views/home/show.html.erb`:

```erb
<% @page_title = "Início" %>

<section class="panel flex items-center gap-4" data-testid="hud">
  <%= link_to edit_profile_path, aria: { label: "Perfil" } do %>
    <%= pixel_art_tag PixelArt.find(:avatars, Current.user.avatar), size: 64, label: Current.user.name %>
  <% end %>
  <div class="flex-1 flex flex-col gap-2">
    <p class="font-display text-xs"><%= Current.user.name %></p>
    <p class="text-sm"><span class="text-gold">Nível <%= @level.number %></span> · <%= @level.title.name %></p>
    <%= segmented_progress @level.progress, color: :xp %>
    <p class="text-xs"><%= @level.xp %> XP · faltam <%= @level.xp_to_next %> pro próximo nível</p>
  </div>
</section>

<section class="panel flex flex-col gap-3" data-testid="phase">
  <% phase = @journey.current_phase %>
  <p class="text-xs"><%= phase.region.name %> · Fase <%= phase.number %> de <%= phase.region.phases.size %></p>
  <h2 class="<%= phase.boss? ? "text-boss" : "text-gold" %>"><%= "Chefão: " if phase.boss? %><%= phase.name %></h2>
  <%= segmented_progress @journey.phase_progress %>
  <p class="font-display text-[0.6rem]"><%= number_with_precision @journey.km_in_phase, precision: 1, strip_insignificant_zeros: true %> / <%= phase.km.to_i %> km</p>

  <% if milestone = @journey.next_milestone %>
    <p>Próximo marco: <strong><%= milestone.subject.name %></strong>, faltam <%= number_with_precision @journey.km_to_next, precision: 1, strip_insignificant_zeros: true %> km</p>
  <% else %>
    <p class="text-gold">Você completou o mundo, viajante!</p>
  <% end %>

  <p class="text-sm">Total: <%= number_with_precision @journey.total_km, precision: 1, strip_insignificant_zeros: true %> km · <%= @journey.leagues %> léguas</p>
</section>

<section class="panel flex flex-col gap-3" data-testid="mission">
  <h2>Missão do dia</h2>
  <% if @walked_today >= @mission_goal %>
    <p class="text-xp">Missão cumprida! +<%= Mission::XP %> XP</p>
  <% else %>
    <p>Caminhar <%= number_with_precision @mission_goal, precision: 1, strip_insignificant_zeros: true %> km</p>
  <% end %>
  <%= segmented_progress @walked_today / @mission_goal, segments: 6, color: :xp %>
  <p class="font-display text-[0.6rem]"><%= number_with_precision @walked_today, precision: 1, strip_insignificant_zeros: true %> / <%= number_with_precision @mission_goal, precision: 1, strip_insignificant_zeros: true %> km</p>
</section>

<%= link_to "Registrar caminhada", new_walk_path, class: "btn-game text-sm py-6" %>
```

Com o locale pt-BR, `number_with_precision` usa vírgula decimal (1,5). Os testes contam com isso.

- [ ] **Step 5: Rodar e ver passar**

Run: `bin/rails test`
Expected: 0 failures

- [ ] **Step 6: Conferir no navegador**

Run: `bin/dev`. Entre, passe pelas boas-vindas, registre 5 km e confira o HUD, a fase e a missão num viewport de 375 px. Pare o servidor.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: início com HUD, fase atual e missão do dia

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Celebrações (model, esquecimento e redirecionamento)

**Files:**
- Create: migration de `celebrations`, `app/models/celebration.rb`, `app/models/user/celebrations.rb`, `app/models/achievement.rb`
- Modify: `app/models/user.rb`, `app/models/walk.rb`, `app/controllers/walks_controller.rb`
- Test: `test/models/user/celebrations_test.rb`, `test/models/achievement_test.rb`

**Interfaces:**
- Consumes: `user.journey.achievement_keys` (Task 10) e `World#landmark/#phase/#region`, `User::Level.title` (Tasks 7 e 10).
- Produces:
  - **User::Celebrations:** `User#pending_celebration_keys` → Array<String> (em ordem), `#next_celebration_key` → String ou nil, `#celebrate(key)`, `#forget_unreached_celebrations`
  - **Achievement:** `Achievement.find(key, world: World.current)` → `Achievement`, com `#key`, `#kind` (`"landmark" | "phase" | "region" | "title"`) e `#subject`
  - **Controller:** `WalksController#create` e `#update` passam a redirecionar pra `celebration_path` quando houver pendência. A rota vem na Task 14; crie-a nesta task.

- [ ] **Step 1: Migration**

```bash
bin/rails g migration CreateCelebrations user:references key:string
```

Edite: `null: false` em `key`, `t.timestamps` e `add_index :celebrations, [ :user_id, :key ], unique: true`.

Run: `bin/rails db:migrate`

- [ ] **Step 2: Testes**

`test/models/user/celebrations_test.rb`:

```ruby
require "test_helper"

class User::CelebrationsTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "pendentes seguem a ordem do caminho" do
    with_world test_world do
      log_walks @user, 12

      assert_equal %w[ landmark:a1_mark phase:a1 ], @user.pending_celebration_keys
      assert_equal "landmark:a1_mark", @user.next_celebration_key
    end
  end

  test "celebrar tira da lista e é idempotente" do
    with_world test_world do
      log_walks @user, 12

      @user.celebrate("landmark:a1_mark")
      @user.celebrate("landmark:a1_mark")

      assert_equal %w[ phase:a1 ], @user.pending_celebration_keys
      assert_equal 1, @user.celebrations.count
    end
  end

  test "excluir caminhada esquece conquistas que deixaram de valer" do
    with_world test_world do
      log_walks @user, 12
      @user.pending_celebration_keys.each { @user.celebrate(it) }

      @user.walks.first.update!(km: 5)

      assert_equal %w[ landmark:a1_mark ], @user.celebrations.pluck(:key)
    end
  end

  test "reconquistar mostra de novo" do
    with_world test_world do
      log_walks @user, 12
      @user.pending_celebration_keys.each { @user.celebrate(it) }

      @user.walks.first.destroy
      log_walks @user, 12

      assert_equal %w[ landmark:a1_mark phase:a1 ], @user.pending_celebration_keys
    end
  end
end
```

`test/models/achievement_test.rb`:

```ruby
require "test_helper"

class AchievementTest < ActiveSupport::TestCase
  setup { @world = test_world }

  test "resolve cada tipo de chave" do
    assert_equal "Marco A1", Achievement.find("landmark:a1_mark", world: @world).subject.name
    assert_equal "Fase A2", Achievement.find("phase:a2", world: @world).subject.name
    assert_equal "Região Beta", Achievement.find("region:beta", world: @world).subject.name
    assert_equal "Andarilho", Achievement.find("title:andarilho", world: @world).subject.name
    assert_equal "phase", Achievement.find("phase:a2", world: @world).kind
  end

  test "chave desconhecida vira nil" do
    assert_nil Achievement.find("phase:nao_existe", world: @world)
    assert_nil Achievement.find("bobagem", world: @world)
  end
end
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bin/rails test test/models/user/celebrations_test.rb test/models/achievement_test.rb`
Expected: FAIL

- [ ] **Step 4: Implementar**

`app/models/celebration.rb`:

```ruby
class Celebration < ApplicationRecord
  belongs_to :user

  validates :key, presence: true, uniqueness: { scope: :user_id }
end
```

`app/models/user/celebrations.rb`:

```ruby
module User::Celebrations
  extend ActiveSupport::Concern

  included do
    has_many :celebrations, dependent: :destroy
  end

  def pending_celebration_keys
    journey.achievement_keys - celebrations.pluck(:key)
  end

  def next_celebration_key
    pending_celebration_keys.first
  end

  def celebrate(key)
    celebrations.find_or_create_by!(key: key)
  end

  def forget_unreached_celebrations
    celebrations.where.not(key: journey.achievement_keys).delete_all
  end
end
```

Em `app/models/user.rb`, troque `include Traveler` por:

```ruby
  include Celebrations, Traveler
```

Em `app/models/walk.rb`, abaixo de `after_save :ensure_mission`:

```ruby
  after_update_commit :forget_unreached_celebrations
  after_destroy_commit :forget_unreached_celebrations
```

e, nos privados (depois de `ensure_mission`):

```ruby
    def forget_unreached_celebrations
      user.forget_unreached_celebrations
    end
```

`app/models/achievement.rb`:

```ruby
Achievement = Data.define(:key, :kind, :subject) do
  def self.find(key, world: World.current)
    kind, subject_key = key.to_s.split(":", 2)

    if subject = subject_for(kind, subject_key, world)
      new(key: key, kind: kind, subject: subject)
    end
  end

  def self.subject_for(kind, subject_key, world)
    case kind
    when "landmark" then world.landmark(subject_key)
    when "phase" then world.phase(subject_key)
    when "region" then world.region(subject_key)
    when "title" then User::Level.title(subject_key)
    end
  end
end
```

- [ ] **Step 5: Redirecionar pra celebração**

Em `config/routes.rb`:

```ruby
  resource :celebration, only: %i[ show create ]
```

Em `app/controllers/walks_controller.rb`, substitua `redirect_after_progress` e ajuste o `update`:

```ruby
  def update
    if @walk.update(walk_params)
      if Current.user.next_celebration_key
        redirect_to celebration_path
      else
        redirect_to walks_path, notice: "Caminhada atualizada."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end
```

```ruby
    def redirect_after_progress(xp_before)
      if Current.user.next_celebration_key
        redirect_to celebration_path
      else
        redirect_to root_path, notice: progress_notice(xp_before, Current.user.journey.xp)
      end
    end
```

Acrescente ao `test/controllers/walks_controller_test.rb`:

```ruby
  test "vencer um marco leva pra celebração" do
    post walks_url, params: { walk: { km: "20", walked_on: Date.current.iso8601 } }

    assert_redirected_to celebration_url
  end
```

- [ ] **Step 6: Rodar e ver passar**

Run: `bin/rails test test/models test/controllers/walks_controller_test.rb`
Expected: 0 failures. O `CelebrationsController` só chega na Task 14, mas `assert_redirected_to` não segue o redirect, então o teste passa sem ele.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: celebrações pendentes, esquecimento ao editar e redirect após caminhar

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Telas de celebração

**Files:**
- Create: `app/controllers/celebrations_controller.rb`
- Create: `app/views/celebrations/show.html.erb`, `app/views/celebrations/_landmark.html.erb`, `_phase.html.erb`, `_region.html.erb`, `_title.html.erb`
- Test: `test/controllers/celebrations_controller_test.rb`

**Interfaces:**
- Consumes: `User#next_celebration_key`, `#pending_celebration_keys` e `#celebrate` (Task 13); `Achievement.find`; `pixel_art_tag`.
- Produces: `GET /celebration` mostra a próxima pendente (ou redireciona pro início); `POST /celebration` com `key` marca como vista e redireciona pra `/celebration`.

- [ ] **Step 1: Testes**

`test/controllers/celebrations_controller_test.rb`:

```ruby
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
```

A 5 km/dia a Região 1 leva uns dois meses, então os testes de chefão e de região usam `log_walks` com até 100 km/dia em dias diferentes. Os XP esperados: 322 km dão 3.220, mais 12 marcos (300), 5 fases (500), 1 chefão (250), a região (500) e as missões (4 × 20). Isso dá 4.850 XP (nível 12), o que garante os títulos Andarilho e Aventureiro. O teste celebra tudo antes, menos a região e o Andarilho, pra ver só essas duas telas.

- [ ] **Step 2: Rodar e ver falhar**

Run: `bin/rails test test/controllers/celebrations_controller_test.rb`
Expected: FAIL (`uninitialized constant CelebrationsController`)

- [ ] **Step 3: Controller**

`app/controllers/celebrations_controller.rb`:

```ruby
class CelebrationsController < ApplicationController
  def show
    if key = Current.user.next_celebration_key
      @achievement = Achievement.find(key)
    else
      redirect_to root_path
    end
  end

  def create
    if Current.user.pending_celebration_keys.include?(params[:key])
      Current.user.celebrate(params[:key])
    end

    redirect_to celebration_path
  end
end
```

As chaves pendentes são geradas a partir do mundo atual (`journey.achievement_keys`), então `Achievement.find` nunca devolve `nil` no `show`.

- [ ] **Step 4: Views**

`app/views/celebrations/show.html.erb`:

```erb
<% @page_title = "Conquista" %>
<% @hide_nav = true %>

<section class="panel flex flex-col items-center gap-5 text-center mt-8">
  <%= render @achievement.kind, achievement: @achievement %>

  <%= button_to "Continuar", celebration_path, params: { key: @achievement.key }, class: "btn-game w-full" %>
</section>
```

`app/views/celebrations/_landmark.html.erb`:

```erb
<% landmark = achievement.subject %>
<h1 class="text-gold">Carimbo conquistado!</h1>
<%= pixel_art_tag PixelArt.find(:stamps, landmark.key), size: 120, label: "Carimbo #{landmark.name}" %>
<h2><%= landmark.name %></h2>
<p><%= landmark.story %></p>
<p class="font-display text-[0.6rem] text-xp">+<%= landmark.xp %> XP</p>
```

`app/views/celebrations/_phase.html.erb`:

```erb
<% phase = achievement.subject %>
<h1 class="<%= phase.boss? ? "text-boss" : "text-gold" %>"><%= phase.boss? ? "Chefão derrotado!" : "Conquista desbloqueada!" %></h1>
<%= pixel_art_tag PixelArt.find(:insignias, phase.key), size: phase.insignia_size * 8, label: "Insígnia #{phase.name}" %>
<h2>Fase <%= phase.number %> vencida: <%= phase.name %></h2>
<p class="text-sm">Inspirada no trecho <%= phase.inspired_by %>.</p>
<p class="font-display text-[0.6rem] text-xp">+<%= phase.xp %> XP</p>
```

`app/views/celebrations/_region.html.erb`:

```erb
<% region = achievement.subject %>
<h1 class="text-gold">NÍVEL COMPLETO!</h1>
<h2><%= region.name %></h2>
<div class="flex flex-wrap justify-center gap-2">
  <% region.phases.each do |phase| %>
    <%= pixel_art_tag PixelArt.find(:insignias, phase.key), size: phase.insignia_size * 3, label: phase.name %>
  <% end %>
</div>
<dl class="grid grid-cols-3 gap-2 w-full font-display text-[0.55rem]">
  <div class="panel"><dt>Distância</dt><dd class="text-gold"><%= region.km.to_i %> km</dd></div>
  <div class="panel"><dt>Fases</dt><dd class="text-gold"><%= region.phases.size %></dd></div>
  <div class="panel"><dt>XP</dt><dd class="text-gold"><%= region.xp %></dd></div>
</dl>
<% if next_region = region.next %>
  <p>A próxima região te espera: <strong><%= next_region.name %></strong>.</p>
<% else %>
  <p>Você completou o mundo inteiro, viajante.</p>
<% end %>
```

`app/views/celebrations/_title.html.erb`:

```erb
<% title = achievement.subject %>
<h1 class="text-gold">Novo título!</h1>
<%= pixel_art_tag PixelArt.find(:avatars, Current.user.avatar), size: 96, label: Current.user.name %>
<h2><%= Current.user.name %>, agora você é <%= title.name %></h2>
<p>Nível <%= title.from_level %> alcançado.</p>
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bin/rails test`
Expected: 0 failures

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: telas de celebração de carimbo, insígnia, região e título

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 15: Teste de sistema do fluxo principal

**Files:**
- Create/Modify: `test/application_system_test_case.rb`, `Gemfile` (se faltar capybara/selenium)
- Create: `test/system/journey_flow_test.rb`

**Interfaces:**
- Consumes: todas as telas das Tasks 4–14.

- [ ] **Step 1: Driver no tamanho de celular**

Confira se o `Gemfile` tem, no grupo `:test`, `gem "capybara"` e `gem "selenium-webdriver"`. Se não tiver (o Rails 8.1 pode não gerar system tests por padrão), acrescente e rode `bundle install`.

`test/application_system_test_case.rb` (crie ou substitua):

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ] do |options|
    options.binary = ENV.fetch("CHROME_BIN", "/usr/bin/chromium")
  end
end
```

- [ ] **Step 2: Escrever o teste**

`test/system/journey_flow_test.rb`:

```ruby
require "application_system_test_case"

class JourneyFlowTest < ApplicationSystemTestCase
  test "novo viajante entra, caminha 34 km e ganha a primeira insígnia" do
    visit root_url
    fill_in "Email", with: "estreante@leguas.test"
    click_on "Receber código"

    fill_in "Código de 6 dígitos", with: User.find_by(email_address: "estreante@leguas.test").auth_tokens.last.code
    click_on "Entrar"

    assert_text "Qual o seu nome, viajante?"
    fill_in "Seu nome de viajante", with: "Nina"
    click_on "Próximo"
    find("label", text: "Romeira").click
    click_on "Próximo"
    find("label", text: "5 km").click
    click_on "Começar jornada"

    assert_text "Boa jornada, Nina!"
    assert_text "Vale das Águas"

    click_on "Registrar caminhada", match: :first
    fill_in "Quantos km?", with: "34"
    click_on "Registrar caminhada"

    assert_text "Carimbo conquistado!"
    click_on "Continuar"
    assert_text "Vinhedos do Vale"
    click_on "Continuar"
    assert_text "Conquista desbloqueada!"
    assert_text "Vale das Águas"
    click_on "Continuar"

    assert_text "Colinas Douradas"
    assert_text "Missão cumprida!"
  end
end
```

- [ ] **Step 3: Rodar**

Run: `bin/rails test:system`
Expected: 1 run, 0 failures. Se falhar por um seletor, corrija a view ou o seletor. Não pule o teste.

- [ ] **Step 4: Suíte inteira e lint**

Run: `bin/rails test && bin/rails test:system && bin/rubocop && bin/brakeman --no-pager -q`
Expected: tudo verde, sem ofensas nem warnings.

- [ ] **Step 5: Commit e push**

```bash
git add -A
git commit -m "test: fluxo completo do novo viajante até a primeira insígnia

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push
```
