extends Node2D
## Corrida no Trem do Circo (fase de plataforma da Área 1): correr e atirar em cima dos
## vagões até a locomotiva. Os vagões ficam parados no mundo; quem anda é o cenário lá atrás
## (TrainScenery), as rodas e as pontes baixas que passam por cima do trem (abaixar!).
## A fase é montada por código a partir das tabelas abaixo (vagões, caixotes, inimigos e
## ingressos), para ficar fácil de ajustar. Desenho provisório por código.

const ROOF_Y := 700.0
const WAGON_BOTTOM := 900.0
const RAIL_Y := 965.0
const LEVEL_WIDTH := 6900.0
const INK := Color("1b1410")
const WAGON_COLORS := [Color("a3282a"), Color("2f5d8a"), Color("b07a20"), Color("3f7a4a")]
const TRIM := Color("ffc93c")

## Vagões: [x inicial, largura, letreiro]. O último é a locomotiva.
const WAGONS := [
	[0.0, 900.0, "CIRCO"],
	[1060.0, 640.0, "RESPEITÁVEL"],
	[1880.0, 620.0, "PÚBLICO"],
	[2700.0, 600.0, "FERAS"],
	[3460.0, 740.0, "MALABARES"],
	[4420.0, 580.0, "MÁGICAS"],
	[5180.0, 720.0, "PALHAÇOS"],
	[6060.0, 700.0, ""],
]
## Caixotes em cima dos vagões: [x do meio, largura, altura, empilhado em cima de (y do topo de baixo)].
const CRATES := [
	[2180.0, 110.0, 100.0, ROOF_Y],
	[3800.0, 120.0, 100.0, ROOF_Y],
	[3800.0, 90.0, 90.0, ROOF_Y - 100.0],
	[5560.0, 120.0, 100.0, ROOF_Y],
]
## Inimigos: [tipo, x, y, extra...] (hopper: alcance, atraso; pigeon: rosa, atraso; cannon: atraso).
const ENEMIES := [
	["hopper", 1380.0, ROOF_Y, 200.0, 0.0],
	["cannon", 2420.0, ROOF_Y, 0.4],
	["pigeon", 3000.0, 470.0, false, 0.0],
	["hopper", 3000.0, ROOF_Y, 220.0, 0.5],
	["pigeon", 3600.0, 430.0, false, 0.5],
	["hopper", 4700.0, ROOF_Y, 180.0, 0.25],
	["cannon", 4930.0, ROOF_Y, 1.1],
	["pigeon", 5400.0, 450.0, true, 0.2],
	["hopper", 5850.0, ROOF_Y, 160.0, 0.7],
]
## Ingressos escondidos: [x, y].
const TICKETS := [
	[2600.0, 470.0],
	[3800.0, 430.0],
	[5560.0, 450.0],
]

## Pontes baixas: a primeira passa aos FIRST_BRIDGE s e depois a cada BRIDGE_PERIOD s.
const FIRST_BRIDGE := 9.0
const BRIDGE_PERIOD := 13.0
const BRIDGE_SPEED := 1900.0
## Parte de baixo da ponte: em pé no teto do vagão encosta; abaixado passa.
const BRIDGE_BOTTOM := ROOF_Y - 100.0
const BRIDGE_WIDTH := 120.0
## Quanto antes de a ponte entrar na tela aparece o aviso "ABAIXE!".
const WARNING_TIME := 1.3

var _time := 0.0
var _bridge: EnemyHitbox
var _warning: Control

@onready var _level: RunLevel = $RunLevel
@onready var _camera: GroupCamera = $Camera


func _ready() -> void:
	_build_wagons()
	_build_crates()
	_build_enemies()
	_build_tickets()
	_build_bridge()


func _physics_process(delta: float) -> void:
	_time += delta
	_update_bridge()
	queue_redraw()


## Onde está a ponte agora (x do meio), ou INF se não há ponte passando.
func bridge_x() -> float:
	var t := _level.clock - FIRST_BRIDGE
	if t < -WARNING_TIME * 2.0:
		return INF
	var s := fposmod(t, BRIDGE_PERIOD)
	var x := LEVEL_WIDTH + 600.0 - s * BRIDGE_SPEED
	return x if x > -400.0 else INF


func _update_bridge() -> void:
	var x := bridge_x() if _level.clock >= FIRST_BRIDGE else INF
	_bridge.visible = x != INF
	_bridge.active = x != INF
	if x != INF:
		_bridge.global_position = Vector2(x, 0)
	# Aviso na borda direita quando a ponte vai entrar na tela.
	var view := _camera.view_rect()
	var next := LEVEL_WIDTH + 600.0 - fposmod(_level.clock - FIRST_BRIDGE, BRIDGE_PERIOD) * BRIDGE_SPEED
	var ahead := next - view.end.x
	_warning.visible = _level.clock > FIRST_BRIDGE - WARNING_TIME - 3.0 and ahead > 0.0 \
			and ahead < BRIDGE_SPEED * WARNING_TIME
	_warning.queue_redraw()


func _build_wagons() -> void:
	var checkpoints := $Checkpoints
	for i in WAGONS.size():
		var wagon: Array = WAGONS[i]
		var body := StaticBody2D.new()
		body.name = "Wagon%d" % i
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(wagon[1], WAGON_BOTTOM - ROOF_Y)
		shape.shape = rect
		shape.position = Vector2(wagon[0] + wagon[1] * 0.5, (ROOF_Y + WAGON_BOTTOM) * 0.5)
		body.add_child(shape)
		add_child(body)
		var marker := Marker2D.new()
		marker.position = Vector2(wagon[0] + 90.0, ROOF_Y)
		checkpoints.add_child(marker)
	# Parede no começo e no fim da fase.
	for x in [-40.0, LEVEL_WIDTH + 40.0]:
		var wall := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(80, 1400)
		shape.shape = rect
		shape.position = Vector2(x, 400)
		wall.add_child(shape)
		add_child(wall)


func _build_crates() -> void:
	for crate: Array in CRATES:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(crate[1], crate[2])
		shape.shape = rect
		shape.position = Vector2(crate[0], crate[3] - crate[2] * 0.5)
		body.add_child(shape)
		add_child(body)


func _build_enemies() -> void:
	var holder := $Enemies
	for i in ENEMIES.size():
		var data: Array = ENEMIES[i]
		var enemy: Enemy
		match data[0]:
			"hopper":
				var hopper := GhostHopper.new()
				hopper.patrol_range = data[3]
				hopper.offset = data[4]
				enemy = hopper
			"pigeon":
				var pigeon := MagicPigeon.new()
				pigeon.pink = data[3]
				pigeon.offset = data[4]
				enemy = pigeon
			"cannon":
				var cannon := ConfettiCannon.new()
				cannon.offset = data[3]
				enemy = cannon
		enemy.name = "Enemy%d" % i
		enemy.position = Vector2(data[1], data[2])
		holder.add_child(enemy)


func _build_tickets() -> void:
	for i in TICKETS.size():
		var ticket := HiddenTicket.new()
		ticket.ticket_id = "train:%d" % (i + 1)
		ticket.position = Vector2(TICKETS[i][0], TICKETS[i][1])
		add_child(ticket)


func _build_bridge() -> void:
	_bridge = EnemyHitbox.new()
	_bridge.name = "LowBridge"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(BRIDGE_WIDTH - 20.0, BRIDGE_BOTTOM + 200.0)
	shape.shape = rect
	shape.position = Vector2(0, (BRIDGE_BOTTOM - 200.0) * 0.5)
	_bridge.add_child(shape)
	_bridge.z_index = 20
	_bridge.draw.connect(_draw_bridge)
	add_child(_bridge)
	_bridge.hide()
	_warning = Control.new()
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warning.draw.connect(_draw_warning)
	$Hud.add_child(_warning)
	_warning.hide()


func _draw_bridge() -> void:
	var w := BRIDGE_WIDTH
	var wood := Color("6b4a2e")
	_bridge.draw_rect(Rect2(-w * 0.5, -200, w, BRIDGE_BOTTOM + 200), INK)
	_bridge.draw_rect(Rect2(-w * 0.5 + 5, -200, w - 10, BRIDGE_BOTTOM + 195), wood)
	var y := -200.0
	while y < BRIDGE_BOTTOM - 40.0:
		_bridge.draw_line(Vector2(-w * 0.5 + 5, y), Vector2(w * 0.5 - 5, y + 80), INK, 4.0)
		_bridge.draw_line(Vector2(w * 0.5 - 5, y), Vector2(-w * 0.5 + 5, y + 80), INK, 4.0)
		y += 80.0
	_bridge.draw_rect(Rect2(-w * 0.5 - 10, BRIDGE_BOTTOM - 26, w + 20, 26), Color("8a5a32"))
	_bridge.draw_rect(Rect2(-w * 0.5 - 10, BRIDGE_BOTTOM - 26, w + 20, 26), INK, false, 4.0)


## Placa "ABAIXE!" piscando na borda direita da tela.
func _draw_warning() -> void:
	if fmod(_time, 0.3) > 0.2:
		return
	var at := Vector2(1780, 520)
	var points := PackedVector2Array([at + Vector2(0, -70), at + Vector2(70, 0), at + Vector2(0, 70), at + Vector2(-70, 0)])
	_warning.draw_colored_polygon(points, Color("ffc93c"))
	points.append(points[0])
	_warning.draw_polyline(points, INK, 6.0)
	var font := UiTheme.TITLE_FONT
	var text := "ABAIXE!"
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	_warning.draw_string(font, at + Vector2(-size.x * 0.5, 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)


func _draw() -> void:
	# Trilhos.
	draw_rect(Rect2(-100, RAIL_Y, LEVEL_WIDTH + 200, 12), Color("3a3236"))
	draw_line(Vector2(-100, RAIL_Y), Vector2(LEVEL_WIDTH + 100, RAIL_Y), INK, 3.0)
	var sleeper := fmod(_time * 900.0, 90.0)
	var x := -100.0 - sleeper
	while x < LEVEL_WIDTH + 100.0:
		draw_rect(Rect2(x, RAIL_Y + 12, 50, 14), Color("4a3424"))
		x += 90.0
	for i in WAGONS.size():
		_draw_wagon(WAGONS[i], i, i == WAGONS.size() - 1)
	for crate: Array in CRATES:
		var rect := Rect2(crate[0] - crate[1] * 0.5, crate[3] - crate[2], crate[1], crate[2])
		draw_rect(rect, Color("a8763e"))
		draw_rect(rect, INK, false, 4.0)
		draw_line(rect.position, rect.end, Color(INK, 0.6), 3.0)
		draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color(INK, 0.6), 3.0)
	# Área final: placa na cabine da locomotiva.
	var end := $EndZone as Node2D
	var font := UiTheme.TITLE_FONT
	draw_string_outline(font, end.position + Vector2(-150, -330), "FIM DA LINHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, INK)
	draw_string(font, end.position + Vector2(-150, -330), "FIM DA LINHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, TRIM)


func _draw_wagon(wagon: Array, index: int, locomotive: bool) -> void:
	var x0: float = wagon[0]
	var width: float = wagon[1]
	var color: Color = Color("2a2a32") if locomotive else WAGON_COLORS[index % WAGON_COLORS.size()]
	var body := Rect2(x0, ROOF_Y, width, WAGON_BOTTOM - ROOF_Y)
	draw_rect(body, color)
	draw_rect(Rect2(x0, ROOF_Y, width, 16), color.darkened(0.3))
	draw_rect(body, INK, false, 5.0)
	# Rodas girando.
	var spin := _time * 9.0
	for wx in [x0 + 90.0, x0 + width - 90.0]:
		var hub := Vector2(wx, WAGON_BOTTOM + 30.0)
		draw_circle(hub, 34, INK)
		draw_circle(hub, 28, TRIM)
		for k in 4:
			draw_line(hub, hub + Vector2.from_angle(spin + k * PI * 0.5) * 26, INK, 4.0)
	if locomotive:
		# Caldeira, chaminé e cabine.
		draw_rect(Rect2(x0 + width - 200, ROOF_Y - 260, 160, 260), Color("3a3236"))
		draw_rect(Rect2(x0 + width - 200, ROOF_Y - 260, 160, 260), INK, false, 5.0)
		draw_rect(Rect2(x0 + 120, ROOF_Y - 150, 50, 150), Color("3a3236"))
		draw_rect(Rect2(x0 + 120, ROOF_Y - 150, 50, 150), INK, false, 4.0)
		for k in 4:
			var puff := fmod(_time * 1.5 + k * 0.25, 1.0)
			draw_circle(Vector2(x0 + 145 - puff * 160, ROOF_Y - 170 - puff * 120), 20 + puff * 30, Color(0.85, 0.85, 0.85, 0.5 * (1.0 - puff)))
		return
	# Enfeites de circo: faixa dourada e letreiro.
	draw_rect(Rect2(x0 + 20, ROOF_Y + 40, width - 40, 6), TRIM)
	draw_rect(Rect2(x0 + 20, WAGON_BOTTOM - 46, width - 40, 6), TRIM)
	var label: String = wagon[2]
	if not label.is_empty():
		var font := UiTheme.TITLE_FONT
		var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 46)
		var at := Vector2(x0 + width * 0.5 - size.x * 0.5, (ROOF_Y + WAGON_BOTTOM) * 0.5 + 16)
		draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, 8, INK)
		draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color("f2e6cc"))
