extends SceneTree
## Folha antes/depois: cada linha um momento do roteiro (antes à esquerda, depois à direita), em 640x360.
func _initialize() -> void:
	var a: String = OS.get_cmdline_user_args()[0]
	var b: String = OS.get_cmdline_user_args()[1]
	var parts := ["curva1", "reta", "curva2", "freio", "8dir", "tab"]
	var out := Image.create(1290, parts.size() * 365, false, Image.FORMAT_RGBA8)
	out.fill(Color("1b1410"))
	for i in parts.size():
		for k in 2:
			var img := Image.load_from_file((a if k == 0 else b).path_join("mundo_%s.png" % parts[i]))
			img.convert(Image.FORMAT_RGBA8)
			img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
			out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i(k * 650, i * 365))
	out.save_png(OS.get_cmdline_user_args()[2])
	quit()
