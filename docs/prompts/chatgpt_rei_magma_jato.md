# Pedido ao ChatGPT (imagens): o jato do Rei Magma, refeito

Escrito em 07/10/2026, a pedido do usuário depois do primeiro teste da luta: na Rajada da fase 3, quando o jato
vem baixo, o rei só afundava atrás da margem e o jato saía da boca como um retângulo cortado. Ficou feio.

Agora o rei ganha **poses próprias para cada altura do jato**, e o jato vem em **três peças** (o clarão na
boca, o meio que se repete e a ponta que bate na parede), para não ter mais corte reto. As três alturas do
jogo:

- **baixo:** rente ao chão, quem está no chão pula ou sobe numa jangada;
- **médio:** na altura do peito, quem está no chão abaixa;
- **alto:** na altura das jangadas, quem está nelas desce.

Colar o bloco inteiro de uma vez. Depois, mostrar ao Claude, que recorta (`tools/cut_magma_king_art.py`) e
troca no jogo.

```
IMPORTANT: Only create the image files at the exact paths below. Do not modify, move or delete any other file of the project. Do not run any git command. Make ALL the files below without stopping to ask questions or show partial results; only talk to me when everything is done, with a short summary.

CONTEXT: this is the phase 3 form of REI MAGMA, the boss of our 2D side-view game: the king made of PURE MAGMA, tall and thin, with the obsidian crown floating above his head. Use docs/referencias/pecas/vulcao/rei_magma/rei_folha.png (the RIGHT drawing) and docs/referencias/pecas/vulcao/rei_magma/rei_derretido.png as the EXACT character reference: same body, same face, same colors, same crown, same size. He breathes a long horizontal jet of magma to the LEFT, at three heights.

STYLE: exactly like those sheets: hand-inked 1930s cartoon look, thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture. The magma jet must be the brightest thing on screen: a pale YELLOW-WHITE hot core, an orange rim with a little MAGENTA at the edges, and a thick dark outline, so it reads on top of a lava background.

ANIMATION: every frame is a real, different drawing (anticipation, action, follow-through), never the same drawing slid or squashed. A DIFFERENT exaggerated facial expression in every frame (written in parentheses).

FORMAT: PNG with a fully TRANSPARENT background (real alpha 0 outside the drawing, no faint glow around it). No grid lines, no text, no numbers, no ground, no shadows. Cells are read left to right. The king faces LEFT. In every king cell his lowest point (the magma puddle of his feet) touches a baseline at y = 980 of the cell, centered at x = 512. Same size of the king in every cell of every file (he fills about 80% of the cell height when standing straight). Keep at least 24 px of empty margin around every drawing. Do NOT draw the jet in the king sheets: only the mouth wide open with a small burst of fire right at the lips.

Save inside docs/referencias/pecas/vulcao/rei_magma/ :

1. rei_jato_baixo.png — 4096 x 1024, 4 cells of 1024 x 1024: the LOW jet. He bends his whole body forward and down like a hunchback, his face almost touching the ground, mouth open at about y = 920 of the cell (just above the baseline) and at about x = 230 of the cell (at the LEFT side of his body):
   (1) starting to bend, cheeks swelling and glowing white (WARNING, eyes squeezed); (2) fully bent down, mouth opening, glow inside (strained, eyes bulging); (3) spitting, mouth wide open at the ground, a fire burst at the lips, body pushed back by the recoil (furious); (4) still spitting, the crown wobbling above his back, magma drips flying behind him (manic grin while spitting).
   In frames 2, 3 and 4 the mouth opening is in EXACTLY the same place.
2. rei_jato_medio.png — 4096 x 1024, same layout: the MIDDLE jet. He leans forward with his head pushed out, mouth at about y = 760 of the cell and x = 220:
   (1) leaning back, cheeks glowing (WARNING, eyes narrowed); (2) throwing the head forward, mouth opening (snarling); (3) spitting, fire burst at the lips, shoulders hunched by the recoil (furious); (4) still spitting, arms spread for balance (gleeful).
   In frames 2, 3 and 4 the mouth opening is in EXACTLY the same place.
3. rei_jato_alto.png — 4096 x 1024, same layout: the HIGH jet. He stands up straight, chest out, and lowers his head a little to aim, mouth at about y = 480 of the cell and x = 230:
   (1) puffing up the chest, cheeks glowing (WARNING, smug); (2) head lowered to aim, mouth opening (mocking); (3) spitting, fire burst at the lips (cackling); (4) still spitting, body swaying back (wild eyes).
   In frames 2, 3 and 4 the mouth opening is in EXACTLY the same place.
4. jato_pecas.png — 3072 x 768, 3 columns x 3 rows of 1024 x 256 cells, the three PIECES of the horizontal jet, all going to the LEFT, all with the jet centered on y = 128 of the cell and about 110 px thick:
   Row 1, the MOUTH piece (3 animation frames): the start of the jet, a round flaring burst of fire about 200 px wide on the RIGHT side of the cell, that narrows into the jet body which reaches the LEFT edge of the cell. The burst touches the right edge of its drawing area at x = 1000.
   Row 2, the MIDDLE piece (3 animation frames): a straight segment of the jet body that fills the whole cell width (x 0 to 1024) and TILES horizontally: the left edge must match the right edge perfectly (same thickness, same position), with flickering flames and small magma drops along it.
   Row 3, the TIP piece (3 animation frames): the end of the jet hitting a wall on the LEFT: the jet body comes from the right edge of the cell and splashes into a burst of fire and drops on the left, the burst touching x = 24.
```

## Depois

Mostrar ao Claude. Ele recorta as três poses e as peças, alinha a boca de cada pose com o começo do jato
(medindo onde a boca ficou) e troca no jogo, sem mudar o tempo nem as alturas da Rajada.
