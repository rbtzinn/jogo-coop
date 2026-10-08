extends SceneTree
## Etapa 0 do rig novo (docs/animacao_rig.md): confere se o tronco em malha (Skeleton2D + Polygon2D com pesos)
## deforma no renderer do jogo e se a mangueira pintada (HoseLimb) dobra sem emendas. Peças provisórias.
## Uso (com janela, não headless): Godot --path . --script res://tools/puppet_spike.gd -- <pasta de saída>

const TORSO := preload("res://core/player/characters/clown/clown_torso.png")
const HEAD := preload("res://core/player/characters/clown/clown_head.png")
## Poses do tronco: [nome, giro do quadril, da barriga, do peito, escala do quadril].
const POSES := [
	["Neutro", 0.0, 0.0, 0.0, Vector2.ONE],
	["Dobra frente", 0.0, 0.25, 0.3, Vector2.ONE],
	["Dobra trás", 0.0, -0.2, -0.25, Vector2.ONE],
	["Espremido", 0.0, 0.0, 0.0, Vector2(0.8, 1.2)],
	["Esticado", 0.0, 0.0, 0.0, Vector2(1.15, 0.85)],
]
const GRID := Vector2i(6, 8)


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
	for i in POSES.size():
		_torso(Vector2(120 + 370 * i, 120), POSES[i])
	var strip := _strip_texture()
	var bends := [Vector2.ZERO, Vector2(40, 0), Vector2(90, 0), Vector2(-70, 30)]
	for i in bends.size():
		var hose := HoseLimb.new()
		hose.texture = strip
		hose.width = 36.0
		hose.taper = 0.8
		hose.position = Vector2(250 + 420 * i, 640)
		root.add_child(hose)
		hose.set_points(Vector2.ZERO, Vector2(i * 40, 300 - i * 50), bends[i])
	for i in 5:
		await process_frame
	root.get_texture().get_image().save_png(out.path_join("spike.png"))
	print("salvo: ", out.path_join("spike.png"), " renderer: ", RenderingServer.get_current_rendering_driver_name())
	quit()


func _torso(at: Vector2, pose: Array) -> void:
	var size := TORSO.get_size()
	var skeleton := Skeleton2D.new()
	skeleton.position = at
	root.add_child(skeleton)
	# Corrente de baixo para cima (o osso aponta para +x, girado para cima).
	var hips := _bone("Hips", Vector2(size.x * 0.5, size.y), -PI * 0.5, size.y * 0.33)
	skeleton.add_child(hips)
	var belly := _bone("Belly", Vector2(size.y * 0.33, 0), 0.0, size.y * 0.33)
	hips.add_child(belly)
	var chest := _bone("Chest", Vector2(size.y * 0.33, 0), 0.0, size.y * 0.33)
	belly.add_child(chest)
	var head := Sprite2D.new()
	head.texture = HEAD
	head.rotation = PI * 0.5
	head.position = Vector2(size.y * 0.33 + 70, 0)
	chest.add_child(head)
	for bone: Bone2D in [hips, belly, chest]:
		bone.rest = bone.transform

	var poly := Polygon2D.new()
	poly.texture = TORSO
	var points := PackedVector2Array()
	for y in GRID.y + 1:
		for x in GRID.x + 1:
			points.append(Vector2(size.x * x / GRID.x, size.y * y / GRID.y))
	poly.polygon = points
	poly.uv = points
	var quads := []
	for y in GRID.y:
		for x in GRID.x:
			var a := y * (GRID.x + 1) + x
			quads.append(PackedInt32Array([a, a + 1, a + GRID.x + 2, a + GRID.x + 1]))
	poly.polygons = quads
	skeleton.add_child(poly)
	poly.skeleton = poly.get_path_to(skeleton)
	# Peso de cada osso cai com a distância (em altura) até o meio dele.
	var centers := [size.y * 0.83, size.y * 0.5, size.y * 0.17]
	var bones := ["Hips", "Hips/Belly", "Hips/Belly/Chest"]
	var weights := [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
	for p in points:
		var raw := []
		var total := 0.0
		for c: float in centers:
			var w := maxf(0.0, 1.0 - absf(p.y - c) / (size.y * 0.33))
			raw.append(w)
			total += w
		for b in 3:
			weights[b].append(raw[b] / maxf(total, 0.001))
	for b in 3:
		poly.add_bone(NodePath(bones[b]), weights[b])

	hips.rotation += pose[1]
	belly.rotation += pose[2]
	chest.rotation += pose[3]
	hips.scale = pose[4]
	var label := Label.new()
	label.text = pose[0]
	label.add_theme_color_override(&"font_color", Color.BLACK)
	label.position = at + Vector2(40, size.y + 30)
	root.add_child(label)


func _bone(bone_name: String, pos: Vector2, rot: float, length: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = pos
	bone.rotation = rot
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(length)
	return bone


## Faixa provisória: xadrez vermelho e creme com contorno nas laterais (a de verdade vem do ChatGPT).
func _strip_texture() -> Texture2D:
	var image := Image.create(32, 160, false, Image.FORMAT_RGBA8)
	for y in 160:
		for x in 32:
			var color := Color("e91717") if (x / 8 + y / 16) % 2 == 0 else Color("f9eedd")
			if x < 4 or x >= 28:
				color = Color("0d0806")
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
