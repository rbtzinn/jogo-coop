extends PhoenixAttack
## Explosão de Brasas: o ovo pulsa (aviso) e cospe brasas para o alto que caem em arco onde estão os jogadores
## (no chão ou numa rocha) e espalhadas; cada uma estoura onde cai. Uma é o ovinho turquesa (parry). Logo
## depois vem uma segunda leva, um passo para cada lado de cada jogador (onde quem desviou costuma parar).
## args: [x onde cai cada brasa]; de VOLLEY em VOLLEY, uma leva.

const PULSE := 0.6
const GAP := 0.12
const FLIGHT := 1.0
const ARC := 320.0
const SPLASH := 0.35
const FROM := Vector2(0, -300)
const VOLLEY := 5
const VOLLEY_GAP := 0.9

var _pink := 0
var _embers: Array[PhoenixProp] = []
var _splashes: Array[PhoenixProp] = []
var _state: Array[int] = []


func _start() -> void:
	_pink = rng.randi_range(0, mini(args.size(), VOLLEY) - 1)
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
		var since: float = t - PULSE - (i / VOLLEY) * VOLLEY_GAP - (i % VOLLEY) * GAP
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
	var last := args.size() - 1
	return elapsed > PULSE + (last / VOLLEY) * VOLLEY_GAP + (last % VOLLEY) * GAP + FLIGHT + SPLASH + 0.05
