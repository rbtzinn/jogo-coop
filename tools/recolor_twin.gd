extends SceneTree
## Faz a folha do Teco a partir da do Tico: troca só o vermelho das LISTRAS (malha e gola) pelo azul do
## Teco, mantendo o claro e escuro de cada pixel e a transparência. Nariz, língua, pele, luvas e sapatos
## ficam como estão.
## Cada mancha vermelha (pixels vermelhos ligados) é julgada pela mediana dela, porque pele e creme têm
## quase a mesma cor e a borda não separa:
## - listra: brilho entre 0,5 e 0,8 e saturação abaixo de 0,99 (na folha base S ~0,87 e V ~0,68; na E2
##   há listras com S 0,93 e V 0,58; na E3, uma com S 0,97 e V 0,62);
## - nariz e língua: mais claros (V 0,85 a 0,91 nas duas folhas); ficam;
## - sapatos marrons: brilho abaixo de 0,45; ficam.
## Conferido na folha base (03/10): o Tico recolorido bate com o Teco desenhado pelo Codex
## (docs/referencias/pecas/malabaristas/teste_teco_por_recolor.png).
## Uso:
##   Godot --headless --script res://tools/recolor_twin.gd -- <tico.png> <teco.png> [troca]
## "troca" (totem, E7, 04/10/2026): a folha tem os dois irmãos; além do vermelho virar azul, o azul das listras
## do Teco vira o vermelho do Tico (o matiz mediano das listras trocadas e o brilho de volta pela mesma
## escala), para a versão com o Teco embaixo.
## Imprime cada mancha grande e se trocou ou não, para conferir.

## Azul do Teco medido na folha base: matiz 0,566; o brilho cai para 0,585 do vermelho (V ~0,38).
const BLUE_HUE := 0.566
const VALUE_SCALE := 0.585


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var img := Image.load_from_file(args[0])
	img.convert(Image.FORMAT_RGBA8)
	var swap := args.size() > 2 and args[2] == "troca"
	var blue: Array[Vector2i] = []
	if swap:
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.05 and c.s > 0.25 and c.v > 0.1 and c.h > 0.5 and c.h < 0.7:
					blue.append(Vector2i(x, y))
	var hue_sum := Vector2.ZERO
	var red := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.3 and c.s > 0.5 and c.v > 0.2 and (c.h < 0.06 or c.h > 0.94):
				red[Vector2i(x, y)] = true
	var seen := {}
	var changed := 0
	var kept := 0
	var recolored := {}
	for start: Vector2i in red:
		if seen.has(start):
			continue
		var blob: Array[Vector2i] = []
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var p: Vector2i = stack.pop_back()
			blob.append(p)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + d
				if red.has(q) and not seen.has(q):
					seen[q] = true
					stack.append(q)
		var sats: Array[float] = []
		var values: Array[float] = []
		for p in blob:
			var c := img.get_pixel(p.x, p.y)
			sats.append(c.s)
			values.append(c.v)
		sats.sort()
		values.sort()
		var median_s := sats[sats.size() / 2]
		var median_v := values[values.size() / 2]
		# Fiapos pequenos soltos (entre os botões, onde o vermelho é claro como o do nariz, V até 0,87)
		# também trocam; o nariz e a língua são bem maiores que 150 px.
		var stripe := (median_v > 0.5 and median_v < 0.8 and median_s < 0.99) or (blob.size() < 150 and median_v > 0.5 and median_v < 0.9)
		if blob.size() > 300:
			print("mancha de %d px em %s: S %.2f, V %.2f: %s" % [blob.size(), blob[0], median_s, median_v, "listra, troca" if stripe else "fica"])
		if stripe:
			changed += blob.size()
			for p in blob:
				hue_sum += Vector2.from_angle(img.get_pixel(p.x, p.y).h * TAU)
			for p in blob:
				var c := img.get_pixel(p.x, p.y)
				img.set_pixel(p.x, p.y, Color.from_hsv(BLUE_HUE, c.s, c.v * VALUE_SCALE, c.a))
				recolored[p] = true
		else:
			kept += blob.size()
	# Segunda passada: fiapos e beiradas avermelhadas (entre os botões, no contorno das listras) que
	# encostam numa listra já trocada viram azul também; os claros (nariz, língua) nunca.
	var edges := 0
	for _round in 3:
		var grow: Array[Vector2i] = []
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a <= 0.3 or c.s < 0.35 or c.v >= 0.8 or not (c.h < 0.06 or c.h > 0.94):
					continue
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = Vector2i(x, y) + d
					if recolored.has(q):
						grow.append(Vector2i(x, y))
						break
		for p in grow:
			var c := img.get_pixel(p.x, p.y)
			img.set_pixel(p.x, p.y, Color.from_hsv(BLUE_HUE, c.s, c.v * VALUE_SCALE, c.a))
			recolored[p] = true
		edges += grow.size()
	print("trocados %d px, mais %d de beirada; mantidos %d px vermelhos" % [changed, edges, kept])
	if swap:
		var red_hue := fposmod(hue_sum.angle() / TAU, 1.0)
		for p in blue:
			var c := img.get_pixel(p.x, p.y)
			img.set_pixel(p.x, p.y, Color.from_hsv(red_hue, c.s, minf(c.v / VALUE_SCALE, 1.0), c.a))
		print("troca: %d px azuis viraram vermelho (matiz %.3f)" % [blue.size(), red_hue])
	img.save_png(args[1])
	quit()
