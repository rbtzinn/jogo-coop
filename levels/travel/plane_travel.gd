extends Control
## A viagem de avião entre as áreas (pedido do usuário em 06/10/2026): o avião com a dupla passa voando pela
## tela, da esquerda para a direita, e sai do outro lado; depois aparece "Para onde vocês querem ir?" com um
## cartão para cada área. Entra-se aqui pelo avião estacionado no mapa de cada área (WorldDoor "plane"); ao
## chegar, a dupla nasce na frente do avião da área escolhida.
## Online, qualquer um dos dois escolhe: o cliente pede e o host leva os dois (como nas tendas).
## A arte do voo vem do pedido E2 (docs/prompts/chatgpt_aviao.md), em levels/travel/art/; enquanto não chega,
## o avião, o céu e a fumaça são provisórios, desenhados por código, com as mesmas medidas.

const ART := "res://levels/travel/art/"
## Folha do voo: 4 x 2 quadros de 768 x 512, o avião virado para a direita no meio de cada quadro.
const PLANE_SHEET := ART + "aviao_voando.png"
const PLANE_FRAMES := Vector2i(4, 2)
const PLANE_FPS := 10.0
## Fumaça: 4 quadros de 256 x 256 numa fileira.
const SMOKE_SHEET := ART + "fumaca.png"
const SKY := ART + "ceu.png"
## Faixa de nuvens que passa na frente do avião (repete lado a lado).
const FRONT_CLOUDS := ART + "nuvens_frente.png"
## Cartão de cada área: nome e miniatura do mapa.
const AREAS := {
	1: ["Área 1 — O Grande Picadeiro", preload("res://levels/travel/art/area1.png")],
	2: ["Área 2 — A Ilha do Vulcão", preload("res://levels/travel/art/area2.png")],
}

## Quanto tempo o avião leva para atravessar a tela (segundos).
const FLIGHT_TIME := 3.6
## Altura do voo (meio do avião) e quanto ele sobe e desce.
const FLIGHT_Y := 500.0
const BOB := 34.0
## Uma nuvem de fumaça a cada tanto, saindo da cauda; cada uma dura isto.
const SMOKE_EVERY := 0.11
const SMOKE_LIFE := 1.0
const FRONT_CLOUDS_SPEED := 900.0

var _time := 0.0
var _smoke_time := 0.0
var _flying := true
var _plane := Node2D.new()
var _plane_sprite := Sprite2D.new()
var _smoke_layer := Node2D.new()
var _front_clouds: TextureRect
var _menu: Control
var _note := Label.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	_build_sky()
	add_child(_smoke_layer)
	add_child(_plane)
	if ResourceLoader.exists(PLANE_SHEET):
		_plane_sprite.texture = load(PLANE_SHEET)
		_plane_sprite.hframes = PLANE_FRAMES.x
		_plane_sprite.vframes = PLANE_FRAMES.y
		_plane.add_child(_plane_sprite)
	else:
		_plane.add_child(PlanePlaceholder.new())
	if ResourceLoader.exists(FRONT_CLOUDS):
		_front_clouds = TextureRect.new()
		_front_clouds.texture = load(FRONT_CLOUDS)
		_front_clouds.stretch_mode = TextureRect.STRETCH_TILE
		_front_clouds.size = Vector2(_screen().x * 2.0 + 1920.0, 400)
		_front_clouds.position = Vector2(0, _screen().y - 400)
		add_child(_front_clouds)
	_place_plane()


func _process(delta: float) -> void:
	_time += delta
	if _front_clouds != null:
		_front_clouds.position.x = -fmod(_time * FRONT_CLOUDS_SPEED, 1920.0)
	if not _flying:
		return
	_place_plane()
	_smoke_time -= delta
	if _smoke_time <= 0.0:
		_smoke_time = SMOKE_EVERY
		_puff()
	if _time >= FLIGHT_TIME:
		_end_flight()


func _unhandled_input(event: InputEvent) -> void:
	# Atirar ou confirmar pula o voo.
	if _flying and (event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"shoot")):
		get_viewport().set_input_as_handled()
		_end_flight()


func _screen() -> Vector2:
	return get_viewport_rect().size


## O avião atravessa a tela subindo e descendo, com o nariz acompanhando a subida.
func _place_plane() -> void:
	var t := clampf(_time / FLIGHT_TIME, 0.0, 1.0)
	var wave := _time * 2.6
	_plane.position = Vector2(lerpf(-520.0, _screen().x + 520.0, t), FLIGHT_Y + sin(wave) * BOB)
	_plane.rotation = -cos(wave) * 0.07
	if _plane_sprite.texture != null:
		_plane_sprite.frame = int(_time * PLANE_FPS) % (PLANE_FRAMES.x * PLANE_FRAMES.y)


## Uma nuvem de fumaça na cauda, que fica para trás, cresce e some.
func _puff() -> void:
	var puff: Node2D
	if ResourceLoader.exists(SMOKE_SHEET):
		var sprite := Sprite2D.new()
		sprite.texture = load(SMOKE_SHEET)
		sprite.hframes = 4
		puff = sprite
	else:
		puff = SmokePlaceholder.new()
	puff.position = _plane.position + Vector2(-300, 10).rotated(_plane.rotation)
	puff.scale = Vector2.ONE * 0.45
	_smoke_layer.add_child(puff)
	var tween := puff.create_tween().set_parallel()
	tween.tween_property(puff, "position", puff.position + Vector2(-140, -30), SMOKE_LIFE)
	tween.tween_property(puff, "scale", Vector2.ONE * 0.9, SMOKE_LIFE)
	tween.tween_property(puff, "modulate:a", 0.0, SMOKE_LIFE).set_ease(Tween.EASE_IN)
	if puff is Sprite2D:
		tween.tween_property(puff, "frame", 3, SMOKE_LIFE)
	tween.chain().tween_callback(puff.queue_free)


func _end_flight() -> void:
	if not _flying:
		return
	_flying = false
	_plane.hide()
	_show_menu()


# ---------------------------------------------------------------- escolha do destino
func _show_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_menu)
	UiTheme.backdrop(_menu)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	var question := "Para onde vocês querem ir?" if Network.is_online() or PlayerSpawner.solo_slot < 0 else "Para onde você quer ir?"
	column.add_child(UiTheme.title_label(question, 52, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	var current := int(SaveGame.data.get("area", 1))
	var target: Button
	for area: int in AREAS:
		var button := Button.new()
		button.name = "Area%d" % area
		button.text = AREAS[area][0] + ("\n(de volta)" if area == current else "")
		button.icon = AREAS[area][1]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size = Vector2(520, 400)
		button.pressed.connect(_choose.bind(area))
		row.add_child(button)
		# Começa no destino que não é a área de onde saíram.
		if area != current and target == null:
			target = button
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override("font_color", UiTheme.INK_SOFT)
	_note.add_theme_font_size_override("font_size", 24)
	column.add_child(_note)
	(target if target != null else row.get_child(0) as Button).grab_focus()


## Um dos dois escolheu: o host (ou sozinho) leva a dupla; o cliente pede ao host.
func _choose(area: int) -> void:
	for button in _menu.find_children("Area*", "Button", true, false):
		(button as Button).disabled = true
	_note.text = "Decolando..."
	if Network.is_online() and not Network.is_host():
		_request_area.rpc_id(1, area)
	else:
		fly_to(area)


@rpc("any_peer", "call_remote", "reliable")
func _request_area(area: int) -> void:
	if Network.is_host() and AREAS.has(area):
		fly_to(area)


## Host (ou sozinho): muda a área do save e leva os dois ao mapa dela, na frente do avião.
func fly_to(area: int) -> void:
	SaveGame.data.area = area
	if SaveGame.is_keeper():
		SaveGame.save_game()
	Levels.return_door = "plane"
	Network.change_level(Levels.MAPS[area])


func _build_sky() -> void:
	if ResourceLoader.exists(SKY):
		var sky := TextureRect.new()
		sky.texture = load(SKY)
		sky.set_anchors_preset(Control.PRESET_FULL_RECT)
		sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(sky)
		return
	var sky := SkyPlaceholder.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)


## Céu provisório: entardecer roxo e laranja, mar escuro e nuvens redondas.
class SkyPlaceholder:
	extends Control

	func _draw() -> void:
		var area := get_rect().size
		var top := Color("2a1838")
		var low := Color("d0703c")
		for i in 24:
			var y := area.y * 0.76 * i / 24.0
			draw_rect(Rect2(0, y, area.x, area.y * 0.76 / 24.0 + 1.0), top.lerp(low, float(i) / 23.0))
		draw_rect(Rect2(0, area.y * 0.76, area.x, area.y * 0.24), Color("1b1f33"))
		draw_line(Vector2(0, area.y * 0.76), Vector2(area.x, area.y * 0.76), Color("f0b070"), 3.0)
		for cloud: Vector3 in [Vector3(0.12, 0.18, 70), Vector3(0.45, 0.12, 90), Vector3(0.8, 0.22, 80), Vector3(0.3, 0.86, 60), Vector3(0.7, 0.9, 70)]:
			var at := Vector2(cloud.x * area.x, cloud.y * area.y)
			for k in 4:
				draw_circle(at + Vector2(k * cloud.z * 0.7, -sin(k * 1.3) * cloud.z * 0.3), cloud.z * (0.8 - 0.1 * absf(k - 1.5)), Color("f3d9c0", 0.75))


## Avião provisório: biplano listrado de vermelho e creme com a hélice girando (o desenho de verdade vem do E2).
class PlanePlaceholder:
	extends Node2D
	var _spin := 0.0

	func _process(delta: float) -> void:
		_spin += delta * 40.0
		queue_redraw()

	func _draw() -> void:
		var ink := Color("1b1410")
		draw_rect(Rect2(-230, -95, 360, 22), Color("e8dac0"))
		draw_rect(Rect2(-230, -95, 360, 22), ink, false, 4.0)
		var body := PackedVector2Array([Vector2(-300, -20), Vector2(200, -45), Vector2(240, 0), Vector2(200, 45), Vector2(-300, 10)])
		draw_colored_polygon(body, Color("a8323a"))
		for x in range(-260, 200, 60):
			draw_rect(Rect2(x, -38, 26, 76), Color("e8dac0", 0.85))
		draw_polyline(body + PackedVector2Array([body[0]]), ink, 5.0)
		draw_rect(Rect2(-220, 30, 360, 20), Color("e8dac0"))
		draw_rect(Rect2(-220, 30, 360, 20), ink, false, 4.0)
		draw_circle(Vector2(-80, 85), 26, ink)
		draw_circle(Vector2(-80, 85), 14, Color("dfbc7d"))
		draw_colored_polygon(PackedVector2Array([Vector2(-300, -20), Vector2(-330, -90), Vector2(-260, -20)]), Color("a8323a"))
		draw_circle(Vector2(170, -10), 16, Color.WHITE)
		draw_circle(Vector2(174, -10), 7, ink)
		var blade := Vector2(0, 90).rotated(_spin)
		draw_line(Vector2(250, 0) - Vector2(0, blade.y), Vector2(250, 0) + Vector2(0, blade.y), Color("8a5a2a"), 12.0)
		draw_circle(Vector2(250, 0), 14, Color("dfbc7d"))


## Fumaça provisória: nuvem creme com contorno de tinta.
class SmokePlaceholder:
	extends Node2D

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 60, Color("1b1410"))
		draw_circle(Vector2.ZERO, 54, Color("ddd2c4"))
