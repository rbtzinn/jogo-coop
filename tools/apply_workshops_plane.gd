extends SceneTree
## Aplica somente a região editada por Imagegen; todo o resto fica byte-idêntico em pixels.
const SOURCE := "res://docs/referencias/mapas/area3_oficinas/mapa_completo.png"
const PATCH := Rect2i(220, 590, 200, 120)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var original := Image.load_from_file(SOURCE)
	var edited := Image.load_from_file(args[0])
	if original == null or edited == null:
		quit(1)
		return
	if edited.get_size() != original.get_size():
		edited.resize(original.get_width(), original.get_height(), Image.INTERPOLATE_LANCZOS)
	edited.convert(original.get_format())
	if not FileAccess.file_exists("res://docs/referencias/mapas/area3_oficinas/mapa_antes_aviao.png"):
		original.save_png("res://docs/referencias/mapas/area3_oficinas/mapa_antes_aviao.png")
	var out := original.duplicate() as Image
	out.blit_rect(edited, PATCH, PATCH.position)
	var outside_changes := 0
	for y in original.get_height():
		for x in original.get_width():
			if not PATCH.has_point(Vector2i(x,y)) and original.get_pixel(x,y) != out.get_pixel(x,y):
				outside_changes += 1
	assert(outside_changes == 0)
	out.save_png(SOURCE)
	out.get_region(Rect2i(190,560,290,210)).save_png("res://build/qa/workshops/plane_detail.png")
	print("Plane edit: outside rectangle changes = ",outside_changes)
	quit()
