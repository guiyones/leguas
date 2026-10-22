# Léguas: rotas e bônus

*Spec de design, 2026-10-22. Soma-se aos specs da trilha (`2026-10-21-trilha-do-vento-austral-design.md`) e do visual (`2026-10-21-visual-crepusculo-austral-design.md`). Onde divergem, vale este documento.*

## Entendimento

**O que é.** Duas mudanças que vieram da primeira caminhada de verdade (22/10, 3,55 km em 38:51, gravada no Samsung Health):

1. **Rotas.** O autor tem caminhos que faz sempre, uns curtos e uns longos. Ele quer salvá-los no Léguas com o mapa e os números, consultar a lista na hora de escolher o treino (um curto num dia leve, um longo no dia do longão) e, ao registrar a caminhada, escolher a rota para não digitar tudo de novo.
2. **Bônus em vez de cobrança.** Hoje a tela da fase tem "Missão do dia: caminhar 5 km", com uma barra vazia, e o card da semana mostra só texto. No primeiro dia ele andou 3,55 km e a tela mostrou que ele "não cumpriu". A semana do plano e a meta do dia viram bônus: dá pra ganhar, mas nada cobra.

**Por quê.** O app tem que acompanhar o treino do jeito que ele acontece de verdade, sem dar sensação de falha. As rotas economizam digitação e ajudam a escolher o treino do dia.

**Base para o app Android.** O próximo projeto é um app Android que lê os treinos do Health Connect automaticamente. O Health Connect entrega, por treino: distância, duração, passos, ganho de elevação e o traçado do GPS. A caminhada e a rota deste spec já guardam esses mesmos dados, para que o app Android só precise preenchê-los.

**Deu certo quando**
- Ele sobe o print do Samsung Health, e a rota aparece como um mapinha no estilo do jogo, sem desenhar nada à mão.
- Ao registrar, escolhe "Volta do Guanabara" e a distância já vem preenchida.
- Num dia de 3,55 km com meta de 5 km, a tela da fase não mostra nada vazio ou vermelho.
- Na semana 1 ele vê "3 caminhadas de 40 min" com 0/3, e a caminhada de 38:51 não conta, mas a próxima de 40 min conta.

**Objetivos**
- Rotas com nome, distância, print do mapa e mapinha gerado automaticamente a partir do print.
- A caminhada passa a ter tempo, passos, ganho de elevação e, opcionalmente, uma rota.
- O card da semana vira **Desafios da semana**, com ✓ e XP de bônus, e um selo de **semana completa**.
- A missão do dia vira **Bônus do dia**, uma linha discreta.

**Fora desta entrega**
- O app Android e a leitura automática (próximo projeto).
- Traçado real do GPS. O formato de dados fica preparado, mas só a foto entra agora.
- Reconhecer sozinho que uma caminhada seguiu uma rota salva.
- Deploy em produção, envio de email e Railway (assunto separado, ainda aberto).

**Anti-objetivos**
- Desenhar a rota à mão. O autor recusou explicitamente: o sistema faz o desenho a partir da foto.
- Precisão de mapa. "Não precisa ter precisão nem nada, é só o formato do mapa com as informações."
- Qualquer marca de falha: vermelho, "não cumprido", "perdeu", barra vazia em destaque ou prazo de calendário.
- Bônus andando na trilha. A posição e os chefes continuam vindo só dos km e das escadas reais.
- Depender de serviço externo (API de visão, mapa online) para gerar o mapinha.

## Caminhada: dados novos

A tabela `walks` ganha estas colunas, todas opcionais. Caminhadas antigas ficam sem elas.

| Campo | Tipo | Formulário | Exemplo |
|---|---|---|---|
| `duration_s` | inteiro, segundos | "Tempo", aceita `38:51` ou `1:05:20` (h:mm:ss) | 2331 |
| `steps` | inteiro | "Passos", aceita `4.507` ou `4507` | 4507 |
| `elevation_gain_m` | inteiro | "Subida (m)" | 32 |
| `route_id` | referência a `routes`, nula | "Rota", um select | — |

- O ritmo (min/km) e a velocidade (km/h) são **calculados** a partir de km e tempo, nunca gravados. Aparecem no histórico e no cartão da rota. Formato: `10'55"/km` e `5,4 km/h`, como no Samsung Health.
- Calorias e voltas ficam de fora.
- Escolher uma rota no formulário preenche os km com a distância dela, via Stimulus, e o campo continua editável. A caminhada guarda os km digitados; a rota é só a referência.
- Ao apagar uma rota, as caminhadas dela ficam com `route_id` nulo e mantêm os km.

## Rotas

**Modelo `Route`** (por usuário):
- `name`: obrigatório, até 40 caracteres.
- `km`: obrigatório, maior que 0. É a distância que o relógio marcou.
- `duration_s`: opcional, o tempo de referência.
- `note`: opcional.
- `photo`: o print, via Active Storage. Precisa instalar o Active Storage, que o projeto ainda não tem. Os arquivos ficam em `storage/`, que em produção já é o volume.
- `trace`: JSON, o traçado (formato abaixo).
- `trace_source`: string, `"photo"` agora e `"gps"` no futuro.

**Formato do traçado.** Uma lista ordenada de pontos `[x, y]` normalizados entre 0 e 1, desenhada como polilinha. A normalização **mantém a proporção**: os dois eixos são divididos pelo maior lado da caixa do traçado, e o lado menor fica centralizado. Assim, uma rota comprida e estreita continua comprida e estreita. Decisão minha. O traçado do GPS que virá do Android será lat/lng; o renderizador normaliza para 0–1 antes de desenhar, então o mesmo mapinha serve para os dois. Agora só existe `"photo"`.

**Telas**
- **Rotas** (`/routes`): lista de cartões ordenada por distância, da menor para a maior. Cada cartão mostra o mapinha, o nome, os km e, se houver, o tempo e o ritmo. Entra como um botão novo no menu de jogo, na grade com Diário, Troféus, Histórico e Perfil.
- **Nova rota / editar rota**: nome, km, tempo, observação e foto. A foto é opcional; sem ela, ou se o traçado falhar, o cartão mostra uma arte padrão de trilha.
- **Registrar caminhada**: o select "Rota" aparece só se houver rotas. Embaixo do formulário, um link "Salvar um caminho novo como rota" leva à tela de nova rota.
- Não há tela de detalhe da rota. O cartão já é o detalhe; editar e apagar ficam no próprio cartão.

**Mapinha no estilo do jogo.** É um SVG inline com o fundo do crepúsculo (tokens `deep`/`panel`), o traçado em dourado (`gold`) com brilho (`glow`), um ponto de início, e embaixo uma faixa com km, tempo e ritmo. Usa as fontes e tokens existentes; nada de mapa de ruas por baixo.

**Gerar o traçado a partir da foto**
- Acontece **no navegador**, num controller Stimulus, quando a foto é escolhida, e não no servidor.
- A foto padrão é o print de **compartilhar** do Samsung Health: mapa claro, trajeto grosso em degradê de laranja a vermelho, com o começo em verde, azul e amarelo, e a faixa de números embaixo.
- O controller ignora a faixa de números de baixo e o logo/data de cima, procura os pixels da linha do trajeto (saturados, na faixa de cor do trajeto, em traço grosso) e descarta os rios azul-claros finos, os parques verdes e o texto.
- Ele reduz esses pixels a uma polilinha ordenada e simplificada, de até uns 200 pontos, normaliza para 0–1 e mostra o mapinha na hora como prévia. O traçado vai num campo escondido do formulário.
- **Saída de um toque:** se a prévia sair errada, aparece "Tocar na linha do trajeto". O autor toca uma vez na linha da foto; o controller passa a seguir a cor daquele ponto e refaz a prévia. Não existe desenho à mão.
- Se não achar nada, a rota salva mesmo assim, sem traçado, com a arte padrão.
- O print do mapa escuro, de dentro do app Samsung Health (trajeto azul), não é obrigatório funcionar sozinho. A saída de um toque cobre esse caso.
- O algoritmo exato fica com o builder. O teste de aceitação usa o print de compartilhar real de 22/10, salvo em `test/fixtures/files/rota_guanabara.png`: o traçado tem que dar um contorno fechado parecido com um quadrilátero e não pode incluir o rio do topo.

## Desafios da semana

**De onde vêm.** Cada semana do plano em `config/world/01_vento_austral.yml` ganha números estruturados em `challenges`, ao lado do texto que já existe. O texto continua sendo o que se mostra no Mapa.

```yaml
challenges:
  walks: { count: 3, min_minutes: 40 }   # caminhadas curtas
  long_walk: { km: 8, load_kg: 5 }       # load_kg só quando a semana pede carga
  stairs: { count: 1 }                   # só quando a semana tem escada
```

Regra para tirar os números do texto, decisão minha:
- Faixas usam o menor valor: `3× 40–50 min` dá `count: 3, min_minutes: 40`; `2–3×` dá 2; `4–5 kg` dá 4.
- O longão usa o maior trecho de um dia: `sábado 15 km + domingo 10 km` dá `km: 15`; `3 dias seguidos de 15–20 km` dá 15.
- `sem mochila` não tem `load_kg`; `escada: não` não tem `stairs`.
- A carga vale para o longão, que é onde o plano pede a mochila.

**Os desafios**

| Desafio | Conta quando | XP |
|---|---|---|
| N caminhadas de M min | caminhada com `duration_s >= M*60`. Uma caminhada longa também conta. Caminhada sem tempo não conta. | 15 por caminhada, até N |
| Longão | uma caminhada com `km >= km` (e `load_kg >= load_kg`, se pedido) | 30 |
| Escada | N sessões de escada | 15 por sessão, até N |
| Semana completa | todos os desafios da semana feitos | 50 + selo |

**Qual semana uma caminhada conta.** A semana do plano é um trecho de km dentro da fase, não do calendário. Um registro conta para a semana em que o viajante estava **no começo daquele dia**, ou seja, antes de somar os km do dia. Isso sai do replay que `User::Journey` já faz dia a dia. Exemplo: estava no km 20 da semana 1 (0–22) e andou 8 km; os 8 km contam pra semana 1, mesmo que no fim do dia ele esteja na semana 2.

**Sem prazo.** Se o viajante passa para a semana seguinte sem fechar a anterior, os desafios dela só ficam sem ✓, sem nenhuma marca de "falhou". Enquanto um chefe espera, não há semana nem desafios; a tela mostra o card do chefe. Os bônus nunca movem a posição nem derrubam chefe.

**XP.** Entra no `User::Journey#xp` e é calculado no replay, nunca gravado, como tudo no Léguas.

**Tela da fase.** O card "Semana 1 de 4" vira "Desafios da semana · Semana 1 de 4", com:
- uma linha por desafio: ✓ ou ☐, o texto ("3 caminhadas de 40 min"), o progresso ("1/3") e o XP;
- a dica `phase.note` continua embaixo;
- os textos do plano (curtas, longa, carga, escada) saem dessa tela e continuam no Mapa.

**Selo de semana completa**
- Gera uma celebração, pelo mesmo mecanismo das outras (`Achievement`), com a chave `week:<fase>:<n>`.
- Aparece no Diário, numa seção "Semanas completas", que mostra **só as semanas fechadas**. Não há espaço vazio para semanas puladas, para não virar marca de falha. Decisão minha. A arte é um SVG só, reaproveitado, com o número da semana.

## Bônus do dia

- O card "Missão do dia", com a barra, sai da tela da fase.
- No lugar, uma linha discreta logo acima de "Registrar caminhada": "Hoje: 3,55 km · bônus do dia em 5 km". Quando bate a meta: "Hoje: 5,2 km · ✓ bônus do dia +20 XP", em dourado.
- Sem barra e sem cor de alerta.
- A regra continua a mesma: `Mission`, `goal_km` congelado no dia, `Mission::XP = 20`. Só muda a apresentação e o nome.

## Testes

Seguem o padrão do projeto: TDD, testes de lógica no mundo pequeno de `test/world/`, e testes de controller e de sistema.
- O mundo de teste ganha `challenges` nas semanas.
- Desafios: casos da tabela, a regra de "começo do dia", caminhada sem tempo não contando, longão com carga, chefe esperando sem desafios, e o XP somando no nível.
- Caminhada: parse de `38:51`, `1:05:20`, `4.507`; ritmo calculado.
- Rotas: CRUD, select preenchendo km, apagar rota mantendo as caminhadas.
- Traçado: teste do algoritmo de extração contra o print real (JS, rodado num teste de sistema); renderização do SVG a partir de um `trace` conhecido.
