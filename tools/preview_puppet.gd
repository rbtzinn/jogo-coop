extends SceneTree
## Confere o boneco novo do palhaço (CharacterPuppet) em imagens. Uso (com janela):
##   Godot --path . --script res://tools/preview_puppet.gd -- <pasta>
## puppet.png: antigo e novo lado a lado, sobrepostos e o novo mirando em várias direções.
## movimento.png: o novo correndo, pulando, pousando e abaixando, um quadro a cada 4 da física (60 por segundo).

const CLOWN := preload("res://core/player/characters/clown/clown_rig.tscn")
const ZOOM := 2.2
const AIMS := [Vector2.RIGHT, Vector2(1, -1), Vector2.UP, Vector2(1, 1)]
## Pulo do Player (altura 270 em 0,38 s; queda 1,4x mais pesada).
const JUMP_SPEED := -1421.0
const GRAVITY := 3740.0
const CELL := Vector2i(300, 360)
const COLUMNS := 8


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1920, 1080)
	var bg := ColorRect.new()
	bg.color = Color("efe0be")
	bg.size = Vector2(1920, 1080)
	root.add_child(bg)
	await _side_by_side(out)
	await _motion(out)
	quit()


func _side_by_side(out: String) -> void:
	var rigs: Array[Array] = []
	rigs.append([_rig(Vector2(200, 520), false, 1.0), Vector2.RIGHT])
	rigs.append([_rig(Vector2(520, 520), true, 1.0), Vector2.RIGHT])
	rigs.append([_rig(Vector2(860, 520), false, 0.45), Vector2.RIGHT])
	rigs.append([_rig(Vector2(860, 520), true, 0.6), Vector2.RIGHT])
	for i in AIMS.size():
		rigs.append([_rig(Vector2(1200 + 230 * (i % 3), 520 if i < 3 else 1020), true, 1.0), AIMS[i].normalized()])
	for frame in 30:
		for pair in rigs:
			pair[0].update_pose(1.0 / 60.0, Vector2.ZERO, true, false, pair[1], 520.0)
		await process_frame
	root.get_texture().get_image().save_png(out.path_join("puppet.png"))
	for pair in rigs:
		pair[0].queue_free()


## Corre 0,6 s, pula, cai, pousa, para e abaixa; guarda um quadro a cada 4.
func _motion(out: String) -> void:
	var rig := _rig(Vector2(960, 900), true, 1.0)
	var sheet := Image.create(CELL.x * COLUMNS, CELL.y * 4, false, Image.FORMAT_RGBA8)
	var velocity := Vector2.ZERO
	var height := 0.0
	var on_floor := true
	var crouching := false
	var shot := 0
	for frame in 128:
		var t := frame / 60.0
		velocity.x = minf(velocity.x + 7000.0 / 60.0, 520.0) if t < 1.3 else maxf(velocity.x - 7000.0 / 60.0, 0.0)
		if frame == 36:
			velocity.y = JUMP_SPEED
			on_floor = false
		if not on_floor:
			velocity.y += GRAVITY * (1.4 if velocity.y > 0.0 else 1.0) / 60.0
			height -= velocity.y / 60.0
			if height <= 0.0:
				height = 0.0
				velocity.y = 0.0
				on_floor = true
				rig.play_land()
		crouching = t > 1.6
		rig.position.y = 900 - height * 0.4
		rig.update_pose(1.0 / 60.0, velocity, on_floor, false, Vector2.RIGHT, 520.0, crouching)
		await process_frame
		if frame % 4 == 0 and shot < COLUMNS * 4:
			var image := root.get_texture().get_image()
			var corner := Vector2i(rig.position) - Vector2i(CELL.x / 2, CELL.y - 20)
			sheet.blit_rect(image, Rect2i(corner, CELL), Vector2i(shot % COLUMNS, shot / COLUMNS) * CELL)
			shot += 1
	sheet.save_png(out.path_join("movimento.png"))


func _rig(at: Vector2, puppet: bool, alpha: float) -> CharacterRig:
	var rig: CharacterRig = CLOWN.instantiate()
	rig.use_puppet = puppet
	rig.position = at
	rig.scale *= ZOOM * (0.6 if at.y == 900 else 1.0)
	rig.modulate.a = alpha
	root.add_child(rig)
	return rig
