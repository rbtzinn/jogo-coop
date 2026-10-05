extends Node3D
## Mundo da Área 1 em 3D (a aventura): o parque do circo assombrado à noite, visto de cima numa câmera
## ortográfica inclinada que acompanha a dupla. Os personagens (desenhos da luta, menores) andam juntos pelas
## trilhas entre as atrações; entra-se andando até elas (WorldDoor). As lutas continuam 2D.
## Atrações: portão e carroção do Camarim, O Domador, carroção da Cartomante (loja), Os Malabaristas, a
## estação do Trem e a tenda grande do Grande Mágico, fechada até vencer os outros três.
## O cenário é o mapa ampliado pintado em quatro partes 2 x 2 (docs/prompts/claude_integrar_mapa_4partes.md,
## 05/10/2026), montadas numa malha só no fundo da câmera; a tela mostra uma região por vez e a câmera revela o
## resto conforme a dupla anda. O chão do mundo casa com o chão pintado (cada pixel do conjunto vira um ponto no
## chão). Onde se anda vem de uma máscara da terra pintada (park_walk.png, feita por
## tools/blender/park_walk_mask.py); quem bate na beira escorrega por ela. As portas ficam nas entradas
## pintadas (DOOR_FRONTS). A lógica das portas não muda.
## Ao chegar aqui, o host salva o jogo.

## As quatro partes do mapa e o canto de cima à esquerda de cada uma no conjunto (pixels).
const PARTS: Array = [
	[preload("res://levels/world/art/park_01_noroeste.png"), Vector2(0, 0)],
	[preload("res://levels/world/art/park_02_nordeste.png"), Vector2(836, 0)],
	[preload("res://levels/world/art/park_03_sudoeste.png"), Vector2(0, 470)],
	[preload("res://levels/world/art/park_04_sudeste.png"), Vector2(836, 470)],
]
## Tamanho do conjunto em pixels (a linha de baixo tem 471 de altura).
const IMAGE_SIZE := Vector2(1672, 941)
## Terra onde se anda (branco), na metade da resolução do conjunto.
const WALK_MASK := preload("res://levels/world/art/park_walk.png")
## Onde fica a frente de cada atração no conjunto (o meio da área de entrada da porta).
const DOOR_FRONTS := {
	"DoorDressing": Vector2(250, 545),
	"DoorTamer": Vector2(362, 212),
	"DoorShop": Vector2(592, 598),
	"DoorJugglers": Vector2(1022, 214),
	"DoorTrain": Vector2(1350, 728),
	"DoorMagician": Vector2(1418, 290),
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

## Câmera: ortográfica, inclinada como a vista da pintura, seguindo o meio da dupla.
const CAMERA_PITCH := -42.0
## Altura da vista em metros (os personagens ficam com uns 12% da tela).
const VIEW_HEIGHT := 15.5
## Quantos pixels do conjunto cabem na altura da vista: 620 de 941 (cerca de dois terços na altura e 1100 de 1672
## na largura). Ampliação de 1,74 na janela de 1080 linhas: a arte tem só 1672 x 941.
const VIEW_PIXELS := 620.0
## Distância da câmera ao ponto seguido (só afasta os planos de corte; a imagem não muda).
const CAMERA_BACK := 40.0
const CAMERA_SMOOTH := 6.0
## A pintura fica atrás de tudo que está no chão, a esta distância do chão ao longo do olhar.
const PAINTING_DEPTH := 30.0
## Margem (metros) que cada personagem deste PC guarda da beira da tela (os dois sempre na vista).
const SCREEN_MARGIN := Vector2(1.0, 1.4)
## Quando bate na beira, procura o ponto andável mais perto do desejado até esta distância (pixels da máscara).
const SLIDE_SEARCH := 8

static var _walk_image: Image

var _camera := Camera3D.new()
var _focus := Vector3.ZERO
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
	_camera.far = CAMERA_BACK + PAINTING_DEPTH + 20.0
	_camera.rotation_degrees = Vector3(CAMERA_PITCH, 0, 0)
	add_child(_camera)
	_build_painting()
	_focus = _target_focus()
	_update_camera(1.0)
	_camera.make_current()


func _process(delta: float) -> void:
	_update_camera(1.0 - exp(-CAMERA_SMOOTH * delta))
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


## Metros de chão (na tela) por pixel do conjunto.
static func meters_per_pixel() -> float:
	return VIEW_HEIGHT / VIEW_PIXELS


## Ponto do conjunto (pixels) no chão do mundo: o meio do conjunto fica na origem, e cada pixel para baixo
## na tela anda 1/sen(inclinação) vezes mais no chão. Uma transformação só para as quatro partes.
static func pixel_to_world(pixel: Vector2) -> Vector3:
	var rel := (pixel - IMAGE_SIZE * 0.5) * meters_per_pixel()
	return Vector3(rel.x, 0.0, rel.y / sin(deg_to_rad(-CAMERA_PITCH)))


static func world_to_pixel(point: Vector3) -> Vector2:
	return IMAGE_SIZE * 0.5 + Vector2(point.x, point.z * sin(deg_to_rad(-CAMERA_PITCH))) / meters_per_pixel()


static func _mask() -> Image:
	if _walk_image == null:
		_walk_image = WALK_MASK.get_image()
		if _walk_image.is_compressed():
			_walk_image.decompress()
	return _walk_image


## Se o pixel da máscara (metade da resolução do conjunto) é terra onde se anda.
static func _walkable_cell(cell: Vector2i) -> bool:
	var mask := _mask()
	if cell.x < 0 or cell.y < 0 or cell.x >= mask.get_width() or cell.y >= mask.get_height():
		return false
	return mask.get_pixelv(cell).r > 0.5


static func _cell_of(point: Vector3) -> Vector2i:
	var pixel := world_to_pixel(point) * float(_mask().get_width()) / IMAGE_SIZE.x
	return Vector2i(floori(pixel.x), floori(pixel.y))


## O ponto dentro do pixel `cell` da máscara mais perto de `point` (a beira do pixel, não o meio: escorregar
## pela beira fica contínuo, sem pular de pixel em pixel).
static func _closest_in_cell(cell: Vector2i, point: Vector3) -> Vector3:
	var scale := IMAGE_SIZE.x / float(_mask().get_width())
	var low := pixel_to_world((Vector2(cell) + Vector2(0.02, 0.02)) * scale)
	var high := pixel_to_world((Vector2(cell) + Vector2(0.98, 0.98)) * scale)
	return Vector3(clampf(point.x, low.x, high.x), point.y, clampf(point.z, low.z, high.z))


## Se o ponto (mundo) está no chão pintado onde se anda.
static func is_walkable(point: Vector3) -> bool:
	return _walkable_cell(_cell_of(point))


## O ponto andável mais perto (mundo), procurando em volta até `reach` pixels da máscara (INF se não achar
## nada: devolve o próprio ponto).
static func nearest_walkable(point: Vector3, reach := 200) -> Vector3:
	if is_walkable(point):
		return point
	var center := _cell_of(point)
	for radius in range(1, reach + 1):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var cell := center + Vector2i(dx, dy)
				if _walkable_cell(cell):
					var distance := _closest_in_cell(cell, point).distance_squared_to(point)
					if distance < best_distance:
						best_distance = distance
						best = cell
		if best.x >= 0:
			return _closest_in_cell(best, point)
	return point


## Segura o boneco no chão pintado e na tela. Bateu na beira: vai para o ponto andável mais perto de onde
## queria ir (escorrega pela beira, também em curvas e na diagonal), em vez de voltar para trás e travar.
func _keep_on_ground(walker: WorldWalker) -> void:
	var at := _inside_view(walker.global_position)
	if not is_walkable(at):
		var near := nearest_walkable(at, SLIDE_SEARCH)
		if not is_walkable(near):
			near = _last_good.get(walker, nearest_walkable(at))
		elif _last_good.has(walker) and not is_walkable(_inside_view(near)):
			near = _last_good[walker]
		at = Vector3(near.x, at.y, near.z)
	if at != walker.global_position:
		# Tira só a parte da velocidade que empurrava para fora; o resto continua (desliza).
		var pushed := Vector3(at.x - walker.global_position.x, 0, at.z - walker.global_position.z)
		if pushed.length_squared() > 0.000001:
			var normal := pushed.normalized()
			var into := Vector3(walker.velocity.x, 0, walker.velocity.z).dot(-normal)
			if into > 0.0:
				walker.velocity += normal * into
		walker.global_position = at
	_last_good[walker] = walker.global_position


## O ponto preso dentro da vista da câmera (com margem): os dois ficam sempre na tela.
func _inside_view(point: Vector3) -> Vector3:
	var half := Vector2(VIEW_HEIGHT * 0.5 * _aspect(), VIEW_HEIGHT * 0.5) - SCREEN_MARGIN
	var center := _screen_coords(_target_focus())
	var at := _screen_coords(point)
	var held := Vector2(clampf(at.x, center.x - half.x, center.x + half.x), clampf(at.y, center.y - half.y, center.y + half.y))
	if held == at:
		return point
	return Vector3(held.x, point.y, -held.y / sin(deg_to_rad(-CAMERA_PITCH)))


## Posição na tela (metros: x para a direita, y para cima) de um ponto no chão.
static func _screen_coords(point: Vector3) -> Vector2:
	return Vector2(point.x, -point.z * sin(deg_to_rad(-CAMERA_PITCH)))


func _aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	return size.x / maxf(size.y, 1.0)


func _update_camera(weight: float) -> void:
	_focus = _focus.lerp(_target_focus(), weight)
	_camera.position = _focus + _camera.transform.basis.z * CAMERA_BACK


## Ponto seguido (no chão): o meio da dupla, preso para a vista nunca sair do conjunto pintado.
func _target_focus() -> Vector3:
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	var middle := Vector3.ZERO
	for walker: WorldWalker in walkers:
		middle += walker.global_position
	if not walkers.is_empty():
		middle /= walkers.size()
	var half_view := Vector2(VIEW_HEIGHT * 0.5 * _aspect(), VIEW_HEIGHT * 0.5)
	var half_map := IMAGE_SIZE * 0.5 * meters_per_pixel()
	var at := _screen_coords(middle)
	at.x = clampf(at.x, -half_map.x + half_view.x, half_map.x - half_view.x) if half_map.x > half_view.x else 0.0
	at.y = clampf(at.y, -half_map.y + half_view.y, half_map.y - half_view.y) if half_map.y > half_view.y else 0.0
	return Vector3(at.x, 0.0, -at.y / sin(deg_to_rad(-CAMERA_PITCH)))


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


## As quatro partes numa malha só, cada uma com o seu material, num plano de frente para a câmera atrás do chão.
## Os cantos vêm da mesma conta (pixel_to_world) para as quatro: as partes vizinhas dividem exatamente os
## mesmos vértices, sem vão nem sobreposição. A textura não repete (sem borda puxada do outro lado).
func _build_painting() -> void:
	var basis := _camera.transform.basis
	var behind := -basis.z * PAINTING_DEPTH
	var up := basis.y
	var mesh := ArrayMesh.new()
	for part: Array in PARTS:
		var texture: Texture2D = part[0]
		var corner: Vector2 = part[1]
		var size := texture.get_size()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(basis.z)
		var points := [corner, corner + Vector2(size.x, 0), corner + size, corner + Vector2(0, size.y)]
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		var vertices := []
		for p: Vector2 in points:
			# O ponto do chão desse pixel, levado ao plano da pintura ao longo do olhar (mesmo lugar na tela).
			var ground := pixel_to_world(p)
			var screen := _screen_coords(ground)
			vertices.append(Vector3(screen.x, 0, 0) + up * screen.y + behind)
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uvs[k])
			st.add_vertex(vertices[k])
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		material.texture_repeat = false
		material.disable_receive_shadows = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		st.set_material(material)
		st.commit(mesh)
	var painting := MeshInstance3D.new()
	painting.name = "Painting"
	painting.mesh = mesh
	painting.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	painting.extra_cull_margin = 100.0
	add_child(painting)


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
