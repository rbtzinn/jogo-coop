# Pedido ao ChatGPT (imagens): novos protagonistas, com o tom do vulcão

Escrito em 06/10/2026, a pedido do usuário: o palhaço e a acrobata atuais ainda lembram os heróis do Cuphead
(ver `docs/regras_originalidade.md` e `docs/referencias/checagem_cuphead.md`). Os dois continuam sendo **um
palhaço e uma acrobata da trupe** (o jogo, os golpes e os Grandes Números dependem disso), mas com um desenho
novo, original, que já combine com a Área 2 (o vulcão, `docs/referencias/mapas/area2_vulcao/`).

Este é só o **passo 1: as fichas de personagem**, com três propostas para cada um. O usuário escolhe uma de
cada; depois vem o passo 2 (as folhas de animação: parado, corrida, pulo, dash, abaixado, dano, parry, balão,
Grande Número), num pedido separado.

```
IMPORTANT: Only create image files at the exact paths below. Do not modify, move or delete any other file of the project. Do not run any git command.

CONTEXT: "Respeitável Público" is a 2D co-op platformer with boss fights about a haunted circus troupe. The two playable heroes are a CLOWN (player 1) and an ACROBAT woman (player 2). Their current design (docs/referencias/pecas/palhaco_folha.png and acrobata_folha.png) is too close to another famous 1930s-cartoon game, so we want NEW, ORIGINAL designs for both. Read docs/regras_originalidade.md and docs/referencias/checagem_cuphead.md first. The troupe is now traveling to a VOLCANIC ISLAND (look at docs/referencias/mapas/area2_vulcao/mapa_completo.png): the new designs must feel at home there.

KEEP: they are still a clown and an acrobat of a traveling circus troupe, both hold a small circus pistol in one hand (the game draws the gun arm separately later, so draw the gun arm relaxed), they are heroes (friendly, brave, funny), and they must read clearly at small size in a side-view platformer (strong silhouettes, about 2.5 heads tall or taller, never a single round object as a head).

CHANGE (to look original):
- Do NOT imitate any existing game or cartoon character. No cup, mug or chalice heads, no straws, no pie-cut eyes (use round or oval eyes with a white highlight, or button-like eyes), no rubber-hose noodle limbs without joints (give elbows and knees), no big white cartoon gloves on both (at most one gloved hand, or fingerless circus gloves).
- Brazilian traveling circus feeling ("circo mambembe"): patched fabric, hand-sewn sequins, ribbons, brass buttons, ticket stubs, painted wood props.
- Volcano tone: a warm palette of ember orange, obsidian black, ash gray, deep wine red and brass gold, with ONE cool accent color per hero so they never blend with the lava. Costume details that hint at the island trip: heat-resistant patches, ash-dusted boots, a small charm or scarf picked up on the island. They are performers, not miners or soldiers.
- CLOWN: big personality, clumsy-brave. Ideas to explore (pick different ones in each proposal): a tall thin clown with a long coat of patches, a round strongman-clown with suspenders, a young clown with a trumpet-shaped hat. Red nose allowed, but not a white face with a black-and-white checkered outfit (that is the current design).
- ACROBAT: agile, confident, a bit cheeky. Ideas to explore: a trapeze artist with ribbons that trail when she moves, a fire-hoop acrobat with a heat-proof leotard, a tightrope walker with a balance parasol folded on her back. Not the current blue-and-gold star leotard with a black bun.

STYLE: match the painted look of the art already in the project (the bosses in docs/referencias/pecas/ and the train challengers in docs/referencias/pecas/trem/desafiantes/): hand-inked thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture, 1930s-inspired but with our own character shapes.

DELIVER, inside docs/referencias/personagens_novos/ (create it), PNG with a fully TRANSPARENT background, no text inside the images:
1. palhaco_propostas.png — 2048 x 1024, three proposals side by side (cells of about 680 x 1024), each one the full body standing in a 3/4 side view facing RIGHT, feet on the same baseline at y = 960.
2. acrobata_propostas.png — same format, three proposals for the acrobat.
3. dupla_propostas.png — 2048 x 1024, the three pairs together (clown proposal 1 with acrobat proposal 1, and so on), in the same scale, to check that they look like a team and are easy to tell apart.
4. For EACH of the six proposals, a small model sheet: palhaco_proposta_1.png ... palhaco_proposta_3.png and acrobata_proposta_1.png ... acrobata_proposta_3.png, each 2048 x 1024: front view, side view facing RIGHT, back view, and four face expressions (happy, angry, scared, hurt) in a row below. Same character, same proportions in every view.

Also write a short report in Brazilian Portuguese, docs/referencias/personagens_novos/propostas.md: for each proposal, a name suggestion, the palette (hex codes), what makes it original, and a check that it does not resemble Cuphead, Mugman or Ms. Chalice (or any other famous character).
```

## Depois
O usuário escolhe uma proposta de cada personagem (ou mistura). O Claude registra a escolha no DESIGN.md e
escreve o passo 2 (folhas de animação no formato que o jogo já usa, com a lista de quadros de cada ação), e
depois troca os personagens no jogo, no mapa e nos ícones sem mudar os números do combate.
