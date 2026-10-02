extends SceneTree
## Arruma uma folha de animação que não respeitou a grade (personagens encostando nas bordas,
## chão em alturas diferentes): separa cada personagem pelo contorno (a partir do nariz
## vermelho), põe todos na mesma escala e remonta uma grade 4 x 2 de células de 512 px com
## o chão na mesma linha e o nariz na mesma coluna.
## Uso: Godot --headless --script res://tools/normalize_sheet.gd -- <entrada.png> <saída.png> [altura]

const CELL := 512
const GROUND_Y := 486
const NOSE_X := 400


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var source := Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	var target_height := float(args[2]) if args.size() > 2 else 470.0
	var cell_size := Vector2i(source.get_width() / 4, source.get_height() / 2)
	var pieces: Array[Image] = []
	var noses: Array[Vector2i] = []
	var tallest := 0
	for i in 8:
		var origin := Vector2i(i % 4, i / 4) * cell_size
		var nose := _find_nose(source, Rect2i(origin, cell_size))
		var piece := _extract(source, nose + Vector2i(-25, 0))
		pieces.append(piece[0])
		noses.append(nose - piece[1].position)
		tallest = maxi(tallest, piece[1].size.y)
	var scale := target_height / tallest
	var sheet := Image.create_empty(CELL * 4, CELL * 2, false, Image.FORMAT_RGBA8)
	for i in 8:
		var piece: Image = pieces[i]
		var size := Vector2i((Vector2(piece.get_size()) * scale).round())
		piece.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		var nose := Vector2(noses[i]) * scale
		var at := Vector2i(i % 4, i / 4) * CELL + Vector2i(roundi(NOSE_X - nose.x), GROUND_Y - size.y)
		sheet.blend_rect(piece, Rect2i(Vector2i.ZERO, size), at)
	sheet.save_png(args[1])
	print("escala ", scale, " maior altura ", tallest)
	quit()


## Ponto vermelho mais à direita na parte de cima da célula (o nariz).
func _find_nose(img: Image, cell: Rect2i) -> Vector2i:
	var nose := Vector2i(-1, -1)
	for y in range(cell.position.y, cell.position.y + cell.size.y * 2 / 3):
		for x in range(cell.end.x - 1, cell.position.x - 1, -1):
			var c := img.get_pixel(x, y)
			if c.a > 0.9 and c.r > 0.8 and c.g < 0.25 and c.b < 0.25:
				if x > nose.x:
					nose = Vector2i(x, y)
				break
	return nose


## Copia só o personagem ligado ao ponto `seed` (pixels visíveis conectados).
## Retorna [imagem recortada, retângulo na folha].
func _extract(img: Image, seed: Vector2i) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[int] = [seed.y * w + seed.x]
	seen[seed.y * w + seed.x] = 1
	var pixels: Array[int] = []
	var rect := Rect2i(seed, Vector2i.ONE)
	while not stack.is_empty():
		var index: int = stack.pop_back()
		pixels.append(index)
		var p := Vector2i(index % w, index / w)
		rect = rect.expand(p)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
				continue
			var k := q.y * w + q.x
			if seen[k] == 0 and img.get_pixel(q.x, q.y).a > 0.25:
				seen[k] = 1
				stack.append(k)
	rect.size += Vector2i.ONE
	# Inclui a borda suave (anti-serrilhado) em volta do que foi achado.
	rect = rect.grow(2).intersection(Rect2i(0, 0, w, h))
	var out := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	var mask := PackedByteArray()
	mask.resize(rect.size.x * rect.size.y)
	for index in pixels:
		var p := Vector2i(index % w, index / w) - rect.position
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var q := p + Vector2i(dx, dy)
				if q.x >= 0 and q.y >= 0 and q.x < rect.size.x and q.y < rect.size.y:
					mask[q.y * rect.size.x + q.x] = 1
	for y in rect.size.y:
		for x in rect.size.x:
			if mask[y * rect.size.x + x] == 1:
				out.set_pixel(x, y, img.get_pixel(rect.position.x + x, rect.position.y + y))
	return [out, rect]
