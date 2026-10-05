extends JugglerAttack
## Bolas Quicando (fases 1 e 3): um irmão joga três bolas grandes que atravessam a arena
## quicando no chão. Pular quando a bola desce ou passar por baixo quando ela sobe.
## Às vezes uma delas é rosa.

const THROWS := [0.6, 1.3, 2.0]
const SPEED := 520.0
const DROP_TIME := 0.35
const BOUNCE_HEIGHT := 230.0
const BOUNCE_TIME := 0.75
const RADIUS := 22.0
const FLOOR_Y := 1000.0
const PINK_CHANCE := 0.4

var _thrower: Juggler
var _direction := 1.0
var _pink_index := -1
## Cada bola: [objeto, já criada].
var _balls: Array = []


func _start() -> void:
	if boss.mode == &"split":
		_thrower = boss.left() if rng.randf() < 0.5 else boss.right()
		# Quem está tonto não joga: joga o outro.
		if boss.started_dizzy(_thrower):
			_thrower = boss.right() if _thrower == boss.left() else boss.left()
	else:
		_thrower = boss.top()
	_direction = 1.0 if _thrower.global_position.x < 960.0 else -1.0
	_thrower.facing = int(_direction)
	_pink_index = rng.randi_range(0, THROWS.size() - 1) if rng.randf() < PINK_CHANCE else -1
	_balls.clear()
	for i in THROWS.size():
		_balls.append([null, false])


func _tick(t: float) -> void:
	var throwing := false
	for i in THROWS.size():
		var since: float = t - THROWS[i]
		var ball: Array = _balls[i]
		# Ficou tonto no meio: as bolas que faltavam não saem.
		if ball[0] == null and _thrower.dizzy:
			if since >= 0.0:
				ball[1] = true
			continue
		if since >= -0.25 and since < 0.1:
			throwing = true
		if since < 0.0:
			continue
		if not ball[1]:
			ball[1] = true
			ball[0] = make_prop(&"ball", i == _pink_index, i)
		var prop: JugglerProp = ball[0] if is_instance_valid(ball[0]) else null
		if not is_instance_valid(prop):
			continue
		prop.global_position = _ball_position(since)
		if prop.global_position.x < -80.0 or prop.global_position.x > 2000.0:
			prop.queue_free()
	if boss.mode == &"split":
		_thrower.pose = &"throw" if throwing else &"idle"


func _is_done() -> bool:
	return elapsed >= THROWS[-1] + DROP_TIME + 2000.0 / SPEED


func _stop() -> void:
	if boss.mode == &"split" and _thrower != null:
		_thrower.pose = &"idle"


## Primeiro cai da mão até o chão; depois quica andando para o outro lado.
func _ball_position(since: float) -> Vector2:
	var hand := _thrower.hand_position()
	var ground := FLOOR_Y - RADIUS
	if since < DROP_TIME:
		var u := since / DROP_TIME
		var contact := Vector2(hand.x + _direction * SPEED * DROP_TIME, ground)
		return Vector2(lerpf(hand.x, contact.x, u), lerpf(hand.y, ground, u * u))
	var x := hand.x + _direction * SPEED * since
	var s := fmod(since - DROP_TIME, BOUNCE_TIME) / BOUNCE_TIME
	return Vector2(x, ground - BOUNCE_HEIGHT * 4.0 * s * (1.0 - s))
