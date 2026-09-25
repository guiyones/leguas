# Léguas

*App de desafios virtuais de caminhada.*

**Sobre o nome:** a légua era a medida de distância das viagens antigas pelo Brasil, das tropas e das estradas coloniais. O app pode brincar com isso, mostrando também a distância em léguas (ex.: "você já andou 31 léguas").

## Visão geral

App brasileiro de desafios virtuais de caminhada, inspirado no The Conqueror. O usuário escolhe uma rota real (ex.: Caminho da Fé), registra suas caminhadas do dia a dia e vê seu progresso avançar num mapa, passando por marcos (cidades) até chegar ao destino. Cada fase vencida dá uma insígnia, e ao completar todas as fases de uma região o usuário ganha o troféu daquela região, com as insígnias encaixadas. O troféu pode ser pedido em versão física, impressa em 3D.

**Objetivo do MVP:** uso próprio e de alguns amigos, com divulgação no LinkedIn. Sem pagamento e sem integrações externas nesta fase.

**Idioma:** toda a interface em português do Brasil. Uso principal pelo celular.

---

## Conceitos principais

- **Rota:** um trajeto com nome, descrição, distância total, traçado no mapa e marcos. No MVP todas as rotas são oficiais, criadas por mim.
- **Marco:** um ponto da rota (cidade, atração) posicionado num km específico. Ao passar dele, o usuário "chega" naquele lugar.
- **Participação:** quando o usuário inicia uma rota. Tem data de início, situação (em andamento, pausada, concluída) e data de conclusão.
- **Caminhada:** uma atividade registrada pelo usuário (data + distância em km, com observação opcional). Soma no progresso da participação.
- **Insígnia:** emblema de uma fase, com um desenho que simboliza aquela fase. É liberada ao vencer a fase.
- **Troféu:** uma placa com um encaixe para cada insígnia da região. Vai sendo preenchido conforme as fases são vencidas e fica completo ao terminar a região.

---

## Regras

- Só contam caminhadas registradas a partir do início da participação.
- O usuário pode ter vários desafios em andamento ao mesmo tempo.
- Não há prazo obrigatório. O desafio não "falha": pode ser pausado e retomado.
- Quando os km percorridos alcançam a distância total da rota, o desafio é concluído.
- Ao ultrapassar o fim de uma fase, a insígnia dela é liberada e aparece encaixada no troféu da região.
- Ao vencer todas as fases de uma região, o troféu fica completo e a próxima região é liberada.
- O progresso no mapa é proporcional: a fração percorrida da distância total é aplicada sobre o traçado da rota.
- Ao passar do km de um marco, ele é considerado alcançado, com destaque na tela.
- Uma caminhada precisa ter distância maior que zero e um limite razoável por dia (ex.: 100 km) para evitar erro de digitação.

---

## Telas

0. **Boas-vindas:** na primeira vez que abre o app, o jogo pergunta "Qual o seu nome, viajante?". O usuário digita o nome e passa a ser um viajante dentro do mundo do jogo. No app todo, o jogador é tratado como "viajante".
1. **Início:** desafios em andamento com barra de progresso, km percorridos, próximo marco e um botão grande de "Registrar caminhada".
2. **Mapa do mundo:** um mapa-múndi com as 3 regiões, como a tela de seleção de mundos do Mario. Mostra onde o jogador está, as regiões concluídas e as bloqueadas, com distância e prévia do troféu de cada uma.
3. **Detalhe do desafio:** mapa com a rota, trecho percorrido destacado, posição atual, marcos alcançados e pendentes, histórico de caminhadas.
4. **Registrar caminhada:** formulário rápido (data padrão = hoje, distância em km). Deve ser o fluxo mais rápido do app.
5. **Insígnia conquistada:** ao vencer uma fase, uma tela ou aviso comemorativo mostra a nova insígnia se encaixando no troféu.
6. **Região completa:** tela comemorativa com o troféu completo, certificado digital (nome, região, distância, datas), chamada para a próxima região, botão para compartilhar no LinkedIn e botão "Quero o troféu físico".
7. **Meus troféus:** um troféu por região, mostrando as insígnias conquistadas encaixadas, os encaixes vazios com a silhueta das que faltam e a situação de cada fase (conquistada, em andamento, bloqueada).

### Troféu físico

No MVP não há fluxo de pedido dentro do app. O botão "Quero o troféu físico" abre o WhatsApp com uma mensagem pronta (nome do usuário + região concluída) enviada para o meu número. O troféu é impresso em 3D: a placa da região e as 6 insígnias como peças separadas que se encaixam, entregues juntas ao completar a região.

---

## Estilo visual: jogo de caminhada

O app deve parecer um jogo, no estilo RPG retrô em pixel art. A ideia é que cada caminhada tenha gosto de avançar de fase.

Mockup de referência: https://claude.ai/artifact/5hTmq1iisQFWneNhjYBJPG

### Identidade
- **O jogador é um viajante:** o app se chama Léguas, mas quem joga é sempre "o viajante" dentro do mundo. A primeira tela é "Qual o seu nome, viajante?".
- **Paleta:** fundo azul-noite (#1B1F3B, com painéis em #2A2F5A e contornos quase pretos #0B0D1F), dourado como cor principal de destaque e ação (#F4C542), verde para XP e sucesso (#5BC27A), laranja para chefões e conquistas especiais (#FF9F6B), texto creme (#F2EEDC).
- **Tipografia:** fonte pixelada estilo videogame (ex.: Press Start 2P) só em títulos, rótulos e botões. Texto corrido numa fonte pixel mais legível (ex.: Pixelify Sans). Nunca usar a fonte de título em parágrafos.
- **Formas:** cantos retos, bordas grossas escuras, botões com "degrau" de sombra embaixo (como botão de jogo), barras de progresso segmentadas. Nada arredondado ou com cara de app corporativo.
- **Ícones e ilustrações:** em pixel art, incluindo o avatar do jogador, as insígnias e os troféus.

### Elementos de jogo
- **HUD do jogador** no topo do início: avatar, nome, nível, título (ex.: "Caminhante") e barra de XP.
- **XP e níveis:** cada km caminhado gera XP; vencer fases e completar regiões dá bônus. O nível do jogador (que sobe com XP) é diferente das regiões (as jornadas).
- **Títulos de progressão:** conforme sobe de nível, o jogador ganha um novo título, nesta ordem: Caminhante → Andarilho → Aventureiro → Peregrino → Desbravador → Lenda das Léguas. Todo mundo começa como Caminhante. Subir de título deve ter um momento comemorativo.
- **Missão do dia:** uma meta diária simples (ex.: caminhar 4 km) com progresso visível.
- **Mundo, regiões e fases:** estrutura como no Mario: um único mundo, dividido em regiões (uma por rota), e cada região com suas fases (ver seção "Mundo, regiões e fases").
- **Mapa como seleção de fases:** o trajeto aparece como um mapa de videogame visto de cima, com os marcos como fases: vencidas (douradas), bloqueadas (apagadas) e o bonequinho do jogador na posição atual. O trecho já percorrido fica em linha contínua, o que falta em linha tracejada. O destino final tem uma bandeira.
- **Chefões:** trechos marcantes da rota viram chefões (ex.: Serra da Mantiqueira no Caminho da Fé). Vencê-los dá uma insígnia rara.
- **Troféu com encaixes:** cada região tem um troféu (placa de madeira em pixel art) com 6 encaixes. Insígnias conquistadas aparecem encaixadas; as que faltam aparecem como silhueta num encaixe vazio; a fase em andamento tem o encaixe com contorno tracejado.
- **Tela de conclusão comemorativa:** "NÍVEL COMPLETO!", troféu completo em destaque, estatísticas (km, fases, XP ganho), insígnias raras conquistadas e os botões de compartilhar e pedir o troféu físico.
- **Linguagem:** textos com tom de jogo, mas claros (ex.: "Registrar caminhada", "Próximo marco", "Conquista desbloqueada").

---

## Mundo, regiões e fases

O app tem **um único mundo** (nome a definir), dividido em **3 regiões**, uma para cada rota. Cada região é dividida em fases. Regiões e fases têm **nomes fictícios**; a trilha real aparece apenas como "inspirada em" e serve de referência para a quilometragem.

- Cada fase corresponde a um trecho da trilha real, então as fases têm tamanhos diferentes.
- A distância de cada fase deve seguir o trecho real correspondente, não ser inventada. Enquanto não houver o traçado real, distribuir proporcionalmente, respeitando a distância total oficial.
- O traçado no mapa pode começar simplificado (linha ligando os pontos das fases em ordem) e depois ser trocado pelo traçado real.
- Cada fase tem uma **insígnia** com um desenho que simboliza a fase (símbolo indicado entre colchetes abaixo).
- Algumas fases são **chefões**: trechos marcantes cuja insígnia é **rara**, com outra cor (laranja). A última fase do jogo tem insígnia **lendária**, com uma cor própria.
- O troféu de cada região é uma placa com 6 encaixes e o nome da região.
- As regiões são liberadas em ordem: a Região 2 abre ao completar a Região 1, e assim por diante.
- Além das 3 regiões principais, existe uma região bônus de montanhas, opcional, liberada ao completar a Região 1.

### Região 1 — Trilha das Setas Douradas
*Inspirada no Caminho da Fé (ramal principal), ~315 km (fontes variam entre 304 e 317 km)*

1. Vale das Águas (Águas da Prata → Andradas) [gota d'água]
2. Colinas Douradas (Andradas → Ouro Fino) [colinas]
3. Planície dos Viajantes (Inconfidentes → Borda da Mata) [pegadas]
4. Estrada Luminosa (Estiva → Luminosa) [estrela]
5. **Chefão: O Gigante de Pedra** (subida da Serra da Mantiqueira até Campos do Jordão, ponto mais alto ~1.820 m) [montanha com pico nevado] · rara
6. Santuário da Luz (descida até Aparecida) [santuário com cruz]

Troféu: placa "Setas Douradas".

### Região 2 — Estrada do Ouro Perdido
*Inspirada na Estrada Real, Caminho Velho, 710 km (Ouro Preto → Paraty)*

1. Vila das Minas (Ouro Preto → Congonhas) [picareta com pepita]
2. Cidade dos Sinos (São João del-Rei e Tiradentes) [sino]
3. Vale das Águas Quentes (São Lourenço e Caxambu) [fonte com vapor subindo]
4. Serra do Nevoeiro (travessia da Mantiqueira) [nuvem sobre a montanha]
5. **Chefão: A Muralha do Mar** (descida da Serra do Mar) [onda batendo na rocha] · rara
6. Porto das Pedras (chegada a Paraty) [âncora]

Confirmar ordem e limites dos trechos pelo traçado oficial do Caminho Velho. Troféu: placa "Ouro Perdido".

### Região 3 — O Caminho do Sol
*Inspirado nos Caminhos do Peabiru (Paraná), ~1.250 km (Paranaguá → Peabiru, 800 km + Peabiru → Foz do Iguaçu, 450 km)*

O nome vem da lenda de que o Peabiru imitava o caminho do sol, que nasce no Atlântico e morre no Pacífico.

1. Baía dos Primeiros Passos (Paranaguá) [pegada na areia com onda]
2. **Chefão: A Serra da Névoa Verde** (subida do litoral ao planalto) [folha envolta em névoa] · rara
3. Planalto dos Pinheiros (região das araucárias) [araucária]
4. Coração da Trilha (chegada a Peabiru) [caminhos se cruzando]
5. Terra Vermelha (travessia do oeste) [sol se pondo no horizonte]
6. **Chefão final: O Trovão das Águas** (Cataratas do Iguaçu) [cachoeira com raio] · lendária

Troféu: placa "Caminho do Sol".

### Região bônus — Montanhas (nome a definir)
*Inspirada em grandes picos do Brasil. Opcional, liberada depois de completar a Região 1, como um desvio do caminho principal.*

- Cada fase corresponde à trilha de ida e volta até o cume do pico que a inspira. Como trilhas de montanha são curtas, a região é mais curta que as outras (estimativa de 60 a 80 km no total, a confirmar trilha por trilha).
- **Visual diferente:** em vez do mapa visto de cima, as fases aparecem de perfil, com o bonequinho subindo e descendo as montanhas lado a lado, como num jogo de plataforma.

1. Serra Verde (inspirada no Pico Paraná, 1.877 m, trilha de ~15 a 17 km ida e volta)
2. Agulhas de Pedra (inspirada no Pico das Agulhas Negras, 2.791 m)
3. O Cume Escondido (inspirada na Pedra da Mina, 2.798 m, que só em 1999 descobriram ser o ponto mais alto da Mantiqueira)
4. Cume do Estandarte (inspirada no Pico da Bandeira, 2.892 m, trilha de ~14 km ida e volta)
5. **Chefão lendário: O Pico Encoberto** (inspirado no Pico da Neblina, o ponto mais alto do Brasil)

Símbolos das insígnias e distância exata de cada fase: a definir.

**Importante:** não usar logos nem nomes oficiais das rotas como marca, nem das associações que as mantêm. Insígnias, troféus e artes devem ser originais.

---

## Fora do MVP (futuro)

- Importar caminhadas automaticamente de apps como o Strava
- Conquistas intermediárias (ex.: "Venceu a Mantiqueira")
- Desafios em grupo/equipe e ranking entre amigos
- Desafios personalizados criados pelo usuário (nome, distância e marcos próprios, com opção de enviar o traçado)
- Rotas temáticas de ficção (apenas obras em domínio público ou com licença)
- Pagamento e pedido de troféu físico dentro do app
- Troféu final maior, que junta os 3 troféus, para quem completar todas as regiões
- Região extra "lendária": Oiapoque ao Chuí

---

## Ordem sugerida de entregas

1. Cadastro e login
2. Rotas, marcos e as três rotas oficiais cadastradas
3. Catálogo de rotas e início de um desafio
4. Registro de caminhadas e cálculo de progresso (incluindo marcos alcançados)
5. Tela de detalhe com mapa e trecho percorrido
6. Insígnias por fase, troféus por região, certificado e compartilhamento
7. App instalável no celular
8. Publicação online
