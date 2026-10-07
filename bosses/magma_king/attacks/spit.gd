extends MagmaAttack
## Cuspe Real: engole uma tocha, as bochechas incham e brilham (aviso) e ele cospe bolas de lava em
## arco; cada uma deixa uma poça no chão por um instante. Às vezes uma das bolas é a gema turquesa
## (parry), que não deixa poça. Na fase 3 (`fast`) é mais rápido e com 4 bolas.
## args: [x onde cai cada bola] (o host mira nos jogadores e espalha o resto).

const SWALLOW := 0.45
const WARN := 0.6
const FIRE_HOLD := 0.45
const WIPE := 0.4
const FLIGHT := 0.85
const GAP := 0.14
const ARC := 260.0
const PUDDLE := 1.0
const PINK_CHANCE := 0.5

@export var fast := false

var _speed := 1.0
var _pink := -1
## Por bola: 0 = ainda na boca, 1 = voando, 2 = caiu.
var _state: Array[int] = []
var _balls: Array[MagmaProp] = []
var _puddles: Array[MagmaProp] = []


func _start() -> void:
	_speed = 1.4 if fast else 1.0
	_pink = rng.randi_range(0, args.size() - 1) if rng.randf() < PINK_CHANCE else -1
	_state.clear()
	_balls.clear()
	_puddles.clear()
	for i in args.size():
		_state.append(0)
		_balls.append(null)
		_puddles.append(null)


func _fire_time() -> float:
	return (SWALLOW + WARN) / _speed


func _tick(t: float) -> void:
	var fire := _fire_time()
	if king.mode == MagmaKing.Mode.MOLTEN:
		king.pose(&"molten", 4 if t < fire else 5)
	elif t < SWALLOW / _speed:
		king.pose(&"spit", 0)
	elif t < fire:
		king.pose(&"spit", 1)
	elif t < fire + FIRE_HOLD / _speed:
		king.pose(&"spit", 2)
	else:
		king.pose(&"spit", 3)
	king.shake = 0.5 if t > SWALLOW / _speed and t < fire else 0.0
	var mouth := king.mouth()
	for i in args.size():
		var since := t - fire - i * GAP / _speed
		if since < 0.0:
			continue
		var flight := FLIGHT / _speed
		var target := Vector2(float(args[i]), FLOOR_Y - 30.0)
		if since < flight:
			if _state[i] == 0:
				_state[i] = 1
				_balls[i] = spawn(&"gem" if i == _pink else &"ball", mouth, i == _pink, i)
			_balls[i].global_position = arc_point(mouth, target, ARC, since / flight)
		else:
			if _state[i] < 2:
				_state[i] = 2
				free_prop(_balls[i])
				if i != _pink:
					_puddles[i] = spawn(&"puddle", Vector2(target.x, FLOOR_Y))
			var puddle := _puddles[i]
			if puddle != null and is_instance_valid(puddle):
				var u := (since - flight) / PUDDLE
				puddle.frame = 0 if u < 0.15 else (3 if u > 0.8 else 1 + int(u * 8.0) % 2)
				puddle.active = u < 0.85
				if u >= 1.0:
					free_prop(puddle)
					_puddles[i] = null


func _is_done() -> bool:
	return elapsed > _fire_time() + (args.size() - 1) * GAP / _speed + FLIGHT / _speed + PUDDLE + 0.05 \
			and elapsed > _fire_time() + (FIRE_HOLD + WIPE) / _speed
