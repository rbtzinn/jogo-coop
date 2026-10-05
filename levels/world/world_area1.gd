extends Node3D
## Mundo da Área 1 em 3D (a aventura): o parque do circo assombrado como uma maquete artesanal vista
## do alto, com câmera oblíqua fixa que acompanha a dupla. As miniaturas 3D andam juntas pelas trilhas
## de tábuas entre as atrações; entra-se andando até elas (WorldDoor). As lutas continuam 2D.
## Roteiro: arco do portão e carroção do Camarim → O Domador (com a jaula do leão) → barraca de
## Curiosidades → bifurcação: Os Malabaristas (norte) e a estação do Trem (leste) → as duas trilhas se
## juntam na tenda grande do Grande Mágico, fechada até vencer os outros três.
## Cenário montado por código (WorldTerrain, WorldProps). Ao chegar aqui, o host salva o jogo.

## Trilhas (pontos por onde a curva passa).
const PATHS: Array[PackedVector2Array] = [
	[Vector2(-16, 11.8), Vector2(-15.6, 8), Vector2(-13.2, 4.6), Vector2(-9, 3.2), Vector2(-4, 3.4),
		Vector2(0, 2.6), Vector2(4, 1.6), Vector2(8.2, 3.6), Vector2(12.5, 5.0)],
	[Vector2(4, 1.6), Vector2(5.6, -1.4), Vector2(7.5, -3.6)],
	[Vector2(7.5, -3.6), Vector2(11, -3.1), Vector2(14.6, -1.9), Vector2(17.5, -1.2)],
	[Vector2(12.5, 5.0), Vector2(15.6, 3.4), Vector2(17.5, -1.2)],
]
## Câmera: alta e inclinada, sempre do mesmo ângulo, seguindo o meio da dupla com suavidade.
const CAMERA_PITCH := -42.0
const CAMERA_DISTANCE := 9.4
const CAMERA_FOV := 34.0
const CAMERA_SMOOTH := 3.5
## O meio da câmera fica um pouco à frente da dupla (para o fundo), onde estão as atrações.
const CAMERA_LEAD := Vector3(0, 0.6, -1.0)
const CAMERA_X := Vector2(-16.5, 17.5)
const CAMERA_Z := Vector2(-10.0, 9.0)
const LAMPS: Array[Vector2] = [
	Vector2(-14.0, 7.6), Vector2(-10.2, 1.9), Vector2(-3.7, 1.9), Vector2(2.2, 0.6),
	Vector2(6.0, 4.4), Vector2(3.2, -1.8), Vector2(13.4, -0.4), Vector2(14.2, 6.2),
]
const TREES: Array[Vector3] = [
	Vector3(-20, 0, -9), Vector3(-15, 0, -10), Vector3(-1, 0, -11), Vector3(9, 0, -11.5),
	Vector3(20.5, 0, 7), Vector3(-20.5, 0, 3), Vector3(2.5, 0, 11), Vector3(-7.5, 0, 10.5),
	Vector3(17, 0, 11), Vector3(21, 0, -3), Vector3(-19, 0, 10.5), Vector3(11, 0, 10.5),
]

var _camera := Camera3D.new()
var _focus := Vector3.ZERO
var _terrain := WorldTerrain.new()
var _title: Label
var _tickets := Label.new()
var _time := 0.0
## Peças altas que podem ficar entre a câmera e a dupla: [raiz, x, z, altura, meia largura, malhas].
## Quando um personagem passa atrás delas, ficam meio transparentes (a colisão não muda).
var _occluders: Array = []


func _ready() -> void:
	if SaveGame.is_keeper():
		SaveGame.save_game()
	_build_environment()
	_build_terrain()
	_seat_doors()
	_build_props()
	_build_hud()
	_place_at_return_door()
	_camera.fov = CAMERA_FOV
	_camera.rotation_degrees = Vector3(CAMERA_PITCH, 0, 0)
	add_child(_camera)
	_focus = _target_focus()
	_update_camera(1.0)
	_camera.make_current()


func _process(delta: float) -> void:
	_time += delta
	_update_camera(1.0 - exp(-CAMERA_SMOOTH * delta))
	var players: Dictionary = SaveGame.data.get("players", {})
	_tickets.text = "Ingressos   Palhaço: %d   ·   Acrobata: %d" % [
		int(players.get("clown", {}).get("tickets", 0)), int(players.get("acrobat", {}).get("tickets", 0))]
	if _title != null:
		_title.modulate.a = clampf(1.0 - (_time - 3.0) / 1.5, 0.0, 1.0)
	_fade_occluders(delta)


func _unhandled_input(event: InputEvent) -> void:
	# Sozinho: Tab troca quem você controla (o outro segue).
	if Network.is_online():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
			walker.input.local_control = not walker.input.local_control
		get_viewport().set_input_as_handled()


func height_at(x: float, z: float) -> float:
	return _terrain.height_at(x, z)


func _update_camera(weight: float) -> void:
	_focus = _focus.lerp(_target_focus(), weight)
	var back := Vector3(0, sin(deg_to_rad(-CAMERA_PITCH)), cos(deg_to_rad(-CAMERA_PITCH))) * CAMERA_DISTANCE
	_camera.position = _focus + back


func _target_focus() -> Vector3:
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	var middle := Vector3(-15, 0, 9)
	if not walkers.is_empty():
		middle = Vector3.ZERO
		for walker: WorldWalker in walkers:
			middle += walker.global_position
		middle /= walkers.size()
	middle += CAMERA_LEAD
	middle.x = clampf(middle.x, CAMERA_X.x, CAMERA_X.y)
	middle.z = clampf(middle.z, CAMERA_Z.x, CAMERA_Z.y)
	return middle


## Voltando de uma luta: os personagens deste PC nascem na frente da atração por onde entraram.
func _place_at_return_door() -> void:
	if Levels.return_door.is_empty():
		return
	for door: WorldDoor in get_tree().get_nodes_in_group(&"world_doors"):
		if door.level_id != Levels.return_door:
			continue
		var front := door.front_point() + Vector3(0, 0, 0.8)
		var side := -0.7
		for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
			if not Network.is_online() or walker.is_multiplayer_authority():
				walker.global_position = Vector3(front.x + side, height_at(front.x + side, front.z) + 0.3, front.z)
			side += 1.4
	Levels.return_door = ""


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0e0a14")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("4c3f63")
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color("221a2e")
	env.fog_density = 0.018
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.06
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("a9b8ff")
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.shadow_blur = 1.6
	moon.directional_shadow_max_distance = 40.0
	moon.rotation_degrees = Vector3(-52, -38, 0)
	add_child(moon)


func _build_terrain() -> void:
	for path in PATHS:
		_terrain.paths.append(path)
	for door: WorldDoor in _doors():
		_terrain.pads.append([Vector2(door.position.x, door.position.z), door.radius + 1.2])
	_terrain.pads.append([Vector2(-16, 9.5), 2.5])
	add_child(_terrain)
	_terrain.build()
	# Cercas invisíveis na borda do mundo, logo por dentro da cerca de madeira da moldura.
	var half := _terrain.size * 0.5
	for wall in [Vector3(0, 1, -half.y + 2.2), Vector3(0, 1, half.y - 2.2),
			Vector3(-half.x + 2.2, 1, 0), Vector3(half.x - 2.2, 1, 0)]:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var wall_shape := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = Vector3(_terrain.size.x, 6, 1) if wall.x == 0 else Vector3(1, 6, _terrain.size.y)
		wall_shape.shape = wall_box
		body.add_child(wall_shape)
		body.position = wall
		add_child(body)


func _doors() -> Array[WorldDoor]:
	var doors: Array[WorldDoor] = []
	for child in get_children():
		if child is WorldDoor:
			doors.append(child)
	return doors


## As atrações e os pontos de nascimento ficam na altura do terreno.
func _seat_doors() -> void:
	for door in _doors():
		door.position.y = height_at(door.position.x, door.position.z)
	for marker in $PlayerSpawner.get_children():
		if marker is Marker3D:
			marker.position.y = height_at(marker.position.x, marker.position.z) + 0.4
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		walker.global_position.y = height_at(walker.global_position.x, walker.global_position.z) + 0.4


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, height_at(x, z), z)


func _build_props() -> void:
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	# Arco de entrada com lâmpadas e o letreiro do parque.
	var arch := WorldProps.arch(props, _ground(-15.8, 9.6), 4.0, 3.4)
	_add_occluder(arch, 4.2, 2.6)
	var sign_text := Label3D.new()
	sign_text.text = "O Grande Picadeiro"
	sign_text.font = UiTheme.TITLE_FONT
	sign_text.font_size = 72
	sign_text.pixel_size = 0.0045
	sign_text.outline_size = 12
	sign_text.modulate = Color("ffd27a")
	sign_text.outline_modulate = WorldProps.INK
	sign_text.position = Vector3(0, 3.7, 0.25)
	arch.add_child(sign_text)
	for lamp in LAMPS:
		_add_occluder(WorldProps.lamp_post(props, _ground(lamp.x, lamp.y)), 2.6, 0.7)
	# Árvores de copa redonda na moldura do parque e duas secas (o parque assombrado), arbustos nas
	# bordas do trecho do portão.
	for i in TREES.size():
		var t := TREES[i]
		# Na beira da frente (perto da câmera) só vegetação baixa, para a moldura não tapar a dupla.
		if t.z > 10.0:
			for k in 3:
				WorldProps.bush(props, _ground(t.x + (k - 1) * 0.9, 13.0 + (k % 2) * 0.4), 0.42 + 0.08 * (k % 2))
			continue
		if i % 5 == 4:
			_add_occluder(WorldProps.dead_tree(props, _ground(t.x, t.z), 3.4, i + 3), 3.6, 1.2)
		else:
			_add_occluder(WorldProps.leafy_tree(props, _ground(t.x, t.z), 3.0 + (i % 3) * 0.6, i + 3), 4.2, 1.6)
	for b in [Vector2(-18.2, 6.5), Vector2(-11.6, 6.4), Vector2(-15.2, -0.6), Vector2(-3.2, 6.2), Vector2(3.6, 5.6), Vector2(-9.8, -5.6)]:
		WorldProps.bush(props, _ground(b.x, b.y), 0.45)
	# Domador: a jaula do leão, fardos de palha e um pedestal listrado.
	WorldProps.cage(props, _ground(-11.6, -3.4), 0.25)
	WorldProps.haystack(props, _ground(-10.4, -0.4), 0.4)
	WorldProps.haystack(props, _ground(-4.6, -3.9), -0.3)
	var pedestal := WorldProps.cylinder(props, 0.6, 0.7, 0.7, WorldProps.stripes(Color("a3282a"), WorldProps.CREAM, 10.0, 0.02),
			_ground(-4.4, -1.6) + Vector3(0, 0.35, 0), Vector3.ZERO, 20)
	WorldProps.cylinder(pedestal, 0.65, 0.65, 0.08, WorldProps.paint(WorldProps.GOLD, 0.01), Vector3(0, 0.38, 0), Vector3.ZERO, 20)
	# Curiosidades: barris e caixotes em volta (a barraca traz os dela).
	WorldProps.barrel(props, _ground(1.6, -2.4))
	WorldProps.crate(props, _ground(2.3, -1.6), 0.4)
	# Malabaristas: pinos gigantes fincados e bolas empilhadas.
	WorldProps.juggling_pin(props, _ground(4.4, -6.2), Color("2e5c8a"), 0.25)
	WorldProps.juggling_pin(props, _ground(10.6, -6.8), Color("a3282a"), -0.3)
	var ball_colors := [Color("2e5c8a"), Color("e8b33a"), Color("a3282a")]
	for k in 3:
		var offset := Vector3(-0.35 + k * 0.7, 0.35, 0) if k < 2 else Vector3(0, 0.95, 0)
		WorldProps.sphere(props, Vector3(0.35, 0.35, 0.35), WorldProps.paint(ball_colors[k], 0.015), _ground(10.8, -4.6) + offset)
	# Estação: caixotes de carga.
	WorldProps.crate(props, _ground(9.2, 0.4), 0.0, 0.55)
	WorldProps.crate(props, _ground(9.3, -0.3), 0.3, 0.55)
	WorldProps.crate(props, _ground(9.25, 0.05) + Vector3(0, 0.55, 0), -0.2, 0.45)
	# Mágico: a cartola gigante com o coelho.
	WorldProps.magic_hat(props, _ground(13.4, -6.6))
	# Varais de bandeirolas no fundo, entre mastros, e cercas de corda ao longo das trilhas.
	var poles: Array[Vector2] = [Vector2(-13.6, -5.6), Vector2(-5.0, -5.2), Vector2(2.6, -4.6), Vector2(5.0, -9.0),
			Vector2(12.6, -9.4), Vector2(20.0, -8.6)]
	for p in poles:
		WorldProps.pole(props, _ground(p.x, p.y))
	for i in poles.size() - 1:
		var a := poles[i]
		var b := poles[i + 1]
		WorldProps.bunting(props, _ground(a.x, a.y) + Vector3(0, 4.0, 0), _ground(b.x, b.y) + Vector3(0, 4.0, 0), 0.7)
	WorldProps.bunting(props, _ground(-17.8, 9.6) + Vector3(0, 3.3, 0), _ground(-17.6, 3.5) + Vector3(0, 2.2, 0), 0.4)
	_fence_along(props, PATHS[0], 1.0, 0.04, 0.3)
	_fence_along(props, PATHS[0], -1.0, 0.1, 0.22)
	_fence_along(props, PATHS[0], 1.0, 0.42, 0.62)
	_fence_along(props, PATHS[3], 1.0, 0.0, 0.78)
	_build_border(props)
	# O acabamento do trecho pode ser desligado só para comparar com a baseline (`-- mundo_piloto <pasta> sem_trecho`).
	if not Engine.get_meta(&"mundo_sem_trecho", false):
		_dress_trail(props)
	var canopy := $DoorTrain.find_child("Canopy", true, false)
	if canopy:
		_add_occluder(canopy, 3.2, 2.4)
	# As tendas também ficam meio transparentes quando a dupla passa atrás delas.
	for door in _doors():
		if door.landmark in ["tent", "big_top", "lion_tent"]:
			_add_occluder(door, door.height + door.radius, door.radius)
	var train := $DoorTrain.find_child("Train", true, false)
	if train:
		_add_occluder(train, 2.6, 3.0)


## Moldura do parque: cerca de madeira velha nas quatro beiras (com falhas, o portão de entrada no sul
## e a passagem dos trilhos no leste), moitas de arbustos do lado de fora em grupos de tamanhos
## diferentes e, no fundo (norte, longe da câmera), fardos, barris e uma roda de carroça encostada.
func _build_border(props: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var half := _terrain.size * 0.5
	var sides := [
		[Vector2(-half.x + 2.6, half.y - 2.6), Vector2(half.x - 2.6, half.y - 2.6), Vector2(-18.6, -13.2)],
		[Vector2(-half.x + 2.6, -half.y + 2.6), Vector2(half.x - 2.6, -half.y + 2.6), Vector2.ZERO],
		[Vector2(-half.x + 2.6, -half.y + 2.6), Vector2(-half.x + 2.6, half.y - 2.6), Vector2.ZERO],
		[Vector2(half.x - 2.6, -half.y + 2.6), Vector2(half.x - 2.6, half.y - 2.6), Vector2(1.4, 4.4)],
	]
	for side in sides:
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		var gap: Vector2 = side[2]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var outward := Vector2(-dir.y, dir.x)
		if outward.dot(a) < 0.0:
			outward = -outward
		var run: Array[Vector3] = []
		var t := 0.0
		var left_in_run := rng.randi_range(4, 9)
		while t <= length:
			var p := a + dir * t + outward * rng.randf_range(-0.12, 0.12)
			var along := p.x if dir.x != 0.0 else p.y
			var in_gap := gap != Vector2.ZERO and along > minf(gap.x, gap.y) and along < maxf(gap.x, gap.y)
			if in_gap or left_in_run <= 0:
				if run.size() > 1:
					WorldProps.wood_fence(props, run, 4)
				run = []
				if not in_gap:
					t += rng.randf_range(1.2, 2.8)
					left_in_run = rng.randi_range(4, 9)
					continue
			else:
				run.append(_ground(p.x, p.y))
				left_in_run -= 1
			t += rng.randf_range(1.6, 2.0)
		if run.size() > 1:
			WorldProps.wood_fence(props, run, 4)
		# Arbustos do lado de fora, em moitas de 1 a 4.
		t = rng.randf_range(0.0, 2.0)
		while t <= length:
			var base := a + dir * t + outward * rng.randf_range(0.7, 1.5)
			for k in rng.randi_range(1, 4):
				var spot := base + dir * rng.randf_range(-0.8, 0.8) + outward * rng.randf_range(-0.2, 0.5)
				WorldProps.bush(props, _ground(spot.x, spot.y), rng.randf_range(0.3, 0.6))
			t += rng.randf_range(2.2, 5.0)
	# Fundo do parque.
	for spot in [Vector3(-8.2, 0.3, -11.6), Vector3(-7.2, -0.4, -11.9), Vector3(15.4, 0.2, -11.4)]:
		WorldProps.haystack(props, _ground(spot.x, spot.z), spot.y)
	for spot in [Vector2(1.8, -11.4), Vector2(2.4, -11.7)]:
		WorldProps.barrel(props, _ground(spot.x, spot.y))
	WorldProps.crate(props, _ground(3.0, -11.2), 0.5)
	var wheel := Node3D.new()
	props.add_child(wheel)
	wheel.position = _ground(-3.6, -11.9) + Vector3(0, 0.5, 0)
	wheel.rotation = Vector3(PI * 0.5 - 0.3, 0.4, 0)
	WorldProps.torus(wheel, 0.42, 0.52, WorldProps.paint(Color("6a3a20"), 0.012), Vector3.ZERO)
	for k in 6:
		WorldProps.box(wheel, Vector3(0.05, 0.05, 0.9), WorldProps.paint(WorldProps.WOOD), Vector3.ZERO, Vector3(0, TAU * k / 12.0, 0))


## Cerca de corda acompanhando um trecho da trilha, do lado `side`, entre as frações `from` e `to`.
func _fence_along(parent: Node3D, path: PackedVector2Array, side: float, from: float, to: float) -> void:
	var samples := WorldTerrain.sample_path(path, 0.2)
	var points: Array[Vector3] = []
	var spacing := 1.8
	var travelled := 0.0
	var total := 0.0
	for i in samples.size() - 1:
		total += samples[i].distance_to(samples[i + 1])
	var next := total * from
	for i in samples.size() - 1:
		var a := samples[i]
		var b := samples[i + 1]
		var seg := a.distance_to(b)
		while next <= travelled + seg and next <= total * to:
			var p := a.lerp(b, (next - travelled) / maxf(seg, 0.0001))
			var dir := (b - a).normalized()
			var normal := Vector2(-dir.y, dir.x) * side
			var at := p + normal * (_terrain.path_width * 0.5 + 0.5)
			points.append(_ground(at.x, at.y))
			next += spacing
		travelled += seg
	if points.size() > 1:
		WorldProps.wood_fence(parent, points, 3)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	_title = UiTheme.title_label("O Grande Picadeiro", 48, true)
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.position = Vector2(-450, 24)
	_title.size = Vector2(900, 70)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_title)
	_tickets.add_theme_font_override("font", UiTheme.BODY_FONT)
	_tickets.add_theme_font_size_override("font_size", 26)
	_tickets.add_theme_color_override("font_color", UiTheme.CREAM)
	_tickets.add_theme_color_override("font_outline_color", UiTheme.INK)
	_tickets.add_theme_constant_override("outline_size", 8)
	_tickets.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tickets.position = Vector2(-560, 18)
	_tickets.size = Vector2(530, 40)
	_tickets.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(_tickets)


func _add_occluder(root: Node3D, height: float, half_width: float) -> void:
	var meshes: Array = []
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		# As sombras de contato ficam como estão.
		if node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		if node is MeshInstance3D or node is MultiMeshInstance3D:
			var original: Material = node.material_override
			if original != null:
				meshes.append([node, original, WorldProps.ghost(original)])
	_occluders.append([root, height, half_width, meshes, false])


## Uma peça alta encobre o que está até altura / tan(ângulo da câmera) atrás dela (para o fundo).
## Com algum personagem nessa faixa, ela troca para a versão meio transparente; depois volta.
func _fade_occluders(_delta: float) -> void:
	var reach := 1.0 / tan(deg_to_rad(-CAMERA_PITCH))
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	for entry in _occluders:
		var root: Node3D = entry[0]
		var behind := 0.0
		for walker: WorldWalker in walkers:
			var dz := root.global_position.z - walker.global_position.z
			var dx := absf(root.global_position.x - walker.global_position.x)
			if dz > -0.4 and dz < entry[1] * reach and dx < entry[2] + 0.5:
				behind = 1.0
		var faded := behind > 0.5
		if faded != entry[4]:
			entry[4] = faded
			for item in entry[3]:
				item[0].material_override = item[2] if faded else item[1]
				item[0].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if faded else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Acabamento do trecho Camarim -> Barraca de Curiosidades (piloto 3D, 04/10/2026; o resto do parque fica para
## depois do piloto). Tudo em MultiMesh (poucas chamadas de desenho), com sorteio fixo (sempre igual):
## - pedrinhas de borda dos dois lados da trilha (3,5 a 10 cm, achatadas), de tamanhos e tons diferentes;
## - tufos de capim na beira (de 3 a 6 folhas, inclinadas para fora, 2 tons) e grupos de margaridas (o enfeite
##   do chapéu do palhaço), nunca em cima da trilha;
## - um varal de lâmpadas âmbar em zigue-zague sobre a trilha, do Camarim à Barraca, com duas luzes de verdade
##   (a luz quente vem de cima e de frente, e o rosto de quem passa por baixo acende);
## - uma placa de bifurcação (Camarim, O Domador, Curiosidades) como marco entre o Domador e a Barraca.
const TRAIL_X := Vector2(-14.0, 1.2)


func _dress_trail(props: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41004
	var samples := WorldTerrain.sample_path(PATHS[0], 0.32)
	var stones: Array = [[], [], []]
	var grass: Array = [[], []]
	var petals: Array[Transform3D] = []
	var hearts: Array[Transform3D] = []
	var half: float = _terrain.path_width * 0.5
	for i in range(1, samples.size() - 1):
		var p := samples[i]
		if p.x < TRAIL_X.x or p.x > TRAIL_X.y:
			continue
		var dir := (samples[i + 1] - samples[i - 1]).normalized()
		var normal := Vector2(-dir.y, dir.x)
		for side: float in [-1.0, 1.0]:
			# Pedras: nem toda amostra ganha uma (falhas naturais), tamanhos de 6 a 16 cm.
			if rng.randf() < 0.78:
				var at := p + normal * side * (half + rng.randf_range(-0.05, 0.12)) + dir * rng.randf_range(-0.1, 0.1)
				var size := rng.randf_range(0.035, 0.1)
				var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(size * rng.randf_range(1.0, 1.6), size * rng.randf_range(0.35, 0.55), size))
				(stones[rng.randi() % 3] as Array).append(Transform3D(basis, _ground(at.x, at.y) + Vector3(0, size * 0.2, 0)))
			# Capim: tufos de 3 a 6 folhas, inclinadas para fora da trilha.
			if rng.randf() < 0.55:
				var at := p + normal * side * (half + rng.randf_range(0.2, 0.9))
				var blades := rng.randi_range(3, 6)
				var tone := rng.randi() % 2
				var out_axis := Vector3(normal.x * side, 0, normal.y * side).cross(Vector3.UP).normalized()
				for k in blades:
					var lean := Basis(out_axis, rng.randf_range(0.15, 0.55))
					var height := rng.randf_range(0.16, 0.34)
					var basis := Basis(Vector3.UP, rng.randf() * TAU) * lean * Basis.from_scale(Vector3(0.025, height, 0.025))
					var offset := Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08))
					(grass[tone] as Array).append(Transform3D(basis, _ground(at.x, at.y) + offset + basis * Vector3(0, 0.5, 0)))
			# Margaridas em grupos de 2 a 5, de vez em quando.
			if rng.randf() < 0.16:
				var center := p + normal * side * (half + rng.randf_range(0.35, 1.2))
				for k in rng.randi_range(2, 5):
					var at := center + Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
					var ground := _ground(at.x, at.y) + Vector3(0, rng.randf_range(0.05, 0.12), 0)
					var tilt := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
					petals.append(Transform3D(tilt * Basis.from_scale(Vector3(0.075, 0.012, 0.075)), ground))
					hearts.append(Transform3D(tilt * Basis.from_scale(Vector3(0.028, 0.02, 0.028)), ground + tilt * Vector3(0, 0.012, 0)))
	var stone := SphereMesh.new()
	stone.radius = 1.0
	stone.height = 2.0
	stone.radial_segments = 7
	stone.rings = 4
	var stone_colors := [Color("8a8478"), Color("6f6a64"), Color("7d7a5c")]
	for k in 3:
		var list: Array[Transform3D] = []
		list.assign(stones[k])
		WorldProps.scatter(props, list, stone, stone_colors[k])
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 1.0
	blade.height = 1.0
	blade.radial_segments = 3
	blade.rings = 1
	var grass_colors := [Color("4f6b34"), Color("6d7f3a")]
	for k in 2:
		var list: Array[Transform3D] = []
		list.assign(grass[k])
		WorldProps.scatter(props, list, blade, grass_colors[k])
	var disc := SphereMesh.new()
	disc.radius = 1.0
	disc.height = 2.0
	disc.radial_segments = 10
	disc.rings = 3
	WorldProps.scatter(props, petals, disc, Color("f6f1e4"))
	WorldProps.scatter(props, hearts, disc, Color("f2c230"))
	# Varal de lâmpadas: do Camarim a um mastro do outro lado da trilha, de lá ao poste do Domador e à Barraca.
	var south := _ground(-7.0, 5.0)
	var mast := Node3D.new()
	props.add_child(mast)
	WorldProps.pole(mast, south, 3.4)
	_add_occluder(mast, 3.4, 0.4)
	WorldProps.festoon(props, _ground(-12.2, 2.4) + Vector3(0, 2.9, 0), south + Vector3(0, 3.3, 0), 0.45, 0.45, 1)
	WorldProps.festoon(props, south + Vector3(0, 3.3, 0), _ground(-3.7, 1.9) + Vector3(0, 2.55, 0), 0.4, 0.45, 1)
	WorldProps.festoon(props, _ground(-3.7, 1.9) + Vector3(0, 2.55, 0), _ground(-0.6, 1.2) + Vector3(0, 2.4, 0), 0.25, 0.45, 0)
	# Placa de bifurcação.
	var signpost := Node3D.new()
	props.add_child(signpost)
	signpost.position = _ground(-5.3, 1.9)
	WorldProps.cylinder(signpost, 0.05, 0.06, 1.9, WorldProps.paint(WorldProps.WOOD_DARK, 0.01), Vector3(0, 0.95, 0), Vector3.ZERO, 8)
	WorldProps.contact_shadow(signpost, 0.3)
	# Tábuas viradas para a câmera (o texto sempre de frente), cada uma para o lado da atração, com um leve giro.
	var boards := [["Camarim", -1.0, 1.6, Color("6b3c7a")], ["O Domador", -1.0, 1.3, Color("a3282a")], ["Curiosidades", 1.0, 1.0, Color("1f5a66")]]
	for b: Array in boards:
		var arm := Node3D.new()
		signpost.add_child(arm)
		arm.position = Vector3(b[1] * 0.62, b[2], 0.06)
		arm.rotation.y = b[1] * 0.18
		WorldProps.box(arm, Vector3(1.2, 0.24, 0.05), WorldProps.paint(b[3], 0.01), Vector3.ZERO)
		var text := Label3D.new()
		text.text = b[0]
		text.font = UiTheme.TITLE_FONT
		text.font_size = 48
		text.pixel_size = 0.004
		text.outline_size = 8
		text.modulate = Color("ffe6b0")
		text.outline_modulate = WorldProps.INK
		text.position = Vector3(0, 0, 0.03)
		arm.add_child(text)
