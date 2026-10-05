# Pedidos ao Codex: O Grande Mágico Zaratan

Hoje o mágico (pequeno e gigante), as caixas e os objetos são desenhados por código
(provisório). Mandar o **Pedido 1** primeiro e mostrar ao Claude; depois o **Pedido 2**.

## Pedido 1 — desenho base

**Atualização de 04/10:** este pedido foi substituído pelo **Pedido M1** em `fila_animacoes_codex.md`
(com as medidas do jogo, a cartola do gigante separada e o arquivo candidato `magico_folha_candidata.png`),
e o Pedido 2 virou o lote M2–M8 da fila. O texto abaixo fica como histórico.

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create ONE character design sheet for "The Great Zaratan", the magician boss that closes the first area of a 2D Godot game about a haunted 1930s circus. Save it INSIDE the project at exactly: docs/referencias/pecas/magico/magico_folha.png (create the folder). Canvas exactly 2048 x 1024, fully TRANSPARENT background, no text, no grid, no shadows.

References (read from the project): docs/referencias/chefao_magico.png (the concept), docs/referencias/pecas/palhaco_folha.png and docs/referencias/pecas/acrobata_folha.png for the ART STYLE to match exactly: hand-inked 1930s rubber-hose cartoon (Cuphead-like), thick dark brown outline #1b1410, warm painted shading, slightly worn print texture.

Personality: tall, thin, elegant and theatrical stage magician who secretly knows the circus is cursed. Black tailcoat, purple cape with red lining, tall top hat with a red band, thin curled mustache and a pointy goatee, white gloves, a wand with a golden star tip.

Layout: left half, full body standing pose facing LEFT holding the wand; right half, the GIANT version for the final phase: only a huge head with the top hat and a big curled mustache, plus two enormous white gloved hands (one open, one closed in a fist), as if coming out of the darkness.
```

## Pedido 2 — animações (só depois de aprovar o Pedido 1)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Using docs/referencias/pecas/magico/magico_folha.png as the EXACT character reference, create these sheets. Save each INSIDE the project at the exact path. Cells of 512 x 512 (giant: 1024 x 1024), one frame per cell, read left to right, top row first. Fully TRANSPARENT background, no grid, no text. Small Zaratan: side view facing LEFT, feet on the same ground line 26 px above the bottom of each cell. FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated expression in every frame.

1. docs/referencias/pecas/magico/magico_parado.png — 2048 x 512 (4 x 1): idle, cape swaying, twirling the mustache; smug, bored, sly smile, raised eyebrow.
2. docs/referencias/pecas/magico/magico_feitico.png — 2048 x 512 (4 x 1): casting: wand raised and glowing (dramatic stare), wand pointing forward (shouting "Abracadabra!"), throwing a fan of cards (grin), follow-through (wink).
3. docs/referencias/pecas/magico/magico_cartola.png — 2048 x 512 (4 x 1): taking off the top hat (mischievous), tapping it on the floor (concentrated), rabbits popping out (delighted), putting the hat back (proud).
4. docs/referencias/pecas/magico/magico_fumaca.png — 2048 x 512 (4 x 1): vanishing into a puff of purple smoke in 4 frames (smirk, eyes closed, only the hat left, only smoke).
5. docs/referencias/pecas/magico/magico_reverencia.png — 2048 x 512 (4 x 1): bowing to the audience (theatrical), scared (eyes popping when losing), falling backwards into his own top hat (screaming), only the hat left wobbling.
6. docs/referencias/pecas/magico/gigante_mao.png — 2048 x 1024 (2 x 1 cells of 1024): the giant white gloved hand OPEN palm down with fingers spread, and CLOSED in a grabbing fist; purple cuff.
7. docs/referencias/pecas/magico/gigante_rosto.png — 4096 x 1024 (4 x 1 cells of 1024): the giant head with top hat, expressions: sinister grin, laughing out loud (mouth wide open), angry (hit), dizzy (defeated).
```
