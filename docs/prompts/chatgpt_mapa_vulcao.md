# Pedido ao ChatGPT (imagens): mapa da Área 2, o Vulcão

Escrito em 06/10/2026, a pedido do usuário: ideia de uma Área 2 fora do circo, num vulcão. Este pedido é **só o
mapa** (2 × 2, como o da Área 1). Os chefões ficam para depois; eles entram aqui só como contexto, para o mapa
já ter as entradas certas.

```
IMPORTANT: Only create image files at the exact paths below. Do not modify, move or delete any other file of the project. Do not run any git command. Do NOT draw any boss or character now: this request is only the map.

CONTEXT: this is the second area of our 2D co-op game "Respeitável Público". After the haunted circus (area 1), the circus train carries the two heroes (a clown and an acrobat) to a volcanic island. The bosses of this area will be made later; the map only needs their ENTRANCES:
  - REI MAGMA (lava rock king): a lava lake with a huge cracked stone throne in the middle; the entrance is a cave mouth framed by a stone arch shaped like a broken crown.
  - FÊNIX DAS CINZAS (ash phoenix): a giant nest of charred branches and bones on a high rocky peak, with a big glowing ash egg in it; a winding stair carved in the rock goes up to it.
  - MESTRE BIGORNA (giant blacksmith): a forge carved into the mountain, with a big chimney, a giant anvil outside and molten metal channels glowing.
  - MINA DE BRASA (platform level, like the circus train of area 1): a mine entrance with wooden supports, rails coming out of it and a couple of mine carts.
  - CORAÇÃO DO VULCÃO (final boss, locked until the other three are beaten): the main crater at the top of the map, with a huge stone door sealed by three glowing seals.
  - Base camp of the circus caravan, where the players arrive: a small train stop with the circus train parked, a striped SHOP tent and a small DRESSING tent (backstage), with lanterns.

STYLE: same game and same look as the area 1 map, look at docs/referencias/remap_conceitos/mapa_amplo_4partes/mapa_completo.png and match it exactly: the same 3/4 top-down painted view (seen from above at about 45 degrees), the same scale for paths, buildings and entrances, hand-inked 1930s rubber-hose cartoon look with thick dark brown outlines (#1b1410), warm painted shading, slightly worn print texture. ORIGINAL design: do not imitate any existing game. Time: dusk, dark purple sky glow, everything lit by the orange-red glow of the lava. Palette: black basalt, dark purple-brown rock, ash gray, glowing orange and red lava, a few brass and circus-red accents near the camp.

WALKABLE PATHS (very important, the game reads them from the picture): all places are connected by one continuous network of paths in a SINGLE distinct color: pale warm ash-gray flagstone road with ochre dust (clearly different from the lava, the dark rocks and the grass). Paths about 3% of the image width wide, with small plazas in front of each entrance. Lava rivers are crossed only by stone bridges in the same path color. No path ends in the void. Nothing covers the paths: no trees, rocks or smoke on top of them.

COMPOSITION: one continuous island seen from above, filling the whole picture, framed by dark sea or lava at the edges. Base camp at the bottom left (the players arrive here); final crater at the top center; the other four entrances spread out so each corner of the map has one important place. Long paths between the places (the map is explored while walking). No characters, no text, no letters, no numbers, no UI, no borders, no vignette.

FORMAT: first paint the WHOLE map as ONE image, 3200 x 1800 pixels (16:9), saved as docs/referencias/mapas/area2_vulcao/mapa_completo.png (create the folders). Then cut THAT SAME image (do not repaint) into four exact parts, each 1600 x 900:
  01_noroeste.png = x 0 to 1600, y 0 to 900
  02_nordeste.png = x 1600 to 3200, y 0 to 900
  03_sudoeste.png = x 0 to 1600, y 900 to 1800
  04_sudeste.png = x 1600 to 3200, y 900 to 1800
saved in the same folder. The four parts put back together must be pixel-identical to mapa_completo.png.
```

## Depois
Mostrar o resultado ao Claude: ele confere as medidas e as emendas, gera a máscara do caminho
(`tools/blender/park_walk_mask.py`, ajustada para a cor da estrada de cinza) e monta a Área 2 como a Área 1.
