# Pedido ao ChatGPT (imagens): armas, tiros, trem e ícones dos itens

Escrito em 05/10/2026, a pedido do usuário. O ChatGPT tem acesso a este projeto: ele pode ler as referências
e salvar as imagens direto nos caminhos abaixo. Mandar **um pedido por vez** (A, B, C), na ordem; o Claude
confere, normaliza (`tools/normalize_sheet.gd` e `tools/normalize_rider_sheet.gd` quando a grade não for
respeitada) e liga no jogo.

**O que existe hoje (tudo provisório, desenhado por código):**
- Os tiros das 4 pistolas (Rolha, Leque de Confete, Clave de Malabares, Bolha de Sabão) e os Tiros EX
  (`components/projectile/projectile.gd`, `area_blast.gd`, `big_cork.svg`). A luva com a pistola é uma
  imagem só (`core/player/characters/shared/glove_gun.png`) para as 4 pistolas.
- A fase do Trem do Circo inteira: vagões, locomotiva, fundo, ponte e inimigos (`levels/train/`).
  O antigo pedido ao Codex (`docs/prompts/codex_trem.md`) nunca foi feito; o Pedido B o substitui.
- Os 17 itens da loja não têm imagem (a prateleira só mostra texto).

Regras para todos os pedidos (colar junto):

```
IMPORTANT: Only create image files at the exact paths below. Do not modify, move or delete any other file of the project. Do not run any git command.

STYLE: a 2D Godot game about a haunted 1930s circus, exactly like the art already in the project: hand-inked 1930s rubber-hose cartoon like Cuphead, thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture. Look at these files first and match them: docs/referencias/pecas/palhaco_folha.png, docs/referencias/pecas/acrobata_folha.png, docs/referencias/pecas/luva_pistola.png, docs/referencias/direcao_arena.png. Palette: muted circus red, cream, brass gold, dark brown ink, with a few accent colors.

FORMAT: PNG with a fully TRANSPARENT background (unless a file says otherwise). Exact canvas sizes. Grids are invisible: no grid lines, no text, no numbers, no shadows on the ground. Every drawing stays inside its own cell with at least 16 px of empty margin.
```

## Pedido A — as pistolas e os tiros

```
Save inside the project in the folder docs/referencias/pecas/armas/ (create it).

A1. docs/referencias/pecas/armas/luvas_pistolas.png — 2048 x 512, 4 cells of 512 x 512 in one row. Each cell: the white cartoon glove (same glove as luva_pistola.png) holding one of the four circus pistols, seen from the side, pointing RIGHT, horizontal. In EVERY cell the wrist opening is at x = 60, y = 256 (left side of the cell) and the tip of the barrel (where the shot comes out) is at x = 440, y = 256. Cells, left to right:
  1. ROLHA: a brass pop-gun with a cork in the barrel (the current one).
  2. LEQUE DE CONFETE: a short blunderbuss with a wide flared mouth, painted with red and gold stripes, confetti bits peeking out.
  3. CLAVE DE MALABARES: a launcher shaped like a juggling club with a little spring at the back.
  4. BOLHA DE SABÃO: a bubble wand pistol with a small soap bottle on top and a round ring at the tip.

A2. docs/referencias/pecas/armas/tiros.png — 2048 x 1024, a grid of 8 columns x 4 rows of 256 x 256 cells, read left to right, top row first. The projectile is CENTERED in its cell and flies to the RIGHT. Rows:
  Row 1 ROLHA: cells 1-4 a flying cork (about 70 px long) spinning (4 frames of a quarter turn each, with a tiny speed streak behind); cells 5-8 the cork hitting: a small cream puff with a "pop" burst, 4 frames growing then fading.
  Row 2 CONFETE: cells 1-4 four single confetti pieces (about 40 px), each a different color (red, gold, teal, pink), a little curled paper rectangle; cells 5-8 a hit: a small burst of confetti bits, 4 frames.
  Row 3 CLAVE: cells 1-4 a white and red juggling club (about 110 px long) at 0, 45, 90 and 135 degrees (the game spins it); cells 5-8 a hit: gold sparkle stars, 4 frames.
  Row 4 BOLHA: cells 1-4 a soap bubble (about 60 px) with rainbow sheen, wobbling (4 frames: round, wide, round, tall); cells 5-8 the bubble popping: ring of droplets, 4 frames.

A3. docs/referencias/pecas/armas/tiros_ex.png — 2048 x 1024, 4 columns x 2 rows of 512 x 512 cells, centered, facing RIGHT:
  1-2 ROLHÃO: a giant cork (about 300 px long) flying, 2 frames (spinning a little), with a strong speed streak.
  3-6 CANHÃO DE CONFETE: an explosion of confetti and streamers around a center point, 4 frames growing (first small, last filling about 460 px), the last one already thinning out.
  7 BOLHONA: a big soap bubble (about 300 px) with rainbow sheen and a tiny frowning face reflection.
  8 BOLHONA POP: the big bubble bursting into a ring of droplets and foam.

A4. docs/referencias/pecas/armas/claroes.png — 1024 x 256, 4 cells of 256 x 256: the muzzle flash of each pistol, coming out of the LEFT edge of the cell going to the right (the flash starts at x = 0, y = 128): 1 a cream "pop" puff; 2 a fan of confetti; 3 a puff with a little spring "boing" line; 4 a burst of small bubbles.
```

## Pedido B — a fase do Trem do Circo

```
Save inside the project in the folder docs/referencias/pecas/trem/ (create it). The level happens on the ROOF of a moving circus train at sunset; the characters run on the roofs from left to right.

B1. vagao_1.png ... vagao_4.png — four circus wagons, side view, each 800 x 300 canvas, the flat roof exactly at the top edge (y = 0) so the characters stand on it, the wheels touching the bottom edge, the box filling the whole width. Colors: red, blue, mustard, green, with gold trim, painted stars and an EMPTY banner panel in the middle (the game writes the name).
B2. rodas.png — 1024 x 256, 4 cells of 256: one wagon wheel (about 200 px diameter, red with gold hub and 8 spokes) in 4 rotations of 22.5 degrees, for the rolling loop.
B3. locomotiva.png — 900 x 560 canvas: an old circus steam locomotive seen from the side, facing RIGHT, black and red with gold details, big smokestack, cab at the back (left side). The roof of the low front part at y = 260 (players walk on it). No smoke (separate file).
B4. fumaca.png — 1024 x 256, 4 cells of 256: a puff of steam/smoke growing and fading, 4 frames, for the smokestack.
B5. fundo_morros.png — 1920 x 1080, NO transparency: a sunset sky with distant purple hills; the left and right edges must match so it tiles horizontally.
B6. fundo_postes.png — 1920 x 1080, transparent: telegraph poles and a wooden fence on the ground line (bottom 300 px), tiling horizontally.
B7. ponte.png — 160 x 900: a wooden trestle bridge seen from the side, coming down from the top of the image, with a thick beam at the bottom edge (the train passes under it; players must crouch).
B8. placa_abaixe.png — 400 x 200: a hand-painted circus warning sign with a downward arrow and NO text (the game writes "ABAIXE!").
B9. Enemy sheets, 2048 x 512 (4 cells of 512 in a row), side view, frames read left to right, a DIFFERENT exaggerated face in every frame:
  - fantasma.png — a little ghost clown made of a white bedsheet with a red nose and a tiny party hat, hopping: crouch (sneaky grin), jump (gleeful "boo!"), top (tongue out), landing squash (eyes squeezed).
  - fantasma_derrota.png — the same ghost hit and deflating into a flat sheet, 4 frames.
  - pombo.png — a magician's white dove flapping, 4 frames of a wing loop (smug, angry, surprised, cooing).
  - pombo_rosa.png — the same dove, all pale PINK (the game uses pink for "parry me"), same 4 frames.
  - canhao.png — a little circus confetti cannon on wheels with a face, facing LEFT: idle (bored), charging (cheeks puffed), firing (mouth wide open, recoil), after shot (dizzy).
  - bola_canhao.png — 1024 x 256, 4 cells: the cannon ball rolling (a striped circus ball, 4 rotations), the 4th cell the same ball all PINK.
B10. ingresso_escondido.png — 1024 x 256, 4 cells: a golden circus ticket floating and spinning (4 frames), for the hidden tickets.
```

## Pedido C — ícones dos itens da loja

```
Save inside the project as docs/referencias/pecas/itens/icones.png (create the folder). Canvas 1536 x 768, a grid of 6 columns x 3 rows of 256 x 256 cells, read left to right, top row first. Each cell: ONE object, centered, about 190 px, slightly tilted, like a painted shop label, no text. The last cell (row 3, column 6) stays EMPTY. Read dialogues/items.json for what each item does.
  1 Rolha (a brass pop-gun with a cork), 2 Leque de Confete (a striped blunderbuss full of confetti), 3 Clave de Malabares (a juggling club with a spring), 4 Bolha de Sabão (a bubble wand pistol),
  5 Cambalhota (a little spinning acrobat silhouette with motion arcs), 6 Fumaça do Mágico (a puff of purple smoke with a top hat in it),
  7 Bala de Canhão (a circus cannonball with a fuse), 8 Pirueta (a ballet slipper with a spin swirl), 9 Coração de Pano (a stitched patchwork heart),
  10 Nariz de Buzina (a red clown nose with a brass horn bulb), 11 Luvas de Mímico (a pair of white mime gloves), 12 Sapatos de Mola (big clown shoes on springs),
  13 Trevo da Cartomante (a four-leaf clover with a crystal-ball sparkle), 14 Catapulta (a wooden circus catapult), 15 Rolha Turbinada (a cork with little flames and wings),
  16 Pirâmide Humana (two tiny acrobat figures stacked), 17 Rede de Segurança (a circus safety net with a pink balloon).
```

## Depois de cada pedido
Mostrar o resultado ao Claude. Ele confere a grade e as âncoras (pulso e boca da pistola, chão dos vagões),
normaliza o que precisar e liga no jogo sem mudar números da luta.

## Situação (05/10/2026)
Os três pedidos chegaram (o usuário mandou num zip), todos no tamanho pedido. O ingresso escondido veio
estragado (quadro 1 cortado, quadro 3 vazio) e foi refeito. O clarão foi salvo como `claroes.png`, sem acento.
O Pedido A está no jogo (Fase 1) e o C também (Fase 2), ver docs/DESIGN.md; o B espera a Fase 4.
