extends Node3D
## Mundo da Área 1 em 3D (a aventura): o parque do circo assombrado à noite, visto de cima numa câmera
## ortográfica inclinada e parada. As miniaturas 3D andam juntas pelas trilhas entre as atrações; entra-se
## andando até elas (WorldDoor). As lutas continuam 2D.
## Atrações: portão e carroção do Camarim, O Domador, carroção da Cartomante (loja), Os Malabaristas, a
## estação do Trem e a tenda grande do Grande Mágico, fechada até vencer os outros três.
## O cenário é a pintura de referência do parque (pedido do usuário em 05/10/2026), parada e ocupando a
## tela toda; a câmera ortográfica fica fixa e casa o chão do mundo com o chão pintado, então os bonecos
## andam por cima da imagem. Onde se anda é desenhado aqui em pixels da pintura (WALK_AREAS e
## WALK_TRAILS); as portas ficam nas entradas pintadas (DOOR_FRONTS). A lógica das portas não muda.
## Ao chegar aqui, o host salva o jogo.

const PAINTING := preload("res://levels/world/art/park_painted.jpg")
## Tamanho da pintura em pixels (as coordenadas abaixo são nela).
const IMAGE_SIZE := Vector2(1376, 768)
## Chão onde se anda: elipses [centro, raios] em pixels da pintura.
const WALK_AREAS: Array = [
	[Vector2(640, 540), Vector2(190, 95)],  # pátio do meio, logo depois do portão
	[Vector2(560, 445), Vector2(70, 25)],  # frente do carroção da Cartomante
	[Vector2(420, 545), Vector2(140, 40)],  # terra em cima do portão
	[Vector2(730, 420), Vector2(60, 40)],  # pé da subida
	[Vector2(175, 428), Vector2(80, 20)],  # frente do carroção do Camarim
	[Vector2(318, 203), Vector2(45, 14)],  # tapete do Domador
	[Vector2(715, 208), Vector2(45, 14)],  # tapete dos Malabaristas
	[Vector2(1090, 247), Vector2(60, 16)],  # tapete do Mágico
	[Vector2(1000, 405), Vector2(35, 18)],  # escada da estação
]
## Trilhas: [pontos em pixels da pintura, meia largura em pixels].
const WALK_TRAILS: Array = [
	[[Vector2(385, 768), Vector2(385, 660), Vector2(420, 600), Vector2(480, 545)], 40.0],  # portão
	[[Vector2(175, 428), Vector2(230, 460), Vector2(300, 495), Vector2(420, 520), Vector2(520, 530)], 30.0],  # Camarim
	[[Vector2(720, 440), Vector2(715, 340), Vector2(712, 240)], 28.0],  # subida para os Malabaristas
	[[Vector2(318, 205), Vector2(450, 218), Vector2(560, 228), Vector2(650, 245), Vector2(712, 250)], 17.0],
	[[Vector2(712, 250), Vector2(760, 280), Vector2(860, 282), Vector2(950, 276), Vector2(1000, 262),
		Vector2(1060, 250)], 12.0],  # atrás do elefante, até o Mágico
	[[Vector2(990, 265), Vector2(995, 330), Vector2(1000, 400)], 28.0],  # descida para a estação
	[[Vector2(760, 400), Vector2(870, 388), Vector2(990, 385)], 12.0],  # na frente do elefante
	[[Vector2(930, 262), Vector2(915, 180), Vector2(900, 110)], 20.0],  # trilha do fundo
	[[Vector2(700, 600), Vector2(720, 690), Vector2(730, 768)], 45.0],  # trilha de baixo
]
## Onde fica a frente de cada atração na pintura (o meio da área de entrada da porta).
const DOOR_FRONTS := {
	"DoorDressing": Vector2(175, 428),
	"DoorTamer": Vector2(318, 203),
	"DoorShop": Vector2(560, 445),
	"DoorJugglers": Vector2(715, 208),
	"DoorTrain": Vector2(1000, 405),
	"DoorMagician": Vector2(1090, 247),
}
## Sozinho: se o parceiro ficar mais longe que isto (preso numa curva), ele reaparece atrás de quem anda.
const FOLLOW_RESCUE := 5.0
## Rostos das plaquinhas de vida (recortes da arte da abertura): região de cada um.
const FACES := {
	"clown": [preload("res://core/ui/art/loading/clown.png"), Rect2(124, 27, 310, 230)],
	"acrobat": [preload("res://core/ui/art/loading/acrobat.png"), Rect2(176, 29, 247, 210)],
}
## Vida de cada um na luta (components/health) e o item que dá mais uma (core/player/player_loadout).
const BASE_HEALTH := 3
const EXTRA_HEALTH_PROP := "cloth_heart"

## Câmera: ortográfica e parada, inclinada como a vista da pintura, mostrando o parque inteiro.
const CAMERA_PITCH := -42.0
## Altura da vista em metros: a pintura inteira (os bonecos ficam com uns 12% da tela, como na referência).
const VIEW_HEIGHT := 15.5
## Distância da câmera ao meio do chão (só afasta os planos de corte; a imagem não muda).
const CAMERA_BACK := 40.0
## A pintura fica bem no fundo, atrás de tudo que está no chão.
const PAINTING_DISTANCE := 150.0

var _camera := Camera3D.new()
var _lives := {}
var _prompts := {}
var _prompt_layer := Control.new()
## Último ponto andável de cada boneco deste PC.
var _last_good := {}


func _ready() -> void:
	# Depois dos bonecos: segura quem saiu do chão pintado.
	process_physics_priority = 10
	if SaveGame.is_keeper():
		SaveGame.save_game()
	_build_environment()
	_build_floor()
	_place_doors()
	_seat_doors()
	_build_hud()
	_place_at_return_door()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = VIEW_HEIGHT
	_camera.near = 0.5
	_camera.far = PAINTING_DISTANCE + 10.0
	_camera.rotation_degrees = Vector3(CAMERA_PITCH, 0, 0)
	_camera.position = _camera.transform.basis.z * CAMERA_BACK
	add_child(_camera)
	_build_painting()
	_camera.make_current()


func _process(_delta: float) -> void:
	_update_hud()


func _physics_process(_delta: float) -> void:
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		if Network.is_online() and not walker.is_multiplayer_authority():
			continue
		_keep_on_ground(walker)
	if not Network.is_online():
		_rescue_follower()


func _unhandled_input(event: InputEvent) -> void:
	# Sozinho: Tab troca quem você controla (o outro segue).
	if Network.is_online():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
			walker.input.local_control = not walker.input.local_control
		get_viewport().set_input_as_handled()


## O chão é plano (o relevo está pintado).
func height_at(_x: float, _z: float) -> float:
	return 0.0


## Ponto da pintura (pixels) no chão do mundo: a câmera parada mira a origem no meio da tela, e cada
## pixel para baixo na tela anda 1/sen(inclinação) vezes mais no chão.
static func pixel_to_world(pixel: Vector2) -> Vector3:
	var meters := VIEW_HEIGHT / IMAGE_SIZE.y
	var rel := pixel - IMAGE_SIZE * 0.5
	return Vector3(rel.x * meters, 0.0, rel.y * meters / sin(deg_to_rad(-CAMERA_PITCH)))


static func world_to_pixel(point: Vector3) -> Vector2:
	var meters := VIEW_HEIGHT / IMAGE_SIZE.y
	return IMAGE_SIZE * 0.5 + Vector2(point.x / meters, point.z * sin(deg_to_rad(-CAMERA_PITCH)) / meters)


## Se o ponto (mundo) está no chão pintado onde se anda.
static func is_walkable(point: Vector3) -> bool:
	var pixel := world_to_pixel(point)
	for area: Array in WALK_AREAS:
		var d: Vector2 = (pixel - area[0]) / area[1]
		if d.length_squared() <= 1.0:
			return true
	for trail: Array in WALK_TRAILS:
		var points: Array = trail[0]
		for i in points.size() - 1:
			if pixel.distance_to(Geometry2D.get_closest_point_to_segment(pixel, points[i], points[i + 1])) <= trail[1]:
				return true
	return false


## O ponto andável mais perto (mundo), para quem nasceu ou foi posto fora do chão pintado.
static func nearest_walkable(point: Vector3) -> Vector3:
	if is_walkable(point):
		return point
	var pixel := world_to_pixel(point)
	var best := Vector2.ZERO
	var best_distance := INF
	for area: Array in WALK_AREAS:
		var d: Vector2 = (pixel - area[0]) / area[1]
		var inside: Vector2 = area[0] + (d.normalized() * 0.95 if d.length() > 0.95 else d) * area[1]
		if pixel.distance_to(inside) < best_distance:
			best_distance = pixel.distance_to(inside)
			best = inside
	for trail: Array in WALK_TRAILS:
		var points: Array = trail[0]
		for i in points.size() - 1:
			var on := Geometry2D.get_closest_point_to_segment(pixel, points[i], points[i + 1])
			if pixel.distance_to(on) < best_distance:
				best_distance = pixel.distance_to(on)
				best = on
	var result := pixel_to_world(best)
	return Vector3(result.x, point.y, result.z)


## Segura o boneco no chão pintado: escorrega pela beira (tenta só um dos eixos) ou volta ao último ponto bom.
func _keep_on_ground(walker: WorldWalker) -> void:
	var at := walker.global_position
	if is_walkable(at):
		_last_good[walker] = at
		return
	if not _last_good.has(walker):
		walker.global_position = nearest_walkable(at)
		_last_good[walker] = walker.global_position
		return
	var last: Vector3 = _last_good[walker]
	var along_x := Vector3(at.x, at.y, last.z)
	var along_z := Vector3(last.x, at.y, at.z)
	if is_walkable(along_x):
		walker.global_position = along_x
		walker.velocity.z = 0.0
	elif is_walkable(along_z):
		walker.global_position = along_z
		walker.velocity.x = 0.0
	else:
		walker.global_position = Vector3(last.x, at.y, last.z)
		walker.velocity.x = 0.0
		walker.velocity.z = 0.0
	_last_good[walker] = walker.global_position


## Sozinho: o parceiro que ficou preso longe reaparece logo atrás de quem você controla.
func _rescue_follower() -> void:
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	for leader: WorldWalker in walkers:
		if not leader.input.local_control:
			continue
		for other: WorldWalker in walkers:
			if other == leader or other.input.local_control:
				continue
			if other.global_position.distance_to(leader.global_position) > FOLLOW_RESCUE:
				var behind := leader.global_position - Vector3(leader.facing * WorldWalker.FOLLOW_DISTANCE, 0, 0)
				other.global_position = nearest_walkable(behind)
				_last_good[other] = other.global_position
		return


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
				walker.global_position = nearest_walkable(Vector3(front.x + side, 0.3, front.z))
				_last_good[walker] = walker.global_position
			side += 1.4
	Levels.return_door = ""


## A luz do cenário já está na imagem; esta só pinta os bonecos com o calor dos lampiões e o azul da noite.
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b1a24")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6f7f9a")
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var lamplight := DirectionalLight3D.new()
	lamplight.light_color = Color("ffc98a")
	lamplight.light_energy = 1.3
	lamplight.shadow_enabled = false
	lamplight.rotation_degrees = Vector3(-50, -25, 0)
	add_child(lamplight)


## Chão plano e invisível embaixo da pintura toda (quem segura os bonecos nas trilhas é _keep_on_ground).
func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 60)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)


## A pintura num quadrado no fundo da câmera, do tamanho exato da vista.
func _build_painting() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(VIEW_HEIGHT * IMAGE_SIZE.x / IMAGE_SIZE.y, VIEW_HEIGHT)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = PAINTING
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.disable_receive_shadows = true
	var painting := MeshInstance3D.new()
	painting.name = "Painting"
	painting.mesh = quad
	painting.material_override = material
	painting.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	painting.position = Vector3(0, 0, -PAINTING_DISTANCE)
	_camera.add_child(painting)


## Cada porta vai para a entrada pintada (a área de entrada fica em DOOR_FRONTS). O corpo da atração não
## bloqueia mais ninguém: a beira das trilhas pintadas é que segura os bonecos.
func _place_doors() -> void:
	for door in _doors():
		if DOOR_FRONTS.has(String(door.name)):
			var offset := door.front_point() - door.global_position
			door.position = pixel_to_world(DOOR_FRONTS[String(door.name)]) - Vector3(offset.x, 0, offset.z)
		for body: StaticBody3D in door.find_children("*", "StaticBody3D", true, false):
			body.collision_layer = 0


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


# ---------------------------------------------------------------- HUD: plaquinhas de latão
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 8
	add_child(hud)
	_prompt_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prompt_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_prompt_layer)
	var area := _plaque()
	area.position = Vector2(26, 22)
	var area_label := _plaque_label("ÁREA 1 — O GRANDE PICADEIRO" + ("  ·  MODO DE TESTE" if SaveGame.test_mode else ""), 27)
	area_label.add_theme_font_override("font", UiTheme.TITLE_FONT)
	area.add_child(area_label)
	hud.add_child(area)
	var lives := HBoxContainer.new()
	lives.add_theme_constant_override("separation", 14)
	lives.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lives.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lives.position = Vector2(-26, 18)
	hud.add_child(lives)
	for kind in ["clown", "acrobat"]:
		var plate := _plaque(Vector4(8, 4, 16, 4))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		plate.add_child(row)
		var face := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = FACES[kind][0]
		atlas.region = FACES[kind][1]
		face.texture = atlas
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2(62, 50)
		row.add_child(face)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", -8)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(column)
		var count := _plaque_label("x 03", 30)
		column.add_child(count)
		var tickets := _plaque_label("", 16)
		tickets.add_theme_color_override("font_color", UiTheme.GOLD)
		column.add_child(tickets)
		lives.add_child(plate)
		_lives[kind] = [count, tickets]


## Plaquinha escura com moldura dourada e um fio de latão por dentro.
func _plaque(margins := Vector4(18, 6, 18, 6)) -> PanelContainer:
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.06, 0.05, 0.9)
	box.border_color = Color("d2a95c")
	box.set_border_width_all(3)
	box.set_corner_radius_all(5)
	box.shadow_color = Color(0, 0, 0, 0.55)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = margins.x
	box.content_margin_top = margins.y
	box.content_margin_right = margins.z
	box.content_margin_bottom = margins.w
	plate.add_theme_stylebox_override("panel", box)
	return plate


func _plaque_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UiTheme.BODY_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f3e3c0"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	return label


func _update_hud() -> void:
	var players: Dictionary = SaveGame.data.get("players", {})
	for kind: String in _lives:
		var player: Dictionary = players.get(kind, {})
		var equipped: Dictionary = player.get("equipped", {})
		var health := BASE_HEALTH + (1 if equipped.get("prop", "") == EXTRA_HEALTH_PROP else 0)
		if SaveGame.test_mode:
			health = PlayerLoadout.TEST_HEALTH
		_lives[kind][0].text = "x %02d" % health
		_lives[kind][1].text = "%d ingressos" % int(player.get("tickets", 0))
	for door in _doors():
		_update_prompt(door)


## Aviso de cada porta: plaquinha flutuando acima da entrada ("J · Entrar", "Fechado", a nota).
func _update_prompt(door: WorldDoor) -> void:
	if not _prompts.has(door):
		var plate := _plaque(Vector4(10, 4, 14, 4))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		plate.add_child(row)
		var key := _plaque(Vector4(9, 0, 9, 0))
		(key.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color("f3e3c0")
		(key.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(2)
		var key_label := _plaque_label("", 22)
		key_label.add_theme_color_override("font_color", Color("1b1410"))
		key_label.add_theme_constant_override("outline_size", 0)
		key.add_child(key_label)
		row.add_child(key)
		var text := _plaque_label("", 24)
		row.add_child(text)
		_prompt_layer.add_child(plate)
		_prompts[door] = [plate, key, key_label, text]
	var parts: Array = _prompts[door]
	var plate: PanelContainer = parts[0]
	plate.visible = not door.status_text.is_empty()
	if not plate.visible:
		return
	var entering := door.status_kind == "enter"
	parts[1].visible = entering
	parts[2].text = WorldDoor._shoot_key_name()
	parts[3].text = "· Entrar" if entering else door.status_text
	parts[3].add_theme_color_override("font_color", Color("f3e3c0") if entering else door.status_color)
	var anchor := door.front_point() + Vector3(0, 2.6, -0.6)
	var ratio := _prompt_layer.size / get_viewport().get_visible_rect().size
	var at := _camera.unproject_position(anchor) * ratio
	plate.reset_size()
	plate.position = (at - Vector2(plate.size.x * 0.5, plate.size.y)).round()
