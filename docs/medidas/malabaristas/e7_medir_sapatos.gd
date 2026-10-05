extends SceneTree
## Sapatos (marrons) nos desenhos do totem: as duas manchas mais baixas, x do meio e y da sola, no jogo (pés da
## base em 0, olhando para a direita).

func _initialize() -> void:
	var anim: FrameAnimation = load("res://bosses/jugglers/art/totem/tico_base.tres")
	for i in anim.frames.size():
		var img := anim.frames[i].get_image()
		var h := img.get_height()
		var seen := {}
		var blobs := []
		for y in range(int(h * 0.7), h):
			for x in img.get_width():
				var p := Vector2i(x, y)
				if seen.has(p) or not _shoe(img.get_pixelv(p)):
					continue
				var stack := [p]
				seen[p] = true
				var rect := Rect2i(p, Vector2i.ONE)
				var n := 0
				while not stack.is_empty():
					var q: Vector2i = stack.pop_back()
					n += 1
					rect = rect.merge(Rect2i(q, Vector2i.ONE))
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var r: Vector2i = q + d
						if r.x >= 0 and r.y >= 0 and r.x < img.get_width() and r.y < h and not seen.has(r) and _shoe(img.get_pixelv(r)):
							seen[r] = true
							stack.append(r)
				if n > 150:
					blobs.append([n, rect])
		blobs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		var text := []
		for blob: Array in blobs.slice(0, 2):
			var r: Rect2i = blob[1]
			text.append("x %.1f sola %.1f" % [anim.origin.x + r.get_center().x * anim.frame_scale, -(anim.origin.y + r.end.y * anim.frame_scale)])
		print("desenho %d: %s" % [i + 1, text])
	quit()


func _shoe(c: Color) -> bool:
	return c.a > 0.8 and c.s > 0.45 and c.v > 0.15 and c.v < 0.55 and c.h > 0.02 and c.h < 0.12
