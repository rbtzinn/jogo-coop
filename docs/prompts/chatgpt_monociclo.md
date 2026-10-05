# Pedido ao ChatGPT (imagens): os Malabaristas no Monociclo Gigante

Substitui o Pedido E8 da fila (`fila_animacoes_codex.md`), que foi escrito para o Codex. Os dois pedidos daqui
vão para o gerador de imagens do ChatGPT, o mesmo que fez as folhas do jogo.

**Por quê:** a fase 3 da luta (Monociclo Gigante) é a última parte dos Malabaristas ainda com o boneco de código.

**O que mudou na luta (05/10/2026):** a pedido do usuário, os irmãos empilhados ficaram mais altos e passam a
pegar quem está em cima das tábuas penduradas.
- O totem (fase 2) cresceu 30%.
- O selim do monociclo baixou de 380 para 330 px do chão.

Por isso os pés de quem pedala podem descer um pouco mais que no E8.

## Como mandar
1. Abrir uma conversa nova no ChatGPT e **anexar estas imagens** (ele não lê os arquivos do projeto):
   - `docs/referencias/pecas/malabaristas/totem.png` (os dois empilhados, no tamanho certo);
   - `docs/referencias/pecas/malabaristas/tico_malabares.png` e `teco_malabares.png` (cores e detalhes);
   - uma captura da luta no monociclo (a imagem do boneco de código serve).
2. Colar o **Pedido 1**.
3. Salvar o resultado em `docs/referencias/pecas/malabaristas/monociclo_candidata.png` e mostrar ao Claude.
4. Só depois, o **Pedido 2** (o monociclo em peças), salvo em
   `docs/referencias/pecas/malabaristas/monociclo_pecas_candidata.png`.

O Claude confere, recorta, normaliza na escala do totem e liga no jogo.

## Pedido 1 — os dois irmãos pedalando (8 desenhos)

```
Create ONE animation sheet (PNG with a fully TRANSPARENT background) for a 2D game about a haunted 1930s circus, in the exact art style of the attached sheets: hand-inked 1930s rubber-hose cartoon like Cuphead, thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture.

CHARACTERS: the two juggling twin brothers from the attached "totem" sheet, EXACTLY the same design, faces, colors and proportions as in that sheet. TICO wears RED and cream stripes and sits at the bottom; TECO wears BLUE and cream stripes and sits on Tico's shoulders, his legs in front of Tico's chest, Tico holding Teco's shins with one or both gloves.

THE POSE: they ride a giant unicycle, but DO NOT DRAW THE UNICYCLE (no wheel, no pole, no seat, no pedals: the game draws them). Tico sits on the invisible seat, pedaling, knees bent and lifted, feet a little below and in front of his bottom, as if pushing two short pedals.

LAYOUT: canvas 2048 x 1024, a grid of 4 columns x 2 rows of 512 x 512 cells, one drawing per cell, read left to right, top row first. Both brothers face RIGHT. In EVERY cell the point where Tico's bottom touches the invisible seat is at x = 256, y = 400. Tico's shoes never go lower than y = 460. The top of Teco's hair is around y = 40. Keep at least 24 px of empty margin around the drawing inside each cell; nothing crosses into another cell. No grid lines, no text, no ground, no shadows.

NOTHING EXTRA: no unicycle, no torches, no balls, no clubs, no props in the hands, no fire, no stars, no motion lines, no dust.

8 FRAMES, with a different, exaggerated cartoon expression on BOTH faces in every frame (Tico concentrating hard on balancing, Teco showing off to the audience):
1. Pedaling A: Tico's right knee up, left knee lower; both leaning slightly forward; Teco with both hands raised as if juggling.
2. Pedaling B: knees passing each other at the same height; bodies upright.
3. Pedaling C: Tico's left knee up, right knee lower; both leaning slightly back.
4. Pedaling D: knees passing again, a small wobble to the side.
5. Bottom brother winds up a throw: Tico keeps pedaling, one arm pulled down and back with an empty open glove; Teco holds on, worried.
6. Bottom brother throws: Tico's arm swung straight UP, open empty glove; Teco ducks.
7. Top brother winds up a throw: Teco twists back, throwing arm behind his head with an empty glove; Tico pedaling.
8. Top brother throws: Teco's arm whipped forward and up, open empty glove; Tico wobbles under him.
```

## Pedido 2 — o monociclo em peças (depois de aprovar o Pedido 1)

```
Using the SAME art style as the previous sheet (1930s rubber-hose cartoon, thick dark brown outline #1b1410, warm painted shading, slightly worn print texture), create ONE PNG with a fully TRANSPARENT background, canvas 2048 x 1024, with the parts of a giant circus unicycle, each part separate, side view, nothing touching, no text, no grid, no shadows:

LEFT HALF (a 1024 x 1024 area): the WHEEL alone, seen exactly from the side as a perfect circle, centered at (512, 512), outer diameter 900 px: a red tire with a dark outline, a cream rim, 8 straight spokes, a brass hub. The wheel must look right at ANY rotation (the game spins it), so no text and no drawing that has an obvious "up".

RIGHT HALF (a 1024 x 1024 area): the FRAME alone, vertical and centered at x = 1536: a polished silver pole with brass rings, a short fork at the bottom that ends in an axle point at y = 990 (where the wheel's hub will be), and at the top a dark red leather seat with brass studs, its top at y = 80. Next to the pole, at about y = 380, two short crank arms with small pedals (one pointing forward, one back).

Same palette as the circus brothers: muted red, cream, brass gold, dark brown ink.
```

## Situação (05/10/2026)
O Pedido 1 foi aprovado e está no jogo: a folha `monociclo_candidata_v2.png` (1774 × 887, fora da grade) foi
arrumada por `tools/normalize_rider_sheet.gd` em `monociclo.png` (células de 512, escala do totem pelo tamanho do
nariz, o nariz do de baixo sempre no mesmo ponto), a versão com o Teco embaixo saiu do `tools/recolor_twin.gd troca`
(`monociclo_teco.png`) e os quadros foram recortados para `bosses/jugglers/art/unicycle/`. Falta o Pedido 2 (o
monociclo em peças); até lá ele continua desenhado por código.

O Pedido 2 chegou (05/10/2026) e está no jogo: `monociclo_pecas_candidata.png` recortada por `tools/cut_unicycle_parts.gd` em `bosses/jugglers/art/unicycle/wheel.png` e `frame.png`.
