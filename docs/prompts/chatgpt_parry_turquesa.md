# Pedido ao ChatGPT: parry de outra cor e conferência de semelhança com o Cuphead

Escrito em 06/10/2026, a pedido do usuário (ver `docs/regras_originalidade.md`). Três partes: achar tudo o que
aceita parry e hoje é rosa, repintar na cor nova (turquesa-fantasma) e conferir se algo do jogo ficou parecido
demais com o Cuphead. O ChatGPT só cria imagens e um relatório; o Claude troca a cor no código e liga as imagens.

```
IMPORTANT: Only create the files at the exact paths below (images and one Markdown report). Do not modify, move or delete any other file of the project, including code and the game's own images. Do not run any git command.

CONTEXT: our 2D co-op game "Respeitável Público" (haunted 1930s circus) is going to Steam. To avoid looking like a copy of another famous game, the objects the players can PARRY will stop being PINK. Read docs/regras_originalidade.md first. The new parry color is GHOST TURQUOISE: main #2EE6D6, light #B8FFF7, dark #138F86, always with a thin bright near-white rim glow and one small 4-point sparkle somewhere on the object, so it reads by shape too (color-blind players). Keep the same drawing, outline (#1b1410), shading and texture as the original: only the pink parts change.

PART 1 — FIND EVERYTHING PINK THAT CAN BE PARRIED.
Search the whole project (images under docs/referencias/pecas/, bosses/*/art/, components/*/art/, levels/*/art/, core/player/, and the code: look for "pink", "parryable", "PINK") and list every parryable object. Already known:
  Images (drawn art, need repainting):
  - Domador (tamer): bosses/tamer/art/effects/ember_pink_a.png, ember_pink_b.png, ring_pink_a.png, ring_pink_b.png, whip_pink_1.png to whip_pink_4.png (and their source sheets in docs/referencias/pecas/domador/).
  - Train: docs/referencias/pecas/trem/pombo_rosa.png (the pink dove), the pink cell of bola_canhao.png, the pink cell of desafiantes/novelo.png, the pink cell of desafiantes/bexiga_agua.png.
  Drawn by code (the Claude changes these, just list them): the Jugglers' pink balls, clubs and torches (bosses/jugglers/attacks/juggler_prop.gd), the Magician's pink cards, doves and other props (bosses/magician/attacks/magic_prop.gd), the downed player's balloon (core/player/balloon.gd), the parry flash (components/fx/parry_flash.gd).
Also check the players' parry sheets (docs/referencias/pecas/palhaco_parry.png, acrobata_parry.png) and any other image for pink parts that mean "parry". Pink that is only decoration (a blush, a heart in the Trapeze Artist's kiss) stays.

PART 2 — REPAINT THE IMAGES IN GHOST TURQUOISE.
For EVERY parry image found, create a repainted copy with EXACTLY the same canvas size, the same grid and the same position of every drawing (pixel-aligned, so the game can swap the files without moving anything). Save them in docs/referencias/pecas/parry_turquesa/ keeping the original file name (for sheets with only one pink cell, save the whole sheet with that cell repainted). Do not overwrite the originals.
The normal (not parryable) water balloon in desafiantes/bexiga_agua.png is blue, too close to the new color: in the same copy, repaint its normal cells (1 to 3) as a WARM YELLOW-ORANGE water balloon.

PART 3 — CHECK THE SIMILARITY WITH CUPHEAD.
Compare everything of our game with Cuphead: Don't Deal with the Devil and its DLC (bosses, enemies, the two playable characters, the train level, the map, the shop, the HUD, the fight texts like "Nocaute!", the parry and the "Grande Número" super). Look at our art in docs/referencias/ and at docs/DESIGN.md. For each item say: what in Cuphead it resembles (if anything), the risk (none / low / medium / high) of being seen as a copy, and a concrete change to make it more original. Also suggest 5 original circus-themed replacements, in Brazilian Portuguese, for the end-of-fight banner "Nocaute!" (NOT "Bravo!", Cuphead uses it).
Write the report in Brazilian Portuguese in docs/referencias/checagem_cuphead.md, with a table, starting with the list from PART 1 (every parryable object, where it is, image or code) and the list of files created in PART 2.

FORMAT: PNG with a fully transparent background (same as the originals). No text inside the images.
```

## Depois
Mostrar ao Claude o relatório e a pasta `docs/referencias/pecas/parry_turquesa/`. Ele confere se as imagens
encaixam pixel a pixel nas originais, troca a cor rosa no código (malabares, mágico, balão do jogador caído,
brilho do parry) e liga as imagens novas.
