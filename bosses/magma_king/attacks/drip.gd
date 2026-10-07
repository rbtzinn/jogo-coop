extends MagmaAttack
## Goteira: anda pelo lago e bate no peito, bravo; a caverna treme e pingos de lava caem do teto um
## depois do outro, cada um avisado por uma sombra onde vai cair (no chão ou no tampo de uma jangada).
## Um pingo é turquesa (parry).
## args: [x de onde sai, x para onde anda, x de cada pingo...].

const BEATS := 0.8
const FIRST := 1.0
const GAP := 0.22
const SHADOW := 0.55
const FALL := 0.5
const SPLASH := 0.3
const TOP_Y := -60.0

var _count := 0
var _pink := 0
var _drops: Array[MagmaProp] = []
var _splashes: Array[MagmaProp] = []
var _shadows: Array[LandingShadow] = []


func _start() -> void:
	_count = args.size() - 2
	_pink = rng.randi_range(0, _count - 1)
	_drops.clear()
	_splashes.clear()
	_shadows.clear()
	for i in _count:
		_drops.append(null)
		_splashes.append(null)
		_shadows.append(null)


func _tick(t: float) -> void:
	if wade(t):
		return
	var beat := t - WADE
	king.pose(&"lake", 6 if beat < BEATS and int(beat * 5.0) % 2 == 0 else 2)
	for i in _count:
		var x := float(args[i + 2])
		var ground := surface_y(x)
		var since := t - (WADE + FIRST + i * GAP)
		if since < 0.0:
			continue
		# Sombra no chão, desde o aviso até o pingo chegar.
		if since < SHADOW + FALL:
			if _shadows[i] == null:
				var shadow := LandingShadow.new()
				shadow.radius = Vector2(46, 11)
				add_child(shadow)
				shadow.global_position = Vector2(x, ground - 4.0)
				_shadows[i] = shadow
			_shadows[i].amount = since / (SHADOW + FALL)
		elif _shadows[i] != null:
			_shadows[i].queue_free()
			_shadows[i] = null
		var fall := since - SHADOW
		if fall >= 0.0 and fall < FALL:
			if _drops[i] == null:
				_drops[i] = spawn(&"drop_parry" if i == _pink else &"drop", Vector2(x, TOP_Y), i == _pink, i)
			_drops[i].global_position = Vector2(x, lerpf(TOP_Y, ground - 20.0, pow(fall / FALL, 1.6)))
		elif fall >= FALL:
			if _drops[i] != null:
				free_prop(_drops[i])
				_drops[i] = null
				if i != _pink:
					_splashes[i] = spawn(&"splash", Vector2(x, ground), false, i)
			var splash := _splashes[i]
			if splash != null and is_instance_valid(splash):
				var u := (fall - FALL) / SPLASH
				splash.frame = mini(int(u * 3.0), 2)
				splash.active = u < 0.35
				if u >= 1.0:
					free_prop(splash)


func _is_done() -> bool:
	return elapsed > WADE + FIRST + (_count - 1) * GAP + SHADOW + FALL + SPLASH + 0.05


func _stop() -> void:
	for shadow in _shadows:
		if shadow != null and is_instance_valid(shadow):
			shadow.queue_free()
