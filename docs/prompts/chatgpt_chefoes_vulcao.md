# Pedido ao ChatGPT (imagens): os quatro chefões da Área 2, o Vulcão

Escrito em 07/10/2026, a pedido do usuário: um pedido grande, de uma vez, com **todos os chefões da Área 2**
(Rei Magma, Fênix das Cinzas, Mestre Bigorna e Coração do Vulcão): ficha de cada um, todas as animações,
ataques e efeitos, e as arenas (com um fundo diferente para a fase final de cada luta). O design de cada luta
está em [bosses.md](../bosses.md) (seção "Área 2"). A Mina de Brasa (fase de plataforma) fica para depois.

**Como usar:** colar o bloco inteiro abaixo de uma vez. O ChatGPT tem acesso ao projeto e salva as imagens
direto nos caminhos pedidos. O pedido manda fazer tudo sem parar e só chamar no fim. Se mesmo assim ele
parar no meio (limite de imagens do ChatGPT), responder só **"continue"**: ele
retoma do próximo arquivo que falta, pela lista do relatório. No fim, mostrar ao Claude, que confere grade,
linha do chão e tamanhos, normaliza o que precisar (`tools/normalize_sheet.gd`) e liga no jogo.

```
IMPORTANT: Only create image files and ONE Markdown report at the exact paths below. Do not modify, move or delete any other file of the project. Do not run any git command. Generate the files ONE AT A TIME, in the order listed. Before starting, read every reference listed in STYLE.
WORK UNTIL EVERYTHING IS DONE: make ALL the files of ALL four bosses (every model sheet, every animation, every effect and every arena) without stopping to show partial results, ask for approval or ask questions. Do not end your answer until the last file and the report are finished. Only talk to me when EVERYTHING is done, with a short summary. Only if a hard limit really stops you (image limit or time), first update the report with what is done and what is missing; when I say "continue", resume from the first missing file, keeping each boss IDENTICAL to its own model sheet.

=== CONTEXT ===
"Respeitável Público" is a 2D side-view co-op run-and-gun boss-fight game about a haunted 1930s circus troupe (a clown and an acrobat). After the circus (area 1), the circus train takes them to a VOLCANIC ISLAND (area 2). Look at the island map: docs/referencias/mapas/area2_vulcao/mapa_completo.png. On the island the cursed "Fire Festival" repeats forever, and each boss is one of its attractions, a performer of the festival, theatrical and full of personality. These are FOUR bosses, each fought in its own arena:
  1. REI MAGMA (the Magma King) — short, very wide king made of cracked BLACK BASALT with glowing orange lava in the cracks; a broken crown of sharp OBSIDIAN shards; a royal cape of slowly dripping lava; huge underbite jaw, tiny vain eyes, stubby arms with rings, a short stone scepter with a lava orb. He was the festival's FIRE-EATER and is extremely vain: he demands bows. Phase 3: his crust cracks off and he becomes a taller, thinner king of PURE MAGMA, the crown floating around his head.
  2. FÊNIX DAS CINZAS (the Ash Phoenix) — a huge bird of gray SMOKE and EMBERS, with very long tail and wing feathers like burning circus RIBBONS, and a cracked white PORCELAIN carnival MASK on its face (with a beak shape). It was the festival's aerial act: dramatic, always posing. Phase 3: it closes itself into a giant glowing EGG.
  3. MESTRE BIGORNA (Master Anvil) — a giant BLACKSMITH with enormous arms, tiny short legs, a handlebar mustache with curled tips, bushy eyebrows, a scorched leather apron, iron bracelets and a hammer as big as a barrel. He did the "forge a sword in 10 seconds" act; impatient, smoke puffs out of his ears when angry. Phase 3: he wears a giant suit of armor that is still RED-HOT from the forge, with a grille on the chest that opens to show the glowing core.
  4. CORAÇÃO DO VULCÃO (the Heart of the Volcano) — the final boss of the area: an enormous beating heart of MAGMA, wrapped in cooled black crust with glowing veins, chained to the crater, with a stone THEATER MASK grown on its front (that mask is its face: eyes and mouth move). The three other bosses were its seals.

=== STYLE ===
Exactly the art already in the game. Read and match these files: docs/referencias/pecas/leao/leao_folha.png, docs/referencias/pecas/domador/domador_folha.png, docs/referencias/pecas/malabaristas/ (the sheets), docs/referencias/pecas/magico/ (the sheets), docs/referencias/pecas/trem/desafiantes/ (the train challengers), docs/referencias/pecas/palhaco_folha.png and docs/referencias/pecas/acrobata_folha.png (the players, for scale and style). Hand-inked 1930s cartoon look, thick dark brown outline (#1b1410), warm painted shading, slightly worn print texture. ORIGINAL characters: do not copy any existing game or cartoon character.
Palette of the island: obsidian black, dark purple-brown rock, ash gray, deep wine red, brass gold, glowing ember orange. The bosses must stand out from their arena: strong silhouettes, light-to-dark contrast, never the same orange as the background lava.

=== READABILITY RULES (very important) ===
- BACKGROUNDS are dark and muted: their lava is a dim, desaturated red-orange, never bright, so the attacks stay readable on top.
- Boss ATTACKS (fireballs, waves, sparks, feathers, horseshoes...) have a pale YELLOW-WHITE hot core, an orange or MAGENTA rim, and a thick dark outline. They are the brightest thing on screen.
- PARRY objects (the player can slap them) are TURQUOISE #2EE6D6 with a light rim and a tiny white four-pointed star sparkle. Turquoise is used ONLY for parry objects, nowhere else.
- Every attack has a clear WARNING pose or mark before it (described below).

=== ANIMATION RULES ===
Every frame is a real, different drawing (anticipation, action, follow-through), never the same drawing slid or rotated. A DIFFERENT exaggerated facial expression in every frame (written in parentheses). Same character, same proportions, same colors in every sheet: always use the boss's own model sheet (file 1 of each boss) as the reference.

=== FORMAT ===
- PNG. Character and effect sheets have a fully TRANSPARENT background (real alpha 0 outside the drawing, no faint pixels, no glow bleeding outside). Arena backgrounds are NOT transparent (said in each file).
- Exact canvas sizes. Grids are invisible: no grid lines, no text, no numbers, no shadows on the ground. Every drawing stays inside its own cell with at least 24 px of empty margin. Cells are read left to right, top row first.
- Boss sheets use cells of 1024 x 1024. The boss faces LEFT (the players come from the left). The boss's lowest point (feet, base, bottom of the body) touches a baseline at y = 980 of the cell, centered at x = 512, unless the file says "in the air" (then centered in the cell). Keep the SAME size of the boss in every cell of every sheet: the boss fills about 80% of the cell height in its standing pose.
- Effect sheets use the cell size given in each file, each effect centered in its cell.
- Scale reference: in the game a player is about 130 px tall and the boss about 600 to 750 px tall. The screen is 1920 x 1080 and the floor top is at y = 1000.
- If the tool cannot make an exact canvas size, keep the same grid with the same cell proportions, scale EVERYTHING by the same factor and write the real size in the report.

=== ARENA RULES ===
Each arena background is 1920 x 1080, NOT transparent, side view (like a theater stage seen from the audience). The walkable floor is painted along the bottom with its TOP EDGE exactly flat and horizontal at y = 1000. The middle of the picture (x 200 to 1720, y 150 to 1000) stays calm and dark: the fight happens there. No characters, no boss, no text. Platforms and moving pieces are separate transparent files.

==================================================================
BOSS 1 — REI MAGMA. Folder: docs/referencias/pecas/vulcao/rei_magma/ (create it)
==================================================================
1. rei_folha.png — 2048 x 1024, 2 cells: (1) the king in his basalt crust, full body standing, scepter in hand (smug); (2) the phase 3 PURE MAGMA king, taller and thinner, the crown floating above his head (furious grin).
2. rei_trono_parado.png — 4096 x 1024, 4 x 1: SITTING (the throne is NOT drawn: he sits in the air at the height of a seat, his bottom at y = 700, feet at the baseline), idle loop: chin up admiring his rings (vain), tapping his fingers (bored), yawning (lava glowing inside the mouth), pointing at the players (demanding a bow).
3. rei_trono.png — 1024 x 1024, 1 cell: the empty THRONE alone, a huge cracked basalt throne with obsidian spikes and a worn red cushion, base on the baseline; the seat top at y = 700.
4. rei_cuspe.png — 4096 x 1024, 4 x 1, sitting: grabs a torch and swallows it (greedy); cheeks swollen and glowing, eyes watering (WARNING pose); spitting fire forward, mouth wide (fierce); wiping the mouth with the cape (smug).
5. rei_cetro.png — 4096 x 1024, 4 x 1, sitting: raises the scepter high (pompous, WARNING pose); slams it on the ground (furious); holds it down while the ground shakes (commanding); lifts it back (satisfied).
6. rei_coroa.png — 4096 x 1024, 4 x 1, sitting: takes off the crown (sly); throws it like a boomerang (grunting); waiting with his BALD cracked head, covering it with one hand (embarrassed); catches the crown back on his head (relieved).
7. rei_lago.png — 4096 x 2048, 4 x 2: PHASE 2, standing in the lava lake, the lava up to his WAIST (draw only the upper body; the lava surface is a flat line at y = 980, draw a few lava ripples around his waist on that line). Row 1 wading loop: 4 frames (proud, huffing, glaring, chin up). Row 2: leaning back with both arms up (WARNING, inhaling); pushing a wave forward with both arms (roaring); beating his chest (outraged); grabbing at the empty air for his lost crown (desperate).
8. rei_mao.png — 2048 x 1024, 2 cells: his big basalt hand with rings, separate, crawling to grab the crown: (1) open, fingers spread; (2) closed fist. Seen from the side, pointing LEFT.
9. rei_derretido.png — 4096 x 2048, 4 x 2: PHASE 3. Row 1: crust cracking all over (shocked); crust falling off in pieces (screaming); pure magma idle 1 (manic grin); idle 2 (cackling). Row 2: mouth glowing, charging the jet (WARNING, cheeks bright); breathing a long horizontal jet (fierce, the jet NOT drawn, only the mouth); sending the crown into orbit with a finger twirl (show-off); hit (wincing, magma splashing).
10. rei_derrota.png — 4096 x 1024, 4 x 1: cooling down, dark crust spreading (dizzy); half stone (sad); fully a stone statue making a deep BOW to the players (humbled, finally bowing); the statue cracked, a little smoke puff (resigned).
11. rei_efeitos.png — 2048 x 1024, cells of 256 x 256 (8 x 4): row 1: lava ball flying (4 frames, about 90 px, hot core); row 2: lava puddle on the floor (4 frames: splash, flat, bubbling, fading; flat, about 180 px wide, bottom at y = 240 of the cell); row 3: the crown spinning as a boomerang (4 rotation frames, about 200 px wide); row 4: frames 1-2 the turquoise obsidian GEM that falls from the crown (parry, about 70 px), frames 3-4 a lava drop falling from the ceiling (about 60 px), frame 5 the same drop in TURQUOISE (parry), frames 6-8 a drop splash.
12. coluna_basalto.png — 1024 x 512, 4 x 1 cells of 256 x 512: a basalt column bursting up from the floor: (1) a glowing crack on the floor only (WARNING); (2) half up, rubble flying; (3) fully up, about 380 px tall, hexagonal basalt with glowing seams; (4) crumbling down. Base on y = 500 of the cell.
13. onda_lava.png — 2048 x 512, 4 x 1 cells of 512 x 512: the lava wave that sweeps the floor: (1) rising; (2) a tall curling wave about 300 px tall; (3) crashing forward; (4) flattening. Base on y = 500; it moves to the LEFT.
14. jato_magma.png — 2048 x 256, 2 x 1 cells of 1024 x 256: the horizontal magma jet from his mouth, going LEFT, about 900 px long and 110 px thick, 2 flickering frames, starting at the right edge of the cell.

ARENA (folder docs/referencias/pecas/vulcao/arenas/):
15. arena_rei.png — 1920 x 1080, NOT transparent: a huge underground lava cave; the throne room of the festival: hanging stone stalactites, old torn festival banners in wine red and brass gold, dim lava lake in the back; the floor is a flat dark basalt SHORE whose top edge is at y = 1000.
16. arena_rei_fase3.png — the SAME picture (same composition, same camera) but in phase 3: the lava lake has risen and glows more, the banners are burning, embers in the air, the cave is redder. Keep the floor top at y = 1000.
17. jangada_basalto.png — 512 x 256, transparent: a floating raft of basalt (a platform for the players), about 340 px wide and 60 px thick, flat walkable top at y = 110, with a ring of lava ripples under it.

==================================================================
BOSS 2 — FÊNIX DAS CINZAS. Folder: docs/referencias/pecas/vulcao/fenix/
==================================================================
1. fenix_folha.png — 2048 x 1024, 2 cells: (1) the phoenix flying, wings open, ribbons trailing (proud, in the air); (2) the giant ember EGG of phase 3 alone, with a bright crack on its LEFT side and another on its RIGHT side (the egg sits on the baseline).
2. fenix_voo.png — 4096 x 2048, 4 x 2, IN THE AIR (centered): row 1 flying loop, 4 wing beats (haughty, singing, preening, glaring); row 2: pulling back with wings folded (WARNING before the dive, eyes narrowed); diving straight forward to the LEFT like an arrow, body horizontal (screeching); shaking off embers after the dive (smug); hit, feathers flying (outraged).
3. fenix_asas.png — 4096 x 1024, 4 x 1, IN THE AIR: big wing flap: wings high (WARNING, dramatic), wings coming down throwing a fan of feathers (theatrical), wings forward blowing wind (cheeks of the mask puffed), recovering (pleased).
4. fenix_ninho.png — 4096 x 2048, 4 x 2, PHASE 2, perched (feet on the baseline): row 1 idle on the nest rim, 4 frames (posing, bowing to an invisible audience, fanning itself with a wing, sneering); row 2: throat swelling (WARNING); spitting an egg (gagging); laughing with the mask tilted (cackling); ash cloud bursting from its feathers (furious).
5. fenix_ovo.png — 4096 x 2048, 4 x 2, PHASE 3, the EGG on the baseline: row 1: the phoenix wrapping itself in its wings and turning into the egg (2 frames, desperate then sealed); the egg idle, glowing (2 frames, pulsing small and big). Row 2: the egg pulsing hard before a ring of fire (WARNING, bright); left crack broken open (the egg tilts); right crack broken open (tilts the other way); the egg healing a crack, the crack glowing warm white, never turquoise (mending).
6. fenix_derrota.png — 4096 x 1024, 4 x 1: the egg cracking all over (trembling); the egg bursting into ash; a tiny gray chick sitting in the ashes (dazed, the porcelain mask too big on its face); the chick sneezing a small ash cloud and running away to the RIGHT (embarrassed).
7. fenix_efeitos.png — 2048 x 1024, cells of 256 x 256 (8 x 4): row 1: burning feather falling and spinning (4 frames, about 150 px long) + the same feather in TURQUOISE (parry, 4 frames); row 2: ember EGG falling (2 frames), the egg cracking open (2 frames), the same egg in TURQUOISE (parry, 2 frames), egg landing splash (2 frames); row 3: an ember CHICK running LEFT (4 frames, about 80 px tall, feet at y = 240) + chick hit/poof (2 frames) + 2 frames of an ember spark falling (about 40 px); row 4: the trail of embers that marks the dive height (4 frames, a horizontal dashed line of embers about 240 px long, appearing and fading).
8. anel_fogo.png — 2048 x 256, 4 x 1 cells of 512 x 256: a ring of fire running along the floor (seen from the side: a low flat arch of flame, about 400 px wide and 90 px tall), 4 frames; base at y = 250.
9. ventania.png — 2048 x 512, 4 x 1 cells of 512 x 512: the wind of the wing flap seen from the side, curling gusts with ash and embers going LEFT, 4 frames (not dangerous: pale gray and white, not yellow).

ARENA:
10. arena_fenix.png — 1920 x 1080, NOT transparent: the top of the volcanic peak at dusk, a dark purple sky with ash clouds, the island far below in the distance; the floor is the rim of a giant NEST of charred branches, bones and old circus ribbons, its top edge flat at y = 1000.
11. arena_fenix_fase2.png — the SAME picture during the ASH STORM: sky almost black-gray, ash falling in streaks, the far island hidden; the floor still readable.
12. arena_fenix_fase3.png — the SAME picture, phase 3: the nest is burning softly at the edges, a warm glow from the center of the nest, embers rising.
13. rocha_flutuante.png — 1536 x 256, 3 x 1 cells of 512 x 256, transparent: three floating rocks (platforms), 260, 320 and 380 px wide, flat walkable tops at y = 100, with little hanging roots and a few glowing embers.

==================================================================
BOSS 3 — MESTRE BIGORNA. Folder: docs/referencias/pecas/vulcao/bigorna/
==================================================================
1. bigorna_folha.png — 2048 x 1024, 2 cells: (1) the blacksmith standing, hammer on his shoulder (impatient frown, smoke from the ears); (2) the phase 3 RED-HOT ARMOR worn by him, giant and heavy, chest grille closed (menacing).
2. bigorna_anvil.png — 1024 x 1024, 1 cell: the ANVIL alone (a huge black iron anvil on a stone block, about 520 px wide, its flat top at y = 640), base on the baseline.
3. bigorna_parado.png — 4096 x 1024, 4 x 1, standing BEHIND where the anvil will be (his lower body is hidden by the anvil in the game, but draw him whole): idle loop: tapping the hammer in his palm (impatient), checking a pocket watch (annoyed), smoke puffing from the ears (fuming), twirling his mustache (proud).
4. bigorna_martelada.png — 4096 x 1024, 4 x 1: hammer raised very high over his head (WARNING, teeth clenched); hammer coming down (yelling); hammer hitting the anvil, sparks (eyes squeezed shut, effort); lifting it back (satisfied grunt).
5. bigorna_arremesso.png — 4096 x 1024, 4 x 1: picking red-hot horseshoes with tongs (focused); winding up (squinting); throwing them forward underhand (grinning); follow-through (cocky).
6. bigorna_fole.png — 4096 x 1024, 4 x 1: grabbing the handle of a big leather BELLOWS (the bellows is drawn and points LEFT; WARNING, chest inflated); squeezing the bellows (cheeks puffed); full blast (eyes wide, mustache flying); releasing (wheezing).
7. bigorna_andando.png — 4096 x 2048, 4 x 2, PHASE 2 walking around the arena with the hammer: row 1 walk loop, 4 frames, heavy steps (grumpy, huffing, snarling, grumbling). Row 2: throwing a small anvil high (straining); the free hand GRABBING forward, open and huge (WARNING, greedy); holding a player up in the fist (the player NOT drawn, just the closed fist raised; gloating); the fist shaken open by pain (yowling, letting go).
8. bigorna_armadura.png — 4096 x 2048, 4 x 2, PHASE 3 in the red-hot armor: row 1: putting on the helmet (determined); walking loop 2 frames (menacing, stomping); spinning the hammer around his body (dizzy-fierce, motion lines). Row 2: crouching before a jump (WARNING); landing hard, ground cracks (roaring); raising the hammer with the chest GRILLE OPEN showing the glowing core (WARNING / weak spot, furious); hit on the open chest (shocked).
9. bigorna_derrota.png — 4096 x 1024, 4 x 1: the armor shaking apart (alarmed); pieces flying off (flailing); standing in red-and-white striped long johns, covering himself with the apron (mortified, blushing); sitting down sulking with the hammer (pouting, smoke from the ears now just a tiny puff).
10. bigorna_efeitos.png — 2048 x 1024, cells of 256 x 256 (8 x 4): row 1: red-hot HORSESHOE bouncing (4 rotation frames, about 110 px) + the same horseshoe in TURQUOISE (parry, 4 frames); row 2: SMALL ANVIL falling and spinning (4 frames, about 150 px) + small anvil landing (2 frames) + its ground shadow WARNING mark (2 frames, a dark oval with a red outline); row 3: spark burst from the hammer blow (4 frames) + ember fan blown by the bellows (4 frames, flying LEFT); row 4: rocks falling from the ceiling (2 frames), rock shadow mark (1 frame), dust puff (2 frames), steam cloud (3 frames).
11. onda_choque.png — 2048 x 256, 4 x 1 cells of 512 x 256: the shockwave of the hammer blow running along the floor: a low wave of cracked ground and sparks, about 120 px tall, 4 frames; base at y = 250.
12. canal_derretido.png — 2048 x 512, 1 x 2 cells of 2048 x 256: (1) a floor channel of molten metal, empty and dark with a faint glow (the WARNING state), 640 px wide and centered; (2) the same channel FULL of bright molten metal, bubbling, small flames on top (danger state). The channel top surface on y = 120.

ARENA:
13. arena_bigorna.png — 1920 x 1080, NOT transparent: inside the giant forge carved in the mountain: stone walls, racks of tools, a huge furnace mouth glowing dimly in the back, chains, old festival posters of "the forge in 10 seconds" act (no readable text, only drawings), the floor of iron plates and stone, top edge flat at y = 1000.
14. arena_bigorna_fase3.png — the SAME picture, phase 3: the furnace roaring, everything lit red, sparks in the air, cracks glowing in the walls.
15. corrente_plataforma.png — 1024 x 1024, 2 x 1 cells of 512 x 1024, transparent: two hanging platforms: an iron plate (about 280 px wide, 40 px thick, flat top at y = 900) hanging from two heavy chains that go straight up to the top edge.

==================================================================
BOSS 4 — CORAÇÃO DO VULCÃO. Folder: docs/referencias/pecas/vulcao/coracao/
==================================================================
1. coracao_folha.png — 2048 x 1024, 2 cells, IN THE AIR: (1) the heart chained, the stone mask calm and sinister, four thick chains going out of the cell; (2) the heart FREE in phase 3, chains broken and dangling, the mask furious.
2. coracao_batida.png — 4096 x 1024, 4 x 1, IN THE AIR, chains included: the heartbeat: (1) relaxed, mask eyes half closed (sinister); (2) contracting small, the mask's eyes flashing white (WARNING); (3) pumping BIG, veins blazing, mask mouth open (roaring); (4) back to normal (breathing out smoke).
3. coracao_mascara.png — 4096 x 1024, 4 x 1, IN THE AIR: close-ups of the MASK alone (no heart), same size and place in each cell, so the game can swap expressions: calm (sinister smile), laughing (mouth wide), angry (hit), mask cracked OPEN in the middle showing the glowing magma behind (weak spot, horrified).
4. coracao_ecos.png — 4096 x 1024, 4 x 1, IN THE AIR: the heart calling the echoes of the three seals: the three glowing seals appear around it (concentrating); a ghost-fire CROWN echo comes out (cruel smile); a ghost-fire FEATHER echo (cruel laugh); a ghost-fire HORSESHOE echo (mocking).
5. coracao_livre.png — 4096 x 2048, 4 x 2, IN THE AIR, PHASE 3: row 1: chains snapping (shock-joy); flying loop 2 frames (wild, wobbling, chains dangling); spitting magma (gagging-cackling). Row 2: pulling back, mask squinting (WARNING before the charge); charging forward to the LEFT, stretched with speed (screaming); hit (cringing); dizzy after hitting a wall (stars of embers).
6. coracao_derrota.png — 4096 x 1024, 4 x 1: cooling, veins going dark (fearful); turning to stone (fading eyes); a big stone heart falling (closed eyes, peaceful); splash in the lava, only the tip of the stone mask visible (smiling, at peace).
7. coracao_efeitos.png — 2048 x 1024, cells of 256 x 256 (8 x 4): row 1: magma ball (4 frames, about 100 px) + TURQUOISE magma drop (parry, 4 frames); row 2: ECHO projectiles in ghost-fire (pale violet core with a magenta rim, never blue or turquoise): crown (2 frames), feather (2 frames), horseshoe (2 frames), echo spawn puff (2 frames); row 3: a ceiling ARTERY swelling and glowing (4 frames: normal, swelling = WARNING, bulging, spurting) seen from below, about 200 px wide; row 4: a vertical lava JET falling from the artery (4 frames, cell is 256 x 256 but the jet can be tiled vertically: make the top and bottom edges match).
8. anel_choque.png — 2048 x 256, 4 x 1 cells of 512 x 256: the heartbeat shockwave ring running along the floor (a low glowing ring of energy and ash, about 100 px tall), 4 frames; base at y = 250.
9. valvula.png — 1024 x 512, 2 x 1 cells of 512 x 512: a big brass PRESSURE VALVE on the floor (a wide round plate with a gauge, about 220 px wide, its top flat at y = 470): (1) released, gauge at zero; (2) pressed down, gauge at max, steam puffing.
10. selos.png — 1536 x 512, 3 x 1 cells of 512 x 512: the three SEALS of the volcano door, round stone medallions glowing ember orange: a crown, a feather, a hammer-on-anvil. About 300 px wide each.

ARENA:
11. arena_coracao.png — 1920 x 1080, NOT transparent: the bottom of the main crater: a vast round chamber, the sealed giant STONE DOOR with three empty seal sockets in the far back, chains coming down from the darkness above (the heart itself is NOT drawn), the floor of black basalt plates, top edge flat at y = 1000.
12. arena_coracao_fase3.png — the SAME place erupting: the lava has flooded the floor (the bottom 180 px are a bright churning lava sea, the floor top line is gone), smoke columns, broken chains, red sky through a crack in the ceiling.
13. plataforma_erupcao.png — 1536 x 256, 3 x 1 cells of 512 x 256, transparent: floating basalt platforms of phase 3 (300, 340 and 380 px wide, flat tops at y = 100), glowing lava dripping from their undersides.

==================================================================
REPORT
==================================================================
Write docs/referencias/pecas/vulcao/entrega.md in Brazilian Portuguese: a checklist with every file above (done / missing), the real canvas size of each file, and anything that differs from what was asked. Update it after each boss.
```

## Depois

Mostrar o resultado ao Claude, um chefão por vez se preferir. Ele confere grade, linha do chão e escala,
normaliza o que precisar e monta cada luta (`bosses/rei_magma/`, `bosses/fenix/`, `bosses/bigorna/`,
`bosses/coracao/`) com desenhos provisórios por código até a arte chegar, sem um chefão depender do outro.
