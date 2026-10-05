# Pedidos ao Codex: Os Irmãos Malabaristas, Tico e Teco

Hoje os irmãos são desenhados por código (provisório). Mandar o **Pedido 1** primeiro e mostrar
o resultado ao Claude; só depois de aprovado, o **Pedido 2**.

## Pedido 1 — desenho base

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE character design sheet for "Tico and Teco, the Juggling Brothers", a boss of a 2D Godot game about a haunted 1930s circus. Save it INSIDE the project at exactly: docs/referencias/pecas/malabaristas/malabaristas_folha.png (create the folder). Canvas exactly 2048 x 1024, fully TRANSPARENT background (real alpha), no text, no grid, no shadows.

References (read from the project): docs/referencias/chefao_malabaristas.png (the concept for these two), and docs/referencias/pecas/palhaco_folha.png + docs/referencias/pecas/acrobata_folha.png for the ART STYLE to match exactly: hand-inked 1930s rubber-hose cartoon (Cuphead-like), thick dark brown outline #1b1410, warm painted shading, slightly worn print texture.

Personality: identical twin jugglers who never stop juggling, cocky and playful, always showing off to the audience. Short and stocky, round heads, big curly mustaches, slicked black hair, striped one-piece circus leotards and white gloves. Tico wears RED and cream stripes, Teco wears BLUE and cream stripes; otherwise identical.

Layout, side view, both facing RIGHT: left half Tico full body standing and juggling three balls; right half Teco full body standing and juggling three clubs. Below each, three heads: grinning, shouting while throwing, dizzy (eyes spinning, stars around).
```

## Pedido 2 — animações (só depois de aprovar o Pedido 1)

**Atualização de 03/10, à noite:** o Pedido 1 foi aprovado tecnicamente (folha normalizada em
`malabaristas_folha.png`). Este Pedido 2 não vai mais inteiro: cada folha vira um pedido próprio na fila
(`fila_animacoes_codex.md`, a começar pelo Pedido E2), com medidas, sem objetos nas mãos e sem trilhas. O
texto abaixo fica como histórico.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Using docs/referencias/pecas/malabaristas/malabaristas_folha.png as the EXACT character reference (same design, colors, proportions, ink style), create these animation sheets. Draw TICO (red stripes) only; the game recolors him into Teco. Save each INSIDE the project at the exact path, replacing if it exists.

Rules for every sheet:
- Cells of 512 x 512, one frame per cell, read left to right, top row first. Side view facing RIGHT.
- Feet on the SAME ground line, 26 px above the bottom of each cell, body centered around x = 256 (in the air frames, keep the belly at x = 256, y = 300).
- Nothing crosses into another cell. Fully TRANSPARENT background, no grid, no text, no shadows.
- FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose expression in EVERY frame.

1. docs/referencias/pecas/malabaristas/tico_malabares.png — 2048 x 1024 (4 x 2), IDLE JUGGLING loop, 8 frames: hands alternating up and down, three balls cycling in the air above the hands, body bouncing on the knees; faces: smug grin, wink, tongue out concentrating, proud smile, eyebrows wiggling, whistling, laughing, cocky smirk.
2. docs/referencias/pecas/malabaristas/tico_arremesso.png — 2048 x 512 (4 x 1), THROW, 4 frames: arm back winding up (focused squint), arm whipping forward (shouting "hup!"), follow-through (delighted), back to ready (smirk).
3. docs/referencias/pecas/malabaristas/tico_salto.png — 2048 x 1024 (4 x 2), FORWARD SOMERSAULT drawn frame by frame (one full 360 turn, never the same drawing rotated), 8 frames: crouch, take-off, tuck 90, upside-down 180, tuck 270, opening, landing, ta-da pose; laughing and showing off.
4. docs/referencias/pecas/malabaristas/tico_tonto.png — 2048 x 512 (4 x 1), DIZZY loop, 4 frames: wobbling on wobbly legs, eyes spinning, tongue out, little stars and birds circling the head.
5. docs/referencias/pecas/malabaristas/tico_derrota.png — 2048 x 512 (4 x 1), DEFEAT, 4 frames: last desperate juggle (worried), losing balance (panic), falling backwards (scream), lying on the floor knocked out (X eyes, balls bouncing off his head).
```
