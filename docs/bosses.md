# Chefões — Respeitável Público

> Parte do [DESIGN.md](DESIGN.md). Aprovado pelo usuário em 01/10/2026; números (dano, tempos, preços) serão calibrados nos testes.

## Regras para todo chefão

- **2 a 4 fases**, cada uma com padrões de ataque legíveis; troca de fase sempre com animação clara.
- Todo ataque tem um **aviso** antes (pose, som, brilho) — morrer tem que parecer culpa do jogador.
- Pelo menos **1 ataque rosa** (parry) por fase; os chefões da Área 1 ensinam o parry com calma.
- **Difícil, mas nunca impossível** (decidido em 02/10/2026, após o 1º teste do Domador): todo ataque tem que ser desviável sem levar dano, com uma janela de reação justa. Ondas com buraco precisam deixar passar com um pulo normal e vir espaçadas o bastante para pular uma e cair antes da próxima (conferido com um teste automático que joga sozinho).
- **Ordem aleatória sem repetir:** os ataques de cada fase saem de um "saco embaralhado" (todos aparecem antes de algum repetir).
- **Janelas conferidas por teste automático:** pular a Corrida (~0,3 s de folga), as ondas do Rugido (~0,3 s) e as ondas da Patada.
- **Sem tempo morto:** o respiro entre ataques é curto (0,35–0,7 s) e todo ataque cobre mais de uma altura do cenário. Ficar parado num canto atirando não pode ser seguro (ex.: as argolas soltam brasas que caem no chão).
- Pelo menos **1 momento de dupla** por chefão (ver "Dependência entre jogadores" no DESIGN.md).
- Ataques determinísticos sempre que possível (o host manda "ataque X começou no tempo T").
- Cada chefão em `bosses/<nome>/`, sem depender de outro chefão.

## Área 1 — O Grande Picadeiro (aprovado)

Ordem: Domador (fácil) → Irmãos Malabaristas (médio) → Grande Mágico (difícil, fecha a área). **Primeiro a construir (etapa 4): o Domador.** Mais uma fase de plataforma: **"Corrida no Trem do Circo"** (correr e atirar em cima dos vagões em movimento).

---

### 1. O Domador e Leopoldo, o Leão

*Um domador baixinho e convencido, com um leão enorme que só finge obedecer.* Arena: picadeiro com 3 pedestais.

**Fase 1 — "O Número Ensaiado"** (40%)
- **Chicotada:** o domador estala o chicote no chão; uma onda corre pelo picadeiro (pular).
- **Argolas de fogo:** Leopoldo atravessa a tela pulando por argolas que o domador segura. Algumas argolas são **rosa** (parry para quicar por cima).
- **Rugido:** Leopoldo ruge; ondas de som em arco (passar entre elas ou dar dash).
- **Volta no Picadeiro** (pedido do usuário após o teste online de 02/10/2026): Leopoldo desce do pedestal, corre pelo chão até a parede e volta pulando em arco (baixo ou alto) até o domador.

**Fase 2 — "Fora de Controle"** (35%)
- O domador foge para cima do pedestal, tremendo (não leva mais tiro).
- **Corrida:** Leopoldo raspa a pata e corre de um lado ao outro (pular por cima, ficar num pedestal ou dar dash); às vezes volta pulando em arco para o lado de onde saiu.
- **Patada:** ele salta e cai no lugar onde um jogador estava (sombra no chão avisa); ao cair solta ondas de poeira rente ao chão. Pode vir duas vezes seguidas, uma em cada jogador.
- **Momento de dupla — Isca:** Leopoldo persegue **o jogador que mais causou dano nos últimos segundos** (um aviso vermelho em cima dele). Um faz de isca correndo enquanto o outro bate pelas costas, onde o leão toma o dobro de dano (vale a luta toda).

**Fase 3 — "O Leão de Fogo"** (25%)
- Leopoldo engole a tocha que o domador joga nele e vira um leão de fogo.
- **Pulos nos Pedestais:** pula de pedestal em pedestal (sombra avisa onde), espalhando brasas a cada pouso.
- **Chuva de Argolas:** argolas de fogo caem do teto em duas levas (uma chama pisca no alto antes de cada uma; sempre sobra uma coluna livre); a última de cada leva é **rosa**.
- **Corrida** mais rápida.
- Ao vencer: o domador, sem graça, tenta fazer uma reverência para a plateia.

---

### 2. Os Irmãos Malabaristas, Tico e Teco

*Dois irmãos gêmeos que nunca param de malabarizar — inclusive um com o outro.* **Um chefão que também é dupla**, como os jogadores.

**Fase 1 — "Troca-Troca"** (40%)
- Cada irmão de um lado da arena jogando claves e bolas em arco para o outro; os objetos atravessam a tela (desviar).
- Às vezes trocam de lugar dando um salto mortal pelo meio da arena.
- Uma das bolas de cada sequência é **rosa**.

**Fase 2 — "Totem"** (35%)
- Teco sobe nos ombros de Tico e os dois andam pela arena como um totem, arremessando para cima e para os lados.
- Bolas de boliche rolando no chão (pular).

**Momento de dupla — "Um Não Vive Sem o Outro"** (vale nas fases 1 e 2)
- Cada irmão tem sua própria barra de vida. Se só um levar dano, **o outro joga uma "bola de cura"** nele após alguns segundos.
- Para ganhar, a dupla precisa **se dividir**: cada jogador foca um irmão. Os dois precisam cair juntos (até 3 s de diferença).

**Fase 3 — "Monociclo Gigante"** (25%)
- Os irmãos montam num monociclo gigante e atravessam a arena; malabares viram tochas.
- No fim, os dois tentam um último malabarismo um com o outro… e caem um em cima do outro.

**Como ficou no jogo (03/10/2026, decidido pelo Claude, revisar; números a calibrar):**

- Arena: o picadeiro com **dois pedestais pendurados** no meio (topo na altura 760, alcançável com um pulo). Os irmãos começam um em cada lado; os jogadores, no meio.
- **Vida:** 1500 no total, 750 para cada irmão; uma barra pequena para cada um embaixo do letreiro. Nas fases 1 e 2, um irmão **não passa do limite da fase**: ao chegar nele fica **tonto** (estrelas na cabeça). Depois de **3 s** tonto, se o outro ainda estiver de pé, o outro joga uma **bola de cura rosa** (voa 1,2 s; um parry estoura e ganha estrela) que devolve 40% da vida da fase. A fase só troca quando **os dois** chegam ao limite. Na fase 3 não há limite: quem chega a zero passa o dano para o irmão.
- **Fase 1 — Troca-Troca:** *Troca-Troca* (6 arremessos alternados por três faixas: alta, média e rasteira, que quica no chão no meio; uma rasteira nunca vem colada numa média; um objeto rosa por sequência), *Troca de Lugar* (agacham como aviso e trocam de lado: um por cima, alto; o outro rolando na altura do peito: **abaixar** ou dash), *Bolas Quicando* (3 bolas grandes atravessam quicando; às vezes uma rosa).
- **Fase 2 — Totem:** *Totem Andante* (atravessa a arena enquanto claves caem em lugares marcados por sombra; **o pedestal é seguro**, o totem passa por baixo; às vezes uma clave rosa), *Boliche* (3 bolas rolando no chão: pular; às vezes uma rosa), *Claves em Linha* (4 claves retas: baixas na altura da cabeça, **abaixar**; altas na altura do pulo e dos pedestais, ficar no chão).
- **Fase 3 — Monociclo Gigante:** *Monociclo* (vai e volta pela arena; só a roda machuca: pular por cima, dash ou ficar no pedestal, que passa no vão entre a roda e o selim), *Chuva de Tochas* (5 tochas caem em lugares marcados e deixam fogo no chão por 0,9 s; sempre sobra lugar; às vezes uma rosa, sem fogo), *Bolas Quicando* (do alto do monociclo).
- Tempo-alvo da nota: 2:40.

---

### 3. O Grande Mágico Zaratan

*Um mágico de capa e cartola, elegante e teatral. Ele parece saber que o circo está amaldiçoado.*

**Fase 1 — "Abracadabra"** (35%)
- **Cartas voadoras:** leques de cartas atravessam a tela; os ases de copas são **rosa**.
- **Coelhos da cartola:** coelhos saltam para fora e correm na direção dos jogadores (atirar ou pular).
- **Teleporte:** some numa fumaça e reaparece em outro ponto do palco (aviso: uma estrela brilha onde ele vai surgir).

**Fase 2 — "A Mulher Serrada"… sem mulher** (30%)
- Caixas de mágica descem do teto; serras atravessam as caixas e saem pelos lados.
- Zaratan se esconde numa de 3 caixas que embaralham; acertar a errada solta pombas que atacam.
- **Momento de dupla — Holofotes:** a luz se apaga; só se vê o que está dentro de **dois holofotes, um seguindo cada jogador**. Ficarem perto ilumina mais a arena; separados, cada um enxerga pouco.

**Fase 3 — "O Grande Final"** (35%)
- Zaratan vira um mágico gigante (só cabeça, cartola e duas mãos enormes saindo da escuridão).
- As mãos tentam agarrar os jogadores (dash para escapar); a cartola despeja de tudo.
- Ao vencer: ele cai na própria cartola e some — deixando para trás um **ingresso dourado** que leva à próxima área (gancho da história).

---

## Ideias para áreas futuras

- **O Homem-Forte** (halteres que tremem a arena), **Os Trapezistas** (luta toda no ar, em trapézios), **O Homem-Bala** (canhões e bombas), **O Engolidor de Espadas**, **A Elefanta Dona Bebel**.
- **Chefão final do jogo: O Mestre de Cerimônias** — o dono do circo, quem fez o pacto que amaldiçoou tudo. Abre a luta gritando **"Respeitável público!"**.
