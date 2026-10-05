extends JugglerAttack
## Totem Andante (fase 2): o totem atravessa a arena andando enquanto o de cima joga claves
## para o alto; elas caem em lugares marcados por uma sombra no chão.
## Para o totem: subir num pedestal (ele passa por baixo) ou atravessar com o dash.
## Às vezes uma clave é rosa.

const WALK_START := 0.6
const WALK_TIME := 2.6
const CLUB_TIMES := [0.3, 0.85, 1.4, 1.95]
## Da clave sair da mão até cair no chão.
const FALL_TIME := 1.1
const RISE_TIME := 0.35
const FLOOR_Y := 1000.0
const SPOTS := [330.0, 620.0, 900.0, 1180.0, 1460.0]
const PINK_CHANCE := 0.4

var _from_x := 0.0
var _to_x := 0.0
## Cada clave: [objeto, sombra, x onde cai, já criada, já caiu].
var _clubs: Array = []
var _pink_index := -1


func _start() -> void:
	_from_x = boss.base().global_position.x
	_to_x = JugglersBoss.HOME_RIGHT.x if _from_x < 960.0 else JugglersBoss.HOME_LEFT.x
	var spots := SPOTS.duplicate()
	for i in range(spots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = spots[i]
		spots[i] = spots[j]
		spots[j] = swap
	_pink_index = rng.randi_range(0, CLUB_TIMES.size() - 1) if rng.randf() < PINK_CHANCE else -1
	_clubs.clear()
	for i in CLUB_TIMES.size():
		_clubs.append([null, null, spots[i], false, false])
	var direction := 1 if _to_x > _from_x else -1
	boss.base().facing = direction
	boss.top().facing = direction


func _tick(t: float) -> void:
	var u := clampf((t - WALK_START) / WALK_TIME, 0.0, 1.0)
	boss.place_group(lerpf(_from_x, _to_x, ease(u, -1.4)), false)
	boss.base().walking = u > 0.0 and u < 1.0
	var throwing := false
	for i in _clubs.size():
		var club: Array = _clubs[i]
		var since: float = t - CLUB_TIMES[i]
		if since >= -0.2 and since < 0.1:
			throwing = true
		if since < 0.0:
			continue
		if not club[3]:
			club[3] = true
			club[0] = make_prop(&"club", i == _pink_index, i)
			club[0].spin_speed = 3.0
			boss.top().throw_released = true
			var shadow := LandingShadow.new()
			shadow.radius = Vector2(60, 12)
			add_child(shadow)
			shadow.global_position = Vector2(club[2], FLOOR_Y)
			club[1] = shadow
		var prop: JugglerProp = club[0] if is_instance_valid(club[0]) else null
		var shadow: LandingShadow = club[1] if is_instance_valid(club[1]) else null
		if is_instance_valid(shadow):
			shadow.amount = since / FALL_TIME
		if not is_instance_valid(prop):
			continue
		if since < RISE_TIME:
			# Sobe da mão até sair por cima da tela.
			# No 1º quadro em que aparece ela fica na mão desenhada; depois sobe.
			var hand := boss.top().hand_position()
			var rise := maxf(since - 1.0 / 60.0, 0.0)
			prop.global_position = hand.lerp(Vector2(hand.x, -80.0), ease(rise / RISE_TIME, 0.5))
		elif since < FALL_TIME:
			var k := (since - RISE_TIME) / (FALL_TIME - RISE_TIME)
			prop.global_position = Vector2(club[2], lerpf(-80.0, FLOOR_Y - 24.0, k * k))
		elif not club[4]:
			club[4] = true
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), Vector2(club[2], FLOOR_Y))
			prop.queue_free()
			if is_instance_valid(shadow):
				shadow.queue_free()
	boss.top().pose = &"throw" if throwing else &"sit"


func _is_done() -> bool:
	return elapsed >= maxf(WALK_START + WALK_TIME, CLUB_TIMES[-1] + FALL_TIME) + 0.3


func _stop() -> void:
	for club in _clubs:
		if is_instance_valid(club[1]):
			club[1].queue_free()
	boss.base().walking = false
	boss.top().pose = &"sit"
	boss.place_group(_to_x)
