extends SceneTree
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	print(("OK " if ok else "FAIL ")+label)
	if not ok: failures += 1

func _run() -> void:
	var demo: Node2D = load("res://bosses/madame_carretel/carretel_attack_visual.tscn").instantiate()
	root.add_child(demo)
	demo.paused = true
	var frames: SpriteFrames = demo.FX
	check(frames.get_animation_names().size()==6,"six effect sequences loaded")
	for key in frames.get_animation_names():
		var seen := {}
		var margins := true
		for i in 4:
			var image := frames.get_frame_texture(key,i).get_image()
			if image.is_compressed(): image.decompress()
			var rect := image.get_used_rect()
			margins = margins and image.get_size()==Vector2i(1024,1024) and rect.position.x>20 and rect.position.y>20 and rect.end.x<1004 and rect.end.y<1004
			seen[hash(image.get_data())] = true
		check(margins,String(key)+" has complete art / >20px margins")
		check(seen.size()==4,String(key)+" has four distinct frames")
		# Needle + tape + button loops are native SpriteFrames, not static props.
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		root.add_child(sprite)
		sprite.play(key)
		await create_timer(0.18).timeout
		check(sprite.frame>0,String(key)+" animates in engine")
		sprite.queue_free()
	for key in demo.ATTACKS:
		demo.play_attack(key)
		var warning: float = demo.ATTACKS[key].warning
		var active: float = demo.ATTACKS[key].active
		check(warning>=0.85,String(key)+" has readable advance warning")
		demo.seek(warning-0.001)
		var hidden := true
		for effect in demo.effects: hidden = hidden and not effect.visible
		check(hidden and demo.phase==&"warning",String(key)+" no projectile before warning")
		demo.seek(warning+0.20)
		check(demo.effects[0].visible and demo.visual.sprite.frame==2,String(key)+" release synchronized with boss pose")
		var first: Vector2 = demo.effects[0].position
		demo.seek(warning+minf(0.72,active*0.8))
		check(demo.effects[0].visible,String(key)+" attack remains visible during motion")
		if key in [&"needles",&"parry",&"armor_attack"]:
			check(demo.effects[0].position.x<first.x-100.0,String(key)+" visibly travels left")
		if key==&"cloth":
			check(demo.effects[0].frame==2 and demo.effects[0].position==first,"curtain fully unfolds without moving rail")
		if key==&"parry":
			check(demo.effects[0].animation==&"needle_parry","parry has its own turquoise/star art")
		demo.seek(warning+active+0.001)
		hidden = true
		for effect in demo.effects: hidden = hidden and not effect.visible
		check(hidden and demo.phase==&"recovery",String(key)+" no lingering hazards after recovery")
	# All visible pixels stay inside the stage viewport for every sampled moment.
	demo.position = Vector2(1530,930)
	for key in demo.ATTACKS:
		demo.play_attack(key)
		var contained := true
		for sample in 180:
			demo.seek(float(sample)*demo.duration(key)/180.0)
			var body_image: Image = demo.visual.sprite.sprite_frames.get_frame_texture(demo.visual.sprite.animation,demo.visual.sprite.frame).get_image()
			if body_image.is_compressed(): body_image.decompress()
			var body_used := Rect2(body_image.get_used_rect())
			var body_at: Vector2 = demo.position+demo.visual.sprite.position
			var body_a := body_at+body_used.position-Vector2(512,512)
			var body_b := body_at+body_used.end-Vector2(512,512)
			contained = contained and body_a.x>20 and body_a.y>260 and body_b.x<1900 and body_b.y<960
			for sprite in demo.effects:
				if not sprite.visible: continue
				var image: Image = frames.get_frame_texture(sprite.animation,sprite.frame).get_image()
				if image.is_compressed(): image.decompress()
				var used := Rect2(image.get_used_rect())
				for corner in [used.position,Vector2(used.end.x,used.position.y),used.end,Vector2(used.position.x,used.end.y)]:
					var point: Vector2 = sprite.global_transform*(corner-Vector2(512,512))
					contained = contained and point.x>20 and point.y>260 and point.x<1900 and point.y<960
		check(contained,String(key)+" never clips against screen or interface")
	demo.queue_free()
	await process_frame
	print("FAILURES: ",failures)
	quit(failures)
