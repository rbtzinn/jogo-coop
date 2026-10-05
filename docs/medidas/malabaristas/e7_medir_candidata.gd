extends SceneTree
## E7: mede a candidata do totem sem alterar nada. Componentes (alpha > 25) por quadro, narizes (blobs vermelhos
## vivos), solas (linha mais baixa e faixa de x dos 10 px de baixo), listras azuis/vermelhas por metade.

const BOXES := [
	Rect2i(77, 18, 295, 432), Rect2i(520, 30, 296, 420), Rect2i(961, 7, 305, 440), Rect2i(1408, 13, 297, 438),
	Rect2i(77, 457, 345, 418), Rect2i(528, 457, 301, 422), Rect2i(968, 462, 342, 413), Rect2i(1421, 458, 343, 419),
]


func _initialize() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	print("folha %dx%d" % [img.get_width(), img.get_height()])
	for i in BOXES.size():
		var box: Rect2i = BOXES[i]
		var noses := _blobs(img, box, func(c: Color) -> bool: return c.a > 0.9 and c.r > 0.78 and c.g < 0.25 and c.b < 0.25)
		noses.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.count > b.count)
		var big := noses.slice(0, 2)
		big.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.rect.position.y < b.rect.position.y)
		var nose_text := []
		for n: Dictionary in big:
			var r: Rect2i = n.rect
			nose_text.append("(%d,%d) %dx%d n=%d" % [r.get_center().x, r.get_center().y, r.size.x, r.size.y, n.count])
		var low := -1
		for y in range(box.end.y - 1, box.position.y - 1, -1):
			for x in range(box.position.x, box.end.x):
				if img.get_pixel(x, y).a > 0.1:
					low = y
					break
			if low >= 0:
				break
		var xs := []
		for y in range(low - 10, low + 1):
			for x in range(box.position.x, box.end.x):
				if img.get_pixel(x, y).a > 0.5:
					xs.append(x)
		xs.sort()
		var blue := [0, 0]
		var red := [0, 0]
		var mid := box.position.y + box.size.y / 2
		for y in range(box.position.y, box.end.y):
			for x in range(box.position.x, box.end.x):
				var c := img.get_pixel(x, y)
				if c.a < 0.9:
					continue
				var half := 0 if y < mid else 1
				if c.b > c.r + 0.12 and c.b > 0.25:
					blue[half] += 1
				if c.r > c.b + 0.3 and c.r > 0.5 and c.g < 0.35:
					red[half] += 1
		print("q%d: caixa %s altura %d; narizes %s; sola y %d, x %d..%d (meio %.0f); azul cima/baixo %d/%d; vermelho cima/baixo %d/%d" % [
				i + 1, box, box.size.y, nose_text, low, xs.front(), xs.back(), (xs.front() + xs.back()) / 2.0, blue[0], blue[1], red[0], red[1]])
	quit()


func _blobs(img: Image, box: Rect2i, test: Callable) -> Array:
	var seen := {}
	var out := []
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var key := Vector2i(x, y)
			if seen.has(key) or not test.call(img.get_pixelv(key)):
				continue
			var stack := [key]
			seen[key] = true
			var rect := Rect2i(key, Vector2i.ONE)
			var count := 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				rect = rect.expand(p).merge(Rect2i(p, Vector2i.ONE))
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if box.has_point(q) and not seen.has(q) and test.call(img.get_pixelv(q)):
						seen[q] = true
						stack.append(q)
			out.append({"rect": rect, "count": count})
	return out
