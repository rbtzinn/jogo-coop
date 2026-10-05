extends MagicianAttack
## Cartas Gigantes (fase 3): as mãos do gigante, uma de cada vez, jogam leques de cartas de
## cima para baixo, atravessando o palco para o outro lado. Cada leque tem um buraco; um ás é
## rosa.

const THROWS := [0.6, 1.4, 2.2, 3.0]
## Ângulos abaixo da horizontal (positivo = para baixo).
const ANGLES := [8.0, 20.0, 32.0, 44.0, 56.0]

var _gaps: Array[int] = []
var _pink_throw := 0
var _thrown := 0


func _start() -> void:
	boss.hands_busy = true
	_gaps.clear()
	for i in THROWS.size():
		_gaps.append(rng.randi_range(0, ANGLES.size() - 1))
	_pink_throw = rng.randi_range(0, THROWS.size() - 1)
	_thrown = 0


func _tick(t: float) -> void:
	for i in THROWS.size():
		var hand: GiantHand = boss.left_hand if i % 2 == 0 else boss.right_hand
		var since: float = t - THROWS[i]
		var rest := boss.hand_rest(hand)
		if since > -0.4 and since < 0.3:
			# Puxa para trás (aviso) e joga.
			var back := clampf((since + 0.4) / 0.4, 0.0, 1.0)
			hand.global_position = rest + Vector2(-hand.side * 80.0 * back, -60.0 * back)
			hand.closed = 1.0 if since < 0.0 else 0.0
		elif since >= 0.3 and since < 0.6:
			hand.global_position = hand.global_position.lerp(rest, 0.2)
	while _thrown < THROWS.size() and t >= THROWS[_thrown]:
		var hand: GiantHand = boss.left_hand if _thrown % 2 == 0 else boss.right_hand
		var direction := Vector2(-hand.side, 0)
		var pink := (_gaps[_thrown] + 2) % ANGLES.size() if _thrown == _pink_throw else -1
		throw_fan(hand.global_position + Vector2(0, 80), direction, ANGLES, _gaps[_thrown], pink, _thrown * 10, 680.0)
		_thrown += 1


func _is_done() -> bool:
	return elapsed >= THROWS[-1] + 3.0


func _stop() -> void:
	for hand: GiantHand in [boss.left_hand, boss.right_hand]:
		hand.closed = 0.0
	boss.hands_busy = false
