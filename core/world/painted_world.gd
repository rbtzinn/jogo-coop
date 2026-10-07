class_name PaintedWorld
extends Node3D
## Mundo de uma área (a aventura): o mapa pintado da área, visto de cima numa câmera ortográfica inclinada que
## acompanha a dupla. Os personagens (desenhos da luta, menores) andam juntos pelas trilhas entre as atrações;
## entra-se andando até elas (WorldDoor). As lutas continuam 2D. Cada área é uma cena com este script e as
## portas dela (levels/world/world_area1.tscn, world_area2.tscn).
## O cenário é o mapa pintado em quatro partes 2 x 2 (docs/prompts/claude_integrar_mapa_4partes.md,
## 05/10/2026), montadas numa malha só no fundo da câmera; a tela mostra uma região por vez e a câmera revela o
## resto conforme a dupla anda. O chão do mundo casa com o chão pintado (cada pixel do conjunto vira um ponto no
## chão). Onde se anda vem de uma máscara da estrada pintada (park_walk.png, feita por
## tools/blender/park_walk_mask.py; volcano_walk.png, por tools/area2_walk_mask.py); quem bate na beira
## escorrega por ela. Cada porta fica na entrada pintada (WorldDoor.painted_front).
## Ao chegar aqui, o host salva o jogo (com a área atual).

const FRONT_SHADER := preload("res://shaders/painted_front.gdshader")

## Número da área (fica no save: é para onde "Voltar ao mapa" e o menu levam).
@export var area := 1
## Nome na plaquinha do canto.
@export var area_title := ""
## As quatro partes do mapa, na ordem noroeste, nordeste, sudoeste, sudeste.
@export var parts: Array[Texture2D] = []
## Estrada onde se anda (branco), na metade da resolução do conjunto.
@export var walk_mask: Texture2D
## O que é alto no desenho e a linha do pé de cada pedaço (tools/front_layer.py): quem anda atrás some atrás
## da pedra. Vazio = os bonecos ficam sempre na frente da pintura.
@export var front_layer: Texture2D
## Quantos pixels do conjunto cabem na altura da vista (os personagens têm sempre o mesmo tamanho na tela; um
## número maior mostra mais do mapa). Área 1: 620 de 941 (a arte tem só 1672 x 941).
@export var view_pixels := 620.0
## Luz dos bonecos (a do cenário já está pintada): o fundo, a luz ambiente e a luz quente dos lampiões.
@export var background_color := Color("0b1a24")
@export var ambient_color := Color("6f7f9a")
@export var lamp_color := Color("ffc98a")

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
## Distância da câmera ao ponto seguido (só afasta os planos de corte; a imagem não muda).
const CAMERA_BACK := 40.0
const CAMERA_SMOOTH := 6.0
## A pintura fica atrás de tudo que está no chão, a esta distância do chão ao longo do olhar.
const PAINTING_DEPTH := 30.0
## Margem (metros) que cada personagem deste PC guarda da beira da tela (os dois sempre na vista).
const SCREEN_MARGIN := Vector2(1.0, 1.4)
## Quando bate na beira, procura o ponto andável mais perto do desejado até esta distância (pixels da máscara).
const SLIDE_SEARCH := 8
## Ângulos (graus) que o passo gira para acompanhar a beira, do menor para o maior.
const SLIDE_ANGLES := [15.0, 30.0, 45.0, 60.0, 75.0, 85.0]

## Tamanho do conjunto em pixels (as quatro partes juntas).
var image_size := Vector2.ZERO
var _walk_image: Image

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
	image_size = parts[0].get_size() + parts[3].get_size()
	if SaveGame.is_keeper():
		SaveGame.data.area = area
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
	# Sozinho: Tab troca de personagem (o palhaço vira a acrobata e vice-versa, no mesmo lugar; a escolha fica
	# no save). Offline dos testes, com os dois: troca quem você controla (o outro segue).
	if Network.is_online():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		if PlayerSpawner.solo_slot >= 0:
			swap_solo_character()
		else:
			for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
				walker.input.local_control = not walker.input.local_control
		get_viewport().set_input_as_handled()


## Sozinho: troca o personagem por outro, no mesmo lugar.
func swap_solo_character() -> void:
	var old: WorldWalker = get_tree().get_first_node_in_group(&"walkers")
	if old == null or get_tree().get_first_node_in_group(&"blocking_ui") != null:
		return
	var at := old.global_position
	var facing := old.facing
	_last_good.erase(old)
	old.remove_from_group(&"walkers")
	old.queue_free()
	PlayerSpawner.solo_slot = 1 - PlayerSpawner.solo_slot
	SaveGame.data.solo_character = PlayerSpawner.solo_slot
	SaveGame.save_game()
	var spawner: PlayerSpawner = $PlayerSpawner
	var walker: WorldWalker = spawner.spawn_solo(PlayerSpawner.solo_slot)
	walker.global_position = at
	walker.facing = facing


## O chão é plano (o relevo está pintado).
func height_at(_x: float, _z: float) -> float:
	return 0.0


## Metros de chão (na tela) por pixel do conjunto.
func meters_per_pixel() -> float:
	return VIEW_HEIGHT / view_pixels


## Ponto do conjunto (pixels) no chão do mundo: o meio do conjunto fica na origem, e cada pixel para baixo
## na tela anda 1/sen(inclinação) vezes mais no chão. Uma transformação só para as quatro partes.
func pixel_to_world(pixel: Vector2) -> Vector3:
	var rel := (pixel - image_size * 0.5) * meters_per_pixel()
	return Vector3(rel.x, 0.0, rel.y / sin(deg_to_rad(-CAMERA_PITCH)))


func world_to_pixel(point: Vector3) -> Vector2:
	return image_size * 0.5 + Vector2(point.x, point.z * sin(deg_to_rad(-CAMERA_PITCH))) / meters_per_pixel()


func _mask() -> Image:
	if _walk_image == null:
		_walk_image = walk_mask.get_image()
		if _walk_image.is_compressed():
			_walk_image.decompress()
	return _walk_image


## Se o pixel da máscara (metade da resolução do conjunto) é terra onde se anda.
func _walkable_cell(cell: Vector2i) -> bool:
	var mask := _mask()
	if cell.x < 0 or cell.y < 0 or cell.x >= mask.get_width() or cell.y >= mask.get_height():
		return false
	return mask.get_pixelv(cell).r > 0.5


func _cell_of(point: Vector3) -> Vector2i:
	var pixel := world_to_pixel(point) * float(_mask().get_width()) / image_size.x
	return Vector2i(floori(pixel.x), floori(pixel.y))


## O ponto dentro do pixel `cell` da máscara mais perto de `point` (a beira do pixel, não o meio: escorregar
## pela beira fica contínuo, sem pular de pixel em pixel).
func _closest_in_cell(cell: Vector2i, point: Vector3) -> Vector3:
	var scale := image_size.x / float(_mask().get_width())
	var low := pixel_to_world((Vector2(cell) + Vector2(0.02, 0.02)) * scale)
	var high := pixel_to_world((Vector2(cell) + Vector2(0.98, 0.98)) * scale)
	return Vector3(clampf(point.x, low.x, high.x), point.y, clampf(point.z, low.z, high.z))


## Se o ponto (mundo) está no chão pintado onde se anda.
func is_walkable(point: Vector3) -> bool:
	return _walkable_cell(_cell_of(point))


## O ponto andável mais perto (mundo), procurando em volta até `reach` pixels da máscara (INF se não achar
## nada: devolve o próprio ponto).
func nearest_walkable(point: Vector3, reach := 200) -> Vector3:
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
	if is_walkable(at):
		if at != walker.global_position:
			walker.global_position = at
		_last_good[walker] = at
		return
	var near := nearest_walkable(at, SLIDE_SEARCH)
	if not is_walkable(near):
		near = _last_good.get(walker, nearest_walkable(at))
	elif _last_good.has(walker) and not is_walkable(_inside_view(near)):
		near = _last_good[walker]
	near = Vector3(near.x, at.y, near.z)
	var from: Vector3 = _last_good.get(walker, near)
	var wish := Vector3(at.x - from.x, 0, at.z - from.z)
	# Também tenta deslizar acompanhando a beira (o passo girado para os lados) e fica com o que mais avança
	# para onde ele queria ir: numa beira inclinada o ponto andável mais perto podia ser o próprio lugar dele, e
	# o boneco travava (curva da frente da mina, 07/10/2026).
	var slid := _slide_along_edge(from, at)
	if slid != Vector3.INF and (slid - from).dot(wish) > (near - from).dot(wish):
		near = slid
	# A velocidade passa a seguir o caminho que ele de fato fez pela beira (desliza sem perder o embalo; parado
	# contra a beira, para).
	var moved := Vector3(near.x - from.x, 0, near.z - from.z)
	var flat := Vector3(walker.velocity.x, 0, walker.velocity.z)
	if moved.length_squared() > 0.0000001:
		var along := moved.normalized()
		flat = along * maxf(flat.dot(along), 0.0)
	else:
		flat = Vector3.ZERO
	walker.velocity = Vector3(flat.x, walker.velocity.y, flat.z)
	walker.global_position = near
	_last_good[walker] = near


## Desliza pela beira: de `from` (andável) querendo ir a `to` (fora da estrada), o passo girado para os lados
## em ângulos crescentes, encolhido pelo quanto girou (só a parte do movimento que segue a beira). Devolve o
## primeiro ponto andável e na tela, ou Vector3.INF se nenhum servir.
func _slide_along_edge(from: Vector3, to: Vector3) -> Vector3:
	var step := Vector3(to.x - from.x, 0, to.z - from.z)
	if step.length_squared() < 0.000001:
		return Vector3.INF
	for degrees in SLIDE_ANGLES:
		var angle := deg_to_rad(degrees)
		for side in [1.0, -1.0]:
			var turned := step.rotated(Vector3.UP, angle * side) * cos(angle)
			var point := Vector3(from.x + turned.x, to.y, from.z + turned.z)
			if is_walkable(point) and _inside_view(point) == point:
				return point
	return Vector3.INF


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
func _screen_coords(point: Vector3) -> Vector2:
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
	var half_map := image_size * 0.5 * meters_per_pixel()
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
	env.background_color = background_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var lamplight := DirectionalLight3D.new()
	lamplight.light_color = lamp_color
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
	var corner := pixel_to_world(image_size)
	box.size = Vector3(corner.x * 2.0 + 10.0, 1, corner.z * 2.0 + 10.0)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)


## As quatro partes numa malha só, cada uma com o seu material, num plano de frente para a câmera atrás do chão.
## Os cantos vêm da mesma conta (pixel_to_world) para as quatro: as partes vizinhas dividem exatamente os
## mesmos vértices, sem vão nem sobreposição. A textura não repete (sem borda puxada do outro lado).
func _build_painting() -> void:
	add_child(_painting_mesh("Painting", PAINTING_DEPTH, _painting_material))
	if front_layer != null:
		add_child(_painting_mesh("Front", PAINTING_DEPTH - 1.0, _front_material))


func _painting_mesh(mesh_name: String, depth: float, material_for: Callable) -> MeshInstance3D:
	var basis := _camera.transform.basis
	var behind := -basis.z * depth
	var up := basis.y
	var mesh := ArrayMesh.new()
	var corners := [Vector2.ZERO, Vector2(parts[0].get_width(), 0), Vector2(0, parts[0].get_height()), parts[0].get_size()]
	for index in parts.size():
		var texture: Texture2D = parts[index]
		var corner: Vector2 = corners[index]
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
		st.set_material(material_for.call(texture, corner))
		st.commit(mesh)
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.extra_cull_margin = 100.0
	return instance


func _painting_material(texture: Texture2D, _corner: Vector2) -> Material:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.texture_repeat = false
	material.disable_receive_shadows = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## A mesma parte, só com o que é alto no desenho, na profundidade do pé de cada pedaço (shaders/painted_front).
func _front_material(texture: Texture2D, corner: Vector2) -> Material:
	var material := ShaderMaterial.new()
	material.shader = FRONT_SHADER
	material.set_shader_parameter("albedo", texture)
	material.set_shader_parameter("front", front_layer)
	material.set_shader_parameter("part_corner", corner)
	material.set_shader_parameter("part_size", texture.get_size())
	material.set_shader_parameter("image_size", image_size)
	material.set_shader_parameter("meters_per_pixel", meters_per_pixel())
	material.set_shader_parameter("sin_pitch", sin(deg_to_rad(-CAMERA_PITCH)))
	return material


## Cada porta vai para a entrada pintada (o meio da área de entrada fica em painted_front).
func _place_doors() -> void:
	for door in _doors():
		if door.painted_front.x >= 0.0:
			var offset := door.front_point() - door.global_position
			door.position = pixel_to_world(door.painted_front) - Vector3(offset.x, 0, offset.z)


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
	var area_label := _plaque_label(area_title + ("  ·  MODO DE TESTE" if SaveGame.test_mode else ""), 27)
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
	var pieces: Array = _prompts[door]
	var plate: PanelContainer = pieces[0]
	plate.visible = not door.status_text.is_empty()
	if not plate.visible:
		return
	var entering := door.status_kind == "enter"
	pieces[1].visible = entering
	pieces[2].text = WorldDoor._shoot_key_name()
	pieces[3].text = "· " + door.enter_label if entering else door.status_text
	pieces[3].add_theme_color_override("font_color", Color("f3e3c0") if entering else door.status_color)
	var anchor := door.front_point() + Vector3(0, 2.6, -0.6)
	var ratio := _prompt_layer.size / get_viewport().get_visible_rect().size
	var at := _camera.unproject_position(anchor) * ratio
	plate.reset_size()
	plate.position = (at - Vector2(plate.size.x * 0.5, plate.size.y)).round()
