extends PhoenixAttack
## Explosão de Brasas: o ovo pulsa (aviso) e cospe brasas para o alto que caem em arco onde estão os jogadores
## (no chão ou numa rocha) e espalhadas; cada uma estoura onde cai. Uma é o ovinho turquesa (parry).
## args: [x onde cai cada brasa].

const PULSE := 0.6
const GAP := 0.12
const FLIGHT := 1.0
const ARC := 320.0
const SPLASH := 0.35
const FROM := Vector2(0, -300)

var _pink := 0
var _embers: Array[PhoenixProp] = []
var _splashes: Array[PhoenixProp] = []
var _state: Array[int] = []


func _start() -> void:
	_pink = rng.randi_range(0, args.size() - 1)
	_embers.clear()
	_splashes.clear()
	_state.clear()
	for i in args.size():
		_embers.append(null)
		_splashes.append(null)
		_state.append(0)


func _tick(t: float) -> void:
	bird.pose(&"egg", 3 if t < PULSE else 4)
	bird.shake = 0.35 if t < PULSE else 0.0
	var from := bird.global_position + FROM
	for i in args.size():
		var since: float = t - PULSE - i * GAP
		if since < 0.0:
			continue
		var x := float(args[i])
		var ground := surface_y(x)
		var pink := i == _pink
		if since < FLIGHT:
			if _state[i] == 0:
				_state[i] = 1
				_embers[i] = spawn(&"egg_parry" if pink else &"spark", from, pink, i)
			_embers[i].global_position = arc_point(from, Vector2(x, ground - 20.0), ARC, since / FLIGHT)
			continue
		if _state[i] < 2:
			_state[i] = 2
			free_prop(_embers[i])
			if not pink:
				_splashes[i] = spawn(&"egg_splash", Vector2(x, ground), false, i)
		var splash := _splashes[i]
		if splash != null and is_instance_valid(splash):
			var u: float = (since - FLIGHT) / SPLASH
			splash.frame = 0 if u < 0.5 else 1
			splash.active = u < 0.45
			if u >= 1.0:
				free_prop(splash)


func _is_done() -> bool:
	return elapsed > PULSE + (args.size() - 1) * GAP + FLIGHT + SPLASH + 0.05
