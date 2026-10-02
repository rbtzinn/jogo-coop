extends BossAttack
## Patada (fase 2): Leopoldo salta bem alto e cai onde um jogador estava. Uma sombra no chão
## avisa onde ele vai cair. Ao cair, solta duas ondas de poeira rente ao chão (pular).
## args: [x do leão, y do leão, x do alvo].

const CROUCH_END := 0.45
const LAND_AT := 1.35
const HOLD := 0.35
const WAVE_SPEED := 700.0
const WAVE_RANGE := 420.0

@export var lion_path: NodePath
@export var floor_y := 1000.0
@export var left_x := 230.0
@export var right_x := 1450.0
@export var leap_height := 560.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _shadow := LandingShadow.new()
var _waves: Array[WhipWave] = []
var _landed := false

@onready var lion: TamerLion = get_node(lion_path)


func _ready() -> void:
	add_child(_shadow)
	_shadow.hide()


func _on_begin() -> void:
	_from = Vector2(args[0], args[1]) if args.size() >= 2 else lion.global_position
	var target_x: float = args[2] if args.size() >= 3 else _from.x
	_to = Vector2(clampf(target_x, left_x, right_x), floor_y)
	lion.place(_from)
	lion.set_facing(-1 if _to.x < _from.x else 1)
	lion.idle = false
	_shadow.global_position = _to
	_shadow.amount = 0.0
	_shadow.show()
	_landed = false
	_waves.clear()


func _on_tick(_delta: float) -> void:
	var t := elapsed
	_shadow.amount = t / LAND_AT
	if t < CROUCH_END:
		var k := t / CROUCH_END
		lion.body.scale = Vector2(1.0 + k * 0.1, 1.0 - k * 0.16)
	elif t < LAND_AT:
		lion.body.scale = Vector2(0.92, 1.08)
		var u := (t - CROUCH_END) / (LAND_AT - CROUCH_END)
		var at := arc_point(_from, _to, leap_height, u)
		lion.global_position = at
		lion.tilt_along(arc_point(_from, _to, leap_height, minf(u + 0.02, 1.0)) - at)
	else:
		if not _landed:
			_landed = true
			lion.place(_to)
			lion.idle = false
			_shadow.hide()
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), _to)
			for side in [-1.0, 1.0]:
				var wave := WhipWave.new()
				wave.scale.x = -side
				add_child(wave)
				_waves.append(wave)
		var since := t - LAND_AT
		lion.body.scale = Vector2(1.2, 0.8).lerp(Vector2.ONE, minf(since / HOLD, 1.0))
		for i in _waves.size():
			var wave := _waves[i]
			if not is_instance_valid(wave):
				continue
			var side := -1.0 if i == 0 else 1.0
			var travel := WAVE_SPEED * since
			wave.global_position = _to + Vector2(side * (90.0 + travel), 0)
			if travel > WAVE_RANGE:
				wave.queue_free()


func _is_done() -> bool:
	return elapsed >= LAND_AT + maxf(HOLD, WAVE_RANGE / WAVE_SPEED) + 0.05


func _on_end() -> void:
	_shadow.hide()
	for wave in _waves:
		if is_instance_valid(wave):
			wave.queue_free()
	_waves.clear()
	lion.place(_to)
