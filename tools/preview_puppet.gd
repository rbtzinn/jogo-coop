extends SceneTree
## Compara o palhaço antigo (quadros) com o boneco novo (CharacterPuppet) numa imagem: lado a lado, sobrepostos e
## o novo mirando em várias direções. Uso (com janela): Godot --path . --script res://tools/preview_puppet.gd -- <pasta>

const CLOWN := preload("res://core/player/characters/clown/clown_rig.tscn")
const ZOOM := 2.2
const AIMS := [Vector2.RIGHT, Vector2(1, -1), Vector2.UP, Vector2(1, 1)]


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
	var rigs: Array[Array] = []
	rigs.append([_rig(Vector2(200, 520), false, 1.0), Vector2.RIGHT])
	rigs.append([_rig(Vector2(520, 520), true, 1.0), Vector2.RIGHT])
	rigs.append([_rig(Vector2(860, 520), false, 0.45), Vector2.RIGHT])
	rigs.append([_rig(Vector2(860, 520), true, 0.6), Vector2.RIGHT])
	for i in AIMS.size():
		rigs.append([_rig(Vector2(1200 + 230 * (i % 3), 520 if i < 3 else 1020), true, 1.0), AIMS[i].normalized()])
	rigs.append([_rig(Vector2(330, 1020), true, 1.0), Vector2.RIGHT])
	for frame in 30:
		for pair in rigs:
			var rig: CharacterRig = pair[0]
			if frame == 25 and rig == rigs[-1][0]:
				rig.play_land()
				rig.play_fire()
			rig.update_pose(1.0 / 60.0, Vector2.ZERO, true, false, pair[1], 520.0)
		await process_frame
	root.get_texture().get_image().save_png(out.path_join("puppet.png"))
	quit()


func _rig(at: Vector2, puppet: bool, alpha: float) -> CharacterRig:
	var rig: CharacterRig = CLOWN.instantiate()
	rig.use_puppet = puppet
	rig.position = at
	rig.scale *= ZOOM
	rig.modulate.a = alpha
	root.add_child(rig)
	return rig
