extends SceneTree
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	print(("OK " if ok else "FAIL ")+label)
	if not ok: failures += 1

func _run() -> void:
	var visual: Node2D = load("res://bosses/madame_carretel/carretel_visual.tscn").instantiate()
	root.add_child(visual)
	var frames: SpriteFrames = visual.sprite_frames
	check(frames.get_animation_names().size()==9, "nine sequences loaded")
	for key in frames.get_animation_names():
		check(frames.get_frame_count(key)==4, String(key)+" has four real poses")
		var seen := {}
		var good_margin := true
		for i in 4:
			var texture := frames.get_frame_texture(key,i)
			var image := texture.get_image()
			if image.is_compressed(): image.decompress()
			var rect := image.get_used_rect()
			good_margin = good_margin and image.get_size()==Vector2i(1024,1024) \
				and rect.position.x>20 and rect.position.y>20 and rect.end.x<1004 and rect.end.y<1004
			seen[hash(image.get_data())] = true
		check(good_margin, String(key)+" keeps complete drawings inside canvas")
		check(seen.size()==4, String(key)+" frames differ")
		visual.play(key)
		await create_timer(visual.duration(key)+0.2).timeout
		if key==&"idle":
			check(visual.sprite.is_playing(), "idle loop continues")
		else:
			check(visual.sprite.frame==3 and not visual.sprite.is_playing(), String(key)+" reaches final pose")
	visual.queue_free()
	await process_frame
	print("FAILURES: ",failures)
	quit(failures)
