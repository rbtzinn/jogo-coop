extends SceneTree
func _initialize() -> void:
	var art := Image.load_from_file(ProjectSettings.globalize_path("res://bosses/rust_maestro/art/p01_base.png"))
	print("SIZE ",art.get_size()," FORMAT ",art.get_format()," ALPHA ",art.detect_alpha()," BOUNDS ",art.get_used_rect())
	var start := Vector2i(art.get_width(),art.get_height())
	var end := Vector2i.ZERO
	var zero := 0
	var border_alpha := 0.0
	for y in art.get_height():
		for x in art.get_width():
			var alpha := art.get_pixel(x,y).a
			if alpha==0: zero += 1
			if x<20 or y<20 or x>=art.get_width()-20 or y>=art.get_height()-20:
				border_alpha = maxf(border_alpha,alpha)
			if alpha>0.05:
				start.x = mini(start.x,x)
				start.y = mini(start.y,y)
				end.x = maxi(end.x,x+1)
				end.y = maxi(end.y,y+1)
	print("VISIBLE ",Rect2i(start,end-start)," ZERO ",zero," BORDER_MAX_ALPHA ",border_alpha)
	quit()
