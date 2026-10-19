class_name MaestroThreat
extends EnemyHitbox
## Perigo do Maestro desenhado por código: nota, par de colcheias, onda grave, lâmina de som, golpe da batuta,
## peso do metrônomo e tubo de órgão. A colisão segue só a parte sólida do desenho, com folga pequena.
## Contorno escuro e preenchimento chapado, no traço das outras lutas; a nota de parry usa o ParryStyle.

const INK := Color("2a1a10")
const BRASS := Color("d9a441")
const BRASS_LIGHT := Color("ffe29a")
const BRASS_DARK := Color("8a5a1c")
const SOUND := Color("f6e7c1")
## Alcance do golpe da batuta a partir do ombro.
const REACH := 560.0

var kind: StringName = &"note"
var parry_id := ""
var popped := false
## Altura do tubo de órgão (pixels acima do chão) e quanto do golpe da batuta já passou (0 a 1).
var amount := 0.0
var _clock := 0.0
var _shapes: Array[CollisionShape2D] = []


func _ready() -> void:
	if parryable:
		parry_target = self
	super()
	z_index = 2
	match kind:
		&"note", &"note_parry":
			_circle(Vector2.ZERO, 30.0)
			_rect(Vector2(24, -38), Vector2(10, 76))
		&"eighths":
			_circle(Vector2(-46, 0), 28.0)
			_circle(Vector2(46, 0), 28.0)
			_rect(Vector2(0, -78), Vector2(112, 18))
		&"wave":
			_polygon(_dome(52.0, 74.0))
		&"crescent":
			_capsule(Vector2(0, -36), 26.0, 72.0)
		&"arc":
			_polygon(_sector(1.0))
		&"blade":
			_polygon(PackedVector2Array([Vector2(-48, -40), Vector2(48, -40), Vector2(30, 44), Vector2(-30, 44)]))
		&"pipe":
			_rect(Vector2(0, -350), Vector2(96, 700))
	set_amount(amount)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


## Tubo: altura acima do chão; golpe da batuta: quanto do arco já passou.
func set_amount(value: float) -> void:
	amount = value
	if kind == &"pipe" and not _shapes.is_empty():
		var rect := _shapes[0].shape as RectangleShape2D
		rect.size.y = maxf(value, 1.0)
		_shapes[0].position.y = -value * 0.5
		_shapes[0].set_deferred("disabled", value < 8.0)


func _circle(at: Vector2, radius: float) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	_add(shape, at)


func _rect(at: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	_add(shape, at)


func _capsule(at: Vector2, radius: float, height: float) -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = radius
	shape.height = height
	_add(shape, at)


func _polygon(points: PackedVector2Array) -> void:
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	_add(shape, Vector2.ZERO)


func _add(shape: Shape2D, at: Vector2) -> void:
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = at
	add_child(node)
	_shapes.append(node)


## Meia-elipse apoiada no chão (y = 0).
static func _dome(half_width: float, height: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		points.append(Vector2(-cos(a) * half_width, -sin(a) * height))
	return points


## Leque do golpe da batuta, do ombro para baixo e para a frente (esquerda). Origem no ombro; alcança o chão
## na frente dele.
static func _sector(reach: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	for i in 9:
		var a := lerpf(-PI * 0.5, -PI * 0.98, i / 8.0)
		points.append(Vector2(cos(a), -sin(a)) * REACH * reach)
	return points


func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.1)


func retire() -> void:
	active = false
	hide()


func _draw() -> void:
	match kind:
		&"note", &"note_parry":
			_draw_note()
		&"eighths":
			_draw_eighths()
		&"wave":
			_draw_wave()
		&"crescent":
			_draw_crescent()
		&"arc":
			_draw_arc()
		&"blade":
			_draw_blade()
		&"pipe":
			_draw_pipe()


func _glow(at: Vector2, radius: float, color: Color) -> void:
	for i in 3:
		draw_circle(at, radius * (1.0 + 0.35 * (i + 1)), Color(color, 0.12))


func _draw_note() -> void:
	var parry := kind == &"note_parry"
	var fill := ParryStyle.MAIN if parry else BRASS
	var light := ParryStyle.LIGHT if parry else BRASS_LIGHT
	_glow(Vector2.ZERO, 30.0, fill)
	# Haste e bandeirinha.
	draw_rect(Rect2(19, -76, 12, 76), INK)
	draw_rect(Rect2(22, -73, 6, 72), light)
	var flag := PackedVector2Array([Vector2(29, -76), Vector2(58, -50), Vector2(52, -26), Vector2(44, -44), Vector2(29, -52)])
	draw_colored_polygon(flag, fill)
	draw_polyline(flag + PackedVector2Array([flag[0]]), INK, 3.0, true)
	# Cabeça oval inclinada.
	var head := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		head.append(Vector2(cos(a) * 34.0, sin(a) * 25.0).rotated(-0.35))
	draw_colored_polygon(head, fill)
	draw_polyline(head + PackedVector2Array([head[0]]), INK, 4.0, true)
	draw_circle(Vector2(-10, -8), 8.0, Color(light, 0.9))
	if parry:
		ParryStyle.draw_sparkle(self, Vector2(0, 2), 13.0, _clock)


func _draw_eighths() -> void:
	_glow(Vector2(-46, 0), 28.0, BRASS)
	_glow(Vector2(46, 0), 28.0, BRASS)
	for x in [-46.0, 46.0]:
		draw_rect(Rect2(x + 14, -84, 11, 84), INK)
		draw_rect(Rect2(x + 17, -81, 5, 80), BRASS_LIGHT)
	var beam := Rect2(-34, -88, 92, 20)
	draw_rect(beam.grow(3), INK)
	draw_rect(beam, BRASS)
	for x in [-46.0, 46.0]:
		var head := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			head.append(Vector2(x, 0) + Vector2(cos(a) * 31.0, sin(a) * 23.0).rotated(-0.35))
		draw_colored_polygon(head, BRASS)
		draw_polyline(head + PackedVector2Array([head[0]]), INK, 4.0, true)
		draw_circle(Vector2(x - 9, -7), 7.0, BRASS_LIGHT)


func _draw_wave() -> void:
	# Três cascas de som apoiadas no chão, a de fora vibrando.
	var wobble := sin(_clock * 30.0) * 3.0
	for i in 3:
		var k := 1.0 - i * 0.28
		var points := _dome(52.0 * k + (wobble if i == 0 else 0.0), 74.0 * k)
		draw_colored_polygon(points, Color(SOUND, 0.28 + i * 0.2))
		draw_polyline(points, INK if i == 0 else BRASS, 5.0 if i == 0 else 3.0, true)
	draw_line(Vector2(-60, 0), Vector2(60, 0), INK, 4.0)


func _draw_crescent() -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 17:
		var a := lerpf(-PI * 0.5, PI * 0.5, i / 16.0)
		outer.append(Vector2(-cos(a) * 34.0, sin(a) * 62.0 - 36.0))
		inner.append(Vector2(-cos(a) * 12.0 + 6.0, sin(a) * 50.0 - 36.0))
	inner.reverse()
	var shape := outer + inner
	draw_colored_polygon(shape, Color(SOUND, 0.9))
	draw_polyline(shape + PackedVector2Array([shape[0]]), INK, 4.0, true)
	for i in 3:
		draw_line(Vector2(18 + i * 16, -66 + i * 6), Vector2(18 + i * 16, -6 - i * 6), Color(SOUND, 0.5 - i * 0.15), 4.0)


func _draw_arc() -> void:
	# Rastro da batuta: faixa clara na ponta do leque, mais forte no começo do golpe.
	var fade := 1.0 - amount * 0.7
	draw_colored_polygon(_sector(1.0), Color(SOUND, 0.12 * fade))
	var band := PackedVector2Array()
	for i in 9:
		var a := lerpf(-PI * 0.5, -PI * 0.98, i / 8.0)
		band.append(Vector2(cos(a), -sin(a)) * REACH)
	for i in range(8, -1, -1):
		var a := lerpf(-PI * 0.5, -PI * 0.98, i / 8.0)
		band.append(Vector2(cos(a), -sin(a)) * REACH * 0.72)
	draw_colored_polygon(band, Color(SOUND, 0.42 * fade))
	draw_polyline(band + PackedVector2Array([band[0]]), INK, 4.0, true)
	for k in 3:
		var r := REACH * (0.62 - k * 0.12)
		draw_arc(Vector2.ZERO, r, PI * 0.5, PI * 0.98, 12, Color(SOUND, 0.4 * fade), 5.0, true)


func _draw_blade() -> void:
	var body := PackedVector2Array([Vector2(-48, -40), Vector2(48, -40), Vector2(30, 44), Vector2(-30, 44)])
	_glow(Vector2.ZERO, 46.0, BRASS)
	draw_colored_polygon(body, BRASS)
	draw_colored_polygon(PackedVector2Array([Vector2(-48, -40), Vector2(-8, -40), Vector2(-14, 44), Vector2(-30, 44)]), BRASS_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -40), Vector2(22, -40), Vector2(14, 44), Vector2(4, 44)]), BRASS_LIGHT)
	draw_polyline(body + PackedVector2Array([body[0]]), INK, 5.0, true)
	# Gume serrilhado embaixo.
	for i in 5:
		var x := -26.0 + i * 13.0
		var tooth := PackedVector2Array([Vector2(x, 44), Vector2(x + 13, 44), Vector2(x + 6.5, 58)])
		draw_colored_polygon(tooth, Color("e9e4d8"))
		draw_polyline(tooth, INK, 2.0, true)


func _draw_pipe() -> void:
	if amount < 2.0:
		return
	var top := -amount
	var rect := Rect2(-48, top, 96, amount)
	# Coluna de som soprando do bocal.
	var blow := 0.5 + 0.5 * sin(_clock * 40.0)
	draw_rect(Rect2(-44, top - 120, 88, 120), Color(SOUND, 0.18 + blow * 0.12))
	for i in 3:
		var y := top - fposmod(_clock * 520.0 + i * 40.0, 120.0)
		draw_arc(Vector2(0, y + 12), 40, PI * 1.1, PI * 1.9, 10, Color(SOUND, 0.7), 4.0, true)
	# Cano de latão com luz na lateral.
	draw_rect(rect.grow(4), INK)
	draw_rect(rect, BRASS)
	draw_rect(Rect2(-48, top, 22, amount), BRASS_DARK)
	draw_rect(Rect2(6, top, 14, amount), BRASS_LIGHT)
	# Boca do tubo (o recorte em V dos tubos de órgão) e anéis.
	var mouth := PackedVector2Array([Vector2(-30, top + 70), Vector2(30, top + 70), Vector2(18, top + 100), Vector2(-18, top + 100)])
	draw_colored_polygon(mouth, INK)
	for y in range(int(top) + 30, -20, 160):
		draw_rect(Rect2(-52, y, 104, 12), BRASS_DARK)
		draw_rect(Rect2(-52, y, 104, 12), INK, false, 2.0)
	draw_rect(Rect2(-56, top - 10, 112, 20), BRASS_LIGHT)
	draw_rect(Rect2(-56, top - 10, 112, 20), INK, false, 3.0)
