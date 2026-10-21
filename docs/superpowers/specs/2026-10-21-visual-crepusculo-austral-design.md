# Léguas: visual novo (Crepúsculo austral)

*Spec de design, 2026-10-21. Muda o "Estilo visual" e parte de "Telas e rotas" do spec do MVP (`2026-09-25-leguas-design.md`) e do spec da trilha (`2026-10-21-trilha-do-vento-austral-design.md`). Onde divergem, vale este documento.*

**Mockups aprovados** (abrir no navegador): `docs/superpowers/specs/assets/2026-10-21-visual/`
- `mescla-paletas.html`: vale só a **paleta 2, Crepúsculo austral**. Tem a tela da fase e o mapa do mundo.
- `avatar-v3.html`: o avatar (retrato e viajante).
- `menu-diario-trofeus.html`: menu, Diário e Troféus.

## Entendimento

**O que é.** Trocar o visual do Léguas inteiro: sai o pixel art retrô 16×16 (Press Start 2P, bordas grossas) e entra um visual ilustrado e moderno com cara de jogo. O app passa a abrir num menu de jogo e as fases viram mapas.

**Por quê.** O autor não gostou do pixel art e quer algo mais moderno, mais "jogo". As referências dele são **Figment**, pela ilustração pintada com formas suaves, e **Children of Morta**, pela luz quente e dramática e pela paleta escura.

**Deu certo quando.** Abrir o app parece abrir um jogo: menu de título, "Continuar jornada", e você vê seu viajante andando na trilha da fase.

**Objetivos**
- Novo sistema visual em todas as telas: paleta, fontes, cards, botões, barras e navegação.
- Menu de jogo como tela inicial do app.
- Tela da fase como **mapa da fase atual**, e a aba Mapa como **mapa do mundo** com as 6 fases.
- **Diário** (carimbos) e **Troféus** (troféu com insígnias e certificado), que ainda não existem.
- Toda a arte redesenhada **em código (SVG)**: avatar, 6 insígnias, 25 carimbos, troféu, paisagens e chefes.
- **Um avatar só**, baseado no autor.

**Fora desta entrega**
- Leitura automática de passos (continua sendo o próximo projeto).
- Arte das regiões brasileiras em standby. Elas ganham arte nova quando voltarem.
- Animações elaboradas, como o avatar andando quadro a quadro. Brilho, pulso e transições suaves bastam.
- Som.

**Anti-objetivos**
- Rosa e lilás como base. O autor recusou as cores do mockup A.
- Pixel art grosseiro.
- Visual "cartoon de celular" com contorno grosso e cores saturadas de jogo mobile (mockup C, recusado).
- Perder legibilidade no celular. O texto corrido continua confortável a 390 px.
- Nada muda nas regras do jogo. Os anti-objetivos dos specs anteriores continuam valendo: sem punição e sem prazo.

## Sistema visual

**Estilo.** Ilustração vetorial pintada: curvas, gradientes e camadas de montanha, sem contorno preto. A cena é um crepúsculo frio da Patagônia, e uma **luz quente** (fogueira, dourado e brasa) marca o que importa: sua posição, o que foi vencido, o chefe e o botão principal. A luz é um brilho radial suave atrás do elemento.

**Paleta (Crepúsculo austral)**

| Token | Cor | Uso |
|---|---|---|
| `deep` | #0D1726 | fundo |
| `panel` | #16263B | cards |
| `night-2` | #1C2E44 / #132235 / #0E1A2A | camadas de montanha |
| `sky` | #29435E → #E2A05A | gradiente do céu no horizonte |
| `ice` | #CFE3EE | neve, gelo |
| `lake` | #5F9BB8 | lagos |
| `text` | #E8EEF2 | texto |
| `muted` | #9FB8C9 | texto de apoio |
| `gold` | #F2C46D | títulos, trilha percorrida, aros |
| `ember` | #E98A3C | brilho, gradiente do botão, chefe |
| `glow` | #FFE6B0 | centro dos brilhos |
| `legend` | #B98CFF | fase lendária |

Os tokens antigos (`night`, `panel`, `ink`, `xp`…) são substituídos. *Minha decisão:* o verde de XP sai. XP usa o gradiente dourado→brasa e a missão do dia usa `lake`.

**Tipografia.** **Cinzel** (600/800) em títulos, nomes de fase, de chefe e de lugar, e no logotipo LÉGUAS. **Nunito** (600/700/800) em todo o resto. Saem Press Start 2P e Jersey 10.

**Componentes**
- **Card:** fundo `panel` translúcido com leve desfoque, borda dourada fina (1px, ~50% de opacidade), cantos de 16px e brilho de brasa suave.
- **Botão principal:** gradiente `gold`→`ember`, texto escuro, cantos de 12px, degrau de sombra e brilho.
- **Botão secundário:** fundo `panel` com borda dourada fina.
- **Barra de progresso:** contínua e arredondada, com gradiente dourado→brasa e brilho. Sai a barra segmentada.
- **Navegação inferior:** Fase · Mapa · Diário · Menu. A aba ativa fica em dourado com brilho.
- **Rótulo de seção** ("eyebrow"): caixa alta pequena, espaçada, em `muted`.
- **Campos de formulário:** fundo escuro, borda dourada fina, texto claro e foco com brilho.

## Telas

### Menu (nova tela inicial)

É o `root` do app. Mostra a paisagem do pôr do sol com as Três Torres nevadas, o logotipo LÉGUAS e "a trilha do vento austral". Embaixo vêm:
- um cartão com o retrato, nível e título, e a fase atual com km;
- o botão principal **"Continuar jornada"**, que leva pra tela da fase;
- quatro secundários: **Diário · Troféus · Histórico · Perfil**.

O menu não tem navegação inferior. A aba "Menu" das outras telas volta pra ele.

### Tela da fase (o antigo Início)

**Mapa da fase atual:** uma cena de paisagem ocupando a tela, com uma trilha sinuosa da esquerda-baixo à direita-alto.
- Os **marcos** da fase são pontos na trilha, posicionados pela fração `at_km / km` ao longo do caminho. Os alcançados ficam dourados com nome e km. Os outros ficam apagados, com "???" e o km.
- O **chefe** fica no fim da trilha: silhueta enquanto escondido e brilho de brasa pulsando quando está esperando.
- O **viajante de corpo inteiro** fica na posição `km_in_phase / km`, com brilho de fogueira. O trecho percorrido é dourado contínuo; o que falta é tracejado escuro.
- Por cima, um **HUD** compacto: retrato, nível e barra de XP.
- Embaixo, o **card da fase**: rótulo "Fase N de 6 · foco", o nome em Cinzel, a barra e o km. Depois vem a semana sugerida ou o card do chefe (mesma lógica de hoje), a dica do dia e os botões **Registrar caminhada** (principal) e **Registrar escada** (secundário).
- Os conteúdos e regras do Início atual continuam todos: missão do dia, total, léguas, metros subidos, km guardados e fim do mundo conhecido. Muda só a forma.
- *Minha decisão:* a cena é a mesma ilustração base pra todas as fases, com o céu e as camadas um pouco variados por fase (uma variante de cor por fase). A trilha e os pontos são gerados a partir dos dados.

### Mapa do mundo (aba Mapa)

- Uma ilustração vertical com uma trilha que serpenteia de baixo pra cima, por colinas e um lago, até as **Três Torres** no horizonte. As 6 fases são nós na trilha, com o nome em Cinzel ao lado.
- **Fases vencidas:** nó dourado com a insígnia pequena. **Fase atual:** nó maior com brilho e "você está aqui". **Chefe esperando:** o nó pulsa em brasa. **Futuras:** apagadas, chefe "???". **Patagônia:** cor `legend`.
- O trecho percorrido é dourado e o futuro tracejado.
- Tocar numa fase abre um painel (sheet) com o mesmo conteúdo do `<details>` atual: foco, km, chefe (escondido nas fases futuras, como hoje), desafio bônus, as 4 semanas e os marcos.
- As regras de visibilidade e o `data-*` dos testes atuais continuam.

### Diário (novo)

`resource :journal, only: :show`, aberto pela aba Diário.
- Topo: card com **km, léguas, m subidos e missões cumpridas**. Os valores vêm de `Journey#total_km`, `#leagues`, `#climbed_m` e `user.missions.accomplished.count`, que já existe: a meta do dia fica congelada na tabela `missions`, conforme o spec do MVP.
- Uma grade de **carimbos** como selos de passaporte de trilha: círculo com borda dourada tracejada e a ilustração do lugar dentro, com o nome embaixo. Os marcos não alcançados aparecem como círculo apagado com "?" e "km N" (ou "fase N", se for de uma fase futura).
- Tocar num carimbo alcançado mostra nome, fase e história. *Minha decisão:* `<details>` ou `<dialog>`, sem rota nova.
- Ordem: a ordem do caminho.

### Troféus (novo)

`resource :trophies, only: :show` (*minha decisão:* uma região só, então uma tela só), aberto pelo menu.
- O **troféu das Três Torres** é uma ilustração: três torres de granito com neve no topo sobre uma base de rocha com moldura dourada e **6 encaixes**.
- Fase vencida: a insígnia como medalhão no encaixe. Fase atual: encaixe com contorno dourado tracejado. Futuras: encaixe vazio. Patagônia: aro `legend`.
- Abaixo, a lista das insígnias conquistadas: medalhão, nome da insígnia e "Fase N vencida · data". A data é `Journey#boss_defeated_on(phase)`, calculada no replay. Editar ou excluir registros pode mudá-la, o que é coerente com "tudo é calculado".
- **Certificado:** aparece quando a trilha é completada. Mostra nome do viajante, "A Trilha do Vento Austral", km totais, data de início (primeiro registro) e data de fim (último chefe derrotado). As duas datas são calculadas: início = primeira data do `TrainingLog`, fim = `boss_defeated_on` da última fase. Antes disso fica um botão desabilitado: "Certificado — ao completar a trilha".

### Celebrações

Mesma sequência e mesmas chaves de hoje. Cada tipo vira uma tela cheia com fundo escuro e brilho radial no centro:
- **Carimbo:** o selo grande e a história.
- **Chefe apareceu:** a ilustração do chefe com brilho de brasa, o nome, a descrição e "Ele espera o tempo que for preciso". *Minha decisão:* o botão diz "Aceitar o desafio".
- **Insígnia (chefe derrotado):** o medalhão grande, o nome da insígnia e a fase.
- **Região/trilha completa** e **novo título**: no mesmo tratamento.

### Demais telas

Login, código, boas-vindas, registrar caminhada e escada, histórico e perfil ganham o novo sistema visual, sem mudança de comportamento, com uma exceção:
- **Boas-vindas:** o passo de escolher avatar sai. Ficam 2 passos, nome e meta diária.

## Arte

Toda em **SVG escrito à mão**, no estilo dos mockups: formas suaves, gradientes, brilho, sem contorno preto e na paleta acima.

| Peça | Quantidade | Notas |
|---|---|---|
| Avatar · retrato | 1 | `avatar-v3.html`: cabelo curto escuro, **óculos redondos**, bigode, cavanhaque e barba rala, camiseta verde-oliva, luz quente de lado. Recorte circular com aro dourado |
| Avatar · viajante | 1 | corpo inteiro, de bota, com mochila laranja-queimado, a **alça curva sobre o ombro** (não uma linha reta) e o braço esquerdo segurando o bastão pela empunhadura, com o bastão inclinado à frente até o chão |
| Insígnias | 6 | medalhão com aro dourado; desenhos do plano (bota com pegada na terra vermelha, mochila na estrada, escada na rocha até um pico, sol e lua sobre a trilha, pico com bandeira, três torres com linhas de vento). Patagônia com aro `legend` |
| Carimbos | 25 | selo circular com borda tracejada e o lugar dentro, um por marco (`config/world/01_vento_austral.yml`) |
| Chefes | 6 | uma ilustração por chefe, usada na celebração e no card |
| Troféu | 1 | Três Torres com 6 encaixes |
| Paisagens | 3 | menu, cena base da fase (com variantes por fase) e mapa do mundo |

- *Minha decisão:* os arquivos ficam em `app/assets/images/art/<tipo>/<key>.svg` e são renderizados com `image_tag`. Cada SVG é autocontido, com gradientes e filtros dentro do arquivo. As cenas com trilha, marcos e posição variáveis (fase e mapa do mundo) são partials ERB com SVG inline gerado a partir dos dados.
- *Minha decisão:* sai o `PixelArt`, junto com o helper e os testes dele, e saem as grades `.txt` da trilha atual e dos avatares. As grades das regiões brasileiras vão pra `config/world/standby/pixel_art/` só como referência, fora do carregamento.
- O teste de conteúdo passa a exigir um SVG pra cada insígnia, carimbo e chefe, mais o troféu e os dois avatares.
- `users.avatar` deixa de ser usado. *Minha decisão:* uma migration remove a coluna e `User::Traveler::AVATARS` sai.

## Rotas e navegação

| Tela | Rota |
|---|---|
| Menu | `root "menus#show"` (*minha decisão:* `resource :menu, only: :show`) |
| Fase | `resource :phase, only: :show` (o antigo `home#show` muda pra cá) |
| Mapa | `resource :map, only: :show` (igual) |
| Diário | `resource :journal, only: :show` |
| Troféus | `resource :trophies, only: :show` |

- Depois de entrar (login + onboarding), o app vai pro **menu**.
- Depois de registrar caminhada ou escada, vai pra **tela da fase** (ou pra celebração), não pro menu.
- O link "Registrar" sai da barra inferior, porque os botões ficam no card da fase.

## Restrições

- Mobile first, 390 px de largura sem rolagem horizontal. A tela da fase e o mapa rolam na vertical se precisar.
- `prefers-reduced-motion` desliga pulso e brilho animado.
- Acessibilidade continua: SVGs com `role="img"` e `aria-label`, contraste de texto legível sobre as cenas (card com fundo próprio, não texto solto no céu) e foco visível.
- As fontes vêm do Google Fonts, como hoje.
- Os testes atuais de comportamento continuam valendo. Os que dependem de texto ou estrutura mudam só no que este spec muda (rotas, avatar, nomes de tela).

## Deixado pra quem construir

- O desenho exato de cada carimbo, insígnia, chefe e paisagem, dentro do estilo e da paleta.
- A curva da trilha da fase e do mapa do mundo e a posição dos nós, desde que caibam a 390 px e os nomes não se sobreponham.
- A variante de cor de cada fase.
- A organização do CSS de componentes.
