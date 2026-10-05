# Pedido ao Codex: Corrida no Trem do Circo

Hoje o trem, o cenário e os inimigos da fase são desenhados por código (provisório). Mandar
quando o usuário quiser; o Claude encaixa depois (cada peça separada, a fase continua igual).

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create art for a side-scrolling run-and-gun level of a 2D Godot game about a haunted 1930s circus (Cuphead-like, hand-inked rubber-hose style, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture). Reference for style and palette: docs/referencias/direcao_arena.png and docs/referencias/pecas/palhaco_folha.png. The level happens on the ROOF of a moving circus train at sunset. Save INSIDE the project at the exact paths (create the folder docs/referencias/pecas/trem/). All with fully TRANSPARENT background unless said otherwise. No text, no grid.

1. docs/referencias/pecas/trem/vagao_1.png ... vagao_4.png — four circus wagons, side view, each 800 x 300 px canvas, the flat roof exactly at the top edge (y = 0) so the characters can stand on it, wheels at the bottom edge. Colors: red, blue, mustard, green, with gold trim, painted stars and an EMPTY banner panel in the middle (the game writes the name). The wagon box fills the whole width.
2. docs/referencias/pecas/trem/locomotiva.png — 900 x 560 px canvas: an old circus steam locomotive seen from the side, facing RIGHT, black and red with gold details, big smokestack, cab at the back (left side). The roof of the low front part at y = 260 (players walk on it).
3. docs/referencias/pecas/trem/fundo_morros.png and fundo_postes.png — 1920 x 1080, NO transparency for the first one: a sunset sky with distant purple hills that tile horizontally (left and right edges must match); the second is transparent with telegraph poles and a fence on the ground, also tiling horizontally.
4. docs/referencias/pecas/trem/ponte.png — 160 x 900 px: a wooden trestle bridge seen from the side, coming down from the top of the image, with a thick beam at the bottom edge (the train passes under it).
5. Enemy sheets, 2048 x 512 (4 x 1 cells of 512), side view, frames read left to right, each with a DIFFERENT exaggerated face in every frame:
   - docs/referencias/pecas/trem/fantasma.png — a little ghost clown made of a white bedsheet with a red nose and a tiny party hat, hopping: crouch (sneaky grin), jump (gleeful "boo!"), top (tongue out), landing squash (eyes squeezed).
   - docs/referencias/pecas/trem/pombo.png — a magician's white dove flapping, 4 frames of a wing loop (smug, angry, surprised, cooing).
   - docs/referencias/pecas/trem/canhao.png — a little circus confetti cannon on wheels with a face, facing LEFT: idle (bored), charging (cheeks puffed), firing (mouth wide open, recoil), after shot (dizzy).
```
