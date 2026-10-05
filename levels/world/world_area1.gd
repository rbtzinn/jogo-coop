extends Node3D
## Mundo da Área 1 em 3D (a aventura): o parque do circo assombrado à noite, visto de cima numa câmera
## ortográfica inclinada que acompanha a dupla. As miniaturas 3D andam juntas pelas trilhas entre as
## atrações; entra-se andando até elas (WorldDoor). As lutas continuam 2D.
## Roteiro: arco do portão e carroção do Camarim → O Domador → carroção da Cartomante (loja) →
## bifurcação: Os Malabaristas (norte) e a estação do Trem (leste) → as duas trilhas se juntam na tenda
## grande do Grande Mágico, fechada até vencer os outros três.
## O cenário é uma imagem renderizada no Blender (tools/blender/park_render.py), com a profundidade de
## cada pixel (PrerenderedBackdrop); aqui ficam só o chão com colisão, as portas e os bonecos.
## Ao chegar aqui, o host salva o jogo.

const BACKDROP_DATA := preload("res://levels/world/art/park_backdrop_data.gd")
const BACKDROP_COLOR := preload("res://levels/world/art/park_color.png")
const BACKDROP_DEPTH := preload("res://levels/world/art/park_depth.png")
## Rostos das plaquinhas de vida (recortes da arte da abertura): região de cada um.
const FACES := {
	"clown": [preload("res://core/ui/art/loading/clown.png"), Rect2(124, 27, 310, 230)],
	"acrobat": [preload("res://core/ui/art/loading/acrobat.png"), Rect2(176, 29, 247, 210)],
}
## Vida de cada um na luta (components/health) e o item que dá mais uma (core/player/player_loadout).
const BASE_HEALTH := 3
const EXTRA_HEALTH_PROP := "cloth_heart"

## Trilhas (pontos por onde a curva passa).
const PATHS: Array[PackedVector2Array] = [
	[Vector2(-16, 11.8), Vector2(-15.6, 8), Vector2(-13.2, 4.6), Vector2(-9, 3.2), Vector2(-4, 3.4),
		Vector2(0, 2.6), Vector2(4, 1.6), Vector2(8.2, 3.6), Vector2(12.5, 5.0)],
	[Vector2(4, 1.6), Vector2(5.6, -1.4), Vector2(7.5, -3.6)],
	[Vector2(7.5, -3.6), Vector2(11, -3.1), Vector2(14.6, -1.9), Vector2(17.5, -1.2)],
	[Vector2(12.5, 5.0), Vector2(15.6, 3.4), Vector2(17.5, -1.2)],
]
## Câmera: ortográfica, sempre do mesmo ângulo (o mesmo do Blender), seguindo o meio da dupla.
const CAMERA_PITCH := -42.0
## Altura da vista em metros (os bonecos ficam pequenos, com cerca de um sétimo da tela, como na referência).
const VIEW_HEIGHT := 15.5
## Distância da câmera ao ponto seguido (só afasta os planos de corte; a imagem não muda).
const CAMERA_BACK := 40.0
const CAMERA_SMOOTH := 3.5
## O meio da câmera fica um pouco à frente da dupla (para o fundo), onde estão as atrações.
const CAMERA_LEAD := Vector3(0, 0.0, -1.2)
## Lampiões (o Blender acende um em cada ponto).
const LAMPS: Array[Vector2] = [
	Vector2(-14.0, 7.6), Vector2(-10.2, 1.9), Vector2(-3.7, 1.9), Vector2(2.2, 0.6),
	Vector2(6.0, 4.4), Vector2(3.2, -1.8), Vector2(13.4, -0.4), Vector2(14.2, 6.2),
]

var _camera := Camera3D.new()
var _focus := Vector3.ZERO
var _terrain := WorldTerrain.new()
var _lives := {}
var _prompts := {}
var _prompt_layer := Control.new()
var _backdrop := PrerenderedBackdrop.new()


func _ready() -> void:
	if SaveGame.is_keeper():
		SaveGame.save_game()
	_build_environment()
	_build_terrain()
	_seat_doors()
	_build_hud()
	_place_at_return_door()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = VIEW_HEIGHT
	_camera.near = 0.5
	_camera.far = CAMERA_BACK * 3.0
	_camera.rotation_degrees = Vector3(CAMERA_PITCH, 0, 0)
	add_child(_camera)
	_backdrop.setup(_camera, BACKDROP_COLOR, BACKDROP_DEPTH, BACKDROP_DATA.DATA)
	_focus = _target_focus()
	_update_camera(1.0)
	_camera.make_current()


func _process(delta: float) -> void:
	# Bonecos (também os que chegam pela rede) ganham a silhueta para quando passam atrás do cenário.
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		if not walker.has_meta(&"silhouette") and walker.miniature.is_inside_tree():
			walker.set_meta(&"silhouette", true)
			_backdrop.mark.call_deferred(walker)
	_update_camera(1.0 - exp(-CAMERA_SMOOTH * delta))
	_update_hud()


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
	_camera.position = _focus + _camera.transform.basis.z * CAMERA_BACK


## Ponto seguido, preso para a vista nunca sair da imagem renderizada.
func _target_focus() -> Vector3:
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	var middle := Vector3(-15, 0, 9)
	if not walkers.is_empty():
		middle = Vector3.ZERO
		for walker: WorldWalker in walkers:
			middle += walker.global_position
		middle /= walkers.size()
	middle += CAMERA_LEAD
	var data: Dictionary = BACKDROP_DATA.DATA
	var up := Vector3(0, cos(deg_to_rad(-CAMERA_PITCH)), -sin(deg_to_rad(-CAMERA_PITCH)))
	var half := Vector2(VIEW_HEIGHT * 0.5 * _aspect(), VIEW_HEIGHT * 0.5)
	var origin: Array = data["origin"]
	var center_v := Vector3(origin[0], origin[1], origin[2]).dot(up)
	var v := clampf(middle.dot(up), center_v - data["size"][1] * 0.5 + half.y, center_v + data["size"][1] * 0.5 - half.y)
	var u := clampf(middle.x, origin[0] - data["size"][0] * 0.5 + half.x, origin[0] + data["size"][0] * 0.5 - half.x)
	# Mesmo ponto na tela: só muda a parte ao longo do olhar, que a vista ortográfica ignora.
	var forward := Vector3(0, -sin(deg_to_rad(-CAMERA_PITCH)), -cos(deg_to_rad(-CAMERA_PITCH)))
	return Vector3(u, 0, 0) + up * v + forward * middle.dot(forward)


func _aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	return size.x / maxf(size.y, 1.0)


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


func _build_terrain() -> void:
	for path in PATHS:
		_terrain.paths.append(path)
	for door: WorldDoor in _doors():
		_terrain.pads.append([Vector2(door.position.x, door.position.z), door.radius + 1.2])
	_terrain.pads.append([Vector2(-16, 9.5), 2.5])
	_terrain.draw = false
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
