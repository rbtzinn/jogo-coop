# Fila de animações para o Codex (Área 1)

Criada em 02/10/2026. O usuário pediu o jogo bem animado até segunda, 05/10, às 09h. O Codex gera
os PNGs; o Claude faz o inventário, escreve os pedidos, recorta, integra e valida no Godot.
**Uma folha por pedido.** Mandar o próximo só depois de o Claude conferir o anterior.
Prazo é prioridade, não garantia: a fila vai até onde der.

## O que já existe (não pedir de novo)

| Arte pronta | Arquivo | Onde está no jogo |
|---|---|---|
| Corrida do palhaço (8 quadros) | `docs/referencias/pecas/palhaco_corrida.png` | `core/player/characters/clown/run/` |
| Corrida da acrobata (8 quadros) | `docs/referencias/pecas/acrobata_corrida.png` | `core/player/characters/acrobat/run/` |
| Peças do palhaço e da acrobata (cabeça, piscar, tronco, sapato, luvas) | `palhaco_folha.png`, `acrobata_folha.png`, `acrobata_tronco.png`, `luva_pistola.png` | peças do `CharacterRig` |
| Leopoldo: folha base, parado, rugido, galope, pulo (4) | `docs/referencias/pecas/leao/` | `bosses/tamer/art/lion/` |
| Tronco novo da acrobata (v2, ainda não usado) | `docs/referencias/acrobata_tronco_v2.png` | não integrado; não mexer |

Todo o resto que aparece em movimento hoje é animado por código: parado, pulo, dash,
abaixado, dano, parry (um desenho girando 360°, de que o usuário não gostou), o balão, os
especiais, o Domador (SVG parado), os Malabaristas, o Mágico, o trem e o mapa.

## Regras comuns (vão dentro de cada pedido)

- **Estilo:** cartum de borracha dos anos 30 desenhado a nanquim (tipo Cuphead), contorno marrom-escuro grosso `#1b1410`, sombra pintada quente, leve textura de impressão gasta. Mesmo traço das referências citadas.
- **Identidade:** o personagem é idêntico em todos os quadros, com as mesmas cores, proporções e detalhes das referências. Só mudam a pose e a cara.
- **Expressão:** cada quadro tem uma expressão diferente e exagerada.
- **Grade:** células iguais, um quadro por célula, lidas da esquerda para a direita e de cima para baixo. Nada cruza para outra célula. Sem linhas de grade, sem texto, sem sombra no chão, sem borrão de movimento e sem linhas de velocidade.
- **Alpha:** fundo totalmente TRANSPARENTE (alpha real, não preto nem xadrez), com borda limpa e sem halo.
- **Jogadores:** vista de lado olhando para a DIREITA. **Sem o braço da frente (o braço da arma):** o jogo desenha esse braço e a pistola por cima, presos ao ombro. Só aparece o braço de trás, sempre ATRÁS do corpo. Exceções que vêm sem pistola nenhuma: parry, balão e especiais.
- **Escala dos jogadores:** a mesma das folhas de corrida. O palhaço mede uns 406 px da sola ao topo da cartola em `palhaco_corrida.png`; a acrobata, uns 465 px em `acrobata_corrida.png`. Células de 512 × 512.
- **Linha do chão (quadros no chão):** sola dos sapatos em y = 486 da célula, com o corpo centrado por volta de x = 290 (palhaço) ou x = 313 (acrobata), como nas corridas.
- **Quadros no ar:** a barriga (meio do corpo) no mesmo ponto em todas as células, x = 256 e y = 280.
- **Chefões:** olhando para a ESQUERDA (como o leão), com as patas ou os pés na mesma linha do chão em todos os quadros. Os tamanhos estão em cada pedido.
- **Base das folhas dos jogadores (regra do usuário):** sempre 2048 × 1024, grade 4 × 2 de células de 512. Folha com menos de 8 quadros deixa as células que sobram totalmente transparentes. Um balão de 16 quadros vira duas folhas de 8.
- **Parado:** olhos abertos em todos os quadros (o piscar é uma peça separada do jogo).
- **Tamanho que volta do Codex:** o gerador às vezes devolve outro tamanho (o A1 veio 1774 × 887). O Claude normaliza com `tools/regrid_sheet.gd`: amplia por igual, sem distorcer nem mexer no alpha, e recoloca cada quadro na sua célula (no ar, o meio em (256, 280); no chão, a sola em 486). O original do Codex fica guardado em `docs/referencias/pecas/originais/`.

## Fila (ordem de prioridade)

Prioridade = o que mais aparece na tela e o que o usuário já reclamou.


### Bloco W: mundo 3D da aventura (03/10/2026, prioridade sobre o resto da fila)

**Atualização de 03/10, à noite: as folhas W1–W8 estão SUSPENSAS.** O usuário viu o piloto e rejeitou os
personagens desenhados no mapa ("horríveis"). Eles agora são miniaturas 3D modeladas no Godot
(`core/world/miniature.gd`), que giram de verdade e andam em qualquer direção.

**Não pedir ao Codex folhas de andar em direções.**

**O que ainda serve do Codex para o mundo:**
- **Referência visual do diorama e da identidade 3D** (já em produção pelo Codex). É um alvo de
  linguagem visual, não uma captura do jogo.
- **Texturas que repetem** (1024 × 1024, contínuas nas bordas, sem sombra nem luz pintada):
  - madeira das tábuas;
  - terra batida com palha;
  - lona listrada envelhecida;
  - madeira pintada de carroção.
- **Placas pintadas** com o nome de cada atração, em letra de circo dos anos 30, com fundo transparente.
  Hoje as placas são texto do Godot.

Só pedir quando o cenário de formas estiver aprovado. Os pedidos W1 abaixo ficam só como histórico.

**Referência recebida (03/10):** `docs/referencias/mundo3d_direcao_visual.png` (1774 × 887, conceito do
Codex). É o alvo de linguagem visual, com a ressalva de que a câmera do jogo é mais alta e as proporções
são as aprovadas. Ela guiou a segunda rodada do M0 visual (diário: "M0 visual, segunda rodada").

**Texturas do chão: T1 (terra) e T2 (grama) já estão no jogo (03/10, noite). Nenhum pedido de imagem do MUNDO está aberto (o M0 espera a avaliação humana). O trabalho aberto agora é de luta (M1): o parado (E2 + E2b), o arremesso (E3) e o tonto (E4) dos Malabaristas estão no jogo; o salto mortal (E5) também está no jogo, com as entradas pilotadas; a derrota (E6) também está no jogo. Mágico: a M1 (folha base) foi aprovada tecnicamente e a M2 (parado) está no jogo. A M3 e a M3b (varinha: feitiço e lançamento) estão no jogo. A M4 (batendo na cartola) está no jogo, conferida nos Coelhos. A M5 (sumir) e a M6 (reverência e medo) também estão no jogo. O marco de gameplay do Mágico (cartas pretas que perseguem, alvos P1/P2, rosas, embaralhar) também está feito; a revisão finita dele (parry nos dois e pela rede, saída real, Três Caixas sem deslize) também. A M7 (mãos gigantes) e a M8 (rosto gigante) estão no jogo: o Mágico está todo desenhado. A E7 (o totem dos Malabaristas, irmãos menores por decisão do usuário) está no jogo, pilotada com as duas bases. A E8 (os Malabaristas no monociclo) fica pronta na fila, em espera: a prioridade humana de 04/10 é o piloto 3D. Pedido de imagem aberto: o P3D1 (folha de modelagem do palhaço em 4 vistas). O piloto por peças do tonto não é viável (nos extremos do pêndulo a cabeça tapa a gola, que não existe por baixo); a E4b continua como defeito conhecido. O meio do pêndulo do tonto foi recusado em três formatos (E4c, E4d e E4e) e o caminho de imagem para ele está encerrado neste ciclo; o tonto segue com a E4b, um defeito conhecido. A avaliação humana é para a aprovação final e não trava o trabalho delegado.**
Depois dele vem o T2, a grama. As outras texturas (tábuas, lona, madeira de carroção) e as placas pintadas
ficam para depois, se o visual aprovado pedir.

**Como o mundo funcionava no piloto** (histórico: hoje a câmera é de 42° e os personagens são miniaturas 3D) (`levels/world/world_area1.tscn`):
- O cenário é 3D. A câmera fica alta e oblíqua, sempre do mesmo ângulo: vê o chão de cima e de frente,
  inclinada 48° para baixo, sem girar.
- Os personagens são desenhos 2D virados para a câmera.
- Hoje eles usam a corrida de lado e o parado da luta como provisório. Isso não serve para andar para
  cima e para baixo: andando para o fundo, o desenho continua de lado.

**Direções:** com a câmera fixa, bastam 3 direções desenhadas, e as outras saem espelhando.

| Folha | Andando para | Também usada para |
|---|---|---|
| "frente" | a câmera, na diagonal para baixo e à direita (de três quartos, de frente) | baixo (S) e a outra diagonal, espelhada |
| "costas" | o fundo, na diagonal para cima e à direita (de três quartos, de costas) | cima (N) e a outra diagonal, espelhada |
| "lado" | a direita, vista de cima de lado | a esquerda, espelhada |

**Pernas:** como na corrida, a perna do lado de lá é um pouco mais escura.

**Ordem, uma folha por vez, cada uma conferida em movimento antes da próxima:**
1. W1, palhaço andando de frente.
2. W2, palhaço de costas.
3. W3, palhaço de lado.
4. W4, palhaço parado nas 3 direções.
5. W5–W8, a acrobata, nas mesmas quatro folhas.
6. W9 em diante, peças do cenário (abaixo).

**Medidas comuns às folhas W1–W8** (as folhas são novas e não precisam bater com o tamanho das folhas
da luta, mas a cabeça e as proporções são as mesmas):
- Canvas de 2048 × 1024, 4 × 2 células de 512.
- O ponto onde os pés tocam o chão (o meio entre os dois pés, no chão) fica em x 256, y 470 de cada
  célula, em todos os quadros. É o pivô do personagem no mundo.
- Altura em pé: palhaço uns 330 px (da sola ao topo do chapéu), acrobata uns 360 px (da sola ao topo
  do coque). A acrobata é mais alta que o palhaço, como na luta.
- Visto um pouco de cima: o topo da cabeça e dos ombros aparece um pouco, e os pés ficam um pouco mais
  curtos (a câmera olha de cima).

| | | | | |
|---|---|---|---|---|
| W1 | `docs/referencias/pecas/mundo/palhaco_andar_frente.png` | `palhaco_corrida.png`, `palhaco_parado.png`, `palhaco_folha.png` | 2048 × 1024, 4 × 2 de 512 | 8: **pedido pronto** (abaixo) |
| W2 | `.../mundo/palhaco_andar_costas.png` | idem + W1 aprovada | idem | 8 (o mesmo pedido, trocando a direção) |
| W3 | `.../mundo/palhaco_andar_lado.png` | idem | idem | 8 |
| W4 | `.../mundo/palhaco_parado_mundo.png` | idem | 2048 × 1536, 4 × 3 de 512 | 4 por direção (linhas: frente, costas, lado) |
| W5–W8 | as mesmas da acrobata | `acrobata_corrida.png`, `acrobata_parado.png` | idem | idem |
| W9 | `.../mundo/placas_tendas.png` | `chefao_domador.png` e as folhas base | 2048 × 1024 | placas pintadas de cada tenda (nome do número), fundo transparente |
| W10 | `.../mundo/texturas_chao.png` | `direcao_arena.png` | 1024 × 1024 cada, contínuas | terra com palha, tábuas do caminho, lona listrada |

## Pedido T1: textura de terra batida (pronto para colar; decidido por delegação em 03/10, à noite)

Primeiro pedido de textura do chão do mundo 3D. Depois de T1 conferida e integrada vem T2, a grama
(abaixo). Uma imagem por pedido.

**Arquivo:** `docs/referencias/texturas/terra_batida_candidata.png`
- É a candidata, irmã das referências desta pasta.
- O Claude confere. Se aprovar, copia para `terra_batida.png` e integra. A candidata fica guardada como
  original.

**Formato:**
- 1024 × 1024 px, quadrada.
- RGB opaco, sem transparência (sem canal alpha, ou alpha 255 em tudo).
- Contínua nas quatro bordas: repetida lado a lado e em cima e embaixo, não pode aparecer emenda. O teste
  do Claude desloca a imagem 512 px nos dois eixos e procura linha ou degrau no meio.

**Escala e orientação no jogo:**
- Uma repetição cobre 4 m × 4 m do chão (no jogo, UV = posição em metros × 0,25). São 256 px por metro,
  ou seja, 2,56 px por centímetro.
- Vista de cima, reta, sem perspectiva: como uma foto tirada de pé, olhando para o chão.
- O topo da imagem é o fundo do mapa e a direita é o leste, mas a textura não pode ter direção
  dominante: nada de riscos, sulcos ou rastros todos no mesmo sentido. A trilha faz curvas, e uma
  direção marcada iria aparecer torta.
- Nada que chame atenção sozinho (uma pedra grande, uma mancha forte). Com a repetição a cada 4 m, isso
  vira um carimbo. As manchas grandes, de 1 a 4 m, já são feitas pelo jogo; a textura só traz o detalhe
  pequeno, espalhado por igual.

**Conteúdo e tamanho dos detalhes:**

| Detalhe | Tamanho real | Na imagem | Quantidade |
|---|---|---|---|
| Base de terra batida, pintada em pinceladas largas e suaves | — | — | o fundo todo |
| Pedrinhas arredondadas | 2 a 6 cm | 5 a 15 px | umas 60 a 90 na imagem, em grupinhos de 2 a 5 e soltas, com vazios entre os grupos |
| Pedriscos (grãos) | 0,5 a 1 cm | 1 a 3 px | salpicados, bem fracos |
| Fiapos de palha seca | 3 a 8 cm de comprimento, 1 cm de largura | 8 a 20 px × 2 a 3 px | uns 25 a 40, em ângulos variados |
| Marcas de pegada ou de sapato, apagadas | 10 a 25 cm | 26 a 64 px | 3 a 5, quase invisíveis, viradas para lados diferentes |
| Rachadinhas da terra seca | 5 a 15 cm | 13 a 38 px | poucas, finas, curvas |

**Paleta** (sRGB; a média da imagem toda deve ficar perto da base, dentro de uns 5%, porque o jogo
tinge a textura pela cor do lugar):
- base da terra `#8a6440`, variando entre `#7a5a3a` e `#9a7450`;
- terra gasta, mais escura, em manchas pequenas: `#5a4630`;
- pedrinhas: cinza-violeta `#6a6470` e bege claro `#b8a888`, com contorno fino `#4a3828`;
- palha: `#c9a24a` a `#a8843a`;
- marcas de pegada: a base só uns 6% mais escura.
- Contraste baixo: 90% dos pixels a até uns 12% da luminosidade média. A cena é noturna e a luz vem do
  jogo.

**Estilo:**
- Pintado à mão, como o chão da referência: pinceladas visíveis, áreas de cor chapada e bordas macias.
- Nada de foto, de ruído de câmera ou de granulado fino abaixo de 2 px.

**Sem luz nem sombra pintadas (obrigatório):**
- As pedrinhas não têm lado claro e lado escuro, nem brilho, nem sombra projetada. São só a cor delas,
  com o contorno fino.
- Sem oclusão de ambiente nos cantos, sem vinheta e sem gradiente de luz atravessando a imagem.
- A luz da lua, das lanternas e as sombras são do jogo.

**Referências:**
- `docs/referencias/mundo3d_direcao_visual.png`: o chão de terra das trilhas, em primeiro plano. É o
  alvo de linguagem.
- `docs/referencias/texturas/chao_atual_jogo.png` e `chao_atual_jogo_domador.png`: o chão de hoje no
  jogo, só cor do vértice e manchas por código. Mostram a escala dos personagens (o palhaço mede uns
  0,9 m) e as cores do lugar.

**Como o Claude confere e integra:**
1. Confere tamanho, RGB sem alpha, emenda (deslocamento de 512 px), média de cor e detalhes sem luz.
2. No `shaders/world_ground.gdshader`, a terra passa a vir da textura (UV em metros × 0,25, repetindo),
   tingida pela cor do vértice da trilha e com as manchas de hoje por cima. A borda gasta mistura a
   terra com a grama.
3. Confere com a câmera do jogo, de perto e de longe, procurando carimbo de repetição.
4. Em movimento real: a dupla andando no trecho portão → Domador → loja, com o `-- mundo`.

### Resultado do T1 (03/10, noite): aprovada e no jogo

**Entrega:** `terra_batida_candidata.png`, gerada pelo Codex. A candidata fica intacta, e o original do
Codex está guardado por ele.

**Medidas do Claude** (`scratchpad/t1/check.gd`):
- **Tamanho:** veio 1254 × 1254, não 1024. Foi reduzida por igual para 1024 (Lanczos), sem cortar.
- **Formato:** RGB opaco.
- **Média de cor:** 140,15 / 104,91 / 70,96, contra o alvo 138 / 100 / 64 (+1,6%, +4,9%, +10,9%). O azul
  ficou fora da tolerância.
  - **Correção:** um ganho único por canal (0,985 / 0,953 / 0,902), aplicado na imagem inteira. É
    tecnicamente adequado porque o jogo usa a textura dividida pela própria média: só o detalhe conta,
    e a cor vem do lugar.
  - **Depois:** 137,15 / 99,60 / 63,54 (−0,6%, −0,4%, −0,7%), sem pixel saturado.
- **Luminância:** 94,5% dos pixels a até 12% da média, antes e depois.
- **Emenda:** a diferença média na borda é de 4,15 da esquerda para a direita (2,13 entre vizinhos
  internos) e 3,43 de cima para baixo (2,60). Com a imagem deslocada 512 px, não se vê linha nem degrau.
  No mosaico 3 × 3, que equivale a 12 m de chão, não aparece carimbo; as pegadas só se notam
  procurando.
- **Luz pintada:** as pedrinhas têm um bisel fraco, com o miolo mais claro e a borda de baixo mais
  escura. No jogo a pedrinha ocupa de 1 a 4 px, e o bisel não aparece.
  - Não pedi correção. Fica anotado para a T2: as folhinhas não podem ter lado claro.

**No jogo:**
- O arquivo é `core/world/art/dirt_albedo.png`, com mipmaps, sem compressão e filtro anisotrópico.
- No `shaders/world_ground.gdshader`, a textura é amostrada com UV = xz × 0,25, dividida pela média e
  multiplicada pela cor do vértice onde é terra. As manchas grandes por cima escondem a repetição.
  - O pedrisco procedural da terra saiu, porque a textura já traz o dela.

**Conferência:**
- **Fotos:** `-- chao`, a tela inteira no portão, no Domador e na loja.
- **Movimento:** `-- mundo` (portão → Domador → loja → Malabaristas, com a dupla andando) e
  `-- caminhada`. O CSV da caminhada saiu idêntico ao da terceira rodada.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Guardados em `docs/referencias/texturas/`:**
- `terra_batida.png`: a versão de 1024 com a paleta corrigida, a que está no jogo;
- `terra_batida_mosaico_12m.png`;
- `terra_batida_no_jogo.png`.

## Pedido T2: textura de grama baixa (pronto para colar; T1 já integrada)

**Arquivo:** `docs/referencias/texturas/grama_baixa_candidata.png`
- É a candidata, irmã de `terra_batida.png`.
- O Claude confere. Se aprovar, normaliza e integra. A candidata fica guardada como original.

**Formato:**
- 1024 × 1024 px, quadrada. A T1 veio com 1254: se vier de outro tamanho, o Claude reduz por igual, mas
  1024 é o pedido.
- RGB opaco, sem transparência.
- Contínua nas quatro bordas. O teste do Claude desloca a imagem 512 px nos dois eixos e procura linha
  ou degrau.

**Escala e orientação no jogo:**
- Uma repetição cobre 4 m × 4 m (UV = posição em metros × 0,25), ou seja, 256 px por metro.
- Vista de cima, reta, sem perspectiva.
- Sem direção dominante: as folhinhas apontam para todos os lados, sem "pentear" a grama.
- Nada que chame atenção sozinho (uma moita grande, uma falha grande), para a repetição a cada 4 m não
  virar carimbo. As manchas grandes, de 1 a 4 m, já são do jogo.
- Os tufos 3D de capim continuam por cima. A textura é só o tapete baixo.

**Conteúdo e tamanho dos detalhes:**

| Detalhe | Tamanho real | Na imagem | Quantidade |
|---|---|---|---|
| Base de grama baixa e gasta, em pinceladas curtas | — | — | o fundo todo |
| Folhinhas pintadas, em tufos pequenos | 2 a 6 cm | 5 a 15 px | muitas, cobrindo a base sem esconder a cor |
| Falhas de terra aparecendo | 5 a 20 cm | 13 a 51 px | 6 a 10, de formas diferentes |
| Folhinhas secas | 2 a 5 cm | 5 a 13 px | poucas, salpicadas |
| Trevinhos ou folhas redondas | 2 a 3 cm | 5 a 8 px | poucos |

Nenhuma flor colorida, pedra ou objeto.

**Paleta** (sRGB; a média da imagem toda deve ficar perto da base, dentro de uns 5% por canal):
- base `#42452a` (66, 69, 42), variando entre `#3a4128` e `#4a4a2a`;
- variação mais escura, em manchinhas e não como sombra: `#2e3420`;
- falhas de terra: `#5a4630`;
- folhinhas secas: `#5a5a34`;
- contraste baixo: 90% dos pixels a até uns 12% da luminosidade média.

**Estilo:**
- Pintado à mão, como a terra T1 e a referência: pinceladas visíveis, áreas chapadas e bordas macias.
- Nada de foto nem de granulado fino abaixo de 2 px.

**Sem luz nem sombra pintadas (obrigatório):**
- As folhinhas não têm lado claro e lado escuro, nem brilho na ponta, nem sombra embaixo.
- Na T1 as pedrinhas vieram com um bisel fraco. Aqui, nada disso.
- Sem oclusão nos cantos, sem vinheta e sem gradiente.

**Referências:**
- `docs/referencias/mundo3d_direcao_visual.png`: a grama em volta das trilhas, como alvo de linguagem.
- `docs/referencias/texturas/terra_batida.png`: o mesmo traço e a mesma escala de pincel. As duas vão
  ficar lado a lado na borda das trilhas.
- `docs/referencias/texturas/terra_batida_no_jogo.png`: o jogo hoje, com a terra pronta e a grama ainda
  lisa, com a escala dos personagens.

**Como o Claude confere e integra:**
1. Confere como na T1: tamanho, alpha, emenda, média, luminância e luz pintada.
2. No `world_ground.gdshader`, entra como `grass_albedo`, dividida pela média `#42452a` e multiplicada
   pela cor do vértice onde é grama, no lugar dos pontinhos procedurais.
3. Confere com `-- chao`, `-- mundo` e `-- entradas`, e roda a bateria.

### Resultado do T2 (03/10, noite): no jogo, com a cor do detalhe reduzida

**Entrega:** `grama_baixa_candidata.png`, gerada pelo Codex. A candidata fica intacta, e o original do
Codex está guardado por ele.

**Medidas do Claude** (`scratchpad/t2/check.gd`):
- **Tamanho:** veio 1254 × 1254. Foi reduzida por igual para 1024 (Lanczos).
- **Formato:** RGB opaco.
- **Média de cor:** 74,95 / 72,08 / 38,81, contra o alvo 66 / 69 / 42 (+13,6%, +4,5%, −7,6%).
  - **Correção:** ganho único por canal (0,881 / 0,957 / 1,082), pelo mesmo motivo da T1: o jogo usa só o
    detalhe e tira a cor do lugar.
  - **Depois:** 65,59 / 68,51 / 41,56, sem pixel saturado.
- **Luminância:** 86,6% dos pixels a até 12% da média; o pedido era 90%.
- **Emenda:** diferença média de 3,95 da esquerda para a direita (1,66 entre vizinhos internos) e 2,59 de
  cima para baixo (1,30). Com a imagem deslocada 512 px não se vê emenda. No mosaico de 12 m não aparece
  grade; as manchas de terra formam um salpicado regular, mas sem carimbo.

**Defeitos que vieram:**
1. **Bases escuras dos tufos:** cada tufo tem uma cunha escura embaixo e para o mesmo lado. É sombra
   estrutural e não se corrige com ganho. No jogo o tufo ocupa de 3 a 8 px e a cunha quase não aparece,
   então não recusei por isso (comparação ampliada 2× em `grama_baixa_antes_depois_jogo.png`).
2. **Falhas de terra avermelhadas:** saíram em vez de `#5a4630`. Tingidas pela grama, viravam manchas
   vermelhas ou magenta no jogo, e isso estava errado.
   - **Correção na integração, sem mexer na arte:** o shader usa o claro e escuro da textura inteiro, mas
     só 30% da cor dela. As falhas viraram manchas mais escuras e neutras, e os tufos continuam legíveis.
   - Comparação de cor cheia contra 30% em `grama_baixa_cor_cheia_vs_30.png`.

**No jogo:**
- O arquivo é `core/world/art/grass_albedo.png`, com mipmaps, sem compressão e filtro anisotrópico.
- No `world_ground.gdshader`, a textura é dividida pela média `#42452a`, com 30% de cor, e multiplicada
  pela cor do vértice onde é grama. Ela substituiu os pontinhos procedurais.

**Conferência:**
- **Fotos:** `-- chao`, `-- entradas` e `-- mundo` (com a dupla andando portão → Domador → loja →
  Malabaristas).
- **Movimento:** a caminhada saiu idêntica (`docs/medidas/caminhada/5_t2_resumo.txt`).
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Guardados em `docs/referencias/texturas/`:**
- `grama_baixa.png`: a versão de 1024 com a paleta corrigida, a que está no jogo;
- `grama_baixa_mosaico_12m.png`;
- `grama_baixa_no_jogo.png`;
- as duas comparações citadas acima.

**Correção focal T2b:** não é necessária agora. Se a avaliação humana pedir as falhas de terra com cor
própria ou se as bases dos tufos aparecerem, o pedido seria só isto:
- folhinhas sem a cunha escura embaixo, com o contorno igual em volta;
- falhas de terra em `#5a4630`, entre `#4e3e2a` e `#66503a`, sem vermelho;
- o resto igual.

### Resultado da E1 (03/10, noite): folha base dos Malabaristas aprovada tecnicamente

A E1 é o Pedido 1 de `codex_malabaristas.md`: a folha base. Não é animação pronta, e nada dela entra no
jogo como está.
- **Candidata:** `malabaristas_folha_candidata.png`, intacta.
- **Original guardado:** `originais/malabaristas_folha_codex_1774x887.png`.

**Identidade, conferida contra o pedido e as folhas dos jogadores:**
- **Os gêmeos são o mesmo desenho:** as medidas na candidata batem quase ao pixel.
  - nariz de bola de 44 × 28 nos dois corpos;
  - branco do olho de 42 × 64 e 42 × 66;
  - a mesma altura do cabelo à sola: 494 px no Tico;
  - o mesmo cabelo, bigode, luvas brancas, sapatos marrons e creme com botão dourado, e gola de babado.
- **O que muda entre eles:** só a cor da malha (Tico vermelho e creme, Teco azul e creme) e os objetos
  (Tico com bolas, Teco com claves).
- **As 6 cabeças** (sorrindo, gritando, tonto com espiral e estrelas) têm o mesmo tamanho de rosto do
  corpo.
- **Traço:** igual ao dos jogadores, com nanquim grosso, cor pintada e textura de impressão.
- **Direção:** os dois olham para a DIREITA, de três quartos, como o pedido manda. No jogo, o desenho é
  espelhado conforme o lado (`facing`).
- **Conceito:** o `chefao_malabaristas.png` mostra arlequins altos. O Pedido 1 os redefiniu como gêmeos
  baixos de bigode, e vale o pedido. O conceito não é referência de aparência.

**Desvios e o que foi feito:**

| Desvio | Medida | Decisão |
|---|---|---|
| Tamanho 1774 × 887 | — | normal do gerador |
| Clave de cima do Teco quase no topo | margem de 4 px (base 10 px) | normalizada com margem, abaixo |
| Trilhas de movimento desenhadas junto às bolas e claves | traços soltos, que não encostam nos objetos | ficam na folha base como referência; **não entram no jogo** e são proibidas nas folhas de animação |
| 5,8% dos pixels semitransparentes | bordas e trilhas | normal |

- **Normalizada:** `malabaristas_folha.png`, em 2048 × 1024, com escala única de 1,1003 (Lanczos),
  centrada e sem cortar. As margens ficaram em 27 px em cima e 35 embaixo. O desenho não mudou.

**Escala de combate** (decidido por delegação):
- O irmão fica com uns 230 px do cabelo à sola no jogo. É a altura do desenho por código de hoje, então
  as caixas de dano (90 × 170), a mão que joga (−150) e a cabeça (−180) não mudam.
- Fica entre o palhaço (198) e a acrobata (268), e abaixo do Domador (260): "baixos e atarracados".
- Na folha de animação, o irmão é desenhado com 430 px em células de 512, a sola em y 486; no jogo, ×
  0,535.

**Teco sem desenho próprio** (decidido por delegação, testado):
- As folhas de animação desenham só o Tico. O Teco sai de `tools/recolor_twin.gd`, que troca só as
  manchas vermelhas das listras pelo azul do Teco e mantém o claro e escuro.
  - Cada mancha é julgada pela mediana dela: listra com S < 0,93 e V entre 0,5 e 0,8.
  - O nariz e a língua (S ~0,97, V ~0,87) e os sapatos (V < 0,45) ficam como estão.
  - Pele, luvas e nariz não mudam de cor.
- **Teste na folha base:** o Tico recolorido bate com o Teco desenhado pelo Codex
  (`malabaristas/teste_teco_por_recolor.png`).
- **Objetos:** a bola do Tico e a clave do Teco serão recortadas da folha base, sem as trilhas, e
  desenhadas pelo jogo nas mãos.
  - As folhas de animação vêm **sem objetos**.
  - Assim não há bola desenhada na folha e outra objeto de ataque ao mesmo tempo.
  - Os ataques continuam com os objetos deles (`juggler_prop.gd`).

## Pedido E2: Tico parado malabarizando (entregue em 03/10; recusado como pedido e aproveitado como "chuveiro", ver "Resultado da E2")

**Uso no jogo:**
- A pose `idle` do `Juggler` (`bosses/jugglers/juggler.gd`): os dois irmãos parados nas fases 1 e 2,
  entre os ataques.
- O Teco usa a mesma folha recolorida.
- Depois, se servir, também o de cima do totem e o do monociclo (`sit`, `ride`).
- O jogo desenha por cima os 3 objetos girando de mão em mão: bolas para o Tico, claves para o Teco.

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_malabares_candidata.png`. É a candidata, irmã da
folha base. O Claude confere, normaliza e só então integra.

**Medidas no desenho** (tiradas da folha base normalizada, × 0,79):

| Parte | Na folha base normalizada | Na E2 |
|---|---|---|
| Altura do cabelo à sola | 543 px | **430 px** |
| Cabeça (cabelo ao queixo) | 220 px | 174 px |
| Nariz de bola | 48 × 31 | 38 × 24 |
| Branco do olho | 46 × 70 | 37 × 56 |
| Luva aberta | ~106 × 90 | ~84 × 71 |
| Sapato | ~187 de comprimento | ~148 |

**Grade e pivôs:**
- 2048 × 1024, 4 × 2 células de 512, lidas da esquerda para a direita e de cima para baixo.
- Sola dos dois sapatos em y 486 em todos os quadros: os pés ficam plantados e o corpo quica nos joelhos.
- Corpo centrado em x 256.
- Margem de 24 px em volta de tudo dentro da célula.
- Se vier em 1774 × 887, todas as medidas valem × 0,866 e o Claude amplia por igual.

**Ciclo:** 8 quadros a 12 por segundo, num loop de 0,67 s. Cada mão joga uma vez por loop:

| Quadro | Mãos | Corpo | Cara |
|---|---|---|---|
| 1 | direita baixa, em concha (pega); esquerda no meio | joelhos dobrados, embaixo | sorriso convencido |
| 2 | direita sobe jogando | subindo | piscada |
| 3 | direita no alto, palma para cima, dedos abertos (solta); esquerda baixa, pronta | quase no alto | língua de fora, concentrado |
| 4 | as duas no meio | no alto | sorriso orgulhoso |
| 5 | esquerda baixa, em concha (pega); direita no meio | joelhos dobrando | sobrancelhas mexendo |
| 6 | esquerda sobe jogando | subindo | assobiando |
| 7 | esquerda no alto, solta; direita baixa, pronta | quase no alto | gargalhada |
| 8 | as duas no meio | voltando | sorriso de lado |

- Mãos na altura do peito e dos ombros: entre y 250 (alto, no queixo) e y 360 (baixo, na cintura).
- Mão esquerda entre x 110 e 210; direita entre x 300 e 400.
- Palmas visíveis, porque o jogo põe o objeto uns 20 px acima do meio da palma.
- O quique do corpo é de uns 8 px para cima e para baixo; os pés não saem do lugar.

**Plano de conferência em movimento** (antes de integrar):
1. Normalizar com `regrid_sheet.gd` (`chao`, sola em 486) e medir em cada quadro:
   - sola a até 2 px de 486;
   - altura do cabelo à sola, a até 3% de 430;
   - nariz, a até 10% de 38 × 24;
   - nenhum objeto, trilha, sombra ou estrela.
2. Teco: rodar `recolor_twin.gd` e conferir que as listras ficaram azuis e que o nariz, a língua, a pele
   e as luvas não mudaram (comparar a contagem de vermelho vivo antes e depois).
3. Recortar a bola e a clave da folha base, sem trilhas, e ligar a folha no `Juggler` (pose `idle`), com
   os objetos indo da palma que solta (quadros 3 e 7) para a que pega (1 e 5).
4. Capturar a 60 quadros por segundo, num modo novo das fotos (`-- malabaristas_parado`), os dois irmãos
   parados na arena ao lado dos dois jogadores. Conferir:
   - a escala contra o palhaço (198) e a acrobata (268);
   - os pés parados;
   - o objeto saindo e chegando na palma, a até 12 px;
   - o espelhamento do lado direito.
5. Rodar a bateria. Os ataques não mudam.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_malabares_candidata.png (replace if it exists).

Reference (read from the project): docs/referencias/pecas/malabaristas/malabaristas_folha.png = the APPROVED design sheet of the twin jugglers. Draw ONLY TICO, the brother with RED and cream stripes (left half of that sheet), EXACTLY the same character: round head, slicked black hair, big curly black mustache, big glossy red ball nose, big eyes, cream ruffle collar, striped one-piece leotard with gold buttons, white gloves, big brown-and-cream shoes with a gold button, same colors, same proportions, same ink style. Same 3/4 view FACING RIGHT as in that sheet. Do NOT use docs/referencias/chefao_malabaristas.png (old concept, different look).

KEEP THE COLORS OF THE DESIGN SHEET EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, and each is fully closed by the dark outline. Do not change any of these reds (the game turns this same drawing into the blue brother by itself).

NO PROPS AT ALL: no balls, no clubs, no motion trails, no speed lines, no stars, no sparkles. The hands juggle INVISIBLE objects: open gloves with the palm visible, as if tossing and catching. The game draws the juggled objects by itself.

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. In every cell Tico is the same size: 430 px from the top of the hair to the bottom of the shoes; head (top of hair to chin) about 174 px; ball nose about 38 x 24 px; open glove about 84 x 71 px; shoe about 148 px long. The bottom of BOTH shoes exactly at y = 486 in every cell (feet planted, they never move); body centered around x = 256. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. Hands always between y = 250 (high, at chin level) and y = 360 (low, at the waist); his left hand between x = 110 and 210, his right hand between x = 300 and 400. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with square cells and scale EVERY number by the same factor (for 1774 x 887 multiply by 0.866); say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the design sheet.

Animation: IDLE JUGGLING loop, 8 frames, the body bouncing on the knees about 8 px while the feet stay planted, each hand throwing once per loop. A DIFFERENT, exaggerated expression in EVERY frame:
1 right hand low and cupped (catching), left hand at middle height, knees bent at the bottom of the bounce; smug grin;
2 right hand flicking up (throwing), body rising; wink;
3 right hand high, palm up and fingers open (release), left hand low and ready; tongue out, concentrating;
4 both hands at middle height, body at the top of the bounce; proud smile;
5 left hand low and cupped (catching), right hand at middle height, knees bending; eyebrows wiggling;
6 left hand flicking up (throwing), body rising; whistling;
7 left hand high, palm up and fingers open (release), right hand low and ready; laughing;
8 both hands at middle height, body coming down; cocky smirk.
The loop must flow from frame 8 back to frame 1.
```

### Resultado da E2 (03/10, noite): recusada como pedida; os 8 desenhos foram aproveitados como "chuveiro" e conferidos em piloto

**Entrega:** `tico_malabares_candidata.png`, 1774 × 887, RGBA. A candidata fica intacta, e o original
está guardado em `originais/tico_malabares_codex_1774x887.png`. O Codex mediu e eu confirmei:
- **Desvio principal:** os quadros 5 a 7 repetem a mão da frente no alto, igual aos quadros 1 a 3, em
  vez de alternar para a outra mão. No 7, a mão é a errada.
- **Tamanho:** alturas de 389 a 407 px na escala real, contra 373 pedidos (uns 7% maiores).
- **Solas:** em 438 e 439 na primeira fila e 416 na segunda, contra 421.
- **Margens:** 4 a 5 px embaixo na primeira fila.
- **Grade:** um pixel do quadro 5 cruza para o 6.
- **O que está certo:** nenhum objeto, trilha ou estrela; a identidade é a da E1; e as oito caras são
  diferentes.
- **Recusa:** a E2 não serve como o ciclo pedido (cada mão jogando uma vez por volta).

**Aproveitamento (decidido por delegação, sem desenho novo e sem espelhar o rosto ou o corpo):**
- Os 8 desenhos formam outro padrão real de malabares, o **chuveiro**. A mão da frente sempre joga alto
  (sobe nos quadros 1 a 3 e 5 a 7 e solta no 3 e no 7). A mão de trás pega embaixo (quadros 1 e 5) e
  passa baixo para a da frente.
- Com isso a folha vira um ciclo de duas jogadas, com as 8 caras.
- **Normalização:** `regrid_sheet.gd` com âncora `pes` e `limpar`, num fator único de 1,1545.
  - O pixel cruzado ficou com o quadro dele, e o desenho não foi cortado.
  - Os pés ficam no mesmo lugar em todos os quadros (sola em 486, meio dos pés em x 256).
  - Altura do cabelo à sola: de 449 a 471 px; a diferença é o quique.
  - Resultado: `tico_malabares.png`.
- **Teco:** `teco_malabares.png`, gerado por `tools/recolor_twin.gd`, que foi ajustado nesta folha.
  - As listras desta folha vão até S 0,93 e V 0,58.
  - Os fiapos entre os botões são vermelho claro como o nariz: as manchas pequenas (< 150 px) também
    trocam.
  - Há uma segunda passada nas beiradas que encostam numa listra trocada.
  - O nariz e a língua ficam (V de 0,85 a 0,91, manchas grandes).
  - Na folha base, o resultado não mudou.
- **Objetos:** `bosses/jugglers/art/ball.png` e `club.png`, recortados da `malabaristas_folha.png` pelo
  objeto ligado, sem as trilhas.
- **No jogo:** `bosses/jugglers/juggler.gd`.
  - Parado no lugar (`idle`, sem andar, sem estar tonto e sem girar), o irmão é o desenho a 12 quadros por
    segundo, espelhado conforme o lado.
  - Os três objetos vêm por código por cima: bolas do Tico, claves do Teco.
  - Na mão, o objeto segue a luva medida em cada quadro (`FRONT_PALMS` e `BACK_PALMS`).
  - O arco alto sobe reto, passa por cima da cabeça e desce por fora do cabelo. Na primeira versão, uma
    parábola, ele descia por cima do cabelo (`piloto_e2_tico_arco_antigo.png`).
  - O passe baixo atravessa reto na frente do peito. Com arco, a clave passava na boca.
  - A clave é segura pelo cabo, apontando para cima e para a frente.
  - O Teco tem `teco = true` na cena.
  - Escala: uns 230 px no jogo, entre o palhaço (198) e a acrobata (268). As caixas de dano não mudaram.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_parado`):
- A luta dos Malabaristas parada, os dois irmãos malabarizando, o palhaço ao lado do Tico e a acrobata
  ao lado do Teco.
- **Registro:**
  - `docs/medidas/malabaristas/e2_piloto_60fps.csv`, com o quadro do desenho e a posição de cada
    objeto a cada quadro do jogo;
  - recortes de 1 s em `piloto_e2_tico_60fps.png`, `piloto_e2_teco_60fps.png` e
    `piloto_e2_arena.png`.
- **Conferido:**
  - os pés parados;
  - a escala ao lado dos jogadores;
  - os objetos saindo e chegando na luva desenhada;
  - o Teco espelhado e azul, com o nariz, a língua, a pele e as luvas sem mudança.
- **Maior salto de um objeto entre dois quadros do jogo:** 74 px.
  - Acontece só quando a mão desenhada muda de lugar entre um desenho e outro (do 7 para o 8, e do 3
    para o 4, a mão desce até 77 px), e o objeto vai junto.
  - Não há salto vindo do código.
- **Bateria depois de integrar:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações que ficam (a E2 não está "completa"):**
- **Padrão:** é o chuveiro, não a cascata alternada pedida.
- **12 quadros por segundo:** a mão da frente salta até 77 px entre dois desenhos.
- **Clave e rosto:** no quadro 2 a luva da frente fica junto do rosto, e a clave segura encosta na beira
  dele.
- **Só o parado é desenho:**
  - Arremesso, agachado, salto, totem, monociclo, tonto, derrota e o andar do totem continuam por
    código.
  - Na luta, o irmão alterna entre o desenho e o boneco de código.
  - As mãos dos ataques (`hand_position`) continuam as do código.
- **Cabelo:** o Teco ficou de cabelo preto como o Tico (a E1 é assim). O castanho era só do código.
- **Recoloração:** pode sobrar algum pixel avermelhado de beirada no Teco, que não aparece no tamanho do
  jogo.

**Correção focal E2b:** não é necessária para o parado. Se a avaliação humana pedir a cascata
alternada, o pedido seria só os quadros 5 a 7 com a OUTRA mão no alto, desenhados de novo (não
espelhados), com as mesmas medidas do Pedido E2.

**Próximo pedido:** a folha do arremesso (E3), uma por vez, com o mesmo método: medidas tiradas da
`tico_malabares.png`, sem objetos e conferida em piloto a 60 quadros por segundo antes de integrar.

### Acabamento E2b do parado (03/10, noite): intermediários do braço e a clave presa pelo cabo

O piloto da E2 tinha três defeitos visíveis. O Codex os apontou e o CSV confirma.
- **Objeto saltando:** até 74 px de um quadro do jogo para o outro. Era o objeto 2, do desenho 7 para o
  8, e houve 56 px do 2 para o 3. A luva desenhada saltava até 77 px.
- **Clave no rosto:** a clave encostava no rosto no desenho 2.
- **Causa:** era a mão desenhada que pulava entre os desenhos. Interpolar só o objeto não resolvia.

**Método escolhido:** desenhos intermediários do braço da frente, montados a partir dos desenhos da
própria E2.
- Sem PNG novo, sem mudar a identidade, sem espelhar o rosto e sem voltar para a cascata.
- **Ferramenta:** `tools/juggler_inbetweens.gd`. Cada intermediário usa o corpo e o rosto de um desenho
  vizinho, sem o braço da frente, mais o braço da frente inteiro (braço e luva, desenhados à mão) de
  outro desenho. O braço é deslocado pela ponta da gola e fica atrás do corpo.
- **Recorte do braço que sai:** o miolo da luva e da pele do braço, mais a tinta que só encosta nele.
  O contorno do tronco, o bigode e a gola ficam (há cantos protegidos).
- **Os quatro intermediários:**
  - C: corpo do 2 com o braço do 6, entre o 2 e o 3;
  - A: corpo do 4 com o braço do 2, entre o 3 e o 4;
  - D: corpo do 5 com o braço do 2, entre o 5 e o 6;
  - B: corpo do 8 com o braço do 2, entre o 7 e o 8.
- **Ordem de tocar:** 1, 2, C, 3, A, 4, 5, D, 6, 7, B, 8, com tempos de 4, 3, 3, 4, 3, 3, 4, 3, 3, 4, 3
  e 3 quadros do jogo (somam 40, ou 0,667 s, a mesma volta de antes). As solturas continuam no começo
  do 3 e do 7.
- **Arquivos:** `tico_malabares_12.png` e `teco_malabares_12.png` (recolorido) em `docs/`, e
  `bosses/jugglers/art/*/idle12.tres`.
- **A versão de 8 fica no jogo para comparar:** `Juggler.smooth_idle = false`, e `idle.tres` está
  intacto.

**Clave pelo cabo** (`bosses/jugglers/juggler.gd`):
- **Pegada:** a clave é segura pelo ponto da pegada (`CLUB_GRIP`, 20% do botão do cabo para o corpo).
  No ar, ela gira em volta do meio, e a passagem entre um e outro dura 0,08 s.
- **Ângulos:**
  - Na mão da frente, a clave aponta para cima e para a frente, uns 43° acima da horizontal, longe do
    rosto.
  - Na mão de trás aponta para cima e para trás. Antes, com o mesmo ângulo nas duas, a clave atravessava
    o peito até o queixo.
- **Giro no ar:** o voo alto gira pouco mais de uma volta e chega no ângulo da mão de trás. O passe
  baixo vira do ângulo de trás para o da frente.
- **Na troca de mão:** a clave chega de cabo para baixo.

**Medidas** (`--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_parado <pasta> [8]`):
- São 3 s (180 quadros do jogo, 4,5 voltas do desenho e 3 ciclos de cada objeto), os dois irmãos, as
  duas versões.
- Cada passo de um objeto é classificado pela causa. Valores em px, iguais no Tico e no Teco:

| Causa | 8 desenhos (antes), máximo / P95 | 12 desenhos (agora), máximo / P95 |
|---|---|---|
| Objeto na fronteira de estado (soltar, pegar, passar) | 74,2 / 56,4 | **13,6 / 13,6** |
| Luva da frente desenhada, de um quadro do jogo para o outro | 77,2 / 74,2 | **48,1 / 47,1** |
| Objeto na mão, quando o desenho troca | 38,8 / 38,8 | **33,5 / 33,5** |
| Objeto na mão, sem troca de desenho | 0 | 0 |
| Voo alto (velocidade do arco, legítima) | 26,6 / 23,6 | 26,6 / 23,6 |
| Passe baixo | 19,1 / 17,4 | 17,2 / 17,2 |

- **Onde estão os maiores que sobram:**
  - Os 48 px da luva são a mão **vazia** descendo logo depois de soltar (do 3 para o A e do 7 para o B).
  - Os 33,5 px são a mão da frente segurando o objeto que acabou de chegar (do A para o 4).
  - Agora, na mão, o salto é parecido com a velocidade do próprio arco (26,6).
- **Do 8 de volta ao 1:** sem evento acima de 25 px na mão. Só o voo alto (26,3 px) atravessa essa
  fronteira.
- **Arquivos:**
  - `docs/medidas/malabaristas/e2b_8desenhos_3s.csv` e `e2b_12desenhos_3s.csv`, com os resumos (`*_resumo.txt`, com cada evento acima de 25 px e a causa);
  - `e2_piloto_60fps.csv`, o de 1 s, preservado.

**Movimento de verdade:**
- **Cena nova:** `tests/juggler_compare.tscn`. Na Godot (F6), mostra em loop o Tico e o Teco, com 8 e 12
  desenhos lado a lado, em 1,6 vez o tamanho.
- **Gravação reproduzível:** `--fixed-fps 60 --path . res://tests/juggler_compare.tscn -- <pasta>` grava
  120 quadros (2 s), que dá para montar num vídeo.
- **Imagens:** `malabaristas/comparar_8_12.png` (4 momentos) e `piloto_e2b_*_3s.png` (recortes a cada 2
  quadros na arena).
- São fotos e números. Ninguém assistiu ao movimento ainda, e nada disso é aprovação.

**Bateria depois de integrar:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações que ficam:**
- **Luva:** a mão vazia ainda desce 48 px de uma vez depois de soltar. Um quinto intermediário (corpo do
  3 com o braço do 6) deixaria a raiz do braço erguido sobrando; não fiz.
- **Tique na raiz do braço:** sobrou um tique de tinta de uns 2 px no jogo em dois intermediários (A e D).
- **Passe baixo:** a clave cruza o peito, na altura da gola. É o passe de mão em mão, legítimo, e não
  passa no rosto.
- **A versão de 8 também mudou:** no "antes" da comparação, a clave já está presa pelo cabo. A clave
  antiga está no scratchpad (`e2b/juggler_chuveiro_v1.gd`).
- **Outras poses:** continuam por código (arremesso, salto, tonto e derrota).

## Pedido E3: Tico arremessando (entregue em 03/10; aproveitado como arremesso por baixo, ver "Resultado da E3")

**Uso no jogo:** a pose `throw` do `Juggler` (`bosses/jugglers/juggler.gd`), que hoje é por código.
Ela entra:
- no Troca-Troca (`juggle_pass.gd`): o irmão arremessa bolas e claves para o outro;
- nas Bolas Quicando (`bounce_balls.gd`): a bola cai da mão e sai quicando;
- nas Claves em Linha (`club_volley.gd`), o de cima do totem;
- na Chuva de Tochas (`torch_rain.gd`), em cima do monociclo;
- nas entradas do totem e do monociclo.
O Teco usa a mesma folha recolorida (`tools/recolor_twin.gd`).

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_arremesso_candidata.png`. É a candidata, irmã de
`tico_malabares.png`. O Claude confere, normaliza e só então integra.

**Tempos medidos nos ataques:**
- **Duração da pose:** o irmão fica em `throw` de 0,25 s antes do objeto sair até 0,1 s depois, ou seja,
  0,35 s. Nas Claves em Linha, de 0,35 s antes até 0,05 s depois (0,4 s).
- **Onde o objeto aparece:** em `hand_position()`, 38 px para a frente e 150 px acima dos pés no jogo,
  ou seja, (332, 186) na célula. Os projéteis continuam sendo do jogo.
- **Quadros no jogo** (contados de quando a pose começa):

| Quadro | Tempo | O que é |
|---|---|---|
| 1 | 0 a 0,13 s | preparo |
| 2 | 0,13 a 0,25 s | braço vindo para a frente |
| 3 | 0,25 a 0,31 s | **soltura**: começa exatamente quando o objeto aparece |
| 4 | 0,31 s até voltar ao parado | acompanhamento e volta |

**Medidas reais da E2 normalizada (`tico_malabares.png`), as que valem para a E3:**
- Alvo do pedido E2 era 430 px; não foi atingido. A E2 normalizada mede de 449 a 471 px do cabelo à
  sola. A E3 deve ter **460 px** em pé, com a mesma escala da E2.
- Nariz de bola: uns 46 × 32 px.
- Luva aberta: de 80 a 100 px de largura.
- Sapato: uns 160 px de ponta a ponta.
- Sola dos dois sapatos em y 486. Meio dos pés em x 256.
- No jogo fica com 230 px, a mesma escala do parado.

**Grade e pivôs:**
- Canvas de 2048 × 512, 4 × 1 células de 512.
- Sola em y 486 nos quatro quadros, com os pés plantados (o arremesso é da cintura para cima, com o peso
  passando de um pé para o outro).
- Meio dos pés em x 256. Margem de 24 px em volta de tudo.
- **Mão da frente (a da direita, que arremessa):**
  - quadro 1: atrás, perto de x 150 e y 300;
  - quadro 2: na altura do ombro, x ~260 e y ~240;
  - quadro 3: aberta e esticada para a frente e para cima, com o meio da luva em (330 ± 15, 220 ± 15),
    bem embaixo do ponto onde o objeto aparece;
  - quadro 4: descendo para a frente, x ~360 e y ~300.
- **Mão de trás:** perto do peito, como no parado.

**Plano de conferência em movimento** (antes de integrar):
1. Normalizar com `regrid_sheet.gd` (`pes`) e medir em cada quadro: sola, altura de 460 ± 3%, nariz
   46 × 32 ± 10%, meio da luva do quadro 3, e nenhum objeto, trilha ou linha de velocidade.
2. Teco por `recolor_twin.gd`, conferindo o nariz e a língua.
3. Ligar o `throw` no `Juggler`: o quadro pelo tempo desde que a pose começou, com o quadro 3 no instante
   em que o objeto aparece.
4. Piloto a 60 quadros por segundo com o Troca-Troca de verdade (os dois irmãos) e as Bolas Quicando.
   Conferir:
   - a distância entre a luva do quadro 3 e o ponto onde o objeto aparece (até 15 px);
   - a troca parado → arremesso → parado sem salto de pé nem de corpo;
   - os dois lados espelhados.
5. Rodar a bateria. Os ataques, os projéteis e as caixas de dano não mudam.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_arremesso_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/malabaristas/tico_malabares.png = the APPROVED idle juggling sheet of TICO (8 frames, cells of 512 x 512). Copy EXACTLY this character, his size and his ground line: same round head, slicked black hair, big curly black mustache, big glossy red ball nose, big eyes, cream ruffle collar, RED and cream striped one-piece leotard with gold buttons, white gloves, big brown-and-cream shoes; same 3/4 view FACING RIGHT; same ink style.
- docs/referencias/pecas/malabaristas/malabaristas_folha.png = the approved design sheet (left half is Tico).
Do NOT use docs/referencias/chefao_malabaristas.png (old concept, different look).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline (the game turns this same drawing into the blue brother by itself).

NO PROPS AT ALL: no ball, no club, no motion trails, no speed lines, no stars, no sparkles. The throwing hand is EMPTY and OPEN; the game draws the thrown object by itself.

SIZE AND POSITION (measure tico_malabares.png and match it): canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. In every cell Tico is the same size as in tico_malabares.png: about 460 px from the top of the hair to the bottom of the shoes; ball nose about 46 x 32 px; open glove 80 to 100 px wide; shoe about 160 px long. The bottom of BOTH shoes exactly at y = 486 in every cell, feet planted (they do not slide; the weight shifts from the back foot to the front foot); the middle between the two feet at x = 256. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow.

FRONT HAND (his right hand, on the right side of the picture) position in each cell, center of the glove:
1 behind and low, about x = 150, y = 300 (wind-up);
2 coming forward at shoulder height, about x = 260, y = 240;
3 stretched forward and up, OPEN, palm up, center of the glove at x = 330, y = 220 (the release; the object leaves from just above this glove);
4 following through forward and down, about x = 360, y = 300.
The back hand stays near the chest, as in the idle sheet.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference sheets.

Animation: THROW, 4 frames, a DIFFERENT, exaggerated expression in EVERY frame:
1 wind-up: arm back, body twisted back, focused squint;
2 arm whipping forward: shouting "hup!" with the mouth wide open;
3 release: arm stretched forward and up, hand open, delighted grin;
4 follow-through: arm coming down in front, cocky smirk, ready to go back to juggling.
```

### Resultado da E3 (03/10, noite): aproveitada como arremesso por baixo, conferida em piloto e no jogo

**Entrega:** `tico_arremesso_candidata.png`, gerada pelo Codex. O Codex não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_arremesso_codex_2173x724.png`.
- **Medidas do Codex, confirmadas:**
  - 2173 × 724 (3:1, não os 4:1 pedidos);
  - alturas de 501 a 534 px na escala real e solas em 648 e 649;
  - margens laterais falhando, e o quadro 1 passando 10 px para a coluna 2;
  - sem objetos nem trilhas, e as quatro caras diferentes.

**Normalização** (`regrid_sheet.gd`, âncora `pes`, `limpar`, `escala=0.936`):
- O fator total é único, de 0,882. Cada quadro foi separado pelo vão transparente, não pela grade, e o
  pedaço do quadro 1 ficou com ele.
- **Resultado:** `tico_arremesso.png`, em 2048 × 512, com os pés no mesmo lugar do parado (sola em 486,
  meio dos pés em x 256).
- **Alturas:** de 443 a 471 px, contra 449 a 471 da E2 normalizada.
- **Nariz:** de 43 a 46 × 28 a 37, contra 46 × 32 na E2.
- A escala bate com o parado, mas nem 430 nem 460 foram "atingidos" exatamente.

**Desvios da candidata e decisões:**
- **Ordem:** o desenho 2 tem a mão mais alta e mais à frente que o 3. Na ordem 1-2-3-4 o braço voltaria
  para trás antes de soltar.
- **Desenho 1:** a mão da frente fica fechada no peito, em vez de atrás, e a cabeça inclinada para a
  frente.
  - No primeiro piloto (ordem 1 → 3 → 2 → 4), o nariz pulava **47 px** ao entrar no arremesso e de novo
    do 1 para o 3.
  - Registro: `docs/medidas/malabaristas/e3_piloto_ordem_1_3_2_4*` e
    `piloto_e3_troca_troca_ordem_antiga.png`.
- **Decisão (por delegação):** aproveitar como **arremesso por baixo**, o lançamento do malabarismo.
  - A ordem é 4 (a mão baixa na frente, sorriso de lado), 3 (a palma aberta no queixo, a soltura) e 2 (a
    mão subindo, gritando "hup!").
  - O desenho 1 fica de fora do jogo, guardado na folha.
- **Teco:** gerado por `recolor_twin.gd`. O limite de saturação da listra subiu para 0,99, porque havia
  uma listra com S 0,97. O nariz e a língua continuam de fora, pelo brilho. No desenho 2 sobram uns
  pixels avermelhados (cerca de 1 px no jogo).

**No jogo** (`bosses/jugglers/juggler.gd`):
- O arremesso desenhado só aparece quando o irmão arremessa **em pé**, vindo do parado: no Troca-Troca, nas
  Bolas Quicando e na base do totem.
- Sentado no totem (Claves em Linha) ou no monociclo (Chuva de Tochas), continua o boneco de código.
- **Tempos** (desde que a pose `throw` começa, 0,25 s antes de o objeto aparecer):
  - desenho 4, de 0 a 0,18 s;
  - desenho 3, de 0,18 a 0,31 s (o objeto aparece aos 0,25 s, com este desenho na tela);
  - desenho 2, de 0,31 s até a pose acabar;
  - depois, o parado.
- `hand_position()`, os ataques, os projéteis e as caixas de dano não mudaram.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_arremesso <pasta>`):
- Troca-Troca e Bolas Quicando de verdade, os dois irmãos, cada um olhando para um lado.
- **Sincronia:** em todos os 9 objetos que apareceram, o desenho na tela era o 3 (a soltura).
  - O ponto onde o objeto aparece ficou a **14,3 px** do meio da palma desenhada, nos dois irmãos, e o
    espelhamento está certo.
  - Algumas leituras deram 28,6 px porque foram feitas um quadro depois, com o objeto já andando.
- **Pés:** não andaram (nenhum aviso).
- **Corpo** (o pulo do nariz desenhado entre dois quadros do jogo):

| Momento | Máximo | P95 |
|---|---|---|
| Parado (trocas normais) | 21,2 px | 14,5 px |
| Entrada no arremesso | 21,8 px | 21,8 px |
| Dentro do arremesso | 23,8 px | 8,5 px |
| Saída para o parado | 21,0 px | 21,0 px |

- **Arquivos:**
  - `docs/medidas/malabaristas/e3_piloto_por_baixo_4_3_2.csv` e o resumo;
  - recortes em `piloto_e3_troca_troca.png` e `piloto_e3_bolas_quicando.png`.
- **Movimento de verdade:** `tests/juggler_compare.tscn` agora também mostra o arremesso (a cada 1,5 s,
  os quatro arremessam por 0,35 s, sem objeto). Na Godot é F6; com uma pasta, grava 180 quadros.
- **Bateria depois de integrar:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- **Três quadros:** o arremesso ficou com 3 desenhos, e o preparo da folha (o desenho 1) não é usado.
- **Malabares durante o arremesso:** os 3 objetos do parado somem enquanto o irmão arremessa e voltam
  depois. O boneco de código também fazia assim.
- **Sentado:** quem está no totem ou no monociclo continua com o boneco de código.
- **Distância:** a palma fica a 14,3 px do objeto, dentro do limite de 15, mas no limite.
- **Aprovação:** nenhuma visual de alguém que tenha assistido.

## Pedido E4: Tico tonto (entregue em 04/10; no jogo, ver "Resultado da E4")

**Por que este agora:** o irmão tonto é o momento de dupla "Um Não Vive Sem o Outro".
- Ele fica parado no mínimo 3 s, e mais 1,2 s até a bola de cura chegar. Pode durar mais, se o outro irmão
  também ficar tonto.
- É a pose que fica mais tempo na tela depois do parado. Hoje é o boneco de código, com olhos em X.

**Uso no jogo:**
- Liga quando `Juggler.dizzy` é verdadeiro, nas fases 1 e 2.
- O Teco usa a mesma folha recolorida.
- As estrelas que giram em volta da cabeça continuam desenhadas pelo jogo (`_draw_star`). Por isso a
  folha vem **sem estrelas e sem passarinhos**, para não ficar duplicado.
- A bola de cura chega em `head_position()`, 180 px acima dos pés no jogo, ou seja, y ~126 na célula. É o
  alto da cabeça.

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_tonto_candidata.png`. É a candidata, irmã de
`tico_malabares.png` e de `tico_arremesso.png`.

**Medidas** (das folhas que estão no jogo, na escala delas):
- Altura do cabelo à sola: de 445 a 470 px (as duas folhas no jogo medem de 443 a 471).
- Nariz de bola: uns 46 × 32 px.
- Luva: de 80 a 100 px de largura.
- Sapato: uns 160 px.
- Cabeça (cabelo ao queixo): uns 215 px.

**Grade e pivôs:**
- Canvas de 2048 × 512, 4 × 1 células de 512.
- Sola dos dois sapatos em y 486 em todos os quadros, com os pés plantados. Só o corpo balança, dos
  joelhos para cima. Meio dos pés em x 256.
- O alto do cabelo entre y 25 e y 60, com a cabeça mais ou menos sobre x 256 a 300. A bola de cura cai
  ali, então a cabeça não pode sair para longe dos pés.
- Margem de 24 px em volta de tudo.

**Ciclo no jogo:** 4 quadros a 8 por segundo, num loop de 0,5 s. O corpo balança como um pêndulo:
1 inclinado para a esquerda;
2 voltando para o meio;
3 inclinado para a direita;
4 voltando para o meio.

**Plano de conferência em movimento** (antes de integrar):
1. Normalizar com `regrid_sheet.gd` (`pes`, escala única) e medir em cada quadro:
   - sola;
   - altura entre 445 e 470;
   - nariz 46 × 32, com 10% de folga;
   - o alto do cabelo onde a bola de cura chega;
   - nenhuma estrela, passarinho, objeto ou trilha.
2. Teco por `recolor_twin.gd`, conferindo o nariz e a língua.
3. Ligar no `Juggler` quando `dizzy`, com as estrelas do jogo por cima.
4. **Piloto a 60 quadros por segundo** com o tonto de verdade: um irmão chega ao limite da fase, fica
   tonto e recebe a bola de cura. Conferir:
   - a bola chegando no alto da cabeça desenhada (até 20 px);
   - os pés parados;
   - a troca parado → tonto → parado;
   - os dois lados espelhados.
5. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_tonto_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/malabaristas/tico_malabares.png = the APPROVED idle sheet of TICO (cells of 512 x 512): copy EXACTLY this character, his size and his ground line (same round head, slicked black hair, big curly black mustache, big glossy red ball nose, cream ruffle collar, RED and cream striped one-piece leotard with gold buttons, white gloves, big brown-and-cream shoes; same 3/4 view FACING RIGHT; same ink style).
- docs/referencias/pecas/malabaristas/malabaristas_folha.png = the approved design sheet: its bottom row has the DIZZY head (spiral eyes, wavy worried mouth). Use that dizzy face.
Do NOT use docs/referencias/chefao_malabaristas.png (old concept).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline.

NO EXTRA THINGS: no stars, no birds, no sparkles, no props, no motion trails, no speed lines (the game draws the stars around his head by itself).

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. In every cell Tico is the same size as in tico_malabares.png: 445 to 470 px from the top of the hair to the bottom of the shoes; ball nose about 46 x 32 px; head (top of hair to chin) about 215 px; shoe about 160 px long. The bottom of BOTH shoes exactly at y = 486 in every cell, feet planted (they never move); the middle between the two feet at x = 256; the top of the hair between y = 25 and y = 60, the head roughly above x = 256 to 300. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference sheets.

Animation: DIZZY loop, 4 frames, wobbling like a pendulum from the knees up while the feet stay planted; arms hanging loose and floppy, gloves open; a DIFFERENT dizzy expression in EVERY frame (spiral eyes in all of them):
1 body leaning to the LEFT, head tilted, tongue hanging out to one side;
2 swinging back through the middle, eyes spiraling, mouth wavy and worried;
3 body leaning to the RIGHT, head tilted the other way, cheeks puffed;
4 swinging back through the middle, goofy dazed grin, tongue out.
The loop must flow from frame 4 back to frame 1.
```

### Resultado da E4 (04/10): tonto no jogo, conferido em piloto com a cura de verdade

**Entrega:** `tico_tonto_candidata.png`, gerada pelo Codex. O Codex não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_tonto_codex_2048x768.png`.
- **Formato:** veio em 2048 × 768 (células de 512 × 768, não 512 quadradas).
- **Figuras:** de 563 a 606 px. A inclinação do pêndulo muda a altura em uns 43 px.
- **Alpha:** nenhum pixel com alpha 255 (o máximo é 254). Alguns pixels fracos aparecem como um "halo"
  escuro quando se olha só o RGB.

**Revisão** (`regrid_sheet.gd`, âncora `pes`, `limpar`, escala única de 0,79, a do nariz):
- **Alpha, conferido composto sobre cinza:** não aparece halo. Fora da figura o alpha fica entre 0 e 3,
  e a limpeza tirou de 1 a 2 pixels soltos por quadro. Não apaguei tinta nem igualei as alturas.
- **Nariz:** de 57 a 58 × 36 a 43 na candidata, ou seja, uns 46 × 30 depois de normalizar (alvo 46 ×
  32).
- **Alturas:** 445, 480, 446 e 480 px.
  - Os quadros do meio do pêndulo (2 e 4) passam 2% do teto de 470.
  - A margem de cima nesses quadros é de 7 px, contra os 24 pedidos.
  - Aceitei, porque é o pêndulo (o corpo se estica no meio) e a altura cabe na célula.
- **Teco:** `recolor_twin.gd`. O nariz e a língua ficaram, e as listras ficaram azuis. Sobra um fiapo
  vermelho de uns 1 px no ombro do quadro 1.
- **Arquivos:** `tico_tonto.png` e `teco_tonto.png`, e `bosses/jugglers/art/*/dizzy.tres`.

**Desvio que pedia ajuste: a cabeça sai do ponto da cura.** O meio da cabeça desenhada, contra o
`head_position()` antigo (180 px acima dos pés):

| Desenho | Distância |
|---|---|
| 2 e 4 (meio do pêndulo) | 10 px |
| 1 (inclinado para um lado) | 15,5 px |
| 3 (inclinado para o outro lado) | **31 px** |

**Decisão (híbrido, sem mexer na arte):**
- Enquanto o irmão está tonto e desenhado, `head_position()` passa a ser o meio da cabeça do desenho
  atual (`DIZZY_HEADS`).
- Só a bola de cura usa esse ponto, como o fim do arco. Ela pousa pelo tempo (`HEAL_FLIGHT`), não por
  colisão. A mecânica não muda: o tempo de tonto, a cura de 40%, o parry na bola e a troca de fase
  continuam iguais.
- As estrelas continuam por código, em volta da cabeça desenhada, um pouco maiores.
- O tonto desenhado só aparece em pé (no parado, na pose `dizzy` ou com a pose de arremesso que ficou).
  No totem continua o boneco de código.

**Corrigido no caminho (no boss, só visual):**
- **O irmão que jogava a cura ficava preso na pose `throw`.** O boss punha a pose e nunca tirava. No
  piloto, isso impediu o Teco de usar o desenho do tonto na rodada seguinte.
  - Agora ele volta ao parado 0,1 s depois de soltar.
  - O arremesso da cura começa direto no desenho de soltura (`Juggler.throw_now()`), porque a bola sai
    na hora, sem os 0,25 s de preparo.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_tonto <pasta>`):
- **Roteiro:** a luta de verdade. O Tico leva dano até o limite, fica tonto e o Teco joga a cura. Depois o
  contrário.

| | Tico | Teco |
|---|---|---|
| Tempo tonto até a cura pousar | 4,18 s | 4,17 s |
| Pulo do nariz ao entrar no tonto | 28,5 px | 12,9 px |
| Pulo do nariz dentro do tonto (com a ponte 4 → 1) | 36,1 px (P95 35,1) | 36,1 px (P95 35,1) |
| Pulo do nariz ao sair | 16,6 px | 14,9 px |
| Parado, para comparar | 21,2 px | 21,2 px |
| Último quadro da bola visível, até o meio da cabeça | 24,9 px | 24,9 px |
| Maior passo da bola no último 0,2 s | 40,3 px | 40,3 px |

- O tempo mínimo de tonto é 4,2 s (3 + 1,2). O piloto contou a partir do primeiro quadro desenhado.
- **Pêndulo:** 4 desenhos a 8 por segundo (0,5 s). Os 36 px dentro do tonto são o balanço do próprio
  pêndulo (a cabeça vai de um lado ao outro a cada 0,125 s). É mais que o parado; é o estilo do tonto, e
  fica registrado.
- **Bola:** pousa no meio da cabeça desenhada (é o fim do arco). O último quadro em que ainda aparece
  fica a 24,9 px do meio, por dentro da cabeça desenhada (meia largura ~67 px). O passo de 40 px no fim
  soma a velocidade do arco (~25 px por quadro) com a cabeça balançando.
- **Pés:** parados. Os dois lados estão espelhados.
- **Arquivos:**
  - `docs/medidas/malabaristas/e4_piloto_tonto_cura.csv` e o resumo;
  - o resumo de antes da correção do curador (`e4_piloto_antes_correcao_curador_resumo.txt`), em que
    o Teco ficou no boneco de código;
  - recortes em `piloto_e4_tonto_*.png`.
- **Bateria depois de integrar:** 9 testes locais com 0 falhas, incluindo o `test_jugglers` (tonto,
  cura, parry na cura e troca de fase), e o online normal e com rede ruim ok.

**Limitações:**
- O pêndulo pula 36 px por desenho.
- A bola chega rápido: o último quadro visível fica a 25 px do meio da cabeça.
- No online, a cabeça desenhada segue o relógio de cada PC: o ponto final da bola pode diferir uns
  quadros entre os PCs. É só visual; o pouso é pelo tempo.
- No totem, o tonto continua o boneco de código.
- O fiapo vermelho de ~1 px no Teco.
- A aprovação visual humana segue pendente.

## Pedido E5: Tico salto mortal (entregue em 04/10; no jogo, ver "Resultado da E5")

**Uso no jogo:**
- **Troca de Lugar** (`swap.gd`, fase 1):
  - os dois se agacham por 0,6 s (pose `crouch`, o aviso);
  - depois trocam de lado em 1,0 s (pose `spin`);
  - o da esquerda passa por cima, alto, dando **2 voltas**;
  - o da direita vem rolando baixo, na altura do peito, dando **3 voltas** para o outro lado.
- **Entradas do totem e do monociclo:** as mesmas poses `spin`.
- **Hoje:** o boneco de código gira inteiro. Pela regra do Pedido 2, a cambalhota é desenhada quadro a
  quadro, nunca o mesmo desenho girado.
- **No jogo:**
  - o desenho de cada instante sai do `spin` (8 orientações por volta), então o mesmo ciclo serve para
    2 ou 3 voltas e para os dois sentidos;
  - nas 2 voltas, cada desenho fica uns 3,75 quadros do jogo; nas 3, uns 2,5;
  - o agachado entra na pose `crouch`;
  - as caixas de dano e os caminhos dos ataques não mudam.
- **Teco:** a mesma folha, recolorida.

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_salto_candidata.png`. É a candidata, irmã das
folhas de Tico que estão no jogo.

**Medidas** (das folhas no jogo):
- nariz de uns 46 × 32 px;
- cabeça (do cabelo ao queixo) de uns 215 px;
- luva de 80 a 100 px;
- sapato de uns 160 px;
- em pé, de 445 a 470 px.

**Grade e pivôs:**
- Canvas de 2048 × 1536, 4 × 3 células de 512.
- **Ordem:**
  - quadro 1: agachado (o aviso);
  - quadros 2 a 9: a bolinha encolhida em 8 orientações seguidas, cada uma 45° adiante na cambalhota
    para a FRENTE;
  - quadro 10: a aterrissagem;
  - quadros 11 e 12: vazios (transparentes).
- **Agachado e aterrissagem:** sola dos dois sapatos em y 486, meio dos pés em x 256.
- **Quadros 2 a 9:** o MEIO DA BOLINHA (o meio do corpo encolhido) exatamente em (256, 280). A bolinha
  tem de 280 a 330 px de diâmetro, em todos o mesmo tamanho.
- Margem de 24 px em volta de tudo.

**Plano de conferência em movimento** (antes de integrar):
1. Normalizar com `regrid_sheet.gd`: âncora `pes` no 1 e no 10, e o meio em (256, 280) nos 2 a 9
   (`meio_quadro`), com escala única. Medir:
   - o nariz nos quadros de frente;
   - os diâmetros iguais (até 5%);
   - as 8 orientações em ordem, sem repetir nem pular;
   - nenhum objeto, trilha ou estrela.
2. Teco por `recolor_twin.gd`.
3. Ligar no `Juggler`:
   - o desenho por `spin` (orientação = fração da volta × 8);
   - o meio da bolinha no meio do giro de hoje (0, −105);
   - o sentido pelo sinal do `spin` e pelo `facing`.
4. **Piloto a 60 quadros por segundo** com a Troca de Lugar de verdade (os dois) e a entrada do totem.
   Conferir:
   - o passo do meio da bolinha entre quadros, contra o caminho do ataque;
   - a troca agachado → giro → parado nos dois lados;
   - que a orientação nunca volta para trás no meio da volta;
   - as caixas de dano iguais.
5. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_salto_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/malabaristas/tico_malabares.png and docs/referencias/pecas/malabaristas/tico_tonto.png = APPROVED sheets of TICO (cells of 512 x 512): copy EXACTLY this character and his size (round head, slicked black hair, big curly black mustache, big glossy red ball nose, cream ruffle collar, RED and cream striped one-piece leotard with gold buttons, white gloves, big brown-and-cream shoes; same ink style).
Do NOT use docs/referencias/chefao_malabaristas.png (old concept).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline.

NO EXTRA THINGS: no props, no motion trails, no speed lines, no stars, no dust.

SIZE AND POSITION: canvas exactly 2048 x 1536, grid of 4 columns x 3 rows, cells of 512 x 512, one frame per cell, left to right, top row first. Same size as the reference sheets: ball nose about 46 x 32 px, head (top of hair to chin) about 215 px, glove 80 to 100 px, shoe about 160 px. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 1536, keep the same 4 x 3 layout with square cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels, full opacity inside the drawing), clean edges, no grid lines, no text, no ground, no shadow.

FRAMES (a FORWARD somersault, side view, facing RIGHT; a DIFFERENT, exaggerated, laughing show-off expression in every frame):
1 CROUCH (the warning before jumping): knees deeply bent, arms back, grinning at the audience; the bottom of BOTH shoes exactly at y = 486, the middle between the feet at x = 256.
2 to 9 TUCKED BALL, drawn frame by frame (NEVER the same drawing rotated): Tico curled into a tight ball, knees to the chest, gloves holding the shins, the same size in all 8 frames (a ball about 280 to 330 px across); the CENTER OF THE BALL exactly at x = 256, y = 280 in every one of these cells. The 8 frames are 8 orientations of ONE forward turn, each 45 degrees further than the previous one: 2 = upright (head on top, facing right), 3 = 45 degrees forward, 4 = 90 (head to the right), 5 = 135, 6 = upside down (head at the bottom), 7 = 225, 8 = 270 (head to the left), 9 = 315; frame 9 leads back into frame 2. The face is always visible and changes expression in every frame.
10 LANDING: feet together, knees bent, arms opened wide, "ta-da!" face; the bottom of BOTH shoes exactly at y = 486, the middle between the feet at x = 256.
11 and 12: completely EMPTY (transparent).
```

### Resultado da E5 (04/10): salto mortal no jogo, conferido na Troca de Lugar de verdade

**Entrega:** `tico_salto_candidata.png`, gerada pelo Codex. O Codex não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_salto_codex_1448x1086.png`.
- **Formato:** veio em 1448 × 1086 (4:3 certo, células de 362).
- **Desvios do pedido:**
  - o quadro 4 passa para o 5;
  - a sola do 1 fica sem margem;
  - a luva do 10 cruza para o 11;
  - bolinhas de 238 a 328 px nesta escala.

**Revisão** (`regrid_sheet.gd`, `pes` no 1 e no 10, `meio_quadro=2..9:256,280`, `limpar`, escala total de
1,28, a do nariz):
- **Nariz:** os de frente (quadros 2, 6 e 10) mediam uns 36 × 25 e ficaram com uns 46 × 32.
- **Tamanho da bolinha:** a raiz da área opaca vai de 227 a 239 (±3%), o mesmo tamanho nos 8. A caixa
  varia de 306 a 408 px porque a bolinha não é redonda (pernas e cabeça saem).
- **Separação:** os quadros foram separados pelos vãos transparentes. A luva do 10 ficou inteira com ele,
  e o 11 e o 12 ficaram vazios.
- **Orientação, conferida a olho nas ampliações:** a cabeça vai em cima (2), em cima à direita (3),
  direita (4), embaixo à direita (5), embaixo (6), embaixo à esquerda (7), esquerda (8) e em cima à
  esquerda (9). É uma volta para a frente, sem voltar para trás.
  - O 8 e o 9 ficam a uns 35° um do outro, não 45°.
  - No 8, o rosto fica de pé (licença de desenho animado).
  - A medida automática pelo "cabelo" foi descartada, porque o marrom dos sapatos se confunde com ele.
  - Nenhum desenho foi girado.
- **Teco:** `recolor_twin.gd`.

**No jogo** (`bosses/jugglers/juggler.gd`):
- **Desenhos:**
  - na pose `crouch`, o agachado (o aviso);
  - na pose `spin`, a bolinha escolhida pelo giro real (`1 + round(spin × 8) mod 8`). O sinal do giro dá
    o sentido (o que rola por baixo vai ao contrário) e o espelho dá o lado;
  - depois do giro, a aterrissagem por 0,15 s, e então o parado.
- **Objetos:** os do malabarismo não aparecem agachado, girando nem aterrissando. No primeiro piloto
  eles flutuavam em volta do Teco agachado; está corrigido.
- **Sem mudança:** os caminhos do ataque, os tempos, as caixas de dano e as entradas do totem e do
  monociclo usam o mesmo `spin`.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_salto <pasta>`):
- A Troca de Lugar de verdade, duas vezes. Cada irmão passa uma vez por cima (2 voltas) e uma vez por
  baixo (3 voltas ao contrário).
- **Orientação:** nunca voltou para trás (0 vezes), e os 8 desenhos apareceram em cada giro, nos dois
  irmãos.
- **Meio de massa do desenho** (separado do caminho do próprio ataque):

| Momento | Máximo |
|---|---|
| Agachado | 0 px |
| Entrada no giro | 8,7 px |
| Troca de desenho durante o giro (em relação aos pés) | 11,3 px |
| Caminho do ataque (o mesmo de antes) | 54,9 px por quadro |
| Aterrissagem | 8,3 px |
| Parado depois | 7,2 px |

- **Arquivos:**
  - `docs/medidas/malabaristas/e5_piloto_troca_de_lugar.csv` e o resumo;
  - recortes em `piloto_e5_salto_*.png`;
  - o erro das claves, guardado como `piloto_e5_salto_teco_com_claves_erro.png`.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- O 8 e o 9 ficam mais perto um do outro que os outros.
- A entrada do totem e a do monociclo usam o desenho, mas não foram pilotadas à parte (o mesmo `spin`).
- A aprovação visual humana segue pendente.

### Revisão em movimento do tonto (E4b, 04/10)

**O defeito:** no tonto, o nariz pulava 36 px a cada 0,125 s, o mesmo tipo de pulo tratado como
defeito na E2. Não fica como "estilo".

**Método (delegado, sem mexer na arte):**
- Assentamento: a cada troca de desenho, o novo começa inclinado em volta dos pés de modo que a cabeça
  fique perto de onde estava a do anterior, e endireita durante o tempo do desenho.
- A inclinação também vale para o ponto da cura e para as estrelas.
- A versão antiga fica para comparar: `smooth_dizzy = false`.

| Versão | Nariz dentro do tonto, máximo / P95 | Inclinação máxima | Ponta do sapato sobe |
|---|---|---|---|
| Sem suavizar (a de antes) | 36,1 / 35,1 px | 0 | 0 |
| Correção inteira (medida e descartada) | 23,8 / 21,2 px | 10,2° | 16,8 px |
| **Metade da correção (no jogo)** | **29,1 / 26,2 px** | **5,1°** | **8,4 px** |

- **Escolha:** a metade. Com a correção inteira, os pés pareciam sair do chão na troca.
- **Bola de cura:** o último quadro visível fica a 23,6–23,8 px do meio da cabeça.
- **Arquivos:** `docs/medidas/malabaristas/e4b_*` (as três versões) e `piloto_e4b_tonto_suave_tico.png`.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.
- **O que ainda incomoda:** o nariz ainda pula 29 px (mais que os 21 do parado), e o sapato sobe 8 px
  por um instante. Se a avaliação humana achar travado, o caminho é um pedido focal de desenhos do meio
  do pêndulo.

### Entradas do totem e do monociclo com o salto (E5), pilotadas de verdade (04/10)

O piloto da E5 cobria só a Troca de Lugar. As entradas foram pilotadas à parte, porque não dá para supor
que funcionam iguais só por usarem o mesmo `spin`.
- **Comando:** `--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_entradas <pasta>`.
- **Roteiro:** a entrada do totem (`IntroTotem`), 1,5 s de totem parado e a entrada do monociclo
  (`IntroUnicycle`), com o lado dos dois irmãos que o ataque escolhe.

**Falha encontrada e corrigida:**
- **O que acontecia:** no totem, o irmão de baixo (a base) aparecia com o desenho do parado (430 px de
  altura no desenho), e o de cima, sentado a 150 px dos pés dele (o boneco de código), caía em cima da
  cara dele. Foram 245 quadros assim no primeiro piloto.
  - Registro: `piloto_e5_entradas_erro_base_desenhada.png` e `e5_entradas_antes_carregando*`.
- **Correção:** `Juggler.carrying`, ligado pelo `set_mode` na base do totem e do monociclo. Quem carrega o
  irmão fica no boneco de código, como o de cima e o monociclo.
- **Depois:** só sobram quadros desenhados durante o salto para o monociclo, quando ninguém está nos
  ombros (55 quadros, os dois girando).

**Medidas (depois da correção), em relação aos pés, com o caminho do ataque à parte:**

| Momento | Meio do corpo | Caminho do ataque |
|---|---|---|
| Entrada no giro | 8,7 px | até 35,9 px por quadro |
| Giro | 11,3 px | até 41,9 px |
| Saída do giro para sentado (totem) | 7,5 px | 0,2 px |
| Saída do giro para montado (monociclo) | 7,5 px | 0,2 px |

- **Tempos e caixas de dano:** os do ataque, sem mudança.
- **Objetos:** nenhum objeto do parado aparece no giro.
- **Espelhos:** o totem pousa olhando para a direita e o monociclo para a esquerda. Os dois aparecem nas
  fotos (`piloto_e5_entradas.png`).
- **Limitação:**
  - A troca do salto desenhado para o boneco sentado ou montado é uma troca de estilo (o desenho para o
    boneco), a 7,5 px.
  - O totem e o monociclo continuam por código até haver folhas de "sentado" e "montado". Não são pedidas
    agora.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

### Cena de comparação ampliada (04/10)

`tests/juggler_compare.tscn` agora tem 3 partes, que se alternam a cada 6 s (teclas 1, 2 e 3 escolhem;
0 volta a alternar):
1. o parado e o arremesso, 8 × 12 desenhos;
2. o tonto, sem suavizar × com o assentamento da E4b;
3. o salto mortal: agachado, giro de 2 voltas por cima e 3 por baixo, aterrissagem.

**Para rodar:**
- dois cliques em `tools/ver_malabaristas.bat`, ou F6 com a cena aberta na Godot;
- para gravar 180 quadros de uma parte: `--fixed-fps 60 --path . res://tests/juggler_compare.tscn --
  <pasta> parado|tonto|salto`.
- **Imagem:** `comparar_tonto_salto.png` (4 momentos). Não é vídeo nem aprovação.
- **Leitura dos pés nas fotos:**
  - no tonto com assentamento, os sapatos inclinam junto no começo de cada desenho (até 8 px na ponta);
  - no salto, o agachado e a aterrissagem pousam no mesmo lugar.
- **Decisão sobre o tonto (delegada):** manter a metade da correção (E4b) até alguém assistir. Se parecer
  travado, o próximo passo é um pedido focal de 4 desenhos do meio do pêndulo (os intermediários de
  verdade), não mais ajuste de código, porque a inclinação não cria desenho novo.

## Pedido E6: Tico e Teco derrotados (entregue em 04/10; no jogo, ver "Resultado da E6")

**A derrota de hoje, medida** (`-- malabaristas_derrota`, `docs/medidas/malabaristas/e6_derrota_atual_medida.csv`):
- A derrota sempre acontece na fase 3, no monociclo: a base montada e o de cima sentado, os dois olhando
  para a esquerda.
- Por 0,38 s (23 quadros) nada muda.
- Depois, num corte seco, os dois aparecem deitados no chão, de boneco de código: o Tico no chão, 40 px à
  esquerda do monociclo, e o Teco 70 px à direita dele e 40 px acima, deitado por cima. Ficam assim até a
  tela de fim, que abre 2,3 s depois da derrota (sobram ~1,9 s deitados).
- As caixas de dano já estão desligadas. Os objetos do malabarismo não aparecem.
- Foto: `derrota_atual_boneco.png`.

**O que a E6 troca:** o corte seco e o boneco deitado. Uma folha só, com a queda e o "nocaute".
- **Aterrissagem:** os dois usam a mesma folha (o Teco recolorido), cada um no seu ponto de hoje. Quem cai
  por cima é o Teco, desenhado depois, por cima do Tico.
- **Tempos no jogo:**
  - depois dos 0,38 s, os quadros 1 a 3 a 10 por segundo (0,3 s: batendo no chão, quicando, assentando);
  - o 4 parado até a tela de fim;
  - o Teco começa 0,1 s depois do Tico, para cair por cima.
- **Sem objetos:** nada de bolas batendo na cabeça (o Pedido 2 antigo pedia). Se for querer, o jogo
  desenha. As estrelas do nocaute também ficam com o jogo.

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_derrota_candidata.png`. É a candidata, irmã das
folhas de Tico que estão no jogo.

**Medidas** (as do jogo, na escala das folhas aprovadas):
- nariz de uns 46 × 32 px;
- cabeça (do cabelo ao queixo) de uns 215 px;
- luva de 80 a 100 px;
- sapato de uns 160 px;
- deitado, de uns 430 a 470 px da cabeça aos pés (o mesmo corpo de pé, deitado).

**Grade e pivôs:**
- Canvas de 2048 × 1024, 2 × 2 células de 1024 × 512, como as do leão.
- Deitado de costas, olhando para a DIREITA na folha: a cabeça à esquerda, os pés à direita (ele caiu
  para trás). O jogo espelha.
- As costas e a cabeça encostam na linha do chão, em y 486. O meio do corpo deitado fica em x 512.
- Margem de 24 px em volta de tudo.

**Plano de conferência em movimento** (antes de integrar):
1. Normalizar com `regrid_sheet.gd` (`celula=1024x512`, escala única pelo nariz) e medir:
   - o comprimento deitado;
   - o nariz;
   - a linha do chão em 486;
   - nenhum objeto, estrela ou passarinho.
2. Teco por `recolor_twin.gd`.
3. Ligar na pose `down` do `Juggler`, nos tempos acima, com cada irmão no ponto de hoje e o Teco por
   cima.
4. **Piloto a 60 quadros por segundo** com a derrota de verdade (a luta até a fase 3, pelo dano).
   Conferir:
   - a troca do monociclo para o chão;
   - os dois sem se atravessar de um jeito estranho;
   - o Teco por cima;
   - o espelho;
   - a tela de fim no tempo de sempre.
5. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_derrota_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/malabaristas/tico_malabares.png, tico_tonto.png and tico_salto.png = APPROVED sheets of TICO (cells of 512 x 512): copy EXACTLY this character and his size (round head, slicked black hair, big curly black mustache, big glossy red ball nose, cream ruffle collar, RED and cream striped one-piece leotard with gold buttons, white gloves, big brown-and-cream shoes; same ink style).
- docs/referencias/pecas/malabaristas/malabaristas_folha.png = the approved design sheet (its bottom row has the dizzy head, for the knocked-out face).
Do NOT use docs/referencias/chefao_malabaristas.png (old concept).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline (the game turns this same drawing into the blue brother by itself).

NO EXTRA THINGS: no balls, no clubs, no props, no stars, no birds, no motion trails, no speed lines, no dust (the game draws any of these by itself).

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 2 columns x 2 rows, cells of 1024 x 512 (wide cells), one frame per cell, left to right, top row first. Same size as the reference sheets: ball nose about 46 x 32 px, head (top of hair to chin) about 215 px, glove 80 to 100 px, shoe about 160 px; lying down, about 430 to 470 px from the top of the head to the tip of the shoes. Side view: he fell over BACKWARDS, so he lies on his back with his HEAD on the LEFT and his FEET on the RIGHT, face turned toward the viewer. His back and the back of his head rest on the floor line at y = 486 in every cell; the middle of the lying body at x = 512. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 1024, keep the same 2 x 2 layout with 2:1 cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels, full opacity inside the drawing), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference sheets.

Animation: DEFEAT, 4 frames, a DIFFERENT, exaggerated expression in EVERY frame:
1 SLAM: just hit the floor flat on his back, arms and legs flung up in the air, eyes bulging, mouth wide open screaming;
2 BOUNCE: body bounced a little (back about 15 px above the floor line, the rest of the frame on the same line), limbs flopping, eyes spinning (spiral eyes);
3 SETTLING: back on the floor, arms and legs dropping down limp, dizzy wavy mouth, spiral eyes;
4 KNOCKED OUT (held until the end screen): lying flat and limp, arms spread on the floor, legs relaxed, X eyes, tongue hanging out to one side.
```

### Resultado da E6 (04/10): derrota no jogo, conferida na derrota de verdade

**Entrega:** `tico_derrota_candidata.png`, gerada pelo Codex. O Codex não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_derrota_codex_1774x887.png`.
- **Formato:** veio em 1774 × 887 (2 × 2 células de 887 × 443,5).
- **Desvios:**
  - a fila de cima passa da linha 443 (até ~468);
  - as figuras têm de 578 a 611 px de comprimento nessa escala.

**Revisão** (`regrid_sheet.gd`, `celula=1024x512`, `limpar`, `escala=0.797`, que dá um fator total
único de 0,92):
- **Separação:** entre as filas há um vão transparente de verdade (de y ~468 a ~516). O corte foi feito
  nele, sem perder pedaços; os pixels de cima da linha 443 eram do desenho de cima. As colunas também
  foram separadas pelo vão.
- **Escala única de 0,92, pelo nariz e pela cabeça juntos:**
  - o nariz pedia 0,98 (47 px no eixo longo, contra 46);
  - a cabeça pedia 0,89 a 0,9 (do cabelo à gola, de 204 a 239 px, contra 194 a 202 no tonto);
  - escolhi o meio, sem encolher a cabeça só para bater o comprimento.
  - Depois disso, o nariz ficou com ~44 no eixo longo.
- **Comprimento deitado:** de 534 a 565 px (267 a 282 no jogo), contra 430 a 470 pedidos.
  - Aceito: deitado, com os braços e as pernas abertos ou erguidos, o desenho é mais comprido que o
    corpo de pé. A cabeça e o nariz batem com as outras folhas.
- **Registro:**
  - em cada quadro, a parte de baixo do desenho (as costas) fica em y 486, e no quique (2) em 474, 12 px
    acima;
  - o nariz fica em x ~430 da célula, para a cabeça não pular entre os quadros.
- **Teco:** `recolor_twin.gd`. O nariz e a língua ficaram, e as listras ficaram azuis.

**No jogo:**
- **Desenhos:** na pose `down` (`Juggler._defeat_art`), os desenhos 1 a 3 a 10 por segundo e o 4 parado.
  O Teco começa 0,1 s depois (`defeat_delay`).
- **A derrota acontece no monociclo, onde o Tico carrega o irmão.** A derrota desenhada vale mesmo assim
  (a regra do `carrying` não se aplica a ela).
- **A pilha (decidido por delegação, só visual):** o Teco fica por cima do Tico, com a cabeça no peito
  dele, 120 px para o lado dos pés do Tico e 35 px acima. Os dois rostos aparecem.
  - Na posição do boneco antigo (70 px para o lado da cabeça), o Teco tapava o rosto do Tico
    (`piloto_e6_pilha_erro_rosto_tapado.png`).
  - Virado ao contrário, os pés do Teco tapavam (`piloto_e6_pilha_erro_virado.png`).
- Os objetos não aparecem.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 res://tests/screenshots.tscn -- malabaristas_derrota <pasta>`):
- A luta levada até a fase 3 pelo dano de verdade, e os dois derrubados.
- **Tempos:**
  - por 0,38 s (23 quadros), o monociclo de sempre (boneco);
  - no quadro 23, os dois no chão;
  - Tico: o desenho 2 no quadro 30, o 3 no 36 e o 4 no 41;
  - Teco: os mesmos, 6 quadros (0,1 s) depois;
  - a tela de fim no quadro 138 (2,30 s), como antes.
- **Caixas de dano:** desligadas o tempo todo.
- **Arquivos:**
  - `docs/medidas/malabaristas/e6_piloto_derrota.csv` e o resumo;
  - `e6_derrota_atual_medida.csv` (o boneco de antes, preservado);
  - fotos em `piloto_e6_derrota.png` e `piloto_e6_pilha.png`.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- **Corte seco:** o monociclo some e os dois aparecem no chão, como antes. Não há um quadro de queda do
  alto; a batida (1) é o primeiro.
- **Espelho:** na luta, a derrota sempre termina olhando para a esquerda (o monociclo pousa assim). O lado
  oposto só existe pelo espelho geral, que já foi conferido nas outras folhas, e não foi pilotado aqui.
- **Comprimento:** 15 a 20% mais comprido que o pedido.
- **Online:** a pilha é montada em cada PC pelo mesmo código (já era assim).
- **Aprovação:** nenhuma visual humana.

### Revisão do tonto em sequência (E4b, 04/10): o pêndulo continua travado

**Medido em sequência:** o pulo do nariz em cada troca de desenho, a 8 por segundo, no Tico, com as
medidas `e4b_tonto_*.csv`.

| Troca | Sem suavizar (a de antes) | Metade da correção (no jogo) |
|---|---|---|
| 1 → 2 | 35,1 px | 29,1 px |
| 2 → 3 | 36,1 px | 26,1 px |
| 3 → 4 | 34,3 px | 22,2 px |
| 4 → 1 | 26,7 px | 20,1 px |
| Dentro do mesmo desenho | 0 | até 2,7 px por quadro (o assentamento) |

**Conclusão:**
- O assentamento divide o pulo em um salto de 20 a 29 px seguido de um deslize. Continua sendo um pulo
  a cada 0,125 s.
- A causa são os 4 desenhos de um pêndulo a 8 por segundo. A inclinação só move o desenho; não cria pose
  nova.
- Os pés seguem plantados no desenho, mas o sapato inclina até 8 px com o assentamento.
- **Bola de cura:** pousa no meio da cabeça, e o último quadro visível fica a 23,6 px dela.
- **Decisão:** pedir 4 desenhos do meio do pêndulo (E4c, abaixo).
  - No jogo: 8 desenhos (1, A, 2, B, 3, C, 4, D) a 16 por segundo, na mesma volta de 0,5 s, **sem** o
    assentamento (`smooth_dizzy = false` passa a ser o padrão).
  - O ponto da cura (`DIZZY_HEADS`) ganha os 4 meios.
  - A versão de agora fica para comparar.

**Para assistir:**
- Deixei a janela de comparação aberta na parte 2 (o tonto, sem suavizar à esquerda e com o assentamento à
  direita).
- Para abrir de novo já nessa parte:
  `Godot_v4.7.2-stable_win64.exe --path . res://tests/juggler_compare.tscn -- tonto` (também aceita
  `parado` e `salto`). Com a janela aberta, as teclas 1, 2 e 3 trocam de parte.

## Pedido E4c: 4 desenhos do meio do pêndulo do tonto (entregue em 04/10; recusado, ver "Resultado da E4c")

**Uso no jogo:** o tonto (`Juggler`, quando `dizzy`) passa a 8 desenhos a 16 por segundo, na ordem 1, A,
2, B, 3, C, 4, D, com os desenhos 1 a 4 da `tico_tonto.png` que estão no jogo. O Teco recolorido.

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_tonto_meio_candidata.png`. É a candidata, irmã de
`tico_tonto.png`.

**Medidas na `tico_tonto.png`** (as células de 512 dela; o meio da cabeça e o meio do nariz de bola):

| Desenho | Meio da cabeça | Meio do nariz | Corpo |
|---|---|---|---|
| 1 | (227, 137) | (269, 173) | inclinado para a esquerda |
| 2 | (258, 107) | (333, 144) | no meio, ereto |
| 3 | (318, 133) | (376, 202) | inclinado para a direita |
| 4 | (257, 107) | (321, 161) | no meio, ereto |

**Os 4 novos** (alvo de cada um: o meio exato entre os dois vizinhos):

| Novo | Entre | Meio da cabeça | Meio do nariz |
|---|---|---|---|
| A | 1 e 2 | (243, 122) | (301, 159) |
| B | 2 e 3 | (288, 120) | (355, 173) |
| C | 3 e 4 | (288, 120) | (349, 182) |
| D | 4 e 1 | (242, 122) | (295, 167) |

- O A e o D ficam no mesmo lugar, e o B e o C também. Mudam a cara e o embalo: o A e o C vão para o meio;
  o B e o D saem do meio.

**Grade:**
- Canvas de 2048 × 512, 4 × 1 células de 512.
- A sola dos dois sapatos em y 486; os pés no mesmo lugar da `tico_tonto.png` (o meio entre eles em x
  256).
- Margem de 24 px. O tamanho é o mesmo da `tico_tonto.png`.

**Plano de conferência em movimento:**
1. Normalizar com `regrid_sheet.gd` (`pes`, a mesma escala da `tico_tonto.png`).
2. Medir o meio da cabeça e o nariz contra a tabela (até 10 px).
3. Teco por `recolor_twin.gd`.
4. Montar a sequência de 8 (o recorte da `tico_tonto.png` mais esta folha) e ligar no `Juggler` a 16 por
   segundo.
5. Piloto `-- malabaristas_tonto`: o pulo do nariz por troca (alvo: até ~18 px), os pés, a cura e a
   comparação na cena. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_tonto_meio_candidata.png (replace if it exists).

Reference (read from the project): docs/referencias/pecas/malabaristas/tico_tonto.png = the APPROVED dizzy loop of TICO, 4 frames in cells of 512 x 512: 1 leaning LEFT, 2 upright in the middle, 3 leaning RIGHT, 4 upright in the middle. Copy EXACTLY this character, his size, his colors, his feet and his ink style (spiral eyes, red and cream stripes, white gloves, brown-and-cream shoes).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline.

NO EXTRA THINGS: no stars, no birds, no props, no trails, no speed lines (the game draws the stars).

Draw the 4 IN-BETWEEN poses of that pendulum, each one exactly HALFWAY between its two neighbors (same body, same feet, only the lean, the arms and the face change):
A = halfway between frame 1 (leaning left) and frame 2 (upright): slightly leaning left, swinging toward the middle; head center at x = 243, y = 122; ball nose center at x = 301, y = 159.
B = halfway between frame 2 (upright) and frame 3 (leaning right): slightly leaning right, swinging away from the middle; head center at x = 288, y = 120; nose center at x = 355, y = 173.
C = halfway between frame 3 (leaning right) and frame 4 (upright): slightly leaning right, swinging back toward the middle; head center at x = 288, y = 120; nose center at x = 349, y = 182.
D = halfway between frame 4 (upright) and frame 1 (leaning left): slightly leaning left, swinging away from the middle; head center at x = 242, y = 122; nose center at x = 295, y = 167.
Arms hanging loose and floppy, trailing a little behind the swing. Spiral eyes in all; a DIFFERENT dizzy expression in each (tongue out, puffed cheeks, wobbly worried mouth, goofy grin), each one a mix of the expressions of its two neighbors.

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, order A, B, C, D from left to right. Same size as tico_tonto.png (about 445 to 480 px from the top of the hair to the bottom of the shoes; ball nose about 46 x 30 px). The bottom of BOTH shoes exactly at y = 486 and the middle between the feet at x = 256 in every cell, exactly where they are in tico_tonto.png (the feet never move). At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground, no shadow.
```

## Pedido M1: O Grande Mágico Zaratan, folha base (entregue em 04/10; aprovada tecnicamente, ver "Resultado da M1")

**O que o Mágico é hoje no jogo** (`bosses/magician/`, tudo desenhado por código, medido no código):

| Parte | Tamanho no jogo | Pontos e caixas |
|---|---|---|
| Zaratan (pequeno) | ~325 px da sola ao alto da cartola; cabeça em −232, cartola de 48 × 64 sobre aba de 76 | pés no ponto do nó; olha para a ESQUERDA (`facing = -1`); caixa de levar tiro 80 × 300 em −150; caixa que machuca 56 × 260 em −130 |
| Varinha | ~46 px, ponta dourada | mão que lança: parado (50 para a frente, −170), `cast` (40, −300), `throw` (90, −190) |
| Gigante: cabeça | rosto oval de 300 × 380, cartola de 260 × 290 sobre aba de 400 × 40 (o alto a ~−470 do meio do rosto) | meio do rosto em (960, 420) da arena; caixa de levar tiro 280 × 360 |
| Gigante: mãos | palma de 180 × 140, dedos de até 100, punho roxo de 140 × 70 | a ±470 e 230 do meio da cabeça; caixa que machuca 220 × 220 |

- **Poses usadas pelos ataques:**
  - pequeno: `idle`, `cast`, `throw`, `tap`, `bow`, `scared`, `vanish` (some aos poucos) e `eyes_only`
    (só os olhos no Blackout);
  - gigante: `laugh` (boca aberta), `hat_tilt` (a cartola inclina para despejar), `shrink` (encolhe para
    dentro da cartola no fim);
  - mãos: `closed` (de aberta a punho).

**Decisões de rotina (por delegação):**
- **Visual:** circo dos anos 30. Fraque escuro, colete vermelho-escuro com botões dourados, gravata-borboleta
  vermelha, capa roxa forrada de vermelho, cartola preta com faixa vermelha, luvas brancas, varinha preta
  com estrela dourada. Rosto comprido e fino, bigode fino enrolado, cavanhaque pontudo, sobrancelhas
  arqueadas.
- **Escala:** a mesma convenção do Domador. Nas folhas de animação ele terá ~465 px de altura em células de
  512, reduzido a ~330 no jogo (× 0,71). Na folha base ele é desenhado maior, para detalhe.
- **Sem objetos de ataque na folha:** nada de cartas, coelhos, fumaça, pombas ou caixas. Os ataques
  continuam com os deles.
- **Gigante:** na folha base, a cartola vem separada da cabeça (a cartola inclina por código), e as mãos,
  aberta e fechada, vêm separadas.

**Arquivo:** `docs/referencias/pecas/magico/magico_folha_candidata.png`. É uma pasta nova, irmã de
`malabaristas/`.

**Layout** (2048 × 1024, fundo transparente):
- **Metade esquerda** (x 0 a 1023): o Zaratan de corpo inteiro, de pé, olhando para a ESQUERDA, varinha na
  mão da frente.
  - ~900 px da sola ao alto da cartola, com a sola em y 990;
  - meio dos pés em x 512;
  - a capa pode abrir até ~±300 px do meio.
- **Metade direita** (x 1024 a 2047): o gigante.
  - **Cabeça sem a cartola:** o meio do rosto em (1536, 430). O rosto tem ~290 × 370; o bigode passa
    para os lados até ~±210.
  - **Cartola sozinha, acima:** a aba de ~390 × 40 com o meio em (1536, 175); a copa de ~250 × 140
    acima, até y ~30. A cartola é a mesma, só que separada e com a parte de baixo da aba visível.
  - **Mão ABERTA, palma para baixo e dedos abertos:** meio em (1230, 830), cabendo em 300 × 330.
  - **Mão FECHADA, punho:** meio em (1840, 830), cabendo em 300 × 330. As duas com o punho da manga roxo.
- **Margens:** pelo menos 24 px de vazio em volta de cada peça, e as peças não se tocam.

**Plano de conferência:**
- Medir as caixas de cada peça contra as do layout (até 10%).
- Conferir a identidade com o conceito (`chefao_magico.png`), as cores e que não há objetos de ataque.
- Normalizar para 2048 × 1024 com escala única, se vier em outro tamanho.
- A folha base não entra no jogo; serve de referência para o lote abaixo.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE character design sheet for "The Great Zaratan", the magician boss that closes the first area of a 2D Godot game about a haunted 1930s circus. Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_folha_candidata.png (create the folder if needed).

References (read from the project): docs/referencias/chefao_magico.png (the concept: his look, the giant head and hands of the final phase), and docs/referencias/pecas/malabaristas/malabaristas_folha.png + docs/referencias/pecas/palhaco_folha.png for the ART STYLE to match exactly: hand-inked 1930s rubber-hose cartoon (Cuphead-like), thick dark brown outline #1b1410, warm painted shading, slightly worn print texture.

Character: tall, thin, elegant and theatrical stage magician who secretly knows the circus is cursed. Long narrow face, arched eyebrows, sly grin, thin curled black mustache and a pointy black goatee. Black tailcoat (#2a2a36), dark red vest with small gold buttons, red bow tie, purple cape (#3a1f4a) with a red lining (#a3282a), tall black top hat (#1e1622) with a red band, white gloves, a short black wand with a golden star tip (#ffc93c), black shoes.

NO ATTACK OBJECTS: no cards, no rabbits, no doves, no smoke, no sparkles, no boxes, no motion trails, no speed lines.

Canvas exactly 2048 x 1024, fully TRANSPARENT background (real alpha 0 everywhere outside the drawings, full opacity inside), no text, no grid, no ground, no shadows. Every piece separated from the others by at least 24 px of empty space, and at least 24 px from the canvas edges.

LEFT HALF (x 0 to 1023): Zaratan full body, standing, side 3/4 view FACING LEFT, holding the wand in his front hand, cape hanging open behind him: about 900 px from the soles to the top of the top hat, soles at y = 990, the middle between the feet at x = 512; the cape may spread up to about 300 px to each side.

RIGHT HALF (x 1024 to 2047), the GIANT version for the final phase, as separate pieces:
- the giant HEAD WITHOUT the hat: long face about 290 px wide and 370 px tall, centered at x = 1536, y = 430, sinister grin, huge curled mustache reaching about 210 px to each side, pointy goatee;
- the giant TOP HAT alone, ABOVE the head and NOT touching it: brim about 390 x 40 px centered at x = 1536, y = 175, crown about 250 x 140 px above it (top at about y = 30), red band;
- the giant hand OPEN (palm down, fingers spread), white glove with a purple cuff, centered at x = 1230, y = 830, fitting in 300 x 330 px;
- the giant hand CLOSED in a grabbing fist, white glove with a purple cuff, centered at x = 1840, y = 830, fitting in 300 x 330 px.
```

### Lote do Mágico depois da M1 (planejado; um pedido por vez, cada um só depois do anterior no jogo)

Os tempos são os dos ataques de hoje. Cada folha é conferida em piloto a 60 quadros por segundo antes de
integrar, e as caixas de dano não mudam.

| # | Folha | Poses | Uso e tempo no jogo | Método |
|---|---|---|---|---|
| M2 | parado | 4, em loop | entre os ataques | desenho a ~8 por segundo |
| M3 | varinha | 4: erguer (`cast`), apontar, lançar (`throw`), acompanhar | Leque de Cartas (preparo de 0,55 s), Caixas com Serras, entradas | o quadro de soltura sincronizado com a carta saindo de `hand_position()` |
| M4 | cartola | 4: tirar, bater (`tap`), coelhos saindo (sem os coelhos), pôr | Coelhos da Cartola (batida aos 0,5 s e a cada 0,5 s) | os coelhos continuam por código |
| M5 | sumir | 3 a 4 poses do corpo indo para a fumaça (sem a fumaça) | Teleporte (sumir em 0,25 s, aparecer aos 0,85 s) e o Jogo das Três Caixas | híbrido: o `vanish` continua apagando a transparência, e a fumaça continua do jogo |
| M6 | reverência e derrota | 4: reverência (`bow`), susto (`scared`), caindo para dentro da cartola, só a cartola | entrada da fase 2 (`bow`, 0,9 s) e o fim da luta | |
| M7 | mãos gigantes | 2 (aberta e fechada) mais 2 do meio | Mãos que Agarram (0,6 s indo, 0,15 s descendo) e Cartas Gigantes | o desenho escolhido pelo `closed` |
| M8 | rosto gigante | 4 (sorriso, gargalhada, bravo ao levar tiro, tonto no fim), sem cartola | toda a fase 3 | híbrido: a cartola (da M1) é uma peça separada, girada pelo `hat_tilt`; o `shrink` continua no código |

O Blackout (`eyes_only`, só os olhos) continua por código.

### Resultado da E4c (04/10): recusada; os desenhos não ficam no meio do pêndulo

**Entrega:** `tico_tonto_meio_candidata.png`, gerada pelo Codex. O Codex não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_tonto_meio_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724 (3:1, células de 543 × 724).
- **Segunda chamada:** a revisão focal virou o D para a esquerda. Foi recusada pelo próprio Codex e ficou
  fora do projeto.

**Revisão** (`regrid_sheet.gd`, `pes`, `limpar`, `escala=0.806`, a mesma escala da `tico_tonto.png` pelo
nariz e pelo sapato):
- **Tamanho:** alturas de 448 a 463 px, nariz de 41 a 49 px e sapato de 54 a 72 px, como na E4. Os pés
  ficam no mesmo lugar (sola em 486, meio em x 256).
- **Posição contra o alvo** (meio da cabeça e meio do nariz, em px da célula):

| Novo | Cabeça medida (alvo) | Erro | Nariz medido (alvo) | Erro |
|---|---|---|---|---|
| A (entre 1 e 2) | (262, 135) — (243, 122) | 23 | (338, 165) — (301, 159) | 37 |
| B (entre 2 e 3) | (307, 128) — (288, 120) | 21 | (392, 166) — (355, 173) | 38 |
| C (entre 3 e 4) | (286, 128) — (288, 120) | 8 | (357, 189) — (349, 182) | 11 |
| D (entre 4 e 1) | (240, 135) — (242, 122) | 13 | (308, 171) — (295, 167) | 14 |

- **O A e o B passaram do ponto:** a cabeça do A está onde fica a do desenho 2, e a do B quase onde fica a do
  3. Os quatro também têm a cabeça mais baixa que os desenhos eretos 2 e 4 (y 128 a 135, contra 107).
- **Previsão do piloto:** a medida é a mesma do piloto, o nariz da célula levado ao jogo × 0,5. Na
  sequência 1, A, 2, B, 3, C, 4, D, o maior pulo do nariz seria de **35 px** (do 1 para o A). Hoje, com
  4 desenhos sem suavizar, ele é de 36 px, e na metade da correção de 29 px. O pedido era chegar a ~18.
- Não há ordem dos 8 que resolva: reordenando pela posição da cabeça, o pior pulo continua acima de
  25 px.
- **Decisão:** recusada como intermediários. Não foi integrada nem pilotada no jogo (a medida acima já a
  reprova), e o Teco não foi gerado. O jogo segue com a E4b (metade da correção).
- **Sem híbrido:** inclinar ou deslocar estes desenhos para os alvos seria fingir pose nova (e os pés
  sairiam do lugar).
- **Arquivos:** `tico_tonto_meio_normalizada_recusada.png` e `tico_tonto_meio_recusada_contra_alvos.png`
  (cada desenho com as cruzes dos alvos).

**Ferramenta nova:** `tools/onion_guide.gd`, um guia de "papel de cebola". Sobrepõe os dois vizinhos meio
transparentes e marca com cruzes onde fica o meio da cabeça (verde) e do nariz (azul) do desenho do meio.
- O guia do tonto: `docs/referencias/pecas/malabaristas/guia_tonto_meio.png`.

## Pedido E4d: o meio do pêndulo do tonto, desenhado sobre o guia (entregue em 04/10; recusado, ver "Resultado da E4d")

**O que muda em relação ao E4c:** a referência principal é uma imagem, não números. Cada célula do guia
mostra os dois vizinhos sobrepostos e as cruzes do alvo. O desenho novo tem de cair exatamente entre os dois
fantasmas, com o nariz na cruz azul.

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_tonto_meio2_candidata.png`.

**Grade, medidas e plano de conferência:** os mesmos do E4c, com o alvo de até 10 px na cabeça e no nariz
e o piloto real (1, A, 2, B, 3, C, 4, D a 16 por segundo, sem o assentamento, com o pulo do nariz de até
~18 px).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_tonto_meio2_candidata.png (replace if it exists).

MAIN REFERENCE, look at it carefully: docs/referencias/pecas/malabaristas/guia_tonto_meio.png = a GUIDE image, 4 cells of 512 x 512. Each cell shows TWO neighbor frames of Tico's dizzy pendulum drawn as faded ghosts on top of each other, a GREEN cross where the middle of the new head must be, a BLUE cross where the middle of the red ball nose must be, and the floor line (gray line at y = 486).
Character and style reference: docs/referencias/pecas/malabaristas/tico_tonto.png (the approved dizzy frames: spiral eyes, red and cream stripes, white gloves, brown-and-cream shoes, same ink style). Copy the character EXACTLY.

TASK: for each guide cell, draw ONE new frame of Tico that is EXACTLY HALFWAY between the two ghosts: the body leans halfway between the two ghost leans, the head sits ON the green cross, the ball nose sits ON the blue cross, and the shoes are EXACTLY on top of the ghost shoes (the feet never move). Do not copy one of the ghosts: the new pose is in between them. Cell 1 = between the left-leaning frame and the upright frame; cell 2 = between the upright frame and the right-leaning frame; cell 3 = between the right-leaning frame and the upright frame; cell 4 = between the upright frame and the left-leaning frame. He always faces RIGHT (like in tico_tonto.png). Arms hanging loose and floppy. Spiral eyes in all four; a different dizzy expression in each.

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline.

OUTPUT: canvas exactly 2048 x 512, 4 cells of 512 x 512 in the same order as the guide, ONLY the new Tico in each cell: NO ghosts, NO crosses, NO floor line, NO stars, NO props, NO trails, NO text. Fully TRANSPARENT background (real alpha 0 outside the drawing, full opacity inside), clean edges. Same size as tico_tonto.png. If the image tool cannot make 2048 x 512, keep 4 square cells in one row and scale everything by the same factor; say the real size when you deliver.
```

### Resultado da M1 (04/10): folha base do Mágico aprovada tecnicamente, como referência de desenho

A M1 é a folha base. Ela não entra no jogo; serve de referência para as folhas de animação.
- **Entrega:** `magico_folha_candidata.png` (1774 × 887). A candidata fica intacta, e o original está
  guardado em `originais/magico_folha_codex_1774x887.png`.

**Revisão:**
- **Peças:** 5, separadas por grupos ligados (alpha > 0,05). Nenhum pedaço solto fora delas e nenhum
  buraco no interior (pixel não opaco cercado de opaco).
  - Sobre magenta (`magico_folha_sobre_magenta.png`), não aparece franja nem halo.
- **Identidade, conferida com o conceito `chefao_magico.png`:**
  - fraque escuro com friso dourado, colete vermelho, gravata-borboleta vermelha;
  - capa roxa forrada de vermelho, cartola preta com faixa vermelha;
  - bigode fino enrolado, cavanhaque pontudo, sorriso sinistro;
  - luvas brancas e varinha com estrela dourada;
  - o pequeno olha para a ESQUERDA, e o gigante tem o mesmo rosto;
  - sem objetos de ataque.
- **Desvios do layout pedido**, aceitos porque a folha base é referência e cada folha de animação define a
  própria escala:

| Peça | Pedido (na escala da candidata, × 0,866) | Veio | Decisão |
|---|---|---|---|
| Zaratan, altura | ~780 | 865 | aceito; a proporção é a do conceito |
| Zaratan, posição | dentro da metade esquerda | invadia a direita em 82 px | recomposto com margem |
| Cartola, aba | ~338 | 385 | aceito; a cartola fica maior em relação ao rosto que no boneco de código, o que serve à leitura do gigante |
| Mão aberta | ~260 de largura | 303 | aceito |
| Mão fechada | ~286 de altura | 233 | aceito; o punho é naturalmente mais baixo que a mão aberta |
| Margens | 24 | de 9 a 10 px entre a cartola e a cabeça e entre a capa e a mão | recomposto |

- **Normalização:** `magico_folha.png`, 2048 × 1024, com as 5 peças **sem mudar o tamanho de nenhuma**
  (escala 1,0 da candidata), só recolocadas com 24 px ou mais de margem.
  - Zaratan em (46, 125) a (978, 990);
  - cartola em (1344, 40);
  - cabeça em (1359, 289);
  - mão aberta em (1100, 690);
  - mão fechada em (1464, 700).
  - Não encolhi nada para esconder diferença de proporção.
- **As peças soltas** ficam em `docs/referencias/pecas/magico/pecas/`: `zaratan_corpo.png`,
  `gigante_cabeca.png`, `gigante_cartola.png`, `gigante_mao_aberta.png` e `gigante_mao_fechada.png`.
- **Proporções do Zaratan na folha** (altura total de 865, da sola ao alto da cartola):
  - cartola ~20% (~175 px);
  - rosto, da aba ao fim do cavanhaque, ~15% (~125 px);
  - pernas ~45%.
- **Sem aprovação humana.** Não há modelo 3D, nem implícito.

## Pedido M2: Zaratan parado (entregue em 04/10; no jogo, ver "Resultado da M2")

**Uso no jogo:**
- A pose `idle` do `Magician` (`bosses/magician/magician.gd`): entre os ataques e nos momentos em que
  ele espera (por exemplo, no Jogo das Três Caixas e nos Coelhos, entre as batidas).
- Hoje é o boneco de código.
- O sumir (`vanish`, a transparência) e os olhos do Blackout continuam por código, por cima do desenho.

**Arquivo:** `docs/referencias/pecas/magico/magico_parado_candidata.png`. É a candidata, irmã de
`magico_folha.png`.

**Escala e pivôs** (convenção do Domador):
- Ele é desenhado com ~465 px da sola ao alto da cartola, em células de 512.
- No jogo fica com ~330 px (× 0,71), quase a altura do boneco de hoje (~325). As caixas de dano (80 × 300
  e 56 × 260) não mudam.
- Na folha base ele mede 865 px, ou seja, a M2 é a mesma figura × 0,54:
  - cartola ~95 px;
  - rosto (da aba ao fim do cavanhaque) ~67 px;
  - corpo com a capa de ~285 px de largura.
- Sola dos dois sapatos em y 486, meio dos pés em x 256, olhando para a ESQUERDA, como na folha base.
- **Mão da varinha:** é a que o jogo usa no parado (`hand_position()`: 50 px para a frente e 170 acima dos
  pés no jogo). Na célula fica em (186, 246), com 15 px de folga; a varinha abaixada, para o chão.
- Margem de 24 px.

**Ciclo:** 4 quadros a 6 por segundo, num loop de 0,67 s (ele é elegante e mais lento que os
Malabaristas).
- A capa balança, e a mão de trás enrola o bigode.
- Uma cara diferente em cada quadro.

**Plano de conferência em movimento** (antes de integrar):
1. Normalizar com `regrid_sheet.gd` (`pes`, escala única) e medir:
   - sola;
   - altura de 465 ± 3%;
   - cartola e rosto contra as proporções da folha base;
   - mão da varinha contra (186, 246);
   - nenhum objeto de ataque.
2. Recortar com `cut_animation_sheet.gd` (`cell_height` 465, `rig_height` 330).
3. Ligar no `Magician` só na pose `idle`, com o `vanish` e o `eyes_only` continuando por cima. As outras
   poses continuam o boneco.
4. Piloto a 60 quadros por segundo com a luta do Mágico de verdade (o parado entre o Leque de Cartas, o
   Teleporte e os Coelhos). Conferir:
   - os pés parados;
   - a troca do boneco para o desenho;
   - o sumir;
   - o tamanho ao lado dos jogadores;
   - os dois lados (ele vira com o `facing`).
5. Rodar a bateria (`test_magician` e o online).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_parado_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/magico/pecas/zaratan_corpo.png = the APPROVED design of THE GREAT ZARATAN (full body, facing LEFT): copy EXACTLY this character, his proportions, colors and ink style (long narrow face, arched eyebrows, thin curled black mustache, pointy goatee, black top hat with a red band, black tailcoat with gold trim, red vest, red bow tie, purple cape with red lining, white gloves, short black wand with a golden star tip, black shoes with gold).
- docs/referencias/pecas/magico/magico_folha.png = the full approved design sheet.

NO ATTACK OBJECTS: no cards, no rabbits, no doves, no smoke, no sparkles, no motion trails, no speed lines.

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. Side 3/4 view FACING LEFT in every frame, same as the reference. In every cell he is the same size: about 465 px from the bottom of the shoes to the top of the top hat (top hat about 95 px tall, face from the hat brim to the tip of the goatee about 67 px, body with the cape about 285 px wide). The bottom of BOTH shoes exactly at y = 486 and the middle between the feet at x = 256 in every cell (feet planted, they never move). The hand holding the wand is his FRONT hand (toward the left), at about x = 186, y = 246, with the wand pointing DOWN and slightly forward. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference.

Animation: IDLE loop, 4 frames, the cape swaying gently, his back hand twirling the tip of his mustache, the wand hand relaxed; a DIFFERENT, exaggerated expression in EVERY frame:
1 smug, eyes half closed;
2 bored, eyes rolling up;
3 sly smile, one eye squinting;
4 one eyebrow raised high, sinister grin.
The loop must flow from frame 4 back to frame 1.
```

### Resultado da E4d (04/10): recusada; o meio do pêndulo fica sem desenho novo por enquanto

**Entrega:** `tico_tonto_meio2_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_tonto_meio2_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724 (3:1).
- **Primeira chamada:** copiava os desenhos das pontas. Ficou fora do projeto.

**Revisão:**
- **Escala:** única de 0,886, pelo nariz. A escala da E4c (0,806) deixava estes desenhos ~8% menores
  que a E4 (410–429 px), porque vieram desenhados menores. Depois da normalização: 451 a 471 px e nariz de
  44 a 47 px.
- **Pés:** no lugar (`pes`). Não desloquei o corpo inteiro para acertar o alvo.
- **Contra os alvos** (meio da cabeça; nariz pela mesma medida usada nos desenhos da E4, que conta junto o
  vermelho da língua):

| Novo | Cabeça medida (alvo) | Erro | Nariz medido (alvo) | Erro |
|---|---|---|---|---|
| A (entre 1 e 2) | (262, 121) — (243, 122) | 19 | (346, 148) — (301, 159) | 46 |
| B (entre 2 e 3) | (290, 117) — (288, 120) | **4** | (362, 172) — (355, 173) | **7** |
| C (entre 3 e 4) | (302, 122) — (288, 120) | 14 | (372, 196) — (349, 182) | 27 |
| D (entre 4 e 1) | (260, 125) — (242, 122) | 18 | (340, 160) — (295, 167) | 46 |

- **Leitura:**
  - o A e o D são, na prática, desenhos eretos: a cabeça fica onde está a dos desenhos 2 e 4 (x ~258), sem
    a inclinação para a esquerda;
  - o C ainda está perto da ponta direita;
  - só o B cai no alvo;
  - a comparação com as cruzes está em `tico_tonto_meio2_recusada_contra_alvos.png`.
- **Previsão do piloto:** na sequência 1, A, 2, B, 3, C, 4, D, o pior pulo da cabeça seria de 47 px na
  célula (24 no jogo), do 4 para o D. O do nariz passaria de 30 no jogo. Não chega aos ~18.
- **Decisão:** recusada. Não foi integrada, pilotada nem recolorida. O jogo segue com a E4b (metade da
  correção, nariz até 29 px).

**Por que não há híbrido:**
- Usar só o B deixaria o pêndulo torto: 16 por segundo de um lado e 8 do outro.
- Inclinar ou deslocar o A, o C e o D até os alvos seria transformação, não desenho novo, e os pés
  sairiam do lugar.
- Juntar metades de desenhos diferentes (como no braço da E2b) não funciona para um corpo inteiro
  inclinando.
- Fusão de desenhos (crossfade) foi vetada pelo usuário.

**Limite registrado:** foram duas tentativas com números (E4c) e duas com o guia visual (E4d), e o gerador
não controlou a inclinação do pêndulo. Não faço uma quinta tentativa do mesmo tipo.
- **Se voltar:** um pedido por desenho, com uma célula de guia só, e o B aproveitado. Fica para depois do
  M2, se a avaliação humana achar o tonto travado.

**Arquivos:** `tico_tonto_meio2_normalizada_recusada.png` e `tico_tonto_meio2_recusada_contra_alvos.png`.

### Resultado da M2 (04/10): Zaratan parado no jogo, conferido na luta de verdade

**Entrega:** `magico_parado_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/magico_parado_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724 (3:1, células de 543 × 724).
- **Altura:** ~703 px, sem as margens pedidas.
- **Capas:** cruzam a grade em 3 a 18 px, mas nenhuma figura encosta na outra.

**Revisão** (`regrid_sheet.gd`, `pes`, `limpar`, `escala=0.701`, um fator total único de 0,661):
- **Separação:** pelos vãos entre as figuras, sem perder a ponta da capa. As larguras batem com as da
  candidata × 0,661 (348 a 352 px).
- **Altura:** 465 a 466 px nos quatro, com os pés no mesmo lugar (sola em 486, meio em x 256).
- **Identidade:** confere com `zaratan_corpo.png`. A capa balança, a varinha está abaixada, há 4 caras
  diferentes e nenhum objeto de ataque.

**Desvios aceitos:**
- **Mão da varinha:** fica em (148, 285) na célula, contra (186, 246) pedido, a ~54 px do alvo.
  - Aceito: no parado ninguém lança nada desta mão. As cartas saem em `hand_position()` com a pose
    `throw` (no Leque de Cartas e no Blackout), que continua o boneco.
  - `hand_position` não mudou.
- **Mão de trás:** fica na altura da orelha, com os dedos perto da ponta do bigode. Não dá para garantir
  que enrola o bigode; lê como "mexendo no bigode". Aceito como gesto.
- **Olhos do Blackout:** continuam desenhados por código no ponto do boneco (−232). Os olhos do desenho
  ficam uns 10 a 20 px de lá; no escuro, isso não aparece junto.

**No jogo** (`bosses/magician/magician.gd`):
- Na pose `idle` e fora do Blackout, o Mágico é o desenho, a 6 quadros por segundo. Ele é espelhado quando
  olha para a direita (`_art_holder.scale.x = -facing`).
- O sumir (`vanish`) apaga junto, porque é a transparência do nó.
- As outras poses (`cast`, `throw`, `tap`, `bow`, `scared`) continuam o boneco de código.
- Recorte: `cut_animation_sheet.gd`, com `cell_height` 465 e `rig_height` 330, em
  `bosses/magician/art/idle.tres`.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 --resolution 1920x1080 res://tests/screenshots.tscn -- magico_parado <pasta>`):
- **Roteiro:** a luta de verdade, com o parado, o Leque de Cartas, o Teleporte, os Coelhos e o Blackout.
- **Trocas:** 654 quadros com o desenho, 14 trocas do boneco para o desenho e 14 de volta.
- **Pés:** não andaram enquanto ele estava desenhado.
- **Lados:** desenhado olhando para os dois.
- **Caixas de dano:** as mesmas, 80 × 300 e 56 × 260.
- **Sumir:** o teleporte apaga o desenho e o boneco juntos.
- **Tamanho:** ao lado do palhaço, `piloto_m2_arena.png`.
- **Arquivos:** `docs/medidas/magico/m2_piloto_parado.csv` e o resumo; a grade em `piloto_m2_parado.png`.
- **Bateria:** 9 testes locais com 0 falhas, incluindo o `test_magician`, e o online normal e com rede ruim
  ok.

**Limitações:**
- **A troca de estilo:** a cada ataque ele passa do desenho para o boneco de código, e a diferença é
  grande (a capa vermelha some, a cabeça muda). Fica até a M3 e as seguintes.
- **Ponte 4 → 1:** sem medida de pulo. São 4 desenhos a 6 por segundo com os pés fixos.
- **Aprovação:** nenhuma visual humana.

## Pedido M3: Zaratan com a varinha, feitiço e lançamento (entregue em 04/10; só o feitiço entrou, ver "Resultado da M3")

**Uso no jogo:** as poses `cast` e `throw` do `Magician`. Juntas, são a maior parte da troca para o
boneco de código que sobrou na M2.
- **Leque de Cartas** (`card_fan.gd`): `cast` durante o preparo de 0,55 s; depois, em cada leque, `throw`
  de 0,15 s antes a 0,15 s depois de as cartas saírem de `hand_position()`.
- **Blackout** (`blackout.gd`): o mesmo `throw` em volta de cada leque. No escuro aparecem só os olhos.
- **Caixas com Serras** (`saw_boxes.gd`) e entrada da fase 2 (`intro_sawing.gd`): `cast` (a varinha para
  cima enquanto as caixas descem).

**Tempos no jogo:**
- quadro 1 (`cast`, varinha erguida) durante todo o `cast`;
- no `throw` (0,3 s): o quadro 2 de −0,15 a −0,05 s, o 3 de −0,05 a +0,05 (as cartas saem no meio dele) e
  o 4 de +0,05 a +0,15 s;
- depois, o parado (M2).

**Pontos** (na escala da M2: 465 px de altura, sola em 486, meio dos pés em x 256, olhando para a
ESQUERDA):
- **Mão que lança, no quadro 3:** fica em `hand_position()` do `throw` (90 px para a frente e 190 acima dos
  pés no jogo), ou seja, **(129, 218)** na célula, com 15 px de folga. A mão vazia e aberta, jogando para
  a frente. As cartas são do jogo.
- **Quadro 1:** a varinha erguida bem alto, com a mão perto de (200, 110) e a ponta da estrela abaixo de y
  24 (dentro da margem).
- **Quadros 2 e 4:** a mão entre esses pontos.

**Arquivo:** `docs/referencias/pecas/magico/magico_varinha_candidata.png`. É a candidata, irmã de
`magico_parado.png`.

**Plano de conferência em movimento:**
1. Normalizar com a mesma escala da `magico_parado.png` (altura de 465 ± 3%, `pes`) e medir:
   - a mão do quadro 3 contra (129, 218);
   - que não há cartas, fumaça ou estrelas soltas.
2. Recortar e ligar no `Magician` nas poses `cast` e `throw`, nos tempos acima.
3. **Piloto a 60 quadros por segundo** com o Leque de Cartas e o Blackout de verdade. Conferir:
   - o quadro 3 na tela quando as cartas aparecem;
   - a distância das cartas à mão desenhada (até 15 px);
   - os pés;
   - as trocas com o parado;
   - os dois lados.
4. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_varinha_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/magico/magico_parado.png = the APPROVED idle sheet of THE GREAT ZARATAN (cells of 512 x 512, facing LEFT): copy EXACTLY this character, his size, his feet and his ink style.
- docs/referencias/pecas/magico/pecas/zaratan_corpo.png = his approved full design (wand with a golden star tip).

NO ATTACK OBJECTS: no cards, no rabbits, no doves, no smoke, no sparkles, no magic glow, no motion trails, no speed lines (the game draws the cards by itself).

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. Side 3/4 view FACING LEFT in every frame, same size as magico_parado.png: about 465 px from the bottom of the shoes to the top of the top hat. The bottom of BOTH shoes exactly at y = 486 and the middle between the feet at x = 256 in every cell (feet planted). At least 24 px of empty margin around the whole drawing inside its cell (also the raised wand); nothing crosses into another cell. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference.

Animation: CAST AND THROW, 4 frames, a DIFFERENT, exaggerated expression in EVERY frame:
1 CAST: the wand raised high above his head in his front hand (hand at about x = 200, y = 110; the star tip must stay inside the cell, below y = 24), cape flaring, dramatic stare;
2 WIND-UP: the front arm pulled back to throw, shouting "Abracadabra!";
3 THROW: the front arm stretched FORWARD (to the left), the front hand OPEN and flicking, centered at x = 129, y = 218 (the cards leave from this hand), wand held loosely in the same hand, wicked grin;
4 FOLLOW-THROUGH: the arm coming back down in front, wink.
```

### Resultado da M3 (04/10): só o feitiço (varinha erguida) entrou; o lançamento fica para a correção M3b

**Entrega:** `magico_varinha_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/magico_varinha_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724.
- **Desvios do pedido:**
  - o quadro 3 cruza a grade em 28 px;
  - a varinha do 1 fica a 9 px do topo;
  - margens abaixo de 24.

**Revisão:**
- **Escala:** única de 0,775, pela altura do personagem da sola ao alto da cartola (~600 px nos quadros 2 a
  4). Não usei a caixa do quadro 1, que inclui a varinha erguida, e não encolhi o personagem para caber.
  Depois disso, os quadros 2 a 4 ficaram com 461 a 469 px, como o parado.
- **Varinha erguida:** passa da altura da célula de 512 (524 px com a varinha). Por isso a folha
  normalizada usa **células de 512 × 640**, com a sola em 614 e o meio dos pés em x 256
  (`magico/magico_varinha.png`, `bosses/magician/art/wand.tres`).
- **Separação:** pelos vãos, sem cortar a capa nem a estrela.
- **Identidade e paleta:** iguais às do parado. Nenhuma carta, fumaça ou brilho.
- **Mão de lançamento (quadro 3):** a luva aberta fica em (65, 172) na escala do parado (sola em 486),
  contra (129, 218) pedido, a ~79 px.
  - No jogo, a luva desenhada fica 136 px para a frente e 223 acima dos pés, contra os 90 e 190 de
    `hand_position()` do `throw`: **~56 px de distância**. O limite era 15.
  - As cartas sairiam de baixo do punho, no ar (`magico_varinha_q3_contra_alvo.png`).
  - Mudar `hand_position()` para a luva mudaria de onde saem os leques, o que é mecânica. **Não mudei.**
- **Decisão (parcial):**
  - só o **quadro 1 (feitiço)** entra no jogo, na pose `cast`;
  - o `throw` (quadros 2 a 4) continua o boneco até a correção M3b, só do quadro de lançamento;
  - os quadros 2 e 4 ficam recortados na `wand.tres`, para quando o 3 chegar.

**Piloto a 60 quadros por segundo** (`-- magico_parado`, agora com as Caixas com Serras):
- **Feitiço desenhado:** no preparo do Leque de Cartas (32 quadros), no teleporte (77) e nas Caixas com
  Serras (83).
- **Lançamento (`throw`):** continua o boneco (45 quadros no Leque, 55 no Blackout).
- **Trocas:** 15 do boneco para o desenho e 14 de volta.
- **Pés:** um único quadro de "pés andando" com o desenho. É o teleporte trocando de lugar com o
  Mágico **totalmente apagado** (`vanish` 1,0), invisível.
- **Caixas de dano:** as mesmas (80 × 300 e 56 × 260).
- **Arquivos:** `docs/medidas/magico/m3_piloto_cast.csv` e o resumo; a grade em `piloto_m3_cast.png`.
- **Bateria:** 9 testes locais com 0 falhas (com o `test_magician`), e o online normal e com rede ruim ok.

**Limitações:**
- O lançamento continua o boneco, e a troca de estilo no meio do Leque fica até a M3b.
- A varinha erguida usa células mais altas que as do parado. O recorte cuida disso (a sola continua no
  mesmo lugar).
- Nenhuma aprovação visual humana.

## Pedido M3b: o quadro de lançamento da varinha, desenhado sobre um guia (entregue em 04/10; no jogo, ver "Resultado da M3b")

**Por que:** o quadro 3 da M3 lança com a mão longe do ponto de onde as cartas saem. Este pedido é de um
desenho só, sobre um guia visual de uma célula.
- **O guia:** `docs/referencias/pecas/magico/guia_varinha_lancamento.png` mostra os quadros 2
  (preparo) e 4 (acompanhamento) como fantasmas e uma cruz azul onde fica o meio da mão aberta: (129,
  218), na escala do parado, com a sola em 486.

**Arquivo:** `docs/referencias/pecas/magico/magico_varinha_lancamento_candidata.png`.

**Conferência:**
- Normalizar com a escala 0,775 (pela altura do personagem). O meio da luva deve ficar a até 15 px de
  (129, 218).
- Pilotar o Leque e o Blackout: o quadro 3 na tela quando as cartas saem, e a distância das cartas à luva.
- Depois, ligar o `throw` (quadros 2, 3 e 4 nos tempos da M3).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE single frame for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_varinha_lancamento_candidata.png (replace if it exists).

MAIN REFERENCE, look at it carefully: docs/referencias/pecas/magico/guia_varinha_lancamento.png = a GUIDE image of 512 x 512. It shows two frames of THE GREAT ZARATAN as faded ghosts on top of each other: the wind-up (wand behind the hat) and the follow-through (wand down in front). The BLUE cross marks exactly where the middle of his OPEN FRONT HAND must be in the new frame: x = 129, y = 218. The gray line is the floor (y = 486).
Character reference: docs/referencias/pecas/magico/magico_parado.png and docs/referencias/pecas/magico/magico_varinha_candidata.png (copy EXACTLY this character, size, colors and ink style).

TASK: draw the THROW frame between the two ghosts: his front arm (the arm toward the LEFT) swung FORWARD at shoulder height, the front hand OPEN and flicking forward with the palm toward the left, its middle EXACTLY ON THE BLUE CROSS; the wand held loosely in that hand; his shoes EXACTLY on top of the ghost shoes (feet planted); facing LEFT; wicked grin. Same body size as the ghosts (about 465 px from the soles to the top of the top hat).

NO cards, no smoke, no sparkles, no glow, no motion trails, no speed lines (the game draws the cards).

OUTPUT: canvas exactly 512 x 512, ONLY the new Zaratan: NO ghosts, NO cross, NO floor line, NO text. Fully TRANSPARENT background (real alpha 0 outside the drawing, full opacity inside), clean edges, at least 16 px of empty margin around the drawing. If the image tool cannot make 512 x 512, keep it square and scale everything by the same factor; say the real size when you deliver.
```

## Pedido E4e: o tonto, desenho A do meio do pêndulo, sozinho sobre um guia (entregue em 04/10; recusado, ver "Resultado da E4e")

**Por que este formato:** as duas tentativas com 4 desenhos de uma vez (E4c e E4d) não controlaram a
inclinação. Agora vai um desenho por pedido, com um guia de uma célula.
- **O B da E4d passou** (4 px na cabeça e 7 no nariz) e está guardado como
  `malabaristas/tico_tonto_meio_B_aprovado.png`.
- **Ordem:** A, depois C, depois D, um por vez, cada um conferido antes do próximo.
- **No jogo:** os 8 desenhos (1, A, 2, B, 3, C, 4, D) a 16 por segundo, sem o assentamento, só quando os
  quatro do meio estiverem aprovados. Até lá, o jogo segue com a E4b.

**O guia:** `docs/referencias/pecas/malabaristas/guia_tonto_meio_A.png` mostra os desenhos 1 (inclinado
para a esquerda) e 2 (ereto) como fantasmas, com a cruz verde no meio da cabeça (243, 122) e a azul no
nariz (301, 159).

**Arquivo:** `docs/referencias/pecas/malabaristas/tico_tonto_meio_A_candidata.png`.

**Conferência:**
- Normalizar com `pes` e a escala pelo nariz.
- A cabeça e o nariz devem ficar a até 10 px das cruzes, e os pés no lugar.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE single frame for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/tico_tonto_meio_A_candidata.png (replace if it exists).

MAIN REFERENCE, look at it carefully: docs/referencias/pecas/malabaristas/guia_tonto_meio_A.png = a GUIDE image of 512 x 512 with TWO faded ghosts of Tico: one LEANING LEFT and one standing UPRIGHT. The GREEN cross marks where the middle of the new head must be (x = 243, y = 122); the BLUE cross marks where the middle of the red ball nose must be (x = 301, y = 159). The gray line is the floor (y = 486).
Character reference: docs/referencias/pecas/malabaristas/tico_tonto.png (the approved dizzy frames; copy EXACTLY this character, size, colors and ink style).

TASK: draw ONE new Tico EXACTLY HALFWAY between the two ghosts: leaning a LITTLE to the left (half of the left ghost's lean), head ON the green cross, ball nose ON the blue cross, shoes EXACTLY on top of the ghost shoes (feet never move), facing RIGHT, spiral eyes, arms loose and floppy, a dizzy face different from both ghosts (for example eyes spiraling with a wobbly open mouth).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the nose and the tongue are a brighter, more saturated red with a white shine, each fully closed by the dark outline. NO stars, no birds, no props, no trails.

OUTPUT: canvas exactly 512 x 512, ONLY the new Tico: NO ghosts, NO crosses, NO floor line, NO text. Fully TRANSPARENT background (real alpha 0 outside the drawing, full opacity inside), clean edges. If the image tool cannot make 512 x 512, keep it square and scale everything by the same factor; say the real size when you deliver.
```

## Pedido M4: Zaratan batendo na cartola (entregue em 04/10; no jogo, ver "Resultado da M4")

**Uso no jogo:** a pose `tap` do `Magician`, nos Coelhos da Cartola (`rabbits.gd`).
- Ele fica em `tap` nos primeiros 0,7 s e depois em pulsos de 0,15 s a cada 0,5 s, enquanto os coelhos
  saem do chão na frente dele (90 px à frente dos pés, por código).
- No boneco de hoje, ele bate a varinha no alto da própria cartola, sem tirá-la da cabeça.
- Os coelhos continuam do jogo, e nenhum ponto de lançamento depende da mão.

**Tempos no jogo:**
- quadro 1 (varinha erguida sobre a cartola) nos primeiros 0,45 s;
- em cada batida (os últimos 0,25 s do começo e cada pulso de 0,15 s): o quadro 2 (bate) na primeira
  metade e o 3 (repique) na segunda;
- o quadro 4 (orgulhoso) é o último pulso.

**Grade e pivôs:**
- Canvas de 2048 × 640, 4 × 1 células de **512 × 640**, como a `magico_varinha.png`, porque a varinha
  sobe acima da cartola.
- Sola em y 614 e meio dos pés em x 256, olhando para a ESQUERDA.
- 465 px da sola ao alto da cartola (cartola de ~95 px).
- A varinha, no quadro 1, fica no máximo a 60 px acima da cartola (dentro da margem de 24).
- **Quadro 2:** a ponta da varinha encostando no alto da cartola, que amassa um pouco.

**Arquivo:** `docs/referencias/pecas/magico/magico_cartola_candidata.png`.

**Plano de conferência:**
1. Normalizar com a escala pela altura do personagem e medir a sola, os 465 px e a varinha dentro da
   célula.
2. Ligar na pose `tap` nos tempos acima.
3. Piloto a 60 quadros por segundo com os Coelhos de verdade: os pés, as trocas com o parado e o espelho.
4. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_cartola_candidata.png (replace if it exists).

References (read from the project): docs/referencias/pecas/magico/magico_parado.png and docs/referencias/pecas/magico/magico_varinha.png = the APPROVED sheets of THE GREAT ZARATAN (facing LEFT): copy EXACTLY this character, his size, his feet and his ink style.

NO ATTACK OBJECTS: no rabbits, no cards, no smoke, no sparkles, no motion trails, no speed lines (the game draws the rabbits).

SIZE AND POSITION: canvas exactly 2048 x 640, grid of 4 columns x 1 row, cells of 512 x 640 (taller than wide), one frame per cell, left to right. Facing LEFT, the same size as the references: about 465 px from the bottom of the shoes to the top of the top hat, which stays ON HIS HEAD in every frame. The bottom of BOTH shoes exactly at y = 614 and the middle between the feet at x = 256 in every cell (feet planted). At least 24 px of empty margin around the whole drawing inside its cell (also the wand); nothing crosses into another cell. If the image tool cannot make 2048 x 640, keep the same 4 x 1 layout with cells of the same 4:5 shape and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation: TAPPING HIS OWN TOP HAT WITH THE WAND (to call the rabbits), 4 frames, a DIFFERENT expression in EVERY frame:
1 the front hand raises the wand above his own top hat (the star no more than 60 px above the hat), mischievous look up;
2 TAP: the wand tip hits the top of the hat, the hat squashes a little, eyes shut, concentrated;
3 REBOUND: the wand bounces up a little, the hat springs back taller, delighted;
4 the wand lowered in front, proud chin up.
```

### Resultado da M3b (04/10): o lançamento da varinha no jogo, conferido com o Leque de Cartas de verdade

**Entrega:** `magico_varinha_lancamento_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata
fica intacta, e o original está guardado em `originais/magico_varinha_lancamento_codex_1254.png`.
- **Formato:** veio em 1254 × 1254, com uma figura.
- **Primeira chamada:** copiava o braço esticado demais. Ficou fora do projeto.

**Revisão:**
- **Escala:** única pela altura do personagem (`regrid_sheet.gd`, 1 × 1, `pes`, `escala=0.990`, fator
  total de 0,404). Ficou com 465 px, como o parado e a M3, sem aplicar cegamente o 0,775 da M3.
- **Pés:** sola em 486, meio dos pés em x 256.
- **Mão aberta da frente:** o meio da luva ficou em **(130, 225)**, contra (129, 218): **7 px**.
- **Gesto:** cotovelo dobrado, luva aberta, varinha frouxa.
- **Identidade e paleta:** iguais às da M3. Nenhuma carta ou efeito.
- **Na folha:** o desenho entrou no lugar do quadro 3 da `magico_varinha.png`, descido 128 px para a sola
  cair em 614 (célula de 512 × 640).
  - A folha de antes (com o quadro 3 recusado) está em `magico_varinha_q3_original_m3.png`, e o desenho
    sozinho em `magico_varinha_lancamento.png`.
  - O recorte `wand.tres` foi refeito. A origem mudou porque o quadro novo é menos largo, e os quatro
    quadros usam o mesmo retângulo.

**No jogo** (`magician.gd`):
- **Desenhos no `throw`**, pelo tempo desde que a pose começou (os ataques põem `throw` de 0,15 s antes a
  0,15 s depois de as cartas saírem):
  - desenho 2 (preparo) até 0,1 s;
  - desenho 3 (lançamento) de 0,1 a 0,2 s, com as cartas saindo aos 0,15 s;
  - desenho 4 (acompanhamento) depois.
- **Primeiro leque:** o `throw` começa logo depois do `cast`, quando faltam só 0,05 s para as cartas saírem.
  Por isso, vindo do `cast`, o preparo é pulado: o lançamento vai até 0,15 s, e depois vem o
  acompanhamento.
  - No primeiro piloto, sem esse ajuste, o primeiro leque saía com o desenho de preparo
    (`m3b_piloto_antes_correcao_primeiro_leque_resumo.txt`).
- **Sem mudança:** `hand_position()`, os ataques, as caixas de dano e as cartas.

**Piloto a 60 quadros por segundo** (`-- magico_parado`: o parado, o Leque, o Teleporte, os Coelhos, o
Blackout e as Serras):
- **Leque de Cartas:** nos 3 leques (12 cartas), o desenho na tela quando as cartas apareceram era o de
  lançamento.
  - Da carta à palma desenhada: **4,8 px** nos dois lados (o limite era 15).
  - O Mágico fica desenhado o leque inteiro, sem trocar para o boneco.
- **Teleporte:** o `throw` usa os mesmos desenhos. As cartas do teleporte saem em círculo do corpo, não
  da mão (a 96 px da palma, como antes, porque o ataque é assim).
- **Blackout:** no escuro só aparecem os olhos, como antes.
- **Pés:** o único quadro com os pés mudando é o teleporte com ele totalmente apagado.
- **Trocas:** 11 do boneco para o desenho e 10 de volta (eram 15 e 14).
- **Caixas de dano:** iguais.
- **Arquivos:** `docs/medidas/magico/m3b_piloto_lancamento.csv` e os resumos; a grade em
  `piloto_m3b_lancamento.png`.
- **Bateria:** 9 testes locais com 0 falhas (com o `test_magician`), e o online normal e com rede ruim ok.

**Limitações:**
- O boneco continua em `tap` (Coelhos), `bow` (entrada da fase 2) e `scared` (fim).
- O teleporte mostra o lançamento, mesmo com as cartas saindo do corpo. É aceitável como gesto de
  "abracadabra", mas não foi pedido.
- Nenhuma aprovação visual humana.

### Resultado da E4e (04/10): o desenho A recusado; o caminho de imagem para o meio do pêndulo é encerrado

**Correção de escopo (04/10, depois):** o veto vale para fingir desenho novo com transformação do corpo
inteiro (inclinar, esticar, fundir). Ele não veta todo método por peças: o usuário autorizou híbrido com
peças, ossos e curvas para movimento secundário. Depois do resto do Mágico, pode haver **um** piloto
híbrido do tonto, se for viável: pés fixos, parte de cima (cabeça e ombros) por peças com curvas, comparado
com a E4b. Ele será chamado "por peças", não de "desenho novo" ou "intermediário pronto". Sem esticar o
corpo nem subir a cabeça só para passar no alvo. Até lá a E4b segue, um defeito conhecido.

**Entrega:** `tico_tonto_meio_A_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/tico_tonto_meio_A_codex_1254.png`.
- **Formato:** veio em 1254 × 1254, com uma figura.
- **Primeira chamada:** tinha a cabeça quase ereta. Ficou fora do projeto.

**Revisão** (`regrid_sheet.gd`, 1 × 1, `pes`, `limpar`, escala única pelo nariz):
- **Escala:** com 1,0 (fator total de 0,408), o nariz fica com 46 × 35, como na `tico_tonto.png`. Com 1,1
  ele passaria para 50 × 38. Os pés ficam no lugar (sola em 486).

| | Medido | Alvo | Erro |
|---|---|---|---|
| Meio da cabeça | (234, 153) | (243, 122) | **32 px** (31 para baixo) |
| Nariz | (306, 179) | (301, 159) | **21 px** |
| Altura total | 430 px | entre 445 (desenho 1) e 480 (desenho 2) | mais baixo que os dois vizinhos |

- **Leitura** (`tico_tonto_meio_A_recusada_contra_alvos.png`, com os vizinhos como fantasmas):
  - a inclinação para a esquerda está certa, e os pés caem sobre os dos fantasmas;
  - mas o corpo está **agachado**: a cabeça fica abaixo das cabeças dos dois vizinhos;
  - na sequência 1, A, 2, a cabeça desceria 16 px e subiria 52 (26 no jogo), um pulo maior que o de hoje.
- **Sem correção por transformação:** esticar o corpo ou subir a cabeça seria mexer no desenho para
  fingir pose, e foi vetado.
- **Decisão:** recusado, sem integrar.

**Decisão sobre o tonto (delegada):**
- **Histórico:** foram três formatos de pedido de imagem:
  - E4c, 4 desenhos guiados por números;
  - E4d, 4 desenhos sobre um guia visual;
  - E4e, 1 desenho sobre um guia.
  - Em todos, o gerador não controlou a altura ou a inclinação do corpo no meio do pêndulo. Só o B da
    E4d passou.
- **Encerrado:** o caminho de imagem para o meio do pêndulo fica encerrado neste ciclo, sem C nem D.
- **Sem recorte por partes:** recortar o tronco de um desenho e girá-lo sobre as pernas de outro seria
  inclinação de parte apresentada como pose nova, o que foi vetado.
- **O tonto segue com a E4b** (nariz até 29 px, sapato subindo até 8 px), um **defeito conhecido**.
  Precisa de desenho feito à mão (ou de outro gerador) para os 4 desenhos do meio.
  - O B aprovado e o guia ficam guardados para isso (`tico_tonto_meio_B_aprovado.png` e
    `guia_tonto_meio*.png`).
- **Comparação para assistir:** a janela está aberta na parte do tonto. Para reabrir:
  `Godot_v4.7.2-stable_win64.exe --path . res://tests/juggler_compare.tscn -- tonto`.

### Resultado da M4 (04/10): batendo na cartola no jogo, conferido nos Coelhos de verdade

**Entrega:** `magico_cartola_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica
intacta, e o original está guardado em `originais/magico_cartola_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724 (3:1, não 4:5).
- **Altura:** as alturas com a varinha vão de 566 a 644 px.

**Revisão:**
- **Escala:** única de 0,798, pela altura do personagem no quadro 4 (583 px, sem a varinha acima), o mesmo
  critério da M3. Depois disso, o quadro 4 ficou com 467 px.
  - Não usei a caixa com a varinha nem encolhi para caber.
- **Células de 512 × 640**, com a sola em 614 e o meio dos pés em x 256, colocadas pelo meio de cada
  quadro calculado a partir dos pés (`magico/magico_cartola.png`, `bosses/magician/art/tap.tres`).
- **Separação:** pelos vãos, sem perder a varinha nem a capa.
- **Conferido a olho nas ampliações:**
  - quadro 1: a varinha erguida sobre a cartola;
  - quadro 2: a estrela encostada na copa, a cartola amassada (mais baixa) e os olhos fechados;
  - quadro 3: o repique;
  - quadro 4: a varinha abaixada, com cara de orgulhoso;
  - identidade e paleta iguais às da M2 e da M3; sem coelhos, cartas ou rastros.
- **Desvio aceito:** no quadro 2 a figura fica com 453 px, porque a cartola amassa e a cabeça abaixa. É o
  próprio gesto.

**No jogo** (`magician.gd`, pose `tap`):
- **Problema:** o ataque põe `tap` por 0,7 s no começo e depois em pulsos de 0,15 s a cada 0,5 s. O desenho
  não sabe qual pulso é o último, então o "4 só no último pulso" do pedido não dá para fazer.
- **Ciclo de 0,3 s** pelo tempo na pose: 2 (bate) até 0,08 s, 3 (repique) até 0,16 s e 1 (erguer) até 0,3 s.
  - Cada pulso mostra bate e repique.
  - O começo longo bate duas vezes e meia.
- **Ao sair do `tap`:** o 4 (varinha abaixada) fica 0,15 s, e então o parado.
- **Ajuste:** com os cortes em 0,075 e 0,15, cada pulso terminava com 1 quadro do "erguer". Passei para 0,08
  e 0,16 (`m4_piloto_antes_ajuste_pulso_resumo.txt`).
- **Sem mudança:** os coelhos (90 px à frente dos pés, do jogo), os tempos do ataque, as caixas de dano,
  `hand_position`, o sumir e o Blackout.

**Piloto a 60 quadros por segundo** (`-- magico_parado`, com os Coelhos e a tira `magico_coelhos.png`):
- **Sequência:** 2 → 3 → 1 → 2 → 3 → 1 → 2 → 3 no começo; em cada pulso, 2 → 3 → 4 → parado.
- **Lado e pés:** olhando para a direita (espelhado), com os pés parados e a estrela na cartola.
- **Coelhos:** só os do jogo, nada duplicado.
- **Trocas na luta inteira:** só 2 do boneco para o desenho e 1 de volta. O boneco sobra no `bow` e no
  `scared`, que não estão neste roteiro, e no Blackout aparecem só os olhos.
- **Pés:** o único quadro com pés mudando é o teleporte, com ele totalmente apagado.
- **Caixas de dano e cartas:** iguais (cartas a 4,8 px da palma).
- **Arquivos:** `docs/medidas/magico/m4_piloto_cartola.csv` e os resumos; `piloto_m4_coelhos.png`.
- **Bateria:** 9 testes locais com 0 falhas (com o `test_magician`), e o online normal e com rede ruim ok.

**Limitações:**
- O quadro 4 aparece depois de cada pulso, não só no último.
- O começo longo bate mais de uma vez.
- Nenhuma aprovação visual humana.

## Pedido M5: Zaratan sumindo (entregue em 04/10; no jogo, ver "Resultado da M5")

**Uso no jogo:** o sumir do `Magician` (`vanish`, de 0 a 1).
- **Teleporte** (`teleport.gd`): some em 0,25 s, reaparece no outro lugar aos 0,85 s e volta a ficar
  visível em 0,25 s.
  - Hoje, enquanto some, ele está na pose `cast` (varinha erguida), e a transparência apaga o desenho
    por igual.
- **Jogo das Três Caixas** (`shell_game.gd`): some ao entrar na caixa.

**Método (híbrido, um desenho por faixa do `vanish`):**
- Os desenhos mostram o corpo se enrolando na capa e sumindo, sem a fumaça. A fumaça (`POOF`) e a estrela
  do destino continuam do jogo.
- Enquanto `vanish` > 0, o desenho sai do valor dele: 1 até 0,25, 2 até 0,5, 3 até 0,75 e 4 depois.
- A transparência continua por cima.
- Na volta, como o `vanish` vai de 1 a 0, os desenhos tocam ao contrário (ele "desenrola").
- As caixas de dano e o `set_present` não mudam.

**Grade e pivôs:**
- Canvas de 2048 × 640, 4 × 1 células de 512 × 640, como a `magico_cartola.png`.
- Sola em y 614 e meio dos pés em x 256, olhando para a ESQUERDA.
- Mesmo tamanho (465 px da sola ao alto da cartola, no quadro 1).
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/magico/magico_sumir_candidata.png`.

**Plano de conferência:**
1. Normalizar com a escala única pela altura do personagem (quadro 1) e os pés.
2. Ligar pelo `vanish` (sobre qualquer pose).
3. **Piloto a 60 quadros por segundo** com o Teleporte e o Jogo das Três Caixas de verdade. Conferir:
   - a ordem na ida e na volta;
   - os pés;
   - a cartola no lugar;
   - os dois lados;
   - que não há fumaça duplicada.
4. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_sumir_candidata.png (replace if it exists).

References (read from the project): docs/referencias/pecas/magico/magico_parado.png and docs/referencias/pecas/magico/magico_cartola.png = the APPROVED sheets of THE GREAT ZARATAN (facing LEFT): copy EXACTLY this character, his size, his feet and his ink style.

NO SMOKE AND NO EFFECTS: no smoke, no puffs, no sparkles, no stars in the air, no motion trails, no speed lines, no cards, no rabbits (the game draws the smoke by itself).

SIZE AND POSITION: canvas exactly 2048 x 640, grid of 4 columns x 1 row, cells of 512 x 640, one frame per cell, left to right. Facing LEFT. In frame 1 he is the same size as the references: about 465 px from the bottom of the shoes to the top of the top hat. The bottom of the shoes exactly at y = 614 and the middle between the feet at x = 256 in every cell where the feet are visible; in frames 3 and 4 the shrinking shape stays centered at x = 256 and sits on the same floor line y = 614. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 640, keep the same 4 x 1 layout with cells of the same 4:5 shape and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation: VANISHING INTO HIS CAPE, 4 frames, a DIFFERENT expression in each:
1 he swings the cape around himself with the wand raised, sly smirk;
2 the cape wraps around his body up to the chin, only the head and the hat showing, eyes closed;
3 the wrapped cape twists into a narrow spinning column, the top hat on top, only his grinning eyes peeking out;
4 only the top hat left, resting on the floor line (y = 614) where his feet were, a little wobbling.
```

### Resultado da M5 (04/10): sumir na capa no jogo, conferido no Teleporte e no Jogo das Três Caixas

**Entrega:** `magico_sumir_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica intacta,
e o original está guardado em `originais/magico_sumir_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724.
- **Grade:** os quadros 1 e 2 cruzam a grade.

**Revisão:**
- **Separação:** o `regrid_sheet.gd` separava errado, porque o corte passava por dentro do quadro 1. Usei a
  separação por peças inteiras (o mesmo método da folha base M1). As 4 peças saíram sem pedaço solto nem
  buraco.
- **Escala:** única de 0,71, pela altura do personagem no quadro 1 (655 px para 465), nas 4 peças.
  - A coluna (3) e a cartola sozinha (4) ficaram menores de propósito: 370 e 116 px de altura.
  - Não igualei as caixas nem reduzi a cabeça.
- **Montagem:** células de 512 × 640. O fundo de cada peça (sapatos, a base da coluna, a aba da cartola) na
  sola em 614, e o meio do que toca o chão em x 256 (`magico/magico_sumir.png`,
  `bosses/magician/art/vanish.tres`).
- **Conferido sobre cinza:**
  - 1: a capa abrindo, com a varinha;
  - 2: enrolado até o queixo, olhos fechados;
  - 3: a coluna torcida, com só os olhos e a cartola;
  - 4: só a cartola no chão.
  - Sem fumaça, fantasmas ou restos de capa; identidade e paleta iguais.
- **Desvio aceito:** a cartola não tem exatamente o mesmo tamanho nos 4 desenhos (na coluna, ela parece um
  pouco menor). Não medi isso ao pixel.

**No jogo** (`magician.gd`):
- Com `vanish` > 0, o desenho sai do valor dele (1 até 0,25, 2 até 0,5, 3 até 0,75, 4 depois), sobre
  qualquer pose.
- A transparência do nó continua por cima. Na volta, o `vanish` desce e os desenhos tocam ao contrário.
- **Sem mudança:** a fumaça (`POOF`) e a estrela do destino (do jogo), o `set_present`, as caixas de dano,
  `hand_position` e os ataques.

**Piloto a 60 quadros por segundo** (`--fixed-fps 60 --resolution 1920x1080 res://tests/screenshots.tscn -- magico_sumir <pasta>`):
- **Roteiro:** a luta de verdade, com Coelhos, Teleporte, Coelhos, Teleporte e o Jogo das Três Caixas.
- **Teleporte, duas vezes:** a ordem foi **1, 2, 3, 4, 3, 2, 1** (some e reaparece desenrolando). Os
  dois lados aparecem.
- **Três Caixas:** na ida, 1 → 2 → 3 → 4 (ele fica sumido durante o embaralhar, e a volta não coube nos 6
  s do roteiro).
- **Limitação real:** enquanto some no Jogo das Três Caixas, ele **desliza** uns 95 px até a caixa (o ataque
  move o nó). O boneco antigo deslizava igual, em reverência. O desenho do sumir não tem passos, então o
  deslize continua até haver uma pose de andar.
- **Coelhos, pendência da M4:** agora nos dois lados, 131 quadros de `tap` olhando para a esquerda e 131
  para a direita, com o mesmo ciclo.
- **Trocas:** só 1 troca para o boneco no roteiro, na reverência das Três Caixas.
- **Arquivos:** `docs/medidas/magico/m5_piloto_sumir_coelhos_dois_lados.csv` e o resumo; a grade em
  `piloto_m5_sumir.png`.
- **Bateria:** 9 testes locais com 0 falhas (com o `test_magician`), e o online normal e com rede ruim ok.

**Limitações:**
- O deslize no sumir das Três Caixas.
- A cartola com o tamanho aproximado.
- Nenhuma aprovação visual humana.

## Pedido M6: Zaratan em reverência e com medo (entregue em 04/10; no jogo, ver "Resultado da M6")

**Uso no jogo:** as duas poses do pequeno que ainda são o boneco.
- **`bow` (reverência):**
  - na entrada da fase 2 (`intro_sawing.gd`), por 0,9 s antes de erguer a varinha;
  - no começo do Jogo das Três Caixas (`shell_game.gd`), enquanto vai até a caixa.
- **`scared` (medo):** na entrada da fase 3 (`intro_giant.gd`), por 0,6 s enquanto a luz apaga. Também no
  fim da luta, se ele perder ainda pequeno (o raro caso em que o gigante não apareceu).

**Tempos no jogo:**
- **Reverência:** desenho 1 (tirando a cartola, começando a curvar) de 0 a 0,3 s, e desenho 2 (reverência
  funda, a cartola na mão) depois, enquanto durar a pose.
- **Medo:** desenhos 3 e 4 alternando a 12 por segundo (tremendo), enquanto durar a pose.

**Grade e pivôs:**
- Canvas de 2048 × 640, 4 × 1 células de 512 × 640, como as outras do Mágico.
- Sola em y 614 e meio dos pés em x 256, olhando para a ESQUERDA.
- 465 px da sola ao alto da cartola, em pé.
- Na reverência, o corpo dobra **para a frente** (para a esquerda), e a cartola na mão não sai da célula.
- Os pés plantados nos 4.
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/magico/magico_reverencia_candidata.png`.

**Plano de conferência:**
1. Normalizar com a escala única pela altura do personagem em pé (o quadro 3 ou o 4) e os pés.
2. Ligar `bow` e `scared` nos tempos acima.
3. **Piloto a 60 quadros por segundo** com a entrada da fase 2, o Jogo das Três Caixas e a entrada da fase 3
   de verdade. Conferir:
   - os pés;
   - as trocas com o parado e o sumir;
   - os dois lados;
   - no Jogo das Três Caixas, o deslize da reverência, registrado como limitação.
4. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_reverencia_candidata.png (replace if it exists).

References (read from the project): docs/referencias/pecas/magico/magico_parado.png and docs/referencias/pecas/magico/magico_cartola.png = the APPROVED sheets of THE GREAT ZARATAN (facing LEFT): copy EXACTLY this character, his size, his feet and his ink style.

NO EFFECTS: no smoke, no sparkles, no sweat drops flying away, no motion lines, no cards, no rabbits.

SIZE AND POSITION: canvas exactly 2048 x 640, grid of 4 columns x 1 row, cells of 512 x 640, one frame per cell, left to right. Facing LEFT. Same size as the references: standing, about 465 px from the bottom of the shoes to the top of the top hat. The bottom of BOTH shoes exactly at y = 614 and the middle between the feet at x = 256 in every cell (feet planted, they never move). At least 24 px of empty margin around the whole drawing inside its cell (also the top hat in his hand); nothing crosses into another cell. If the image tool cannot make 2048 x 640, keep the same 4 x 1 layout with cells of the same 4:5 shape and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 4 frames, a DIFFERENT expression in each:
1 BOW START: taking the top hat off with the front hand, the body starting to bend forward (to the left), theatrical smile;
2 DEEP BOW: bent forward at the waist, the top hat held out in front at knee height, the other arm swept back with the cape, eyes closed, smug;
3 SCARED: standing upright, top hat ON his head, both hands raised in front of the chest, eyes popping, mouth open in fear;
4 SCARED, TREMBLING: the same pose as 3 but shaking (knees together, shoulders up), teeth chattering, eyes darting; it alternates with frame 3.
```

### Resultado da M6 (04/10): reverência e medo no jogo, conferidos nas entradas das fases 2 e 3, no Jogo das Três Caixas e na derrota ainda pequeno

**Entrega:** `magico_reverencia_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica intacta,
e o original está guardado em `originais/magico_reverencia_codex_2172x724.png`.
- **Formato:** veio em 2172 × 724 (3:1, células nominais de 543 × 724).
- **Grade:** os quadros 1 e 2 cruzam a grade.
- **Solas:** em 672, 672, 672 e 673.

**Revisão:**
- **Separação:** por peças inteiras (o `pieces.gd` da M1). As 4 peças saíram sem pedaço solto, com 1 buraco
  isolado de 1 px no interior do quadro 2.
- **Escala:** única de 0,756, pela altura do personagem em pé no quadro 3 (615 px para 465), nas 4 peças.
  - **Conferência de identidade:** a aba da cartola fica com 132 px no 3, 130 no 4 e 122 no quadro 4 da M4.
    A cabeça desta folha sai uns 7% maior que a da M4, e os sapatos uns 3% menores (232 contra 240).
  - **Escolha:** fiquei com a altura em pé do pedido, que é o meio-termo entre as duas medidas.
- **Quadro 4:** fica 24 px mais baixo que o 3 (441 contra 465) com a mesma cabeça e a mesma cartola (aba de
  130 contra 132 px).
  - Ele se encolhe: ombros altos, joelhos juntos, sapatos mais próximos (276 contra 307 px).
  - É o tremor pedido, então não igualei as alturas.
- **Células de 640 × 640** (desvio motivado):
  - na escala única, a reverência funda (quadro 2), com a cartola na mão, tem 478 px de largura e 273 deles
    à frente do meio dos pés;
  - numa célula de 512 ela sairia 17 px para fora;
  - em 640, a margem menor é de 47 px.
  - Não encolhi o desenho. A célula mais larga não muda nada no jogo, porque o `.tres` guarda a origem.
- **Montagem:** sola em 614, meio dos pés (as 40 linhas de baixo) em x 320 (`magico/magico_reverencia.png`,
  `bosses/magician/art/bow.tres`). A conferência sobre cinza, com a M4 e o parado ao lado, está em
  `magico_reverencia_conferencia.png`.
- **Conferido a olho:**
  - 1: tirando a cartola e começando a curvar, sorriso teatral;
  - 2: reverência funda, a cartola na altura do joelho, o outro braço para trás com a capa, olhos fechados;
  - 3: em pé, com medo, as mãos erguidas e a boca aberta;
  - 4: encolhido, os dentes batendo e os punhos fechados;
  - sem efeitos, varinha ou duplicatas; identidade e paleta iguais às da M2 a M5.

**No jogo** (`magician.gd`):
- **`bow`:** desenho 1 até 0,3 s (`BOW_DEEP`) e 2 depois.
- **`scared`:** 3 e 4 alternando a 12 por segundo (`SCARED_FPS`).
- **Tempo na pose:** só conta com ele à vista. Assim, quando ele reaparece da caixa ("Ta-dá!"), a reverência
  recomeça do 1.
- **Saída da reverência:** ao passar para o parado ou a varinha, o 1 fica 0,1 s (`BOW_SETTLE`), recolocando
  a cartola (o mesmo desenho, ao contrário).
  - Sem isso, a primeira rodada do piloto saltava 137 px no alto do desenho, da reverência funda para a
    varinha erguida.
  - Com ele, a maior troca da entrada da fase 2 é de 91 px (1 → 2, o próprio curvar).
- **Fim do boneco por código:** não há mais pose em boneco; ele sobra só para os olhos no Blackout.
- **Sem mudança:** os ataques, as caixas de dano, `hand_position`, o `vanish` (o sumir tem prioridade sobre a
  reverência e o medo), o coop e o save.

**Piloto a 60 quadros por segundo** (`-- magico_reverencia <pasta> [virado|fim]`), a luta de verdade:
- **Entrada da fase 2, nos dois lados** (a segunda depois de um Teleporte, olhando para a direita): 1 (18
  quadros), 2 (35), 1 (7) e varinha. Os pés ficam parados.
- **Jogo das Três Caixas, duas vezes, até ele reaparecer:**
  - **Ida:** 1 (18), 2 (9) e o sumir 1 → 4.
  - **Na caixa:** 376 quadros sumido.
  - **Reaparece:** "Ta-dá!", com 1 (17), 2 (37), 1 (7) e o parado.
  - Isto fecha o trecho da volta que faltou na M5.
- **Entrada da fase 3:** o medo alterna 3 e 4 em blocos de 4 a 6 quadros por 0,6 s, depois some no escuro.
  - Olhando para a esquerda, como na luta, e para a direita (virado à mão no roteiro `virado`, porque na
    luta ele chega olhando para a esquerda).
  - O alto do desenho salta 16 px entre o 3 e o 4 (o tremor).
- **Derrota ainda pequeno (`fim`):** medo por 0,6 s e depois o sumir 1 → 4.
- **Trocas para o boneco:** 0.
- **Escala com os jogadores:** `piloto_m6_arena_reverencia.png` e `piloto_m6_arena_medo.png`.
- **Arquivos:** `docs/medidas/magico/m6_*` (os CSVs e o resumo, com a rodada antes do ajuste da saída); a
  grade em `piloto_m6_reverencia.png`.
- **Bateria:** 9 testes locais com 0 falhas (com o `test_magician`), e o online normal e com rede ruim ok.

**Limitações (registradas, sem aprovação humana):**
- **Deslize da reverência nas Três Caixas (defeito real, maior do que a M5 dizia):** o ataque leva o nó
  até a caixa durante a reverência.
  - Com o desenho da reverência à vista, ele **desliza 885 a 912 px** em uns 0,45 s.
  - Depois disso, desliza mais uns 93 px sumindo.
  - Os "95 px" registrados na M5 eram só o trecho sumindo; naquele piloto a reverência ainda era o boneco,
    que deslizava igual.
  - Não mexi no ataque para esconder isso.
  - O conserto é uma decisão de jogo, a do marco de gameplay seguinte: ou ele some no lugar e reaparece
    dentro da caixa, ou um pedido de andar.
  - **Corrigido na revisão do marco (04/10):** ele some no lugar e só muda de lugar invisível, e na
    revelação desenrola da capa (ver o DESIGN.md).
- **Reaparecer da caixa:** ele aparece de uma vez, já na reverência. O `vanish` vai de 1 a 0 num quadro, já no
  ataque. O desenrolar da M5 não toca ali.
- **Cabeça e sapatos:** a cabeça sai uns 7% maior que a da M4, e os sapatos uns 3% menores.
- **Saída da reverência:** ainda é um corte de pose (1 → varinha). O desenho 1 só encurta o salto.
- **Aprovação:** nenhuma aprovação visual humana.

## Pedido M7: mãos gigantes do Zaratan (entregue em 04/10; no jogo, ver "Resultado da M7")

**Uso no jogo:** as duas mãos do mágico gigante (fase 3), hoje desenhadas por código (`giant_hand.gd`).
- **Uma folha só:** a mão da ESQUERDA da tela (a `LeftHand`, com o polegar para o centro do palco). A da
  direita é a mesma, espelhada.
- **Quem escolhe o desenho:** o `closed`, de 0 (aberta) a 1 (punho):
  - desenho 1 até 0,17;
  - 2 até 0,5;
  - 3 até 0,83;
  - 4 depois.
- **Mãos que Agarram** (`grab_hands.gd`):
  - a mão vai aberta até em cima do jogador em 0,6 s e treme 0,15 s;
  - desce fechando em 0,15 s (1 → 4);
  - fica 0,35 s no chão em punho;
  - sobe abrindo em 0,5 s (4 → 1).
- **Cartas Gigantes** (`giant_cards.gd`): puxa para trás fechada (4) por 0,4 s e abre de uma vez (1) ao
  jogar o leque.
- **Fica no código:**
  - a sombra no chão, a poeira e a transparência (`presence`) ao sumir no escuro;
  - o balanço parado;
  - a área de dano (220 × 220, centrada 60 px abaixo do meio da mão, ligada só no golpe).

**Grade e pivôs:**
- Canvas de 2048 × 640, 4 × 1 células de 512 × 640.
- **Pivô (o nó da mão no jogo):** o meio das costas da mão, no centro da linha dos nós dos dedos, em
  (256, 260) em todas as células.
- **Punho da manga** (roxo, com o botão dourado): no mesmo lugar nas 4, o alto em y ~84.
- **Tamanho:** a mão aberta tem uns 460 px do alto do punho às pontas dos dedos.
- **Área de dano na célula** (escala de 1,6 da célula para o jogo): de x 80 a 432 e de y 180 a 532. O punho
  fechado precisa cobrir essa área quase toda, para o dano não sair de onde não há mão.
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/magico/magico_maos_candidata.png`.

**Plano de conferência:**
1. Normalizar com a escala única pela largura do punho da manga (a identidade) e o pivô.
2. Ligar pelo `closed`, nos limites acima, espelhando para a `RightHand`.
3. **Piloto a 60 quadros por segundo** com as Mãos que Agarram e as Cartas Gigantes de verdade. Conferir:
   - a sequência 1 → 4 → 1;
   - a área de dano dentro do desenho;
   - as duas mãos;
   - o sumir no escuro;
   - a escala com os jogadores.
4. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_maos_candidata.png (replace if it exists).

References (read from the project): docs/referencias/pecas/magico/pecas/gigante_mao_aberta.png and docs/referencias/pecas/magico/pecas/gigante_mao_fechada.png = the APPROVED giant white-gloved hand of THE GREAT ZARATAN (open and fist); docs/referencias/pecas/magico/magico_folha.png = the approved style sheet. Copy EXACTLY this glove, its cuff (dark purple sleeve with the gold button), its proportions and its ink style.

NO EFFECTS: no dust, no motion lines, no shadow, no sparkles, no cards, no face on the hand.

SIZE AND POSITION: canvas exactly 2048 x 640, grid of 4 columns x 1 row, cells of 512 x 640, one frame per cell, left to right. ONE giant LEFT-of-screen hand seen from the BACK of the glove: fingers pointing DOWN (it grabs downward), cuff at the TOP, the thumb on the RIGHT side of the image. Open hand about 460 px tall from the top of the cuff to the fingertips. In EVERY cell: the middle of the back of the hand (the center of the knuckle line) exactly at x = 256, y = 260, and the cuff in the same place (its top at about y = 84). The fist in frame 4 must fill roughly the area x 80 to 432, y 180 to 532. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 640, keep the same 4 x 1 layout with cells of the same 4:5 shape and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no text, no ground.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 4 frames, the hand closing step by step (same glove, same cuff, same size):
1 OPEN, hovering: fingers spread wide and pointing down, slightly curved like claws, ready to grab;
2 the fingers start to curl in, the thumb moves toward the palm;
3 almost closed: fingers bent, knuckles forward, the thumb across;
4 tight FIST, knuckles down, ready to slam the floor.
```

### Resultado da M7 (04/10): mãos gigantes no jogo, conferidas nas Mãos que Agarram, nas Cartas Gigantes e na entrada da fase 3

**Entrega:** `magico_maos_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica intacta, e o
original está guardado em `originais/magico_maos_codex_2205x713.png`.
- **Formato:** veio em 2205 × 713 (3,09:1, células nominais de 551 × 713). A mão 1 atravessa a divisão em
  551.

**Revisão:**
- **Separação:** por peças inteiras, sem cortar pela grade nem amputar o polegar. Saíram 4 peças, 0 px
  soltos, 0 buracos.
- **Identidade:**
  - a manga mede 278, 279, 282 e 297 px de largura;
  - o botão dourado mede 798, 729, 799 e 988 px de área.
- **Desvio aceito:** no punho (4) a manga e o botão saem uns 7 a 11% maiores. As peças aprovadas da M1 fazem o
  mesmo: o botão do punho tem 257 px de área contra 217 na mão aberta, como se o punho viesse para a frente.
  Não usei escala por quadro.
- **Escala:** única, de 0,891 (a mão aberta fica com 472 px de altura na célula; no jogo, 290, como a do
  código).
- **Âncora:** o botão dourado da manga no mesmo ponto das 4. É rígido e fica no pulso, então o pulso não se
  mexe e só os dedos fecham.
- **Células de 640 × 640** (desvio motivado): a mão aberta tem 515 px de largura nessa escala e não cabe em
  512 com margem.
- **Pivô (o nó GiantHand) em (315, 282):** no meio do punho fechado e 175 px acima do fundo dele, como o
  punho do código.
  - O pivô pedido (256, 260) ficaria no lugar errado para este desenho. Com o pivô no meio do punho, ele
    afundaria ~75 px no chão no golpe.
- **Área de dano** (220 × 220 no jogo, só a parte acima do chão) que cai no desenho, na célula: 73, 79, 81 e
  82% nos quadros 1 a 4. As sobras são os cantos de um quadrado em volta de um punho redondo.
- **Conferido sobre claro, escuro e magenta** (`magico_maos_conferencia.png`): sem halo, sem buraco, sem
  efeito.

**No jogo** (`giant_hand.gd`):
- **O desenho sai do `closed`:** 1 até 0,17, 2 até 0,5, 3 até 0,83 e 4 depois.
- **Lados:** a folha é a `LeftHand`; a `RightHand` é espelhada.
- **Sem mudança:** a transparência (`presence`), a sombra, a poeira, o balanço, a área de dano e os tempos das
  Mãos que Agarram e das Cartas Gigantes. A mão por código saiu.

**Defeito achado no piloto e corrigido** (`grab_hands.gd`):
- **O que acontecia:** as duas agarradas da mesma mão se sobrepõem 0,05 s (a 2ª começa aos 1,5 s e a 1ª sai
  do chão aos 1,55 s). A 2ª puxava a mão do chão para perto do descanso, já aberta, num quadro (um pulo de
  298 px). Nesses 3 quadros, o golpe da 1ª continuava ligado na mão aberta no ar: dano injusto. Já acontecia
  com a mão por código.
- **Correção:**
  - cada mão segue só a agarrada mais nova;
  - a nova sai de onde a mão está, abrindo aos poucos;
  - os horários das agarradas e as durações de cada fase não mudaram.
  - A 1ª agarrada de cada mão perde os últimos 0,05 s no chão. A subida dela nunca aparecia.

**Piloto a 60 quadros por segundo** (`-- magico_maos`), a luta de verdade:
- **Entrada da fase 3:** as mãos abertas (1) surgem do escuro.
- **Mãos que Agarram, duas vezes, nas duas mãos:** 1 → 2 → 3 → 4 (golpe) → 3 → 2 → 1 entre as agarradas.
  - O golpe só fica ligado nos desenhos 3 e 4 (antes, 3 quadros no desenho 1).
  - A área de dano acima do chão cai em média 77% no desenho (mínimo de 62%, no começo do golpe).
  - O maior passo da mão num quadro é de 75,6 px (a descida do golpe; antes, 298,5).
- **Cartas Gigantes:** punho (4) puxando para trás e 1 ao jogar ("abre de uma vez", como pedido).
- **Espelho:** certo nas duas mãos.
- **Escala com os jogadores:** `piloto_m7_golpe.png`.
- **Teste local:** com o `grab_hands.gd` antigo, o teste novo falha (6 quadros de golpe com a mão aberta e um
  pulo de 402 px); com o novo, passa.

**Rede:** uma bateria falhou com rede ruim (logs em `docs/medidas/magico/logs_m7/falha_ruim_bateria/`):
- **No cliente, o bônus da caixa certa não apareceu.** Causa: a vida do chefão ia por um canal que perde
  mensagens e só era enviada quando mudava, então uma perda deixava a barra do cliente errada até o próximo
  dano. Isso se repetiu numa das duas rodadas seguintes.
  - **Correção** (`boss_sync.gd`): o host reenvia a vida atual a cada 0,5 s.
  - Depois disso, 3 rodadas seguidas com rede ruim passaram sem falha.
- **No mesmo log, o Leque no cliente não teve contato nem parry.** Não se repetiu em 5 rodadas seguintes.
  - A causa não ficou clara.
  - O teste agora imprime a posição e o estado do jogador do cliente no começo dessa medida.

**Limitações:**
- O punho sai uns 7–11% maior (o mesmo da M1).
- A área de dano é um quadrado e o desenho é redondo: 62 a 82% de cobertura acima do chão.
- As Cartas Gigantes abrem de uma vez (4 → 1), como o ataque pede.
- A falha intermitente do Leque no cliente com rede ruim ficou sem explicação.
- Nenhuma aprovação visual humana.

**Bateria final:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok
(`logs_m7/bateria_depois.log`).

## Pedido M8: rosto do mágico gigante (entregue em 04/10; no jogo, ver "Resultado da M8")

**Uso no jogo:** a cabeça do mágico gigante (fase 3), hoje desenhada por código (`giant.gd`).
- A cartola continua uma peça separada (a `gigante_cartola.png` da M1), girada pelo `hat_tilt` em volta da
  aba (170 px de jogo acima do meio da cabeça). O rosto vem sem cartola.
- **O código continua fazendo:**
  - o balanço (±8 px);
  - o clarão ao levar tiro;
  - o encolher para dentro da cartola no fim (`shrink`).
- **Quem escolhe o desenho:**
  - 2 com `laugh` ≥ 0,5: nas Mãos que Agarram, 0,4 s a cada 1,2 s; na Cartola Despejando, durante os 3 s da
    varrida; no fim da entrada da fase 3;
  - 3 por ~0,25 s depois de levar tiro, no máximo uma vez por segundo, para não ficar bravo o tempo todo
    debaixo de tiro;
  - 4 na derrota, enquanto encolhe;
  - 1 no resto.

**Grade e pivôs:**
- Canvas de 2560 × 640, 4 × 1 células de 640 × 640.
- **Pivô (o nó Giant):** o meio da cabeça, em (320, 300) em todas as células.
- **Rosto de FRENTE**, para o meio do palco, com a identidade da cabeça aprovada da M1 (cabelo preto
  penteado para trás, orelhas, nariz comprido e pontudo, bigode de pontas enroladas, cavanhaque).
- **Alturas:**
  - o alto do cabelo em y ~72 (a aba da cartola cobre acima de y ~96);
  - a ponta do cavanhaque em y ~600;
  - as pontas do bigode entre x ~80 e 560.
- **Área de dano da cabeça** (280 × 360 no jogo, escala de 1,2 na célula): de x 152 a 488 e de y 84 a 516. O
  rosto precisa cobrir essa área.
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/magico/magico_rosto_candidata.png`.

**Plano de conferência:**
1. Normalizar com a escala única pela largura do rosto na linha dos olhos (a identidade) e o pivô.
2. Ligar pelos estados acima e pôr a cartola da M1 como peça (`hat_tilt`).
3. **Piloto a 60 quadros por segundo** com a entrada da fase 3, as Mãos que Agarram, a Cartola Despejando, as
   Cartas Gigantes e a derrota. Conferir:
   - as trocas de desenho;
   - a cartola no lugar e girando;
   - a área de dano dentro do rosto;
   - o encolher;
   - a escala com os jogadores.
4. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_rosto_candidata.png (replace if it exists).

References (read from the project): docs/referencias/pecas/magico/pecas/gigante_cabeca.png = the APPROVED giant head of THE GREAT ZARATAN (slicked-back black hair, ears, long pointed nose, huge curled moustache, goatee); docs/referencias/pecas/magico/pecas/gigante_cartola.png = his top hat (it is a SEPARATE piece in the game: do NOT draw the hat); docs/referencias/pecas/magico/magico_folha.png = the approved style sheet. Copy EXACTLY this face, its proportions and its ink style.

NO EFFECTS: no hat, no hands, no smoke, no sparkles, no stars, no motion lines, no tears flying away, no text.

SIZE AND POSITION: canvas exactly 2560 x 640, grid of 4 columns x 1 row, cells of 640 x 640, one frame per cell, left to right. The giant head seen from the FRONT (facing the viewer, symmetrical), only the head (no neck, no body). In EVERY cell the middle of the head is exactly at x = 320, y = 300; the top of the hair at about y = 72 (the hat will cover the top of the head down to about y = 96); the tip of the goatee at about y = 600; the moustache tips between about x = 80 and x = 560. The face must fill the area x 152 to 488, y 84 to 516. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2560 x 640, keep the same 4 x 1 layout with SQUARE cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, full opacity inside), clean edges, no grid lines, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 4 frames, the SAME head (same size, same position), a DIFFERENT expression in each:
1 SLY SMILE: grinning down at the players, eyebrows sharp, eyes glinting;
2 BIG LAUGH: mouth wide open laughing, eyes squeezed shut, moustache lifted;
3 HURT AND ANGRY: just got shot, teeth clenched, one eye squinting, brows furrowed down;
4 DIZZY, DEFEATED: spiral eyes, tongue out, moustache drooping.
```

### Resultado da M8 (04/10): rosto do gigante no jogo, conferido na fase 3 inteira

**Entrega:** `magico_rosto_candidata.png`, gerada pelo Codex, que não a aprovou. A candidata fica intacta, e o
original está guardado em `originais/magico_rosto_codex_1983x793.png`.
- **Formato:** veio em 1983 × 793, não 2560 × 640 (células nominais de 496 × 793, margem direita de 16 px).

**Revisão:**
- **Separação:** por peças inteiras. Saíram 4 peças, 0 px soltos e 1 buraco isolado de 1 px no quadro 2.
- **Identidade:**
  - largura nas orelhas, na linha dos olhos: 370, 380, 379 e 374 px (~3% de variação);
  - linha das orelhas igual nas 4;
  - alturas de 570 a 577 (as diferenças são da expressão: a boca aberta e a língua).
- **Escala:** única, de 0,921 (do cabelo ao cavanhaque: 528 px na célula, 440 no jogo, como o rosto do
  código).
- **Montagem:**
  - células de 640 × 640;
  - o meio das orelhas em x 320 e o alto do cabelo em y 72;
  - o pivô (o meio da cabeça) em (320, 300);
  - o cavanhaque termina entre y 597 e 603.
- **Conferido sobre claro, escuro e magenta, com a cartola da M1 no lugar** (`magico_rosto_conferencia.png`):
  - sem halo e sem buraco;
  - a cartola assenta no alto do cabelo;
  - mesma identidade da M1: cabelo penteado para trás, orelhas, nariz pontudo, bigode enrolado, cavanhaque;
  - expressões: 1 sorriso maroto, 2 gargalhada de olhos fechados, 3 bravo com um olho apertado e os dentes
    cerrados, 4 tonto com olhos em espiral e a língua de fora.
- **Área de dano da cabeça** (280 × 360 no jogo, sem mudança) dentro do desenho: 73 a 77%. Os cantos de
  baixo, ao lado do queixo pontudo, ficam vazios; essa sobra favorece quem atira.

**No jogo** (`giant.gd`):
- **O rosto** é escolhido pelos estados do plano:
  - 4 desde a derrota e enquanto encolhe;
  - 2 com `laugh` >= 0,5;
  - 3 por 0,25 s depois de levar tiro, no máximo uma vez por segundo;
  - 1 no resto.
- **A cartola é a peça da M1** (`giant_hat.png`, a aba com 400 px de jogo), girada pelo `hat_tilt` em volta do
  meio da aba, 170 px acima do meio da cabeça.
- **Continuam por código:** o balanço, o clarão do tiro e o encolher.
- **O chefão avisa o gigante na derrota** (`defeated`). Na primeira rodada ele ficou sorrindo 81 quadros
  antes de o encolher começar.
- **Sem mudança:** os ataques, as mãos, a área de dano e o `hat_mouth`. A cartola desenhada é mais baixa que
  a do código, mas nenhum ataque usa a boca da cartola: as tralhas da Cartola Despejando caem do alto da tela.

**Piloto a 60 quadros por segundo** (`-- magico_rosto`), a luta de verdade:
- **Entrada da fase 3:** sorriso, e gargalhada no fim.
- **Mãos que Agarram:** gargalhada ~0,4 s a cada 1,2 s.
- **Cartola Despejando:** gargalhada durante a varrida, e a cartola gira até 0,6 rad presa na aba.
- **Cartas Gigantes, levando tiro a cada 0,2 s:** bravo 16 quadros uma vez por segundo (5 vezes).
- **Derrota:** tonto desde a derrota até sumir encolhendo.
- **Cartola:** 0,00 px fora do lugar em relação à cabeça (a primeira medida dava 10,9 px porque lia o
  `shrink` um quadro atrasado).
- **Fotos:** `piloto_m8_cartola.png` (escala com os jogadores e as mãos da M7) e `piloto_m8_rosto.png`.
- **Testes** (`test_magician`): a gargalhada, o bravo uma vez por segundo e o tonto na derrota.

**Limitações:**
- A cartola é mais baixa que a do código.
- Os cantos de baixo da área de dano ficam fora do rosto (73–77% coberta).
- Há um buraco isolado de 1 px no quadro 2.
- A falha rara do Leque no cliente (rede ruim, sem contato nem parry; logs da M7) não apareceu nesta
  bateria, o que não a resolve. Depois da M8 achei uma causa provável no próprio teste (diário: "Falha rara
  do Leque no cliente").
- Nenhuma aprovação visual humana.

**Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok (`logs_m8/bateria_m8.log`,
com os logs do host e do cliente da rodada com rede ruim).

## Pedido E7: o totem dos Malabaristas (entregue em 04/10; no jogo, ver "Resultado da E7")

**Por quê:** no teste em dupla o usuário achou feio o totem (fase 2), que ainda é o boneco de código.

**Decisão do usuário (04/10):** no totem os irmãos ficam **menores** que nas outras folhas, para o totem caber
por baixo dos pedestais pendurados. O Totem Andante continua igual: ficar no pedestal desvia. Desenhados no
tamanho normal (uns 230 px no jogo cada), os dois juntos passariam de 340 px; o pedestal fica a 240 px do chão.

**Uma folha só, com o totem inteiro** (os dois irmãos num desenho): o Tico embaixo (listras vermelhas) e o Teco
nos ombros (listras azuis).
- Quando a base for o Teco, o jogo usa a mesma folha com as cores trocadas (vermelho ↔ azul, como o
  `recolor_twin.gd`, nos dois sentidos).
- O clarão do tiro passa a valer para o totem inteiro. As áreas de dano de cada irmão continuam por código.
- As estrelas da tontura continuam por código.

**Uso no jogo:**
- 1 e 2: parado (Claves em Linha, Boliche, entre os ataques);
- 3 a 6: andando (Totem Andante);
- 7 e 8: o de cima arremessa (preparo e soltura).

**Grade e pivôs:**
- Canvas de 2048 × 1024, 4 × 2 células de 512 × 512.
- Olhando para a DIREITA (o jogo espelha).
- As solas do de baixo em y 486, com o meio dos pés em x 256.
- O alto do cabelo do de cima por volta de y 40. O totem inteiro mede uns 440 px, como um irmão sozinho nas
  outras folhas.
- Os dois do mesmo tamanho entre si: cabeça de uns 125 px, nariz de uns 27 × 19 px.
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/malabaristas/totem_candidata.png`.

**Plano de conferência (antes de integrar):**
1. Normalizar com uma escala única pelo nariz e pelas solas.
2. Medir as alturas e conferir que o totem cabe por baixo do pedestal, com folga para quem está em cima.
3. Fazer a versão com as cores trocadas.
4. Ajustar `SHOULDER` e as alturas das áreas de dano ao desenho.
5. **Piloto a 60 quadros por segundo:** a entrada do totem, o Totem Andante com um jogador no pedestal (sem
   tomar dano), as Claves em Linha, o Boliche, o tonto no totem e a saída para o monociclo.
6. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

We are continuing the animation work for "Respeitável Público", a 2D Godot game about a haunted 1930s circus (Cuphead-like). You make the PNG sheets; Claude reviews, cuts and puts them in the game. One sheet per request.

Create ONE animation sheet. Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/totem_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/malabaristas/tico_malabares.png, tico_tonto.png, tico_salto.png = APPROVED sheets of TICO (red-and-cream stripes); docs/referencias/pecas/malabaristas/teco_malabares.png = his twin TECO (same drawing, blue-and-cream stripes). Copy EXACTLY these two characters (round head, slicked black hair, big curly black mustache, big glossy red ball nose, cream ruffle collar, striped one-piece leotard with gold buttons, white gloves, big brown-and-cream shoes; same ink style).
- docs/referencias/pecas/malabaristas/malabaristas_folha.png = the approved design sheet.
Do NOT use docs/referencias/chefao_malabaristas.png (old concept).

THE TOTEM: the two brothers as ONE drawing in every cell. TICO (RED stripes) is at the BOTTOM, standing with knees a bit bent; TECO (BLUE stripes) rides on his shoulders, sitting astride his neck with his legs hanging down in front of Tico's chest, and Tico holds Teco's shins with both gloves. Teco's hands are free (he is the one who juggles and throws).

KEEP THE COLORS EXACTLY: the stripe red is a darker, slightly muted red; the stripe blue is the blue of teco_malabares.png; the noses and tongues are a brighter, more saturated red with a white shine, each fully closed by the dark outline.

NO EXTRA THINGS: no balls, no clubs, no pins, no props in the hands, no stars, no motion trails, no speed lines, no dust (the game draws all of these by itself).

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, left to right, top row first. Both brothers facing RIGHT. IMPORTANT, SMALLER THAN THE REFERENCES: the WHOLE totem (both brothers) is about 440 px tall, from the soles of Tico's shoes on the floor line at y = 486 to the top of Teco's hair at about y = 40, so each brother is drawn at about 60% of the reference size (head about 125 px from hair to chin, ball nose about 27 x 19 px), and both brothers are the SAME size as each other. The middle of Tico's feet at x = 256 in every cell; his soles on y = 486 in every cell (in the walking frames the foot that is down stays on y = 486). At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels, full opacity inside the drawing), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference sheets.

Animation, 8 frames, a DIFFERENT, exaggerated expression on BOTH faces in EVERY frame (Tico straining under the weight, Teco cocky and showing off):
1 STANDING A: Tico braced, legs apart, holding Teco's shins; Teco sitting tall, both hands raised at head height as if juggling;
2 STANDING B: same pose with a small bounce (Tico's knees a little more bent, Teco about 6 px lower, hands at a different height);
3 WALK 1: Tico steps forward with his right foot lifted, Teco leaning back for balance;
4 WALK 2: Tico's feet passing each other, both bodies slightly higher;
5 WALK 3: Tico steps forward with his left foot lifted, Teco leaning forward;
6 WALK 4: Tico's feet passing again, both bodies slightly higher (frames 3 to 6 loop as a walk);
7 THROW WIND-UP: Tico braced still; Teco twists back with his throwing arm pulled far back behind his head (empty glove);
8 THROW RELEASE: Teco's arm whipped forward and out to the right, open glove, as if he just let go of a club; Tico wobbling under him.
```

### Revisão e plano da E7 (04/10, antes de integrar)

**Entrega:** `totem_candidata.png`, gerada pelo Codex numa chamada, que não a aprovou. A candidata fica intacta, e o
original está guardado em `originais/totem_codex_1774x887.png`.
- **Formato:** veio em 1774 × 887 (2:1, células nominais de 443,5), não 2048 × 1024.
- **Na grade nominal:** a 1ª fila passa da linha 443,5 em 3–7 px e as margens ficam abaixo de 24. Por isso o
  corte é pelas 8 peças inteiras, com vãos de 7 a 15 px, e não pela grade (que cortaria os pés).

**Revisão:**
- **Leitura:** boa. O Tico (vermelho) está embaixo e o Teco (azul) em cima, nos ombros, os dois olhando para a
  direita. As 8 caras do par são diferentes.
- **Desvios aceitos, com motivo:**
  - **Cabeça de cima um pouco maior.** O nariz de cima mede 30–34 × 21–26 px e o de baixo 29–32 × 16–21 (uns 8%
    linear). Os dois continuam reconhecíveis como os mesmos gêmeos e menores que nas outras folhas, que era a
    decisão do usuário. Não uso escala por irmão nem deformação.
  - **O Tico segura os sapatos do Teco na frente do peito, não as canelas.** A pegada lê do mesmo jeito.
  - **No quadro 8 os dois braços do Teco vêm para a frente.** A soltura lê bem.
  - **Nos quadros 7 e 8 o Tico também dá um passo.** No jogo o arremesso pode acontecer andando, e esses
    quadros servem para isso.
- **Não certificado pela candidata:** o tamanho pedido (cabeça de 125 px, nariz de 27 × 19) e a passada real
  dos quadros 3 a 6. O piloto confere a passada.

**Normalização** (`docs/medidas/malabaristas/e7_normalizar.gd`; resultado em `malabaristas/totem.png`, irmã
da candidata):
- **Escala única** de 1,019 para os 8: o quadro 1, em pé, fica com 440 px.
- **Âncora "pés"**, como as outras folhas dos irmãos: a sola mais baixa em y 486 e o meio das solas em x 256.
  O nariz de baixo fica entre x 314 e 335 nas 8 células (o Tico firme). O que se mexe nos quadros 7–8 é o
  Teco se inclinando.
- **Margem mínima:** 17 px (quadro 8, à direita). Nada cruza a célula.
- **Alpha:** fiapos com alpha ≤ 25 a mais de 3 px do desenho foram zerados (594 a 1206 por quadro); o resto
  ficou como veio.
- **Conferido sobre claro, escuro e magenta:** sem halo.
- **Altura no jogo** (célula 440 → 220): o quadro mais alto (3) dá 225 px, abaixo dos 240 do pedestal.

**Plano de integração:**
- **Folhas:**
  - `totem.png` (o Tico embaixo);
  - `totem_teco.png`, com as cores trocadas (vermelho ↔ azul), para quando a base for o Teco. Sai do
    `recolor_twin.gd` com uma opção nova de troca, que preserva nariz, língua, pele, luvas e sapatos.
- **Quem desenha:** o irmão de baixo desenha o totem inteiro. O de cima só fica com as áreas de tiro e de
  dano, as estrelas da tontura e as bolinhas; o clarão do tiro dele acende o desenho inteiro.
- **Desenho por momento:**
  - parado: 1 e 2 alternando;
  - andando: 3 a 6 a 12 por segundo (uma volta em 0,33 s, perto dos 590 px/s do Totem Andante);
  - o de cima arremessando: 7 (preparo) e 8 (soltura), mesmo andando;
  - o Boliche (a base abaixada) usa o 2, com os joelhos mais dobrados.
  - O giro das entradas continua com o salto (E5) no tamanho normal. Uma nuvem de poeira na hora do encaixe
    esconde a troca de tamanho, na chegada do totem e na saída para o monociclo.
- **Alturas do totem, medidas no desenho** (as do monociclo não mudam):
  - `TOTEM_SHOULDER` 115 (era 150);
  - área de dano da base com 115 de altura, e a do de cima com 97 (até 212);
  - área de tiro da base de 0 a 120, e a do de cima de 115 a 222.
  - O pedestal (240) continua seguro.
- **Cabeça, mãos e bolinhas:**
  - a cabeça de cada um (a bola de cura e as estrelas) sai de uma tabela por desenho, medida pelo nariz;
  - a mão que joga (as claves do Totem Andante) sai da luva da soltura;
  - as bolinhas do parado fazem um arco entre as duas luvas do de cima.
- **Piloto a 60 quadros por segundo:**
  - a entrada do totem;
  - o Totem Andante com um jogador no pedestal (sem dano);
  - as Claves em Linha;
  - o Boliche;
  - o tonto no totem com a cura;
  - a saída para o monociclo;
  - com o Tico e com o Teco de base (os dois espelhos);
  - conferir: as trocas de desenho, a cabeça e a bola de cura, a mão e a clave (≤ 15 px) e as áreas.
- **Depois:** os testes e a bateria.

### Resultado da E7 (04/10): totem desenhado no jogo, pilotado com o Tico e com o Teco de base

**Folhas:**
- `malabaristas/totem.png`: a candidata normalizada (plano acima). A candidata e o original ficam intactos.
- `malabaristas/totem_teco.png`: as cores trocadas, por `tools/recolor_twin.gd ... troca`. 10 022 px vermelhos
  viraram azuis (mais 3 891 de beirada) e 12 947 azuis viraram vermelhos. Nariz, língua, pele, luvas e sapatos
  ficaram como estavam. Conferência: `totem_teco_conferencia.png`.
- Recortadas em `bosses/jugglers/art/totem/` (`tico_base.tres` e `teco_base.tres`).

**Escala no jogo:** 0,477 (o quadro 1 tem 210 px).
- **Desvio da primeira escolha, com motivo.** Com 0,5 (220 px) o quadro mais alto entrava 9 px na tábua
  pendurada, que fica de 216 a 240 px do chão. Com 0,477 o mais alto (os quadros 3 e 4) mede 214,0 px e fica
  2 px abaixo dela.
- Os irmãos do totem ficam com uns 46% do tamanho que têm nas folhas normais.

**No jogo** (`juggler.gd`, `jugglers_boss.gd`):
- **Quem desenha:** a base desenha o totem inteiro (`totem_role`). O de cima fica com as áreas de tiro e de
  dano, as estrelas da tontura e três bolinhas em arco entre as luvas dele no parado. O tiro no de cima acende
  o desenho inteiro.
- **Desenho por momento:**
  - parado: 1 e 2 a 3 por segundo;
  - Boliche: o 2 (a base abaixada);
  - andando: 3 a 6, um desenho a cada 44 px andados (pela posição);
  - o de cima arremessando parado: 7 até a clave nascer e 8 desde esse quadro.
  - Andando, as pernas continuam na caminhada: os desenhos 7 e 8 parariam as pernas 0,3 s a ~590 px/s.
- **Alturas do totem:**
  - `TOTEM_SHOULDER` 110;
  - área de dano da base 110, e a do de cima 92 (até 202);
  - área de tiro da base de 0 a 115, e a do de cima de 110 a 212.
  - Antes, com o boneco: 150 + 80 (até 230).
  - O monociclo não mudou (continua o boneco de código, com `SHOULDER` 150).
- **Cabeça e mão:** saem de tabelas por desenho, medidas no nariz e nas luvas da folha normalizada.

**Defeitos achados no piloto e corrigidos:**
1. **O Totem Andante apagava o arremesso.** Ele chamava `place_group` a cada quadro, e isso voltava o de cima
   para "sentado" no começo de cada quadro. A clave nascia na mão do parado e a soltura aparecia 1 quadro. Agora
   `place_group(x, false)` só move.
2. **A soltura era decidida pelo tempo da pose,** contado no desenho, e a clave nasce na física. Agora o
   ataque marca `throw_released` na hora em que cria a clave.
3. **Claves em Linha:** a clave nascia direto na faixa, até 149 px longe da mão desenhada. Agora sai da mão e
   entra na faixa em 0,1 s. As faixas, a velocidade e os tempos não mudaram.
4. **Caminhada:** com o ritmo fixo de 12 por segundo o pé deslizava ~49 px por desenho e mais nas pontas (o
   Totem Andante acelera e freia). Agora o desenho avança pela distância andada.
5. **A entrada e a saída do totem trocam de tamanho** (o salto continua com o desenho normal). Uma nuvem de
   poeira na altura dos ombros esconde a troca na chegada; na saída para o monociclo, uma em cada irmão.

**Piloto a 60 quadros por segundo** (`-- malabaristas_totem <pasta> [teco]`), a luta de verdade, com o
Tico e com o Teco de base (os mesmos números nos dois):
- **Entrada do totem:** o salto (66 quadros) e depois 2 → 1 → 2.
- **Totem Andante:**
  - um jogador parado na tábua, sem invencibilidade: vida 3 → 3 nos dois pilotos;
  - fotos `piloto_e7_tabua_tico.png` e `piloto_e7_tabua_teco.png`;
  - a caminhada passa por 3–6 com 3 a 11 quadros por desenho (mais devagar nas pontas).
- **Claves:** em todos os arremessos (Totem Andante e Claves em Linha), a clave nasce na luva do desenho na tela
  (0,0 px).
- **Boliche:** a bola sai com a base no desenho 2.
- **Tonto no totem:** a bola de cura chega à cabeça do desenho (15,1 px no último quadro do voo, em movimento).
- **Saída para o monociclo:** o braço esticado (8) apontando o monociclo, depois o salto.
- **Logs:** `docs/medidas/malabaristas/e7_logs/` (inclui a 1ª rodada e a do ritmo fixo).
- **CSV:** `e7_piloto_base_teco.csv`.
- **Grades:** `piloto_e7_totem_tico.png` e `piloto_e7_totem_teco.png`.
- **Teste** (`test_jugglers`):
  - a base desenha e o de cima não;
  - a folha é a do irmão que está embaixo;
  - o desenho e as áreas ficam abaixo da tábua;
  - a clave nasce na luva do desenho 8.
- A bateria completa passou.

**Limitações:**
- A cabeça do Teco sai ~8% maior que a do Tico.
- O Tico segura os sapatos, não as canelas.
- Quatro desenhos de caminhada para ~590 px/s: avançando pela distância, cada desenho dura de 3 a 11
  quadros, e ainda há algum deslize entre um desenho e outro.
- Andando, o arremesso não aparece (a clave nasce na luva da caminhada).
- A troca de tamanho na entrada e na saída fica atrás da nuvem.
- O tonto no totem não tem cara de tonto (só as estrelas).
- Nenhuma aprovação visual humana.

## Pedido E8: os Malabaristas no monociclo (pronto para colar; uma folha)

**Por quê:** a fase 3 ("Monociclo Gigante") é o último lugar dos Malabaristas ainda com o boneco de código (o
de baixo montado no selim, o de cima nos ombros). Com o totem desenhado (E7), é a diferença mais visível da luta.

**Uso no jogo:** o monociclo continua desenhado por código, e só a roda machuca.
- **Medidas do monociclo:** selim a 380 px do chão; roda com 110 px de raio, até 220 do chão. A tábua pendurada
  (216 a 240) passa no vão.
- **Restrição:** quem está na tábua tem a cabeça a até 372 px do chão. Por isso os pés de quem pedala não podem
  descer mais que ~8 px de jogo (≤ 16 px de célula) abaixo do selim. Os joelhos ficam bem para cima, com os pés
  em dois pedais curtos logo abaixo do selim (o jogo desenha os pedais e o resto do monociclo).
- **Os dois num desenho,** como na E7: o Tico pedalando sentado no selim, o Teco nos ombros. O jogo troca as
  cores quando a base é o Teco.
- **Uso dos desenhos:**
  - 1 a 4: pedalando (Monociclo, o vai e volta);
  - 5 e 6: o de baixo joga uma tocha para o alto (Chuva de Tochas, `base` em `throw`);
  - 7 e 8: o de cima joga (tochas e Bolas Quicando).
- **Mesmo tamanho dos irmãos da E7:** nariz de ~30 × 21 px de célula, cabeça de ~145 px (o nariz das folhas normais tem 46 px e a cabeça 215).

**Grade e pivôs:**
- Canvas de 2048 × 1024, 4 × 2 células de 512 × 512.
- Olhando para a DIREITA.
- O ponto do selim (onde o de baixo senta) em (256, 400), em todas as células. Os pés no máximo em y 416.
- O alto do cabelo do de cima por volta de y 40.
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/malabaristas/monociclo_candidata.png`.

**Plano de conferência:**
1. Normalizar com a escala da E7 (o mesmo nariz e a mesma cabeça) e o ponto do selim.
2. Fazer a versão com as cores trocadas.
3. Ligar nas poses `ride`, `sit` e `throw`, com as áreas pelo desenho.
4. **Piloto a 60 quadros por segundo:** a entrada do monociclo, o Monociclo com um jogador na tábua (sem dano e
   sem os pés na cabeça dele), a Chuva de Tochas, as Bolas Quicando e a derrota (a E6 continua).
5. Rodar a bateria.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

We are continuing the animation work for "Respeitável Público", a 2D Godot game about a haunted 1930s circus (Cuphead-like). You make the PNG sheets; Claude reviews, cuts and puts them in the game. One sheet per request.

Create ONE animation sheet. Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/monociclo_candidata.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/malabaristas/totem.png = the APPROVED-FOR-USE totem sheet you made: TICO (RED stripes) at the bottom, TECO (BLUE stripes) on his shoulders. Use EXACTLY these two characters AT THIS SAME SMALL SIZE (ball nose about 30 x 21 px, head about 145 px from hair to chin, same faces, same ink style).
- docs/referencias/pecas/malabaristas/tico_malabares.png and teco_malabares.png = the brothers' approved design (colors and details).
Do NOT use docs/referencias/chefao_malabaristas.png (old concept).

THE POSE: the same two brothers as ONE drawing in every cell, riding a giant unicycle that the GAME draws (do NOT draw the unicycle, the wheel, the pole, the seat or the pedals). TICO (RED) sits on the unicycle seat, pedaling, with his KNEES BENT HIGH and his feet close under his seat (as if on two short pedals right under the seat). TECO (BLUE) sits on Tico's shoulders, legs in front of Tico's chest, Tico holding his shoes or shins with one or both gloves.

KEEP THE COLORS EXACTLY like totem.png (stripe red darker and slightly muted, stripe blue like teco_malabares.png, noses and tongues brighter red with a white shine, each fully closed by the dark outline).

NO EXTRA THINGS: no unicycle, no seat, no pedals, no torches, no balls, no clubs, no props in the hands, no fire, no stars, no motion trails, no speed lines, no dust (the game draws all of these).

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, left to right, top row first. Both brothers facing RIGHT. In EVERY cell the point where Tico's bottom sits on the (invisible) seat is exactly at x = 256, y = 400. Tico's shoes NEVER go below y = 416 (his feet stay right under the seat, knees up). The top of Teco's hair at about y = 40. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels, full opacity inside the drawing), clean edges, no grid lines, no text, no ground, no shadow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like totem.png.

Animation, 8 frames, a DIFFERENT, exaggerated expression on BOTH faces in EVERY frame (Tico concentrating hard on balancing, Teco showing off):
1 PEDAL A: Tico's right knee up, left knee down a little, both bodies leaning slightly forward; Teco with both hands raised as if juggling;
2 PEDAL B: knees passing (both at the same height), bodies upright;
3 PEDAL C: Tico's left knee up, right knee down a little, bodies leaning slightly back;
4 PEDAL D: knees passing again, a small wobble to the side (frames 1 to 4 loop as pedaling);
5 BOTTOM THROW WIND-UP: Tico still pedaling with knees up, one arm pulled down and back (empty glove) ready to throw upward; Teco holding on, worried;
6 BOTTOM THROW RELEASE: Tico's arm swung straight UP, open glove, as if he just tossed something high; Teco ducking;
7 TOP THROW WIND-UP: Teco twists back, throwing arm pulled behind his head (empty glove); Tico pedaling;
8 TOP THROW RELEASE: Teco's arm whipped forward and up, open glove, as if he just let go; Tico wobbling under him.
```

## Pedido P3D1: folha de modelagem do palhaço, 4 vistas (pronto para colar; 04/10/2026)

**Por quê:** é o piloto 3D do usuário (`docs/medidas/mundo3d/plano_piloto_3d.md`): uma miniatura de verdade do
palhaço, modelada no Blender. As folhas aprovadas mostram o palhaço só de lado e de 3/4. Faltam a frente e as
costas: a nuca e os tufos atrás, como a cartolinha senta vista de frente, a gola por trás, o xadrez nas costas e
os sapatos de frente.
- **Não é render de conceito nem captura de tela.** É uma folha de modelagem desenhada no mesmo traço, que o
  Claude usa só como guia para modelar e montar o esqueleto no Blender.
- **Pose A,** para o esqueleto.

**Uso:** referência de modelagem. Não entra no jogo como imagem.

**Grade e medidas:**
- Canvas de 2048 × 1024, 4 × 1 células de 512 × 1024 (altas).
- Vistas ortográficas (sem perspectiva), o mesmo boneco e o mesmo tamanho nas 4: 1 frente, 2 três-quartos de
  frente (virado para a direita), 3 perfil olhando para a direita, 4 costas.
- **Linha do chão** (sola) em y 980 e o meio do corpo em x 256 em todas.
- **Altura** do chão ao alto da cartolinha: ~860 px.
- **Proporções da folha aprovada:** cabeça grande (do queixo ao alto do cabelo, sem o chapéu, ~42% da altura
  sem o chapéu), corpo de pera curto, pernas curtas, sapatões compridos.
- Margem de 24 px.

**Arquivo:** `docs/referencias/pecas/palhaco_modelagem_candidata.png`.

**Plano de conferência:**
1. Conferir a identidade com `palhaco_folha.png`, `palhaco_parado.png` e `palhaco_corrida.png`.
2. Medir as proporções nas 4 vistas: a cabeça, o chapéu, a gola, as alturas da cintura, do joelho e do
   tornozelo, e o comprimento do sapato.
3. Usar as medidas no script do Blender (as vistas como imagens de fundo para conferir a silhueta) e conferir o
   modelo renderizado nas mesmas 4 vistas, lado a lado com a folha.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

We are continuing the art work for "Respeitável Público", a 2D Godot game about a haunted 1930s circus (Cuphead-like). You make PNG images; Claude uses them. This one is a MODELING REFERENCE (a character turnaround model sheet) that Claude will use to build a 3D miniature of the clown in Blender. One image.

Create ONE image. Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_modelagem_candidata.png (replace if it exists).

References (read from the project): docs/referencias/pecas/palhaco_folha.png (APPROVED parts: head with black top hat with gold band and white daisy, red cloud-like hair puffs, cream ruffle collar, round body with maroon-and-cream checker and two gold buttons, puffy pants ending in cream ruffles, big brown clown shoes with a cream band and cream sole, white cartoon gloves), docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_corrida.png (APPROVED full body and proportions). Copy EXACTLY this character, his colors, proportions and ink style.

WHAT TO DRAW: a character TURNAROUND model sheet of the clown: the SAME clown drawn 4 times in ORTHOGRAPHIC views (no perspective), same size and same height in all 4, standing in an A-POSE (arms straight, angled down about 45 degrees away from the body, gloves open and relaxed, empty hands, no gun), feet slightly apart, neutral friendly smile, eyes open looking straight ahead in his own direction:
1 FRONT view (facing the viewer, symmetrical: both hair puffs, the hat seen from the front, the daisy on his right side of the hat, both shoes pointing at the viewer);
2 THREE-QUARTER FRONT view (turned 45 degrees to the RIGHT);
3 SIDE view (profile facing RIGHT);
4 BACK view (the back of the head with the red hair puffs, the back of the hat, the back of the ruffle collar, the checker pattern on the back, the heels of the shoes).

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 4 columns x 1 row, TALL cells of 512 x 1024, one view per cell, left to right. In EVERY cell: shoe soles on the floor line at y = 980, the middle of the body at x = 256, about 860 px from the floor to the top of the hat; the head (chin to top of hair, without the hat) about 42% of the height without the hat, like in the approved sheets. At least 24 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell. If the image tool cannot make 2048 x 1024, keep the same 4 x 1 layout with cells of 1:2 and scale EVERY number by the same factor; say the real size when you deliver. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing), clean edges, no grid lines, no text, no labels, no arrows, no measurement lines, no ground, no shadow, no extra props.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, flat colors with soft painted shading, exactly like the reference sheets. Same colors: maroon and cream checker, red hair, black hat with gold band, white daisy with yellow center, cream ruffles, brown shoes with cream band and sole, white gloves, red ball nose with a white shine.
```

## Pedido W1 (SUSPENSO em 03/10: personagens do mapa agora são miniaturas 3D; só histórico)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D/3D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/mundo/palhaco_andar_frente.png (create the folder).

What it is for: an overworld where the camera looks DOWN at the ground from a high angle (about 48 degrees down, like a tilted diorama view), always from the same side. The characters are flat 2D drawings standing on the 3D ground. This sheet is the clown WALKING TOWARD the camera, diagonally down and to the RIGHT (three-quarter FRONT view: we see his face and his front, turned a little to his left, i.e. to our right), seen slightly from ABOVE (the top of his hat brim and shoulders show a little, his feet look a bit foreshortened).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png, docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_folha.png = the EXACT clown: design, colors (red/cream harlequin suit, ruffled collar, red nose, red hair puffs, small black top hat with a gold band and a white daisy, white gloves, big brown shoes), proportions, head size and ink style.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells and scale every number by the same factor; say the real size when you deliver.
SIZE AND PIVOT: standing he would be about 330 px tall from the shoe soles to the top of the hat, in every frame the same size (same head, same hat). The point on the ground between his two feet is exactly at x = 256, y = 470 of every cell (this is his pivot in the game): the feet touching the ground are on that line. At least 12 px of empty margin around the whole drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow (the game adds a shadow), no motion blur.
BOTH arms drawn (white gloves), NO gun: he is walking around the circus grounds, arms swinging.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation: a cheerful WALK CYCLE (a walk, NOT a run: one foot always on the ground, a little bounce), 8 frames, frame 8 flows back into frame 1:
1 right foot forward touching the ground (heel), left foot behind, arms swinging opposite;
2 weight on the right foot, body lowest, left foot lifting;
3 left foot passing under the body, body rising;
4 body highest, left foot reaching forward;
5 left foot forward touching the ground (heel), right foot behind (the mirror of frame 1);
6 weight on the left foot, body lowest, right foot lifting;
7 right foot passing under the body, body rising;
8 body highest, right foot reaching forward.
The leg on the far side is drawn slightly darker. The head bobs only a few pixels; the head and hat never change size. FACE: a happy, curious walking face (small changes between frames: a blink in frame 4, a smile), always clearly the same clown.
```

**Como entra no jogo:**
- O quadro sai do passo andado, pela distância, como a corrida da luta: o pé no chão não desliza.
- O pivô (256, 470) fica nos pés do andador.
- Conferência:
  - captura a 60 quadros por segundo andando nas 8 direções;
  - medida do pé de apoio;
  - troca parado ↔ andando e mudança de direção sem pulo;
  - sozinho e online.

### Bloco A: jogadores (aparecem o tempo todo)

| # | Folha (caminho de saída) | Referências | Canvas / células | Quadros |
|---|---|---|---|---|
Todas as folhas do bloco A: 2048 × 1024, 4 × 2 células de 512 (células que sobram, transparentes).

| # | Folha (caminho de saída) | Referências | Quadros | Situação |
|---|---|---|---|---|
| A1 | `docs/referencias/pecas/palhaco_parry.png` | `palhaco_corrida.png`, `palhaco_folha.png`, `docs/referencias/combate_parry.png` | 8 (cambalhota + tapa) | **no jogo** (02/10) |
| A2 | `docs/referencias/pecas/acrobata_parry.png` | `acrobata_corrida.png`, `acrobata_folha.png`, `combate_parry.png` | 8 | **no jogo** (02/10) |
| A3 | `docs/referencias/pecas/palhaco_parado.png` | `palhaco_corrida.png`, `palhaco_folha.png` | 8 (respirando, olhos abertos) | **no jogo** (02/10); quadro 6 trocado pelo da A3c (03/10) |
| A4 | `docs/referencias/pecas/acrobata_parado.png` | `acrobata_corrida.png`, `acrobata_folha.png` | 8 | **no jogo** (03/10), versão A4c (A4 e A4b recusadas) |
| A5 | `docs/referencias/pecas/palhaco_pulo.png` | `palhaco_corrida.png` | 8 no ar (subida, topo, queda) | **no jogo** (03/10), com escala única 1,26 na preparação |
| A6 | `docs/referencias/pecas/acrobata_pulo.png` | `acrobata_corrida.png`, `acrobata_parado.png`, `acrobata_parry.png` | 8 no ar | **no jogo** (03/10), escala única 0,94 e cintura em (256, 229) |
| A7 | `docs/referencias/pecas/palhaco_balao_flutua.png` | `palhaco_folha.png`, `docs/referencias/combate_balao_resgate.png` | 8 (6 flutuando + 2 no vento) | **no jogo** (03/10), fator 0,90 e meio do oval em (256, 240) |
| A8 | `docs/referencias/pecas/palhaco_balao_vira_resgate.png` | idem | 8 (4 virando balão + 4 resgate) | **no jogo** (03/10), escala por grupo (0,85 e 1,20) e pivôs por quadro |
| A9 | `docs/referencias/pecas/acrobata_balao_flutua.png` | `palhaco_balao_flutua.png` (aprovada), `acrobata_folha.png`, `acrobata_parado.png`, `combate_balao_resgate.png` | 8 (6 flutuando + 2 no vento) | **no jogo** (03/10), fator 0,91 e meio do oval em (256, 240) |
| A10 | `docs/referencias/pecas/acrobata_balao_vira_resgate.png` | `palhaco_balao_vira_resgate.png` e `acrobata_balao_flutua.png` (aprovadas), `acrobata_folha.png`, `acrobata_parado.png` | 8 (4 virando balão + 4 resgate) | **no jogo** (03/10), escala por grupo (0,80, 0,85, 0,91; 0,97 no 6) |
| A11 | `docs/referencias/pecas/palhaco_dash.png` | `palhaco_corrida.png`, `palhaco_parado.png`, `palhaco_pulo.png` | 4 (células 5–8 transparentes) | **no jogo** (03/10), fator 1,0 e tronco em (250, 330) |
| A12 | `docs/referencias/pecas/acrobata_dash.png` | `acrobata_corrida.png`, `acrobata_parado.png`, `acrobata_pulo.png` | 4 (células 5–8 transparentes) | **no jogo** (03/10), fator 0,94 e cintura em (300, 280) |
| A13 | `docs/referencias/pecas/palhaco_abaixado.png` | `palhaco_parado.png`, `palhaco_corrida.png`, `palhaco_dash.png` | 4 (descendo, 2 parado abaixado, subindo) | A13 recusada (cabeça na linha do tiro); **A13b no jogo** (03/10) |
| A14 | `docs/referencias/pecas/acrobata_abaixado.png` | `acrobata_parado.png`, `acrobata_corrida.png`, `acrobata_dash.png` | 4 (células 5–8 transparentes) | **no jogo** (03/10), fator 1,0 |
| A15 | `docs/referencias/pecas/palhaco_dano.png` | `palhaco_parado.png`, `palhaco_pulo.png`, `palhaco_corrida.png` | 4 (levou o golpe, recuo, susto, volta; células 5–8 transparentes) | **no jogo** (03/10), fator 1,0 e tronco em (256, 332) |
| A16 | `docs/referencias/pecas/acrobata_dano.png` | `acrobata_parado.png`, `acrobata_pulo.png`, `palhaco_dano.png` | 4 (células 5–8 transparentes) | **no jogo** (03/10), fator 1,0 e cintura em (256, 280) |

Quadros detalhados:
- **Parry (A1, A2):** cambalhota inteira desenhada, sem desenho repetido e girado. O desenho inteiro cabe na célula com uns 12 px de folga (a acrobata é alta: nas poses esticadas, dobrar as pernas em vez de encostar na borda). (1) pulo com os joelhos subindo, olhar firme; (2) inclinado 45°, bochechas cheias; (3) encolhido a 90°, olhos apertados; (4) de cabeça para baixo a 180°, boca em "uou!"; (5) 270°, abrindo um olho com sorriso maroto; (6) quase de pé, mão abrindo para o tapa, olhos arregalados; (7) TAPA: luva aberta batendo para a frente e para cima, faíscas rosa `#ff5fa2` em volta da mão, sorriso vitorioso; (8) braços abertos caindo, piscadinha. Sem pistola. Barriga em (256, 280).
- **Parado (A3, A4):** loop de 8 quadros, no chão, sem o braço da arma. Respiração (peito sobe e desce), leve balanço; o braço de trás na cintura (acrobata) ou solto (palhaço); olhos abertos em todos os quadros. Caras: sorriso, olhando de lado, sobrancelha erguida, assobiando, bochechas cheias, sorriso largo, curioso, confiante.
- **Pulo (A5, A6):** os 8 quadros no ar, barriga em (256, 280): (1) acabou de sair do chão, esticado, "hup!"; (2) e (3) subindo, joelhos dobrando; (4) quase no topo, encolhido; (5) topo; (6) começando a cair; (7) caindo; (8) prestes a pousar. O impulso e o pouso amassado ficam por código. No jogo, o quadro sai da velocidade vertical. Sem o braço da arma. (Decidido no pedido A5; a versão antiga, com os quadros 1 e 8 no chão, foi trocada.)
- **Balão (A7 a A10):** os quadros do Pedido 2 de `codex_parry_balao_especiais.md`, divididos em duas folhas de 8: "flutua" (6 flutuando + 2 no vento) e "vira_resgate" (4 virando balão + 4 resgate). Meio do oval em (256, 240) em todas as células (era 210 na folha antiga de 2048 × 2048; com o chapéu em cima não cabia), oval de 260 × 300 px; balão rosa `#ff5fa2` com a cara do personagem, nó e cordinha de uns 70 px.
- **Dash (A11, A12):** (1) arranque inclinado para a frente, olhar decidido; (2) corpo esticado e voando reto, dentes cerrados; (3) igual com variação (cabelo e roupa voando), olhos semicerrados; (4) freando, corpo para trás, sorriso de alívio. Meio da barriga em (256, 280), como no pulo e no parry (decidido no pedido A11; antes era a sola em 486). Sem o braço da arma.
- **Abaixado (A13, A14):** joelhos dobrados, pés plantados (sola em 486), sem o braço da arma. Regra medida no jogo: abaixado, o tiro sai de uma altura fixa (palhaço: ombro em uns (322, 343) da folha; acrobata: (339, 299)), e o braço da pistola vai dali para a direita, saindo da gola logo abaixo do queixo, como em pé. A cabeça fica em pé, do tamanho real (palhaço: do topo do chapéu ao nariz 164 px; acrobata: do topo do coque ao nariz 119), por cima do corpo agachado. Altura abaixado: palhaço uns 355–375 px, acrobata uns 350–370 (contas na correção do A13b, abaixo; as estimativas antigas de 210, 240–260 e 250–265 px estavam erradas). (1) descendo; (2) e (3) abaixado e atento, loop; (4) levantando.
- **Dano (A15, A16):** (1) o golpe, olhos saltando, estrelinhas; (2) jogado para trás, dor; (3) susto, cabelo em pé; (4) recompondo-se, bravo. No jogo o golpe joga o personagem para trás e para cima (0,22 s atordoado), então os quadros são no ar, com o meio do corpo em (256, 280), como no pulo (decidido no pedido A15; a nota antiga dizia sola em 486). Sem o braço da arma.

### Bloco B: Leopoldo (pedido antigo, Pedido 3 de `codex_leao.md`)

| # | Folha | Referências | Canvas / células | Quadros |
|---|---|---|---|---|
| B1 | `docs/referencias/pecas/leao/leao_salto.png` | `leao_folha.png` e as folhas do leão | 2048 × 2048, 2 × 4 de 1024 × 512 | 8 (arco inteiro do salto): B1 recusada (cabeça de tamanhos diferentes); **B1b no jogo** (resultado abaixo) |
| B2 | `docs/referencias/pecas/leao/leao_fogo_parado.png` | `leao_parado.png`, `leao_folha.png` | 2048 × 1024, 2 × 2 | 4: **B2 no jogo** (resultado abaixo) |
| B3 | `docs/referencias/pecas/leao/leao_fogo_corrida.png` | idem | 2048 × 2048, 2 × 4 | 8: **B3 no jogo** (resultado abaixo; Investida da fase 3) |
| B4 | `docs/referencias/pecas/leao/leao_fogo_salto.png` | idem | 2048 × 2048, 2 × 4 | 8: **B4 no jogo** (resultado abaixo; pulos da fase 3) |
| B5 | `docs/referencias/pecas/leao/leao_derrota.png` | idem | 2048 × 1024, 2 × 2 | 4 (cansado, deitando, deitado de língua de fora, deitado dormindo): **B5 no jogo** (resultado abaixo) |

Regras do leão: olhando para a ESQUERDA, célula de 1024 × 512, patas na linha do chão a 30 px do fundo da célula, no máximo 440 px de altura. **Manter as proporções exatas do leão das folhas prontas, mesmo que a largura fique menor (uns 565 px com 440 de altura); nunca esticar até 880** (regra do usuário). Quadros de cada um, como em `codex_leao.md` (Pedido 3).

### Bloco C: Domador (o 1º chefão ainda é um SVG parado)

| # | Folha | Referências | Canvas / células | Quadros |
|---|---|---|---|---|
| C1 | `docs/referencias/pecas/domador/domador_folha.png` | `docs/referencias/chefao_domador.png`, `palhaco_folha.png` (estilo) | 2048 × 1024 | folha base: corpo inteiro olhando para a esquerda + 3 cabeças (convencido, bravo, apavorado): **C1 aprovada** (folha base; resultado abaixo) |
| C2 | `docs/referencias/pecas/domador/domador_chicote.png` | `domador_folha.png` | 2048 × 512, 4 × 1 de 512 | 4: braço baixo, chicote erguido, estalando, depois do estalo. **Sem o chicote** (o jogo desenha o chicote por código, preso à mão): **C2 no jogo** (resultado abaixo) |
| C3 | `docs/referencias/pecas/domador/domador_medo.png` | idem | 2048 × 512, 4 × 1 | 4: tremendo encolhido (loop de 3) + espiando: **C3 no jogo** (resultado abaixo) |
| C4 | `docs/referencias/pecas/domador/domador_reverencia.png` | idem | 2048 × 512, 4 × 1 | 4: reverência sem graça no fim da luta: C4 recusada (cabeça menor nos quadros 3 e 4); **C4b no jogo** (resultado abaixo) |

Domador: baixinho, olhando para a ESQUERDA, uns 465 px de altura na célula de 512 (no jogo ele é reduzido para 260, como a acrobata; decidido em 03/10 para ter a mesma resolução dos jogadores), pés em y = 486, desenho e proporções da `domador_folha.png` aprovada.

### Bloco D: especiais (Pedido 3 de `codex_parry_balao_especiais.md`, uma folha por vez)

| # | Folha | Canvas | Quadros |
|---|---|---|---|
| D1 | `docs/referencias/pecas/palhaco_torta.png` | 2048 × 1024, 4 × 2 | 8 (Torta na Cara, sem pistola): **D1 no jogo** (resultado abaixo) |
| D2 | `docs/referencias/pecas/torta.png` | 2048 × 1024, 4 × 2 | 4 voando + 4 esborrachando: **D2 no jogo** (resultado abaixo) |
| D3 | `docs/referencias/pecas/acrobata_salto_mortal.png` | 2048 × 1024, 4 × 2 | 8 (cambalhota inteira desenhada): **D3 no jogo** (resultado abaixo) |
| D4 | `docs/referencias/pecas/acrobata_chute_torta.png` | 2048 × 1024, 4 × 1 de 512 × 1024 | 4: D4 recusada (acrobata uns 30% grande, torta 6%); **D4b no jogo** (resultado abaixo) |

### Bloco E: chefões e fase novos (hoje desenhados por código)

1. Malabaristas: `codex_malabaristas.md`, Pedido 1 (folha base), depois Pedido 2, uma folha por vez. **E1 (Pedido 1) aprovada tecnicamente em 03/10; o Pedido 2 virou E2, E3... nesta fila, uma folha por vez, a começar pelo Pedido E2 (parado malabarizando), que substitui o item 1 do Pedido 2 antigo.**
2. Mágico: `codex_magico.md`, Pedido 1, depois as folhas do Pedido 2, uma por vez.
3. Trem: `codex_trem.md`, uma peça por vez (vagões, locomotiva, fundo, ponte, inimigos).
4. Mapa: `codex_mapa.md`, uma peça por vez.



### Resultado do D3 (03/10)

No jogo, conferido em movimento. O original está em `originais/acrobata_salto_mortal_codex_1774x887.png`.

**Tamanho:** a folha veio em 1774 × 887 e foi ampliada até 2048 com fator único (1,1545), sem
outra escala.
- Lado a lado, com o nariz alinhado, a cabeça bate com o parado e o pulo aprovados: coque, olho e
  rosto do mesmo tamanho.
- O corpo é mais compacto que o do parado (pernas mais grossas e curtas), no estilo do parry
  aprovado. Aceito: as poses são encolhidas e passam rápido.

**Desvios aceitos:**
- No quadro 4 o espacate tem os joelhos dobrados.
- No quadro 8 os braços estão erguidos com os cotovelos dobrados.

**Registro:**
- Quadros 1 e 8 com a sola em 486.
- Quadros 2–7 com o meio do tronco em (256, 250). Foi medido pelo maiô nos quadros em que ele aparece
  inteiro e à mão nos encolhidos.
- O quadro 7 ficou 37 px à esquerda, para o pé do chute caber na margem.

**No jogo:**
- O giro de duas voltas por código saiu.
- O quadro 1 aparece na agachada (0,12 s), os quadros 2–7 dão a volta até 60% do arco, o chute (7)
  segura até 88%, e o pouso (8) entra no fim.
- Pousando antes num pedestal, o número acaba no chute.
- Arco, dano, invencibilidade, tiro e rede ficaram iguais.
- Captura a 60 quadros por segundo: `--fixed-fps 60 res://tests/screenshots.tscn -- salto_mortal`,
  com registro em `salto_mortal.csv`.


### Acabamento do D3 (03/10, pedido do Codex)

**1. Salto do 6 para o 7.** O quadro 7 tinha sido posto 37 px à esquerda na célula para o pé do chute
caber. O recorte usa uma origem só para os 8 quadros, então o tronco pulava uns 21 px para trás nessa
troca.
- `FrameAnimation` ganhou `offsets` (deslocamento opcional por quadro) e `origin_of(index)`. O
  `CharacterRig` usa isso.
- O `cut_animation_sheet.gd` ganhou a opção `"offsets"`. A entrada `somersault` traz
  `{7: Vector2(37, 0)}`, que no rig vira 21,3 px.
- O desenho e a folha não mudaram. Na captura, o tronco segue contínuo do 6 para o 7.

**2. Salto que termina no chão.** Nova captura com `-- salto_mortal2`: a acrobata sai de x 900 para a
esquerda e cai no chão em x 144.
- O número dura 0,87 s e acabou com ela ainda no ar. Ela cai com os quadros do pulo e pousa uns 0,25 s
  depois.
- No pedestal, o número acaba no pouso, com ela ainda deslizando.
- Nos dois casos, o pouso desenhado (8) nunca aparecia.

**Correção, só de desenho:** `CharacterRig.play_special_ending()`, chamado pelo `PlayerSpecial` quando
o Grande Número termina sem ser cortado.
- No primeiro momento em que o personagem fica parado no chão, dentro de 0,6 s, aparece o último
  quadro da folha do número por 0,35 s, sem a pistola.
- Andar, pular, dar dash ou atirar corta na hora.
- O parado volta pelo quadro 1.
- O controle não fica preso. Duração, invencibilidade, arco e dano não mudaram.
- Vale também para a Torta na Cara (o polegar para cima).

**Resultado nas capturas:**

| Caso | Sequência |
|---|---|
| Pedestal | chute → pousa deslizando (corrida 8 quadros) → "ta-dá" 22 quadros → parado |
| Chão | chute → queda com os quadros do pulo → "ta-dá" no pouso → parado |

Bateria depois das duas mudanças: 9 testes locais com 0 falhas, online normal e com rede ruim ok.

### D4: decisão de uso registrada para comparar (03/10)

O Codex apontou um risco: esconder a acrobata e só soltar a torta no quadro 3 pode mudar a leitura, o
tempo e a resposta do golpe.

**Decisão, a confirmar com captura do antes e do depois quando a folha chegar:**
- O momento do dano fica o de hoje: a Torta de Ouro sai na hora em que o número em dupla dispara e
  chega em 0,6 s.
- O desenho se ajusta a isso:
  - os quadros 1 e 2 passam rápidos (0,05 s cada);
  - o 3 (o chute) coincide com a torta aparecendo no pé dela;
  - o 4 dura uns 0,2 s.
- Esconder a acrobata de verdade só entra se a comparação mostrar que ficam duas acrobatas na tela e
  que esconder lê melhor. Se entrar, vale só no PC de quem vê, sem mexer em posição, colisão nem rede.

**A conferir na integração:**
- dono e observador, nos dois lados da arena;
- a posição real dela;
- o disparo uma vez só;
- as transições para pulo, dash e corrida, sem acrobata nem torta em dobro.

## Pedido D4 (pronto para colar)

**Uso no jogo:** é o Grande Número em Dupla (`core/combat/duo_finale.gd`), quando os dois soltam o
Grande Número em menos de 1 s.
- Hoje sai do meio da dupla uma Torta de Ouro, que voa 0,6 s em arco e explode no chefão.
- Com a folha, a acrobata aparece em cima da Torta de Ouro e chuta a torta (como em
  `combate_especial.png`).

**Como entra (decidido por delegação):**
- A folha toca uma vez no ponto de saída. O tempo e a decisão sobre esconder a acrobata estão em
  "D4: decisão de uso registrada para comparar", logo acima (o momento do dano fica o de hoje).
- O dano, o tempo do voo e a rede ficam iguais.

**Tamanho:** a acrobata no tamanho do parado (465 px em pé) e a torta no tamanho da torta voando do
jogo (`torta.png`, uns 345 px de largura nesta escala). Os dois juntos não cabem numa célula de 512 de
altura, então as células têm 512 × 1024.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_chute_torta.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png and docs/referencias/pecas/acrobata_salto_mortal.png = the EXACT acrobat (design, colors, head size, ink style); both arms drawn, white gloves, NO gun.
- docs/referencias/pecas/torta.png = the EXACT pie of the game (first frame). Here it is the GOLDEN PIE of the duo special: same shape, but the tin and the crust are shiny gold, the cream has a few gold sparkles, the cherry stays red.
- docs/referencias/combate_especial.png = what the duo special looks like.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 1 row, cells of 512 x 1024 (TALL cells), one frame per cell, left to right. If the image tool cannot make 2048 x 1024, keep the same 4 x 1 layout with 1:2 cells and scale every number by the same factor; say the real size when you deliver. Side view, facing RIGHT.
SIZE: the acrobat has the same size as in acrobata_corrida.png: standing she would be about 465 px tall from heel to the top of the bun, the top of the bun to the center of her red nose is 119 px, her head is about 157 px wide at eye level. The golden pie is about 345 px wide and 235 px tall. Never shrink her or the pie to fit; bend her knees instead.
POSITION: in frames 1 to 3 the CENTER of the golden pie is exactly at x = 256, y = 800 of the cell and the pie does not move; the acrobat stands or crouches ON TOP of it (her shoes on the cream). At least 12 px of empty margin around the whole drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.

Animation: DUO KICK, 4 frames (played once):
1 she lands with both feet on top of the golden pie, arms out for balance, surprised face;
2 crouching on the pie, winding up the kick, mischievous grin;
3 the KICK: she jumps up a little and one leg smashes the pie forward to the RIGHT; the pie is tilted and just leaving her foot (its center now at about x = 300, y = 800), a few gold sparkles at the impact, shouting with joy;
4 jumping off backwards (to the LEFT and up), arms up, laughing; NO pie in this frame (the game draws the flying pie). Her waist about at x = 200, y = 450.
FACIAL EXPRESSIONS: a different, exaggerated expression in every frame, always clearly the same acrobat.
```


### Histórico: D4 recusada e pedido D4b (correção focal com medidas, 03/10)

O original da D4 está em `originais/acrobata_chute_torta_codex_1774x887.png` e a candidata ficou no
lugar, sem recorte nem ligação no jogo. A folha veio em 1774 × 887, com células de 443,5 × 887.

**O que está bom:**
- As quatro poses (pouso equilibrando, agachada, chute, salto para trás sem torta) e as caras.
- A Torta de Ouro, os dois braços, nenhuma pistola.
- Nada cruza de célula, e o fundo está limpo.
- No quadro 2, o braço meio escondido atrás do tronco lê bem.

**O que reprovou: a acrobata veio uns 30% maior que nas folhas aprovadas, e a torta uns 6% maior.**
Medidas na escala 2048, com a cabeça alinhada pelo nariz lado a lado:

| Medida | D4 | Parado | Corrida |
|---|---|---|---|
| Branco do olho | 37 × 54 | 25 × 41 | 22 × 38 |
| Nariz | 20 × 21 | 18 × 15 | 15 × 13 |
| Largura da torta | uns 367 | — | — |

- O olho fica 32% mais alto que no parado, e o nariz uns 25% maior.
- A torta tem uns 367 de largura, contra 345 da torta voando aprovada (D2) nessa escala.
- Um fator único não resolve. Com 0,76 a acrobata fica certa, mas a torta cai para uns 279 (19% pequena).
- Escalar a acrobata e a torta separadamente seria recortar e redimensionar partes, e isso não se faz
  aqui.

**Pedido D4b:** uma irmã a partir da D4, com a acrobata redesenhada menor e a torta um pouco menor, sem
mudar as poses. Medidas na escala em que o gerador entrega (1774 × 887).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit docs/referencias/pecas/originais/acrobata_chute_torta_codex_1774x887.png and save the result INSIDE the project at exactly: docs/referencias/pecas/acrobata_chute_torta_v2.png (do NOT overwrite any other file).

Keep the same 4 frames, the same poses, faces, colors and golden pie design, the same canvas (1774 x 887, 4 columns x 1 row of cells about 443 x 887), facing RIGHT, transparent background. Fix ONLY the SIZES:

PROBLEM 1: the acrobat is about 30 percent too big. Measured against the approved docs/referencias/pecas/acrobata_parado.png and acrobata_corrida.png (numbers for this 1774-wide canvas): the white of her eye is 47 px tall here but must be about 35 px; her red nose is 17 x 18 px here but must be about 14 x 12 px; standing she would be about 403 px tall from heel to the top of the bun. Redraw the acrobat about 24 percent SMALLER in every frame (head, bun, body, arms and legs all together, the same proportions as acrobata_corrida.png: tall, slim, long legs).
PROBLEM 2: the golden pie is about 6 percent too big: it must be about 299 px wide and 204 px tall (the same size as the approved docs/referencias/pecas/torta.png), not about 318.

POSITION (same canvas): in frames 1 and 2 the CENTER of the golden pie is exactly at x = 222, y = 693 of its cell, and her shoes stand on the cream on top of it (so she is lower than now, because she is smaller). Frame 3: the pie is at about x = 260, y = 693, tilted, just leaving her foot; she kicks it from on top. Frame 4: no pie; her waist (the gold star) at about x = 173, y = 390 of the cell. At least 10 px of empty margin around the whole drawing inside its cell; nothing crosses into another cell; real alpha 0 outside the drawing (no faint pixels); same 1930s hand-inked style, thick dark brown outline #1b1410.
```


### Resultado do D4b (03/10)

No jogo, com fator único 1,1545 (a ampliação até 2048). Os originais estão em
`originais/acrobata_chute_torta_codex_1774x887.png` (D4) e `..._v2_codex_1774x887.png` (D4b).

**Medidas** (escala 2048, cabeças lado a lado alinhadas pelo nariz com o parado e a corrida):

| Medida | Quadros 1–4 | Parado | Corrida |
|---|---|---|---|
| Nariz | 16–17 × 17–18 | 18 × 15 | 15 × 13 |

- Olho, coque e cabeça do tamanho do parado e iguais nos quatro quadros.
- Torta: 343–352 de largura nos quadros 1 e 2, contra 345 da D2. No quadro 3 ela fica uns 8% maior e
  quase deitada (aceito: lê como a torta amassada pelo chute).

**Registro:**
- A base da torta fica no mesmo ponto nos quadros 1–3 (meio em x 256).
- O quadro 4 (o salto para trás) não cabia no lugar dele dentro da célula. Ficou no meio da célula e
  volta ao lugar por `offsets` no recorte: (−148, −10) px da folha, uns 60 px acima e à esquerda do
  chute.

**No jogo** (`core/combat/duo_finale.gd`, `core/combat/duo_kick/`):
- A Torta de Ouro sai na mesma hora e chega em 0,6 s: o dano é na mesma hora de antes.
- A acrobata desenhada vai em cima da torta, que é a torta desenhada:
  - quadro 1 até 0,05 s, quadro 2 até 0,1 s, quadro 3 até 0,16 s;
  - depois o 4 fica parado onde ela chutou e some em 0,22 s.
- A torta voando aparece no pé dela com o tamanho da torta desenhada (0,92) e cresce até o fim, como
  antes.
- Com o chefão à esquerda, o desenho espelha.
- A acrobata de verdade não foi escondida:
  - ela segue onde está, no Salto Mortal dela ou parada;
  - a do desenho aparece em cima da torta, como num número de picadeiro;
  - fica para a avaliação humana se as duas na tela confundem.
- Os dois PCs criam o efeito pela mesma chamada de antes, uma vez cada.

**Conferido:**
- Fotos com `--fixed-fps 60 res://tests/screenshots.tscn -- dupla`: saída à esquerda e à direita do
  chefão, a tela a cada 2 quadros.
- Bateria: 9 testes locais com 0 falhas (o `test_special` faz o número em dupla) e online normal e com
  rede ruim ok (o online confere "duo declared" e o dano nos dois PCs).

## Pedido B6 (pronto para colar; decidido por delegação em 03/10)

**Uso no jogo:** o rugido (`ROAR_ANIM` em `bosses/tamer/lion.gd`). Na fase 3 o leão ruge em fogo:
- na entrada do fogo (`intro_fire.gd`), ao engolir a tocha;
- nas Argolas Caindo (`falling_rings.gd`), enquanto avisa as ondas.

Hoje é o rugido de pelo com as chamas soltas por código, o único estado da fase 3 que sobrou. O B6
troca quadro por quadro, como no B2 e no B3, e as chamas soltas somem.

**Quadros e tempos do rugido no jogo:**
- Preparação: quadro 1 até 60% e depois o 2.
- Rugido: o 2 nos primeiros 0,08 s e depois o 3 e o 4 alternando a 9 por segundo.

**Medidas do `leao_rugido.png` aprovado** (2048 × 1024, células de 1024 × 512):

| Quadro | Caixa (x, y) | Tamanho |
|---|---|---|
| 1 | 235–787, 79–481 | 553 × 403 |
| 2 | 223–801, 83–482 | 579 × 400 |
| 3 | 199–822, 90–482 | 624 × 393 |
| 4 | 209–814, 101–482 | 606 × 382 |

- Patas em y 481–482, de ponta a ponta 480–523 px.
- Nariz de uns 32 × 25.

**Atenção:** as folhas de fogo B2 e B3 vieram uns 9–10% grandes.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_fogo_rugido.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/leao/leao_rugido.png = the APPROVED roar sheet of Leopoldo the lion: copy its 4 frames EXACTLY (same body, legs, paws, tail, pose, size and position in each cell). Only the mane and the face change.
- docs/referencias/pecas/leao/leao_fogo_parado.png and docs/referencias/pecas/leao/leao_fogo_corrida.png = the APPROVED fire-mane sheets of the same lion: copy their FIRE MANE (orange and yellow cartoon flames with red-orange tips and a dark outline, attached to the head like a mane, covering ALL of the fur mane, also under the chin) and their angry fire face.

SIZE AND POSITION (copy leao_rugido.png): canvas exactly 2048 x 1024, grid of 2 columns x 2 rows, cells of 1024 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 2 x 2 layout with 2:1 cells and scale EVERY number by the same factor (for 1774 x 887 multiply by 0.866); say the real size when you deliver. Side view, facing LEFT. In every cell the lion has the same size and place as in the same frame of leao_rugido.png: bodies about 553 to 624 px wide and 382 to 403 px tall without the flames, the bottom of the paws exactly at y = 482, the paws spanning about 480 to 523 px from front toes to back toes, dark brown nose about 32 x 25 px. IMPORTANT: the last fire sheets came out about 10 percent too big; the body, legs and paws must match leao_rugido.png frame by frame, NOT bigger. The flames may rise at most 40 px above the fur mane of the reference; at least 12 px of empty margin around the whole drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow, no glow outside the drawing.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture. The body keeps its normal golden colors (the game adds the orange tint by itself).

Animation: ROAR ON FIRE, 4 frames, the same poses as leao_rugido.png:
1 wind-up: head pulled back, flames pulled in, smoldering furious eyes;
2 mouth opening, flames flaring up and back;
3 full ROAR: mouth wide open with fangs, flames blasting backward big and wild, eyes squeezed in rage;
4 the roar continuing (alternates with frame 3): mouth wide open, the flames in a different flickering shape.
The flames never cover the eyes, the nose or the open mouth.
```


### Resultado do B6 (03/10)

No jogo, com fator único 0,91. O original está em `leao/originais/leao_fogo_rugido_codex_1774x887.png`.

**Tamanho:** de novo uns 9% grande, como o B2 e o B3. Com 0,91, sem escala por quadro:

| Medida | B6 com 0,91 | Rugido aprovado |
|---|---|---|
| Patas, de ponta a ponta | 479, 491, 522, 511 | 480, 499, 523, 502 |
| Nariz nos quadros 3–4 | 36 × 24–25 | 35 × 27–28 |

O nariz foi medido do mesmo jeito nos dois (`darknose.gd`).

**Alinhamento:** patas em y 482 e o meio das patas no mesmo x do rugido aprovado, para a troca do
rugido normal para o rugido em fogo não saltar.

**Desvio aceito:** a manchinha marrom embaixo da juba, no peito, lê como sombra, como no B2 e no B3.

**No jogo:**
- Preparação e rugido em fogo usam esta folha (`FIRE_ROAR_ANIM`). Com isso todas as poses em pé do leão
  têm a juba de fogo desenhada, e as chamas soltas por código não aparecem mais.
- Captura com `--fixed-fps 60 res://tests/screenshots.tscn -- rugido_fogo` (registro em
  `rugido_fogo.csv`), pelo cérebro do chefão como numa luta:
  - a entrada do fogo: tocha, engole, pega fogo e ruge em loop 3 ↔ 4, depois volta ao parado em fogo;
  - as Argolas Caindo: ruge avisando as ondas.
- Patas paradas e chamas soltas desligadas em todos os quadros.
- Avisos, dano e rede ficaram iguais. Os dois PCs tocam o mesmo ataque.

### D4b: eco dourado da acrobata do número (decidido por delegação, 03/10)

O Codex viu nas fotos duas acrobatas separadas: a jogadora e a do número em dupla. Comparei a mesma
cena, no tamanho real da tela e a 60 quadros por segundo (`-- dupla`, close `dupla_perto_*`):
- **antes:** as cores normais;
- **variante:** a acrobata do número em tom dourado e um pouco transparente (`RIDER_TINT`).

**Escolhida a variante.** A jogadora, de maiô verde, fica claramente separada do "número" dourado. O tom
é o mesmo da Torta de Ouro voando, então desenho e torta leem como um efeito só. O creme da torta
desenhada fica um pouco amarelado, coerente com a Torta de Ouro.

Não mudou: a jogadora não é escondida, e dano, posição, colisão e controle ficaram iguais.

### Bloco M: movimento (decidido por delegação em 03/10/2026)

Antes de pedir ciclos inteiros novos, o movimento é medido no jogo: captura a 60 quadros por segundo,
pé de apoio e transições (ver o diário, "Piloto de movimento"). Este bloco traz só os desenhos que
faltam para o movimento ficar contínuo.

**Ordem de prioridade na fila** (atualizada em 03/10, à noite): D3, D4/D4b e B6 já estão no jogo; MV1 pausada; W1–W8 suspensas. T1 e T2 (texturas do chão) já estão no jogo; nenhum pedido de imagem do mundo aberto até a avaliação do M0. Bloco E: a E1 (folha base dos Malabaristas) foi aprovada tecnicamente; a E2 foi recusada como pedida e aproveitada como "chuveiro" (no jogo, conferida em piloto); depois o acabamento E2b (intermediários do braço e a clave pelo cabo, conferido em 3 s); a E3 (arremesso) está no jogo como arremesso por baixo, conferida em piloto; a E4 (tonto) está no jogo, conferida com a cura de verdade; a E5 (salto mortal) está no jogo, conferida na Troca de Lugar; o tonto ganhou a suavização E4b. As entradas do totem e do monociclo foram pilotadas à parte (a base do totem passou a usar o boneco ao carregar o irmão). A E6 (derrota) está no jogo, conferida na derrota real. Com ela, as poses em pé dos Malabaristas estão desenhadas (o totem e o monociclo continuam por código, sem pedido). Mágico: a M1 (folha base) foi aprovada tecnicamente e a M2 (parado) está no jogo, conferida na luta. A M3 e a M3b (feitiço e lançamento) estão no jogo, conferidas com o Leque de Cartas. A M4 (cartola), a M5 (sumir) e a M6 (reverência e medo) estão no jogo. O marco de gameplay do Mágico (cartas pretas que perseguem alternando P1 e P2, rosas, embaralhar das caixas) está feito, sem pedido de imagem; a revisão finita dele também. A M7 (mãos gigantes) e a M8 (rosto gigante) estão no jogo; o Mágico está todo desenhado. A E7 (o totem dos Malabaristas, irmãos menores por decisão do usuário) está no jogo, pilotada com as duas bases. A E8 (os Malabaristas no monociclo) fica pronta na fila, em espera: a prioridade humana de 04/10 é o piloto 3D. Pedido de imagem aberto: o P3D1 (folha de modelagem do palhaço em 4 vistas). O piloto por peças do tonto não é viável (nos extremos do pêndulo a cabeça tapa a gola, que não existe por baixo); a E4b continua como defeito conhecido. O meio do pêndulo do tonto foi recusado em três formatos (E4c, E4d e E4e, só o B passou) e o caminho de imagem está encerrado neste ciclo; o jogo segue com a E4b, um defeito conhecido. A avaliação humana continua necessária para a aprovação final, mas não trava as decisões de rotina do M1, que são delegadas. A revisão de arte de luta não espera a avaliação humana do M0.

| # | Folha | Referências | Canvas / células | Quadros |
|---|---|---|---|---|
| B6 | `docs/referencias/pecas/leao/leao_fogo_rugido.png` | `leao_rugido.png`, `leao_fogo_parado.png` | 2048 × 1024, 2 × 2 de 1024 × 512 | 4 (rugido em fogo): **B6 no jogo** (resultado acima) |
| MV1 | `docs/referencias/pecas/acrobata_corrida_entre.png` | `acrobata_corrida.png` | 2048 × 1024, 4 × 2 de 512 | 8 intermediários da corrida: **pedido pronto** (abaixo) |


### MV1: tentativas recusadas e guia visual (03/10)

**Recusadas pelo Codex, nenhuma copiada para o projeto.** Ficam só para diagnóstico em
`C:\Users\roberto.gabriel\.codex\generated_images\01a0fcde-7657-7510-ba11-05f60a496a40\`:

| Arquivo | Problema |
|---|---|
| `exec-e6e0299f-…` | repete poses dos quadros-chave e erra o caminho do pé de apoio |
| `exec-2bbc479a-…` | piora as margens |
| `exec-279611a4-…` | pé fora dos pontos e desenho cruzando a divisão entre as filas (alpha > 25 na faixa de 12 px da borda em todos os 8 quadros) |

**Erro no pedido, corrigido.** O pedido antigo trocava as pernas: dizia que a perna ESCURA apoiava nos
intermediários 1–4. Na folha aprovada é o contrário: nos quadros 1–4 o pé no chão é o da perna CLARA
(do pouso em x 490 até o empurrão em 199), e nos 5–8 o da escura (482 até 184). A perna escura é sempre
a do lado de lá. Os x das pontas (442, 361, 263, 192, 431, 358, 260, 191) estavam certos: são a média
exata das pontas dos quadros vizinhos (490 e 394 → 442; 394 e 328 → 361; 328 e 199 → 263; 199 e 185 →
192; 482 e 380 → 431; 380 e 337 → 358; 337 e 184 → 260; 184 e 199 → 191).

**Novo método: guia visual** (`scratchpad/mv1_guia.png`, 2048 × 1024, 4 × 2 de 512; gerado por
`scratchpad/mv1_guide.gd`). É só referência para o gerador de imagem, nunca entra no jogo.
- Cada célula tem o tronco, a cabeça e o braço de trás do quadro aprovado N, sem as coxas.
- A cabeça sobe ou desce metade do balanço até N+1, e o nariz continua em x 400.
- As duas pernas aparecem em esquema, com a escura atrás da clara.
- Juntas, medidas à mão nas folhas aprovadas (tabela abaixo):
  - quadril e tornozelo são a média de N e N+1;
  - o joelho sai do comprimento médio da coxa e da canela, dobrado para o lado do joelho dos vizinhos.
- O pé de apoio leva a ponta para o x pedido, na sola 486.
- Nos intermediários 4 e 8, o pé que vai pousar fica com o calcanhar uns 10 px acima do chão, perto de
  x 470 e 475.
- Marcações: pontos azuis nas juntas, ponto dourado na ponta do sapato, cruz vermelha onde a ponta toca
  o chão, linha tracejada vermelha no chão (y 486) e azul no nariz (x 400).

**Juntas do guia** (x, y na célula; "cabeça" = quanto o desenho sobe ou desce em relação ao quadro N):

| # | Entre | Apoio | Quadril claro | Joelho claro | Tornozelo claro | Ponta clara | Quadril escuro | Joelho escuro | Tornozelo escuro | Ponta escura | Cabeça |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1–2 | clara | (343, 301) | (336, 373) | (385, 428) | (442, 480) | (308, 306) | (296, 372) | (215, 375) | (195, 420) | +3 |
| 2 | 2–3 | clara | (318, 286) | (316, 362) | (310, 432) | (361, 480) | (325, 291) | (359, 334) | (288, 350) | (270, 386) | −4 |
| 3 | 3–4 | clara | (285, 281) | (246, 345) | (241, 423) | (263, 480) | (340, 276) | (405, 321) | (371, 375) | (401, 412) | +1 |
| 4 | 4–5 | clara, só a ponta | (290, 294) | (227, 340) | (195, 413) | (192, 480) | (343, 294) | (380, 359) | (417, 433) | (470, 474) | +4 |
| 5 | 5–6 | escura | (300, 306) | (290, 368) | (203, 377) | (184, 423) | (343, 306) | (385, 353) | (380, 425) | (431, 480) | +1 |
| 6 | 6–7 | escura | (325, 298) | (360, 345) | (285, 357) | (273, 393) | (313, 293) | (317, 359) | (310, 428) | (358, 480) | −2 |
| 7 | 7–8 | escura | (340, 295) | (410, 326) | (370, 385) | (397, 429) | (283, 300) | (237, 342) | (240, 418) | (260, 480) | +5 |
| 8 | 8–1 | escura, só a ponta | (335, 286) | (377, 348) | (423, 427) | (475, 474) | (293, 291) | (246, 351) | (195, 410) | (191, 480) | −7 |

**Limitações do guia:**
- As juntas dos quadros aprovados foram medidas à mão, com erro de uns ±5 px.
- Os sapatos são esquemas, sem o salto alto.
- Sobram uns pontinhos dourados perto do quadril nos intermediários 4 e 8, do contorno da saia.

O pedido MV1 abaixo foi corrigido (as cores das pernas trocadas) e agora aponta para o guia.

**Mais duas tentativas recusadas (03/10):** `exec-9faf7069-…` (guia, corrida e parado) e `exec-7f2a3dcd-…`
(só o guia, edição). As duas repetiram quase os quadros-chave e não seguiram os pontos de apoio; nenhuma
foi copiada. MV1 pausada (5 tentativas recusadas); o mundo 3D (bloco W) vem antes. Se voltar: guias
recortados de 1 ou 2 poses ou redesenho controlado, nunca mistura ou girar a imagem.

## Pedido MV1 (pronto para colar; corrigido em 03/10 com o guia visual)

**Uso no jogo:** a corrida da acrobata tem 8 desenhos por ciclo, a 520 px/s. Em cada desenho o corpo
anda uns 35–45 px com o pé de apoio parado, e depois o pé volta de uma vez. É o "travado" que o usuário
sente.

Com um desenho novo entre cada par dos aprovados, o ciclo fica com 16, intercalados (1, 1½, 2, 2½...),
e esse salto cai pela metade. Cadência e tempo por pose já foram ajustados no jogo.

**Medidas da folha aprovada** (células de 512):
- Sola em y 486 e nariz em x 400 em todos os quadros.
- A ponta do sapato de apoio no chão fica nestes x:

| Quadro | Ponta do sapato de apoio |
|---|---|
| 1 | 490, o pé da frente pousando |
| 2 | 394 |
| 3 | 328 |
| 4 | 199, a ponta empurrando |
| 5 | 482, o outro pé pousando |
| 6 | 380 |
| 7 | 337 |
| 8 | 184 |

**Cada intermediário fica no meio do caminho entre os dois vizinhos.** Não é mistura de imagens: cada
um é um desenho novo.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_corrida_entre.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the APPROVED 8-frame run cycle of the acrobat (frames read left to right, top row first). This new sheet contains the 8 IN-BETWEEN drawings of that cycle: new frame N goes BETWEEN approved frame N and approved frame N+1 (new frame 8 goes between approved frame 8 and approved frame 1). Copy the character EXACTLY (same design, colors, size, head, bun, leotard, shoes, ink style); only the legs, arms and body lean change, halfway between the two neighbour poses.
- docs/referencias/pecas/acrobata_parado.png = the same acrobat at the correct size.

IMPORTANT, NOT a blend: draw each in-between as a NEW clean drawing of a pose halfway between its two neighbours (no cross-fade, no double lines, no ghost limbs, no motion blur).

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells and scale every number by the same factor; say the real size when you deliver. Side view, facing RIGHT, exactly like acrobata_corrida.png: in every cell the tip of her small RED NOSE is at x = 400, the soles of the shoes touching the ground are exactly at y = 486, the head and bun are the same size and at about the same height as in the neighbour frames (the head bobs only a few pixels). Like in acrobata_corrida.png, the FRONT ARM (the gun arm) is NOT drawn (the game adds it); the back arm swings halfway between the neighbours. At least 12 px of empty margin around the drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, no grid lines, no text, no ground, no shadow.

The leg on the far side of her body is drawn slightly darker, exactly as in the reference (in approved frames 1–4 the LIGHTER leg is the one on the ground, in frames 5–8 the DARKER one). Use the visual guide C:SERSOBERTO.GABRIELAPPDATAocaltempaudem-jogo-coop3c5555f-0fb1-4b98-a0e2-ac83b517d037scratchpadmv1_guia.png (same canvas and cells as this sheet): it shows, for each in-between, the approved upper body at the right height and the two legs as a schematic (blue dots = hip, knee, ankle; gold dot = shoe tip; red cross = where the supporting shoe tip touches the ground; dashed red line = the ground at y 486; dashed blue line = the nose at x 400). copy the poses of the guide exactly, but draw the real acrobat (real legs, real shoes, same style as acrobata_corrida.png); never copy the schematic shapes, dots, lines or crosses. feet on the ground (x of the tip of the supporting shoe, in its cell):
1 (between approved 1 and 2): the lighter leg supports her, its whole shoe flat on the ground, shoe tip at x = 442; the darker leg has just left the ground behind and is starting to bend.
2 (between 2 and 3): lighter shoe flat on the ground, tip at x = 361; the darker leg swings forward under the body, knee bent.
3 (between 3 and 4): lighter shoe on the ground with the heel starting to lift, tip at x = 263; the darker knee comes up in front.
4 (between 4 and 5): lighter leg pushing off with only the toes on the ground, tip at x = 192; the darker leg reaches forward, its heel just above the ground (about 10 px up) near x = 470, about to land.
5 (between 5 and 6): the darker leg supports her, shoe flat, tip at x = 431; the lighter leg has just left the ground behind.
6 (between 6 and 7): darker shoe flat, tip at x = 358; the lighter leg swings forward under the body.
7 (between 7 and 8): darker shoe heel starting to lift, tip at x = 260; the lighter knee comes up in front.
8 (between 8 and 1): darker leg pushing off with only the toes on the ground, tip at x = 191; the lighter leg reaches forward, heel just above the ground near x = 475, about to land.
Face: the same happy running face as the neighbours (eyes and mouth halfway between them).
```

## Como cada folha entra no jogo

Recortar com `tools/cut_animation_sheet.gd`; se a grade vier torta, normalizar antes com
`tools/normalize_sheet.gd`. O resultado vira um `FrameAnimation` (.tres). No `CharacterRig`
cada estado ganha a sua animação, como a corrida já tem; o braço da arma continua por
código, preso ao ombro de cada quadro. Não mudam mecânica, colisão, saída do tiro, rede nem
controles. Cada integração é conferida com fotos da tela (`tests/screenshots.tscn`) e com a
bateria de testes.

## Pedido A4 (pronto para colar)

O A3 está no jogo e serve de modelo: no chão, sola em 486, pés plantados e sem o braço da arma.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_parado.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the EXACT acrobat: a TALL, SLIM, long-legged young woman (NOT short, NOT chubby). Black hair in a high round bun with a small gold star tiara, gold star earrings, big round black cartoon eyes with lashes, rosy cheeks, a small red clown nose, teal (#1f5a66) strapless leotard with thin gold shoulder straps, gold sweetheart neckline trim, a gold star at the waist and a gold zigzag hem, bare slim legs, white gloves, teal high-heel shoes with gold ankle straps and gold balls on the toes. She is about 465 px tall from heel to top of the bun, exactly as in that sheet. Like in that sheet, the FRONT ARM (the gun arm, the arm on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/acrobata_folha.png = face details.
- docs/referencias/pecas/acrobata_parry.png = an approved sheet of this acrobat, for identity and ink quality.
- docs/referencias/pecas/palhaco_parado.png = the approved idle sheet of the clown: follow the SAME layout, framing, planted feet and subtle breathing loop, but with the acrobat's tall, elegant figure.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. Side view, facing RIGHT, the same angle as the run sheet. The acrobat is IDENTICAL in every frame. Feet on the SAME ground line in every cell: the bottom of the shoes exactly at y = 486 of the cell; body centered horizontally around x = 256; she must fit inside the cell with about 12 px of empty margin at the top. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo, no grid lines, no text, no ground shadow, no motion blur.
ARMS: only the BACK arm is drawn, BEHIND the body, with the gloved hand resting on her back hip (hand on the waist, elbow out behind her), like a confident performer. NO front arm, NO gun, NO hand in front of the chest: the front shoulder area stays clean.
EYES OPEN in every frame (no blink frame; the game has its own blink).

Animation: IDLE, 8 frames, a smooth breathing LOOP (frame 8 flows back into frame 1). Subtle motion, standing elegantly with one foot slightly in front of the other, weight on the back leg:
1 neutral elegant stance, gentle confident smile;
2 chest rising slightly, chin lifting a little, smile widening a bit;
3 top of the breath, body a few pixels taller, eyebrows lifted slightly, proud look;
4 starting to breathe out, bun and earrings swaying very slightly, content smile;
5 chest lowering, front knee softening a tiny bit, relaxed smile;
6 bottom of the breath, only 2 or 3 percent lower than frame 1 (NOT a deep squash), cheeks a bit rounder;
7 rising again, small playful grin;
8 almost back to frame 1, eyes glancing slightly forward, ready.
Keep the feet planted in exactly the same place in all frames; only the upper body, head, bun and back arm move a few pixels. Keep her total height nearly constant (the difference between the tallest and shortest frame no more than about 15 px). Expressions SUBTLE and continuous, always eyes open.
```

## Pedido A3b (correção do quadro 6 do palhaço parado, depois do A4)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit the existing sheet docs/referencias/pecas/originais/palhaco_parado_codex_1774x887.png and save the corrected sheet INSIDE the project at exactly: docs/referencias/pecas/palhaco_parado_v2.png (do NOT overwrite any other file).

Keep frames 1, 2, 3, 4, 5, 7 and 8 EXACTLY as they are (same pixels, same position). Change ONLY frame 6 (second row, second cell): it is too short compared with its neighbours (about 5% lower), which makes a visible jump in the breathing loop. Redraw frame 6 as the gentle bottom of the breath: the clown only 1 to 2 percent shorter than frame 5, same head size, same hat size, same planted feet in exactly the same place, same back arm behind the body, eyes open, relaxed smile, no front arm. Same canvas size and layout as the input, fully transparent background (real alpha), same 1930s hand-inked style.
```

## Pedido A4b (correção da acrobata parada, pronto para colar)

A candidata A4 foi recusada (02/10). Medição depois de normalizar para 2048 × 1024:
- os quadros 1 a 4 têm 508 a 510 px de altura e os 5 a 8, 482 a 483 px: a fila de cima está desenhada uns 5% maior;
- o loop pula uns 27 px na passagem do 4 para o 5 e do 8 para o 1 (o limite é 15 px);
- nas duas filas ela também fica mais alta que os 465 px da corrida;
- há pontinhos vermelhos e amarelos soltos perto das pernas.
O original recusado está em `originais/acrobata_parado_codex_1774x887.png`.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit the candidate sheet docs/referencias/pecas/originais/acrobata_parado_codex_1774x887.png and save the corrected version INSIDE the project at exactly: docs/referencias/pecas/acrobata_parado_v2.png (do NOT overwrite any other file).

Problems to fix (keep the same drawing, poses, faces, colors and 1930s hand-inked style):
1. SCALE: the four frames of the TOP row are drawn about 5 percent BIGGER than the four frames of the BOTTOM row. Make all 8 frames the SAME size: same head size, same bun size, same leg length. The total height (heel to top of the bun) may change only with the subtle breathing, at most about 2 percent between any two frames.
2. SIZE AND MARGINS: inside every cell (4 columns x 2 rows), leave clear empty transparent space around the figure: the figure must not touch or come near the cell borders, with at least 6 percent of the cell height empty above the bun and the shoes standing on the same ground line, a bit above the bottom of the cell. The bottom-row figures are the right size; match the top row to them.
3. CLEAN EDGES: remove every stray red, orange or yellow speck or fringe around the legs and the outline. Only the figure itself, with its dark brown outline, on a fully TRANSPARENT background (real alpha, not black, not a checkerboard), no halo.
4. Keep: eyes open in all frames, the small red nose visible, only the back arm with the hand on the hip, NO front arm, NO gun, feet planted in the same place in every frame, the same 8-frame breathing loop.
Output the same layout as the input (4 columns x 2 rows, frames left to right, top row first).
```

## Histórico: A4b recusada e pedido A4c (atendido pela A4c em 03/10) (correção focal com medidas)

Diagnóstico da A4b (02/10, `originais/acrobata_parado_v2_codex_1774x887.png`, normalizada só no scratchpad):
- **Altura:** fila de cima 500–501 px, fila de baixo 483–484 px (17 px de diferença; o limite é 15).
- **Não é só escala:** largura/altura de 0,520–0,527 em cima e 0,542–0,549 embaixo; nariz a 0,230–0,234 da altura em cima e a 0,242–0,246 embaixo. A fila de cima está uns 4–5% mais esticada na vertical. Com escala por fila até 465 px (opção `altura=465` do `regrid_sheet.gd`), a cabeça e o coque da fila de baixo ficam visivelmente maiores: o 4→5 pularia. Precisa de redesenho, então foi recusada.
- **Pontinhos:** são grupos soltos (37–93 px por quadro), longe do desenho. A opção `limpar` tira só grupos soltos com menos de 400 px e não toca pele, contorno nem dourado. Pode ser usada nas próximas versões.

Ordem: mandar o **A3b** agora; o A4c depois.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit docs/referencias/pecas/originais/acrobata_parado_v2_codex_1774x887.png and save the result INSIDE the project at exactly: docs/referencias/pecas/acrobata_parado_v3.png (do NOT overwrite any other file).

The BOTTOM row (frames 5, 6, 7 and 8) is correct: keep those four frames EXACTLY as they are (same pixels, same position).
The TOP row (frames 1, 2, 3 and 4) is wrong: those figures are drawn about 4 to 5 percent taller and narrower than the bottom ones (stretched vertically, head and bun smaller). Redraw frames 1 to 4 so that the acrobat has EXACTLY the same proportions and size as in frame 5:
- same total height as frame 5 (heel to top of the bun), within 1 percent;
- same head size, same eye size, same bun size, same width of the body and legs as frame 5;
- the red nose at the same height as in frame 5;
- the same planted feet, in the same place inside the cell as in frame 5;
- the same pose family: hand on the hip with the back arm, no front arm, no gun, eyes open, subtle breathing differences only (chest a few pixels up or down).
Frame order of the loop: 1 neutral, 2 inhale, 3 top of the breath, 4 starting to exhale, then 5 to 8 as they are now; frame 4 must flow smoothly into frame 5 and frame 8 back into frame 1.
Remove any stray red, orange or yellow specks around the figure. Same canvas size and layout as the input (4 columns x 2 rows), fully TRANSPARENT background (real alpha), same 1930s hand-inked style.
```

## Histórico: A3b recusada e pedido A3c (atendido pela A3c em 03/10) (quadro 6 do palhaço parado, com medidas)

Diagnóstico da A3b (02/10, `originais/palhaco_parado_v2_codex_1774x887.png`):
- **Quadro 6:** foi para 453 px (normalizado), mais alto que o 5 (441) e que o topo da respiração (quadro 3, 449). O ciclo ficou invertido.
- **Outros sete quadros:** mudaram de 1 a 3 px.
- **Teste:** folha de preparação com os sete quadros do original aprovado e só o 6 da candidata. Os quadros 5, 6 e 7 medem 440, 453 e 436 (+13 / −17; o limite é 15). O nariz fica a 0,157 da altura no 6 e a 0,167–0,170 nos vizinhos: a cabeça e o chapéu foram esticados para cima. Escala uniforme não corrige, então foi recusada.
- **No jogo:** continua o A3 aprovado (quadro 6 com 416 px).
- **Alternativa só de integração, sem mexer no desenho e a decidir pelo usuário:** tocar o parado do palhaço com 7 quadros, pulando o 6 (o 5→7 vai de 440 para 436). Não foi aplicada.

Medidas-alvo na folha do Codex (1774 × 887): o quadro 5 tem uns 381 px de altura, do pé ao topo do chapéu. O quadro 6 precisa ficar com **376 a 379 px**, com o topo do chapéu 2 a 5 px ABAIXO do topo do chapéu do quadro 5 e os pés no mesmo lugar.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit docs/referencias/pecas/originais/palhaco_parado_codex_1774x887.png and save the result INSIDE the project at exactly: docs/referencias/pecas/palhaco_parado_v3.png (do NOT overwrite any other file).

Keep frames 1, 2, 3, 4, 5, 7 and 8 EXACTLY as they are (copy their pixels unchanged). Change ONLY frame 6 (second row, second cell).
Frame 6 must be an exact copy of frame 5 with ONE tiny change: the whole upper body (head, hat, collar, chest, back arm) moved DOWN by 3 to 4 pixels and the belly a touch wider, as the bottom of a calm breath. Same head size, same hat size and shape, same face, eyes open, same planted feet in exactly the same place as in frame 5, no front arm, no gun.
Measurements on this 1774 x 887 sheet: frame 5 is about 381 px tall from the shoe sole to the top of the hat; frame 6 must be 376 to 379 px tall, and the top of its hat must be 2 to 5 px LOWER than the top of the hat in frame 5. Do NOT make frame 6 taller than frame 5. Do NOT stretch the head or the hat.
Same canvas size and layout, fully TRANSPARENT background (real alpha), same 1930s hand-inked style.
```

## Pedido A5 (pronto para colar)

Decisão de integração: os 8 quadros do pulo são todos **no ar** (âncora `ar`, meio em
256, 280). O impulso agachado e o pouso amassado continuam por código (o squash que o jogo
já faz ao pousar). No jogo, o quadro é escolhido pela velocidade vertical: subindo, topo,
caindo.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_pulo.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png = the EXACT clown: design, colors (red/cream harlequin suit, ruffled collar, red nose, red hair puffs, small black top hat with a white daisy, white gloves, big brown shoes), proportions, SCALE and ink style. He is about 406 px tall from shoe sole to hat top when standing in that sheet. Like in that sheet, the FRONT ARM (the gun arm, on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_parry.png = approved sheets of this clown, for identity, size and ink quality.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. Side view, facing RIGHT. The clown is IDENTICAL in every frame (same head size, same hat, same body size as in the references); only the pose and the face change. He is in the AIR in every frame: keep the middle of his belly at the same point in every cell, x = 256, y = 280, with at least 12 px of empty margin around the drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground shadow, no motion blur, no speed lines.
ARMS: only the BACK arm is drawn, BEHIND the body, swinging with the jump. NO front arm, NO gun, NO hand in front of the chest: the front shoulder area under the collar stays clean, and the red nose is always visible.

Animation: JUMP in the air, 8 frames, from just after take-off to just before landing:
1 just left the ground, body stretched upward, legs straight down, mouth open "hup!";
2 rising, knees starting to bend, back arm swinging up, cheerful grin;
3 rising higher, knees up, collar flapping, excited eyes;
4 near the top, tucked, hat lifting a little off his head, surprised round mouth;
5 top of the jump (apex), small float pose, eyes wide, delighted;
6 starting to fall, legs opening downward, hat settling back, focused look;
7 falling, legs reaching down, back arm up for balance, a bit worried;
8 about to land, both big shoes pointing down ready to touch the ground, concentrated, lips pressed.
FACIAL EXPRESSIONS: a different expression in every frame, lively but readable.
```

### Resultado do A5 (03/10)

No jogo. O desenho veio uns 20% menor que o resto do palhaço: do topo do chapéu ao nariz,
54–61 px (já em 2048) contra 70–76 no parado aprovado. Corrigido na preparação com um fator
só para a folha inteira (`regrid_sheet.gd ... 4 2 ar limpar escala=1.26`), sem igualar a
altura das poses encolhidas às esticadas. Original guardado em `originais/`. Detalhes no diário.

## Pedido A6 (pronto para colar)

Mesma decisão do A5: os 8 quadros no **ar** (meio em 256, 280), escolhidos no jogo pela
velocidade vertical. Lição do A5: o pedido traz a medida da cabeça para o desenho não vir menor.
Na folha de 2048 × 1024, a acrobata parada mede uns 465 px do salto ao topo do coque, e do topo
do coque ao nariz vermelho dá uns **114 px** (no tamanho em que o Codex costuma entregar,
1774 × 887, isso dá uns 99 px). Na conferência: medir essa distância (`medir` do
`regrid_sheet.gd`) e, se vier diferente, corrigir com `escala=F`, um fator único para a folha inteira.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_pulo.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the EXACT acrobat: a TALL, SLIM, long-legged young woman (NOT short, NOT chubby). Black hair in a high round bun with a small gold star tiara, gold star earrings, big round black cartoon eyes with lashes, rosy cheeks, a small red clown nose, teal (#1f5a66) strapless leotard with thin gold shoulder straps, gold sweetheart neckline trim, a gold star at the waist and a gold zigzag hem, bare slim legs, white gloves, teal high-heel shoes with gold ankle straps and gold balls on the toes. Like in that sheet, the FRONT ARM (the gun arm, the arm on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/acrobata_parado.png and docs/referencias/pecas/acrobata_parry.png = approved sheets of this acrobat, for identity, SIZE and ink quality.

SIZE (very important, the previous jump sheet came out 20 percent too small): draw her at EXACTLY the same size as in docs/referencias/pecas/acrobata_parado.png. On the 2048 x 1024 sheet she is about 465 px tall from heel to top of the bun when standing, and the distance from the top of the bun down to the red nose is about 114 px. Keep that head size (bun, head, eyes, nose) in EVERY frame. Only the pose changes the total height: tucked frames are shorter, stretched frames taller; do NOT shrink the whole figure to make the stretched poses fit. If a stretched pose would come near the cell border, bend the knees or tilt the legs instead (she must keep at least 12 px of empty margin inside her cell).

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. Side view, facing RIGHT. The acrobat is IDENTICAL in every frame; only the pose and the face change. She is in the AIR in every frame: keep the middle of her body (the gold star at the waist) at the same point in every cell, x = 256, y = 280. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground shadow, no motion blur, no speed lines.
ARMS: only the BACK arm is drawn, BEHIND the body, swinging with the jump, graceful like a gymnast. NO front arm, NO gun, NO hand in front of the chest: the front shoulder area stays clean, and the red nose is always visible.

Animation: JUMP in the air, 8 frames, from just after take-off to just before landing:
1 just left the ground, body stretched upward like a diver, toes pointed down, confident smile;
2 rising, one knee starting to lift, back arm sweeping up, bright eyes;
3 rising higher, both knees bending elegantly, bun and earrings bouncing, joyful;
4 near the top, tucked, toes pointed, playful raised eyebrow;
5 top of the jump (apex), graceful split-leg float, eyes wide, delighted;
6 starting to fall, legs coming together downward, focused look;
7 falling, legs reaching down, back arm up for balance, a bit worried;
8 about to land, both heels pointing down ready to touch the ground, concentrated, lips pressed.
FACIAL EXPRESSIONS: a different expression in every frame, lively but readable; eyes open in every frame.
```

### Resultado do A6 (03/10)

No jogo. A cabeça veio uns 6% maior. Medidas: largura da cabeça na linha dos olhos, 162–172 px
contra 157; branco do olho, 41–43 contra 40–41. Corrigido com o fator único 0,94. A distância
coque-nariz não serve sozinha em pose inclinada: a cabeça inclinada aumenta a distância vertical.
Quadros centrados pela **cintura** (meio do maiô) em (256, 229), e não em (256, 280): em 280 o
quadro 2 passaria 39 px da célula, e 229 é a mesma altura da cintura da acrobata parada (231), então
o corpo não pula na troca. Nenhum pixel cortado no original. Detalhes no diário.

## Pedido A7 (pronto para colar)

Uso no jogo, sem mudar a mecânica: hoje o balão é desenhado por código (`core/player/balloon.gd`),
um oval rosa de 132 × 156 px na tela, que sobe devagar e balança de um lado para o outro. A folha
troca só o desenho: os quadros 1–6 tocam em loop e os 7 e 8 aparecem nos extremos do balanço. O
balão precisa ter o **mesmo tamanho em todos os quadros** (oval de 260 × 300 px na folha de
2048, meio do oval em (256, 240)), para a escala ser medida uma vez só. Conta da altura: chapéu uns
60 px acima do oval + 300 do oval + nó 15 + barbante 70 = uns 445 px, cabendo nos 488 úteis da
célula (12 px de margem em cima e embaixo).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_balao_flutua.png (replace if it exists).

References (read from the project):
- docs/referencias/combate_balao_resgate.png = how the knocked-out balloon looks in this game: a round PINK circus balloon whose front IS the character's face, glowing pink outline, little knot and curly string.
- docs/referencias/pecas/palhaco_folha.png, docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_pulo.png = the EXACT clown face: big round black eyes, red ball nose, wide expressive mouth, red hair puffs on the sides, small black top hat with a gold band and a white daisy, same ink style.

The balloon: an oval PINK circus balloon (#ff5fa2, glossy white highlight on the upper left, darker pink #c23b78 shading on the lower right, thick dark outline #1b1410). The clown's face is printed/inflated on the front of the balloon (eyes, red nose, mouth), the red hair puffs bulge out on both sides near the top, and the little black top hat with the daisy sits on top of the balloon, slightly tilted. A small knot at the bottom (pink, with dark outline) and a thin curly dark string hanging about 70 px below the knot.
SIZE (important): the oval balloon body is exactly 260 px wide and about 300 px tall in EVERY frame (the hat, hair puffs and string are extra). The top of the hat must stay at least 12 px below the top of the cell and the end of the string at least 12 px above the bottom of the cell. Keep the same size in all 8 frames; only small squash and stretch of at most 5 percent.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. The CENTER OF THE BALLOON BODY at the same point in every cell: x = 256, y = 240. Everything (hat, string, tilt) stays inside its own cell with at least 12 px of empty margin. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no shadows, no motion blur.

Style: hand-inked 1930s rubber-hose cartoon, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 8 frames:
FLOATING LOOP (frames 1 to 6; frame 6 flows back into frame 1): the balloon gently squashing and stretching, the string swaying left and right, a different face in each frame:
1 worried, eyebrows up, looking down for help;
2 pleading puppy eyes, mouth wobbling;
3 blink (eyes closed), small sigh;
4 calling out, mouth wide open "help!";
5 looking to the side, anxious;
6 hopeful little smile, looking down.
SWAYING (used at the ends of the side-to-side drift):
7 the balloon tilted about 15 degrees to the LEFT and slightly squashed, string flung to the right, scared face, eyes shut, hat holding on;
8 the same tilted about 15 degrees to the RIGHT, string flung to the left, cheeks puffed, holding breath.
FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame, always clearly the clown.
```

### Resultado do A7 (03/10)

No jogo. O oval veio uns 12% maior: 282–294 px de largura nos quadros retos (na escala 1,1545),
contra o alvo de 260. A medida é uma elipse ajustada à silhueta de fora do rosa, sem cabelo,
chapéu, nó nem barbante (âncora `balao` do `regrid_sheet.gd`). Corrigido com o fator único 0,90 e o
meio do oval em (256, 240). O barbante creme com contorno aparece bem no tamanho do jogo; aceito.
No jogo, só o desenho mudou: os quadros 1–6 em loop e o 7/8 nos extremos do balanço. A acrobata
continua com o balão de código até o A9. Detalhes no diário.

## Pedido A8 (pronto para colar)

Uso no jogo, sem mudar a mecânica: os quadros 1–4 tocam **uma vez** quando o palhaço cai (vira
balão) e então entra o loop da A7. Os 5–8 tocam **uma vez** quando o parceiro dá parry no balão
(resgate), como efeito no lugar do balão. O balão inteiro dos quadros 4 a 6 precisa ter o mesmo
tamanho e o mesmo meio da folha aprovada `palhaco_balao_flutua.png` (oval de 260 px de largura,
meio em 256, 240), para emendar sem salto com o loop.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_balao_vira_resgate.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_balao_flutua.png = the APPROVED balloon of this clown. Copy it exactly: same oval pink balloon (#ff5fa2 with glossy highlight and darker pink shading, thick dark outline #1b1410), same face style, same red hair puffs, same little black top hat with a gold band and a white daisy, same pink knot and the same cream string with dark outline. On that sheet the oval balloon body is 260 px wide, with its center at x = 256, y = 240 of each 512 x 512 cell.
- docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_folha.png = the clown's head and face before he turns into a balloon (frames 1 and 2).
- docs/referencias/combate_balao_resgate.png = the rescue moment in this game.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. The center of the head or balloon is at the same point in every cell: x = 256, y = 240. Everything stays inside its own cell with at least 12 px of empty margin (also the confetti of the pop). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no shadows, no motion blur.
SIZE: frames 4, 5 and 6 show the full balloon at EXACTLY the size of the approved sheet (oval 260 px wide, about 275 px tall); frame 3 is a bit smaller (about 220 px wide); frames 1 and 2 are the clown's head only (no body), at the same size as his head in palhaco_parado.png.

Style: hand-inked 1930s rubber-hose cartoon, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 8 frames:
TURNING INTO A BALLOON (plays once when the clown is knocked out):
1 the clown's head alone, dizzy, eyes spinning in spirals, three small stars circling the hat;
2 the head starting to puff up round and turning pink, cheeks bulging, surprised;
3 almost a full balloon (about 220 px wide), face stretched, eyes wide in panic, the knot appearing below;
4 the full balloon popping into shape with a little bounce (slightly squashed), the string appearing, embarrassed face. This frame must match the approved floating balloon so the loop can start right after it.
RESCUED BY A PARRY (plays once):
5 surprised and happy, eyes wide, big open smile, the balloon starting to stretch upward a little;
6 the balloon over-stretched (taller and narrower, about 10 percent), face laughing, hat lifting off;
7 POP: a burst of pink confetti, small gold stars and pink balloon scraps around, the clown's happy face (with hat and hair puffs) in the middle, no balloon left;
8 only a fading puff of pink confetti and gold stars, no face, smaller and lighter.
FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame with a face, always clearly the same clown.
```

### Resultado do A8 (03/10)

No jogo. O oval do 4 e do 5 veio uns 5% maior que o da A7, e a cabeça dos quadros 1–3 veio pequena
demais: uns 30% menor que a cabeça do palhaço no jogo, medindo pelo nariz de bola. Corrigido com
escala uniforme por grupo, sem deformar: 0,85 nos 4–8 e 1,20 nos 1–3. O 6 veio menor e mais estreito;
com 1,02, o rosto fica do tamanho do 5 e o balão uns 10% mais alto, que é o "esticado" pedido.
Pivôs: 3–6 pelo meio do oval em (256, 240); o 6 subiu 22 px para o barbante caber; 1, 2 e 7 pelo
nariz; o 8 pelo meio do estouro. No jogo: 1–4 tocam uma vez ao cair e 5–8 viram um efeito solto
no resgate, sem atrasar nada. Detalhes no diário.

## Pedido A9 (pronto para colar)

Mesmo uso da A7: os quadros 1–6 em loop e o 7/8 nos extremos do balanço; só o desenho muda. Lição
da A7 e da A8: o Codex tende a desenhar o balão uns 5–12% maior. O pedido manda copiar o
tamanho da folha aprovada do palhaço, que já está normalizada (oval de 260 px de largura, meio em
256, 240).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_balao_flutua.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_balao_flutua.png = the APPROVED floating balloon of the other character (the clown). Copy its balloon EXACTLY: same oval pink balloon (#ff5fa2 with glossy white highlight on the upper left and darker pink #c23b78 shading on the lower right, thick dark outline #1b1410), same SIZE and POSITION in the cell, same pink knot, same cream string with dark outline, same layout and the same 8 actions. On that sheet the oval balloon body is 260 px wide and about 275 px tall, with its center at x = 256, y = 240 of each 512 x 512 cell. Measure it and match it: do NOT make the balloon bigger.
- docs/referencias/pecas/acrobata_folha.png and docs/referencias/pecas/acrobata_parado.png = the EXACT acrobat face: big round black cartoon eyes with lashes, rosy cheeks, small red clown nose, black hair in a high round bun with a small gold star tiara, gold star earrings.
- docs/referencias/combate_balao_resgate.png = how the knocked-out balloon looks in this game.

The balloon: the acrobat's face is printed/inflated on the front of the pink balloon (eyes with lashes, rosy cheeks, red nose, mouth), black hair framing the top of the balloon like bangs, the high round black bun with the small gold star tiara sitting on top of the balloon, and the gold star earrings hanging on both sides. NO red hair puffs and NO top hat (those are the clown's). A small pink knot at the bottom and a cream string with dark outline hanging about 70 px below the knot.
SIZE (important): the oval balloon body is exactly 260 px wide and about 275 px tall in EVERY frame (the bun, earrings and string are extra). The top of the bun must stay at least 12 px below the top of the cell and the end of the string at least 12 px above the bottom of the cell. Keep the same size in all 8 frames; only small squash and stretch of at most 5 percent.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. The CENTER OF THE BALLOON BODY at the same point in every cell: x = 256, y = 240. Everything stays inside its own cell with at least 12 px of empty margin. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no shadows, no motion blur.

Style: hand-inked 1930s rubber-hose cartoon, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 8 frames:
FLOATING LOOP (frames 1 to 6; frame 6 flows back into frame 1): the balloon gently squashing and stretching, the string swaying left and right, a different face in each frame:
1 worried, eyebrows up, looking down for help;
2 pleading puppy eyes, lips trembling;
3 blink (eyes closed with long lashes), small sigh;
4 calling out, mouth wide open "help!";
5 looking to the side, anxious;
6 hopeful little smile, looking down.
SWAYING (used at the ends of the side-to-side drift):
7 the balloon tilted about 15 degrees to the LEFT and slightly squashed, string flung to the right, scared face, eyes shut, bun holding on;
8 the same tilted about 15 degrees to the RIGHT, string flung to the left, cheeks puffed, holding breath.
FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame, always clearly the acrobat.
```

### Resultado do A9 (03/10)

No jogo. O oval veio uns 10% maior de novo (mediana de 285 px na escala da folha, contra 260),
apesar do pedido de cópia exata. Corrigido com o fator único 0,91 e o meio do oval em (256, 240);
elipse conferida desenhando por cima, sem coque, franja nem brincos. Dá para reconhecer a acrobata
no tamanho do jogo. Detalhes no diário.

## Pedido A10 (pronto para colar)

Mesmo uso da A8, só o desenho: 1–4 tocam uma vez quando a acrobata cai, depois entra o loop da
A9; 5–8 tocam num efeito solto no resgate. Lição da A8: o Codex errou a escala dos quadros de cabeça
(1–3) e do balão (4–6). Agora há um modelo exato: a folha do palhaço `palhaco_balao_vira_resgate.png`
já normalizada, com os tamanhos e as posições certos. O pedido manda copiar esse layout quadro a
quadro.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_balao_vira_resgate.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_balao_vira_resgate.png = the APPROVED sheet of the same 8 actions for the other character (the clown), already at the correct sizes and positions. Copy its LAYOUT frame by frame: the same size and position of the head in frames 1 and 2, of the small balloon in frame 3, of the full balloon in frames 4, 5 and 6, and of the burst in frames 7 and 8. Measure it and match it; do NOT make anything bigger.
- docs/referencias/pecas/acrobata_balao_flutua.png = the APPROVED floating balloon of the acrobat: copy her balloon exactly for frames 4, 5 and 6 (oval pink balloon 260 px wide with its center at x = 256, y = 240 of the cell, her face on the front, black bangs, high round black bun with the small gold star tiara on top, gold star earrings on both sides, pink knot and cream string with dark outline).
- docs/referencias/pecas/acrobata_folha.png and docs/referencias/pecas/acrobata_parado.png = the EXACT acrobat face before she turns into a balloon (frames 1 and 2): big round black cartoon eyes with lashes, rosy cheeks, small red clown nose, black hair with bangs, high round bun with the gold star tiara, gold star earrings.
- docs/referencias/combate_balao_resgate.png = the rescue moment in this game.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. Everything stays inside its own cell with at least 12 px of empty margin (also the bun, the string and the confetti). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks (except the confetti pieces of frames 7 and 8, which are separate on purpose), no grid lines, no text, no shadows, no motion blur.

Style: hand-inked 1930s rubber-hose cartoon, warm painted shading, slightly worn print texture, exactly like the references.

Animation, 8 frames:
TURNING INTO A BALLOON (plays once when the acrobat is knocked out):
1 the acrobat's head alone (no body), dizzy, eyes spinning in spirals, three small gold stars circling the bun, tongue out;
2 the head starting to puff up round and turning pink at the edges, cheeks bulging, surprised "oh!";
3 almost a full balloon, a bit smaller than the final one, face stretched, eyes wide in panic, the knot appearing below;
4 the full balloon popping into shape with a little bounce, the string appearing, embarrassed face with eyes closed. This frame must match the approved floating balloon so the loop can start right after it.
RESCUED BY A PARRY (plays once):
5 surprised and happy, eyes wide, big open smile, the balloon starting to stretch upward;
6 the balloon stretched about 10 percent TALLER (same width), face laughing with eyes closed, the bun bouncing up;
7 POP: a burst of pink confetti, small gold stars and pink balloon scraps around, the acrobat's happy face (with bun, tiara and earrings, no balloon) in the middle, at the same size as her head in frame 1;
8 only a fading puff of pink confetti and gold stars, no face, smaller and lighter.
FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame with a face, always clearly the same acrobat.
```

### Resultado do A10 (03/10)

No jogo. Escala uniforme por grupo, sem deformar: 0,80 na cabeça (1–2), 0,85 no balão parcial (3),
0,91 no balão e no estouro (4, 5, 7, 8) e 0,97 no 6. Com isso o 6 fica uns 10% mais alto que o 5,
com a mesma largura, como pedido. A cabeça da acrobata foi medida pela largura do rosto, e não
pelo nariz: nas folhas de balão o nariz dela é desenhado aumentado. O barbante do 4 e a estrela do
7 encostam nas divisões da grade, mas estão inteiros. Detalhes no diário.

## Pedido A11 (pronto para colar)

Uso no jogo, só o desenho: o dash dura só 0,17 s (a 1700 px/s), então os 4 quadros são escolhidos
pelo progresso do dash: 1 no arranque, 2 e 3 no meio, 4 freando. Com a Pirueta o dash vai em 8
direções, inclusive para cima; o jogo pode girar o desenho na direção do dash. O braço da pistola
continua por código no ombro. Mudança em relação à nota antiga da fila: em vez da sola em 486, o
**meio da barriga em (256, 280)**, como no pulo e no parry, porque o corpo fica quase deitado e
muitas vezes o dash é no ar. Lição das entregas anteriores: o pedido dá a medida da cabeça para a
escala não vir errada.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_dash.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png = the EXACT clown: design, colors (red/cream harlequin suit, ruffled collar, red nose, red hair puffs, small black top hat with a gold band and a white daisy, white gloves, big brown shoes), proportions and ink style. Like in that sheet, the FRONT ARM (the gun arm, on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_pulo.png = approved sheets of this clown at the CORRECT SIZE. Match their size exactly.

SIZE (very important, earlier sheets came out 10 to 20 percent too big or too small): draw the clown at EXACTLY the same size as in palhaco_parado.png. On the 2048 x 1024 sheet he is about 406 px tall from shoe sole to hat top when standing, and the distance from the top of the hat down to the red nose is about 73 px. Keep that head size (hat, head, nose) in EVERY frame. The dash poses are long and low, so the figure is wider than tall: if a pose would come near the cell border, bend the knees or tuck the legs instead of shrinking the clown.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512. ONLY the 4 cells of the TOP row have drawings (frames 1 to 4, left to right); the 4 cells of the bottom row stay completely EMPTY and transparent. Side view, facing RIGHT. The clown is IDENTICAL in every frame; only the pose and the face change. Keep the middle of his belly at the same point in every cell: x = 256, y = 280, with at least 12 px of empty margin around the drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines (the game adds its own effects).
ARMS: only the BACK arm is drawn, BEHIND the body, swept back by the speed. NO front arm, NO gun, NO hand in front of the chest: the front shoulder area under the collar stays clean, and the red nose is always visible.

Animation: DASH (a very fast burst forward), 4 frames:
1 take-off: body leaning far forward (about 45 degrees), back leg pushing off, front knee up, hat tilting back, determined squint;
2 full speed: body stretched almost horizontal, legs straight back together, collar and hair puffs blown back, teeth clenched;
3 full speed, a variation of frame 2 (legs slightly apart, collar flapping the other way, hat brim bent by the wind), eyes half closed;
4 braking: body leaning back, front shoe sliding forward, back arm swinging forward for balance, relieved grin.
FACIAL EXPRESSIONS: a different expression in every frame, lively but readable.
```

### Resultado do A11 (03/10)

No jogo, sem ajuste de escala: o nariz e a distância chapéu-nariz batem com o parado. A fila de
baixo, que tinha 315 pixels com alpha 1, saiu com alpha 0 em todos. Os quadros foram alinhados
pelo meio do tronco xadrez em (250, 330), e não pelo meio da caixa, que caía na gola ou no cabelo.
No jogo, o quadro sai do andamento do dash (0,17 s). Na Pirueta, os quadros 1–3 giram na direção
do dash e a freada fica em pé. A freada veio mais ereta que o pedido, mas lê como freio; foi
aceita. Detalhes no diário.

## Pedido A12 (pronto para colar)

Mesmo uso do A11. Medidas da acrobata para a escala não vir errada: na folha de 2048 × 1024 ela
mede uns 465 px em pé, a cabeça mede 157 px de largura na linha dos olhos (da nuca ao nariz, de
lado) e o branco do olho mede uns 40 px de altura, como em `acrobata_parado.png`. Na conferência,
medir esses dois, e não coque-nariz, que muda com a cabeça inclinada. Pivô: cintura (meio do maiô,
a estrela dourada) no mesmo ponto em todos os quadros, com a âncora `cintura`.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_dash.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the EXACT acrobat: a TALL, SLIM, long-legged young woman (NOT short, NOT chubby). Black hair in a high round bun with a small gold star tiara, gold star earrings, big round black cartoon eyes with lashes, rosy cheeks, a small red clown nose, teal (#1f5a66) strapless leotard with thin gold shoulder straps, gold sweetheart neckline trim, a gold star at the waist and a gold zigzag hem, bare slim legs, white gloves, teal high-heel shoes with gold ankle straps and gold balls on the toes. Like in that sheet, the FRONT ARM (the gun arm, the arm on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/acrobata_parado.png and docs/referencias/pecas/acrobata_pulo.png = approved sheets of this acrobat at the CORRECT SIZE. Match their size exactly.
- docs/referencias/pecas/palhaco_dash.png = the approved dash sheet of the other character (the clown): same layout, same 4 actions, same framing.

SIZE (very important, earlier sheets came out 5 to 20 percent too big or too small): draw her at EXACTLY the same size as in acrobata_parado.png. On the 2048 x 1024 sheet she is about 465 px tall from heel to top of the bun when standing; her head is about 157 px wide at eye level (from the back of the head to the nose, in side view) and the white of her eye is about 40 px tall. Keep that head size in EVERY frame. The dash poses are long and low: if a pose would come near the cell border, bend the knees or tuck the legs instead of shrinking her.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512. ONLY the 4 cells of the TOP row have drawings (frames 1 to 4, left to right); the 4 cells of the bottom row stay completely EMPTY with alpha exactly 0 in every pixel (no faint pixels at all). Side view, facing RIGHT. The acrobat is IDENTICAL in every frame; only the pose and the face change. Keep the gold star at her waist at the same point in every cell: x = 256, y = 280, with at least 12 px of empty margin around the drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines (the game adds its own effects).
ARMS: only the BACK arm is drawn, BEHIND the body, swept back by the speed. NO front arm, NO gun, NO hand in front of the chest: the front shoulder area stays clean, and the red nose is always visible.

Animation: DASH (a very fast burst forward), 4 frames:
1 take-off: body leaning far forward (about 45 degrees) like a sprinter, back leg pushing off on the toe, front knee up, bun tilting back, determined look;
2 full speed: body stretched almost horizontal like a diver, legs straight back together with pointed toes, bun and earrings blown back, teeth clenched;
3 full speed, a variation of frame 2 (legs slightly apart in a split, earrings swinging the other way), eyes half closed;
4 braking: body leaning BACK, front heel sliding forward, back arm swinging forward for balance, relieved grin.
FACIAL EXPRESSIONS: a different expression in every frame, lively but readable; eyes open except where noted.
```

### Resultado do A12 (03/10)

No jogo. O desenho veio uns 6% maior (branco do olho 41–45 contra 40–41, nariz de lado
18–19 × 16–18 contra 17–18 × 14–15): fator único 0,94, como a A6. A cintura não cabia em
(256, 280) por causa do espacate do 3; ficou em (300, 280), e o recorte usa `center_x` 300 para a
cintura cair no mesmo x do corpo parado. Fila de baixo com alpha 0 em todos os pixels. Detalhes no
diário.

## Pedido A13 (pronto para colar)

Uso no jogo, só o desenho: o abaixar já existe por código. A caixa do corpo vai de 132 para 84 px,
e as pontes baixas do trem passam por cima de quem está abaixado. Quadro 1 enquanto desce, 2 e 3 em
loop enquanto fica abaixado, 4 enquanto levanta. A pistola continua por código no ombro, e atirar
abaixado é comum. Medidas para a escala e a altura não virem erradas: chapéu-nariz uns 73 px e nariz
uns 52 × 39 px, como no parado; abaixado, uns 240 px da sola ao topo do chapéu.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_abaixado.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png = the EXACT clown: design, colors (red/cream harlequin suit, ruffled collar, red nose, red hair puffs, small black top hat with a gold band and a white daisy, white gloves, big brown shoes), proportions and ink style. Like in that sheet, the FRONT ARM (the gun arm, on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_dash.png = approved sheets of this clown at the CORRECT SIZE. Match their size exactly.

SIZE (very important, earlier sheets came out 5 to 20 percent too big or too small): the clown's head must be EXACTLY the same size as in palhaco_parado.png: on the 2048 x 1024 sheet, the distance from the top of the hat down to the red nose is about 73 px and the red nose is about 52 px wide and 39 px tall. CROUCH HEIGHT (important for the game): when crouched (frames 2 and 3), the clown measures about 240 px from the shoe soles to the top of the hat, never more than 260 px (standing he is about 406 px). Get there by bending the knees deeply and hunching the back, NOT by drawing him smaller.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512. ONLY the 4 cells of the TOP row have drawings (frames 1 to 4, left to right); the 4 cells of the bottom row stay completely EMPTY with alpha exactly 0 in every pixel (no faint pixels at all). Side view, facing RIGHT. The clown is IDENTICAL in every frame; only the pose and the face change. Feet on the SAME ground line in every cell: the bottom of the shoes exactly at y = 486 of the cell; the feet centered around x = 256, planted in the same place in every frame. At least 12 px of empty margin around the drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur.
ARMS: only the BACK arm is drawn, BEHIND the body (resting on the back knee or hanging down). NO front arm, NO gun, NO hand in front of the chest: the front shoulder area under the collar stays clean, and the red nose is always visible.

Animation: CROUCH, 4 frames:
1 going down: knees bending halfway (about 320 px tall), body starting to hunch, eyes squinting, bracing;
2 fully crouched and alert (about 240 px tall): deep knee bend, back hunched, head low with the hat pressed down a little, eyes wide looking forward, lips pressed;
3 the same crouch, a tiny variation for a 2-frame loop (body 2 or 3 px lower, collar settled, a quick glance up), same height within 5 px of frame 2;
4 getting up: knees halfway straight (about 320 px tall), body rising, relieved little smile.
FACIAL EXPRESSIONS: a different expression in every frame, lively but readable; eyes open.
```

## Histórico: A13 recusada e pedido A13b (correção focal com medidas do jogo)

Diagnóstico da A13 (03/10, `originais/palhaco_abaixado_codex_1774x887.png`, normalizada só para
conferência):
- **O que passou:** escala (nariz 4–7% menor que no parado, dentro da tolerância), pés plantados,
  margens, fila de baixo zerada, duas pernas e dois sapatos, só o braço de trás.
- **O que reprovou:** abaixado, o jogo atira de uma altura fixa: o ombro da pistola fica 64 px
  acima dos pés e a boca a 67 (na folha, ombro em uns (322, 343), com o braço indo para a direita
  nessa altura). Isso não pode mudar (é a altura do tiro). Nos quadros 2 e 3 a cabeça desce até
  os joelhos, bem nessa faixa: a pistola cobre os olhos (braço na frente) ou some atrás da cabeça
  (braço atrás, testado). Nos 1 e 4 o braço passa pela boca.
- **No jogo:** continua o abaixar de peças; o código para o abaixado desenhado está pronto
  (`crouch_animation`).

### Correção das medidas (03/10, apontada pelo Codex)

A primeira versão do A13b e do A14 pedia medidas impossíveis. O "topo do chapéu até o nariz de
uns 73 px" vinha da opção `medir` do `regrid_sheet.gd`, que pega a primeira linha com qualquer
vermelho; no palhaço essa linha é a do cabelo vermelho, não a do nariz. Medido de novo no
`palhaco_parado.png` aprovado (2048 × 1024, sola em 486), quadro 1:
- topo do chapéu em y = 52; nariz (preenchido a partir dele) com 50 × 39 px, centro (352, 216):
  do topo ao nariz são **164 px**; queixo por volta de y = 260 (cabeça inteira, do topo ao queixo,
  uns 208 px); gola de y 240 a 295; ombro da pistola em pé em (352 − 64, 216 + 60) = (288, 276),
  dentro da gola, 16 px abaixo do queixo.

Acrobata (`acrobata_parado.png`, quadro 1): topo do coque em y = 22; nariz com 16 × 14 px, centro
(315, 141): do topo ao nariz são **119 px**; queixo por volta de y = 180; ombro da pistola em pé
em (270, 196), 16 px abaixo do queixo.

Conta compatível, mantendo a cabeça do tamanho real e o braço saindo da gola logo abaixo do
queixo, como em pé:
- **Palhaço abaixado:** ombro da pistola em (322, 343) → queixo por volta de 327 → nariz em uns
  (386, 283) → topo do chapéu por volta de 119. Altura abaixado de uns 355–375 px (uns 165 px no
  jogo, praticamente o mesmo que o abaixar de peças de hoje). A cabeça desce só uns 67 px em
  relação ao parado: o abaixar fica nas pernas dobradas e nas costas curvadas.
- **Acrobata abaixada:** ombro em (339, 299) → queixo por volta de 283 → nariz em uns (384, 244) →
  topo do coque por volta de 125. Altura de uns 350–370 px.

**Limite real de altura no jogo:** a caixa de colisão abaixada (84 px) não depende do desenho. O
limite do desenho vem da altura do tiro abaixado: com a cabeça acima do braço, o palhaço abaixado
mede uns 165 px no jogo, o mesmo do abaixar de peças de hoje. As pontes baixas do trem (100 px
acima do teto do vagão) já passam por cima do chapéu desenhado hoje. Desenhar o personagem
abaixado inteiro abaixo da ponte exigiria baixar a altura do tiro abaixado, uma mudança de
mecânica que fica para o usuário decidir e não faz parte deste pedido.

O texto do pedido A11 também dizia "topo do chapéu até o nariz uns 73 px". A conferência do A11
comparou a mesma medida (até o cabelo) dos dois lados e também o nariz de verdade, então a escala
aprovada continua certa; só o texto do pedido estava errado.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit docs/referencias/pecas/originais/palhaco_abaixado_codex_1774x887.png and save the result INSIDE the project at exactly: docs/referencias/pecas/palhaco_abaixado_v2.png (do NOT overwrite any other file).

Keep the same clown, the same faces, the same shoes planted on the same ground line, the same back arm, and the bottom row completely empty (alpha exactly 0 in every pixel). Keep the head EXACTLY its real size (do NOT shrink or squash the head or the hat). Redraw the crouch so the head sits HIGHER, on top of a crouched body, as described below.

All measurements are for a 2048 x 1024 version of the sheet, inside each 512 x 512 cell, with the shoe soles at y = 486 (on the 1774 x 887 file, multiply every number by 0.866).

THE CLOWN'S REAL HEAD (from the approved docs/referencias/pecas/palhaco_parado.png): top of the hat to the center of the red nose = 164 px; red nose about 50 x 39 px; center of the nose to the bottom of the chin = about 44 px; the ruffled collar sits right under the chin.

THE GUN LINE (fixed by the game, do not change): while crouching, the game draws the gun arm by code from the front shoulder at about x = 322, y = 343, pointing straight forward (to the right) at that height. The arm must come out of the RUFFLED COLLAR, just under the chin, exactly like when he stands. So:
- frames 2 and 3 (fully crouched): chin at about y = 327, red nose center at about x = 386, y = 283, top of the hat at about y = 119 (total height from shoe soles to hat top about 355 to 375 px); the collar / front shoulder around x = 300 to 340, y = 320 to 360; NOTHING of the face (eyes, nose, mouth, cheeks) below y = 330 to the right of x = 300;
- frames 1 and 4 (halfway): red nose center at about y = 250, total height about 395 to 410 px, same rule (face above the collar, collar where the arm starts);
- the crouch is shown by the legs and back: deep knee bend, knees forward, back curved, body leaning slightly forward; the head stays up, looking forward.
Frames 2 and 3 stay almost identical (2-frame loop: 2 or 3 px of breathing, a quick glance). At least 12 px of empty margin inside every cell. Fully TRANSPARENT background (real alpha), clean edges, same 1930s hand-inked style, same canvas size and layout as the input.
```

## Pedido A14 (pronto para colar; mandar depois do A13b)

Mesmo uso e mesma regra do A13b, com as medidas corrigidas da acrobata: abaixada, o ombro da
pistola dela fica 93 px acima dos pés no jogo, ou seja, na folha, em uns (339, 299).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_abaixado.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the EXACT acrobat: a TALL, SLIM, long-legged young woman (NOT short, NOT chubby). Black hair in a high round bun with a small gold star tiara, gold star earrings, big round black cartoon eyes with lashes, rosy cheeks, a small red clown nose, teal (#1f5a66) strapless leotard with thin gold shoulder straps, gold sweetheart neckline trim, a gold star at the waist and a gold zigzag hem, bare slim legs, white gloves, teal high-heel shoes with gold ankle straps and gold balls on the toes. Like in that sheet, the FRONT ARM (the gun arm) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/acrobata_parado.png and docs/referencias/pecas/acrobata_dash.png = approved sheets of this acrobat at the CORRECT SIZE. Match their size exactly.

All measurements are for the 2048 x 1024 sheet, inside each 512 x 512 cell, with the heels at y = 486.

HER REAL HEAD (from acrobata_parado.png): top of the bun to the center of the red nose = 119 px; red nose about 16 x 14 px; center of the nose to the bottom of the chin = about 39 px; head about 157 px wide at eye level (side view, back of the head to the nose); white of the eye about 40 px tall. Keep that size in every frame (do NOT shrink or squash the head or the bun).

THE GUN LINE (fixed by the game): while she crouches, the game draws the gun arm by code from her front shoulder at about x = 339, y = 299, pointing straight forward (to the right) at that height. The arm must come out of the front shoulder / neckline, just under the chin, exactly like when she stands. So:
- frames 2 and 3 (fully crouched): chin at about y = 283, red nose center at about x = 384, y = 244, top of the bun at about y = 125 (total height from heels to the top of the bun about 350 to 370 px); NOTHING of the face below y = 285 to the right of x = 320;
- frames 1 and 4 (halfway): red nose center at about y = 205, total height about 400 to 415 px, same rule;
- the crouch is shown by the legs and back: deep knee bend like a sprinter in the blocks, knees forward, back leaning slightly forward; the head stays up, looking forward.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512. ONLY the 4 cells of the TOP row have drawings (frames 1 to 4, left to right); the 4 cells of the bottom row stay completely EMPTY with alpha exactly 0 in every pixel. Side view, facing RIGHT. The acrobat is IDENTICAL in every frame; only the pose and the face change. Feet planted on the SAME ground line in every cell: the bottom of the shoes exactly at y = 486; the feet centered around x = 256, in the same place in every frame. At least 12 px of empty margin around the drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur.
ARMS: only the BACK arm, BEHIND the body (resting on the back knee). NO front arm, NO gun.

Animation: CROUCH, 4 frames:
1 going down: knees bending halfway, body lowering, eyes narrowing, bracing;
2 fully crouched and alert: deep knee bend, head up looking forward, lips pressed;
3 the same crouch, a tiny variation for a 2-frame loop (2 or 3 px lower, a quick glance up), same height within 5 px of frame 2;
4 getting up: knees halfway straight, body rising, relieved little smile.
FACIAL EXPRESSIONS: a different expression in every frame, lively but readable; eyes open.
```

### Resultado do A13b (03/10)

No jogo. A cabeça ficou em pé, uns 3–7% menor que no parado (do topo do chapéu ao nariz
153–161 px, contra 165), dentro da tolerância e sem ajuste de escala. Alturas 383, 371, 372 e 378 px.
Os quadros 1 e 4 ficaram mais agachados que os 395–410 pedidos, mas no movimento não pulam. No
jogo, o braço da pistola sai da frente do tronco, logo abaixo da gola, com o rosto livre e a
pistola inteira; ombro, mão e boca da pistola nas mesmas posições de antes (a altura do tiro não
mudou). Detalhes no diário. Próximo: A14, com o mesmo critério de conferência: modo
`screenshots.tscn -- abaixado2`, rosto livre, pistola inteira e posições iguais às de antes.

### Resultado do A14 (03/10)

No jogo, com fator 1,0 (o branco do olho e o nariz batem com o parado; a distância coque-nariz muda
com a cabeça inclinada). Nos quadros 2 e 3 o braço da pistola sai do decote, abaixo do queixo,
com o rosto e a pistola livres, e ombro, mão e boca da pistola ficam nas mesmas posições de antes.
Defeito achado no jogo e corrigido só no desenho: nos quadros de meio caminho (1 e 4) o braço
cruzava o rosto, porque o ombro desce aos poucos enquanto o personagem abaixa. Agora o quadro de
meio caminho só aparece depois de 60% do abaixar; antes disso fica o desenho em pé. Vale para os
dois personagens. Detalhes no diário.

## Pedido A15 (pronto para colar)

Uso no jogo, só o desenho: quando leva um golpe, o personagem é jogado para trás e para cima
(450 px/s para trás, 420 px/s para cima) e fica 0,22 s atordoado; depois pisca invencível por
1,5 s. Os 4 quadros serão escolhidos pelo andamento desses 0,22 s, quase sempre no ar, então o
pivô é o meio do corpo em (256, 280), como no pulo. O braço da pistola continua por código no ombro.
Medidas reais da cabeça, conferidas no `palhaco_parado.png` aprovado com a medida de nariz corrigida.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_dano.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png = the EXACT clown: design, colors (red/cream harlequin suit, ruffled collar, red nose, red hair puffs, small black top hat with a gold band and a white daisy, white gloves, big brown shoes), proportions and ink style. Like in that sheet, the FRONT ARM (the gun arm, on the side facing the viewer) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/palhaco_parado.png and docs/referencias/pecas/palhaco_pulo.png = approved sheets of this clown at the CORRECT SIZE. Match their size exactly.

SIZE (very important, earlier sheets came out 5 to 20 percent too big or too small). All measurements are for the 2048 x 1024 sheet: the clown standing is about 435 to 448 px tall from shoe sole to hat top; from the top of the hat to the CENTER of the red nose is 164 px; the red nose is about 50 px wide and 39 px tall; from the center of the nose to the bottom of the chin is about 44 px. Keep that head size in EVERY frame (do NOT shrink or squash the head or the hat; a tilted head may change the vertical distances, but not the size of the nose, eyes and hat).

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512. ONLY the 4 cells of the TOP row have drawings (frames 1 to 4, left to right); the 4 cells of the bottom row stay completely EMPTY with alpha exactly 0 in every pixel (no faint pixels at all). Side view, facing RIGHT (he is knocked BACKWARD, to the left). The clown is IDENTICAL in every frame; only the pose and the face change. He is in the AIR in every frame: keep the middle of his body (the belly) at the same point in every cell, x = 256, y = 280, with at least 12 px of empty margin around the whole drawing inside its cell (including stars and sweat drops). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.
ARMS: only the BACK arm is drawn, BEHIND the body, flung by the hit. NO front arm, NO gun, NO hand in front of the chest: the front shoulder area under the collar stays clean, and the red nose is always visible.

Animation: HURT (knocked back and up by a hit), 4 frames:
1 the hit: body jolted backward, eyes popping out wide, mouth open in an "ow!", hat jumping off the head a little, three small stars around the head;
2 thrown back: body arched backward, legs flying forward, eyes squeezed shut in pain, teeth clenched;
3 shock: body curled, hair puffs standing on end, hat tilted, eyes wide and shaky, sweat drops;
4 recovering: body straightening, legs coming down under him, hat settling back, annoyed frown, ready to fight.
FACIAL EXPRESSIONS: a different, exaggerated expression in every frame, always clearly the same clown.
```

### Resultado do A15 (03/10)

No jogo, com fator 1,0. Narizes de 42–49 × 36–37 px, contra 50 × 39 no parado; o quadro 1 tem o
nariz mais estreito porque a cabeça está reclinada e virada, mas chapéu, olho e cabelo têm o mesmo
tamanho dos outros quadros. Pivô: o meio do tronco xadrez em (256, 332) nos 4 quadros, como no pulo
e no dash. Nos quadros reclinados (1 e 2) o ombro da pistola foi medido à mão (opção nova `shoulders`
do recorte), porque a regra do nariz cairia na boca. O piscar da invencibilidade agora começa depois
dos 0,22 s do susto, senão o quadro do impacto não aparecia; a invencibilidade em si não mudou.
Limitação aceita: no quadro 3 o braço passa rente ao queixo. Detalhes no diário.

## Pedido A16 (pronto para colar)

Mesmo uso do A15 (4 quadros pelo andamento dos 0,22 s de susto, quase sempre no ar). Medidas reais
da acrobata, conferidas no `acrobata_parado.png` aprovado com a medida de nariz corrigida. Pivô: a
estrela dourada da cintura no mesmo ponto em todos os quadros; na preparação, a âncora `cintura`.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_dano.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the EXACT acrobat: a TALL, SLIM, long-legged young woman (NOT short, NOT chubby). Black hair in a high round bun with a small gold star tiara, gold star earrings, big round black cartoon eyes with lashes, rosy cheeks, a small red clown nose, teal (#1f5a66) strapless leotard with thin gold shoulder straps, gold sweetheart neckline trim, a gold star at the waist and a gold zigzag hem, bare slim legs, white gloves, teal high-heel shoes with gold ankle straps and gold balls on the toes. Like in that sheet, the FRONT ARM (the gun arm) is NOT drawn: the game adds the arm holding the gun from the front shoulder.
- docs/referencias/pecas/acrobata_parado.png and docs/referencias/pecas/acrobata_pulo.png = approved sheets of this acrobat at the CORRECT SIZE. Match their size exactly.
- docs/referencias/pecas/palhaco_dano.png = the approved hurt sheet of the other character (the clown): same 4 actions, same framing, same kind of stars and sweat drops.

SIZE (very important, earlier sheets came out 5 to 20 percent too big or too small). All measurements are for the 2048 x 1024 sheet: standing, she is about 465 px tall from heel to the top of the bun; from the top of the bun to the CENTER of the red nose is 119 px; the red nose is about 16 x 14 px; from the center of the nose to the bottom of the chin is about 39 px; her head is about 157 px wide at eye level (side view, back of the head to the nose); the white of her eye is about 40 px tall. Keep that head size in EVERY frame (do NOT shrink or squash the head or the bun; a tilted head may change vertical distances, but not the size of the nose, eyes and bun). Her body poses may be compact (curled, legs bent), but never smaller.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512. ONLY the 4 cells of the TOP row have drawings (frames 1 to 4, left to right); the 4 cells of the bottom row stay completely EMPTY with alpha exactly 0 in every pixel (no faint pixels at all). Side view, facing RIGHT (she is knocked BACKWARD, to the left). The acrobat is IDENTICAL in every frame; only the pose and the face change. She is in the AIR in every frame: keep the gold star at her waist at the same point in every cell, x = 256, y = 260, with at least 12 px of empty margin around the whole drawing inside its cell (including the bun, stars and sweat drops). If a stretched pose would come near the cell border, bend the legs instead of shrinking her. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.
ARMS: only the BACK arm is drawn, BEHIND the body, flung by the hit. NO front arm, NO gun, NO hand in front of the chest: the front shoulder / neckline area stays clean, and the red nose is always visible.

Animation: HURT (knocked back and up by a hit), 4 frames:
1 the hit: body jolted backward, eyes popping wide, mouth open in an "ow!", bun and tiara jolted, three small gold stars around the head;
2 thrown back: body arched backward, legs flying forward with pointed toes, eyes squeezed shut in pain, teeth clenched;
3 shock: body curled, bun loosened a little with a few strands sticking out, eyes wide and shaky, sweat drops;
4 recovering: body straightening, legs coming down under her, tiara settling, annoyed frown, ready to fight.
FACIAL EXPRESSIONS: a different, exaggerated expression in every frame, always clearly the same acrobat.
```

### Resultado do A16 (03/10)

No jogo, com fator 1,0 (o branco do olho é igual ao do parado; o nariz desenhado menor é detalhe
do desenho). Pivô na estrela da cintura em (256, 280), alinhada à mão, porque a âncora `cintura` se
confundia com um sapato no quadro encolhido. O recorte usa `ground_y` 537 para a cintura ficar à
mesma distância dos pés que no pulo. Nos quadros reclinados, o ombro da pistola foi medido à mão. Com
isso, o bloco A (jogadores) está completo no jogo. Detalhes no diário.

## Pedido B1 (pronto para colar)

Uso no jogo, só o desenho: hoje o salto do Leopoldo usa os 4 quadros de `leao_pulo.png`, e o corpo
gira na direção do movimento. O B1 traz o arco inteiro em 8 quadros, escolhidos pela fase do salto:
1 agachado (antes de sair), 2 saída, 3 subindo, 4 e 5 no alto, 6 descendo, 7 perto do chão,
8 pouso. Medidas do leão aprovado, na folha de 2048 de largura, células de 1024 × 512:
- **Parado:** 513–556 × 387–396 px, patas em y 482, meio em x uns 506.
- **Cabeça:** juba de uns 285 × 318 px; nariz de uns 35 × 28 px.
- **Corrida:** 645–705 × 283–347 px.
- **Voo atual** (`leao_pulo.png`, quadro 3): 825 × 289 px, meio do tronco por volta de (590, 335).
- **Regra do usuário:** manter as proporções exatas, nunca esticar até 880 de largura.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_salto.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/leao/leao_folha.png, leao_parado.png, leao_corrida.png, leao_rugido.png and leao_pulo.png (all in docs/referencias/pecas/leao/) = Leopoldo, the EXACT lion: same design, colors (golden body, big dark red-brown mane, dark brown nose, cream muzzle and paws, tail with a dark tuft), proportions and ink style. These sheets are approved: match their SIZE exactly.

SIZE (very important; earlier sheets came out 5 to 20 percent too big or too small, and the lion must NEVER be stretched): all measurements are for this 2048-wide sheet with cells of 1024 x 512. Standing, the lion is about 513 to 556 px wide and about 390 px tall; his mane is about 285 px wide and 318 px tall; his dark nose is about 35 x 28 px. Running he is about 650 px long. In the current flight drawing (leao_pulo.png, third frame) he is about 825 px long and 289 px tall. Keep that same head, mane and body size in EVERY frame; keep his real proportions (never stretch him to fill 880 px).

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 2048, grid of 2 columns x 4 rows, cells of 1024 x 512, one frame per cell, read left to right, top row first. Side view, facing LEFT. The lion is IDENTICAL in every frame; only the pose and the face change. Frames 1 and 8 are on the ground: the bottom of the paws exactly at y = 482 of the cell, the body centered around x = 506. Frames 2 to 7 are in the air: keep the middle of his TORSO (belly, between front and back legs) at the same point in every cell, x = 590, y = 335, exactly like the flight frame of leao_pulo.png. At least 12 px of empty margin around the whole drawing (mane, tail tuft, paws) inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha, not black, not a checkerboard), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.

Animation: FULL LEAP ARC of a showman leap through circus hoops, 8 frames:
1 deep crouch, ready to spring, smug grin, eyes on the target;
2 explosive take-off, body stretched diagonally upward to the left, back legs still pushing, mouth open in a cocky "hah!";
3 rising, front legs reaching forward and up, mane and tail streaming back;
4 apex, body fully horizontal and stretched long like a showman (same length as the flight frame of leao_pulo.png, not longer), eyes closed, proud smile;
5 apex variation, tail curling, one eye opening to wink at the audience;
6 starting to fall, front paws reaching down and forward, focused eyes;
7 just before landing, front paws extended down toward the ground, back legs tucked, mouth closed tight in effort;
8 landing impact on the ground, body squashed low, paws spread wide, cheeks puffed, eyes squeezed.
FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated expression in every frame, always clearly the same lion.
```

## Histórico: B1 recusada e pedido B1b (correção focal com medidas)

Diagnóstico da B1 (03/10, `leao/originais/leao_salto_codex_1254x1254.png`): anatomia e expressões
boas, mas a cabeça muda de tamanho entre os quadros. Nariz na escala 2048: quadro 2 = 30 × 24 (igual
ao aprovado, 31–34 × 23–27), quadro 1 = 26 × 20, quadros 4, 5 e 7 = 21–23 × 16–18 (uns 35% menor que
o 2). Nenhum fator único deixa todos certos, e escalar cada quadro diferente deformaria o corpo.
No jogo continua o `leao_pulo.png`.

Medidas-alvo: o tamanho dos quadros aprovados de `leao_pulo.png` (que já está no jogo) e o nariz do
leão aprovado. Como o gerador entrega a folha quadrada em 1254 × 1254, o pedido traz os números nas
duas escalas (1254 = 2048 × 0,6123).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit docs/referencias/pecas/leao/originais/leao_salto_codex_1254x1254.png and save the result INSIDE the project at exactly: docs/referencias/pecas/leao/leao_salto_v2.png (do NOT overwrite any other file).

Keep the same 8 poses, the same faces and expressions, the same order (2 columns x 4 rows), facing LEFT, and the same lion design. Fix ONLY the SIZE of each frame, so the lion is the SAME size in all 8 frames and the same size as the approved sheets.

PROBLEM: the head changes size between frames. Measured by the dark brown nose: frame 2 is correct, frame 1 is about 15 percent too small, frames 4, 5 and 7 are about 30 percent too small (and their heads are also small compared with their own bodies).

TARGET (from the approved docs/referencias/pecas/leao/leao_pulo.png and leao_parado.png). Numbers for a 1254 x 1254 sheet (cells of 627 x 313.5); numbers for a 2048 x 2048 sheet (cells of 1024 x 512) in brackets:
- dark brown nose about 20 x 15 px [32 x 25] in EVERY frame; mane about 175 px wide and 195 px tall [285 x 318] when seen from the side;
- frame 1 (crouch): about 400 x 191 px [654 x 312], same size as the first frame of leao_pulo.png;
- frame 2 (take-off diagonal): about 457 x 264 px [747 x 431], same size as the second frame of leao_pulo.png;
- frame 3 (rising) and frames 6 and 7 (falling): between those two sizes, at most 270 px tall [440];
- frames 4 and 5 (apex, horizontal): about 505 x 177 px [825 x 289], same size as the third frame of leao_pulo.png, NOT longer;
- frame 8 (landing): about 444 x 198 px [725 x 324], same size as the fourth frame of leao_pulo.png.
Keep the real proportions of the lion (head, mane, body, legs and tail in the same proportion as in leao_parado.png); never stretch him.

POSITION in each cell: frames 1 and 8 on the ground, the bottom of the paws at y = 295 [482] of the cell, the body centered around x = 310 [506]. Frames 2 to 7 in the air: the middle of the TORSO (between front and back legs) at x = 361, y = 205 [590, 335] of the cell. At least 8 px [12] of empty margin around the whole drawing (mane, tail tuft, paws) inside its cell; nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges, same 1930s hand-inked style, same canvas size and layout as the input.
```

### Resultado do B1b (03/10)

No jogo como `leao/leao_salto.png`, com fator único: na escala 2048 é 1,0, ou seja, a folha de 1254
ampliada por 1,6332. O original está em `leao/originais/leao_salto_v2_codex_1254x1254.png`.

Nariz por quadro, de 1 a 8: 34 × 24, 35 × 29, 31 × 19, 30 × 20, 31 × 21, 32 × 22, 32 × 24 e 32 × 24.
O aprovado mede 31–34 × 23–27. Nos quadros 3–5 o nariz sai mais baixo porque a cabeça está deitada,
mas a largura bate. Olhos, focinho e juba têm o mesmo tamanho do parado e do voo aprovados, conferidos
lado a lado.

**Desvios aceitos (tamanho do desenho):**
- Voo 4 e 5: 772–784 de largura, contra 825.
- Pouso 8: 621 × 337, contra 725 × 324.
- Agachado 1: 622 × 303, contra 654 × 312.

Nada foi esticado.

**Alinhamento** (por posição, sem escala própria):
- Quadros 1 e 8: sola em y 482, meio em x 506.
- Quadros 2 a 7: tronco no mesmo ponto do voo antigo.
- Exceção: no quadro 6 o tronco fica 19 px mais alto, para as patas caberem na margem de baixo.

**Como entra no jogo:** cada quadro é escolhido pela direção do voo, como antes:

| Momento | Quadro |
|---|---|
| Agachado e deitado | 1 |
| Saída (primeiros 0,12 s) | 2 |
| Subindo | 3 |
| No alto | 4, e depois de 0,1 s o 5 |
| Descendo | 6, e depois de 0,1 s o 7 |
| Pouso | 8 |

As chamas da fase 3 agora ficam sobre a juba em cada quadro. Antes, no voo, elas apareciam à frente
da cabeça. Trajetória, tempo, colisão e rede não mudaram. Fotos: `screenshots.tscn -- leao`.

## Pedido B2 (pronto para colar)

Uso no jogo, só o desenho: na fase 3 da luta do Domador o leão fica "em fogo". Hoje isso é feito por
código: um desenho de chamas solto sobre a juba e o leão tingido de laranja (`set_on_fire` no
`bosses/tamer/lion.gd`). O B2 troca o parado por uma versão com a juba feita de fogo. Mesmas células,
pés e tamanho do `leao_parado.png` aprovado, para trocar quadro por quadro sem salto. Medidas do
parado aprovado (2048 × 1024, células de 1024 × 512):
- **Corpo:** 513–556 × 387–396 px, patas em y 482, meio em x uns 506.
- **Juba:** uns 285 × 318 px.
- **Nariz:** 32 × 25 px.
- **Referência da cabeça de fogo:** está na `leao_folha.png`, à direita.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_fogo_parado.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/leao/leao_parado.png = the APPROVED idle sheet of Leopoldo the lion: copy its 4 frames EXACTLY (same body, same pose, same breathing, same size and position in each cell, same paws on the same ground line). Only the mane and the face change.
- docs/referencias/pecas/leao/leao_folha.png = the lion's design sheet; the head on the far right shows the FIRE MANE: the mane is made of orange and yellow cartoon flames (with red-orange tips and a dark outline) instead of fur, same head shape.

SIZE AND POSITION (copy leao_parado.png): canvas exactly 2048 x 1024, (if the image tool cannot make 2048 x 1024, keep the same 2 x 2 layout with 2:1 cells and scale EVERY number below by the same factor; say the real size when you deliver), grid of 2 columns x 2 rows, cells of 1024 x 512, one frame per cell, read left to right, top row first. Side view, facing LEFT. In every cell the lion is about 513 to 556 px wide and about 390 px tall (the flames may rise up to about 40 px higher than the fur mane, never more), the bottom of the paws exactly at y = 482, the body centered around x = 506. His head is the same size as in leao_parado.png (dark brown nose about 32 x 25 px; the flame mane about the size of the fur mane, about 285 x 318 px, plus the flame tips). At least 12 px of empty margin around the whole drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no glow outside the drawing.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references. The body keeps its normal golden colors (the game adds the orange tint by itself).

Animation: IDLE ON FIRE, 4 frames (a breathing loop, frame 4 flows back into frame 1, same body motion as leao_parado.png):
1 flames of the mane licking upward, angry wild eyes, a snarl showing a few teeth;
2 flames flickering to the other side, nostrils flaring, eyes narrowed;
3 flames taller, mouth half open in a low growl, eyebrows down;
4 flames settling, wild grin, one eye twitching.
The flames must change shape in every frame (flickering fire), always attached to the head like a mane, and never cover the eyes or the nose.
FACIAL EXPRESSIONS: angry and wild in every frame, a different expression each time, always clearly the same lion.
```

### Resultado do B2 (03/10)

No jogo como `leao/leao_fogo_parado.png`. O original está em
`leao/originais/leao_fogo_parado_codex_1774x887.png`.

**Tamanho:** o gerador redesenhou o leão uns 9% maior que o parado. Corrigi com um fator único de 0,92
(a 1774 de largura isso dá ×1,0622) na folha inteira.

| Medida | Antes do fator | Depois do fator | Parado aprovado |
|---|---|---|---|
| Patas, de ponta a ponta | 516–521 | 475–480 | 468–475 |
| Dorso, acima da sola | 228 | 209–210 | 209–216 |
| Nariz | — | 30–35 × 22–26 | 31–32 × 24–25 |

**Alinhamento:**
- Sola em y 482.
- Meio das patas em x 529, como no parado. A caixa inteira não serve de referência, porque as chamas vão
  mais para a esquerda.

**No jogo:**
- Parado em fogo usa estes 4 quadros e esconde as chamas soltas por código, para não ter fogo em dobro.
- Nas outras poses as chamas soltas continuam até chegarem as folhas delas.
- O tom alaranjado continua por código.
- Fotos: `screenshots.tscn -- leao_fogo`.

## Pedido B3 (pronto para colar)

**Uso no jogo:** na fase 3 do Domador, a Investida (`Charge`) faz o leão correr pela arena em fogo.
Hoje a corrida usa os 8 quadros do `leao_corrida.png` a 14 quadros por segundo, com as chamas soltas
por código. O B3 troca a corrida por uma versão com a juba de fogo, quadro a quadro, sem salto.

**Medidas do `leao_corrida.png` aprovado** (2048 × 2048, células de 1024 × 512):
- Caixas por quadro: 647 × 347, 658 × 341, 645 × 320, 655 × 326, 653 × 321, 705 × 283, 648 × 338 e
  652 × 337.
- Sola em y 481–482 nos quadros com patas no chão. Nos quadros 3 e 6, que estão no ar, a sola fica em
  453 e 446.
- Caixa de x 160–188 até x 833–864.
- Nariz de uns 32 × 24.

**Lição do B2:** o corpo veio 9% grande. O pedido traz o vão das patas para conferir e as medidas também
na escala 1254, em que o gerador costuma entregar.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_fogo_corrida.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/leao/leao_corrida.png = the APPROVED run sheet of Leopoldo the lion: copy its 8 frames EXACTLY (same body, same legs and paws, same tail, same pose in each frame, same size and the same position in each cell). Only the mane and the face change.
- docs/referencias/pecas/leao/leao_fogo_parado.png = the APPROVED fire-mane idle of the same lion: copy its FIRE MANE (orange and yellow cartoon flames with red-orange tips and a dark outline, attached to the head like a mane) and its angry face style.
- docs/referencias/pecas/leao/leao_folha.png = the lion's design sheet (fire head on the far right).

SIZE AND POSITION (copy leao_corrida.png): canvas exactly 2048 x 2048, grid of 2 columns x 4 rows, cells of 1024 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 2048, make a square canvas with the same 2 x 4 layout and scale EVERY number below by the same factor (for 1254 x 1254 the numbers are in brackets); say the real size when you deliver.
Side view, facing LEFT. In every cell the lion has the same size as in the same frame of leao_corrida.png: about 645 to 705 px long [395 to 432] and 283 to 347 px tall [173 to 212] without the flames; the flames may rise up to about 40 px [25] above the fur mane, never more. In frames 1, 2, 4, 5, 7 and 8 the bottom of the lowest paw is exactly at y = 481 [295] of the cell; frames 3 and 6 are the airborne strides, with the paws at about y = 453 and 446 [277 and 273], exactly like leao_corrida.png. The lion is drawn between about x = 160 and 864 [98 and 529] of the cell, like the reference. His head is the same size as in leao_corrida.png and leao_fogo_parado.png: dark brown nose about 32 x 24 px [20 x 15]. The body must NOT be bigger than the reference (an earlier fire sheet came out 9 percent too big): check that the body, legs and paws match leao_corrida.png frame by frame. At least 12 px [8] of empty margin around the whole drawing (flames, tail tuft, paws) inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no glow outside the drawing, no motion blur, no speed lines.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references. The body keeps its normal golden colors (the game adds the orange tint by itself).

Animation: RUN ON FIRE, 8 frames (the same gallop cycle as leao_corrida.png; frame 8 flows back into frame 1). The FIRE MANE streams BACKWARD like a torch (the flames lean to the right, away from the running direction), a little different in every frame (flickering fire), always attached to the head, never covering the eyes or the nose.
FACIAL EXPRESSIONS: furious grin showing teeth, wild eyes; vary a little between frames (snarl, growl, toothy grin, eyes narrowed), always clearly the same lion as leao_fogo_parado.png.
```

### Resultado do B3 (03/10)

No jogo como `leao/leao_fogo_corrida.png`. O original está em
`leao/originais/leao_fogo_corrida_codex_1254x1254.png`.

**Tamanho:** de novo uns 10% grande. Corrigi com um fator único de 0,91 na folha inteira.

| Medida | Como veio | Depois do fator | Corrida aprovada |
|---|---|---|---|
| Vão das patas, por quadro | 2–15% maior (mediana 12%) | média 2% maior | — |
| Caixas | — | 606–709 × 267–337 | 645–705 × 283–347 |
| Nariz | 33–38 | 30–34 × 21–26 | 30–33 × 24–25 |

**Alinhamento:**
- Solas em 481–482 nos quadros com patas no chão.
- Quadros 3 e 6 no ar, nas mesmas alturas da corrida aprovada (453 e 446).
- Caixa centrada em x 512.

**Manchas marrons sob o peito** (quadros 1, 5 e 8): são o resto da juba de pelo do lado de lá. No
tamanho do jogo parecem sombra, e o B2 tem a mesma coisa. Aceitas; o B4 pede fogo também ali.

**No jogo:**
- Correndo em fogo usa estes 8 quadros, a 14 por segundo, e esconde as chamas soltas.
- Salto, rugido e agachado continuam com as chamas soltas.
- Fotos: `screenshots.tscn -- leao_fogo`, segunda fila.

## Pedido B4 (pronto para colar)

**Uso no jogo:** na fase 3 do Domador, os Pulos nos Pedestais (`Hops`) e a Investida usam o salto com
o leão em fogo. Hoje o salto usa os 8 quadros do `leao_salto.png` (B1b, já aprovado) com as chamas
soltas por código. O B4 troca o salto por uma versão com a juba de fogo, quadro a quadro.

**Medidas do `leao_salto.png` aprovado** (2048 × 2048, células de 1024 × 512):

| Quadro | Caixa (x, y) | Tamanho |
|---|---|---|
| 1 | 197–814, 182–480 | 618 × 299 |
| 2 | 198–880, 18–439 | 683 × 422 |
| 3 | 170–890, 59–432 | 721 × 374 |
| 4 | 121–889, 153–428 | 769 × 276 |
| 5 | 113–892, 167–436 | 780 × 270 |
| 6 | 174–825, 126–497 | 652 × 372 |
| 7 | 179–792, 118–471 | 614 × 354 |
| 8 | 198–815, 148–481 | 618 × 334 |

- Nariz de uns 32 × 24 em todos os quadros.
- O quadro 2 encosta a 18 px do topo, então ali as chamas têm de ir para trás e não para cima.
- B2 e B3 vieram uns 10% grandes, por isso o pedido reforça o tamanho e traz as medidas na escala 1254.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_fogo_salto.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/leao/leao_salto.png = the APPROVED leap sheet of Leopoldo the lion (8 frames): copy its 8 frames EXACTLY (same body, legs, paws and tail, same pose in each frame, same size and the same position in each cell). Only the mane and the face change.
- docs/referencias/pecas/leao/leao_fogo_parado.png and docs/referencias/pecas/leao/leao_fogo_corrida.png = the APPROVED fire-mane sheets of the same lion: copy their FIRE MANE (orange and yellow cartoon flames with red-orange tips and a dark outline, attached to the head like a mane) and their angry face style.

SIZE AND POSITION (copy leao_salto.png): canvas exactly 2048 x 2048, grid of 2 columns x 4 rows, cells of 1024 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 2048, make a square canvas with the same 2 x 4 layout and scale EVERY number below by the same factor (for 1254 x 1254 the numbers are in brackets); say the real size when you deliver.
Side view, facing LEFT. In every cell the lion has the same size and place as in the same frame of leao_salto.png. Size of each frame without the flames: 1 = 618 x 299 [378 x 183], 2 = 683 x 422 [418 x 258], 3 = 721 x 374 [441 x 229], 4 = 769 x 276 [471 x 169], 5 = 780 x 270 [478 x 165], 6 = 652 x 372 [399 x 228], 7 = 614 x 354 [376 x 217], 8 = 618 x 334 [378 x 205]. Frames 1 and 8 are on the ground: the bottom of the paws exactly at y = 481 [295] of the cell. Frames 2 to 7 are in the air at the same place in the cell as in leao_salto.png. His head is the same size as in the references: dark brown nose about 32 x 24 px [20 x 15] in every frame. IMPORTANT: the last two fire sheets came out about 10 percent too big; the body, legs and paws must match leao_salto.png frame by frame, NOT bigger.
The FIRE MANE replaces ALL of the fur mane, including the part under the chin and behind the front legs (no brown fur mane left anywhere). The flames stream BACKWARD, opposite to the direction of the leap (rising frames: flames back and down; falling frames: flames back and up), always attached to the head, never covering the eyes or the nose. The flames may stick out at most 40 px [25] beyond the fur mane of leao_salto.png; in frames 2 and 3 they must NOT go higher than the top of the fur mane (frame 2 is close to the top of its cell). At least 12 px [8] of empty margin around the whole drawing (flames, tail tuft, paws) inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no glow outside the drawing, no motion blur, no speed lines.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references. The body keeps its normal golden colors (the game adds the orange tint by itself).

Animation: LEAP ON FIRE, 8 frames, the same poses as leao_salto.png:
1 deep crouch, ready to spring, wild grin, eyes locked on the target, flames flaring up;
2 explosive take-off, body diagonal upward to the left, mouth open in a fiery roar;
3 rising, front legs reaching forward and up, flames streaming back;
4 apex, body fully horizontal and stretched, eyes narrowed in fury, teeth showing;
5 apex variation, tail curling, a wild crazy grin;
6 starting to fall, front paws reaching down and forward, eyes wide and wild;
7 just before landing, front paws down toward the ground, snarling;
8 landing impact, body squashed low, paws spread wide, eyes squeezed, flames bursting outward.
FACIAL EXPRESSIONS: angrier and wilder than the normal leap, a different expression in every frame, always clearly the same lion as leao_fogo_parado.png.
```

### Resultado do B4 (03/10)

No jogo como `leao/leao_fogo_salto.png`, com fator 1,0. O original está em
`leao/originais/leao_fogo_salto_codex_1254x1254.png`.

**Tamanho:** desta vez o tamanho veio certo.
- O vão das patas ficou 0–4% do salto aprovado.
- Tirando a cabeça, o corpo cobre 96–99% do corpo do salto aprovado.
- Nariz de 31–38 × 20–25, contra 31–34 × 22–26.
- No quadro 7 o nariz é mais largo, mas tem a mesma área. A cabeça foi conferida lado a lado.

**Alinhamento:** patas dos quadros 1 e 8 em 481. Os voos ficam onde o corpo melhor se encaixa sobre o
mesmo quadro do salto aprovado. A cor do tronco não serve aqui, porque as chamas amarelas parecem o
dourado do corpo.

**Desvios aceitos:**
- No quadro 2 as chamas sobem uns 25 px acima da juba. Ele ficou 12–15 px mais baixo que o salto normal,
  sem cortar nada. É o quadro da saída, que fica só 0,12 s na tela.
- O quadro 6 ficou 8 px mais alto, para as patas terem margem embaixo.

**No jogo:**
- Agachado, no ar e pouso em fogo usam estes 8 quadros, escolhidos do mesmo jeito do salto normal.
- As chamas soltas por código ficam só no rugido.
- Fotos: `screenshots.tscn -- leao`, segunda fila.

## Pedido B5 (pronto para colar)

**Uso no jogo:** quando o Domador perde, o leão se apaga e deita, cansado. A vitória aparece 2,3 s
depois. Hoje isso é o quadro do agachado achatado por código. O B5 traz a derrota desenhada, tocada
uma vez:
1. Cansado, por uns 0,35 s.
2. Deitando, por uns 0,35 s.
3. Deitado de língua de fora, por uns 0,8 s.
4. Dormindo, até o fim, com a respiração por código.

É a juba de pelo, sem fogo.

**Medidas do `leao_parado.png` aprovado** (2048 × 1024, células de 1024 × 512):
- Corpo de 513–556 × 387–396, patas em y 482, meio em x uns 506.
- Vão das patas de ponta a ponta 468–475, dorso a 209–216 px da sola.
- Nariz de 32 × 25, juba de uns 285 × 318.

**Medidas do agachado do `leao_salto.png`:** 618 × 299.

A última folha 2 × 2 veio em 1774 × 887, por isso os números também vão nessa escala (fator 0,8662).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_derrota.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/leao/leao_parado.png = the APPROVED idle sheet of Leopoldo the lion: the EXACT lion (same design, golden body, big dark red-brown FUR mane, dark brown nose, cream muzzle and paws, tail with a dark tuft), same size, same ink style. No fire in this sheet: the fire is out, the mane is normal fur again.
- docs/referencias/pecas/leao/leao_salto.png (first frame, the crouch) = how big the same lion is when his body is low to the ground.
- docs/referencias/pecas/leao/leao_folha.png = the lion's design sheet.

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 2 columns x 2 rows, cells of 1024 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 2 x 2 layout with 2:1 cells and scale EVERY number below by the same factor (for 1774 x 887 the numbers are in brackets); say the real size when you deliver.
Side view, facing LEFT. The lion is EXACTLY the size of leao_parado.png in every frame (do not make him bigger: the last sheets came out about 10 percent too big): his dark brown nose is about 32 x 25 px [28 x 22], his fur mane about 285 x 318 px [247 x 275], and standing his paws span about 470 px [407] from the front toes to the back toes. In every frame the lowest point (paws, belly or chin resting on the floor) is exactly at y = 482 [418] of the cell, and the body is centered around x = 506 [438]. Frame sizes, about: 1 = 513 to 556 x 380 [444 to 482 x 329] (standing, like the idle); 2 = about 600 x 330 [520 x 286] (going down); 3 and 4 = about 650 to 720 long and 230 to 270 tall [563 to 624 x 199 to 234] (lying flat on the floor, like the crouch of leao_salto.png but lower and relaxed). At least 12 px [10] of empty margin around the whole drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no smoke, no "Z" letters, no stars.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation: DEFEAT (played once, not a loop), 4 frames:
1 exhausted, still standing: head hanging low, mane drooping, tongue hanging out, panting, eyes half closed, legs a little wobbly;
2 lying down: front legs folding, chest going down to the floor, back still up, a big tired yawn;
3 lying flat on his belly, chin on his crossed front paws, tongue hanging out of the side of the mouth, dizzy happy eyes, tail flat on the floor;
4 asleep in the same lying pose as frame 3: eyes closed, a small content smile, tongue back in, tail curled around the back paws.
FACIAL EXPRESSIONS: tired and silly, a different expression in every frame, always clearly the same lion.
```

### Resultado do B5 (03/10)

No jogo como `leao/leao_derrota.png`, com fator único 0,95. O original está em
`leao/originais/leao_derrota_codex_1774x887.png`.

**Tamanho:**
- Antes do fator, o quadro 1 tinha a cabeça do parado e o corpo uns 4% maior; nos deitados o nariz
  vinha uns 10% maior.
- Com 0,95, tudo fica a no máximo 5% do parado. O nariz dos deitados mede 35–36 × 26–28, contra
  31–32 × 24–25.

**Alinhamento:**
- O ponto mais baixo dos 4 quadros fica em y 482.
- No quadro 1 a pata da frente fica onde está a do parado, para a cabeça não pular na troca.
- O quadro 4 foi movido 9 px para o nariz cair no mesmo lugar do 3.

**No jogo:** o leão apaga o fogo e toca os 4 quadros uma vez (0,35, 0,35 e 0,8 s), depois fica dormindo
e respirando. Fotos: `screenshots.tscn -- leao_derrota`.

**Pendência real (fora do plano, não pedida; atualizado em 03/10: decidido por delegação, pedido B6 pronto abaixo):** o rugido em fogo. Na fase 3 o leão ruge em fogo nas
Argolas Caindo e na entrada do fogo. Esse rugido ainda usa o `leao_rugido.png`, com juba de pelo e as
chamas soltas por código. O Pedido 3 só incluía parado, corrida e salto em fogo. O usuário decide se
entra um B6 (`leao_fogo_rugido.png`, 4 quadros com as medidas do `leao_rugido.png`).

## Pedido C1 (pronto para colar)

**Uso:** é a folha base do Domador, como a `leao_folha.png` foi para o leão. Não entra no jogo
diretamente: fixa o desenho e as proporções para C2–C4. Hoje o Domador do jogo é um SVG parado
(`bosses/tamer/art/tamer.svg`, 180 × 260 px). Ele é baixinho e gordinho, de cartola alta, nariz
redondo, bigodão enrolado, casaca vermelha com alamares dourados, dragona, cinto preto de fivela
dourada, calça creme, botas marrons e a aba da casaca para trás. No jogo ele mede 260 px de altura
(a vida, a colisão e a mão do chicote estão nessa medida). O chicote é desenhado por código, saindo da
mão da frente. A outra referência é `docs/referencias/chefao_domador.png`: o domador à direita no
painel 1 e em cima do pedestal no painel 2.

**Proporções do SVG**, de cima para baixo em 260 px:

| Parte | Faixa (px) | Altura |
|---|---|---|
| Cartola | 0–50 | ~19% |
| Rosto até o queixo | 50–115 | ~25% |
| Tronco | 115–180 | — |
| Pernas | 180–260 | ~31% |

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE character design sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/domador/domador_folha.png (create the folder).

References (read from the project):
- bosses/tamer/art/tamer.svg = the CURRENT placeholder drawing of the Lion Tamer in the game: keep his design and PROPORTIONS (short and stocky, a tall black top hat with a red band, a big round pink-red nose, small round eyes, a huge black curled handlebar mustache, rosy cheeks, a red ringmaster tailcoat with gold frogging and three gold buttons, a gold epaulette on the shoulder, a black belt with a gold buckle, cream breeches, dark brown boots, the red coattail behind him).
- docs/referencias/chefao_domador.png = concept art of the boss fight; the tamer is the little ringmaster on the right of the first panel (and scared on the pedestal in the second panel).
- docs/referencias/pecas/leao/leao_folha.png, docs/referencias/pecas/palhaco_folha.png and docs/referencias/pecas/acrobata_folha.png = the ART STYLE and LAYOUT to match exactly: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture.

Sheet: canvas exactly 2048 x 1024 (if the image tool cannot make 2048 x 1024, keep the same 2:1 layout and scale every number by the same factor; say the real size when you deliver). Fully TRANSPARENT background (real alpha 0 outside the drawings, no faint pixels), no text, no grid, no ground, no shadows.
1. Left half: the tamer's FULL BODY, standing, side view facing LEFT (three-quarter is fine, like leao_folha.png), proud chest out, about 880 px tall from the top of the hat to the soles, the soles at y = 980, centered around x = 480. Keep the proportions of tamer.svg: the hat about 19 percent of his height, the face from the hat brim to the chin about 25 percent, the legs about 31 percent; short and round, NOT tall and slim. His FRONT hand (the one on the left, toward where he faces) is a white-gloved closed fist held a little forward at chest height, EMPTY: no whip, no stick (the game draws the whip from that hand). The back arm rests on his hip.
2. Right half: three HEADS of the same tamer (with the top hat), in a row, each the SAME SIZE as the head on the full body, all facing LEFT, centered around y = 450, at about x = 1180, 1500 and 1820, at least 30 px apart:
   a) SMUG: chin up, eyes half closed, a cocky grin under the mustache;
   b) ANGRY: shouting a command, mouth wide open, eyebrows down, mustache bristling;
   c) TERRIFIED: eyes huge, mouth in a wobbly "O", hat jumping off the head a little, sweat drops.
At least 24 px of empty space around every drawing; nothing touches the canvas border.
```

### Resultado do C1 (03/10)

Aprovada como folha base. Ela fixa o desenho do Domador, mas não entra no jogo: o SVG continua até o
C2. O original está em `domador/originais/domador_folha_codex_1774x887.png`.

**Desenho:** o mesmo personagem no corpo e nas três cabeças. As proporções batem com o SVG:

| Parte | Folha C1 | SVG |
|---|---|---|
| Cartola | ~21% | 19% |
| Da aba ao queixo | ~24% | 25% |
| Pernas | ~33% | 31% |

Botões e alamares ficaram invertidos em relação ao SVG; o desenho novo vale como canônico.

**Reorganização em 2048 × 1024:**
- O corpo foi ampliado por 2048/1774 e mede 930 px de altura, acima dos 880 pedidos. Aceito, porque
  é só a folha de design.
- As cabeças vieram uns 5% menores que a do corpo. Ampliei cada uma pelo mesmo fator × 1,05, sem
  deformar, para os narizes ficarem iguais: 63–65 × 57–59 nas cabeças, 64 × 59 no corpo.
- As três cabeças ficaram lado a lado à direita do corpo.

**Escala dos quadros (combinado com o Codex em 03/10):** o Domador é desenhado com uns 465 px na
célula de 512 e reduzido para 260 no jogo, como a acrobata.

## Pedido C2 (pronto para colar)

**Uso no jogo:** o Domador estala o chicote na fase 1 (Chicotada) e na entrada da fase 2. O jogo já
tem as posições do chicote (`whip_pose` em `bosses/tamer/tamer.gd`): 0 caído, 1 erguido, 2 estalado.
O chicote continua sendo uma linha desenhada por código, saindo da mão da frente. Por isso a mão vai
vazia, e na integração mede-se onde fica a mão em cada quadro, como foi feito com os ombros dos
jogadores. No jogo ele tem 260 px de altura. Vida, colisão e tempo dos ataques não mudam.

**Medidas na escala do pedido** (a folha C1 reduzida para 465 px de altura, fator 0,5):
- Nariz de bola de uns 32 × 30 px.
- Cartola de uns 98 px da copa à aba.
- Cinto a uns 190 px acima da sola.
- Corpo de uns 315 px de largura em pé, contando o punho para a frente.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/domador/domador_chicote.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/domador/domador_folha.png = the APPROVED design of the Lion Tamer: the EXACT character (short and stocky, tall black top hat with a red band, round red nose, big black curled mustache, brown hair, red ringmaster tailcoat with gold buttons and gold frogging, one gold epaulette, black belt with a gold buckle, cream breeches, black boots with gold trim, red coattail), same proportions, same faces (the smug and the angry heads).
- docs/referencias/pecas/acrobata_parado.png = an approved animation sheet of the game: same kind of layout, framing and cleanliness.

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square cells and scale EVERY number below by the same factor; say the real size when you deliver.
Side view, facing LEFT, like domador_folha.png. In every cell he is about 465 px tall from the top of the hat to the soles (the same size in all 4 frames; his round red nose about 32 x 30 px, the hat about 98 px from the top to the brim), the soles of both boots exactly at y = 486, the middle of his body (the belt buckle) at about x = 256. At least 12 px of empty margin around the whole drawing inside its cell (the raised fist must stay inside: lift it beside the hat, not above it). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.
NO WHIP: his FRONT hand is an empty closed white-gloved fist in every frame, clearly visible, not hidden behind the body (the game draws the whip from that fist). The back hand stays on his hip in every frame.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference.

Animation: WHIP CRACK, 4 frames:
1 ready: front fist low in front of the belly, chest out, smug grin, eyes half closed (the smug head of the design sheet);
2 wind-up: front arm raised high, fist beside the top hat, leaning back, angry shout (the angry head);
3 crack: front arm swung down and forward, fist in front at knee height, body leaning forward, mouth wide open in a loud "HUP!", hat tipping forward a little;
4 after the crack: standing up again, front fist back in front of the chest, proud smirk, chin up, one eyebrow raised.
FACIAL EXPRESSIONS: a different, exaggerated expression in every frame, always clearly the same tamer.
```

### Resultado do C2 (03/10)

No jogo, com fator 1,0. O original está em `domador/originais/domador_chicote_codex_2048x768.png`.

**Medidas:** a folha veio em 2048 × 768, com células de 512 × 768.
- Altura de 463 px em pé e 412 no estalo, por causa da pose.
- Nariz de 33–34 × 28–31.
- Solas subidas de 534 para 486, e a fivela do cinto em x 255–260.

**No jogo:**
- O Domador deixou de ser SVG.
- O quadro sai da pose do chicote que o jogo já tinha: pronto, erguido, estalo e, logo depois do estalo,
  0,35 s do quadro "orgulhoso".
- O chicote (e a tocha da fase 3) sai do meio da luva da frente de cada quadro, medido na folha.
- O medo das fases 2 e 3 e a reverência continuam por código sobre o quadro "pronto" até chegarem C3
  e C4.
- Fotos: `screenshots.tscn -- domador`.

## Pedido C3 (pronto para colar)

**Uso no jogo:** nas fases 2 e 3 o Domador foge para cima do pedestal e fica com medo, sem levar tiro.
Hoje isso é o quadro "pronto" achatado, inclinado e tremendo por código. O C3 traz o medo desenhado:
os quadros 1–3 em loop rápido (tremendo) e, de vez em quando, o 4 por meio segundo (espiando).

O chicote continua pendurado do punho da frente, desenhado por código, então o punho precisa
aparecer, vazio. A mesma escala do C2 (uns 465 px em pé) vale aqui, com o corpo encolhido.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/domador/domador_medo.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/domador/domador_folha.png = the APPROVED design of the Lion Tamer (use the TERRIFIED head for the face).
- docs/referencias/pecas/domador/domador_chicote.png = the APPROVED animation sheet of the same tamer at the CORRECT SIZE: match his size exactly (head, hat, nose, coat, boots) and the framing.

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square 512 x 512 cells (do NOT make the cells taller); say the real size when you deliver.
Side view, facing LEFT. He is the SAME SIZE as in domador_chicote.png (standing he would be about 465 px tall; his round red nose about 32 x 30 px, the hat about 98 px from the top to the brim), but here he is CROUCHED with fear: knees bent, shoulders up, head pulled down, about 340 to 380 px tall from the top of the hat to the soles (never smaller: the body is bent, not shrunk). The soles of both boots exactly at y = 486 of the cell, the middle of his body (the belt buckle) at about x = 256. At least 12 px of empty margin around the whole drawing inside its cell (including the hat, sweat drops and the jumping hat). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines, no shaking lines.
NO WHIP: his FRONT hand is an empty closed white-gloved fist clutched in front of his chest in every frame, clearly visible, not hidden (the game draws the whip hanging from that fist). The back hand holds the brim of his hat down on his head.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation: SCARED, 4 frames:
1 crouched and trembling, eyes huge, teeth chattering, a few sweat drops;
2 the same crouch, slightly different (knees knocking together, mustache drooping, eyes darting), sweat drops in other places;
3 the same crouch again (the hat lifted a little off his head by fear, mouth in a wobbly "O"); frames 1, 2 and 3 loop quickly as a tremble, so keep the boots in exactly the same place and the body in almost the same place;
4 peeking: still crouched with the boots in the same place, he raises his head a little and peeks to the LEFT with one eye open and one eye shut, biting his lip, the hat pulled down.
FACIAL EXPRESSIONS: terrified and silly, a different expression in every frame, always clearly the same tamer.
```

### Resultado do C3 (03/10)

No jogo, com fator único 0,80, como o Codex propôs. O original está em
`domador/originais/domador_medo_codex_2048x768.png`.

**Tamanho:** com o fator, o nariz mede 33–34 × 25–30, contra 33–34 × 28–31 no C2. Cartola, cabeça e
botas ficam do tamanho do C2.

**Desvio aceito:** no quadro 3 a cartola pula uns 31 px, mais que os 10 pedidos. Só a cartola e a mão
sobem; corpo e rosto ficam no lugar, e no tremor isso parece um pulo de susto.

**Alinhamento:** solas em 486. As botas já estavam no mesmo lugar nos quatro quadros e ficaram paradas
para o tremor. A fivela cai em x 252–263.

**No jogo:**
- Com medo, os quadros 1–3 passam a 12 por segundo e, a cada 2,4 s, aparece o 4 por meio segundo.
- O chicote fica pendurado do punho de cada quadro.
- O medo feito por código (achatado e inclinado) saiu.
- Fotos: `screenshots.tscn -- domador`, segunda fila.

## Pedido C4 (pronto para colar)

**Uso no jogo:** quando a luta acaba, o Domador, sem graça, faz uma reverência para a plateia. O jogo
já tem o andamento: o valor `bow` vai de 0 a 1 em 0,6 s, depois de 0,8 s. Hoje isso é o quadro "pronto"
inclinado por código.

O C4 traz quatro quadros escolhidos pelo `bow`:
1. Começando, tirando a cartola.
2. Meio curvado.
3. Reverência funda.
4. Segurando a reverência e espiando a plateia, sem graça. Fica até o fim.

O chicote continua pendurado do punho da frente, desenhado por código, então o punho aparece vazio.
A escala é a do C2 e do C3: uns 465 px em pé.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/domador/domador_reverencia.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/domador/domador_folha.png = the APPROVED design of the Lion Tamer.
- docs/referencias/pecas/domador/domador_chicote.png and docs/referencias/pecas/domador/domador_medo.png = APPROVED animation sheets of the same tamer at the CORRECT SIZE: match his size exactly (head, top hat, round red nose, coat, boots) and the framing.

SIZE AND POSITION: canvas exactly 2048 x 512, grid of 4 columns x 1 row, cells of 512 x 512, one frame per cell, left to right. If the image tool cannot make 2048 x 512, keep the same 4 x 1 layout with square 512 x 512 cells (do NOT make the cells taller and do NOT make him bigger to fill them: the last two sheets came 768 px tall and one of them 25 percent too big); say the real size when you deliver.
Side view, facing LEFT. He is the SAME SIZE as in domador_chicote.png: standing about 465 px tall from the top of the hat to the soles, his round red nose about 32 x 30 px, the hat about 98 px from the top to the brim. When he bends forward he gets shorter (about 330 to 400 px tall), but never smaller. The soles of both boots exactly at y = 486 of the cell, in the SAME place in all 4 frames (he bows without moving his feet), the belt buckle at about x = 256 when standing. At least 12 px of empty margin around the whole drawing inside its cell (the head and the hat go forward to the left when he bows: keep them inside). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.
NO WHIP: his FRONT hand is an empty closed white-gloved fist held against his belly in every frame, clearly visible (the game draws the whip hanging from that fist). The BACK hand takes off the top hat and holds it out to the side in the bow.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Animation: AWKWARD BOW at the end of the fight (played once, the last frame stays), 4 frames:
1 standing, taking off the top hat with the back hand, a forced nervous smile, sweat drop;
2 bending forward halfway, hat held out, eyes squeezed, embarrassed blush;
3 deep bow, upper body forward, the top of his head showing his curly brown hair (as in the third frame of domador_medo.png), hat held out to the side, mustache drooping;
4 still in the deep bow, peeking up at the audience with one eye, a sheepish crooked grin, a bead of sweat.
FACIAL EXPRESSIONS: embarrassed and silly, a different expression in every frame, always clearly the same tamer.
```

## Histórico: C4 recusada e pedido C4b (correção focal com medidas)

O diagnóstico da C4 (03/10, `domador/originais/domador_reverencia_codex_2048x768.png`) foi o
seguinte.

**O que está bom:**
- Corpo, braços, botas e punho vazio.
- O cabelo igual ao do C3 e as quatro caras.
- Quadros 1 e 2 do tamanho do C2: nariz uns 34 × 30, rosto do nariz à orelha uns 150–155 px.

**Aceitáveis:**
- A cartola segura atrás, à direita.
- Os quadros 3 e 4 mais baixos que 330 px, porque a reverência é funda.

**O que reprovou:** nos quadros 3 e 4 a cabeça encolhe uns 13–16%.
- O nariz mede 28–29, contra 33–35.
- O rosto, do nariz à orelha, mede uns 130 px, contra 150–155.
- O quadro 4 é o que fica parado na tela até a vitória.
- Os quadros 1 e 2 já estão certos, então não há fator único que resolva. Escala por quadro não foi
  usada.

No jogo, a reverência continua por código. As medidas abaixo estão no canvas entregue
(2048 × 768, colunas de 512 × 768).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Edit docs/referencias/pecas/domador/originais/domador_reverencia_codex_2048x768.png and save the result INSIDE the project at exactly: docs/referencias/pecas/domador/domador_reverencia_v2.png (do NOT overwrite any other file).

Keep EVERYTHING the same (canvas 2048 x 768, the 4 columns of 512 x 768, frames 1 and 2 untouched, the bodies, arms, fists, boots, coat, the held top hats, the soles at y = 652, the positions in each column, transparent background) EXCEPT the HEAD of frames 3 and 4 (the third and fourth columns).

PROBLEM: in frames 3 and 4 the head (face, nose, eyes, mustache, ears and curly hair) is about 15 percent SMALLER than in frames 1 and 2 and in the approved docs/referencias/pecas/domador/domador_chicote.png. Measured: the round red nose is 28 to 29 px wide there, but 33 to 35 px in frames 1 and 2; the face from the tip of the nose to the back of the ear is about 130 px there, but 150 to 155 px in frames 1 and 2.

FIX: redraw the head of frames 3 and 4 at the SAME SIZE as the head of frames 1 and 2 (round red nose about 34 x 30 px, face about 150 px from the nose tip to the back of the ear, the same big curly brown hair, the same eye size), keeping the same pose of the head (frame 3 looking down in the deep bow, frame 4 peeking up at the audience with one eye and the sheepish crooked grin), attached to the same neck. The bigger head may grow a little forward and down; keep at least 8 px of empty margin inside its column and do not cross into the next column. Same 1930s hand-inked style, thick dark brown outline #1b1410, real alpha 0 outside the drawing (no faint pixels).
```

### Resultado do C4b (03/10)

No jogo como `domador/domador_reverencia.png`. O original está em
`domador/originais/domador_reverencia_v2_codex_2048x768.png`.

O gerador mexeu um pouco nos quatro quadros. Por isso a folha final usa os quadros 1 e 2 da C4 original
e os quadros 3 e 4 da C4b.

**Cabeças:** nariz de 33 × 30, 34 × 30, 31 × 29 e 33 × 31, medido do mesmo jeito nos quatro. Rosto,
cabelo e olho batem com o quadro 1 e com o C2. No quadro 3 o nariz sai um pouco menor porque ele olha
para baixo.

**Botas:** o meio das botas ficou em x 245 nos quatro quadros. No jogo, a reverência, o medo e o chicote
põem as botas no mesmo lugar, pelo ponto de origem de cada recorte, sem mexer nos pixels. Com isso, o
desenho do medo ficou 26 px mais à direita do que estava.

**No jogo:** a reverência segue o andamento do fim da luta, com o quadro 2 a partir de 0,25, o 3 a
partir de 0,6 e o 4 a partir de 0,95. O 4 fica até o fim. O chicote sai da luva em todos os quadros, e a
inclinação por código saiu. Fotos: `screenshots.tscn -- domador`, terceira fila.

O bloco C está completo.

## Pedido D1 (pronto para colar)

**Uso no jogo:** é a Torta na Cara, o Grande Número do palhaço
(`core/player/characters/clown/grand_number/pie_throw.gd`). Dura 0,75 s. O palhaço fica parado, mesmo
no ar, e invencível; a torta sai da mão aos 0,38 s, na direção da mira. Hoje isso é feito por código:
o braço da pistola vai para trás e chicoteia para a frente, com uma torta solta crescendo na mão.

Com os quadros desenhados:
- Os quadros 1 a 3 cobrem a preparação, o 4 é o arremesso (0,38 s) e os 5 a 8 são o depois.
- O braço da pistola e a torta solta somem durante o número. A torta voando (D2) continua sendo o
  projétil.
- Os dois braços são desenhados, porque ele não segura a pistola.
- A torta voando sai na direção da mira; o desenho do arremesso é para a frente.

**Medidas do palhaço** (as do A15, conferidas no `palhaco_parado.png`):

| Medida | Valor |
|---|---|
| Altura em pé | 435–448 px |
| Do topo do chapéu ao meio do nariz | 164 px |
| Nariz | 50 × 39 px |
| Do nariz ao queixo | uns 44 px |
| Sola | y 486 |
| Meio do corpo | x 256 |

A torta do jogo é `core/player/characters/clown/grand_number/pie.svg`.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/palhaco_torta.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png = the EXACT clown: design, colors (red/cream harlequin suit, ruffled collar, red nose, red hair puffs, small black top hat with a gold band and a white daisy, white gloves, big brown shoes), proportions and ink style.
- docs/referencias/pecas/palhaco_parado.png = an approved sheet of this clown at the CORRECT SIZE and framing. Match his size exactly.
- core/player/characters/clown/grand_number/pie.svg = the pie of the game (cream pie with a red cherry on top): the same pie, drawn in the hand-inked style.
- docs/referencias/combate_especial.png = what the special moves look like in this game.

SIZE (very important, earlier sheets came out 5 to 25 percent too big or too small). All measurements are for the 2048 x 1024 sheet: the clown standing is about 435 to 448 px tall from shoe sole to hat top; from the top of the hat to the CENTER of the red nose is 164 px; the red nose is about 50 px wide and 39 px tall; from the center of the nose to the bottom of the chin is about 44 px. Keep that head size in EVERY frame (do NOT shrink or squash the head or the hat). The giant pie is about as wide as his head (about 150 px across) while he holds it.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells (do not make the cells taller) and scale every number by the same factor; say the real size when you deliver. Side view, facing RIGHT. The clown is IDENTICAL in every frame; only the pose and the face change. He stays on the SAME spot: in every frame the soles of his shoes are exactly at y = 486 of the cell and the middle of his body is at about x = 256 (he throws without walking). At least 12 px of empty margin around the whole drawing inside its cell (the pie over his head and the arm thrown forward must stay inside; bend the arm instead of shrinking him). Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines, no flying pie outside his hands (the game draws the flying pie).
ARMS: NO gun in any frame. BOTH arms are drawn (white gloves), because he holds the pie with his hands.

Animation: "PIE IN THE FACE" throw, 8 frames:
1 pulls the giant pie from behind his back, sly grin;
2 lifts the pie over his head with both hands, tongue out in concentration;
3 leans far back, one eye closed aiming, wicked smile;
4 THROW: arm whipping forward, the pie just leaving the hand (still touching the fingers), mouth open shouting;
5 follow-through, body stretched forward, the hand now EMPTY, delighted face;
6 watching the pie fly, hand over his mouth, giggling;
7 laughing, bent over, tears of laughter;
8 standing back up, thumbs up, proud wink.
FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame, always clearly the same clown.
```

### Resultado do D1 (03/10)

No jogo, com fator único 0,961: o 1,11 do Codex sobre a folha recebida. O original está em
`originais/palhaco_torta_codex_1774x887.png`.

**Tamanho:** a cabeça veio certa, mas o corpo uns 6% mais alto e os sapatos uns 12% mais largos. Com o
fator, a cabeça fica 4% menor que a do parado, o quadro 8 mede 444 px de altura e os sapatos ficam uns
8% maiores.

**Alinhamento:** o meio dos sapatos em x 260 nos 8 quadros, como no parado, para ele não deslizar.

**Desvios aceitos:** o arremesso (quadro 4) mostra a torta à frente, sem o braço chicoteando, e o
quadro 3 inclina pouco. No jogo funciona, porque a torta voando sai da torta desenhada no quadro 4.

**No jogo:**
- O rig ganhou `special_animation`. O Grande Número escolhe o quadro, e o braço da pistola some.
- Na Torta na Cara, os quadros 1–3 vão até soltar a torta (0,38 s), o 4 vem logo depois e os 5–8 vão
  até o fim (0,75 s).
- A torta solta na mão não aparece. Duração, dano, mira e rede ficaram iguais.
- Fotos: `screenshots.tscn -- torta`.

**Observação:** a torta voando do jogo é umas três vezes maior que a torta na mão. A área de dano
combina com a torta grande; mudar isso é decisão do usuário.

## Pedido D2 (pronto para colar)

**Uso no jogo:** é a torta voando da Torta na Cara (`core/player/characters/clown/grand_number/pie.tscn`)
e o esborrachar dela.
- Hoje a torta voando é um SVG de 190 × 130, mostrado a 0,9 (171 × 117 na tela). Ela balança um pouco
  e atravessa o chefão, acertando várias vezes, mais devagar enquanto acerta.
- O esborrachar hoje é um punhado de gotas de creme feitas por código, quando acerta e quando some.

Com a folha:
- Os quadros 1–4 são o loop da torta voando.
- Os quadros 5–8 são um efeito que toca uma vez no ponto onde ela bate.
- O jogo vira o desenho para a direção da mira.
- A torta é desenhada no dobro do tamanho da tela (uns 380 × 260 na célula), como os outros desenhos,
  e reduzida pela metade no jogo.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/torta.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/palhaco_torta.png = the APPROVED "pie in the face" sheet of the clown: the EXACT same pie (fluted aluminum tin, golden crust, a big mound of whipped cream, a red cherry with a stem), same colors and ink style.
- core/player/characters/clown/grand_number/pie.svg = the pie of the game (its shape and proportions).

SIZE AND POSITION: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells (do not make the cells taller) and scale every number by the same factor; say the real size when you deliver. At least 12 px of empty margin around the whole drawing inside its cell. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines, no hands, no characters.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the reference.

Frames 1 to 4 (top row) = the PIE FLYING to the RIGHT, a loop: side view of the whole pie, about 380 px wide and 260 px tall (tin, crust, cream and cherry; the SAME size in all 4 frames), its center at x = 256, y = 256 of the cell. The pie wobbles a little in the air: tilted about 8 degrees up, level, 8 degrees down, level; the cream mound jiggles (a slightly different shape each frame) and the cherry bounces on top. No trail, no speed lines.
Frames 5 to 8 (bottom row) = the PIE SPLATTING against something on the RIGHT, played once, all centered on the impact point at x = 300, y = 256 of the cell:
5 impact: the tin squashed flat against an invisible wall on the right, cream bursting out in all directions, the cherry flying up;
6 big splash: a large star-shaped burst of white cream with blobs (about 420 px across), the dented tin bouncing back to the left;
7 the cream sliding down in thick drips and falling blobs, the tin falling away;
8 the last drips and a few small falling blobs, smaller and fading (no tin).
```

### Resultado do D2 (03/10)

No jogo, com fator único 0,935. O original está em `originais/torta_codex_1774x887.png`.

**Tamanho:** a torta voando mede 372–387 × 260 e na tela fica com os mesmos 171 px de antes.

**Registro:**
- O voo ficou com o centro do desenho no mesmo ponto nos quatro quadros, sem salto no loop.
- No esborrachar, o centro do creme ficou no mesmo ponto nos quatro quadros, com a forma recuando
  em volta.

**No jogo:**
- A torta voando toca em loop. O balanço por código foi zerado, porque o desenho já balança.
- O esborrachar desenhado aparece no primeiro acerto e quando a torta some. Jogada para a frente, a
  torta sai da tela, então só no fim quase nunca se veria.
- Os acertos seguintes continuam só com as gotas.
- Área de dano, acertos, desaceleração, mira e tamanho ficaram iguais.
- Componentes novos: `FrameLoopSprite` e `FrameBurst`.
- Fotos: `screenshots.tscn -- torta_voo`.

## Pedido D3 (pronto para colar)

**Uso no jogo:** é o Salto Mortal, o Grande Número da acrobata
(`core/player/characters/acrobat/grand_number/somersault.gd`).
- Ela agacha por 0,12 s e salta em arco por 0,75 s, por cima do chefão, acertando o que atravessa.
- Hoje o corpo de peças gira duas voltas por código.

Com a folha:
- O quadro 1 é a agachada.
- Os quadros 2–7 são uma cambalhota inteira desenhada, escolhida pelo andamento do salto, sem o giro
  por código.
- O quadro 8 é o pouso.
- Sem pistola, como no parry.

**Medidas da acrobata** (as do A16, conferidas no `acrobata_parado.png`):

| Medida | Valor |
|---|---|
| Altura em pé, do salto do sapato ao topo do coque | 465 px |
| Do topo do coque ao meio do nariz | 119 px |
| Nariz | 16 × 14 px |
| Cabeça, na linha dos olhos | 157 px de largura |
| Branco do olho | 40 px de altura |
| Cintura em pé (meio do maiô) | y 229 |

No ar, a estrela da cintura fica em (256, 250), um pouco abaixo da cintura em pé, para caber o quadro 4
(pernas abertas para cima). Na integração o giro de peças sai, e o desenho fica preso nesse ponto.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE animation sheet for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save it INSIDE the project at exactly: docs/referencias/pecas/acrobata_salto_mortal.png (replace if it exists).

References (read from the project):
- docs/referencias/pecas/acrobata_corrida.png = the EXACT acrobat: a TALL, SLIM, long-legged young woman. Black hair in a high round bun with a small gold star tiara, gold star earrings, big round black cartoon eyes with lashes, rosy cheeks, a small red clown nose, teal (#1f5a66) strapless leotard with thin gold shoulder straps, gold sweetheart neckline trim, a gold star at the waist and a gold zigzag hem, bare slim legs, white gloves, teal high-heel shoes with gold ankle straps and gold balls on the toes.
- docs/referencias/pecas/acrobata_parado.png and docs/referencias/pecas/acrobata_parry.png = approved sheets of this acrobat at the CORRECT SIZE (the parry sheet is her approved somersault: same size and style of flip).
- docs/referencias/combate_especial.png = what the special moves look like in this game.

SIZE (very important, earlier sheets came out 5 to 25 percent too big or too small). All measurements are for the 2048 x 1024 sheet: standing, she is about 465 px tall from heel to the top of the bun; from the top of the bun to the CENTER of the red nose is 119 px; the red nose is about 16 x 14 px; her head is about 157 px wide at eye level (side view, back of the head to the nose); the white of her eye is about 40 px tall. Keep that head size in EVERY frame (do NOT shrink or squash the head or the bun). Tucked poses are compact, stretched poses are long, but she is never drawn smaller.

Style: hand-inked 1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture, exactly like the references.

Sheet: canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first. If the image tool cannot make 2048 x 1024, keep the same 4 x 2 layout with SQUARE cells (do not make the cells taller) and scale every number by the same factor; say the real size when you deliver. Side view, facing RIGHT. The acrobat is IDENTICAL in every frame; only the pose and the face change. Frames 1 and 8 are on the ground: the soles of her shoes exactly at y = 486 of the cell, the body centered around x = 256. Frames 2 to 7 are in the air: keep the gold star at her waist at the same point in every one of them, x = 256, y = 250. At least 12 px of empty margin around the whole drawing inside its cell (including the bun, the stretched legs and the stars); if a stretched pose would come near the border, bend the knees instead of shrinking her. Nothing crosses into another cell. Fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels), clean edges without halo or stray specks, no grid lines, no text, no ground, no shadow, no motion blur, no speed lines.
ARMS: NO gun in any frame. BOTH arms are drawn, white gloves.

Animation: "DEATH-DEFYING LEAP" (salto mortal), 8 frames. Frames 2 to 7 together show ONE complete forward somersault (360 degrees) drawn frame by frame (the body really turns through the frames; never the same drawing rotated):
1 deep crouch on the ground ready to spring, fierce determined eyes;
2 explosive take-off, body stretched diagonally up and forward, shouting "hup!";
3 tucking in, rotated about 90 degrees forward, knees to chest, focused squint;
4 upside-down (180 degrees), legs stretched up in a split like a star, laughing;
5 tuck at 270 degrees, eyes shut tight, teeth gritted;
6 coming upright, one leg extending forward in a flying kick, fierce grin;
7 the KICK: leg fully extended forward, arms back, triumphant shout, small gold stars around the foot;
8 landing on the ground in a performer's pose: one knee bent, arms raised "ta-da!", big smile.
FACIAL EXPRESSIONS: a different, exaggerated rubber-hose cartoon expression in EVERY frame, always clearly the same acrobat.
```
