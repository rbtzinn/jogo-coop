# Pedido ao ChatGPT (imagens): efeitos da luta do Domador (Pedido D)

Escrito em 05/10/2026, a pedido do usuário. Os efeitos da luta do Domador ainda são desenhados por código
ou são SVGs provisórios:
- as ondas de som do Rugido (`bosses/tamer/attacks/sound_wave.gd`, só na fase 1);
- a onda da Chicotada, normal e rosa (`whip_wave.gd`);
- as brasas, normal e rosa (`art/ember.svg`, `art/ember_pink.svg`);
- as argolas de fogo, apagada (aviso), acesa e rosa (`art/fire_ring_*.svg`, `art/pink_ring_*.svg`).

Decidido com o usuário: as ondas do Rugido são **ondas de som** (arcos grossos com riscos de vibração), uma
versão só (cor de creme), e o pedido inclui todos os efeitos do Domador.

**Por que a onda de som vem em peças:** cada onda é um arco de ~700 px com um buraco que muda de lugar (rente
ao chão ou na altura do pulo). O jogo monta a onda com um trecho que se repete e as duas pontas, nos dois
lados do buraco.

**Medidas usadas (o jogo usa as imagens com metade do tamanho):**
- onda da Chicotada: 96 × 86 no jogo → desenho de ~190 × 170 numa célula de 256;
- brasa: 48 × 64 no jogo → ~90 × 120 numa célula de 128;
- argola: 228 × 312 no jogo (miolo livre de 140 × 224) → célula de 512 × 640;
- onda de som: faixa de ~70 px de largura no jogo → ~140 px numa célula de 256.

## Prompt (colar inteiro)

```
Create image sheets for a 2D Godot game about a haunted 1930s circus, and then save them into the repository and push (instructions at the end).

STYLE: exactly like the art already in the project: hand-inked 1930s rubber-hose cartoon like Cuphead, thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture. Look at these files first and match them: docs/referencias/pecas/leao/leao_rugido.png, docs/referencias/pecas/leao/leao_fogo_parado.png, docs/referencias/pecas/domador/domador_chicote.png, docs/referencias/direcao_arena.png. These are ATTACKS of the boss: they must read instantly on top of a busy, dark circus background.

FORMAT FOR EVERY FILE: PNG with a fully TRANSPARENT background (real alpha 0 everywhere outside the drawing, no faint pixels, no glow outside the drawing). Grids are invisible: no grid lines, no text, no numbers, no ground, no shadows. Every drawing stays inside its own cell with at least 12 px of empty margin. If the image tool cannot make the exact canvas size, keep the same grid layout with the same cell proportions and scale EVERY number by the same factor, and report the real size.

Save everything in the folder docs/referencias/pecas/domador/efeitos/ (create it).

D1. ondas_som.png — the SOUND WAVES of the lion's ROAR. Canvas 768 x 768, a grid of 3 columns x 3 rows of 256 x 256 cells. The wave is a thick vertical BAND of sound travelling to the LEFT: a bold cream/pale-gold arc stroke (#fff6dc center, #f3d9a0 body, thick #1b1410 outline), about 60 px wide, with two thinner, fainter "echo" strokes BEHIND it (on its RIGHT side) and small cartoon vibration ticks. The band is VERTICAL and STRAIGHT inside each cell (the game bends it). The leading stroke is centered at x = 100; the echoes go to the right of it, up to x = 220. The 3 columns are 3 frames of a vibration loop (the band wobbles a little, the ticks change); frame N of every row matches.
  Row 1, MIDDLE PIECE: the band crosses the whole cell from top edge (y = 0) to bottom edge (y = 256) and must TILE SEAMLESSLY vertically (the top edge continues exactly into the bottom edge). This row is the only one allowed to touch the cell edges.
  Row 2, UPPER END: the band comes from the bottom edge of the cell (y = 256) and ENDS with a rounded, vibrating tip at about y = 90 (empty above).
  Row 3, LOWER END: the band comes from the top edge of the cell (y = 0) and ENDS with a rounded, vibrating tip at about y = 166 (empty below).
  The band must have the same width and position in all three rows, so the ends join the middle piece perfectly.

D2. onda_chicote.png — the WHIP SHOCKWAVE that runs along the ground to the LEFT. Canvas 1024 x 512, a grid of 4 columns x 2 rows of 256 x 256 cells. In each cell, a crest-shaped blade of dust and sparks, about 190 px wide and 170 px tall, pointing/leaning to the LEFT, with 2-3 short speed streaks behind it on the right. Its flat BOTTOM sits exactly on y = 236, horizontally centered at x = 128. Row 1: 4 frames of the NORMAL wave (golden #f0c46a with a pale #fff3c4 core), a flickering loop. Row 2: the SAME 4 frames all in PINK (#ff5fa2 with a pale #ffd1e6 core) — pink means "the player can parry it".

D3. brasas.png — falling EMBERS. Canvas 512 x 128, 4 cells of 128 x 128 in a row. Each cell: one ember falling, a little flame drop about 90 px wide and 120 px tall at most, the hot round body at the bottom and the flame tail pointing UP, centered in the cell. Cells 1-2: normal ember (orange and yellow, dark outline), 2 frames of flicker. Cells 3-4: the same ember all in PINK (#ff5fa2, pale pink core), 2 frames of flicker.

D4. argolas.png — the circus FIRE RINGS the lion jumps through. Canvas 2048 x 640, 4 cells of 512 x 640 in a row. Each cell: one ring seen from the front, a tall ellipse centered at (256, 320): the metal hoop's centerline is an ellipse of 280 x 448 px; the hole in the middle must stay EMPTY and transparent (at least 220 x 390 px free), and the drawing must be left-right symmetric enough to be cut down the vertical middle (the left half is drawn in front of the lion and the right half behind it). Flames may rise up to 60 px outside the hoop.
  Cell 1 UNLIT (warning): the bare iron hoop, dark metal with brass bands, wrapped in rags, a few small smoke wisps, no fire.
  Cells 2-3 LIT: the same hoop all ablaze with orange and yellow 1930s cartoon flames, 2 frames of a flicker loop (different flame shapes).
  Cell 4 PINK: the same burning hoop with all the flames PINK (#ff5fa2 with pale pink cores) — pink means "the player can parry it".

AFTER THE IMAGES ARE READY, SAVE AND PUSH:
- Only add these 4 files: docs/referencias/pecas/domador/efeitos/ondas_som.png, onda_chicote.png, brasas.png, argolas.png. Do not create, modify, move or delete any other file.
- Create a new branch named arte/chatgpt-pedido-d from main. Do NOT commit to main.
- One commit with the message: "arte: Pedido D (efeitos do Domador)"
- Push the branch to origin.
- When done, reply with: the branch name, and the exact pixel size (width x height) of each file.
```

## Depois
Mostrar o resultado ao Claude (ou só avisar o nome da branch). Ele confere a grade, as âncoras (a base da
onda da Chicotada, o miolo livre das argolas, a emenda das peças da onda de som), normaliza o que precisar e
liga no jogo sem mudar números da luta.
