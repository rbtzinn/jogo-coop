# Combate — Respeitável Público

> Parte do [DESIGN.md](DESIGN.md). Aprovado pelo usuário em 01/10/2026; números (dano, tempos, preços) serão calibrados nos testes.

## Vida e dano

- Cada jogador tem **3 pontos de vida (PV)**. Adereços podem aumentar.
- Ao levar dano: perde 1 PV, fica **1,5 s invencível** (piscando) e é empurrado levemente para trás.
- Encostar no corpo do chefão também causa dano (exceto durante dash invencível).
- Detecção de dano favorável a quem joga: a caixa de dano do jogador é **menor que o desenho** (já é assim) e a decisão de "fui atingido" é tomada no PC de quem joga (ver regras de rede no CLAUDE.md).

## Cair e reviver: o Balão (decidido)

Diferente do Cuphead (fantasma), aqui quem cai **vira um balão de circo com a própria cara**, que sobe devagar.

- O balão leva **cerca de 6 segundos** para sair pelo topo da tela (sobe 190 px/s, balançando). Em "Testar sozinho", quando o personagem controlado cai, o controle passa sozinho para o outro.
- O parceiro revive **ficando encostado no balão por 1 s** (um anel em volta do balão mostra quanto falta; até 06/10/2026 era com parry, como no Cuphead). O revivido volta com **1 PV** e quem resgatou ganha 1 estrela.
- Se o balão sair da tela, aquele jogador está fora até o fim da luta.
- **Os dois caírem = derrota.**
- O balão balança com o vento dos ataques do chefão, o que deixa o resgate mais emocionante.

## Parry

Objetos **rosa** (`#ff5fa2`) podem receber parry. Todo chefão tem alguns ataques rosa.

- **Como fazer (decidido):** apertar **pular de novo no ar** encostando no objeto rosa (como no Cuphead). Sem botão novo; com "Cima pula", é só apertar Cima de novo no ar.
- Efeito: o personagem **quica para cima** (pulo extra), o objeto é destruído ou anulado e ele ganha **1 estrela de Aplauso** (ver Especial).
- Janela generosa: a área de parry do personagem é bem maior que o desenho (círculo de 105 px em volta do corpo) e o parry vale por 0,22 s depois de apertar. Uma tentativa por pulo; um parry certo devolve a tentativa.
- **Parry em dupla (diferencial):** se os dois jogadores derem parry no **mesmo objeto** com até **0,3 s** de diferença, sai um **"Número Perfeito"**: cada um ganha 2 estrelas, a tela dá um flash e a plateia aplaude. Alguns chefões têm objetos rosa grandes feitos para isso.

## Especial: a barra de Aplausos

Cada jogador tem uma barra de **5 estrelas de Aplauso**. Ela enche causando dano ao chefão e com parries (+1 estrela cada).

- **Tiro EX (gasta 1 estrela):** versão forte do tiro da pistola equipada, na direção da mira. Cada pistola tem o seu (ver [shop.md](shop.md)).
- **Grande Número (gasta as 5 estrelas):** golpe máximo, **diferente para cada personagem** (no Cuphead é igual para os dois):
  - **Palhaço — "Torta na Cara":** arremessa uma torta gigante que atravessa a tela causando muito dano, e o palhaço fica invencível durante a animação.
  - **Acrobata — "Salto Mortal":** salta girando por cima do chefão, invencível, causando dano em tudo que atravessa.
  - **Invencível pelo menos 2 s** desde o começo do Grande Número, nos dois (pedido do usuário em 04/10/2026): o que sobra depois da animação pisca, como depois de levar dano (`PlayerSpecial.GRAND_MIN_INVINCIBLE`).
- **Grande Número em Dupla (diferencial):** se os dois soltarem o Grande Número com até **1 s** de diferença, os golpes se combinam num ataque único maior (ex.: a acrobata salta em cima da torta e a chuta no chefão), com dano maior que a soma dos dois.
- Novo botão **Especial**. Padrão sugerido: teclado **I** (layout 1) e **V** (layout 2, como no Cuphead); controle **Y**. Toque = Tiro EX; com 5 estrelas, toque = Grande Número.

### Como ficou no jogo (02/10/2026, primeira versão; números a calibrar)

Decisões tomadas pelo Claude enquanto o usuário estava fora (revisar):

- **Botão Especial** em Configurações > Controles. O aperto fica guardado 0,2 s (apertado no meio do dash, sai quando o dash acaba). Caído, nada acontece.
- **Tiro EX "Rolhão"** (pistola Rolha): rolha gigante na direção da mira que atravessa o chefão, "afunda" nele (fica mais lenta enquanto encosta) e acerta até **6 vezes x 5 de dano = 30** (o tiro normal dá 1 por rolha). Recuo de 0,25 s: empurra para trás, sem atirar; **no ar, fica pairando**; o dash corta o recuo. Não é invencível.
- **Torta na Cara**: o palhaço para (até no ar), ergue a torta (0,38 s) e arremessa na direção da mira; a torta cruza a tela, afunda no chefão e acerta até **10 x 14 = 140**. Invencível por 0,75 s + 0,2 s.
- **Salto Mortal**: a acrobata agacha (0,12 s) e salta em arco de 760 px para o lado em que olha, 400 px de altura, girando 2 voltas; acerta até **7 x 20 = 140** (mais nas costas do leão, que levam dano dobrado). Invencível o salto inteiro + 0,3 s. Se pousar antes (num pedestal), acaba ali.
- **O especial não enche a barra** (como no Cuphead): só os tiros normais e os parries dão estrelas.
- **Número Perfeito**: depois que um jogador estoura o objeto rosa, o parceiro ainda consegue dar parry nele por 0,3 s (o objeto já sumiu, mas a área continua). Cada um ganha 2 estrelas; flash dourado, letreiro "Número Perfeito!". Online: se em qualquer um dos PCs a diferença couber em 0,3 s, conta para os dois (favorável a quem joga).
- **Grande Número em Dupla** (primeira versão): os dois Grandes Números acontecem normalmente e, por cima, sai a **Torta de Ouro**: uma torta dourada gigante sai do meio da dupla e explode no chefão com **+120 de dano** (total ~400, mais que os 280 da soma). Letreiro "Grande Número em Dupla!". O dano extra é contado só no host. Quando chegar a arte da acrobata chutando a torta (Pedido 3 em docs/prompts/codex_parry_balao_especiais.md), a Torta de Ouro passa a ser chutada por ela, como na prancha `combate_especial.png`.
- Ainda **sem som** (o jogo não tem áudio); o aplauso da plateia entra quando o áudio entrar.
- Para testar: **F1** enche as estrelas (só na versão de desenvolvimento).

### Objetos rosa do Domador

| Fase | Ataque | Rosa |
|---|---|---|
| 1 | Argolas de fogo | 1 das 3 argolas |
| 1 | Chicotada | metade das vezes, a última onda |
| 2 | Patada | metade das vezes, uma das duas ondas de poeira |
| 3 | Pulos nos Pedestais | 2 brasas de um dos pousos |
| 3 | Chuva de Argolas | a última argola de cada leva |

## Crítica da plateia (nota no fim da luta)

Ao vencer, aparece um cartaz de circo com a reação da plateia à luta da dupla. **Desde 06/10/2026** (pedido do
usuário: os critérios antigos, tempo, vida, parries e estrelas, eram o mesmo conjunto do Cuphead) o que a dupla
faz junta pesa um quarto da nota. 100 pontos no total (`FightGrade`):

| Critério | Em dupla | Sozinho |
|---|---|---|
| Tempo (cheio até o tempo-alvo do chefão, zero no dobro) | 30 | 35 |
| Vida restante (somando os dois; caído conta 0) | 25 | 30 |
| Números em dupla: Número Perfeito, Grande Número em Dupla, resgate do parceiro (até 3) | 25 | — |
| Truques: parries + estrelas usadas, dos dois (até 8) | 20 | 35 |

Nota: **S** a partir de 90, **A** a partir de 75, **B** a partir de 55, senão **C**. No cartaz e na tenda do
mapa a nota aparece como a reação da plateia: S **"Ovação!"**, A **"Aplausos"**, B **"Palmas"**, C
**"Silêncio"** (a letra fica pequena no placar e no save). Em dupla, sem nenhum número em dupla a nota vai no
máximo até A. Melhorar a melhor nota de um chefão dá ingressos de bônus (ver [shop.md](shop.md)). Online, quem
calcula é o host e o cliente recebe o mesmo cartaz.

## Dificuldade

- Os chefões são balanceados **para 2 jogadores**. Com um só atirando, cada tiro no chefão vale por dois (`BossBrain.SOLO_DAMAGE`; decidido com o usuário em 04/10/2026): no "Testar sozinho" sempre, e online enquanto o parceiro está caído (balão) ou saiu da partida. Com os dois de pé, vale 1. Online quem aplica é o host, na hora em que o tiro chega.
- Duração alvo de uma luta: **2 a 3 minutos** quando bem jogada.
- Vida do chefão dividida por fase (ex.: 40% / 35% / 25%); a troca de fase é sempre clara (animação + som).
