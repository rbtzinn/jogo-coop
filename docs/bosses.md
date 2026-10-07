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

**Corrida no Trem do Circo — como ficou (02/10/2026, decidido pelo Claude, revisar):** 8 vagões (o último é a locomotiva) com vãos de 160 a 220 px entre eles (um pulo normal passa). Caixotes em cima de alguns vagões. Inimigos: 4 palhacinhos-fantasma (4 tiros), 3 pombos de mágico (2 tiros; um rosa), 2 canhões de confete (8 tiros; bolas rente ao chão a cada 2,4 s, 1 em 4 rosa). Ponte baixa a cada 13 s (a primeira aos 9 s), passando rápido por cima do trem: abaixar (ou descer do caixote). Ingressos escondidos: em cima do vão entre o 3º e o 4º vagão, em cima da pilha de caixotes do 5º e acima do caixote do 7º. Cair no vão: -1 vida e volta no vagão visível mais próximo. Chegar na cabine da locomotiva termina a fase.

---

### 1. O Domador e Leopoldo, o Leão

*Um domador baixinho e convencido, com um leão enorme que só finge obedecer.* Arena: picadeiro com 3 pedestais.

**Fase 1 — "O Número Ensaiado"** (40%)
- **Chicotada:** o domador estala o chicote no chão; uma onda corre pelo picadeiro (pular).
- **Argolas de fogo:** Leopoldo atravessa a tela pulando por argolas que o domador segura. Algumas argolas são **rosa** (parry para quicar por cima).
- **Rugido:** Leopoldo ruge; ondas de som em arco (passar entre elas ou dar dash).
- **Volta no Picadeiro** (pedido do usuário após o teste online de 02/10/2026): Leopoldo desce do pedestal, corre pelo chão até a parede e volta pulando em arco (baixo ou alto) até o domador.

**Fase 2 — "Fora de Controle"** (35%)
- O domador foge para cima do pedestal, tremendo. **Mudou em 04/10/2026** (pedido do usuário: em cima do pedestal, do lado dele, ninguém tomava dano e dava para ganhar só atirando dali): lá em cima ele continua levando tiro e machucando quem encosta, e a cada 2,6 s estala o chicote de medo para um lado do pedestal, alternando (ergue o chicote 0,5 s antes, como aviso; o estalo machuca 0,25 s, do corpo até passar da beira; pulando passa por cima). Vale nas fases 2 e 3, fora das trocas de fase.
- **Corrida:** Leopoldo raspa a pata e corre de um lado ao outro (pular por cima, ficar num pedestal ou dar dash); às vezes volta pulando em arco para o lado de onde saiu.
- **Patada:** ele salta e cai no lugar onde um jogador estava (sombra no chão avisa); ao cair solta ondas de poeira rente ao chão. Pode vir duas vezes seguidas, uma em cada jogador.
- **Momento de dupla — Isca:** Leopoldo persegue **o jogador que mais causou dano nos últimos segundos** (um aviso vermelho em cima dele). Um faz de isca correndo enquanto o outro bate pelas costas, onde o leão toma o dobro de dano (vale a luta toda).

**Fase 3 — "O Leão de Fogo"** (25%)
- Leopoldo engole a tocha que o domador joga nele e vira um leão de fogo.
- **Pulos nos Pedestais:** pula de pedestal em pedestal (sombra avisa onde), espalhando brasas a cada pouso.
- **Chuva de Argolas:** argolas de fogo caem do teto em duas levas (uma chama pisca no alto antes de cada uma; sempre sobra uma coluna livre); a última de cada leva é **rosa**.
- **Corrida** mais rápida.
- Ao vencer: o domador, sem graça, tenta fazer uma reverência para a plateia.
- **Vida:** 1200 (era 1500 até 04/10/2026; o usuário achou as lutas longas demais em dupla). As outras lutas também perderam 20%.

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

**Como ficou no jogo (02/10/2026, decidido pelo Claude, revisar; números a calibrar):**

- Arena: o picadeiro com **dois pedestais pendurados** no meio (topo na altura 760, alcançável com um pulo). Os irmãos começam um em cada lado; os jogadores, no meio.
- **Vida:** 1200 no total, 600 para cada irmão (eram 1500 e 750 até 04/10/2026); uma barra pequena para cada um embaixo do letreiro. Nas fases 1 e 2, um irmão **não passa do limite da fase**: ao chegar nele fica **tonto** (estrelas na cabeça). Depois de **3 s** tonto, se o outro ainda estiver de pé, o outro joga uma **bola de cura rosa** (voa 1,2 s; um parry estoura e ganha estrela) que devolve 40% da vida da fase. A fase só troca quando **os dois** chegam ao limite. Na fase 3 não há limite: quem chega a zero passa o dano para o irmão. **Tonto fica parado (04/10/2026, pedido do usuário: o tonto pulava e arremessava, e o desenho tonto pulando ficava feio):** separados, quem está tonto não arremessa (os arremessos dele no Troca-Troca não saem, as Bolas Quicando são do outro) e eles não trocam de lugar; se ficar tonto ainda agachado para a troca, os dois desistem dela. No totem a tontura continua igual (os dois andam juntos).
- **Fase 1 — Troca-Troca:** *Troca-Troca* (6 arremessos alternados por três faixas: alta, média e rasteira, que quica no chão no meio; uma rasteira nunca vem colada numa média; um objeto rosa por sequência), *Troca de Lugar* (agacham como aviso e trocam de lado: um por cima, alto; o outro rolando na altura do peito: **abaixar** ou dash), *Bolas Quicando* (3 bolas grandes atravessam quicando; às vezes uma rosa).
- **Fase 2 — Totem:** *Totem Andante* (atravessa a arena enquanto claves caem em lugares marcados por sombra; às vezes uma clave rosa; **desde 05/10/2026 o pedestal não é mais seguro**: o totem cresceu 30% e o de cima pega quem está na tábua, então lá é preciso pular por cima dele ou dar dash; do chão, o pulo passa rente), *Boliche* (3 bolas rolando no chão: pular; às vezes uma rosa), *Claves em Linha* (4 claves retas: baixas na altura da cabeça, **abaixar**; altas na altura do pulo e dos pedestais, ficar no chão). **Desenhado desde 04/10/2026 (E7):** os dois num desenho só, menores que nas outras folhas (no jogo, 30% maiores que o desenho entregue: até ~278 px, mais alto que a tábua; pedido do usuário em 05/10/2026). O de baixo carrega; quando a base é o Teco, as cores do desenho trocam. As claves saem da luva desenhada do de cima.
- **Fase 3 — Monociclo Gigante:** *Monociclo* (vai e volta pela arena; a roda e os irmãos machucam; desde 05/10/2026 o selim fica a 330 px do chão (era 380) e os irmãos pegam quem está no pedestal: o desvio seguro é o dash; pular a roda do chão fica arriscado). Os irmãos em cima já têm desenho (folha do ChatGPT de 05/10/2026, arrumada por `tools/normalize_rider_sheet.gd` na escala do totem: pedalando, e cada um arremessando); o monociclo segue por código, agora com os pedais lá em cima e corrente até a roda (pedido 2 de `docs/prompts/chatgpt_monociclo.md` para as peças), *Chuva de Tochas* (5 tochas caem em lugares marcados e deixam fogo no chão por 0,9 s; sempre sobra lugar; às vezes uma rosa, sem fogo), *Bolas Quicando* (do alto do monociclo).
- Tempo-alvo da nota: 2:40.

---

### 3. O Grande Mágico Zaratan

*Um mágico de capa e cartola, elegante e teatral. Ele parece saber que o circo está amaldiçoado.*

**Fase 1 — "Abracadabra"** (35%)
- **Bilhetes voadores** (eram cartas de baralho até 06/10/2026): leques de bilhetes encantados atravessam a tela; os de parry são **turquesa**.
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

**Como ficou no jogo (02/10/2026, decidido pelo Claude, revisar; números a calibrar):**

- Vida 1280 (era 1600 até 04/10/2026; o mais forte da área), fases 35% / 30% / 35%. Mesma arena dos Malabaristas (dois pedestais pendurados). Tempo-alvo da nota: 2:50.
- **Fase 1 — Abracadabra:** *Leque de Cartas* (ergue a varinha como aviso; 3 leques de 5 direções com um buraco cada; um ás rosa) [desde 04/10: em cada leque uma carta preta, no lugar de uma reta, persegue por 0,8 s (560 px/s, até 120°/s) o jogador da vez: os leques miram P1, P2, P1... pela luta toda, com uma placa "P1"/"P2" sobre o alvo 0,5 s antes; mira só quem está de pé; duas rosas por ataque, na altura do pulo; ver "Marco de gameplay do Mágico" no DESIGN.md], *Coelhos da Cartola* (bate na cartola; 4 coelhos saem pulando na direção de onde cada jogador estava; pular por cima; um rosa), *Teleporte* (estrela piscando onde ele vai aparecer, inclusive em cima de um pedestal; ao chegar solta 8 cartas em círculo; uma rosa).
- **Fase 2 — A Mulher Serrada... sem Mulher:** *Caixas com Serras* (3 caixas descem do teto, uma linha vermelha pisca na altura da serra; no ataque todo as serras vêm na mesma altura: baixa = pular, alta = ficar no chão), *Jogo das Três Caixas* (ele entra numa caixa, elas se embaralham 5 vezes; [desde 04/10: sorteio novo a cada execução, sem troca que desfaz a anterior, a caixa dele se mexe pelo menos 2 vezes; ele faz a reverência no lugar enquanto só a tampa da caixa dele abre, some pela capa, aparece enrolado na frente dessa caixa e afunda nela; na revelação desenrola da capa na caixa certa;] depois, 3,6 s para adivinhar: a certa leva 50% a mais de dano, a errada abre e solta 2 pombas; no fim ele aparece na certa com "Ta-dá!"), **Blackout** (momento de dupla: 7 s no escuro, um holofote em cada jogador, maiores quando estão perto; ele joga leques de cartas e só os olhos dele brilham).
- **Fase 3 — O Grande Final:** cabeça gigante com cartola no alto (a cabeça leva tiro) e duas mãos enormes. *Mãos que Agarram* (cada mão vai para cima de onde um jogador estava, sombra no chão, e desce fechando; sair de baixo ou dash), *Cartola Despejando* (a cartola inclina e despeja tralhas numa faixa que varre o palco; ficar à frente da faixa ou atravessar com dash; uma rosa), *Cartas Gigantes* (as mãos jogam leques de cima para baixo, alternando os lados). [desde 04/10: mãos desenhadas (M7); cada mão segue só a agarrada mais nova, sem pular do chão para o ar com o golpe ligado. Rosto desenhado (M8): ri nas gargalhadas, fica bravo ao levar tiro (no máximo uma vez por segundo) e tonto na derrota; a cartola é peça separada que inclina para despejar.]

---

## Área 2 — A Ilha do Vulcão (proposta do Claude, 07/10/2026, revisar)

O ingresso dourado do Zaratan leva o Trem do Circo à ilha. Ali acontece o **Festival do Fogo**, um espetáculo amaldiçoado como o do circo: cada atração da ilha repete o seu número para sempre. Ordem sugerida: Rei Magma (médio) → Fênix das Cinzas (médio) → Mestre Bigorna (difícil), em qualquer ordem no mapa; o **Coração do Vulcão** abre só depois dos três. A **Mina de Brasa** é a fase de plataforma da área (fica para depois).

Cores: o fundo da ilha tem muita lava, então **os fundos ficam escuros e com a lava apagada**, e os ataques dos chefões são **amarelo-claro no miolo com borda laranja/magenta e contorno escuro grosso**, para não se perderem na lava. Parry continua **turquesa** (`ParryStyle`). Arte pedida em [chatgpt_chefoes_vulcao.md](prompts/chatgpt_chefoes_vulcao.md); até ela chegar, desenhos provisórios por código com as mesmas medidas.

### 4. O Rei Magma

*Um rei baixinho e largo de basalto preto rachado, com lava brilhando nas rachaduras, coroa de lascas de obsidiana quebrada e um manto de lava escorrendo devagar. Foi o engolidor de fogo do festival e é vaidoso: quer reverência.* Arena: margem de basalto de um lago de lava, com o trono no fundo e **duas jangadas de basalto** boiando (plataformas).

**Fase 1 — "Audiência Real"** (40%), sentado no trono:
- **Cuspe Real:** engole uma tocha (bochechas incham, aviso) e cospe 3 bolas de lava em arco; cada uma deixa uma poça no chão por 1 s.
- **Cetro:** bate o cetro no chão; colunas de basalto sobem em sequência pelo chão, da frente dele para longe (uma rachadura brilha 0,5 s antes de cada uma). Pular ou ficar numa jangada.
- **Coroa Bumerangue:** atira a coroa, que vai e volta num arco (uma vez alto, uma vez baixo). Uma gema turquesa da coroa se solta e aceita parry.

**Fase 2 — "O Rei Desce do Trono"** (35%), andando pelo lago com a lava pela cintura:
- **Onda de Lava:** empurra uma onda que cobre o chão inteiro; subir nas jangadas ou pular por cima com dash. Sempre sobra uma jangada livre.
- **Goteira:** bate no peito, e pingos de lava caem do teto da caverna em lugares marcados por sombra; um pingo turquesa.
- **Momento de dupla — Coroa Pesada:** a coroa cai e se crava no chão. Enquanto um jogador fica **encostado nela** (segurando), o rei fica de cabeça descoberta, com a rachadura do alto da cabeça aberta, e leva o **dobro de dano**. Quem segura não atira, mas o rei tenta tomar a coroa de volta: o parceiro precisa protegê-lo atirando nas mãos que se aproximam. Sozinho: a coroa dá a mesma janela por 2 s sem segurar.

**Fase 3 — "Coroação Derretida"** (25%): a casca racha e cai; ele vira **magma puro**, mais alto e magro, com a coroa flutuando em volta da cabeça. *Rajada* (cospe um jato contínuo que varre a tela numa altura, alta ou baixa, avisada pela boca brilhando), *Coroa em Órbita* (a coroa gira em volta dele e sai voando em espiral), *Cuspe Real* mais rápido. A lava do lago sobe um pouco: as jangadas ficam mais importantes.
- Ao vencer: esfria, vira uma estátua de pedra fazendo uma reverência para os jogadores (finalmente ele é quem se curva).
- Vida: 1200. Tempo-alvo: 2:30.

**Como ficou no jogo (07/10/2026, primeira versão, decidido pelo Claude; números a calibrar):** `bosses/magma_king/`, entrada pela porta do Rei Magma no mapa da Área 2. Arte do pedido do Vulcão recortada por `tools/cut_magma_king_art.py` (as folhas vieram fora da grade; cada quadro é ancorado no apoio do desenho).
- Arena: a caverna do pedido, com o chão (beira da margem) em y 1000; duas jangadas de basalto (tampo em y 760, x 620 e 1260) e o trono à direita. Uma faixa da beira da margem é desenhada por cima do rei, para ele afundar no lago (fase 2) e derreter até a altura do jato (fase 3). Na fase 3 o fundo e a beira trocam pela versão "quente".
- **Fase 1:** *Cuspe Real* (3 bolas nos jogadores e espalhadas; poça de 1 s; 50% de chance de uma ser a gema turquesa, sem poça), *Cetro* (colunas a cada 230 px da frente dele para a esquerda, rachadura 0,5 s antes, de pé 0,4 s; 230 px de altura, não chegam nas jangadas), *Coroa Bumerangue* (vai até x 170 e volta; uma perna baixa em y 945, pular; a outra alta em y 812, abaixar; a gema turquesa cai na virada).
- **Fase 2:** no lago ele não machuca quem encosta; cada ataque começa andando 0,8 s até um x sorteado (1180 a 1720). *Onda de Lava* (uma onda de 150 px de altura a 640 px/s; às vezes duas), *Goteira* (7 pingos, metade em cima de quem está de pé, sombra 0,55 s antes; um turquesa), *Coroa Pesada* (janela de 6,5 s com dano em dobro enquanto alguém encosta na coroa; duas mãos se arrastam a 75 px/s e caem com 20 de dano cada, contado como dano da mão e não do rei; se uma chega, ele pega a coroa. Sozinho: sem mãos, dobro por 3 s).
- **Fase 3:** *Rajada* (afunda até a boca ficar em y 860, abaixar, ou 950, pular; linha de aviso piscando 0,8 s; jato de 1,3 s até a parede), *Coroa em Órbita* (1,2 s girando na cabeça, depois espiral que se abre 420 px/s; rente ao chão desliza em y 955), *Cuspe Real* 40% mais rápido com 4 bolas.
- Teste: `tests/test_magma_king.tscn`; também entra no teste de fumaça.

### 5. A Fênix das Cinzas

*Uma ave enorme de fumaça cinzenta e brasa, com penas longas como fitas de trapezista em chamas e uma máscara de baile de porcelana rachada no rosto. Era o número aéreo do festival; dramática, nunca para de se exibir.* Arena: o ninho no alto do pico, com o chão de galhos queimados e **três rochas flutuantes** em alturas diferentes.

**Fase 1 — "Voo de Abertura"** (35%), voando ao fundo e cruzando a tela:
- **Rasante:** um rastro de brasa marca a altura (alta ou baixa) e ela atravessa a tela de um lado ao outro. Duas vezes seguidas, alternando a altura.
- **Leque de Penas:** bate as asas e solta 5 penas de brasa que caem girando, com um buraco; uma pena turquesa.
- **Ventania:** bate as asas de frente; o vento **empurra** os jogadores para a borda (não machuca; cuidado com o que vem junto: brasas rolando pelo chão).

**Fase 2 — "Tempestade de Cinzas"** (35%), pousada no ninho:
- O céu escurece de cinzas (sem apagar a tela: dá para ver os ataques, mas o fundo some).
- **Ovinhos de Brasa:** cospe 3 ovos que caem e chocam pintinhos de brasa que correm pelo chão (atirar ou pular); um ovo turquesa.
- **Chuva de Fagulhas:** fagulhas caem em colunas marcadas no chão; sempre sobra espaço.
- **Rasante** mais baixo, rente às rochas.

**Fase 3 — "Renascimento"** (30%): ela se fecha num **ovo gigante incandescente** no ninho.
- **Anéis de Fogo:** o ovo pulsa e solta anéis que correm pelo chão (pular ou dash).
- **Momento de dupla — Casca Dupla:** o ovo tem uma rachadura brilhante de cada lado. As duas precisam ser quebradas **com até 3 s de diferença**; se uma quebrar sozinha, ela se fecha de novo e o ovo recupera 30% da vida da fase. Sozinho: a outra rachadura quebra junto.
- Ao vencer: o ovo racha e sai um pintinho cinzento que espirra uma nuvenzinha de cinza e foge.
- Vida: 1200. Tempo-alvo: 2:40.

### 6. O Mestre Bigorna

*Um ferreiro gigante de braços enormes e pernas curtas, bigode de pontas enroladas, avental de couro chamuscado e um martelo do tamanho de um barril. Fazia o número de "forjar uma espada em 10 segundos" no festival; impaciente, bufa fumaça pelas orelhas.* Arena: dentro da forja, com a bigorna no meio, **canais de metal derretido** no chão (desligados no começo) e **duas correntes** penduradas do teto (plataformas balançando).

**Fase 1 — "Malhando o Ferro"** (35%), atrás da bigorna:
- **Martelada:** ergue o martelo (aviso) e bate na bigorna; uma onda de choque corre pelo chão para os dois lados (pular) e faíscas saem em arco.
- **Ferraduras:** arremessa 3 ferraduras em brasa que quicam pelo chão; uma turquesa.
- **Fole:** puxa o fole e sopra um leque de brasas na horizontal, na altura da cabeça (abaixar) ou na altura do pulo (ficar no chão).

**Fase 2 — "Forja Aberta"** (35%), andando pela arena:
- **Canal Derretido:** um terço do chão brilha e se enche de metal derretido por 3 s; a parte muda a cada vez.
- **Bigorninhas:** forja e arremessa 4 bigornas pequenas que caem em lugares marcados por sombra.
- **Momento de dupla — Braço de Ferro:** ele agarra um jogador com a mão livre e o ergue (o preso fica sem dano por 3 s). O parceiro precisa acertar a mão 8 vezes para soltar; se não soltar a tempo, o preso perde 1 vida e cai. Com um jogador só de pé, ele não agarra.

**Fase 3 — "Armadura Recém-Forjada"** (30%): veste uma armadura de ferro ainda em brasa e fica enorme e lento.
- **Martelo Giratório:** gira o martelo em volta do corpo e anda; pular por cima do martelo baixo ou passar por baixo do alto.
- **Pisão:** salta e cai, a arena treme, pedras caem do teto (sombras).
- **Peito Aberto:** quando ergue o martelo, a grade do peito abre e mostra a brasa: ali leva o **dobro de dano**.
- Ao vencer: a armadura desmonta peça por peça e ele fica de ceroulas listradas, envergonhado, tapando-se com o avental.
- Vida: 1400. Tempo-alvo: 2:50.

### 7. O Coração do Vulcão (fecha a área)

*O coração da ilha: um enorme coração de magma batendo, preso por correntes no fundo da cratera, com uma máscara de teatro de pedra crescida na frente (o rosto). É a atração principal do Festival do Fogo; as três atrações vencidas eram os seus selos.* Arena: o fundo da cratera, chão de basalto, o coração pendurado no alto do fundo. A máscara leva tiro.

**Fase 1 — "Batimento"** (35%):
- **Pulsação:** cada batida manda um anel de choque pelo chão (pular). O ritmo acelera aos poucos e volta ao normal; a máscara pisca antes de cada batida.
- **Artérias:** tubos de lava no teto se enchem (incham e brilham) e esguicham jatos na vertical em lugares marcados.
- **Gotas Turquesa:** de vez em quando uma gota turquesa escapa de uma artéria (parry).

**Fase 2 — "Os Três Selos"** (35%): os três selos da porta brilham e o coração usa **ecos** dos chefões vencidos (as mesmas formas, só que em fogo fantasma): a Coroa Bumerangue do Rei, o Leque de Penas da Fênix e as Ferraduras do Bigorna, um de cada vez, mais rápidos que os originais.
- **Momento de dupla — Válvulas:** duas válvulas de pressão, uma em cada ponta da arena. Os dois jogadores ficam em cima delas **ao mesmo tempo** (com 1 s de tolerância) por 1 s; a máscara se abre por 5 s e o coração leva o **dobro de dano**. Sozinho: uma válvula só abre a máscara por 3 s.

**Fase 3 — "Erupção"** (30%): as correntes arrebentam e o coração voa pela cratera. A lava sobe e o chão vira **plataformas de basalto que sobem e descem** com a pulsação; cair na lava tira 1 vida e o jogador volta na plataforma mais próxima.
- **Cuspe de Magma:** bolas de magma em leque.
- **Investida:** o coração recua, a máscara aperta os olhos e ele atravessa a tela.
- Ao vencer: esfria e vira um coração de pedra que cai na lava. A porta da cratera se abre e mostra o caminho para a Área 3 (gancho da história).
- Vida: 1500. Tempo-alvo: 3:00.

## Ideias para áreas futuras

- **O Homem-Forte** (halteres que tremem a arena), **Os Trapezistas** (luta toda no ar, em trapézios), **O Homem-Bala** (canhões e bombas), **O Engolidor de Espadas**, **A Elefanta Dona Bebel**.
- **Chefão final do jogo: O Mestre de Cerimônias** — o dono do circo, quem fez o pacto que amaldiçoou tudo. Abre a luta gritando **"Respeitável público!"**.
