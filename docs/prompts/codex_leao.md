# Pedidos ao Codex: arte do Leopoldo (leão)

Mandar o **Pedido 1** primeiro e mostrar o resultado ao Claude. Só depois de aprovado, mandar o **Pedido 2**.

## Pedido 1 — desenho base

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE character design sheet for "Leopoldo", the lion boss of a 2D Godot game about a haunted 1930s circus.
Save it INSIDE the project at exactly: docs/referencias/pecas/leao/leao_folha.png (create the folder). Canvas exactly 2048 x 1024, fully TRANSPARENT background (real alpha), no text, no grid, no shadows.

References (read from the project):
- docs/referencias/leopoldo_atual.png = the current placeholder lion (keep the concept: huge round dark mane, golden body, tail with a dark tuft, lazy smug face). The new one must look MUCH better.
- docs/referencias/pecas/palhaco_folha.png and docs/referencias/pecas/acrobata_folha.png = the ART STYLE to match exactly: hand-inked 1930s rubber-hose cartoon (Cuphead-like), thick dark brown outline #1b1410, warm painted shading, slightly worn print texture.

Personality: a HUGE, lazy, smug circus lion who only pretends to obey his tamer. Half-closed eyes, sly smile, big round fluffy mane, chunky paws, long tail with a tuft. Golden-orange fur, dark red-brown mane.

Layout, all facing LEFT, side view:
1. Left half: full body standing pose (side view facing LEFT), the main model.
2. Right half, three heads in a row: calm head (sly smile); ROARING head (mouth wide open, teeth, angry eyes, mane bristling); head with the mane ON FIRE (flames instead of mane fur, orange/yellow fire, same face).
```

## Pedido 2 — animações (só depois de aprovar o Pedido 1)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Using docs/referencias/pecas/leao/leao_folha.png as the EXACT character reference (same design, colors, proportions, ink style), create these animation sheets for Leopoldo the lion. Save each INSIDE the project at the exact path, replacing if it exists.

Rules for every sheet:
- Side view, facing LEFT. The lion is IDENTICAL in every frame; only the pose changes.
- Grid of cells of 1024 x 512 pixels (2 columns), one frame per cell, read left to right, top row first.
- The lion fills about 880 px wide and up to 440 px tall inside the cell, centered horizontally; paws touch the SAME ground line about 30 px above the bottom of each cell (in jump frames the hips stay at the standing height and only the pose changes).
- Nothing crosses into another cell. Fully TRANSPARENT background (real alpha), no grid lines, no text, no shadows.

Sheets:
1. docs/referencias/pecas/leao/leao_parado.png — canvas 2048 x 1024 (2 x 2 cells), IDLE, 4 frames loop: standing, slow breathing (chest up/down), tail swishing; frame 3 eyes closed (blink).
2. docs/referencias/pecas/leao/leao_rugido.png — canvas 2048 x 1024 (2 x 2 cells), ROAR, 4 frames: 1 wind-up (head pulled back, chest in, eyes squinting), 2 mouth opening, 3 FULL roar (mouth wide, mane bristling, body leaning forward), 4 like 3 with a small variation (frames 3-4 loop).
3. docs/referencias/pecas/leao/leao_corrida.png — canvas 2048 x 2048 (2 columns x 4 rows), GALLOP, 8 frames, real quadruped gallop loop (front legs and back legs alternate; frame 8 flows back into frame 1), body low and stretched, mane and tail flowing back.
4. docs/referencias/pecas/leao/leao_pulo.png — canvas 2048 x 1024 (2 x 2 cells), LEAP, 4 frames: 1 crouched ready to spring (body low, haunches up), 2 take-off fully stretched, 3 flying (front paws reaching forward, back legs stretched back), 4 landing squash (body compressed, paws spread).
```

## Pedido 3 — salto de verdade e leão de fogo (depois do Pedido 2)

O salto pelas argolas usava um desenho parado deslizando. Este pedido traz o voo inteiro desenhado
quadro a quadro e as versões em chamas (fase 3). Cada quadro com a expressão certa.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Using docs/referencias/pecas/leao/leao_folha.png and the existing sheets in docs/referencias/pecas/leao/ as the EXACT character reference (same design, colors, proportions, ink style), create these new sheets for Leopoldo the lion. Save each INSIDE the project at the exact path, replacing if it exists.

Same rules as before: side view facing LEFT; cells of 1024 x 512 (2 columns), read left to right, top row first; the lion about 880 px wide and up to 440 px tall inside the cell, centered horizontally; standing paws on the ground line about 30 px above the bottom of the cell (for frames in the air, keep the body centered in the cell the same way as in leao_pulo.png). Nothing crosses into another cell. Fully TRANSPARENT background, no grid, no text, no shadows.

FACIAL EXPRESSIONS ARE IMPORTANT: the face must change with the action in every frame (rubber-hose cartoon acting, exaggerated like Cuphead). Never the same face in all frames.

1. docs/referencias/pecas/leao/leao_salto.png — canvas 2048 x 2048 (2 x 4 cells), FULL LEAP ARC, 8 frames, played over the whole flight of a long showman leap through circus hoops:
   1 deep crouch, smug grin, eyes on the target;
   2 explosive take-off, body stretched diagonally upward, mouth open in a cocky "hah!";
   3 rising, front legs reaching forward and up, mane and tail streaming back;
   4 apex, body fully horizontal and stretched long like a showman, eyes closed, proud smile;
   5 apex variation, tail curling, one eye opening to wink at the audience;
   6 starting to fall, front paws reaching down and forward, focused eyes;
   7 just before landing, front paws extended to the ground, back legs tucked, mouth closed tight in effort;
   8 landing impact, body squashed, paws spread wide, cheeks puffed, eyes squeezed.
2. docs/referencias/pecas/leao/leao_fogo_parado.png — same as leao_parado.png (4 frames) but the MANE IS MADE OF FIRE (orange/yellow cartoon flames instead of fur, same face shape as the fire head in leao_folha.png), face now angry and wild-eyed.
3. docs/referencias/pecas/leao/leao_fogo_corrida.png — same as leao_corrida.png (8 frames, 2048 x 2048) with the FIRE MANE streaming back like a torch, furious grin showing teeth.
4. docs/referencias/pecas/leao/leao_fogo_salto.png — same as leao_salto.png (8 frames, 2048 x 2048) with the FIRE MANE, expressions angrier and wilder.
```
