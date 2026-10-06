# Pedido ao ChatGPT (imagens): o avião que leva de uma área para outra

Escrito em 06/10/2026, a pedido do usuário: cada área tem um avião estacionado no mapa. Quem entra nele vê o
avião passar voando pela tela e sair do outro lado; depois aparece "Para onde vocês querem ir?", com o Circo
(Área 1) e o Vulcão (Área 2). O usuário pediu primeiro a arte e depois a lógica.

O ChatGPT tem acesso ao projeto: ele pode ler as referências e salvar as imagens direto nos caminhos abaixo.
Mandar **um pedido por vez** (E1 e depois E2). O Claude confere as medidas e liga no jogo.

Regras para os dois pedidos (colar junto):

```
IMPORTANT: Only create image files at the exact paths below. Do not modify, move or delete any other file of the project (the original maps stay untouched: save the new versions in NEW folders). Do not run any git command.

STYLE: a 2D game about a haunted 1930s circus. Hand-inked 1930s rubber-hose cartoon style (pie-cut eyes, bendy shapes), thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture. ORIGINAL design: do not imitate any existing game or cartoon. Match the art already in the project: docs/referencias/pecas/palhaco_folha.png, docs/referencias/pecas/acrobata_folha.png and docs/referencias/pecas/trem/ (the circus train).

THE PLANE (the same plane in every image): a small old 1930s circus BIPLANE with two open cockpits, one behind the other. Body painted in circus red and cream stripes, brass trims and rivets, a big wooden propeller with brass tips, two round wheels, a little tail with a cream star, and a short pennant flag on the tail. It is a living cartoon plane: a FACE on the nose under the propeller (pie-cut eyes in round goggle-like windows on the sides of the nose, a wide grinning mouth on the front of the nose). About 3 times longer than one of the heroes is tall.
```

## E1 — O avião estacionado nos dois mapas

```
Paint the parked plane INTO the two area maps. Edit only the rectangle given for each map: everything outside that rectangle must stay pixel-identical to the original (paint the plane on a copy, then paste only the rectangle back into the original image). The plane sits on the ground, seen from the same 3/4 top-down view (about 45 degrees from above) and at the same scale as the buildings of that map, same lighting as that map. Its nose points to the RIGHT. A small wooden boarding ladder with a brass rail leans on its left side, at the bottom of the rectangle, touching the road, so the players walk up to it from the road. Wheel chocks under the wheels. Do NOT cover any road: the road must stay fully visible and continuous. No characters, no text.

MAP 1 (the circus park, area 1): original docs/referencias/remap_conceitos/mapa_amplo_4partes/mapa_completo.png, 1672 x 941. Rectangle: x 770 to 1070, y 605 to 760 — the grass island with bushes in the lower middle, surrounded by the dirt road. Replace the bushes and rocks of that island with the parked plane on the grass (keep a grass border around it; the dirt road around the island stays exactly as it is). Night light, warm lamp glow, like the rest of the park.
Save the whole edited map as docs/referencias/mapas/area1_circo_aviao/mapa_completo.png (1672 x 941). Then cut THAT image into four parts (do not repaint):
  01_noroeste.png = x 0 to 836, y 0 to 470
  02_nordeste.png = x 836 to 1672, y 0 to 470
  03_sudoeste.png = x 0 to 836, y 470 to 941
  04_sudeste.png = x 836 to 1672, y 470 to 941
in the same folder.

MAP 2 (the volcanic island, area 2): original docs/referencias/mapas/area2_vulcao/mapa_completo.png, 3200 x 1800. Rectangle: x 1000 to 1300, y 930 to 1160 — the flat brown ash ground with dead trees and red crystals just right of the base camp, between the road on its left and top and the rocky cliff on its right. Replace the dead trees and crystals with a small flat landing strip of packed ash and the parked plane on it (a few brass lanterns and a red windsock on a pole next to it). Dusk light, orange-red lava glow, like the rest of the island.
Save the whole edited map as docs/referencias/mapas/area2_vulcao_aviao/mapa_completo.png (3200 x 1800). Then cut THAT image into four parts (do not repaint):
  01_noroeste.png = x 0 to 1600, y 0 to 900
  02_nordeste.png = x 1600 to 3200, y 0 to 900
  03_sudoeste.png = x 0 to 1600, y 900 to 1800
  04_sudeste.png = x 1600 to 3200, y 900 to 1800
in the same folder.

Check before finishing: each new mapa_completo.png has the exact size of its original; outside the rectangle zero pixels differ from the original; the four parts put back together are pixel-identical to the new mapa_completo.png.
```

## E2 — O avião voando (a viagem)

```
The travel scene: the plane flies across the screen from LEFT to RIGHT, seen from the SIDE, with the two heroes riding it: the clown (docs/referencias/pecas/palhaco_folha.png) in the front cockpit and the acrobat (docs/referencias/pecas/acrobata_folha.png) in the back cockpit, only their upper bodies visible. The game moves the plane across the screen; the frames give it life.

ANIMATION: every frame is a real pose, never the same drawing slid around: the propeller is in a different position (with motion blur arcs), the body tilts and bobs, the wings flex a little, the pennant and the clown's collar flap in the wind. A DIFFERENT exaggerated facial expression in EVERY frame, for the plane AND for both heroes.

FORMAT: PNG with a fully TRANSPARENT background. Exact canvas sizes. Grids are invisible: no grid lines, no text, no numbers, no ground shadows. Every drawing stays inside its own cell with at least 16 px of empty margin. The plane faces RIGHT in every frame, its body centered in the cell (center of the body at the center of the cell), about 640 px long.

1) docs/referencias/pecas/aviao/aviao_voando.png — 3072 x 1024, 4 columns x 2 rows of 768 x 512 cells, read left to right, top row first. The flying loop (frame 8 goes back to frame 1 smoothly):
  1 level flight, the plane grinning, the clown pointing forward (excited), the acrobat holding her hat (surprised);
  2 nose a little up, the plane puffing its cheeks, the clown laughing, the acrobat waving;
  3 top of the bob, the plane whistling, the clown with tongue out in the wind, the acrobat laughing;
  4 nose a little down, the plane winking, the clown holding on (scared), the acrobat cheering with both arms up;
  5 level flight, the plane singing (mouth open, eyes closed), the clown waving at the camera, the acrobat blowing a kiss;
  6 a small wobble, the plane cross-eyed for a moment, both heroes bumping into each other (comic shock);
  7 recovering, the plane embarrassed grin, the clown scolding, the acrobat giggling;
  8 level flight again, the plane proud, the clown saluting, the acrobat pointing ahead (determined).

2) docs/referencias/pecas/aviao/fumaca.png — 1024 x 256, 4 cells of 256 x 256: the little round puff of smoke the plane leaves behind (cream-gray with dark brown ink outline), 4 frames: small and dense, bigger, breaking apart, almost gone. Centered in each cell.

3) docs/referencias/pecas/aviao/ceu_viagem.png — 1920 x 1080, NOT transparent: the background of the travel scene. A wide dusk sky over a dark sea, seen from the side, with big soft painted clouds, a few birds far away, and a thin horizon line low in the picture (around y = 820). On the far left, very small on the horizon, the striped tents of the circus; on the far right, very small, the smoking volcano. Leave the middle band (y 250 to 750) calm and open: the plane flies there.

4) docs/referencias/pecas/aviao/nuvens_frente.png — 1920 x 400, transparent: a strip of loose cartoon clouds that passes in FRONT of the plane, only at the bottom half of the strip, with gaps between them. Its left and right edges must match so it can repeat side by side.
```

## Depois
O Claude confere as medidas e as emendas, troca as partes dos mapas no jogo (Área 1 e Área 2), faz a máscara de
onde se anda das duas e liga a viagem: entrada no avião, a cena do voo e a escolha do destino.
