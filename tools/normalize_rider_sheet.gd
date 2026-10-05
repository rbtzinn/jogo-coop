extends SceneTree
## Arruma a folha dos irmãos no monociclo (8 desenhos, 4 x 2, gerada pelo ChatGPT sem respeitar a grade:
## os sapatos da linha de cima entram nas células de baixo e o tamanho veio 1774 x 887). Para cada desenho:
## acha o nariz do de baixo (a mancha vermelha redonda mais baixa), separa o desenho pelo contorno ligado a
## ele, põe na escala da folha do totem (os narizes do mesmo tamanho) e remonta uma grade 4 x 2 de células de
## 512 px com o nariz do de baixo sempre no mesmo ponto (o corpo sentado fica parado; pernas e braços mexem).
## Uso:
##   Godot --headless --script res://tools/normalize_rider_sheet.gd -- <entrada.png> <saída.png> <totem.png>

const CELL := 512
## Onde fica o nariz do de baixo em cada célula da saída.
const NOSE_AT := Vector2(300, 290)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var source := Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	var totem := Image.load_from_file(args[2])
	totem.convert(Image.FORMAT_RGBA8)
	var target := _median_nose(totem, Vector2i(totem.get_width() / 4, totem.get_height() / 2))
	var cell_size := Vector2i(source.get_width() / 4, source.get_height() / 2)
	var own := _median_nose(source, cell_size)
	var scale := target / own
	print("nariz do totem %.1f px, da folha %.1f px: escala %.4f" % [target, own, scale])
	var sheet := Image.create_empty(CELL * 4, CELL * 2, false, Image.FORMAT_RGBA8)
	for i in 8:
		var cell := Rect2i(Vector2i(i % 4, i / 4) * cell_size, cell_size)
		var noses := _noses(source, cell)
		var bottom: Array = noses[noses.size() - 1]
		var seed := Vector2i(bottom[0])
		var piece: Array = _extract(source, seed)
		var image: Image = piece[0]
		var rect: Rect2i = piece[1]
		var size := Vector2i((Vector2(image.get_size()) * scale).round())
		image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		var nose := (Vector2(bottom[0]) - Vector2(rect.position)) * scale
		var at := Vector2i(i % 4, i / 4) * CELL + Vector2i((NOSE_AT - nose).round())
		var inside := Rect2i(Vector2i(i % 4, i / 4) * CELL, Vector2i(CELL, CELL))
		var placed := Rect2i(at, size)
		print("desenho %d: nariz de baixo %s, %d narizes, recorte %s, cabe na célula: %s" % [i + 1, bottom[0], noses.size(), rect, inside.encloses(placed)])
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, size), at)
	sheet.save_png(args[1])
	quit()


## Diâmetro mediano dos narizes (sqrt da área) em todas as células.
func _median_nose(img: Image, cell_size: Vector2i) -> float:
	var sizes: Array[float] = []
	for i in 8:
		for nose: Array in _noses(img, Rect2i(Vector2i(i % 4, i / 4) * cell_size, cell_size)):
			sizes.append(sqrt(float(nose[1])))
	sizes.sort()
	return sizes[sizes.size() / 2]


## Narizes da célula (manchas vermelho-vivo grandes e redondas), de cima para baixo: [ponto mais à direita, área].
func _noses(img: Image, cell: Rect2i) -> Array:
	var seen := {}
	var found := []
	for y in range(cell.position.y, cell.end.y):
		for x in range(cell.position.x, cell.end.x):
			var p := Vector2i(x, y)
			if seen.has(p) or not _red(img.get_pixel(x, y)):
				continue
			var stack: Array[Vector2i] = [p]
			seen[p] = true
			var area := 0
			var box := Rect2i(p, Vector2i.ONE)
			var right := p
			while not stack.is_empty():
				var q: Vector2i = stack.pop_back()
				area += 1
				box = box.expand(q)
				if q.x > right.x:
					right = q
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var r: Vector2i = q + d
					if cell.has_point(r) and not seen.has(r) and _red(img.get_pixel(r.x, r.y)):
						seen[r] = true
						stack.append(r)
			var aspect := float(maxi(box.size.x, box.size.y)) / maxi(mini(box.size.x, box.size.y), 1)
			if area > 250 and aspect < 1.7:
				found.append([right, area, box.get_center().y])
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[2] < b[2])
	return found


func _red(c: Color) -> bool:
	return c.a > 0.9 and c.r > 0.65 and c.g < 0.3 and c.b < 0.3 and c.r - c.g > 0.45


## Copia só o desenho ligado ao ponto `seed` (pixels visíveis conectados). Retorna [imagem, retângulo].
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
