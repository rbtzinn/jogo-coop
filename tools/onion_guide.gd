extends SceneTree
## Guia visual de intermediários ("papel de cebola"): para cada intermediário pedido, os dois desenhos
## vizinhos de uma folha sobrepostos meio transparentes, mais uma cruz verde no meio da cabeça e uma cruz
## azul no meio do nariz onde o intermediário deve ficar, e a linha do chão. Serve de referência visual
## para pedir desenhos do meio (o gerador de imagens erra posições só por números).
## Uso:
##   Godot --headless --script res://tools/onion_guide.gd -- <folha.png> <saída.png> <colunas> \
##       <vizinho_a,vizinho_b,cabeça_x,cabeça_y,nariz_x,nariz_y> [...]
## Os vizinhos são números de quadro da folha (1 = primeira célula); a saída tem uma célula por item.

const CELL := 512
const GROUND_Y := 486


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var sheet := Image.load_from_file(args[0])
	sheet.convert(Image.FORMAT_RGBA8)
	var columns := int(args[2])
	var items := args.slice(3)
	var out := Image.create(CELL * items.size(), CELL, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.93, 0.92, 0.88))
	for k in items.size():
		var v := (items[k] as String).split(",")
		var origin := Vector2i(k * CELL, 0)
		for neighbor in [int(v[0]), int(v[1])]:
			var cell: Image = sheet.get_region(Rect2i(((neighbor - 1) % columns) * CELL, ((neighbor - 1) / columns) * CELL, CELL, CELL))
			for y in CELL:
				for x in CELL:
					var c := cell.get_pixel(x, y)
					if c.a > 0.05:
						var under := out.get_pixel(origin.x + x, y)
						out.set_pixel(origin.x + x, y, under.lerp(c, c.a * 0.38))
		for x in CELL:
			out.set_pixel(origin.x + x, GROUND_Y, Color(0.2, 0.2, 0.2))
		_cross(out, origin + Vector2i(int(v[2]), int(v[3])), Color(0.1, 0.7, 0.2))
		_cross(out, origin + Vector2i(int(v[4]), int(v[5])), Color(0.1, 0.35, 0.9))
		for y in CELL:
			out.set_pixel(origin.x, y, Color(0.4, 0.4, 0.4))
	out.save_png(args[1])
	quit()


func _cross(image: Image, at: Vector2i, color: Color) -> void:
	for d in range(-14, 15):
		for w in range(-1, 2):
			for p in [at + Vector2i(d, w), at + Vector2i(w, d)]:
				if Rect2i(Vector2i.ZERO, image.get_size()).has_point(p):
					image.set_pixelv(p, color)
