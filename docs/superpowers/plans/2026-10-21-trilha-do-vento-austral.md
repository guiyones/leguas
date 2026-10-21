# Léguas: Trilha do Vento Austral — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de escrever código Rails, carregue o skill `superpowers-ruby:37signals-style`.

**Goal:** Trocar o mundo do Léguas pela Trilha do Vento Austral: 6 fases de treino com chefes, sugestão semanal calculada por km, registro de escada e peso da mochila.

**Architecture:** O conteúdo continua em YAML: `World::Phase` ganha `World::Boss` e `World::Week`. `User::Journey` deixa de comparar só o `total_km` com marcos fixos e passa a reproduzir os registros dia a dia (`User::TrainingLog`). Assim ele sabe quando cada chefe apareceu e caiu, a posição limitada pelo chefe que espera e os km guardados. Nada de progresso é gravado. A escada vira o model `StairSession`, e o desnível sai de `users.stair_steps`.

**Tech Stack:** Rails 8.1, Ruby 4.0.6 (comandos com prefixo `mise exec ruby@4.0.6 --`), Minitest, Hotwire/Stimulus (importmap, `app/frontend/`), Tailwind 4.

**Spec:** `docs/superpowers/specs/2026-10-21-trilha-do-vento-austral-design.md` (o spec do MVP, `2026-09-25-leguas-design.md`, vale onde este não muda). Plano original de treino: `docs/research/2026-10-21-plano-vento-austral.yml`.

## Global Constraints

- **Nunca gravar posição, XP ou chefe vencido.** Tudo sai do replay de `walks` + `stair_sessions`.
- Uma fase com chefe só é vencida com **km completo + chefe derrubado**. O chefe aparece quando a posição chega no `end_km` da fase. Ele só cai com um feito **no dia em que apareceu ou depois**, e **no máximo um chefe cai por dia**.
- **Km guardados** = `total_km − position_km`. O XP de km usa `total_km`.
- Feitos: `distance` (uma caminhada com `km ≥ boss.km`), `distance_with_load` (+ `load_kg ≥ boss.load_kg`), `climb` (soma do desnível das sessões do dia `≥ boss.climb_m`), `climb_with_load` (só as sessões com `load_kg ≥ boss.load_kg`), `consecutive_days` (`boss.days` dias de calendário seguidos, todos ≥ dia de aparecimento e depois do último chefe derrubado, cada um com pelo menos uma caminhada com `load_kg ≥ boss.load_kg`, e soma de **todas** as caminhadas desses dias `≥ boss.km`).
- `load_kg` vazio conta como 0.
- Degrau = **0,17 m**. Desnível da sessão = `climbs × user.stair_steps × 0.17`. XP de escada = `floor(desnível total ÷ 5)`. Escada não soma km nem conta pra missão do dia.
- Limites: `load_kg` entre 0 (exclusivo) e 40, opcional; até 500 subidas por dia; `stair_steps` de 1 a 1000; janela de 7 dias pra trás como a de `Walk`.
- Celebrações: chave nova `boss:<phase_key>` (o chefe apareceu). Ordem no caminho: marco → `boss:` → `phase:` → `region:` → título.
- Raridade: fases 1–5 `rare`, fase 6 `legendary`. Tabela de XP do MVP sem mudança. O XP do `boss:` é 0.
- Semana da sugestão = posição do km dentro da fase nas somas acumuladas de `weeks[].km`. A 4ª semana é a "semana leve". Com o km da fase completo, não há semana e entra o card do chefe.
- Textos em pt-BR, sem linguagem de falha, atraso ou cobrança ("atrasado", "perdeu", "falhou" não aparecem). Estilo `STYLE.md`. Commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, sem push.

## Review Focus

1. **Desfazer um chefe.** Editar ou excluir a caminhada que derrubou um chefe faz ele voltar a esperar: a fase volta a `:boss`, os km guardados são recalculados e a celebração `phase:` é esquecida. Teste na Task 3.
2. **Mudar `stair_steps`.** Diminuir os degraus no perfil pode desfazer um chefe de escada, e a celebração tem que ser esquecida. Teste na Task 3.
3. **Mochila vazia.** Caminhada sem `load_kg` nunca derruba chefe com carga, mas conta km normalmente. Teste na Task 2.
4. **Várias caminhadas no dia.** 6 + 6 km no mesmo dia não derrubam o chefe de 12 km. No `consecutive_days`, caminhadas sem carga entram na soma se o dia tiver uma com carga. Teste na Task 2.
5. **Viajante parado com chefe esperando.** Semanas depois, o início mostra o chefe e os km guardados, sem nenhum texto de atraso. Teste na Task 5.

---

### Task 1: Mochila na caminhada e o model de escada

**Files:**
- Create: `db/migrate/*_add_load_kg_to_walks.rb`, `db/migrate/*_add_stair_steps_to_users.rb`, `db/migrate/*_create_stair_sessions.rb`
- Create: `app/models/concerns/backdatable.rb`, `app/models/stair_session.rb`
- Modify: `app/models/walk.rb`, `app/models/user.rb`
- Test: `test/models/walk_test.rb`, `test/models/stair_session_test.rb`, `test/models/user_test.rb`, `test/test_helper.rb`

**Interfaces:**
- Produces:
  - `walks.load_kg` decimal(4,1) nulo
  - `users.stair_steps` integer nulo
  - tabela `stair_sessions(user_id, climbed_on date, climbs integer, load_kg decimal(4,1), note string, timestamps)`, índice `[user_id, climbed_on]`
  - `Backdatable` (concern em `app/models/concerns/`): `backdatable :date_attribute` define a validação da janela de 7 dias e `#<attr>_min` (generaliza `Walk#walked_on_within_window`/`#walked_on_min`). `Walk::RETROACTIVE_DAYS` continua respondendo 7.
  - `StairSession::STEP_RISE_M = BigDecimal("0.17")`, `StairSession::DAILY_LIMIT = 500`, `StairSession#climb_m → BigDecimal`, `StairSession#climbed_on_min`
  - `User has_many :stair_sessions`. Quando `stair_steps` muda (`after_update_commit`), chama `forget_unreached_celebrations`.
  - Helpers de teste em `ActiveSupport::TestCase`: `walk_on(user, days_ago, km, load_kg: nil) → Walk` e `climb_on(user, days_ago, climbs, load_kg: nil) → StairSession`. Criam o registro com `save!(validate: false)`, pra permitir datas fora da janela. Também `walk_steady(user, total_km, until_days_ago: 1)`: caminhadas de no máximo 10 km, uma por dia, terminando em `until_days_ago`. Serve pra chegar num chefe sem que nenhuma caminhada sozinha cumpra um feito de distância. **Atenção:** qualquer caminhada de 12 km ou mais depois do aparecimento derruba o chefe da fase 1, então teste de "chefe esperando" sempre usa `walk_steady`.

- [ ] **Step 1: Testes que falham**

`test/models/stair_session_test.rb` (o fixture `viajante` ganha `stair_steps: 50` em `test/fixtures/users.yml`):

```ruby
test "desnível usa os degraus do perfil" do
  session = users(:viajante).stair_sessions.create!(climbs: 10, climbed_on: Date.current)
  assert_equal BigDecimal("85"), session.climb_m           # 10 × 50 × 0,17
end

test "sem degraus no perfil não registra" do
  session = users(:novato).stair_sessions.new(climbs: 3, climbed_on: Date.current)
  assert_not session.valid?
  assert_includes session.errors.full_messages.join, "degraus"
end

test "subidas inteiras e maiores que zero, até 500 por dia" do
  user = users(:viajante)
  assert_not user.stair_sessions.new(climbs: 0, climbed_on: Date.current).valid?
  user.stair_sessions.create!(climbs: 450, climbed_on: Date.current)
  assert_not user.stair_sessions.new(climbs: 51, climbed_on: Date.current).valid?
end

test "data vai de hoje até 7 dias atrás" do
  user = users(:viajante)
  assert user.stair_sessions.new(climbs: 1, climbed_on: Date.current - 7).valid?
  assert_not user.stair_sessions.new(climbs: 1, climbed_on: Date.current - 8).valid?
end

test "mochila opcional até 40 kg" do
  user = users(:viajante)
  assert user.stair_sessions.new(climbs: 1, climbed_on: Date.current, load_kg: nil).valid?
  assert_not user.stair_sessions.new(climbs: 1, climbed_on: Date.current, load_kg: 41).valid?
end
```

Em `test/models/walk_test.rb`: `"mochila opcional, com vírgula, até 40 kg"` (`load_kg: "7,5"` salva 7.5; `0` e `41` inválidos; `nil` válido). Em `test/models/user_test.rb`: `"degraus de 1 a 1000"`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/stair_session_test.rb test/models/walk_test.rb test/models/user_test.rb`
Expected: FAIL (tabela/coluna inexistente)

- [ ] **Step 3: Migrations, `Backdatable`, `StairSession`, `Walk#load_kg` e helpers de teste**

`load_kg=` aceita vírgula, como `Walk#km=`. Os testes atuais de janela de `Walk` têm que continuar passando sem mudança.

- [ ] **Step 4: Rodar e ver passar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add db app/models test
git commit -m "feat: mochila na caminhada e registro de escada"
```

---

### Task 2: Chefes e semanas no conteúdo do mundo

**Files:**
- Create: `app/models/world/boss.rb`, `app/models/world/week.rb`
- Modify: `app/models/world/phase.rb`, `app/models/world/region.rb`, `app/models/achievement.rb`
- Modify: `test/world/01_alpha.yml`, `test/world/02_beta.yml`
- Test: `test/models/world/boss_test.rb`, `test/models/world_test.rb`

**Interfaces:**
- Consumes: `Walk#km`, `Walk#load_kg`, `StairSession#climb_m`, `StairSession#load_kg` (Task 1).
- Produces:
  - `World::Boss` com `name`, `description`, `kind` (`KINDS = %w[ distance distance_with_load climb climb_with_load consecutive_days ]`), `km`, `load_kg`, `climb_m`, `days` e `phase`. Método `#defeated_on?(date, log:, since:) → Boolean`. `log` responde `walks_on(date) → [Walk]` e `stair_sessions_on(date) → [StairSession]`. `since` é a data mínima de qualquer dia do feito.
  - `World::Week` com `number`, `km`, `short_walks`, `long_walk`, `load`, `stairs`, `start_km` (dentro da fase), `end_km` e `light?` (última semana da fase).
  - `World::Phase`: `boss` (nil se o YAML não tiver), `weeks` ([] se não tiver), `focus`, `note`, `insignia_name`, `bonus` (hash `name`/`description` ou nil). `boss?` passa a significar `boss.present?`. A raridade continua mandando em `xp`, `insignia_size` e `legendary?`; adicione `rare? = rarity != "common"`.
  - `World::Phase#milestones`: quando há chefe, entra `World::Milestone.new(key: "boss:#{key}", kind: :boss, at_km: end_km, xp: 0, subject: self)` **antes** do `phase:`.
  - `World::Region#tips → [String]` (YAML `tips`, [] se faltar).
  - `Achievement.subject_for("boss", key)` → a fase.
- Validações (`World::Invalid`): `boss.kind` conhecido; parâmetros obrigatórios por tipo (`km` em distance*/consecutive_days, `climb_m` em climb*, `load_kg` nos `*_with_load` e em consecutive_days, `days ≥ 2` em consecutive_days); se `weeks` existir, a soma de `weeks[].km` é igual ao `km` da fase.

- [ ] **Step 1: Mundo de teste**

`a1` 10 km, sem chefe (continua igual). `a2` 20 km, `rare`, `boss: { name: Chefe A2, description: x, kind: distance, km: 12 }`, `weeks` de 5 km × 4 (textos curtos quaisquer). `b1` 30 km, `rare`, `boss: { kind: climb, climb_m: 100, ... }`. `b2` 40 km, `legendary`, `boss: { kind: consecutive_days, days: 2, km: 10, load_kg: 5, ... }`. A região `alpha` ganha `tips: [ Dica um., Dica dois. ]`.

- [ ] **Step 2: Testes que falham**

`test/models/world/boss_test.rb`, com um `log` falso (`Struct` com hashes por data) e registros `Walk.new`/`StairSession.new` não salvos (pra `climb_m`, use um user com `stair_steps: 50`):

```ruby
test "distance: uma caminhada só, 6 + 6 não vale" do
  boss = boss(kind: "distance", km: 12)
  assert boss.defeated_on?(today, log: log(today => [ walk(12) ]), since: today)
  assert_not boss.defeated_on?(today, log: log(today => [ walk(6), walk(6) ]), since: today)
end

test "distance_with_load: mochila vazia não vale" do
  boss = boss(kind: "distance_with_load", km: 15, load_kg: 5)
  assert boss.defeated_on?(today, log: log(today => [ walk(15, 5) ]), since: today)
  assert_not boss.defeated_on?(today, log: log(today => [ walk(15) ]), since: today)
  assert_not boss.defeated_on?(today, log: log(today => [ walk(15, 4.9) ]), since: today)
end

test "climb soma as sessões do dia; climb_with_load só as com carga" do
  # 50 degraus × 0,17 = 8,5 m por subida
  assert boss(kind: "climb", climb_m: 100).defeated_on?(today, log: log(today => [ climb(6), climb(6) ]), since: today)   # 102 m
  with_load = boss(kind: "climb_with_load", climb_m: 100, load_kg: 10)
  assert_not with_load.defeated_on?(today, log: log(today => [ climb(6, 10), climb(6) ]), since: today)
end

test "consecutive_days: cada dia com carga, soma de todas as caminhadas" do
  boss = boss(kind: "consecutive_days", days: 2, km: 10, load_kg: 5)
  entries = { today - 1 => [ walk(4, 5) ], today => [ walk(3, 5), walk(3) ] }
  assert boss.defeated_on?(today, log: log(entries), since: today - 1)
  assert_not boss.defeated_on?(today, log: log(entries), since: today)                   # janela começa antes de since
  assert_not boss.defeated_on?(today, log: log(today - 2 => [ walk(5, 5) ], today => [ walk(5, 5) ]), since: today - 2)   # buraco
  assert_not boss.defeated_on?(today, log: log(today - 1 => [ walk(5) ], today => [ walk(5, 5) ]), since: today - 1)      # dia sem carga
end
```

Em `test/models/world_test.rb`, atualize `"milestones em ordem de caminho"` com `[ "boss:a2", 30, 0 ]` antes de `phase:a2`, `boss:b1` e `boss:b2` nos lugares certos, e acrescente:
- `"semanas acumulam km dentro da fase"`: semanas de a2 com `start_km` 0, 5, 10, 15, e só a 4ª com `light?`;
- `"chefe com tipo desconhecido é inválido"`;
- `"chefe sem parâmetro obrigatório é inválido"` (`distance_with_load` sem `load_kg`);
- `"semanas que não somam o km da fase são inválidas"`;
- `"dicas da região"`.

O teste de raridade passa a usar `a1` (comum, 100 XP) e `a2` (rara, 250 XP).

- [ ] **Step 3: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/world`
Expected: FAIL (`World::Boss` não existe)

- [ ] **Step 4: Implementar `World::Boss`, `World::Week` e as mudanças em `Phase`, `Region` e `Achievement`**

- [ ] **Step 5: Rodar tudo**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models`
Expected: PASS em `world` e `boss`. Os testes de `journey`/`celebrations` que dependem de a2 sem chefe podem falhar. Eles são reescritos na Task 3; anote quais falharam.

- [ ] **Step 6: Commit**

```bash
git add app/models/world app/models/world.rb app/models/achievement.rb test/world test/models/world_test.rb test/models/world
git commit -m "feat: chefes e semanas no conteúdo do mundo"
```

---

### Task 3: Jornada calculada por replay, com chefes e km guardados

**Files:**
- Create: `app/models/user/training_log.rb`
- Modify: `app/models/user/journey.rb`, `app/models/user.rb`
- Test: `test/models/user/journey_test.rb`, `test/models/user/celebrations_test.rb`, `test/models/user/training_log_test.rb`

**Interfaces:**
- Consumes: `World::Boss#defeated_on?`, `World::Phase#boss`/`#weeks`/`#milestones`, `World::Week` (Task 2); `StairSession#climb_m` (Task 1).
- Produces:
  - `User::TrainingLog.new(user)`: carrega walks e sessions uma vez. `#dates` (datas com registro, em ordem), `#walks_on(date)`, `#stair_sessions_on(date)`, `#km_on(date)`, `#climbed_m` (total) e `#entries_newest_first` (walks e sessions misturadas, por `[data, created_at]` desc, usado no histórico da Task 6). `user.training_log` memoiza por instância de `User`.
  - `User::Journey` (mesma assinatura `new(user, world:)`): `total_km`, `position_km`, `banked_km`, `climbed_m`, `boss_status(phase) → :hidden | :waiting | :defeated` (`:defeated` também pra fase sem chefe completa), `boss_appeared_on(phase)`, `boss_defeated_on(phase)`, `phase_completed?(phase)`, `current_week → World::Week | nil`. O que já existe continua: `current_phase` (primeira não completa, ou a última), `current_region`, `km_in_phase` (`position_km` relativo à fase, de 0 a `phase.km`), `phase_progress`, `next_milestone`/`km_to_next` (por `position_km`), `reached_milestones`, `completed_phases`, `region_status`, `phase_status` (agora `:completed | :boss | :current | :upcoming`, com `:boss` = fase atual com chefe esperando), `landmark_reached?`, `finished?` (todas as fases completas), `xp`, `level`, `achievement_keys` e `leagues` (pelo `total_km`).

- [ ] **Step 1: Testes que falham**

Reescreva `test/models/user/journey_test.rb` sobre o mundo de teste da Task 2. Use `walk_on`/`climb_on` (Task 1); o fixture `viajante` tem `stair_steps: 50`. Testes, com os valores:

```ruby
test "sem caminhadas: início da primeira fase"   # como hoje

test "chefe aparece quando o km da fase fecha e espera" do
  walk_steady @user, 30, until_days_ago: 2     # 3 × 10 km, chega no fim de a2 (30)
  journey = @user.journey(world: @world)
  assert_equal :waiting, journey.boss_status(@world.phase("a2"))
  assert_equal Date.current - 2, journey.boss_appeared_on(@world.phase("a2"))
  assert_equal :boss, journey.phase_status(@world.phase("a2"))
  assert_includes journey.achievement_keys, "boss:a2"
  assert_not_includes journey.achievement_keys, "phase:a2"
  assert_nil journey.current_week
end

test "a caminhada que fecha o km e cumpre o feito derruba o chefe no mesmo dia" do
  walk_on @user, 2, 18
  walk_on @user, 1, 12                          # 30 km, e é uma caminhada de 12
  assert_equal :defeated, @user.journey(world: @world).boss_status(@world.phase("a2"))
end

test "feito antes do chefe aparecer não vale" do
  walk_on @user, 5, 12
  walk_on @user, 4, 9
  walk_on @user, 4, 9                           # chefe aparece aqui (30), nenhuma caminhada de 12 depois
  assert_equal :waiting, @user.journey(world: @world).boss_status(@world.phase("a2"))
end

test "km guardados esperam o chefe e entram de uma vez" do
  walk_steady @user, 40, until_days_ago: 2     # 10 km guardados
  journey = @user.journey(world: @world)
  assert_equal [ 30, 10, 40 ], [ journey.position_km, journey.banked_km, journey.total_km ]
  assert_equal 400 + 25 + 100 + 25 + 0, journey.xp - Mission::XP   # km pelo total; a2 e região ainda não

  walk_on @user, 1, 12
  journey = @user.journey(world: @world)
  assert_equal [ 52, 0 ], [ journey.position_km, journey.banked_km ]
  assert_equal "b1", journey.current_phase.key
end

test "um chefe por dia: km guardados que fecham a próxima fase deixam o chefe pro dia seguinte" do
  walk_steady @user, 70, until_days_ago: 2     # para em 30 (a2), 40 guardados
  climb_on @user, 1, 12                         # 102 m: feito de b1, mas b1 ainda não apareceu
  walk_on @user, 1, 12                          # derruba a2; posição vai a 60 (fim de b1), b1 aparece hoje
  journey = @user.journey(world: @world)
  assert_equal :defeated, journey.boss_status(@world.phase("a2"))
  assert_equal :waiting, journey.boss_status(@world.phase("b1"))

  climb_on @user, 0, 12
  assert_equal :defeated, @user.journey(world: @world).boss_status(@world.phase("b1"))
end

test "semana atual pelo km dentro da fase" do
  walk_on @user, 1, 17                          # a2 com 7 km → semana 2 (5–10)
  assert_equal 2, @user.journey(world: @world).current_week.number
end

test "excluir a caminhada do feito faz o chefe voltar a esperar" do
  walk_steady @user, 30, until_days_ago: 2
  feat = walk_on @user, 1, 12
  feat.destroy
  journey = @user.journey(world: @world)
  assert_equal :waiting, journey.boss_status(@world.phase("a2"))
  assert_equal 0, journey.banked_km
end

test "mundo completo"                           # walk_steady até cada fim de fase e o feito de cada chefe num dia próprio → finished?, sem next_milestone, todas :completed
test "xp de escada"                             # climb_on 12 (102 m) → +20 XP
test "status de região e fase com chefe esperando"   # região alpha :current enquanto a2 espera
```

Em `celebrations_test.rb`:
- os testes existentes continuam (usam só a1);
- `"chefe que apareceu vem antes da insígnia"`: `walk_steady` 30 km → pendentes terminam em `boss:a2`, sem `phase:a2`; com o feito, `phase:a2` e `region:alpha` aparecem depois;
- `"diminuir os degraus esquece o chefe de escada"`: b1 derrubado com 12 subidas, celebrar tudo, `update!(stair_steps: 40)` (12 × 40 × 0,17 = 81,6 m) → `phase:b1` sai das celebrações gravadas.

`training_log_test.rb`: `entries_newest_first` mistura e ordena caminhadas e sessões.

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/user`
Expected: FAIL

- [ ] **Step 3: Implementar o replay**

Algoritmo de `User::Journey` (um passe, em `initialize` ou memoizado):

```
total = 0; last_defeat = nil
gate = primeira fase com chefe          # fase cujo chefe trava a posição
para cada date em log.dates:
  total += log.km_on(date)
  se gate e appeared[gate].nil? e min(total, gate.end_km) >= gate.end_km: appeared[gate] = date
  se gate e appeared[gate] e (last_defeat.nil? ou date > last_defeat):
    since = [appeared[gate], (last_defeat&.+ 1)].compact.max
    se gate.boss.defeated_on?(date, log:, since:):
      defeated[gate] = date; last_defeat = date
      gate = próxima fase com chefe depois de gate
      se gate e total >= gate.end_km: appeared[gate] = date   # aparece hoje, só cai amanhã
position = gate ? min(total, gate.end_km) : min(total, world.total_km)
```

Milestone alcançado:
- `landmark`: `at_km <= position`;
- `boss`: apareceu;
- `phase`: com chefe, quando foi derrotado; sem chefe, quando `end_km <= position`;
- `region`: todas as fases completas.

`xp` = `floor(total_km × 10)` + XP dos alcançados + missões + `floor(climbed_m / 5)`. Em `User`, `after_update_commit :forget_unreached_celebrations, if: :saved_change_to_stair_steps?`.

- [ ] **Step 4: Rodar e ver passar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/models/user app/models/user.rb test/models/user
git commit -m "feat: jornada por replay com chefes e km guardados"
```

---

### Task 4: Conteúdo da Trilha do Vento Austral e arte

**Files:**
- Move: `config/world/0{1,2,3}_*.yml` → `config/world/standby/`
- Create: `config/world/01_vento_austral.yml`
- Create: `app/pixel_art/insignias/{primeiros_passos,carga_leve,a_subida,dois_dias,o_pico,patagonia}.txt` (20×20), `app/pixel_art/stamps/<landmark_key>.txt` (12×12, um por marco), `app/pixel_art/trophies/vento_austral.txt` (32×32)
- Modify: `test/models/world_content_test.rb`, `test/controllers/{home,maps,celebrations}_controller_test.rb`, `test/system/journey_flow_test.rb`

**Interfaces:**
- Consumes: formato do YAML da Task 2. Pra ver um exemplo de cada campo, use o bloco "Conteúdo (YAML)" do spec.
- Produces: região `vento_austral`, "A Trilha do Vento Austral", `trophy_name: Vento Austral`, `inspired_by: Circuito W, Torres del Paine`. Fases, em ordem:

| key | name | km | rarity | weeks km | boss |
|---|---|---|---|---|---|
| `primeiros_passos` | Primeiros Passos | 90 | rare | 22, 24, 26, 18 | O Primeiro Horizonte · distance 12 |
| `carga_leve` | Carga Leve | 115 | rare | 28, 30, 33, 24 | O Fardo do Caminhante · distance_with_load 15 / 5 kg |
| `a_subida` | A Subida | 125 | rare | 30, 33, 36, 26 | A Torre de Degraus · climb 300 m |
| `dois_dias` | Dois Dias | 150 | rare | 36, 40, 42, 32 | Sol e Lua · consecutive_days 2 / 25 km / 8 kg |
| `o_pico` | O Pico | 180 | rare | 44, 47, 50, 39 | O Cume · climb_with_load 700 m / 10 kg |
| `patagonia` | Patagônia | 150 | legendary | 38, 55, 30, 27 | O Vento Austral · consecutive_days 3 / 50 km / 9 kg |

Total: 810 km.

- [ ] **Step 1: Teste de conteúdo que falha**

Em `world_content_test.rb`:
- `"região e fases"`: `[["vento_austral", 6]]`;
- km por fase `[90, 115, 125, 150, 180, 150]` e `total_km == 810`;
- `"toda fase tem chefe, 4 semanas e insígnia nomeada"`;
- `"raridades"`: 5 × rare e a última legendary;
- `"marcos espaçados"`: de 3 a 5 por fase, primeiro marco da fase 1 com `at_km <= 10`, nenhum intervalo entre marcos consecutivos do mundo (contando os fins de fase) acima de 35 km;
- `"troféu 32x32"`;
- `"dicas da região"` (≥ 3).

Os testes de insígnia, carimbo e avatar continuam.

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/models/world_content_test.rb`
Expected: FAIL

- [ ] **Step 3: Mover as regiões brasileiras e escrever o YAML**

- `focus`, `note`, `boss.description`, `bonus` e `insignia_name` vêm do plano em `docs/research/2026-10-21-plano-vento-austral.yml`, sem nada de treino de força.
- `boss.description` do Sol e Lua: "Dois dias seguidos com 8 kg nas costas, somando 25 km."
- `weeks`: distribua as faixas do plano. O longão sobe nas semanas 1–3 e cai na 4ª (fase 1: 8, 10, 12, 8 km). `load` e `stairs` em texto curto ("sem mochila", "4–5 kg", "1× 15–20 min", "não").
- `tips`, nesta ordem:
  - "Treine cedo ou à noite no calor e leve água sempre."
  - "Nos longões, use a bota e a mochila da viagem."
  - "Se uma dor piorar, segura o ritmo. A fase espera você."
- Marcos: 4 por fase, com nome fictício inspirado num lugar real da Patagônia chilena, em ordem de aproximação. Candidatos: Punta Arenas, Estreito de Magalhães, Puerto Natales, Cerro Dorotea, Cueva del Milodón, Laguna Amarga, Lago Sarmiento, Salto Grande, Lago Pehoé, Refugio Paine Grande, Glaciar Grey, Valle del Francés, Cuernos del Paine, Lago Nordenskjöld, Valle Ascencio, Refugio Chileno, Mirador Base Las Torres. Os `at_km` dentro da fase:
  - fase 1: 8, 30, 55, 75
  - fase 2: 20, 50, 80, 105
  - fase 3: 25, 55, 85, 110
  - fase 4 e fase 6: 25, 60, 95, 130
  - fase 5: 30, 70, 110, 150

  As histórias têm 2 frases, com fato conferível. Na dúvida, tire o fato.

- [ ] **Step 4: Desenhar a arte**

Insígnias pelos desenhos do plano (bota com pegada na terra vermelha; mochila de alças cruzadas sobre estrada; escada na rocha até um pico; sol e lua sobre trilha; pico com bandeira; três torres com linhas de vento). Use só cores de `app/pixel_art/palette.yml` e acrescente cores à paleta se precisar (granito, gelo). Carimbos pelos marcos. Troféu: três torres de granito sobre rocha com 6 encaixes vazios.

- [ ] **Step 5: Atualizar os testes de controller e sistema pro mundo novo**

Mesma intenção, números novos:
- **home:** 5 km → "5 / 90 km" e o primeiro marco;
- **maps:** uma região `vento_austral`, sem os testes de região bloqueada e de fronteira de região, que não existem com uma região só;
- **celebrations:** sequência com 8 km → carimbo → início; "chefe apareceu" fica pra Task 8;
- **system:** o novo viajante registra 8 km e ganha o primeiro carimbo.

- [ ] **Step 6: Rodar a suíte inteira**

Run: `mise exec ruby@4.0.6 -- bin/rails test && mise exec ruby@4.0.6 -- bin/rails test:system`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add config/world app/pixel_art test
git commit -m "feat: conteúdo da Trilha do Vento Austral; regiões brasileiras em standby"
```

---

### Task 5: Início com sugestão da semana, chefe e dica

**Files:**
- Modify: `app/views/home/show.html.erb`, `app/controllers/home_controller.rb`
- Create: `app/views/home/_week.html.erb`, `app/views/home/_boss.html.erb`
- Test: `test/controllers/home_controller_test.rb`

**Interfaces:**
- Consumes: `Journey#current_week`, `#boss_status`, `#banked_km`, `#climbed_m`, `#phase_status`; `World::Region#tips`; `World::Phase#focus`/`#note`/`#boss`.
- Produces: `[data-testid=week]` e `[data-testid=boss]` (nunca os dois juntos) e `[data-testid=tip]`. O botão "Registrar escada" no início entra na Task 6, junto com a rota.

- [ ] **Step 1: Testes que falham**

```ruby
test "sugestão da semana pelo km da fase" do
  log_walks users(:viajante), 5, 20                 # 25 km na fase 1 → semana 2 (22–46)
  get root_url
  assert_select "[data-testid=week]", text: /Semana 2 de 4/
  assert_select "[data-testid=boss]", 0
end

test "semana leve" do
  log_walks users(:viajante), 30, 30, 15            # 75 km → semana 4 (72–90)
  get root_url
  assert_select "[data-testid=week]", text: /semana leve/i
end

test "chefe esperando com km guardados, sem cobrança" do
  walk_steady users(:viajante), 100                 # 10 × 10 km: chefe da fase 1 esperando, 10 guardados
  get root_url
  assert_select "[data-testid=boss]", text: /O Primeiro Horizonte/
  assert_select "[data-testid=boss]", text: /10 km guardados/
  assert_select "[data-testid=week]", 0
  assert_no_match(/atras|perdeu|falhou|prazo/i, response.body)
end

test "dica do plano"                                # [data-testid=tip] com uma das 3 dicas
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers/home_controller_test.rb`
Expected: FAIL

- [ ] **Step 3: Implementar**

O card da fase não usa mais o prefixo "Chefão:", porque agora toda fase tem chefe. O card do chefe mostra nome, `description`, "Ele espera o tempo que for preciso." e, quando houver, "N km guardados esperando o chefe". A dica do dia é `tips[Date.current.yday % tips.size]`, num helper `tip_of_the_day(region)`. O desnível acumulado aparece na linha "Total" quando `climbed_m > 0` ("· 1.240 m subidos").

- [ ] **Step 4: Rodar e ver passar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers/home_controller_test.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/views/home app/controllers/home_controller.rb app/helpers test/controllers/home_controller_test.rb
git commit -m "feat: sugestão da semana e card do chefe no início"
```

---

### Task 6: Registrar escada, mochila na caminhada, degraus no perfil e histórico junto

**Files:**
- Create: `app/controllers/stair_sessions_controller.rb`, `app/views/stair_sessions/{new,edit,_form}.html.erb`, `app/frontend/controllers/climb_preview_controller.js`
- Create: `app/controllers/concerns/progress_redirect.rb` (extraído de `WalksController`: `redirect_after_progress`, `redirect_to_celebration_or` e `progress_notice`)
- Modify: `config/routes.rb`, `app/controllers/walks_controller.rb`, `app/views/walks/_form.html.erb`, `app/views/walks/index.html.erb`, `app/controllers/profiles_controller.rb`, `app/views/profiles/edit.html.erb`
- Test: `test/controllers/stair_sessions_controller_test.rb`, `test/controllers/walks_controller_test.rb`, `test/controllers/profiles_controller_test.rb`

**Interfaces:**
- Consumes: `StairSession` (Task 1), `user.training_log.entries_newest_first` (Task 3).
- Produces: `resources :stair_sessions, except: %i[ index show ]`. O histórico continua em `walks#index` e lista as entradas misturadas. Os params são `stair_session: [ :climbs, :climbed_on, :load_kg, :note ]`, `walk:` ganha `:load_kg` e `user:` (perfil) ganha `:stair_steps`.

- [ ] **Step 1: Testes que falham**

`stair_sessions_controller_test.rb`:
- `"registrar escada dá XP e volta pro início"` (12 subidas → notice "+20 XP");
- `"sem degraus no perfil manda cadastrar antes"`: o `novato` com onboarding feito, ou um user sem `stair_steps`, vê o form com o campo de degraus;
- `"editar e excluir"`;
- `"subidas inválidas re-renderizam com 422"`.

`walks_controller_test.rb`: `"caminhada com mochila"` (`load_kg: "5"` salvo) e `"histórico mistura caminhadas e escada"` (as duas aparecem, a mais recente primeiro, com "Editar" apontando pro recurso certo). `profiles_controller_test.rb`: `"salva os degraus da escada"`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers`
Expected: FAIL

- [ ] **Step 3: Implementar**

- Form de escada: "Quantas subidas?", com atalhos 10/20/30 como os atalhos de km, "Quando?", "Mochila (kg, opcional)" e "Observação (opcional)".
- Sem `stair_steps`, o form mostra antes o campo "Quantos degraus tem uma subida?". Ele salva no user no mesmo submit, porque o controller atualiza `Current.user.stair_steps` antes de salvar a sessão.
- `climb_preview_controller.js`: values `steps` e `rise` (0.17), target `climbs` e `output`. Mostra "≈ 85 m de desnível" enquanto digita.
- Walk form: campo "Mochila (kg, opcional)". Em `walks/new`, link "Foi de escada? Registrar escada".
- Perfil: "Degraus da sua escada", com a ajuda "conte da calçada ao topo, sem os patamares".
- Início: botão "Registrar escada" (`btn-game--secondary`) embaixo de "Registrar caminhada". Teste em `home_controller_test.rb`: `"botão de registrar escada"`.

- [ ] **Step 4: Rodar e ver passar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app config/routes.rb test/controllers
git commit -m "feat: registro de escada, mochila e histórico unificado"
```

---

### Task 7: Mapa com chefes e semanas

**Files:**
- Modify: `app/views/maps/_phase.html.erb`, `app/views/maps/_region.html.erb`, `app/assets/tailwind/components.css`
- Test: `test/controllers/maps_controller_test.rb`

**Interfaces:**
- Consumes: `Journey#phase_status` (com `:boss`), `#boss_status`; `Phase#focus`/`#boss`/`#bonus`/`#weeks`.
- Produces: `[data-phase=<key>][data-status=boss]` e, dentro de cada fase, `[data-boss=hidden|waiting|defeated]`.

- [ ] **Step 1: Testes que falham**

- `"fase com chefe esperando"`: com `walk_steady` de 100 km, `#atual[data-phase=primeiros_passos][data-status=boss]` tem `[data-boss=waiting]` e o texto "O Primeiro Horizonte".
- `"detalhes da fase mostram foco, chefe, bônus e semanas"`: em `a_subida`, depois de vencer as fases 1 e 2 (`walk_steady` até o fim de cada fase e, no dia seguinte, `walk_on` com o feito: 15 km com 5 kg derruba os dois chefes, um por dia), aparecem "Ganhar desnível", "A Torre de Degraus", "Pico Agudo" e 4 itens de semana.
- `"chefe de fase futura fica escondido"`: `[data-phase=o_pico] [data-boss=hidden]` sem o nome "O Cume" visível.

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers/maps_controller_test.rb`
Expected: FAIL

- [ ] **Step 3: Implementar**

`:boss` conta como fase andada no `partition` de `_region` (a linha contínua vai até ela). Nó `trail-node--waiting` com borda laranja pulsando (`@keyframes`, respeitando `prefers-reduced-motion`). Com `phase.rare?`, o tamanho da insígnia é 60. A linha "Trecho real" vira "Foco: …". O título do mapa vira "Mapa da trilha".

- [ ] **Step 4: Rodar e ver passar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers/maps_controller_test.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/views/maps app/assets/tailwind test/controllers/maps_controller_test.rb
git commit -m "feat: chefes e semanas no mapa"
```

---

### Task 8: Celebração "O chefe apareceu" e fluxo completo

**Files:**
- Create: `app/views/celebrations/_boss.html.erb`
- Modify: `app/views/celebrations/_phase.html.erb`, `app/views/celebrations/_region.html.erb` (se mencionar a próxima região: com uma região só, cai no texto de "fim do mundo conhecido")
- Test: `test/controllers/celebrations_controller_test.rb`, `test/system/journey_flow_test.rb`

**Interfaces:**
- Consumes: `Achievement` com `kind == "boss"` (Task 2) e as chaves `boss:` da jornada (Task 3).

- [ ] **Step 1: Testes que falham**

- `celebrations_controller_test.rb` — `"chefe apareceu antes da insígnia"`: com `walk_steady` de 90 km e as pendentes anteriores celebradas, a próxima é `h1` "Um chefe apareceu!" com "O Primeiro Horizonte", a descrição e "Ele espera o tempo que for preciso". Depois de `post` da chave, volta pro início.
- `celebrations_controller_test.rb` — `"chefe derrotado"`: uma caminhada de 12 km depois → `h1` "Chefe derrotado!" com a insígnia "Pegada do Viajante".
- `journey_flow_test.rb`: além do fluxo de entrada atual, `"o chefe da fase 1 aparece e cai"`. Com 78 km já registrados (`walk_steady`) e todas as pendentes já celebradas (`user.pending_celebration_keys.each { user.celebrate(it) }`), o usuário registra 12 km pela tela. Aparecem, nessa ordem, "Um chefe apareceu!", "Chefe derrotado!" com "Pegada do Viajante" e, no início, "Carga Leve".

- [ ] **Step 2: Rodar e ver falhar**

Run: `mise exec ruby@4.0.6 -- bin/rails test test/controllers/celebrations_controller_test.rb && mise exec ruby@4.0.6 -- bin/rails test:system`
Expected: FAIL

- [ ] **Step 3: Implementar `_boss` e ajustar `_phase`**

`_phase` usa "Chefe derrotado!" quando `phase.boss?`, mostra `phase.insignia_name` e troca "Inspirada no trecho" por "Foco: …".

- [ ] **Step 4: Rodar a suíte inteira e o lint**

Run: `mise exec ruby@4.0.6 -- bin/rails test && mise exec ruby@4.0.6 -- bin/rails test:system && mise exec ruby@4.0.6 -- bin/rubocop`
Expected: tudo PASS, sem ofensas

- [ ] **Step 5: Conferir no celular (390 px)**

Suba o app (`bin/dev`) e confira por screenshot: o início com o card da semana, o início com o chefe esperando, o form de escada e o mapa. Nada pode estourar a largura.

- [ ] **Step 6: Commit**

```bash
git add app/views/celebrations test
git commit -m "feat: celebração do chefe e fluxo completo da trilha"
```
