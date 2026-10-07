extends PhoenixAttack
## Ovinhos de Brasa: o pescoço incha (aviso) e ela cospe 3 ovinhos em arco, mirando em quem está de pé (no chão
## ou numa rocha). Cada um racha e choca um pintinho de brasa que corre para a esquerda (pular por cima); se
## nasceu numa rocha, corre até a beira e cai no chão. Um ovinho é turquesa (parry) e não choca.
## args: [x onde cai cada ovinho].

const THROAT := 0.6
const SPITS := [0.6, 0.95, 1.3]
const SPIT_POSE := 0.22
const FLIGHT := 0.8
const ARC := 220.0
const CRACK := 0.45
const RUN := 360.0
const FALL_SPEED := 900.0
const EXIT_X := -70.0
const PINK_HOLD := 0.7

var _pink := -1
var _eggs: Array[PhoenixProp] = []
var _chicks: Array[PhoenixProp] = []
var _from: Array[Vector2] = []


func _start() -> void:
	_pink = rng.randi_range(0, args.size() - 1)
	_eggs.clear()
	_chicks.clear()
	_from.clear()
	for i in args.size():
		_eggs.append(null)
		_chicks.append(null)
		_from.append(Vector2.ZERO)


func _tick(t: float) -> void:
	if t < THROAT:
		bird.pose(&"perch", 4)
		bird.shake = 0.3
	else:
		bird.shake = 0.0
		var spitting := false
		for at: float in SPITS:
			if t >= at and t < at + SPIT_POSE:
				spitting = true
		bird.pose(&"perch", 5 if spitting else 6)
	for i in args.size():
		var since: float = t - SPITS[i]
		if since < 0.0:
			continue
		var x := float(args[i])
		var ground := surface_y(x)
		var pink := i == _pink
		if since < FLIGHT:
			if _eggs[i] == null:
				_from[i] = bird.beak()
				_eggs[i] = spawn(&"egg_parry" if pink else &"egg", _from[i], pink, i)
			_eggs[i].global_position = arc_point(_from[i], Vector2(x, ground - 28.0), ARC, since / FLIGHT)
			continue
		if since < FLIGHT + CRACK:
			if _eggs[i] != null and _eggs[i].kind != &"egg_crack" and not pink:
				free_prop(_eggs[i])
				_eggs[i] = spawn(&"egg_crack", Vector2(x, ground), false, i)
			if _eggs[i] != null and not pink:
				_eggs[i].frame = 0 if since < FLIGHT + CRACK * 0.5 else 1
			elif _eggs[i] != null:
				_eggs[i].global_position = Vector2(x, ground - 28.0)
			continue
		if pink:
			if _eggs[i] != null and since > FLIGHT + PINK_HOLD:
				free_prop(_eggs[i])
				_eggs[i] = null
			continue
		if _eggs[i] != null:
			free_prop(_eggs[i])
			_eggs[i] = null
			_chicks[i] = spawn(&"chick", Vector2(x, ground), false, i)
		var chick := _chicks[i]
		if chick == null or not is_instance_valid(chick):
			continue
		var run_x: float = x - RUN * (since - FLIGHT - CRACK)
		if run_x < EXIT_X:
			free_prop(chick)
			continue
		# Corre pelo tampo onde nasceu; passou da beira de uma rocha, cai até o chão.
		var under := surface_y(run_x)
		if under < chick.global_position.y - 4.0:
			# A rocha está acima dele (corre por baixo dela).
			under = FLOOR_Y
		var y := minf(chick.global_position.y + FALL_SPEED * get_physics_process_delta_time(), under)
		chick.global_position = Vector2(run_x, y)


func _is_done() -> bool:
	var longest := 0.0
	for i in args.size():
		longest = maxf(longest, SPITS[i] + FLIGHT + CRACK + (float(args[i]) - EXIT_X) / RUN)
	return elapsed > longest + 0.05
