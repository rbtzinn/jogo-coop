extends Node
var failures := 0
func check(ok: bool,label: String) -> void:
	print(("OK " if ok else "FAIL ")+label)
	if not ok: failures += 1
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var art := Image.load_from_file(ProjectSettings.globalize_path("res://bosses/rust_maestro/art/p01_base.png"))
	check(art!=null and art.get_size()==Vector2i(1254,1254),"native resolution preserved")
	check(art.get_format()==Image.FORMAT_RGBA8 and art.detect_alpha()==Image.ALPHA_BLEND,"real transparent RGBA sprite")
	var start := Vector2i(art.get_width(),art.get_height())
	var end := Vector2i.ZERO
	var transparent := 0
	for y in art.get_height():
		for x in art.get_width():
			var alpha := art.get_pixel(x,y).a
			if alpha==0: transparent += 1
			if alpha>0.05:
				start.x = mini(start.x,x)
				start.y = mini(start.y,y)
				end.x = maxi(end.x,x+1)
				end.y = maxi(end.y,y+1)
	var bounds := Rect2i(start,end-start)
	check(transparent>art.get_width()*art.get_height()*0.65,"most of canvas is actual zero-alpha background")
	check(start.x>=100 and start.y>=100 and art.get_width()-end.x>=100 and art.get_height()-end.y>=100,"visible baton/fingers/pipes/shoes have 100px margins")
	print("Visible bounds: ",bounds)
	var scene := load("res://bosses/rust_maestro/rust_maestro_visual.tscn").instantiate() as Node2D
	add_child(scene)
	var sprite := scene.get_node("Sprite") as Sprite2D
	check(sprite.texture.get_size()==Vector2(1254,1254),"Godot visual consumes project-bound original pixels")
	var bottom := float(end.y)-art.get_height()*0.5+sprite.position.y
	check(absf(bottom)<1,"visible shoe bottom anchored at local y0")
	check(scene.get_child_count()==1 and scene.get_node_or_null("Health")==null,"P01 is visual only, never pretends to be a playable fight")
	var preview := load("res://tools/maestro_art_preview.tscn").instantiate() as Control
	add_child(preview)
	check(get_tree().get_nodes_in_group(&"players").is_empty(),"art preview does not spawn a player or change gameplay")
	preview.queue_free()
	scene.queue_free()
	await get_tree().process_frame
	print("FAILURES: ",failures)
	get_tree().quit(failures)
