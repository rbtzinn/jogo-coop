extends MagmaAttack
## Momento de dupla — Coroa Pesada: anda pelo lago e atira a coroa, que cai e se crava no chão. Ele
## fica careca, desesperado, e a cabeça descoberta leva o DOBRO de dano enquanto alguém fica
## encostado na coroa (segurando). Duas mãos de basalto saem do lago e se arrastam até a coroa: o
## parceiro de quem segura precisa vencê-las a tiros; se uma chega, ele pega a coroa de volta.
## Sozinho (um jogador só de pé): sem mãos, e o dano dobrado vale por HOLD_SOLO segundos, sem segurar.
## args: [x de onde sai, x para onde anda, x onde a coroa cai, 1 em dupla / 0 sozinho].

const THROW := 0.35
const FLIGHT := 0.7
const WINDOW := 6.5
const HOLD_SOLO := 3.0
const RETURN := 0.6
const HOLD_RANGE := 110.0
const HAND_SPEED := 75.0
const HAND_START := 120.0
## Dano que vence uma mão (cada tiro vale 1 ou 2; ~3 s de tiro).
const HAND_HP := 20
const STUCK_Y := FLOOR_Y - 40.0

var _crown: MagmaProp
var _hands: Array[MagmaHand] = []
var _hand_hp: Array[int] = []
var _hand_start: Array[float] = []
## Quando a janela acabou (uma mão chegou, ou o tempo): a coroa volta.
var _end_at := -1.0
var _land_at := 0.0
var _duo := true


func _start() -> void:
	_crown = null
	_hands.clear()
	_hand_hp.clear()
	_hand_start.clear()
	_end_at = -1.0
	_duo = int(args[3]) == 1
	_land_at = WADE + THROW + FLIGHT


func _tick(t: float) -> void:
	if wade(t):
		return
	var head := king.global_position + Vector2(-10, -380)
	var spot := Vector2(float(args[2]), STUCK_Y)
	if t < WADE + THROW:
		king.pose(&"lake", 4)
		return
	if _crown == null:
		_crown = spawn(&"crown", head)
	if t < _land_at:
		_crown.global_position = arc_point(head, spot, 240.0, (t - WADE - THROW) / FLIGHT)
		return
	var window_end := _land_at + (WINDOW if _duo else HOLD_SOLO)
	if _end_at < 0.0 and t >= window_end:
		_end_at = window_end
	if _end_at >= 0.0 and t >= _end_at:
		# A coroa volta para a cabeça; a janela acabou.
		king.hurtbox.damage_multiplier = 1.0
		king.pose(&"lake", 3)
		_crown.global_position = arc_point(spot, head, 200.0, clampf((t - _end_at) / RETURN, 0.0, 1.0))
		_crown.active = true
		_crown.hold_frame = -1
		for hand in _hands:
			hand.set_beaten()
		return
	# Cravada no chão: não machuca; ele careca, tentando pegá-la de volta.
	_crown.global_position = spot
	_crown.active = false
	_crown.hold_frame = 1
	king.pose(&"lake", 7)
	king.shake = 0.25
	var held := _held(spot)
	king.hurtbox.damage_multiplier = 2.0 if held or not _duo else 1.0
	_crown.modulate = Color(1.4, 1.25, 1.0) if held or not _duo else Color.WHITE
	if _duo:
		_update_hands(t, spot)


## Alguém de pé encostado na coroa (cada PC vê pelas posições que tem; a favor de quem joga).
func _held(spot: Vector2) -> bool:
	for player in boss.alive_players():
		var at := player.global_position
		if absf(at.x - spot.x) < HOLD_RANGE and at.y > FLOOR_Y - 60.0:
			return true
	return false


func _update_hands(t: float, spot: Vector2) -> void:
	if _hands.is_empty():
		for i in 2:
			var hand := MagmaHand.new()
			add_child(hand)
			var x := king.global_position.x - HAND_START - i * 150.0
			hand.global_position = Vector2(x, FLOOR_Y)
			hand.reset_physics_interpolation()
			boss.connect_hurtbox(hand.hurtbox, hand, "hand%d" % i)
			_hands.append(hand)
			_hand_hp.append(HAND_HP)
			_hand_start.append(x)
	var since := t - _land_at
	for i in _hands.size():
		var hand := _hands[i]
		if hand.beaten:
			# Afunda e some.
			hand.position.y += 6.0
			hand.modulate.a = maxf(hand.modulate.a - 0.05, 0.0)
			continue
		# A segunda mão sai um pouco depois.
		var walk := maxf(since - i * 0.8, 0.0)
		hand.crawl = walk * 1.4
		hand.global_position.x = maxf(_hand_start[i] - HAND_SPEED * walk, spot.x + 70.0)
		if is_zero_approx(hand.global_position.x - (spot.x + 70.0)) and boss.is_brain():
			# Chegou na coroa: o host avisa e os dois PCs acabam a janela no mesmo instante.
			_finish(t)
			boss.sync.send_attack_event(name, run_seed, [&"grab", t])


## Tiro numa mão (só no cérebro; o BossBrain manda para cá o dano das partes "hand0"/"hand1").
func hand_damage(index: int, amount: int) -> void:
	if index >= _hands.size() or _hands[index].beaten:
		return
	_hand_hp[index] -= amount
	if _hand_hp[index] <= 0:
		_hands[index].set_beaten()
		boss.sync.send_attack_event(name, run_seed, [&"hand", index])


func _on_event(data: Array) -> void:
	match data[0]:
		&"hand":
			var index: int = data[1]
			if index < _hands.size():
				_hands[index].set_beaten()
		&"grab":
			_finish(float(data[1]))


func _finish(at: float) -> void:
	if _end_at < 0.0:
		_end_at = at


func _is_done() -> bool:
	return _end_at >= 0.0 and elapsed > _end_at + RETURN + 0.15


func _stop() -> void:
	king.hurtbox.damage_multiplier = 1.0
	for hand in _hands:
		if is_instance_valid(hand):
			hand.queue_free()
	_hands.clear()
