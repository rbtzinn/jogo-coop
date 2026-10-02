extends BossAttack
## Argolas de fogo: o domador lança três argolas que ficam no ar (aviso piscando),
## e Leopoldo pula da direita para a esquerda passando por dentro delas.
## Uma das argolas é rosa (parry, etapa 4b). Quando o leão passa, cada argola solta brasas
## que caem no chão (quem está parado embaixo precisa sair). Depois ele volta caindo no pedestal.

const RING_XS := [1250.0, 820.0, 390.0]
## Distância do pé do leão até o meio do corpo (as argolas ficam no meio do corpo).
const BODY_CENTER := Vector2(0, -85)
const TOSS_END := 0.35
const RINGS_LIT := 1.25
const LEAP_START := 1.35
const LEAP_TIME := 1.5
const RINGS_OUT := 3.1
const RETURN_START := 3.5
const RETURN_TIME := 0.6
const END := 4.4
## Alturas possíveis do pulo: o baixo ameaça quem está nos pedestais.
const LEAP_HEIGHTS := [200.0, 280.0]

@export var tamer_path: NodePath
@export var lion_path: NodePath
## Onde o pulo termina (fora da tela, à esquerda).
@export var leap_end := Vector2(-320, 1000)

var _rings: Array[FireRing] = []
var _landed := false
var _leap_height := 280.0
var _embers := EmberShower.new()

@onready var tamer: Tamer = get_node(tamer_path)
@onready var lion: TamerLion = get_node(lion_path)


func _ready() -> void:
	add_child(_embers)


func _on_begin() -> void:
	_leap_height = LEAP_HEIGHTS[rng.randi_range(0, LEAP_HEIGHTS.size() - 1)]
	var pink_index := rng.randi_range(0, RING_XS.size() - 1)
	_rings.clear()
	_embers.clear()
	lion.go_home()
	for i in RING_XS.size():
		var ring := FireRing.new()
		ring.pink = i == pink_index
		ring.parry_id = "%s:%d:%d" % [name, rng.seed, i]
		add_child(ring)
		ring.global_position = _leap_point(_u_at_x(RING_XS[i])) + BODY_CENTER
		_rings.append(ring)
		# Duas brasas por argola, soltas quando o leão passa por ela.
		var drop_time := LEAP_START + _u_at_x(RING_XS[i]) * LEAP_TIME
		var bottom := ring.global_position + Vector2(0, ring.radius.y * 0.8)
		for side in [-1.0, 1.0]:
			var velocity := Vector2(side * rng.randf_range(60.0, 160.0), rng.randf_range(-220.0, -80.0))
			_embers.add(drop_time, bottom, velocity)
	_landed = false
	lion.idle = false


func _on_tick(_delta: float) -> void:
	var t := elapsed
	tamer.whip_pose = 1.0 if t < TOSS_END + 0.3 else 0.0

	var strength := 0.0
	if t >= TOSS_END and t < RINGS_LIT:
		strength = lerpf(0.2, 0.99, (t - TOSS_END) / (RINGS_LIT - TOSS_END))
	elif t >= RINGS_LIT and t < RINGS_OUT:
		strength = 1.0
	elif t >= RINGS_OUT:
		strength = maxf(0.0, 0.99 - (t - RINGS_OUT) * 3.0)
	for ring in _rings:
		ring.strength = strength

	_embers.update(t)

	if t < LEAP_START:
		# Aviso: Leopoldo se agacha para pegar impulso.
		var crouch := clampf((t - (LEAP_START - 0.45)) / 0.4, 0.0, 1.0)
		lion.body.scale = Vector2(1.0 + crouch * 0.08, 1.0 - crouch * 0.14)
	elif t < LEAP_START + LEAP_TIME:
		lion.body.scale = Vector2(0.95, 1.06)
		var u := (t - LEAP_START) / LEAP_TIME
		lion.global_position = _leap_point(u)
		lion.tilt_along(_leap_point(minf(u + 0.02, 1.0)) - _leap_point(maxf(u - 0.02, 0.0)))
	elif t < RETURN_START:
		lion.visible = false
	elif t < RETURN_START + RETURN_TIME:
		# Volta caindo do alto em cima do pedestal.
		lion.visible = true
		lion.rotation = 0.0
		lion.body.scale = Vector2(0.95, 1.06)
		var k := (t - RETURN_START) / RETURN_TIME
		lion.global_position = lion.home_position + Vector2(0, -900.0 * (1.0 - k * k))
	elif not _landed:
		_landed = true
		lion.go_home()
		lion.body.scale = Vector2(1.15, 0.85)
		Fx.spawn(preload("res://components/fx/dust_puff.tscn"), lion.home_position)


func _is_done() -> bool:
	return elapsed >= END


func _on_end() -> void:
	for ring in _rings:
		ring.queue_free()
	_rings.clear()
	_embers.clear()
	tamer.whip_pose = 0.0
	lion.go_home()


func _leap_point(u: float) -> Vector2:
	return arc_point(lion.home_position, leap_end, _leap_height, u)


func _u_at_x(x: float) -> float:
	return (lion.home_position.x - x) / (lion.home_position.x - leap_end.x)
