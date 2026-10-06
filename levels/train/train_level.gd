extends Node2D
## Corrida no Trem do Circo (fase de plataforma da Área 1): correr e atirar em cima dos
## vagões até a locomotiva. Os vagões ficam parados no mundo; quem anda é o cenário lá atrás
## (TrainScenery), as rodas e as pontes baixas que passam por cima do trem (abaixar!).
## A fase é montada por código a partir das tabelas abaixo (vagões, caixotes, inimigos e
## ingressos), para ficar fácil de ajustar. Vagões, locomotiva, ponte e placa são desenhos
## (tools/cut_train_art.gd) esticados para o tamanho de cada vagão; os caixotes ainda são por código.

const ROOF_Y := 700.0
const WAGON_BOTTOM := 900.0
const RAIL_Y := 965.0
## Comprimento da fase: 6900 até 06/10/2026, quando a fase ganhou 5 vagões (pedido do usuário: maior), e
## 13140 desde os desafios dos vagões (vãos maiores).
const LEVEL_WIDTH := 13140.0
const INK := Color("1b1410")
const TRIM := Color("ffc93c")
const ART := "res://levels/train/art/"
## Vagões desenhados (vermelho, azul, mostarda, verde), 800 x 300: o teto em y 0, as rodas pintadas
## com o meio nestes pontos e a faixa do letreiro neste retângulo.
const WAGON_ART := [preload(ART + "wagon_1.png"), preload(ART + "wagon_2.png"), preload(ART + "wagon_3.png"),
		preload(ART + "wagon_4.png")]
const WAGON_ART_SIZE := Vector2(800, 300)
const WAGON_WHEELS := [Vector2(133, 232), Vector2(665, 232)]
const WAGON_WHEEL_RADIUS := 67.0
const WAGON_BANNER := Rect2(215, 70, 375, 120)
## Roda que gira por cima das rodas pintadas.
const WHEEL := preload(ART + "wheel.tres")
const WHEEL_SPIN := 9.0
## Locomotiva (900 x 560), com escala única: o canto esquerdo do desenho em x 16, o teto da caldeira
## (onde se anda) em y 262; desce um pouco para as rodas encostarem nos trilhos.
const LOCOMOTIVE := preload(ART + "locomotive.png")
const LOCOMOTIVE_SCALE := 1.05
const LOCOMOTIVE_ROOF := Vector2(16, 262)
const LOCOMOTIVE_SINK := 10.0
const LOCOMOTIVE_CHIMNEY := Vector2(750, 30)
const SMOKE := preload(ART + "smoke.tres")
const SMOKE_PUFFS := 4
const BRIDGE_ART := preload(ART + "bridge.png")
const SIGN_ART := preload(ART + "duck_sign.png")

## Vagões: [x inicial, largura, letreiro]. O último é a locomotiva. Desde 06/10/2026 (pedido do usuário: fase
## simples e fácil demais) os vãos variam e os cinco últimos vagões têm um desafio com um desafiante próprio:
## ACROBATAS (Saltimbanco de Mola), TRAPÉZIO (Trapezista do Além, e depois um vão largo demais para pular, só no
## balanço), LEÕES (Leõezinhos de Pelúcia nas escotilhas), BALÕES (carga alta demais: subir no balão; Baloeiro
## Assombrado por cima) e FANTASMAS (Sombras do Lanterninha).
const WAGONS := [
	[0.0, 900.0, "CIRCO"],
	[1060.0, 640.0, "RESPEITÁVEL"],
	[1960.0, 620.0, "PÚBLICO"],
	[2800.0, 600.0, "FERAS"],
	[3700.0, 740.0, "MALABARES"],
	[4660.0, 580.0, "MÁGICAS"],
	[5540.0, 720.0, "PALHAÇOS"],
	[6460.0, 900.0, "ACROBATAS"],
	[7560.0, 700.0, "TRAPÉZIO"],
	[9020.0, 900.0, "LEÕES"],
	[10120.0, 800.0, "BALÕES"],
	[11120.0, 900.0, "FANTASMAS"],
	[12220.0, 700.0, ""],
]
## Caixotes em cima dos vagões: [x do meio, largura, altura, empilhado em cima de (y do topo de baixo)].
## A pilha do vagão BALÕES (380 de altura) é alta demais para pular: sobe-se pelo balão.
const CRATES := [
	[2260.0, 110.0, 100.0, ROOF_Y],
	[4040.0, 120.0, 100.0, ROOF_Y],
	[4040.0, 90.0, 90.0, ROOF_Y - 100.0],
	[5920.0, 120.0, 100.0, ROOF_Y],
	[10640.0, 150.0, 130.0, ROOF_Y],
	[10640.0, 140.0, 130.0, ROOF_Y - 130.0],
	[10640.0, 130.0, 120.0, ROOF_Y - 260.0],
]
## Inimigos: [tipo, x, y, extra...] (hopper: alcance, atraso; pigeon: rosa, atraso; cannon: atraso;
## acrobat: alcance, atraso; trapeze: comprimento, atraso; lion: atraso; balloon: alcance, atraso;
## lantern: alcance, atraso).
const ENEMIES := [
	["hopper", 1380.0, ROOF_Y, 200.0, 0.0],
	["cannon", 2500.0, ROOF_Y, 0.4],
	["pigeon", 3100.0, 470.0, false, 0.0],
	["hopper", 3100.0, ROOF_Y, 220.0, 0.5],
	["pigeon", 3840.0, 430.0, false, 0.5],
	["hopper", 4940.0, ROOF_Y, 180.0, 0.25],
	["cannon", 5170.0, ROOF_Y, 1.1],
	["pigeon", 5760.0, 450.0, true, 0.2],
	["hopper", 6060.0, ROOF_Y, 160.0, 0.7],
	["acrobat", 6910.0, ROOF_Y, 300.0, 0.0],
	["pigeon", 7200.0, 420.0, false, 0.3],
	["trapeze", 7910.0, ROOF_Y - 100.0, 430.0, 0.0],
	["cannon", 8200.0, ROOF_Y, 0.8],
	["lion", 9250.0, ROOF_Y, 0.0],
	["lion", 9530.0, ROOF_Y, 0.9],
	["lion", 9810.0, ROOF_Y, 1.7],
	["pigeon", 9530.0, 400.0, true, 0.6],
	["balloon", 10520.0, ROOF_Y - 470.0, 300.0, 0.0],
	["lantern", 11400.0, ROOF_Y, 200.0, 0.0],
	["lantern", 11780.0, ROOF_Y, 180.0, 0.5],
	["pigeon", 11600.0, 440.0, true, 0.4],
	["hopper", 12500.0, ROOF_Y, 150.0, 0.2],
]
## Plataformas que se mexem pelo relógio da fase: ["swing", x, y no ponto mais baixo, comprimento, atraso] e
## ["balloon", x, y lá embaixo, altura da subida, atraso].
const PLATFORMS := [
	["swing", 8640.0, ROOF_Y - 8.0, 420.0, 0.0],
	["balloon", 10380.0, ROOF_Y - 12.0, 420.0, 0.0],
]
## Ingressos escondidos: [x, y] (os mesmos 3, espalhados pela fase; o último em cima do balão).
const TICKETS := [
	[2690.0, 470.0],
	[5920.0, 450.0],
	[10380.0, 150.0],
]

## Pontes baixas: a primeira passa aos FIRST_BRIDGE s e depois a cada BRIDGE_PERIOD s (13 até 06/10/2026).
const FIRST_BRIDGE := 9.0
const BRIDGE_PERIOD := 9.0
## Trechos em que a ponte não machuca (quem está no balanço ou no balão não tem como abaixar).
const BRIDGE_FREE := [[8200.0, 9100.0], [10120.0, 10920.0]]
const BRIDGE_SPEED := 1900.0
## Parte de baixo da ponte: em pé no teto do vagão encosta; abaixado passa.
const BRIDGE_BOTTOM := ROOF_Y - 100.0
const BRIDGE_WIDTH := 120.0
## Quanto antes de a ponte entrar na tela aparece o aviso "ABAIXE!".
const WARNING_TIME := 1.3

var _time := 0.0
var _bridge: EnemyHitbox
var _warning: Control
var _wheels: Array[Sprite2D] = []
var _smoke: Array[Sprite2D] = []
## Onde a fumaça sai (boca da chaminé).
var _chimney := Vector2.ZERO
## Desenhos dos vagões (atrás de tudo da fase) e os letreiros por cima deles.
var _train := Node2D.new()
var _labels := Node2D.new()

@onready var _level: RunLevel = $RunLevel
@onready var _camera: GroupCamera = $Camera


func _ready() -> void:
	_train.name = "TrainArt"
	add_child(_train)
	move_child(_train, 0)
	_build_wagons()
	_build_wagon_art()
	_build_crates()
	_build_enemies()
	_build_tickets()
	_build_platforms()
	_build_bridge()


func _physics_process(delta: float) -> void:
	_time += delta
	_update_bridge()
	for wheel in _wheels:
		wheel.rotation = _time * WHEEL_SPIN
	_update_smoke()
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
	_bridge.active = x != INF and not _bridge_free(x)
	if x != INF:
		_bridge.global_position = Vector2(x, 0)
	# Aviso na borda direita quando a ponte vai entrar na tela.
	var view := _camera.view_rect()
	var next := LEVEL_WIDTH + 600.0 - fposmod(_level.clock - FIRST_BRIDGE, BRIDGE_PERIOD) * BRIDGE_SPEED
	var ahead := next - view.end.x
	_warning.visible = _level.clock > FIRST_BRIDGE - WARNING_TIME - 3.0 and ahead > 0.0 \
			and ahead < BRIDGE_SPEED * WARNING_TIME
	_warning.queue_redraw()


func _bridge_free(x: float) -> bool:
	for zone: Array in BRIDGE_FREE:
		if x > zone[0] and x < zone[1]:
			return true
	return false


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
			"acrobat":
				var acrobat := SpringAcrobat.new()
				acrobat.patrol_range = data[3]
				acrobat.offset = data[4]
				enemy = acrobat
			"trapeze":
				var trapeze := TrapezeGhost.new()
				trapeze.length = data[3]
				trapeze.offset = data[4]
				enemy = trapeze
			"lion":
				var lion := PlushLion.new()
				lion.offset = data[3]
				enemy = lion
			"balloon":
				var balloon := BalloonGhost.new()
				balloon.patrol_range = data[3]
				balloon.offset = data[4]
				balloon.ground_y = ROOF_Y
				enemy = balloon
			"lantern":
				var lantern := LanternGhost.new()
				lantern.patrol_range = data[3]
				lantern.offset = data[4]
				enemy = lantern
		enemy.name = "Enemy%d" % i
		enemy.position = Vector2(data[1], data[2])
		holder.add_child(enemy)


func _build_tickets() -> void:
	for i in TICKETS.size():
		var ticket := HiddenTicket.new()
		ticket.ticket_id = "train:%d" % (i + 1)
		ticket.position = Vector2(TICKETS[i][0], TICKETS[i][1])
		add_child(ticket)


func _build_platforms() -> void:
	for i in PLATFORMS.size():
		var data: Array = PLATFORMS[i]
		var platform: AnimatableBody2D
		match data[0]:
			"swing":
				var swing := SwingPlatform.new()
				swing.length = data[3]
				swing.offset = data[4]
				platform = swing
			"balloon":
				var balloon := BalloonPlatform.new()
				balloon.rise = data[3]
				balloon.offset = data[4]
				platform = balloon
		platform.name = "Platform%d" % i
		platform.position = Vector2(data[1], data[2])
		add_child(platform)


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
	var art := Sprite2D.new()
	art.texture = BRIDGE_ART
	art.scale = Vector2.ONE * (BRIDGE_BOTTOM + 200.0) / BRIDGE_ART.get_height()
	art.position = Vector2(0, (BRIDGE_BOTTOM - 200.0) * 0.5)
	_bridge.add_child(art)
	add_child(_bridge)
	_bridge.hide()
	_warning = Control.new()
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warning.draw.connect(_draw_warning)
	$Hud.add_child(_warning)
	_warning.hide()


## Desenhos do trem: cada vagão esticado para o tamanho dele, com as rodas girando por cima das
## pintadas; a locomotiva com a fumaça; e os letreiros.
func _build_wagon_art() -> void:
	var sy := (RAIL_Y - ROOF_Y) / WAGON_ART_SIZE.y
	for i in WAGONS.size() - 1:
		var wagon: Array = WAGONS[i]
		var sx: float = wagon[1] / WAGON_ART_SIZE.x
		var body := Sprite2D.new()
		body.texture = WAGON_ART[i % WAGON_ART.size()]
		body.centered = false
		body.position = Vector2(wagon[0], ROOF_Y)
		body.scale = Vector2(sx, sy)
		_train.add_child(body)
		for at: Vector2 in WAGON_WHEELS:
			var wheel := Sprite2D.new()
			WHEEL.show_on(wheel, 0)
			wheel.position = Vector2(wagon[0] + at.x * sx, ROOF_Y + at.y * sy)
			wheel.scale = Vector2.ONE * WHEEL.frame_scale * (WAGON_WHEEL_RADIUS * sy) / -WHEEL.origin.y
			_train.add_child(wheel)
			_wheels.append(wheel)
	var engine: Array = WAGONS[WAGONS.size() - 1]
	var locomotive := Sprite2D.new()
	locomotive.texture = LOCOMOTIVE
	locomotive.centered = false
	locomotive.scale = Vector2.ONE * LOCOMOTIVE_SCALE
	locomotive.position = Vector2(engine[0], ROOF_Y + LOCOMOTIVE_SINK) - LOCOMOTIVE_ROOF * LOCOMOTIVE_SCALE
	_train.add_child(locomotive)
	_chimney = locomotive.position + LOCOMOTIVE_CHIMNEY * LOCOMOTIVE_SCALE
	for k in SMOKE_PUFFS:
		var puff := Sprite2D.new()
		_train.add_child(puff)
		_smoke.append(puff)
	_labels.draw.connect(_draw_labels)
	_train.add_child(_labels)


## Fumaça saindo da chaminé e ficando para trás (o trem anda para a direita).
func _update_smoke() -> void:
	for k in _smoke.size():
		var puff := fmod(_time * 1.1 + float(k) / _smoke.size(), 1.0)
		var sprite := _smoke[k]
		SMOKE.show_on(sprite, mini(int(puff * 4.0), 3))
		sprite.scale = Vector2.ONE * SMOKE.frame_scale * (0.8 + puff * 0.8)
		sprite.position = _chimney + Vector2(-puff * 260.0, -puff * 150.0)
		sprite.modulate.a = 1.0 - puff * puff


## Letreiros nas faixas dos vagões (o maior tamanho que cabe) e a placa do fim.
func _draw_labels() -> void:
	var font := UiTheme.TITLE_FONT
	for wagon: Array in WAGONS:
		var label: String = wagon[2]
		if label.is_empty():
			continue
		var sx: float = wagon[1] / WAGON_ART_SIZE.x
		var sy := (RAIL_Y - ROOF_Y) / WAGON_ART_SIZE.y
		var banner_width := WAGON_BANNER.size.x * sx * 0.8
		var size := 40
		while size > 18 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > banner_width:
			size -= 2
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var center := Vector2(wagon[0] + WAGON_BANNER.get_center().x * sx, ROOF_Y + WAGON_BANNER.get_center().y * sy)
		var at := center + Vector2(-text_size.x * 0.5, size * 0.35)
		_labels.draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color("f2e6cc"))
		_labels.draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("6e1c1b"))
	var end := $EndZone as Node2D
	_labels.draw_string_outline(font, end.position + Vector2(-330, -330), "FIM DA LINHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, INK)
	_labels.draw_string(font, end.position + Vector2(-330, -330), "FIM DA LINHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, TRIM)


## Placa "ABAIXE!" piscando na borda direita da tela.
func _draw_warning() -> void:
	if fmod(_time, 0.3) > 0.2:
		return
	var at := Vector2(1760, 500)
	var size := SIGN_ART.get_size() * 0.7
	_warning.draw_texture_rect(SIGN_ART, Rect2(at - size * 0.5, size), false)
	var font := UiTheme.TITLE_FONT
	var text := "ABAIXE!"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	var base := at + Vector2(-text_size.x * 0.5, size.y * 0.5 + 34)
	_warning.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 8, INK)
	_warning.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, TRIM)


func _draw() -> void:
	# Trilhos.
	draw_rect(Rect2(-100, RAIL_Y, LEVEL_WIDTH + 200, 12), Color("3a3236"))
	draw_line(Vector2(-100, RAIL_Y), Vector2(LEVEL_WIDTH + 100, RAIL_Y), INK, 3.0)
	var sleeper := fmod(_time * 900.0, 90.0)
	var x := -100.0 - sleeper
	while x < LEVEL_WIDTH + 100.0:
		draw_rect(Rect2(x, RAIL_Y + 12, 50, 14), Color("4a3424"))
		x += 90.0
	for crate: Array in CRATES:
		var rect := Rect2(crate[0] - crate[1] * 0.5, crate[3] - crate[2], crate[1], crate[2])
		draw_rect(rect, Color("a8763e"))
		draw_rect(rect, INK, false, 4.0)
		draw_line(rect.position, rect.end, Color(INK, 0.6), 3.0)
		draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color(INK, 0.6), 3.0)
