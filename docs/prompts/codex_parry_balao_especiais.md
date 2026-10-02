# Pedidos ao Codex: parry, balão e especiais dos personagens

Substitui o antigo `chatgpt_balao_parry.md`. Hoje o parry é o desenho parado girando 360° e o
balão é um círculo desenhado por código: o usuário achou feio ("um png dando 360 tá horrível").
Estes pedidos trazem cada movimento desenhado quadro a quadro, com expressão diferente em cada
quadro.

Como mandar: **um bloco por vez**, colando o bloco inteiro. Cada bloco gera as duas folhas
(palhaço e acrobata). Quando uma folha chegar, avisar o Claude para recortar e encaixar no jogo
(`tools/cut_animation_sheet.gd`; se a grade vier torta, `tools/normalize_sheet.gd`).

Ordem sugerida: Pedido 1 (parry) → Pedido 2 (balão) → Pedido 3 (especiais).

## Pedido 1 — Parry (pulo com tapa no objeto rosa)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create TWO animation sheets, one per character, for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save INSIDE the project at exactly:
- docs/referencias/pecas/palhaco_parry.png (the clown)
- docs/referencias/pecas/acrobata_parry.png (the acrobat)
Replace the files if they exist.

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png and docs/referencias/pecas/acrobata_corrida.png = EXACT character design, colors, proportions, SCALE and ink style. Each new frame must have the character at the same size as in these run sheets.
- docs/referencias/pecas/palhaco_folha.png and docs/referencias/pecas/acrobata_folha.png = face details.
- docs/referencias/combate_parry.png = what a parry looks like in this game.

Sheet rules:
- Canvas exactly 2048 x 1024, grid of 4 columns x 2 rows, cells of 512 x 512, one frame per cell, read left to right, top row first.
- Side view, facing RIGHT. The character is IDENTICAL in every frame; only the pose and the face change.
- The character is in the AIR: keep the center of the body (the belly) at the same point in every cell, about x = 256, y = 280. Nothing crosses into another cell.
- Fully TRANSPARENT background (real alpha), no grid lines, no text, no shadows, no motion blur, no speed lines.
- NO gun and NO gun arm in any frame: both hands empty, white gloves.

Animation: PARRY, 8 frames. ONE complete forward somersault (360°) drawn frame by frame (the body really turns through the frames; never the same drawing rotated), ending with a slap on a pink object:
1 jump pose, knees starting to come up, eyes locked on the target, determined squint;
2 tucking into the flip, body tilted forward 45°, cheeks puffed;
3 tuck at 90°, head down, eyes squeezed shut, teeth clenched;
4 upside-down tuck (180°), mouth open in a "whoa!", hat/bun barely holding on;
5 tuck at 270°, coming around, one eye opening with a sly smile;
6 almost upright, one hand opening for the slap, eyes popping wide with excitement;
7 the SLAP: open glove striking forward-up, body stretched, big triumphant grin, eyes sparkling, small pink sparkles (#ff5fa2) around the hand;
8 follow-through, arms out, body relaxing into a fall, cheeky wink and laugh.

FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame.
```

## Pedido 2 — Balão (quem cai vira balão com a própria cara)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create TWO animation sheets, one per character, for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save INSIDE the project at exactly:
- docs/referencias/pecas/palhaco_balao.png (the clown)
- docs/referencias/pecas/acrobata_balao.png (the acrobat)
Replace the files if they exist.

References (read from the project):
- docs/referencias/pecas/palhaco_folha.png and docs/referencias/pecas/acrobata_folha.png = the character's face, hat/flower or hair bun, colors and ink style.
- docs/referencias/combate_balao_resgate.png = how the balloon looks in this game (round pink balloon whose front IS the character's face, glowing pink outline, little knot and curly string).

The balloon: round PINK circus balloon (#ff5fa2, glossy white highlight, thick dark outline #1b1410), about 300 px wide, whose front IS the character's face (same eyes, red nose, hat with daisy for the clown / black bun with gold star for the acrobat). A small knot and a curly string hanging about 150 px below. Same balloon size in every frame (except where the animation says it stretches or pops).

Sheet rules:
- Canvas exactly 2048 x 2048, grid of 4 columns x 4 rows, cells of 512 x 512, one frame per cell, read left to right, top row first.
- The CENTER OF THE BALLOON at the same point in every cell, about x = 256, y = 210 (the string hangs below). Nothing crosses into another cell.
- Fully TRANSPARENT background (real alpha), no grid lines, no text, no shadows.

Frames (16):
- Frames 1-4, TURNING INTO A BALLOON (plays once when the character is knocked out): 1 the character's head dizzy, eyes spinning, small stars around; 2 the head starting to puff up round, cheeks bulging, surprised; 3 almost a full balloon, face stretched, eyes wide in panic, knot appearing below; 4 full balloon popping into shape with a little bounce, string appearing, embarrassed face.
- Frames 5-10, FLOATING LOOP (plays while rising, frame 10 flows back into 5): the balloon gently squashing and stretching, string swaying left and right, a different face in each frame: 5 worried, eyebrows up, looking down for help; 6 pleading puppy eyes, mouth wobbling; 7 blink (eyes closed), small sigh; 8 calling out, mouth wide open "help!"; 9 looking left and right, anxious; 10 hopeful little smile, looking down.
- Frames 11-12, BLOWN BY A GUST (when the boss attacks nearby): 11 balloon tilted and squashed to the left, string flung sideways, scared face, eyes shut; 12 same tilted to the right, cheeks puffed, holding breath.
- Frames 13-16, RESCUED BY A PARRY (plays once): 13 surprised and happy, eyes wide, big open smile, balloon starting to stretch; 14 balloon over-stretched, face laughing; 15 POP: burst of pink confetti, stars and balloon scraps, the character's happy face in the middle; 16 only a fading puff of pink confetti and gold stars (no face).

FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame.
```

## Pedido 3 — Especiais (Grande Número e dupla)

```
IMPORTANT: Only create image files. Do not modify, move or delete any other file. Do not run any git command.

Create these animation sheets for a 2D Godot game about a haunted 1930s circus (Cuphead-like). Save INSIDE the project at the exact paths (replace if they exist).

References (read from the project):
- docs/referencias/pecas/palhaco_corrida.png and docs/referencias/pecas/acrobata_corrida.png = EXACT character design, colors, proportions, SCALE and ink style. Characters must have the same size as in these run sheets.
- docs/referencias/combate_especial.png = what the special moves look like in this game.

Rules for every sheet:
- Cells of 512 x 512, one frame per cell, read left to right, top row first.
- Side view, facing RIGHT. The character is IDENTICAL in every frame; only the pose and the face change.
- Frames on the ground: feet on the SAME ground line, 26 px above the bottom of the cell, body centered around x = 256. Frames in the air: the belly at the same point, about x = 256, y = 280.
- Fully TRANSPARENT background (real alpha), no grid lines, no text, no shadows. Nothing crosses into another cell.
- FACIAL EXPRESSIONS ARE IMPORTANT: a different, exaggerated rubber-hose cartoon expression in EVERY frame.

1. docs/referencias/pecas/palhaco_torta.png — canvas 2048 x 1024 (4 x 2 cells), the clown's "PIE IN THE FACE" throw, 8 frames, NO gun (the clown holds a giant cream pie with a red cherry, as big as his head):
   1 pulls the giant pie from behind his back, sly grin;
   2 lifts the pie over his head with both hands, tongue out in concentration;
   3 leans far back, one eye closed aiming, wicked smile;
   4 THROW: arm whipping forward, pie leaving the hand, mouth open shouting;
   5 follow-through, body stretched forward, the hand now empty, delighted face;
   6 watching the pie fly, hand over his mouth, giggling;
   7 laughing, bent over, tears of laughter;
   8 standing back up, thumbs up, proud wink.

2. docs/referencias/pecas/torta.png — canvas 2048 x 1024 (4 x 2 cells), the PIE as an object (no character), seen from the side, about 300 px wide, centered in the cell:
   1-4 flying loop: the pie wobbling in the air (tilting slightly up and down), little drops of cream flying off the back;
   5-8 SPLAT: 5 the pie squashing flat against an invisible wall on its right side; 6 cream exploding outward in big blobs, cherry flying up; 7 cream dripping, pie tin bent; 8 just a few drops of cream and the cherry falling.

3. docs/referencias/pecas/acrobata_salto_mortal.png — canvas 2048 x 1024 (4 x 2 cells), the acrobat's "DEATH-DEFYING LEAP" (salto mortal), 8 frames, NO gun. Frames 2-7 together show ONE complete forward somersault (360°) drawn frame by frame (the body really turns; never the same drawing rotated):
   1 deep crouch on the ground ready to spring, fierce determined eyes;
   2 explosive take-off, body stretched diagonally up, shouting "hup!";
   3 tucking in at 90°, knees to chest, focused squint;
   4 upside-down (180°), legs stretched up in a split like a star, laughing;
   5 tuck at 270°, eyes shut tight, teeth gritted;
   6 coming upright, one leg extending forward in a flying kick, fierce grin;
   7 the KICK: leg fully extended forward, arms back, triumphant shout, small gold stars around the foot;
   8 landing on the ground in a performer's pose: one knee bent, arms raised "ta-da!", big smile.

4. docs/referencias/pecas/acrobata_chute_torta.png — canvas 2048 x 512 (4 x 1 cells), the DUO special: the acrobat jumps on top of the clown's flying pie and kicks it forward (like in combate_especial.png), 4 frames in the air, NO gun:
   1 landing with both feet on top of a giant flying pie (the pie under her feet, same pie as torta.png), arms out for balance, surprised;
   2 crouching on the pie, winding up the kick, mischievous grin;
   3 the KICK: one leg smashing the pie forward, the pie starting to leave her foot, shouting with joy;
   4 jumping off backwards, arms up, laughing, the pie gone.
```
