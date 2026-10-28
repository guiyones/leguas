# Léguas: extensão do Strava

*Spec de design, 2026-10-28. Soma-se aos specs anteriores (`2026-10-22-rotas-e-bonus-design.md` e os de 2026-10-21). Onde divergem, vale este documento. Substitui a ideia do app Android com Health Connect.*

## Entendimento

**O que é.** O autor grava as caminhadas no Strava, que puxa os dados do relógio Samsung. O Léguas passa a ser uma extensão do Strava:

- busca as caminhadas de lá sozinho;
- transforma cada uma em progresso na trilha;
- escreve uma linha do jogo na descrição da atividade no Strava.

O registro à mão continua, de reserva, para quando ele caminhar sem o relógio.

**Por quê.** Digitar gerava erro: 1:31 foi gravado como 1 minuto e 31 segundos. Além disso, o Strava já tem a distância exata, o tempo em movimento, a subida e o traçado do GPS. Ver o jogo dentro do Strava ("+5,2 km na trilha, carimbo Ponta das Areias") é o que faz o Léguas parecer uma extensão, e não um app a mais.

**Deu certo quando**
- Ele conecta o Strava uma vez. A caminhada do dia 25, que só existe no Strava, aparece no Léguas sem ele digitar nada.
- As caminhadas manuais de 22, 23 e 24 não ficam duplicadas: cada uma é ligada à atividade do Strava do mesmo dia e ganha o traçado.
- Ele termina uma caminhada, abre o Léguas, e a celebração do marco aparece.
- No Strava, a descrição da caminhada termina com uma linha do Léguas, e o texto que ele escreveu antes da linha continua intacto.

**Objetivos**
- Conectar e desconectar a conta do Strava pelo Menu.
- Importar automaticamente as atividades de caminhada e trilha.
- Ligar uma atividade a uma caminhada manual que já existe, em vez de duplicar.
- Escrever de volta na descrição da atividade, com uma opção para desligar.

**Fora desta entrega**
- Webhook do Strava, em que o Strava avisa o Léguas na hora. Precisa do jogo publicado, que é o próximo projeto (deploy). Aqui a busca é feita quando o app abre.
- Perceber quando uma atividade é apagada ou editada no Strava depois de importada. Também depende do webhook.
- Login pelo Strava. O login continua sendo o código por e-mail.
- Outros jogadores. O app do Strava fica em "Single Player Mode", só para a conta do autor.
- Criar uma rota a partir do traçado de uma caminhada do Strava. Fica para depois, mas o traçado já é guardado no formato das rotas.
- As estrelas dos trechos. Voltam depois desta entrega, usando o ritmo que vem do Strava.

**Anti-objetivos**
- Duplicar km. Uma atividade nunca vira duas caminhadas, nem soma por cima de uma manual.
- Apagar ou reescrever o que o autor escreveu no Strava.
- Travar o app quando o Strava estiver fora do ar ou recusar a conexão. O Léguas continua funcionando com o que já tem.

## Regras

### Conexão

- No Menu aparece "Conectar com Strava". O OAuth do Strava pede os escopos `activity:read_all` (inclui atividades privadas) e `activity:write` (para a descrição).
- Se o autor desmarcar `activity:write` na tela do Strava, a conexão funciona assim mesmo, só sem a escrita de volta. Sem `activity:read_all` não há o que fazer: o Léguas mostra "O Léguas precisa ler suas atividades" e não conecta.
- Os escopos concedidos vêm no parâmetro `scope` do retorno do OAuth e são guardados na conexão. A escrita de volta consulta esse campo.
- Os tokens ficam no banco, criptografados com Active Record Encryption. O token de acesso expira em 6 horas e é renovado com o refresh token antes de cada chamada, quando estiver vencido.
- Se o Strava recusar o refresh token (o autor revogou o acesso pelo site do Strava), a conexão é apagada e o Menu volta a mostrar "Conectar com Strava". As caminhadas importadas ficam.
- "Desconectar Strava" no Menu chama o deauthorize do Strava, apaga a conexão e mantém as caminhadas importadas.
- O `client_id` e o `client_secret` do app do Strava ficam nas credentials do Rails (`strava.client_id`, `strava.client_secret`). Quem cria o app no Strava e coloca os valores é o autor. O `config/master.key` nunca sai da máquina dele.

### O que é importado

- Entram só as atividades com `sport_type` `Walk` ou `Hike`. As outras são ignoradas sem aviso.
- Uma atividade vira uma caminhada assim:

  | Caminhada | Vem de |
  |---|---|
  | `km` | `distance` (metros) ÷ 1000, com 2 casas |
  | `walked_on` | data de `start_date_local` |
  | `duration_s` | `moving_time` |
  | `elevation_gain_m` | `total_elevation_gain`, arredondado |
  | `trace` (novo campo) | `map.summary_polyline`, convertido para o formato de `Route::Trace` (abaixo) |
  | `note` | o nome da atividade no Strava, cortado em 140 caracteres |
  | `strava_activity_id` (novo campo) | `id` |

  Passos, mochila e rota não vêm do Strava. O autor pode acrescentar depois, editando a caminhada.
- Valem as mesmas regras da caminhada manual:
  - só entram atividades de hoje ou dos últimos 7 dias (`Backdatable`);
  - o limite de 100 km por dia continua.

  Uma atividade que fura uma regra é pulada e não trava as outras.
- Uma atividade pulada (velha demais, acima do limite do dia) não é guardada em lugar nenhum. Ela só volta a ser tentada enquanto estiver dentro da janela de busca, o que é inofensivo.
- Uma atividade com distância zero, por exemplo gravada sem GPS, é pulada.
- `strava_activity_id` é único por usuário. Importar de novo a mesma atividade não faz nada.
- **Traçado.** O polyline decodificado vira pontos de latitude e longitude, que são projetados no plano:
  - x = longitude × cos(latitude média);
  - y = −latitude, para o norte ficar em cima.

  Depois os pontos são simplificados para no máximo `Route::Trace::MAX_POINTS` e normalizados com `Route::Trace.normalize`. Atividade sem polyline fica sem traçado. A lista de caminhadas mostra o traçado em miniatura, do mesmo jeito que o card da rota.

### Juntar com uma caminhada manual

- Antes de criar uma caminhada nova, o importador procura uma caminhada manual do autor que cumpra três condições:
  - é do mesmo `walked_on`;
  - não tem `strava_activity_id`;
  - tem `km` com no máximo 15% de diferença da atividade (em relação ao maior dos dois).
- Se houver mais de uma, vale a de km mais próximo.
- Achou: a caminhada ganha o `strava_activity_id` e recebe só o que estava vazio (`duration_s`, `elevation_gain_m`, `trace`). Km, data, rota, mochila e observação digitados à mão continuam como estão. Assim, separar depois não perde nada.
- Não achou: cria uma caminhada nova.
- As atividades são processadas da mais antiga para a mais nova, e cada caminhada manual só pode ser ligada a uma atividade. Com duas atividades no mesmo dia e uma caminhada manual, a mais parecida liga e a outra entra como nova.
- Isso vale para a primeira conexão (22, 23 e 24 se ligam, 25 entra como nova) e para sempre depois.
- **Separar.** A tela de editar de uma caminhada ligada ao Strava tem o botão "Não é esta caminhada". Ele faz duas coisas:
  - tira o `strava_activity_id` e o `trace` da caminhada manual;
  - importa a atividade como caminhada nova, sem tentar juntar de novo.

  As duas coisas acontecem numa transação só. Se a importação falhar (por exemplo, a atividade já passou dos 7 dias), nada é separado e aparece o erro.

### Quando a busca acontece

- Na primeira conexão, logo depois do OAuth: busca as atividades dos últimos 7 dias, mostra a celebração se houver alguma e depois o resumo: "3 caminhadas ligadas ao Strava, 1 importada".
- Depois, ao abrir a tela da Fase ou o Menu, desde que a última busca tenha sido há mais de 5 minutos. A página carrega normalmente, sem esperar pelo Strava. Uma ação em JS faz um POST de sincronização e:
  - se entrou caminhada e há celebração pendente, navega para a celebração;
  - se entrou caminhada sem celebração, recarrega a página e mostra o aviso de XP, como no registro manual;
  - se não entrou nada, não faz nada.
- A busca roda dentro do próprio POST, de forma síncrona: é uma chamada ao Strava, rápida para um jogador. A resposta diz se entrou caminhada e para onde ir.
- **Duas buscas ao mesmo tempo** (duas abas, celular e computador): antes de chamar o Strava, a busca marca `synced_at` com um UPDATE condicional (`WHERE synced_at IS NULL OR synced_at < 5 min atrás`). Se nenhuma linha mudou, outra busca já está rodando, e esta não faz nada. "Buscar agora" ignora os 5 minutos, mas usa a mesma marcação.
- A celebração já sai do estado (`User#pending_celebration_keys`), então uma caminhada importada dispara a celebração sem mecanismo novo.
- A busca usa `after` com a hora da atividade mais recente já importada (com uma folga de um dia) e nunca volta mais que 7 dias. Uma página de 30 atividades basta para um jogador.
- Qualquer erro do Strava (fora do ar, limite de uso, rede) é registrado no log e fica em silêncio. A próxima abertura tenta de novo.
- No Menu, abaixo de "Strava conectado", aparece "Última busca: há 3 min" e o botão "Buscar agora".

### Escrever no Strava

- Depois que uma caminhada é importada ou ligada, um job acrescenta uma linha no fim da descrição da atividade. Os passos:
  1. Lê a descrição atual com `GET /activities/{id}`.
  2. Se ela já tem uma linha do Léguas, troca só essa linha; se não tem, acrescenta a linha depois de uma linha em branco.
  3. Grava com `PUT /activities/{id}`.
- A linha do Léguas é reconhecida por começar com `🥾 Léguas`.
- Formato da linha:
  - sempre: `🥾 Léguas · +5,2 km na Trilha do Vento Austral · Fase 1, km 22`;
  - acrescentando o que a caminhada conquistou, nesta ordem e separado por ` · `:
    - `Carimbo Ponta das Areias`, ou `Carimbo dourado Ponta das Areias` quando o trecho foi conquistado;
    - `Chefe à vista: O Primeiro Horizonte`;
    - `Chefe derrotado: O Primeiro Horizonte`;
    - `Novo título: Andarilho`.

  O "km 22" é a posição na fase logo depois desta caminhada.
- **Quando o texto é calculado.** A linha é montada no momento da importação, dentro da busca, comparando a jornada antes e depois de salvar a caminhada:
  - os km e a posição saem de `User::Journey`;
  - o que foi conquistado sai da diferença entre `achievement_keys` antes e depois.

  O job recebe o texto pronto e só escreve. Assim a linha não muda se outras caminhadas entrarem antes de o job rodar.
- Uma caminhada manual ligada ao Strava também ganha a linha. Ela é montada na hora da ligação, com a posição atual da jornada.
- No Menu há o interruptor "Escrever no Strava", ligado por padrão. Desligado, nada é escrito. Também nada é escrito se a conexão não tiver o escopo `activity:write`.
- Falha ao escrever não desfaz nada no Léguas. O job tenta de novo algumas vezes e depois desiste em silêncio.

### Telas

- **Menu:**
  - Desconectado: o botão "Conectar com Strava", seguindo as regras de marca do Strava.
  - Conectado: "Strava conectado", a última busca, "Buscar agora", o interruptor "Escrever no Strava" e "Desconectar Strava".
- **Registrar caminhada:** igual a hoje. O título ganha a dica "Caminhou com o relógio? Ela vem sozinha do Strava.", só quando o Strava está conectado.
- **Lista de caminhadas:**
  - as que vieram do Strava ou foram ligadas a ele têm a marquinha "via Strava", com link para a atividade (`https://www.strava.com/activities/{id}`);
  - quem tem traçado mostra a miniatura.
- **Editar caminhada ligada ao Strava:**
  - km, data e tempo ficam só para leitura, com a nota "vem do Strava";
  - rota, mochila, passos, subida e observação continuam editáveis;
  - "Não é esta caminhada" separa, como descrito em "Separar".
  - "Remover" apaga a caminhada e marca a atividade como ignorada, para a próxima busca não trazer de volta. Isso vale também para uma caminhada manual que foi ligada: o autor remove a caminhada inteira. Se quiser só desfazer a ligação, usa "Não é esta caminhada".

## Dados

- **`strava_connections`**, um por usuário:
  - `user_id` (único);
  - `athlete_id`;
  - `access_token` e `refresh_token`, criptografados;
  - `expires_at`;
  - `scopes`;
  - `write_back` (boolean, padrão true);
  - `synced_at`.
- **`walks`** ganha:
  - `strava_activity_id` (bigint, índice único com `user_id`);
  - `trace` (json, mesmo formato e validação de `Route::Trace`).
- **`strava_ignored_activities`** guarda o `user_id` e o `activity_id` das caminhadas removidas pelo autor, para não voltarem.
- Nada de posição, XP ou conquista é gravado. O progresso continua sendo calculado das caminhadas em `User::Journey`.

## Deixado para quem constrói

- Cliente HTTP: o `Net::HTTP` da biblioteca padrão basta, sem gem nova, a não ser que uma simplifique muito o OAuth.
- Como organizar o código, por exemplo `Strava::Client`, `Strava::Importer`, `Strava::WriteBackJob`.
- Testes sem rede: stubs das respostas do Strava. Os fixtures JSON copiam o formato real da API.
- O algoritmo de simplificação do traçado. Pode reaproveitar a ideia do RDP do importador de prints.
- **Callback domain.** No cadastro do app do Strava, o domínio de retorno do OAuth é `localhost` enquanto o jogo não está publicado. Pelo celular na rede de casa (`192.168.1.12`), o autor conecta uma vez pelo computador. A conexão vale para o celular também, porque é da conta.
