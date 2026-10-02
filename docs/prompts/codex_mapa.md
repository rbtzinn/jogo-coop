# Pedido ao Codex: mapa do parque (Área 1, "O Grande Picadeiro")

Hoje o mapa é desenhado por código (céu, roda-gigante, tendas listradas). Este pedido traz a
arte de verdade. Mandar quando o usuário quiser; o Claude encaixa depois (cada tenda é uma peça
separada, a cena continua igual).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create art for the world map of a 2D Godot game about a haunted 1930s circus (Cuphead-like, hand-inked rubber-hose style, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture). References: docs/referencias/direcao_arena.png and docs/referencias/loja_barraca_camarim.png for the style and palette. Save INSIDE the project at the exact paths (create the folder docs/referencias/pecas/mapa/).

1. docs/referencias/pecas/mapa/mapa_fundo.png — canvas 1920 x 1080, NO transparency: the circus park at night seen from the side. Dark purple night sky with stars and a moon top right, a big ferris wheel and distant tent silhouettes in the middle distance (dark, desaturated), a wavy string of glowing bulbs crossing the upper third, and a dirt ground strip at the bottom: the ground line must be exactly at y = 1000 (the bottom 80 px are ground). Leave the lower middle area clear (no big objects in front between y = 600 and y = 1000), because the tents and the characters stand there.

2. Five separate tents, each its own file, canvas 400 x 440, fully TRANSPARENT background, the tent standing on the bottom edge (its base touches y = 440), centered horizontally, front view, an open curtain door in the middle (about 110 px wide, 150 px tall) and an EMPTY wooden sign above the door (the game writes the name on it):
   - docs/referencias/pecas/mapa/tenda_domador.png — red and cream stripes, a whip and a lion paw print painted on the canvas.
   - docs/referencias/pecas/mapa/tenda_malabaristas.png — blue and cream stripes, juggling clubs and balls painted on it.
   - docs/referencias/pecas/mapa/tenda_trem.png — not a tent: a small wooden circus TRAIN STATION booth with a little clock and rails at the base, green and cream.
   - docs/referencias/pecas/mapa/tenda_magico.png — purple and black stripes, a top hat and playing cards on it, a little spooky glow from the door.
   - docs/referencias/pecas/mapa/barraca_curiosidades.png — a small "cabinet of curiosities" booth, gold and brown, jars and a creepy ventriloquist dummy peeking from the window.
```
