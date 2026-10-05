extends MagicianAttack
## Mãos que Agarram (fase 3): as mãos gigantes, uma de cada vez, vão para cima de onde um
## jogador estava (sombra no chão avisa) e descem fechando. Sair de baixo ou dar dash.

const GRABS := [0.3, 0.9, 1.5, 2.1]
const MOVE := 0.6
const HOLD := 0.15
const SLAM := 0.15
const ON_FLOOR := 0.35
const RISE := 0.5
const HOVER_Y := 520.0
const FLOOR_HAND_Y := 880.0

## Cada golpe: [mão, x do alvo, sombra].
var _grabs: Array = []


func _start() -> void:
	boss.hands_busy = true
	var aims := targets()
	_grabs.clear()
	for i in GRABS.size():
		var hand: GiantHand = boss.left_hand if i % 2 == 0 else boss.right_hand
		var x := clampf(aims[[0, 1, 1, 0][i]], 160.0, 1760.0)
		var shadow := LandingShadow.new()
		shadow.radius = Vector2(130, 20)
		add_child(shadow)
		shadow.global_position = Vector2(x, 1000.0)
		shadow.hide()
		# [mão, x, sombra, posição e closed da mão quando esta agarrada começou (null = ainda não)]
		_grabs.append([hand, x, shadow, null, 0.0])
	boss.giant.laugh = 0.0


func _tick(t: float) -> void:
	for hand: GiantHand in [boss.left_hand, boss.right_hand]:
		hand.hitbox.active = false
	var total := MOVE + HOLD + SLAM + ON_FLOOR + RISE
	# Cada mão segue só a agarrada mais nova que já começou: a seguinte da mesma mão começa 0,05 s antes de a
	# anterior sair do chão. Antes, a anterior continuava ligando o golpe e a mão pulava do chão para perto do
	# descanso, já aberta, num quadro (3 quadros de golpe ligado na mão aberta no ar).
	var current := {}
	for i in _grabs.size():
		var since_start: float = t - GRABS[i]
		if since_start >= 0.0 and since_start <= total:
			current[_grabs[i][0]] = i
	for i in _grabs.size():
		var grab: Array = _grabs[i]
		var hand: GiantHand = grab[0]
		var shadow: LandingShadow = grab[2]
		var since: float = t - GRABS[i]
		if since < 0.0 or since > total or current.get(hand, -1) != i:
			if since >= 0.0:
				shadow.hide()
			continue
		if grab[3] == null:
			grab[3] = hand.global_position
			grab[4] = hand.closed
		var rest := boss.hand_rest(hand)
		var above := Vector2(grab[1], HOVER_Y)
		var down := Vector2(grab[1], FLOOR_HAND_Y)
		shadow.visible = since < MOVE + HOLD + SLAM + ON_FLOOR
		shadow.amount = since / (MOVE + HOLD + SLAM)
		if since < MOVE:
			# Sai de onde a mão está (do descanso, ou do chão se a agarrada anterior foi cortada), abrindo.
			hand.global_position = (grab[3] as Vector2).lerp(above, ease(since / MOVE, -2.0))
			hand.closed = lerpf(grab[4], 0.0, clampf(since / (MOVE * 0.5), 0.0, 1.0))
		elif since < MOVE + HOLD:
			hand.global_position = above + Vector2(sin(since * 60.0) * 6.0, 0)
		elif since < MOVE + HOLD + SLAM:
			var u := (since - MOVE - HOLD) / SLAM
			hand.global_position = above.lerp(down, u * u)
			hand.closed = u
			hand.hitbox.active = u > 0.5
		elif since < MOVE + HOLD + SLAM + ON_FLOOR:
			if hand.global_position.y < FLOOR_HAND_Y - 1.0 or not hand.hitbox.active:
				Fx.spawn(preload("res://components/fx/dust_puff.tscn"), Vector2(grab[1], 1000.0))
			hand.global_position = down
			hand.closed = 1.0
			hand.hitbox.active = true
		else:
			var u := (since - MOVE - HOLD - SLAM - ON_FLOOR) / RISE
			hand.global_position = down.lerp(rest, ease(u, 0.5))
			hand.closed = 1.0 - u
	boss.giant.laugh = 1.0 if fmod(t, 1.2) < 0.4 else 0.0


func _is_done() -> bool:
	return elapsed >= GRABS[-1] + MOVE + HOLD + SLAM + ON_FLOOR + RISE + 0.1


func _stop() -> void:
	for grab in _grabs:
		if is_instance_valid(grab[2]):
			grab[2].queue_free()
	for hand: GiantHand in [boss.left_hand, boss.right_hand]:
		hand.hitbox.active = false
		hand.closed = 0.0
	boss.giant.laugh = 0.0
	boss.hands_busy = false
