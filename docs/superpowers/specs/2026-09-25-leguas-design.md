# Léguas: design do MVP

*Spec de design, 2026-09-25. Nasceu de `docs/PROJETO.md` (visão original) e da sessão de brainstorming. Onde os dois divergem, vale este documento.*

## Entendimento

**O que é.** Um jogo de caminhada em pixel art. O viajante registra os km que andou e avança por um mundo de regiões inspiradas em trilhas reais do Brasil, divididas em fases. O MVP tem 3 regiões (4, 6 e 6 fases), e outras 2 já desenhadas ficam em standby. Marcos dão carimbos, fases dão insígnias e regiões dão troféus.

**Pra quem.** No começo, só o autor, pelo celular. Amigos podem entrar depois, então o app já nasce com contas de usuário.

**Deu certo quando.** O autor registra caminhadas com frequência e sente que está avançando de fase: tem alguma recompensa a cada poucos dias e a primeira insígnia chega na primeira semana.

**Filosofia.** Não existe falha nem prazo. Ninguém "perde" nada por parar de andar, não há streak e nenhuma tela usa linguagem de punição.

## Fora do MVP

- Região bônus das montanhas (vira a primeira atualização)
- Troféu físico e o botão de WhatsApp
- Compartilhamento no LinkedIn e página pública de certificado (o LinkedIn é pra falar do projeto, não uma função do app)
- Mapa geográfico real / traçado GPX
- Strava, grupos, ranking, desafios personalizados, pagamento
- Avatares desbloqueáveis

## Decisões de jogo

### Mundo, regiões e fases

- Um mundo e 3 regiões em ordem fixa no MVP: **Costa do Missionário → Trilha do Primeiro Raio → Estrada da Promessa** (100 → 177 → 322 km, ~600 km no total).
- Número de fases: **4, 6 e 6**. As regiões crescem aos poucos: a primeira insígnia sai com 25 km (~5 dias a 5 km/dia) e cada região é maior que a anterior. Os cortes caem em cidades reais do trajeto e as fases são contíguas.
- **Em standby** (desenhadas, fora do MVP): Estrada do Ouro Perdido (10 fases, 675 km) e O Caminho do Sol (14 fases, 1.233 km). Voltam depois como Regiões 4 e 5, sem mudar a curva de XP.
- Marcos idealmente a cada ~20–25 km, pra ter algo novo a cada 4–5 dias.
- O viajante tem **uma única posição** no mundo. Não existem "desafios" nem "participações", só a caminhada contínua.
- Cada fase tem uma meta em km. Ao batê-la, a fase fica vencida, a insígnia é liberada e o viajante segue pra próxima. **O excedente passa pra fase seguinte**, inclusive de uma região pra outra.
- Ao vencer a última fase de uma região, o troféu fica completo e a próxima região é liberada automaticamente.
- Ao fim da Região 3 o viajante chega ao "fim do mundo conhecido" (a interface avisa que novas regiões estão a caminho). Caminhadas posteriores continuam somando km e XP, mas a posição fica na bandeira final até as regiões em standby voltarem.
- Raridade das insígnias: **comum**, **rara** (chefões) e **lendária** (O Trovão das Águas, a última fase do jogo). Chefões raros no MVP: 1 por região (As Areias Sem Fim, O Guardião do Céu, O Gigante de Pedra). A insígnia lendária (O Trovão das Águas) fica com a região em standby O Caminho do Sol.
- **Troféu:** uma placa por região com **um encaixe por fase** (4, 6 e 6 no MVP). Os encaixes de chefão são maiores.

### Marcos, carimbos e diário

- Cada fase pode ter de 0 a 4 marcos intermediários (as fases mais longas precisam de mais), com nome fictício inspirado num lugar real do trecho, `at_km` dentro da fase, um texto de curiosidade e um carimbo.
- Passar por um marco dá XP e um carimbo no **Diário de viagem**. Fases sem marcos são válidas.
- Hierarquia: marco → carimbo (diário), fase → insígnia (troféu), região → troféu completo + certificado.

### XP, níveis e títulos

| Evento | XP |
|---|---|
| 1 km caminhado | 10 |
| Marco alcançado | 25 |
| Fase vencida | 100 |
| Chefão vencido (fase rara ou lendária) | 250 (no lugar dos 100) |
| Região completa | 500 |
| Missão do dia cumprida | 20 |

- Nível *n* exige `40 × (n−1)²` de XP acumulado (nível 1 = 0 XP).
- Títulos por nível: 1–4 Caminhante · 5–9 Andarilho · 10–14 Aventureiro · 15–19 Peregrino · 20–24 Desbravador · 25+ Lenda das Léguas.
- A curva foi calibrada pro mundo completo (~2.230 km). No mundo do MVP (~600 km) o viajante chega a Peregrino (~nível 16); Desbravador e Lenda das Léguas esperam as regiões em standby. Decisão: não comprimir a curva.
- Cada troca de título tem uma celebração. Subir de nível sem trocar de título só mostra um aviso.

### Missão do dia

- O viajante escolhe a meta diária no onboarding (2, 3, 5 ou 8 km) e pode mudar no perfil.
- Cumprir a missão (soma do dia ≥ meta daquele dia) dá +20 XP.
- **Sem streak.** Missão não cumprida não aparece em lugar nenhum. O diário mostra só o total de missões cumpridas.
- A meta do dia é congelada na primeira caminhada registrada naquela data. Mudar a meta depois não altera missões passadas.

### Caminhadas

- Campos: data, km (decimal, 2 casas) e observação opcional.
- A data vai de hoje−7 até hoje, com hoje como padrão.
- km > 0, e **a soma do dia não pode passar de 100 km**.
- Toda caminhada pode ser editada ou excluída. A posição, o XP e as conquistas são **sempre calculados** a partir das caminhadas. Excluir uma caminhada pode fazer o viajante voltar e perder uma insígnia, e isso é intencional.

### Celebrações

- Cada conquista tem uma chave: `landmark:<key>`, `phase:<key>`, `region:<key>`, `title:<key>`.
- A tabela `celebrations` guarda as chaves já comemoradas. **Pendentes** = conquistas alcançadas − chaves já comemoradas.
- Depois de registrar uma caminhada, as pendentes aparecem em sequência, na ordem em que aconteceram no caminho (carimbo → insígnia → região → título).
- Ao editar ou excluir caminhadas, as chaves de conquistas que deixaram de ser alcançadas são apagadas, então elas voltam a ser comemoradas quando forem reconquistadas.

### Léguas

1 légua = 6 km (légua comum). O app mostra os km e, como detalhe, as léguas ("você já andou 31 léguas").

## Arquitetura

### Stack

- Rails 8 estável, Ruby atual, **SQLite** (banco principal + Solid Queue/Cache, padrão Rails 8)
- Hotwire (Turbo + Stimulus), importmap, Propshaft
- Tailwind 4 (tailwindcss-rails) pra layout, mais CSS de componentes pro visual de jogo
- Solid Queue dentro do Puma, só pro envio de emails
- Resend pros emails em produção; em desenvolvimento, o código aparece na tela
- pt-BR, com textos escritos direto em português; `config.time_zone = "Brasilia"`, datas via `Date.current`
- Deploy com Kamal + Dockerfile

### Base: convenções do beep

A arquitetura segue o beep (`~/Projects/risecode/beep/master`), trazendo só o que se aplica aqui:

- **STYLE.md:** `if/else` expandido em vez de guard clause (a guard só vale no topo de um método com corpo não trivial); métodos ordenados pela ordem em que são chamados; `private` sem linha em branco depois e com os métodos indentados; `!` só quando existe a versão sem `!`; recurso novo em vez de action customizada; controller magro e model rico.
- **Models:** concerns do model em `app/models/<model>/`, incluídos pelo nome curto. POROs ficam dentro do namespace. `app/models/concerns/` só pro que é compartilhado. Não há camada de services.
- **Auth:** `AuthToken` + `SixDigitCode` + `Session` + concern `Authentication` (`allow_unauthenticated_access`, `rate_limit`), com cookie assinado permanente `session_token`.
- **Frontend:** JS em `app/frontend/`, pinado via importmap, com um controller Stimulus pequeno por comportamento. PWA via `PwaController`.
- **Testes:** Minitest + fixtures, TDD, e helper `sign_in` passando pelo fluxo real de código.

Fica de fora do beep: multitenant, a separação `Identity`/`User`, `Deactivatable`, `app/services`, Action Cable, Postgres, Sentry e os e2e com Playwright.

### Conteúdo do mundo (arquivos)

```
config/world/
  01_costa_do_missionario.yml
  02_trilha_do_primeiro_raio.yml
  03_estrada_da_promessa.yml
  # standby (sem YAML até voltarem): ouro_perdido, caminho_do_sol
app/pixel_art/
  insignias/<phase_key>.txt
  stamps/<landmark_key>.txt
  trophies/<region_key>.txt
  avatars/<avatar_key>.txt
  palette.yml
```

Formato de uma região:

```yaml
key: estrada_da_promessa
name: Estrada da Promessa
inspired_by: Caminho da Fé (ramal principal)
trophy_name: Promessa
phases:
  - key: vale_das_aguas
    name: Vale das Águas
    inspired_by: Águas da Prata → Andradas
    km: 34.0
    rarity: common            # common | rare | legendary
    symbol: gota d'água
    landmarks:
      - key: fonte_da_prata
        name: Fonte da Prata
        at_km: 12.0
        story: >
          Texto curto do cartão do diário.
```

Formato de uma grade de pixel art: uma linha de texto por linha de pixels, um caractere por pixel, e `.` como transparente. Os caracteres são mapeados em `palette.yml`. Tamanhos: insígnia comum 16×16, rara e lendária 20×20, carimbo 12×12. Um helper renderiza a grade como `<svg>` com `shape-rendering="crispEdges"`, agrupando pixels da mesma cor numa mesma linha em um único `<rect>`.

POROs (`app/models/world.rb`, `app/models/world/`):

- `World`: `World.current` (memoizado e carregado de `config/world`), `World.load(path)` (pros testes), `regions`, `milestones`, `total_km`
- `World::Region`, `World::Phase`, `World::Landmark`: dados, mais `start_km`/`end_km` acumulados no mundo
- `World::Milestone`: um ponto ordenado da jornada, com `key` (ex.: `phase:vale_das_aguas`), `kind` (`landmark`/`phase`/`region`), `at_km` acumulado, `xp` e a referência ao objeto
- `PixelArt`: carrega e valida uma grade

### Banco

| Tabela | Colunas |
|---|---|
| `users` | `email_address` (único), `name`, `avatar` (string, chave do avatar), `daily_goal_km` (decimal), timestamps |
| `auth_tokens` | `user_id`, `code`, `expires_at`, `used_at` |
| `sessions` | `user_id`, `token` (único), `expires_at`, `last_active_at`, `user_agent`, `ip_address` |
| `walks` | `user_id`, `walked_on` (date), `km` (decimal 5,2), `note` |
| `missions` | `user_id`, `date` (único por usuário), `goal_km` (decimal) |
| `celebrations` | `user_id`, `key` (único por usuário), timestamps |

### Cálculo do progresso

`User::Journey` (PORO, `user.journey`) recebe `total_km = user.walks.sum(:km)` e o `World`:

- `reached_milestones`: milestones com `at_km ≤ total_km`
- `current_region`, `current_phase`, `km_in_phase`, `phase_progress` (0..1), `next_landmark`, `km_to_next`
- `completed_phases`, `completed_regions`, `stamps`, `finished?`
- `xp` = `total_km × 10` + soma do XP dos marcos alcançados + `20 × missões cumpridas`
- `level` e `title`, calculados por `User::Level` a partir do XP. Os títulos não ficam num km do caminho: `reached_titles` lista os títulos já atingidos (exceto Caminhante), com a chave `title:<key>`.

Regras de fronteira: um km total exatamente igual ao `at_km` conta como alcançado. Com o jogo completo, `current_phase` é a última fase e `phase_progress` é 1.

`User::Celebrations` (concern do `User`):

- `pending_celebration_keys`: chaves alcançadas − chaves gravadas, na ordem do caminho, com a de título por último
- `celebrate(key)`: grava a chave
- `forget_unreached_celebrations`: apaga as chaves gravadas que já não são alcançadas. Roda depois de `Walk` ser atualizada ou excluída (`after_update_commit`/`after_destroy_commit`)

`Mission`: `user.missions.find_or_create_by!(date: walk.walked_on) { it.goal_km = user.daily_goal_km }`, chamado quando uma `Walk` é criada ou muda de data. Uma missão está cumprida quando a soma das caminhadas daquela data é ≥ `goal_km`.

## Telas e rotas

A navegação inferior tem Início · Mapa · **Registrar** · Diário · Troféus. (Até o diário e os troféus existirem: Início · Mapa · **Registrar** · Histórico.)

| Tela | Rota | Conteúdo |
|---|---|---|
| Login | `resource :session`, `resources :auth_tokens`, `namespace :auth_tokens { resource :validations }` | Email e depois o código de 6 dígitos |
| Boas-vindas | `resource :traveler, only: %i[ new create ]` | Formulário em 3 passos (Stimulus): nome ("Qual o seu nome, viajante?"), avatar (4 opções), meta diária. Um before_action manda pra cá enquanto `name` estiver vazio |
| Início | `root "home#show"` | HUD (avatar, nome, nível, título, barra de XP), card da fase atual (barra segmentada, km feitos/meta, próximo marco), missão do dia, botão "Registrar caminhada" |
| Mapa | `resource :map, only: :show` | Uma tela só, com trilha vertical: as regiões empilhadas em ordem, cada uma com número, nome, km e situação (concluída, atual ou bloqueada). As fases são nós ligados por uma linha (contínua no que já foi percorrido, tracejada no que falta): fase vencida mostra a insígnia colorida, a fase atual mostra o avatar, a barra e os km, e as futuras mostram a silhueta. Chefões são nós maiores e laranja. Regiões bloqueadas mostram só o nome e as fases como "???". Tocar numa fase (`<details>`) abre km, trecho real e marcos (alcançados com o carimbo; os outros como "???" com o km). A página abre rolada até a fase atual |
| Registrar | `resources :walks` (`new`, `create`) | Km com atalhos 2/3/5, data e observação |
| Histórico | `resources :walks` (`index`, `edit`, `update`, `destroy`) | Lista com editar e excluir |
| Celebração | `resource :celebration, only: %i[ show create ]` | `show`: próxima pendente (ou redireciona pro início). `create`: marca como vista e redireciona pra `show` |
| Diário | `resource :journal, only: :show` | Carimbos conquistados e silhuetas, cartão ao tocar, km totais, léguas e missões cumpridas |
| Troféus | `resources :trophies, only: %i[ index show ], param: :region_key` | Placas com encaixes (insígnia, silhueta, contorno tracejado na fase atual). Região completa: certificado (nome, região, km, data de início e de fim) |
| Perfil | `resource :profile, only: %i[ edit update ]` | Nome, avatar, meta diária e sair |

Fluxo principal: `WalksController#create` → se houver celebração pendente, redireciona pra `celebration`; senão, vai pro início com um flash de XP ganho (ex.: "+50 XP").

Tipos de celebração:

- **Carimbo:** o cartão com a curiosidade
- **Insígnia:** a insígnia entrando no encaixe do troféu
- **Região:** "NÍVEL COMPLETO!", troféu cheio, estatísticas (km, fases, XP da região), certificado e a chamada pra próxima região
- **Título:** o novo título

As datas do certificado vêm da primeira caminhada da região e da caminhada que a completou. As duas são calculadas pelas somas acumuladas das caminhadas ordenadas por `walked_on, created_at`.

## Estilo visual

Segue `docs/PROJETO.md`, seção "Estilo visual":

- **Paleta:** fundo #1B1F3B, painéis #2A2F5A, contornos #0B0D1F, dourado #F4C542, verde #5BC27A, laranja #FF9F6B, texto #F2EEDC. Cor da lendária: #B98CFF (a confirmar na arte).
- **Fontes:** Press Start 2P em títulos, rótulos e botões; Jersey 10 no texto corrido (trocada da Pixelify Sans, cujos dígitos 2 e 5 se confundiam com 8 e S).
- **Formas:** cantos retos, bordas grossas, botões com degrau de sombra e barras segmentadas.

Os tokens ficam em `@theme` no Tailwind, e os componentes (`.btn-game`, `.panel`, `.progress-segmented`) em CSS próprio.

**Mapa:** no MVP é uma trilha vertical gerada por código (HTML + CSS, sem ilustração), pensada pra rolagem no celular. Decisão de 2026-09-28: uma tela só em vez de mapa do mundo + mapa da região. Depois, cada região pode ganhar um fundo ilustrado sem mexer na lógica.

## Tratamento de erros

- Formulário inválido: re-render com status 422 e mensagem em tom de jogo ("Essa distância parece exagerada, viajante.")
- Código de login inválido ou expirado: volta pra validação com um alerta. Rate limit de 10 tentativas por minuto.
- Conteúdo do mundo inválido: o carregamento levanta exceção na inicialização, e há um teste de conteúdo que falha no CI.
- Como o progresso é sempre calculado, não existe estado de progresso corrompido pra reparar.

## Testes

- `test/fixtures/world/`: um mundo pequeno com números redondos (2 regiões, 2–3 fases, alguns marcos) usado pelos testes de lógica via `World.load`
- **Models:** `World` (carregamento, km acumulados, milestones), `PixelArt` (tamanhos e paleta), `User::Journey` (posição, fronteira exata, excedente atravessando região, jogo completo), `User::Level` (curva e títulos), `Walk` (validações, limite diário, janela de 7 dias), `Mission` (meta congelada, cumprida), `User::Celebrations` (pendentes em ordem, esquecer não alcançadas)
- **Conteúdo real:** chaves únicas, `at_km` < `km` da fase, número de fases por região (4/6/6), grades existentes e válidas
- **Integração:** login por código, redirecionamento pro onboarding, CRUD de caminhadas, sequência de celebrações, região bloqueada
- **System test:** registrar uma caminhada que vence uma fase → ver a insígnia → voltar pro início

## Conteúdo: distâncias das fases

Os km vêm da pesquisa em `docs/research/2026-09-25-distancias.md`, que traz as fontes, a lista cidade a cidade e os marcos candidatos. Status: **OF** = planilha ou perfil oficial, **EST** = estimativa por rota rodoviária. Os nomes das fases são fictícios; a coluna "trecho real" só existe pra referência e não aparece no app como marca.

Mundo do MVP: **599 km** (~100 léguas). Com as regiões em standby, o mundo completo tem 2.507 km.

Pesquisa das Regiões 1 e 2: `docs/research/2026-09-28-distancias-regioes-curtas.md`.

### Região 1: Costa do Missionário (100 km, OF)

*Inspirada nos Passos de Anchieta (ES), 4 etapas oficiais da ABAPA.* Placa do troféu: "Missionário".

| # | Fase | Trecho real | km | Raridade | Insígnia |
|---|---|---|---|---|---|
| 1 | Mirante do Convento | Vitória → Barra do Jucu | 25 | comum | convento no alto do morro |
| 2 | As Areias Sem Fim | Barra do Jucu → Setiba | 28 | rara | pegada na areia sob o sol |
| 3 | Praia das Areias que Curam | Setiba → Meaípe | 24 | comum | concha brilhando |
| 4 | Chegada do Missionário | Meaípe → Anchieta | 23 | comum | cajado com cruz |

A fase 2 é o chefão por ser a etapa mais longa, de areia fofa, isolada e quase sem sombra.

### Região 2: Trilha do Primeiro Raio (177 km, SEC)

*Inspirada no Caminho da Luz (MG), tabela detalhada de etapas.* O site oficial arredonda para "~200 km"; o jogo usa a soma das etapas (177,3 km, arredondada por fase). Placa do troféu: "Primeiro Raio" (o nascer do sol no Pico da Bandeira).

| # | Fase | Trecho real | km | Raridade | Insígnia |
|---|---|---|---|---|---|
| 1 | Vale das Quedas | Tombos → Pedra Dourada | 44 | comum | cachoeira |
| 2 | Vale do Silêncio | Pedra Dourada → Faria Lemos | 25 | comum | lua sobre a mata |
| 3 | Estação Esquecida | Faria Lemos → Carangola | 23 | comum | trilho de trem |
| 4 | Colinas do Café | Carangola → Espera Feliz | 33 | comum | grão de café |
| 5 | Portal da Serra | Espera Feliz → Alto Caparaó | 34 | comum | portal de pedra |
| 6 | O Guardião do Céu | Alto Caparaó → cume do Pico da Bandeira (2.892 m) | 18 | rara | pico com o sol nascendo |

### Região 3: Estrada da Promessa (322 km, OF)

*Inspirada no Caminho da Fé, perfil oficial da Associação.* O traçado atual desce por Gomeral e Potim (~317 km) em vez de Pindamonhangaba. Por isso a fase 6 fica com 72 km provisórios até confirmar o trecho.

| # | Fase | Trecho real | km | Raridade | Insígnia |
|---|---|---|---|---|---|
| 1 | Vale das Águas | Águas da Prata → Andradas | 34 | comum | gota d'água |
| 2 | Colinas Douradas | Andradas → Inconfidentes | 53 | comum | colinas |
| 3 | Planície dos Viajantes | Inconfidentes → Estiva | 59 | comum | pegadas |
| 4 | Estrada Luminosa | Estiva → Luminosa | 66 | comum | estrela |
| 5 | O Gigante de Pedra | Luminosa → Campos do Jordão (Mantiqueira, 1.820 m) | 38 | rara | montanha com pico nevado |
| 6 | Santuário da Luz | Campos do Jordão → Aparecida | 72 | comum | santuário com cruz |

A fase 5 é curta porque é chefão: 38 km de subida forte. É a única fase abaixo da faixa de 50–80 km, e o motivo é o terreno.

### Standby: Estrada do Ouro Perdido (675 km, OF)

*Inspirada na Estrada Real, Caminho Velho.* A soma oficial dos 27 trechos planilhados pelo Instituto Estrada Real é 675 km. O número de divulgação é 710, mas o jogo usa a soma dos trechos.

| # | Fase | Trecho real | km | Raridade | Insígnia |
|---|---|---|---|---|---|
| 1 | Vila das Minas | Ouro Preto → Lobo Leite | 80 | comum | picareta com pepita |
| 2 | Profetas de Pedra | Lobo Leite → Casa Grande (Congonhas) | 80 | comum | profeta esculpido |
| 3 | Lagoa do Ouro | Casa Grande → Tiradentes | 67 | comum | lagoa com brilho |
| 4 | Cidade dos Sinos | Tiradentes → Capela do Saco (São João del-Rei, balsa) | 60 | comum | sino |
| 5 | Serra das Caras Feias | Capela do Saco → Traituba (Carrancas) | 59 | comum | carranca de pedra |
| 6 | Campos do Marchador | Traituba → Caxambu (Cruzília) | 63 | comum | ferradura |
| 7 | Vale das Águas Quentes | Caxambu → Itanhandu (São Lourenço) | 76 | comum | fonte com vapor subindo |
| 8 | A Garganta do Nevoeiro | Itanhandu → Guaratinguetá (Mantiqueira pelo Embaú) | 83 | rara | nuvem sobre a montanha |
| 9 | Colinas do Barro | Guaratinguetá → Cunha | 50 | comum | vaso de cerâmica |
| 10 | A Muralha do Mar | Cunha → Paraty (1.450 m até o nível do mar) | 57 | rara | onda batendo na rocha |

O último marco da fase 10 é **Porto das Pedras** (Paraty), que herda a âncora como carimbo.

### Standby: O Caminho do Sol (1.233 km, EST)

*Inspirada nos Caminhos do Peabiru.* Não existe tabela oficial por trecho, porque o Peabiru é uma rede de ramais. O traçado linear passa por municípios da rota oficial e mede cada par por estrada (OSRM). Os totais oficiais são 800 km (Paranaguá → Peabiru) + 450 km (Peabiru → Foz), e o traçado dá 775 + 458.

| # | Fase | Trecho real | km | Raridade | Insígnia |
|---|---|---|---|---|---|
| 1 | Baía dos Primeiros Passos | Paranaguá → Morretes | 72 | comum | pegada na areia com onda |
| 2 | A Serra da Névoa Verde | Morretes → Curitiba (Graciosa) | 81 | rara | folha envolta em névoa |
| 3 | Planalto dos Pinheiros | Curitiba → Palmeira (Purunã) | 86 | comum | araucária |
| 4 | Cidade de Pedra | Palmeira → Carambeí (Vila Velha) | 101 | comum | taça de arenito |
| 5 | O Cânion Profundo | Carambeí → Tibagi (Guartelá) | 87 | rara | cânion com rio |
| 6 | Rio dos Diamantes | Tibagi → Reserva | 88 | comum | diamante |
| 7 | Vale do Rio Sinuoso | Reserva → Cândido de Abreu (Ivaí) | 73 | comum | rio em curva |
| 8 | Sertão das Tropas | Cândido de Abreu → Iretama | 106 | comum | chapéu de tropeiro |
| 9 | Coração da Trilha | Iretama → Peabiru | 81 | comum | caminhos se cruzando |
| 10 | Lagoa Azul | Peabiru → Campina da Lagoa (Campo Mourão) | 102 | comum | lagoa |
| 11 | Terra Vermelha | Campina da Lagoa → Braganey | 103 | comum | sol se pondo no horizonte |
| 12 | Encruzilhada do Oeste | Braganey → Céu Azul (Cascavel) | 103 | comum | placa de estrada |
| 13 | Floresta das Onças | Céu Azul → São Miguel do Iguaçu | 80 | comum | pegada de onça |
| 14 | O Trovão das Águas | São Miguel do Iguaçu → Cataratas | 70 | lendária | cachoeira com raio |

Cinco fases passam de 100 km, o que dá uns 20 dias cada a 5 km/dia. Como é a jornada épica e cada uma dessas fases tem 2 ou 3 marcos no meio, o ritmo é aceitável.

### Marcos

Os candidatos de cada fase, com o km dentro da fase e a curiosidade, estão no documento de pesquisa. O conteúdo final (nome fictício, texto do cartão e carimbo) foi escrito no Plano 1 (Estrada da Promessa) e é escrito na entrega 8 (Costa do Missionário e Trilha do Primeiro Raio); o das regiões em standby, quando voltarem. As curiosidades sem fonte oficial devem ser conferidas antes de entrar.

## Ordem de entregas

1. Esqueleto Rails + login por código + boas-vindas (nome, avatar, meta)
2. Carregador do mundo + `PixelArt` + conteúdo da Estrada da Promessa (km, marcos, insígnias, carimbos) — feita no Plano 1, quando ela ainda era a Região 1
3. Caminhadas + `User::Journey` + início com HUD
4. XP, níveis, títulos e missão do dia
5. Celebrações (a partir daqui o app já é usável com a Região 1)
6. Mapa (tela única com a trilha vertical de regiões e fases)
7. Diário e troféus com certificado
8. Conteúdo das Regiões 1 e 2 (Costa do Missionário, Trilha do Primeiro Raio); a Estrada da Promessa passa a ser a Região 3
9. PWA + deploy (Kamal, Resend)

**Pré-requisito do deploy:** conta no Resend com domínio verificado.
