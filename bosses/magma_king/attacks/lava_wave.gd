extends MagmaAttack
## Onda de Lava: anda pelo lago, se inclina para trás com os braços erguidos puxando o ar (aviso) e
## empurra uma onda de lava que corre pelo chão até sair pela esquerda. Pular por cima ou subir numa
## jangada (a onda não chega lá). Às vezes vem uma segunda onda logo atrás.
## args: [x de onde sai, x para onde anda].

const INHALE := 0.8
const PUSH_HOLD := 0.45
const SPEED := 640.0
const SECOND_GAP := 0.95
const EXIT_X := -200.0
const RISE := 0.2

var _times: Array[float] = []
var _waves: Array[MagmaProp] = []
var _from_x := 0.0


func _start() -> void:
	_times = [WADE + INHALE]
	if rng.randf() < 0.5:
		_times.append(WADE + INHALE + SECOND_GAP)
	_waves.clear()
	for i in _times.size():
		_waves.append(null)
	_from_x = float(args[1]) - 130.0


func _tick(t: float) -> void:
	if wade(t):
		return
	if t < WADE + INHALE:
		king.pose(&"lake", 4)
		king.shake = 0.4
	elif t < _times[-1] + PUSH_HOLD:
		king.pose(&"lake", 5)
		king.shake = 0.0
	else:
		king.pose(&"lake", 0)
	for i in _times.size():
		var since := t - _times[i]
		if since < 0.0:
			continue
		var x := _from_x - SPEED * since
		if _waves[i] == null and x > EXIT_X:
			_waves[i] = spawn(&"wave", Vector2(x, FLOOR_Y), false, i)
		var wave := _waves[i]
		if wave == null or not is_instance_valid(wave):
			continue
		wave.global_position.x = x
		wave.frame = 0 if since < RISE else 1 + int(since * 8.0) % 2
		if x < EXIT_X:
			free_prop(wave)


func _is_done() -> bool:
	return elapsed > _times[-1] + (_from_x - EXIT_X) / SPEED + 0.05
