extends SceneTree
## Renderiza os dois personagens em várias poses numa imagem, para conferir o encaixe das peças.
## Uso (com janela, não headless): Godot --script res://tools/preview_characters.gd -- <pasta de saída>

const POSES := ["Parado", "Corrida", "Mira diagonal + piscar", "Pulo", "Dash", "Abaixado"]
const ZOOM := 1.9
## Personagens mostrados (um por linha).
const KINDS := ["clown", "acrobat"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir: String = args[0]
	# Opcional: só um personagem, ampliado ("acrobat" ou "clown").
	var kinds: Array = [args[1]] if args.size() > 1 else KINDS
	var zoom := ZOOM * (1.15 if kinds.size() == 1 else 1.0)
	root.size = Vector2i(1920, 1080)
	var board := Node2D.new()
	root.add_child(board)
	var backdrop := ColorRect.new()
	backdrop.color = Color("efe0be")
	backdrop.size = Vector2(1920, 1080)
	board.add_child(backdrop)
	for row in kinds.size():
		var kind: String = kinds[row]
		for col in POSES.size():
			var rig: CharacterRig = load("res://core/player/characters/%s/%s_rig.tscn" % [kind, kind]).instantiate()
			rig.position = Vector2(110 + 320 * col, 500 if row == 0 else 1040) if kinds.size() > 1 else Vector2(170 + 640 * (col % 3), 520 + 540 * (col / 3))
			rig.scale *= zoom
			board.add_child(rig)
			var label := Label.new()
			label.text = POSES[col]
			label.position = Vector2(20 + 320 * col, 10 if row == 0 else 545) if kinds.size() > 1 else Vector2(20 + 640 * (col % 3), 10 + 540 * (col / 3))
			label.add_theme_color_override("font_color", Color("38291f"))
			label.add_theme_font_size_override("font_size", 24)
			board.add_child(label)
			var velocity := Vector2.ZERO
			var on_floor := true
			var dashing := false
			var crouching := false
			var aim := Vector2.RIGHT
			match col:
				1: velocity = Vector2(360, 0)
				2: aim = Vector2(1, -1).normalized()
				3:
					velocity = Vector2(160, -500)
					on_floor = false
				4:
					velocity = Vector2(900, 0)
					dashing = true
				5: crouching = true
			for frame in 12:
				rig.update_pose(1.0 / 60.0, velocity, on_floor, dashing, aim, 360.0, crouching)
			if col == 2:
				rig.get_node("Body/Head/Blink").show()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join("characters_%s.png" % "_".join(kinds)))
	print("PREVIEW_OK")
	quit()
