extends SceneTree
## Recorta uma folha de animação quadro a quadro (grade de células iguais, fundo transparente)
## e gera os PNGs + um FrameAnimation (.tres) para o CharacterRig.
## Uso: Godot --headless --script res://tools/cut_animation_sheet.gd [-- folha.png ...]
##
## Alinhamento: as células da folha já vêm com o chão na mesma linha, então todos os quadros
## são recortados com o MESMO retângulo (o pulinho desenhado é preservado).
## O ombro da frente é achado a partir do nariz vermelho (ponto vermelho mais à direita na
## metade de cima da célula) mais um deslocamento medido uma vez por personagem.
## Sem "shoulder_from_nose" (ex.: o leão), não calcula ombros.

const SOURCES := "res://docs/referencias/pecas/"
## Os quadros são reduzidos para este tanto do tamanho da célula (fica ~1,7x o tamanho
## na tela: nítido e mais leve).
const TEXTURE_FACTOR := 0.75

## Uma entrada por animação.
const ANIMATIONS := [
	{
		"sheet": "palhaco_corrida.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/run/",
		"name": "run",
		# Linha do chão na célula e o x da célula que fica no centro do corpo (x = 0 no rig).
		"ground_y": 486, "center_x": 290,
		# Altura do personagem em pé, em pixels da célula, e a altura dele no rig.
		"cell_height": 406.0, "rig_height": 198.0,
		"shoulder_from_nose": Vector2(-64, 60),
	},
	# Parry no ar (sem pistola): o meio do desenho em (256, 280), mesma escala da corrida.
	{
		"sheet": "palhaco_parry.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/parry/",
		"name": "parry",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
	},
	{
		"sheet": "acrobata_parry.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/parry/",
		"name": "parry",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 268.0,
	},
	# Parado no chão: pés plantados no meio da célula (âncora "pes" do regrid), sola em 486.
	{
		"sheet": "palhaco_parado.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/idle/",
		"name": "idle",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
		"shoulder_from_nose": Vector2(-64, 60),
	},
	# Pulo no ar (A5): meio do desenho em (256, 280), escala única da folha (equivalente a 406).
	# Quadros 1-3 subindo, 4-5 no alto, 6-8 caindo; o CharacterRig escolhe pela velocidade vertical.
	{
		"sheet": "palhaco_pulo.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/jump/",
		"name": "jump",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
		"shoulder_from_nose": Vector2(-64, 60),
	},
	{
		"sheet": "acrobata_parado.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/idle/",
		"name": "idle",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 268.0,
		"shoulder_from_nose": Vector2(-45, 55),
	},
	# Balão do palhaço (A7): meio do oval em (256, 240) vira a origem do balão; o oval tem
	# 260 px de largura na folha e 132 no jogo (o mesmo do balão desenhado por código).
	{
		"sheet": "palhaco_balao_flutua.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/balloon/",
		"name": "float",
		"ground_y": 240, "center_x": 256,
		"cell_height": 260.0, "rig_height": 132.0,
	},
	# Balão da acrobata (A9): mesma origem e escala do balão do palhaço.
	{
		"sheet": "acrobata_balao_flutua.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/balloon/",
		"name": "float",
		"ground_y": 240, "center_x": 256,
		"cell_height": 260.0, "rig_height": 132.0,
	},
	# Dash do palhaço (A11): só os 4 quadros de cima; o meio do tronco em (250, 330) em todos,
	# que é também o ponto de giro quando o dash vai para cima ou na diagonal (Pirueta).
	{
		"sheet": "palhaco_dash.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/clown/dash/",
		"name": "dash",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
		"shoulder_from_nose": Vector2(-64, 60),
		"pivot": Vector2(250, 330),
	},
	# Abaixado do palhaço (A13): só os 4 quadros de cima, pés plantados (sola em 486, meio dos pés
	# em 256). Sem "shoulder_from_nose": a cabeça desce até os joelhos, então a pistola continua
	# no ombro das peças (o tiro abaixado sai do mesmo lugar de antes).
	{
		"sheet": "palhaco_abaixado.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/clown/crouch/",
		"name": "crouch",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
	},
	# Dano do palhaço (A15): 4 quadros no ar, o meio do tronco em (256, 332), como no pulo e no dash.
	{
		"sheet": "palhaco_dano.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/clown/hurt/",
		"name": "hurt",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
		"shoulder_from_nose": Vector2(-64, 60),
		# Quadros 1 e 2 reclinados: o nariz + (-64, 60) cairia na boca e no queixo; ombro na gola.
		"shoulders": {1: Vector2(285, 312), 2: Vector2(262, 272)},
	},
	# Dano da acrobata (A16): 4 quadros no ar, a estrela da cintura em (256, 280) em todos (não
	# cabia mais alto sem encolher). ground_y 537 deixa a cintura à mesma distância dos pés que
	# no pulo (cintura em 229 com chão em 486), então o corpo não pula na troca dano/pulo.
	{
		"sheet": "acrobata_dano.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/acrobat/hurt/",
		"name": "hurt",
		"ground_y": 537, "center_x": 256,
		"cell_height": 465.0, "rig_height": 268.0,
		"shoulder_from_nose": Vector2(-45, 55),
		# Quadros 1 e 2 reclinados: a regra do nariz cairia no pescoço; ombro no peito.
		"shoulders": {1: Vector2(250, 235), 2: Vector2(250, 232)},
	},
	# Abaixado da acrobata (A14): como o do palhaço, pés plantados e sem ombros (a pistola fica no
	# ombro das peças e o tiro abaixado sai do mesmo lugar).
	{
		"sheet": "acrobata_abaixado.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/acrobat/crouch/",
		"name": "crouch",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 268.0,
	},
	# Dash da acrobata (A12): cintura (meio do maiô) em (300, 280) nos 4 quadros; center_x 300
	# põe a cintura no mesmo x do corpo parado. Também é o ponto de giro da Pirueta.
	{
		"sheet": "acrobata_dash.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/acrobat/dash/",
		"name": "dash",
		"ground_y": 486, "center_x": 300,
		"cell_height": 465.0, "rig_height": 268.0,
		"shoulder_from_nose": Vector2(-45, 55),
		"pivot": Vector2(300, 280),
	},
	# Virando balão e resgate da acrobata (A10): mesma origem e escala do balão.
	{
		"sheet": "acrobata_balao_vira_resgate.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/balloon/",
		"name": "turn",
		"ground_y": 240, "center_x": 256,
		"cell_height": 260.0, "rig_height": 132.0,
	},
	# Virando balão e resgate do palhaço (A8): mesma origem e escala do balão da A7.
	{
		"sheet": "palhaco_balao_vira_resgate.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/balloon/",
		"name": "turn",
		"ground_y": 240, "center_x": 256,
		"cell_height": 260.0, "rig_height": 132.0,
	},
	# Pulo no ar (A6): cintura (meio do maiô) em (256, 229), a mesma altura da cintura no parado
	# (231), então o corpo não pula na troca. Escala única 0,94 na preparação (cabeça como a do parado).
	{
		"sheet": "acrobata_pulo.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/jump/",
		"name": "jump",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 268.0,
		"shoulder_from_nose": Vector2(-45, 55),
	},
	{
		"sheet": "acrobata_corrida.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/run/",
		"name": "run",
		# Folha arrumada por tools/normalize_sheet.gd (chão em 486, nariz em x = 400).
		"ground_y": 486, "center_x": 313,
		"cell_height": 465.0, "rig_height": 268.0,
		"shoulder_from_nose": Vector2(-45, 55),
	},
	# Leopoldo: células de 1024 x 512, olhando para a esquerda; parado mede 396 px de altura.
	{
		"sheet": "leao/leao_parado.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "idle",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Parado com a juba em fogo (B2, fase 3): mesmas células, sola e escala do parado.
	{
		"sheet": "leao/leao_fogo_parado.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "fire_idle",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	{
		"sheet": "leao/leao_rugido.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "roar",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	{
		"sheet": "leao/leao_corrida.png",
		"columns": 2, "rows": 4, "count": 8,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "run",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Derrota (B5): cansado, deitando, deitado de língua de fora e dormindo; ponto mais baixo em
	# y 482, mesma escala do parado.
	{
		"sheet": "leao/leao_derrota.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "defeat",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Rugido com a juba em fogo (B6, fase 3): mesmas células, patas e escala do rugido.
	{
		"sheet": "leao/leao_fogo_rugido.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "fire_roar",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Corrida com a juba em fogo (B3, Investida da fase 3): mesmas células, solas e escala da corrida.
	{
		"sheet": "leao/leao_fogo_corrida.png",
		"columns": 2, "rows": 4, "count": 8,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "fire_run",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Salto do leão (B1b): 8 quadros (agachado, saída, subindo, dois no alto, descendo, perto do
	# chão e pouso), patas de 1 e 8 em y 482 e tronco de 2 a 7 no ponto do voo do antigo
	# leao_pulo.png (4 quadros, guardado na pasta). Mesma escala.
	{
		"sheet": "leao/leao_salto.png",
		"columns": 2, "rows": 4, "count": 8,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "leap",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Salto com a juba em fogo (B4, fase 3): mesmos quadros, células e escala do salto; corpos
	# alinhados ao salto aprovado pela silhueta.
	{
		"sheet": "leao/leao_fogo_salto.png",
		"columns": 2, "rows": 4, "count": 8,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "fire_leap",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	# Domador (C2): células de 512, olhando para a esquerda, uns 465 px de altura (260 no jogo),
	# solas em y 486 e a fivela do cinto em x 256.
	{
		"sheet": "domador/domador_chicote.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/tamer/art/tamer/",
		"name": "whip",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 260.0,
	},
	# Medo do Domador (C3): mesma escala e solas do chicote. As botas ficam no mesmo lugar das do
	# quadro "pronto" do chicote (meio das botas em x 302 lá e 257 aqui): center_x 211.
	{
		"sheet": "domador/domador_medo.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/tamer/art/tamer/",
		"name": "fear",
		"ground_y": 486, "center_x": 211,
		"cell_height": 465.0, "rig_height": 260.0,
	},
	# Reverência do Domador (C4, quadros 3 e 4 da C4b): botas paradas, meio das botas em x 245;
	# center_x 199 põe as botas no mesmo lugar das do quadro "pronto" do chicote.
	{
		"sheet": "domador/domador_reverencia.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/tamer/art/tamer/",
		"name": "bow",
		"ground_y": 486, "center_x": 199,
		"cell_height": 465.0, "rig_height": 260.0,
	},
	# Torta na Cara desenhada (D1, Grande Número do palhaço): sapatos no lugar dos do parado (meio
	# em x 260), mesma escala; sem pistola (os dois braços desenhados).
	{
		"sheet": "palhaco_torta.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/special/",
		"name": "pie_throw",
		"ground_y": 486, "center_x": 256,
		"cell_height": 406.0, "rig_height": 198.0,
	},
	# Torta voando (D2, quadros 1–4) e esborrachando (5–8): o meio da torta (e o núcleo do creme)
	# em (256, 256) da célula; a torta em pé mede uns 386 px de largura e 171 na tela.
	{
		"sheet": "torta.png",
		"columns": 4, "rows": 2, "count": 4,
		"out_dir": "res://core/player/characters/clown/grand_number/",
		"name": "pie_fly",
		"ground_y": 256, "center_x": 256,
		"cell_height": 386.0, "rig_height": 171.0,
	},
	{
		"sheet": "torta.png",
		"columns": 4, "rows": 2, "count": 4, "first": 4,
		"out_dir": "res://core/player/characters/clown/grand_number/",
		"name": "pie_splat",
		"ground_y": 256, "center_x": 256,
		"cell_height": 386.0, "rig_height": 171.0,
	},
	# Salto Mortal desenhado (D3, Grande Número da acrobata): 1 e 8 no chão (sola em 486), 2–7 no ar
	# com o meio do tronco em (256, 250); mesma escala do parado.
	{
		"sheet": "acrobata_salto_mortal.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/special/",
		"name": "somersault",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 268.0,
		# O quadro 7 (o chute) foi posto 37 px à esquerda na célula para o pé caber: volta ao lugar.
		"offsets": {7: Vector2(37, 0)},
	},
	# Chute da Torta de Ouro (D4b, Grande Número em Dupla): células de 512 × 1024; a origem é o meio
	# da torta (x 256, y 857) nos quadros 1–3. Escala da acrobata na tela (465 px da folha = 268 x 0,86
	# do rig). O quadro 4 (o salto para trás) ficou na célula longe do lugar dele: "offsets" o devolve.
	{
		"sheet": "acrobata_chute_torta.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://core/combat/duo_kick/",
		"name": "duo_kick",
		"ground_y": 857, "center_x": 256,
		"cell_height": 465.0, "rig_height": 230.5,
		"offsets": {4: Vector2(-148, -10)},
	},
	# Malabaristas parados malabarizando (E2, aproveitada como "chuveiro"): células de 512, olhando
	# para a direita, uns 460 px do cabelo à sola (230 no jogo), solas em 486 e o meio dos pés em
	# x 256 (âncora "pes" do regrid). O Teco é a mesma folha com as listras trocadas
	# (tools/recolor_twin.gd).
	{
		"sheet": "malabaristas/tico_malabares.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://bosses/jugglers/art/tico/",
		"name": "idle",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	{
		"sheet": "malabaristas/teco_malabares.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://bosses/jugglers/art/teco/",
		"name": "idle",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	# Arremesso (E3), mesma escala e mesmos pés do parado (âncora "pes", escala única 0,882 da candidata).
	{
		"sheet": "malabaristas/tico_arremesso.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/jugglers/art/tico/",
		"name": "throw",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	{
		"sheet": "malabaristas/teco_arremesso.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/jugglers/art/teco/",
		"name": "throw",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	# Tonto (E4): mesma escala e mesmos pés do parado (âncora "pes", escala única 0,79 da candidata).
	{
		"sheet": "malabaristas/tico_tonto.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/jugglers/art/tico/",
		"name": "dizzy",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	{
		"sheet": "malabaristas/teco_tonto.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/jugglers/art/teco/",
		"name": "dizzy",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	# Salto mortal (E5): 1 agachado, 2–9 a bolinha em 8 orientações (o meio dela em (256, 280)) e 10 a
	# aterrissagem; agachado e aterrissagem com os pés no lugar do parado. Escala única 1,28 da candidata.
	{
		"sheet": "malabaristas/tico_salto.png",
		"columns": 4, "rows": 3, "count": 10,
		"out_dir": "res://bosses/jugglers/art/tico/",
		"name": "flip",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	{
		"sheet": "malabaristas/teco_salto.png",
		"columns": 4, "rows": 3, "count": 10,
		"out_dir": "res://bosses/jugglers/art/teco/",
		"name": "flip",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	# Derrota (E6): deitados de costas, células de 1024 × 512, as costas na linha do chão (486) e o nariz em
	# x ~430 da célula (o meio do corpo perto de 512). Mesma escala do parado (460 px de pé = 230 no jogo);
	# escala única 0,92 da candidata, pelo nariz e pela cabeça.
	{
		"sheet": "malabaristas/tico_derrota.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/jugglers/art/tico/",
		"name": "defeat",
		"ground_y": 486, "center_x": 512,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	{
		"sheet": "malabaristas/teco_derrota.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/jugglers/art/teco/",
		"name": "defeat",
		"ground_y": 486, "center_x": 512,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	# Totem dos Malabaristas (E7, 04/10/2026): os dois irmãos num desenho, MENORES que nas outras folhas (decisão
	# do usuário, para caber por baixo do pedestal). Folha normalizada por docs/medidas/malabaristas/e7_normalizar.gd
	# (escala única 1,019, solas em 486, meio das solas em 256). O quadro 1 tem 440 px = 210 no jogo (0,477;
	# com 0,5 o quadro mais alto entrava 9 px na tábua pendurada, que vai de 216 a 240 px do chão; assim fica 1 px
	# abaixo dela). O "teco_base" é a mesma folha com as cores trocadas
	# (tools/recolor_twin.gd troca).
	{
		"sheet": "malabaristas/totem.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://bosses/jugglers/art/totem/",
		"name": "tico_base",
		"ground_y": 486, "center_x": 256,
		"cell_height": 440.0, "rig_height": 210.0,
	},
	{
		"sheet": "malabaristas/totem_teco.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://bosses/jugglers/art/totem/",
		"name": "teco_base",
		"ground_y": 486, "center_x": 256,
		"cell_height": 440.0, "rig_height": 210.0,
	},
	# Mágico parado (M2): células de 512, olhando para a ESQUERDA, ~465 px da sola ao alto da cartola
	# (330 no jogo), solas em 486, meio dos pés em x 256 (âncora "pes" do regrid, escala única).
	{
		"sheet": "magico/magico_parado.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "idle",
		"ground_y": 486, "center_x": 256,
		"cell_height": 465.0, "rig_height": 330.0,
	},
	# Mágico com a varinha (M3): células de 512 × 640 (a varinha erguida passa da altura de 512), solas em
	# 614, meio dos pés em x 256, mesma escala do parado (465 px da sola ao alto da cartola = 330 no jogo).
	{
		"sheet": "magico/magico_varinha.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "wand",
		"ground_y": 614, "center_x": 256,
		"cell_height": 465.0, "rig_height": 330.0,
	},
	# Mágico batendo na cartola (M4): células de 512 × 640 como a da varinha, solas em 614, meio dos pés em
	# x 256, escala única pela altura do personagem (quadro 4, sem a varinha acima: 465 px).
	{
		"sheet": "magico/magico_cartola.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "tap",
		"ground_y": 614, "center_x": 256,
		"cell_height": 465.0, "rig_height": 330.0,
	},
	# Mágico sumindo na capa (M5): células de 512 × 640, solas (ou o fundo da coluna e da cartola) em 614, meio
	# do que encosta no chão em x 256; escala única 0,71 da candidata pela altura do personagem no quadro 1.
	{
		"sheet": "magico/magico_sumir.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "vanish",
		"ground_y": 614, "center_x": 256,
		"cell_height": 465.0, "rig_height": 330.0,
	},
	# Mágico em reverência (1, 2) e com medo (3, 4) (M6): células de 640 × 640 (a reverência funda com a
	# cartola na mão não cabe em 512), solas em 614, meio dos pés em x 320; escala única 0,756 da candidata
	# pela altura do personagem em pé no quadro 3.
	{
		"sheet": "magico/magico_reverencia.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "bow",
		"ground_y": 614, "center_x": 320,
		"cell_height": 465.0, "rig_height": 330.0,
	},
	# Mão gigante do Zaratan (M7), a da esquerda da tela (polegar para a direita; a outra é espelhada): células
	# de 640 × 640, escala única 0,891 da candidata, o botão dourado da manga no mesmo ponto das 4 (o pulso não
	# se mexe). Pivô (o nó GiantHand) em (315, 282): no meio do punho fechado e 175 px acima do fundo dele, como
	# o punho do código. A mão aberta tem 472 px de altura na célula e 290 no jogo, como a desenhada por código.
	{
		"sheet": "magico/magico_maos.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "hand",
		"ground_y": 282, "center_x": 315,
		"cell_height": 472.0, "rig_height": 290.0,
	},
	# Rosto do mágico gigante (M8), de frente e sem cartola (a cartola é a peça da M1, `giant_hat.png`): células de
	# 640 × 640, escala única 0,921 da candidata, o meio das orelhas em x 320 e o alto do cabelo em y 72. Pivô (o
	# nó Giant, o meio da cabeça) em (320, 300). Do cabelo ao cavanhaque: 528 px na célula e 440 no jogo, como o
	# rosto do código.
	{
		"sheet": "magico/magico_rosto.png",
		"columns": 4, "rows": 1, "count": 4,
		"out_dir": "res://bosses/magician/art/",
		"name": "face",
		"ground_y": 300, "center_x": 320,
		"cell_height": 528.0, "rig_height": 440.0,
	},
	# Os mesmos com os 4 intermediários do braço da frente (tools/juggler_inbetweens.gd), 12 desenhos
	# na ordem de tocar. As de 8 ficam para comparar.
	{
		"sheet": "malabaristas/tico_malabares_12.png",
		"columns": 4, "rows": 3, "count": 12,
		"out_dir": "res://bosses/jugglers/art/tico/",
		"name": "idle12",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
	{
		"sheet": "malabaristas/teco_malabares_12.png",
		"columns": 4, "rows": 3, "count": 12,
		"out_dir": "res://bosses/jugglers/art/teco/",
		"name": "idle12",
		"ground_y": 486, "center_x": 256,
		"cell_height": 460.0, "rig_height": 230.0,
	},
]


func _initialize() -> void:
	# Com argumentos (nomes das folhas), recorta só essas e não mexe nas outras.
	var only := OS.get_cmdline_user_args()
	for animation in ANIMATIONS:
		if only.is_empty() or animation.sheet in only:
			_cut(animation)
	quit()


func _cut(a: Dictionary) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + a.sheet))
	sheet.convert(Image.FORMAT_RGBA8)
	var cell_size := Vector2i(sheet.get_width() / a.columns, sheet.get_height() / a.rows)
	var cells: Array[Image] = []
	var union := Rect2i()
	# "first": começa nesse quadro da folha (0 = o primeiro), para recortar só parte dela.
	var first: int = a.get("first", 0)
	for i in a.count:
		var k: int = first + i
		var cell := sheet.get_region(Rect2i(Vector2i(k % a.columns, k / a.columns) * cell_size, cell_size))
		cells.append(cell)
		var used := cell.get_used_rect()
		union = used if i == 0 else union.merge(used)
	union = union.grow(2).intersection(Rect2i(Vector2i.ZERO, cell_size))
	var scale: float = a.rig_height / a.cell_height
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(a.out_dir))
	var paths: Array[String] = []
	var shoulders: Array[Vector2] = []
	for i in a.count:
		var frame := cells[i].get_region(union)
		frame.resize(roundi(union.size.x * TEXTURE_FACTOR), roundi(union.size.y * TEXTURE_FACTOR), Image.INTERPOLATE_LANCZOS)
		var path: String = a.out_dir + "%s_%d.png" % [a.name, i + 1]
		frame.save_png(path)
		paths.append(path)
		if a.has("shoulder_from_nose"):
			var nose := _find_nose(cells[i])
			var shoulder: Vector2 = Vector2(nose) + a.shoulder_from_nose
			# "shoulders": ombro medido à mão (pixels da célula) nos quadros em que a regra do nariz
			# não serve (corpo reclinado, cabeça virada).
			if a.has("shoulders") and a.shoulders.has(i + 1):
				shoulder = a.shoulders[i + 1]
			shoulders.append((shoulder - Vector2(a.center_x, a.ground_y)) * scale)
			print(path, " nariz ", nose)
		else:
			print(path)
	var origin := (Vector2(union.position) - Vector2(a.center_x, a.ground_y)) * scale
	# Ponto de giro opcional ("pivot", em pixels da célula), levado para o espaço do rig.
	var pivot: Vector2 = (Vector2(a.pivot) - Vector2(a.center_x, a.ground_y)) * scale if a.has("pivot") else Vector2.ZERO
	# "offsets": deslocamento de quadros que tiveram de ser postos fora do lugar na célula para caber
	# ({quadro: Vector2 em pixels da célula}), levado para o espaço do rig.
	var offsets: Array[Vector2] = []
	if a.has("offsets"):
		for i in a.count:
			offsets.append(Vector2(a.offsets.get(i + 1, Vector2.ZERO)) * scale)
	_write_resource(a.out_dir + a.name + ".tres", paths, scale / TEXTURE_FACTOR, origin, shoulders, pivot, offsets)


## Ponto vermelho mais à direita na metade de cima da célula (o nariz de palhaço).
func _find_nose(cell: Image) -> Vector2i:
	var nose := Vector2i(-1, -1)
	for y in range(0, cell.get_height() / 2 + 60):
		for x in range(cell.get_width() - 1, -1, -1):
			var c := cell.get_pixel(x, y)
			if c.a > 0.9 and c.r > 0.8 and c.g < 0.25 and c.b < 0.25:
				if x > nose.x:
					nose = Vector2i(x, y)
				break
	return nose


## Escreve o .tres à mão (os PNGs ainda não foram importados, então não dá para load()).
func _write_resource(path: String, frames: Array[String], scale: float, origin: Vector2,
		shoulders: Array[Vector2], pivot := Vector2.ZERO, offsets: Array[Vector2] = []) -> void:
	var text := "[gd_resource type=\"Resource\" script_class=\"FrameAnimation\" load_steps=%d format=3]\n\n" % (frames.size() + 2)
	text += "[ext_resource type=\"Script\" path=\"res://core/player/characters/frame_animation.gd\" id=\"1_script\"]\n"
	for i in frames.size():
		text += "[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%d_frame\"]\n" % [frames[i], i + 2]
	text += "\n[resource]\nscript = ExtResource(\"1_script\")\n"
	var refs := PackedStringArray()
	for i in frames.size():
		refs.append("ExtResource(\"%d_frame\")" % (i + 2))
	text += "frames = Array[Texture2D]([%s])\n" % ", ".join(refs)
	text += "frame_scale = %s\n" % scale
	text += "origin = Vector2(%s, %s)\n" % [origin.x, origin.y]
	if not shoulders.is_empty():
		var values := PackedStringArray()
		for s in shoulders:
			values.append("%.1f, %.1f" % [s.x, s.y])
		text += "shoulders = PackedVector2Array(%s)\n" % ", ".join(values)
	if pivot != Vector2.ZERO:
		text += "pivot = Vector2(%.1f, %.1f)\n" % [pivot.x, pivot.y]
	if not offsets.is_empty():
		var moved := PackedStringArray()
		for o in offsets:
			moved.append("%.1f, %.1f" % [o.x, o.y])
		text += "offsets = PackedVector2Array(%s)\n" % ", ".join(moved)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	print(path, " escala ", scale, " origem ", origin)
