extends SceneTree
## E7 (totem dos Malabaristas): normaliza a candidata 1774x887 numa folha 2048x1024 (4x2 células de 512).
## - Cada quadro sai da caixa inteira dele (os 8 desenhos são peças separadas por vãos de 7 a 15 px; não corta
##   pela grade, que passaria pelos pés da 1ª fila).
## - Uma escala única para os 8 (SCALE): o quadro 1, em pé, fica com 440 px da sola ao topo.
## - Âncora "pés", como as outras folhas dos irmãos: a sola mais baixa em y 486 e o meio das solas (os 10 px de
##   baixo) em x 256.
## - Alpha: fiapos de alpha <= 25 a mais de 3 px de um pixel forte viram 0; o resto fica como veio.
## Uso: Godot --headless --script normalizar.gd -- <candidata.png> <saída.png>

const BOXES := [
	Rect2i(77, 18, 295, 432), Rect2i(520, 30, 296, 420), Rect2i(961, 7, 305, 440), Rect2i(1408, 13, 297, 438),
	Rect2i(77, 457, 345, 418), Rect2i(528, 457, 301, 422), Rect2i(968, 462, 342, 413), Rect2i(1421, 458, 343, 419),
]
const SCALE := 440.0 / 432.0
const CELL := 512
const GROUND_Y := 486


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var src := Image.load_from_file(args[0])
	src.convert(Image.FORMAT_RGBA8)
	var out := Image.create(4 * CELL, 2 * CELL, false, Image.FORMAT_RGBA8)
	for i in BOXES.size():
		var box: Rect2i = BOXES[i].grow(2)
		var piece := src.get_region(box)
		_clean(piece)
		var size := Vector2i(roundi(piece.get_width() * SCALE), roundi(piece.get_height() * SCALE))
		piece.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		for y in piece.get_height():
			for x in piece.get_width():
				var c := piece.get_pixel(x, y)
				if c.a < 0.03:
					piece.set_pixel(x, y, Color(0, 0, 0, 0))
		var used := piece.get_used_rect()
		var low := used.end.y - 1
		var xs: Array[int] = []
		for y in range(low - 10, low + 1):
			for x in piece.get_width():
				if piece.get_pixel(x, y).a > 0.5:
					xs.append(x)
		xs.sort()
		var feet_mid: float = (xs.front() + xs.back()) / 2.0
		var cell := Vector2i((i % 4) * CELL, (i / 4) * CELL)
		var at := cell + Vector2i(roundi(256 - feet_mid), GROUND_Y - low)
		var placed := Rect2i(at + used.position, used.size)
		var margin := [placed.position.x - cell.x, placed.position.y - cell.y, cell.x + CELL - placed.end.x, cell.y + CELL - placed.end.y]
		print("q%d: %dx%d na célula, margens esq/topo/dir/baixo %s, meio das solas %.1f -> 256" % [i + 1, used.size.x, used.size.y, margin, feet_mid])
		out.blend_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), at)
	out.save_png(args[1])
	quit()


## Zera fiapos fracos (alpha <= 25/255) longe (> 3 px) de qualquer pixel forte.
func _clean(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var strong := PackedByteArray()
	strong.resize(w * h)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 25.0 / 255.0:
				strong[y * w + x] = 1
	var removed := 0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a <= 0.0 or c.a > 25.0 / 255.0:
				continue
			var near := false
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var xx := x + dx
					var yy := y + dy
					if xx >= 0 and yy >= 0 and xx < w and yy < h and strong[yy * w + xx] == 1:
						near = true
						break
				if near:
					break
			if not near:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				removed += 1
	if removed > 0:
		print("  fiapos zerados: %d" % removed)
