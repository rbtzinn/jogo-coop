extends JugglerAttack
## Chuva de Tochas (fase 3): de cima do monociclo, os irmãos jogam tochas para o alto; cada
## uma cai num lugar marcado por uma sombra e deixa fogo no chão por um instante.
## Sempre sobra um lugar livre. Às vezes uma tocha é rosa (não deixa fogo).

const TIMES := [0.3, 0.7, 1.1, 1.5, 1.9]
const RISE_TIME := 0.3
const FALL_TIME := 1.05
const FIRE_TIME := 0.9
const FLOOR_Y := 1000.0
const SPOTS := [330.0, 590.0, 850.0, 1110.0, 1370.0, 1630.0]
const PINK_CHANCE := 0.4

## Cada tocha: [objeto, sombra, fogo, x, já criada, já caiu].
var _torches: Array = []
var _pink_index := -1


func _start() -> void:
	var spots := SPOTS.duplicate()
	for i in range(spots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = spots[i]
		spots[i] = spots[j]
		spots[j] = swap
	_pink_index = rng.randi_range(0, TIMES.size() - 1) if rng.randf() < PINK_CHANCE else -1
	_torches.clear()
	for i in TIMES.size():
		_torches.append([null, null, null, spots[i], false, false])


func _tick(t: float) -> void:
	var top_throwing := false
	var base_throwing := false
	for i in _torches.size():
		var torch: Array = _torches[i]
		var since: float = t - TIMES[i]
		var thrower := boss.top() if i % 2 == 0 else boss.base()
		if since >= -0.2 and since < 0.1:
			if i % 2 == 0:
				top_throwing = true
			else:
				base_throwing = true
		if since < 0.0:
			continue
		if not torch[4]:
			torch[4] = true
			torch[0] = make_prop(&"torch", i == _pink_index, i)
			torch[0].spin_speed = 2.5
			var shadow := LandingShadow.new()
			shadow.radius = Vector2(70, 14)
			add_child(shadow)
			shadow.global_position = Vector2(torch[3], FLOOR_Y)
			torch[1] = shadow
		var prop: JugglerProp = torch[0] if is_instance_valid(torch[0]) else null
		var shadow: LandingShadow = torch[1] if is_instance_valid(torch[1]) else null
		if is_instance_valid(shadow):
			shadow.amount = since / FALL_TIME
		if since < RISE_TIME:
			if is_instance_valid(prop):
				var hand := thrower.hand_position()
				prop.global_position = hand.lerp(Vector2(hand.x, -80.0), ease(since / RISE_TIME, 0.5))
		elif since < FALL_TIME:
			if is_instance_valid(prop):
				var k := (since - RISE_TIME) / (FALL_TIME - RISE_TIME)
				prop.global_position = Vector2(torch[3], lerpf(-80.0, FLOOR_Y - 30.0, k * k))
		elif not torch[5]:
			torch[5] = true
			var lit := is_instance_valid(prop) and not prop.popped
			if is_instance_valid(prop):
				prop.queue_free()
			if is_instance_valid(shadow):
				shadow.queue_free()
			if lit and i != _pink_index:
				var fire := FirePatch.new()
				add_child(fire)
				fire.global_position = Vector2(torch[3], FLOOR_Y)
				torch[2] = fire
		elif is_instance_valid(torch[2]):
			var burn: float = since - FALL_TIME
			if burn >= FIRE_TIME:
				torch[2].queue_free()
			else:
				torch[2].strength = 1.0 - maxf(0.0, burn - FIRE_TIME * 0.7) / (FIRE_TIME * 0.3)
	boss.top().pose = &"throw" if top_throwing else &"sit"
	boss.base().pose = &"throw" if base_throwing else &"ride"


func _is_done() -> bool:
	return elapsed >= TIMES[-1] + FALL_TIME + FIRE_TIME + 0.1


func _stop() -> void:
	for torch in _torches:
		for node in [torch[1], torch[2]]:
			if is_instance_valid(node):
				node.queue_free()
	boss.top().pose = &"sit"
	boss.base().pose = &"ride"
