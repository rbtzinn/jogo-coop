extends SceneTree
## Margem transparente em arte única, sem redimensionar nem redesenhar pixels.
## Uso: --script res://tools/pad_single_art.gd -- entrada saída lado

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		quit(1)
		return
	var source := Image.load_from_file(args[0])
	var side := int(args[2])
	if source == null or side < maxi(source.get_width(),source.get_height()):
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var out := Image.create_empty(side,side,false,Image.FORMAT_RGBA8)
	var origin := Vector2i((side-source.get_width())/2,(side-source.get_height())/2)
	out.blit_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),origin)
	var preserved := out.get_region(Rect2i(origin,source.get_size())).get_data() == source.get_data()
	assert(preserved)
	var result := out.save_png(args[1])
	print("Arte: ",out.get_size(),"; margem: ",origin,"; pixels preservados: ",preserved)
	quit(0 if result == OK else 1)
