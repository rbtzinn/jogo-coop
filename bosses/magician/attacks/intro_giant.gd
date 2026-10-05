extends MagicianAttack
## Troca para a fase 3, "O Grande Final": a luz apaga, o mágico some, e da escuridão sobe um
## mágico gigante (cabeça, cartola e duas mãos enormes). A luz volta com ele já gargalhando.

const DARK := 0.6
const RISE_END := 2.1
const END := 2.7
const START_Y := 1400.0
const HEAD_Y := 420.0


func _start() -> void:
	boss.hands_busy = true
	boss.giant.global_position = Vector2(960, START_Y)
	boss.giant.reset_physics_interpolation()


func _tick(t: float) -> void:
	var zaratan := boss.zaratan
	if t < DARK:
		boss.darkness.darkness = t / DARK
		zaratan.pose = &"scared"
		return
	if zaratan.visible:
		zaratan.set_present(false)
		zaratan.hide()
		boss.show_giant(true)
		boss.giant.hurtbox.monitorable = false
	var u := clampf((t - DARK) / (RISE_END - DARK), 0.0, 1.0)
	boss.giant.global_position.y = lerpf(START_Y, HEAD_Y, ease(u, 0.4))
	boss.giant.laugh = clampf((t - RISE_END + 0.4) / 0.3, 0.0, 1.0)
	for hand: GiantHand in [boss.left_hand, boss.right_hand]:
		hand.presence = u
		hand.global_position = boss.hand_rest(hand) + Vector2(0, (1.0 - u) * 500.0)
	if t >= RISE_END:
		boss.darkness.darkness = clampf(1.0 - (t - RISE_END) / (END - RISE_END), 0.0, 1.0)


func _is_done() -> bool:
	return elapsed >= END


func _stop() -> void:
	boss.zaratan.hide()
	boss.zaratan.set_present(false)
	boss.show_giant(true)
	boss.giant.global_position = Vector2(960, HEAD_Y)
	boss.giant.laugh = 0.0
	boss.darkness.darkness = 0.0
	for hand: GiantHand in [boss.left_hand, boss.right_hand]:
		hand.presence = 1.0
	boss.hands_busy = false
