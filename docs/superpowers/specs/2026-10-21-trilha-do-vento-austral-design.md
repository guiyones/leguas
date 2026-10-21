# Léguas: a Trilha do Vento Austral

*Spec de design, 2026-10-21. Muda o spec do MVP (`2026-09-25-leguas-design.md`). Onde os dois divergem, vale este documento. Plano de treino original: `docs/research/2026-10-21-plano-vento-austral.yml`.*

## Entendimento

**O que é.** O Léguas passa a acompanhar um treino de caminhada de 6 fases, a Trilha do Vento Austral, com tema de Patagônia e inspirado na preparação pro Circuito W (Torres del Paine). Ela **substitui** as três regiões brasileiras, que ficam guardadas pra voltar depois.

**Por quê.** O autor já fez um treino de caminhada antes e parou. Caminhar é o exercício de que ele mais gosta, e a ideia é juntar o treino com o jogo pra ficar mais gostoso. Ele não sabe se vai fazer a viagem de verdade, então o app não pode depender dela: a Patagônia é tema, não compromisso.

**Deu certo quando.** O autor abre o app e vê quantos km já andou e as fases que venceu. O registro continua manual nesta entrega.

**Objetivos**
- Trocar o mundo pela Trilha do Vento Austral (810 km, 6 fases).
- Cada fase termina com um **chefe**: um feito (caminhada longa, com mochila, escada, dias seguidos) que libera a próxima fase.
- Mostrar o plano semanal como **sugestão**, sem cobrar.
- Registrar sessões de escada (escadaria do estádio em Paranavaí) e o peso da mochila nas caminhadas.

**Fora desta entrega**
- Treino de força. Saiu do plano.
- Leitura automática de passos/distância (Health Connect, Strava, Samsung Health). É o próximo projeto; ver "Depois".
- Desafios bônus como algo registrável (Pico Agudo, Morro do Diabo, Pico Paraná). Aparecem só como texto na fase.
- Telas de Diário e Troféus (continuam sendo a entrega 7 do spec do MVP), exceto a arte do troféu, que entra aqui.

**Anti-objetivos.** Nada de prazo, calendário que atropela, streak ou linguagem de punição. Se o autor ficar dias sem andar, o app continua exatamente onde estava, e voltar tem que ser fácil. Um chefe pode ficar esperando semanas sem nenhum aviso de atraso.

## Decisões de jogo

### Mundo

- O mundo passa a ter **uma região**: A Trilha do Vento Austral. Fases e metas em km vêm do plano: 90, 115, 125, 150, 180 e 150 (810 km).
- As três regiões brasileiras saem do carregamento, mas os YAMLs, as pinturas e as pesquisas ficam no repositório. *Minha decisão:* mover os YAMLs pra `config/world/standby/`. `World.load` lê só `*.yml` do diretório raiz, então eles saem do jogo sem mudança de código. Voltar com elas depois é outro projeto.
- Ao vencer a fase 6, o viajante chega ao "fim do mundo conhecido", como já acontece hoje.

### Chefes

Toda fase tem um chefe. **A fase só é vencida com as duas coisas: o km da fase completo e o chefe derrubado.**

1. Enquanto o km da fase não fecha, o viajante avança normalmente pelos marcos.
2. Quando o km fecha, **o chefe aparece** e fica esperando, sem prazo.
3. O chefe cai com um feito realizado **no dia em que ele apareceu ou depois**. A caminhada que fecha o km da fase vale, se ela mesma cumprir o feito.
4. Ao derrubar o chefe, a fase é vencida (insígnia + encaixe no troféu) e o viajante entra na fase seguinte.

**Um chefe por dia.** *Minha decisão:* num mesmo dia cai no máximo um chefe. Se os km guardados fecharem a fase seguinte no dia em que um chefe caiu, o próximo chefe aparece nesse mesmo dia, mas só pode ser derrotado a partir do dia seguinte. Assim, uma caminhada de 15 km com 5 kg não derruba os chefes 1 e 2 de uma vez: cada chefe pede o seu próprio dia. No `consecutive_days`, a janela precisa começar no dia em que o chefe apareceu ou depois, e nunca no dia em que o chefe anterior caiu.

**Km guardados.** O km nunca para de somar. O que passar da meta enquanto o chefe espera fica **guardado** ("18 km guardados esperando o chefe"). Quando o chefe cai, esses km entram de uma vez na fase seguinte, até o limite dela, onde aparece o próximo chefe. O XP de km conta sempre sobre o total andado. Nada se perde.

**Tipos de feito** (YAML `boss.kind`):

| Tipo | Feito | Fases |
|---|---|---|
| `distance` | Uma caminhada com `km ≥ meta` | 1: 12 km |
| `distance_with_load` | Uma caminhada com `km ≥ meta` e `load_kg ≥ carga` | 2: 15 km, 5 kg |
| `climb` | Soma do desnível das sessões de escada de um mesmo dia `≥ meta` | 3: 300 m |
| `climb_with_load` | Mesma soma, contando só as sessões com `load_kg ≥ carga` | 5: 700 m, 10 kg |
| `consecutive_days` | N dias de calendário seguidos, todos com caminhada com `load_kg ≥ carga`, e a soma das caminhadas desses dias `≥ meta` | 4: 2 dias, 25 km, 8 kg · 6: 3 dias, 50 km, 9 kg |

- "Uma caminhada" é um registro só. Duas de 6 km no mesmo dia não derrubam o chefe de 12 km.
- *Minha decisão:* no `consecutive_days`, contam as caminhadas com carga que bastar pra fazer a soma. Basta cada dia ter pelo menos uma caminhada com carga suficiente, e a soma usa todas as caminhadas daqueles dias. O "na segunda, caminhada curta normal" do Sol e Lua sai, porque cobrar o dia seguinte vai contra a ideia de não cobrar.
- No `consecutive_days`, todos os N dias precisam ser do dia em que o chefe apareceu ou depois.

**Raridade e XP.** Toda fase tem chefe, então as fases 1 a 5 são `rare` (250 XP, insígnia 20×20) e a fase 6, O Vento Austral, é `legendary`. A tabela de XP do MVP não muda.

**Celebrações novas.** *Minha decisão:* o aparecimento do chefe ganha celebração própria, com chave `boss:<phase_key>`, nome, descrição do feito e "ele espera o tempo que for preciso". A insígnia continua na chave `phase:<phase_key>`, que agora só é alcançada quando o chefe cai. A ordem das pendentes segue a ordem do caminho: marco → chefe apareceu → fase → região → título.

### Sugestão da semana

- Cada fase tem 4 semanas do plano, e as metas semanais somam a meta da fase (22+24+26+18 = 90).
- **A semana é calculada pelo km andado dentro da fase, não pelo calendário.** Semana 1 vale de 0 a 22 km da fase 1, a semana 2 de 22 a 46 km, e assim por diante. Ficar parado não muda a semana.
- O card mostra: número da semana ("Semana 2 de 4", com "semana leve" na 4ª), caminhadas curtas, longão, mochila, escada e a observação da fase. Os textos vêm do plano, sem a linha de força.
- Com o km da fase completo e o chefe esperando, o card de sugestão dá lugar ao card do chefe.
- As regras gerais do plano (dor que piora, calor e água, usar a bota e a mochila da viagem) aparecem como dicas. *Minha decisão:* uma dica por vez no início, trocando por dia. A regra "repita a semana" é reescrita como "se uma dor piorar, segura o ritmo; a fase espera você", porque com semana calculada por km ninguém "repete" semana.

### Marcos

- *Minha decisão:* uns 4 marcos por fase (~24 no total), espaçados pra dar uma recompensa a cada 20–30 km. Os primeiros chegam na primeira semana; a primeira insígnia só sai depois de 90 km e do chefe.
- Os marcos contam uma aproximação da Patagônia: Puerto Natales, Laguna Amarga, Lago Pehoé, Glaciar Grey, Valle del Francés, Mirador Las Torres, etc. Seguem a regra do MVP: nome fictício inspirado no lugar real, texto curto de curiosidade conferível e carimbo 12×12. As fases não são trechos geográficos, então a distribuição dos lugares pelas fases é narrativa.

### Escada

- O viajante cadastra no perfil **quantos degraus tem uma subida** (`stair_steps`), contando da calçada até o pórtico, sem os patamares. No caso do estádio de Paranavaí, ele conta numa ida ao treino.
- Cada degrau vale **0,17 m** (constante, *minha decisão*). Desnível de uma sessão = `climbs × stair_steps × 0,17`.
- O desnível é calculado a partir do `stair_steps` atual. Se o número de degraus mudar, as sessões antigas são recalculadas, coerente com "tudo é calculado".
- Sem `stair_steps`, a tela de registrar escada pede o número antes.
- Escada **não soma km** e não mexe na barra da fase. Serve pros chefes de escada e aparece como estatística ("1.240 m subidos").
- *Minha decisão:* sessão de escada dá XP de `desnível ÷ 5` (300 m = 60 XP), pra não ser um treino sem recompensa nenhuma. Não conta pra missão do dia, que continua sendo de km.

### Mochila

- A caminhada ganha `load_kg`, opcional (vazio = sem mochila). A sessão de escada também.

### O que não muda

XP, níveis, títulos, missão do dia, celebrações e o fato de tudo ser calculado das caminhadas. Continua valendo: **nunca gravar posição, XP ou chefe vencido**. O estado dos chefes sai do replay dos registros.

## Arquitetura

### Conteúdo (YAML)

Os campos novos ficam no formato atual, com chaves em inglês:

```yaml
key: vento_austral
name: A Trilha do Vento Austral
inspired_by: Circuito W, Torres del Paine
trophy_name: Vento Austral
tips:
  - Treine cedo ou à noite no calor e leve água sempre.
phases:
  - key: primeiros_passos
    name: Primeiros Passos
    focus: Criar o hábito
    inspired_by: Semanas 1–4 do plano
    km: 90
    rarity: rare
    symbol: bota de trilha deixando uma pegada na terra vermelha
    insignia_name: Pegada do Viajante
    note: Desça prédios de elevador para poupar os joelhos.
    weeks:
      - km: 22
        short_walks: 3× 40–50 min
        long_walk: 8 km
        load: sem mochila
        stairs: não
      # ... 4 semanas
    boss:
      name: O Primeiro Horizonte
      description: Caminhar 12 km sem parar, em ritmo confortável.
      kind: distance
      km: 12
    bonus: # opcional, só texto
      name: Pico Agudo ou Morro do Diabo
      description: Subir uma montanha real num fim de semana.
    landmarks: [...]
```

Validações novas em `World::Phase`: `weeks` com 4 itens cujo `km` soma o `km` da fase, `boss.kind` conhecido e os parâmetros obrigatórios de cada tipo. As faixas do plano ("8 → 12 km") viram texto por semana; quem escreve o conteúdo distribui as faixas entre as 4 semanas.

### Banco

| Mudança | Detalhe |
|---|---|
| `walks.load_kg` | decimal(4,1), nulo |
| `users.stair_steps` | integer, nulo |
| nova `stair_sessions` | `user_id`, `climbed_on` (date), `climbs` (integer > 0), `load_kg` (decimal 4,1, nulo), `note`, timestamps. Índice `[user_id, climbed_on]` |

`StairSession` segue as regras de `Walk`: janela de 7 dias pra trás, edição/exclusão livre, e `forget_unreached_celebrations` depois de commit. *Minha decisão:* limite de 500 subidas por dia, como sanidade.

### Cálculo do progresso

`User::Journey` deixa de ser só `total_km` contra marcos fixos e passa a **reproduzir os registros em ordem** (caminhadas e sessões de escada por data e `created_at`, dia a dia):

- Mantém a posição (`position_km`), limitada ao `end_km` da primeira fase cujo chefe não caiu.
- Ao fim de cada dia, verifica se o chefe da fase atual apareceu (posição chegou no `end_km`) e, se apareceu, se algum feito daquele dia (ou da janela de dias seguidos que termina nele) o derruba.
- Expõe: `total_km` (tudo), `position_km`, `banked_km` (`total_km − position_km`), `boss_status(phase)` (`:hidden`, `:waiting`, `:defeated`), datas de aparecimento e de derrota, `current_week` e `climbed_m`.
- `reached_milestones` passa a ser calculado com `position_km` e o estado dos chefes: marcos por `at_km ≤ position_km`, `boss:` quando aparece e `phase:` quando cai.
- XP = `total_km × 10` + XP dos milestones alcançados + missões + XP de escada.

A interface pública atual (`current_phase`, `km_in_phase`, `phase_status`, `achievement_keys`, etc.) continua existindo, com a semântica nova. `phase_status` ganha o estado `:boss`, com o km completo e o chefe esperando.

### Telas

| Tela | Mudança |
|---|---|
| Início | O card da fase mostra a barra e o km e, embaixo, a **sugestão da semana** ou o **card do chefe** (nome, feito, "esperando você", km guardados). Dica do plano. Botões "Registrar caminhada" e "Registrar escada" |
| Registrar caminhada | Campo opcional "Mochila (kg)" |
| Registrar escada | `resources :stair_sessions` (`new`, `create`, `edit`, `update`, `destroy`): número de subidas com atalhos, data, mochila e observação. Mostra o desnível estimado enquanto digita (Stimulus) |
| Histórico | Junta caminhadas e escadas na mesma lista, por data |
| Mapa | Uma região. Cada fase mostra o nó do chefe: silhueta enquanto escondido, laranja pulsando quando espera, insígnia quando vencido. O `<details>` da fase traz foco, chefe, desafio bônus e as 4 semanas |
| Perfil | Campo "Degraus da sua escada" |
| Celebração | Novo tipo "O chefe apareceu" |

### Pixel art

A arte nova é feita no formato atual: 6 insígnias 20×20 (desenhos do plano), ~24 carimbos 12×12 e o troféu (`trophies/vento_austral.txt`: três torres de granito sobre a rocha, com 6 encaixes).

### Testes

- O mundo de teste (`test/world/`) ganha chefes de todos os tipos, semanas e uma fase lendária. O teste de conteúdo real passa a verificar 1 região com 6 fases, semanas que somam o km da fase e chefes válidos.
- `User::Journey`: chefe aparece no dia exato, feito antes do aparecimento não vale, caminhada que fecha o km e já cumpre o feito, km guardados liberados até o próximo chefe, `consecutive_days` com buraco no meio, mochila abaixo da carga, escada somada no dia, editar/excluir que desfaz um chefe.
- `StairSession`: validações, desnível com `stair_steps`.
- Sistema: chegar ao chefe da fase 1 → celebração do chefe → caminhada de 12 km → insígnia.

## Ordem de entregas

Esta entrega entra antes da 7 (Diário e Troféus) e da 9 (PWA + deploy) do spec do MVP. A entrega 8, das regiões brasileiras, fica em standby junto com elas.

## Depois

Próximo projeto: registro automático. O autor anda com o celular no bolso e tem um relógio Samsung. O Google Fit não é opção (API descontinuada). Os caminhos são o **Strava** (API web, com o Samsung Health sincronizando nele, sem app nativo) ou o **Health Connect**, com Hotwire Native Android em Kotlin. A decisão fica pra quando esse projeto começar.

## Deixado pra quem construir

- Textos do conteúdo: nomes e histórias dos marcos, como as faixas do plano se distribuem nas semanas e o texto das celebrações, no tom do jogo.
- A estrutura interna do replay em `User::Journey`, desde que o progresso continue calculado e com bom desempenho pro volume de um usuário.
- Visual dos cards novos, dentro do `STYLE.md` e dos componentes atuais.
