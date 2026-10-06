# Pedido ao ChatGPT (imagens): os desafiantes dos vagões do Trem

Escrito em 06/10/2026, a pedido do usuário: a fase do Trem estava simples e fácil (dava para terminar em menos
de 1 minuto). Cada vagão temático ganha um desafio com um **desafiante novo**, que não aproveita nada dos
chefões que já existem (nada do Domador, do leão, dos Malabaristas nem do Mágico). Até as imagens chegarem, o
jogo usa desenhos provisórios feitos por código, com as mesmas medidas.

O ChatGPT tem acesso ao projeto: ele pode ler as referências e salvar as imagens direto nos caminhos abaixo.
Mandar **um pedido por vez** (D1 a D5), na ordem. O Claude confere, normaliza (`tools/normalize_sheet.gd`) e
liga no jogo.

Regras para todos os pedidos (colar junto):

```
IMPORTANT: Only create image files at the exact paths below. Do not modify, move or delete any other file of the project. Do not run any git command.

STYLE: a 2D game about a haunted 1930s circus. Hand-inked 1930s rubber-hose cartoon style (pie-cut eyes, bendy limbs, white gloves), thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture. These are ORIGINAL characters: do not imitate any existing game or cartoon character. Match the art already in the project: look at docs/referencias/pecas/palhaco_folha.png, docs/referencias/pecas/acrobata_folha.png and the train enemies in docs/referencias/pecas/trem/ (fantasma.png, pombo.png, canhao.png). Palette: muted circus red, cream, brass gold, dark brown ink, with a few accent colors. Every character is a little GHOST of the circus: slightly see-through pale edges, a faint cold glow.

ANIMATION: every frame is a real pose (anticipation, action, follow-through), never the same drawing slid around. A DIFFERENT exaggerated facial expression in every frame.

FORMAT: PNG with a fully TRANSPARENT background. Exact canvas sizes. Grids are invisible: no grid lines, no text, no numbers, no shadows on the ground. Every drawing stays inside its own cell with at least 16 px of empty margin. Characters face LEFT (toward the players, who come from the left) unless said otherwise. In every cell the character's feet (or lowest point) touch the same baseline at y = 480 of the cell, centered at x = 256, unless said otherwise.
```

## D1 — Vagão ACROBATAS: o Saltimbanco de Mola

```
Save as docs/referencias/pecas/trem/desafiantes/saltimbanco.png (create the folders). 2048 x 1024, 4 columns x 2 rows of 512 x 512 cells, read left to right, top row first.
A skinny ghost acrobat in a striped leotard and a tiny pillbox hat, standing on a big brass pogo spring (the spring is part of him). He bounces in huge arcs across the train roof and lands with a shock.
  Row 1 (bounce loop): 1 squashed on the compressed spring, knees bent (eager grin); 2 launching, spring stretched, arms up (whooping); 3 high in the air, body tucked in a somersault (dizzy delight); 4 falling feet first, spring pointing down (wicked aim).
  Row 2: 5 slamming down, spring fully crushed, a ring of dust (teeth clenched); 6 wobbling after the landing (smug); 7 hit: spring bent, eyes spinning (shocked); 8 defeated: spring snapped, he deflates into a limp leotard (tongue out).
In row 1 frames 2-4 the baseline does not apply: draw him in the air, centered in the cell.
Also save docs/referencias/pecas/trem/desafiantes/onda_impacto.png — 1024 x 256, 4 cells of 256: the shockwave of his landing running along the roof, a low flat ring of dust and sparks, 4 frames growing and fading. Baseline y = 230.
```

## D2 — Vagão TRAPÉZIO: a Trapezista do Além

```
Save as docs/referencias/pecas/trem/desafiantes/trapezista.png — 2048 x 1024, 4 columns x 2 rows of 512 x 512 cells.
A tall ghost trapeze artist with a feathered headband and a long flowing scarf, hanging from a trapeze bar by her knees, upside down. The trapeze ropes are NOT drawn (the game draws them): the bar is always at the TOP of the cell, horizontal, centered at x = 256, y = 60, about 200 px wide, and she hangs from it.
  Row 1 (swing loop): 1 swinging back, arms stretched (sly smile); 2 bottom of the swing, arms reaching down to grab (greedy, mouth open); 3 swinging forward, scarf trailing (laughing); 4 top of the swing, arms crossed (bored).
  Row 2: 5 swooping low, claws out (screaming); 6 blowing a kiss that becomes a small pink heart (the parry heart, coquettish); 7 hit, feathers flying (outraged); 8 defeated: she lets go and dissolves into a falling scarf (fainting).
Also save docs/referencias/pecas/trem/desafiantes/trapezio_tabua.png — 512 x 512: an empty trapeze for the PLAYERS to ride over the gap: a wide wooden swing seat (about 300 px wide, 30 px thick) with gold ends, seen from the side, the seat centered at x = 256, y = 460, and the two ropes going straight up to the top edge (y = 0).
```

## D3 — Vagão LEÕES: os Leõezinhos de Pelúcia

```
Save as docs/referencias/pecas/trem/desafiantes/leaozinho.png — 2048 x 1024, 4 columns x 2 rows of 512 x 512 cells.
NOT a real lion: an old, patched stuffed-toy lion head (plush, button eyes, yarn mane, a stitched smile), possessed by a ghost. It pops out of a round hatch in the train roof like a jack-in-the-box, on a coiled spring neck, and spits a ball of yarn. The round hatch (a brass ring 180 px wide, seen slightly from above) is drawn in EVERY cell at the bottom, centered at x = 256, y = 470; the head comes up out of it.
  Row 1: 1 hatch closed, the lid rattling (only the lid and two button eyes peeking); 2 popping out, spring neck stretched (manic grin); 3 fully up, mouth wide open spitting (cheeks puffed); 4 sinking back down (snickering).
  Row 2: 5 roaring up close (fake fierce, stitches straining); 6 dizzy, button eye hanging by a thread (dazed); 7 hit, stuffing bursting out of a seam (yelping); 8 defeated: the head flops over the hatch rim, stuffing everywhere (X button eyes).
Also save docs/referencias/pecas/trem/desafiantes/novelo.png — 1024 x 256, 4 cells of 256: the ball of yarn it spits (about 70 px), rolling (4 rotations), with a little loose thread trailing. The 4th cell: the same ball all PINK (the game uses pink for "parry me").
```

## D4 — Vagão BALÕES: o Baloeiro Assombrado

```
Save as docs/referencias/pecas/trem/desafiantes/baloeiro.png — 2048 x 1024, 4 columns x 2 rows of 512 x 512 cells.
A chubby ghost balloon-seller floating in the air, held up by a bunch of colorful balloons tied to his wrist, with a sack of water balloons. He drifts over the wagon and drops water balloons on the players. Centered in the cell (no baseline).
  Row 1 (float loop): 1 drifting, whistling (cheerful); 2 looking down, aiming (squinting, tongue out); 3 dropping a water balloon (cackling); 4 waving (fake friendly).
  Row 2: 5 one balloon popped, he sinks a little (alarmed); 6 two balloons popped, holding on desperately (panic); 7 hit (ouch face); 8 defeated: all balloons popped, he falls with a small parachute made of his hat (resigned).
Also save docs/referencias/pecas/trem/desafiantes/bexiga_agua.png — 1024 x 256, 4 cells: 1 a blue water balloon falling (about 60 px); 2 the same, wobbling; 3 splash on the roof (a flat puddle burst); 4 the same balloon all PINK.
Also save docs/referencias/pecas/trem/desafiantes/balao_plataforma.png — 1024 x 512, 4 cells of 256 x 512: a big single circus balloon (about 200 px wide) with a small wooden plank hanging under it on two strings (the players stand on the plank, its top at y = 470 of the cell), in 4 colors: red, gold, teal, pink-free purple.
```

## D5 — Vagão FANTASMAS: a Sombra do Lanterninha

```
Save as docs/referencias/pecas/trem/desafiantes/lanterninha.png — 2048 x 1024, 4 columns x 2 rows of 512 x 512 cells.
A tall, thin ghost usher (the theater "lanterninha") in an old usher uniform with a cap, holding a tin lantern. He fades in and out: when his lantern is lit he is solid and can be hit; when it goes out he is only a see-through shadow and bullets pass through him.
  Row 1 (solid, lantern lit): 1 walking, lantern raised (stern); 2 swinging the lantern like a club (angry); 3 shushing the players, finger on lips (annoyed); 4 lantern flickering (worried).
  Row 2: 5 fading: half transparent, lantern out (sinister smile); 6 only a dark see-through silhouette with two glowing eyes (creepy); 7 hit, cap flying (startled); 8 defeated: the lantern drops and he fades into smoke (sad sigh).
```

## Depois de cada pedido
Mostrar o resultado ao Claude. Ele confere a grade, a linha do chão e o tamanho, normaliza o que precisar e
troca o desenho provisório pelo novo sem mudar os números do desafio.
