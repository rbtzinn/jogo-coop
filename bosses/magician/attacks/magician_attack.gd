class_name MagicianAttack
extends BossAttack
## Base dos ataques do Grande Mágico: põe o mágico onde o host disse (args) e cuida dos
## objetos criados pelo ataque (somem quando ele acaba). Objetos que andam em linha reta
## (cartas, serras, rajadas) são movidos aqui mesmo, pelo tempo do ataque.
## Cada ataque sobrescreve `_start()`, `_tick(t)`, `_stop()` e `_is_done()`.

var _props: Array[MagicProp] = []
## Objetos em linha reta: [objeto, origem, velocidade (vetor), tempo em que saiu, vida (s)].
var _straight: Array = []
## Objetos que perseguem (ver `launch_homing`), por número.
var _homing := {}

@onready var boss: MagicianBoss = get_parent().get_parent()


func _on_begin() -> void:
	boss.apply_args(args)
	_clear_props()
	_start()


func _on_tick(_delta: float) -> void:
	for item in _straight:
		var prop: MagicProp = item[0] if is_instance_valid(item[0]) else null
		if prop == null:
			continue
		var since: float = elapsed - item[3]
		if since > item[4]:
			prop.queue_free()
			continue
		prop.global_position = item[1] + item[2] * since
	for id: int in _homing:
		_move_homing(id)
	_tick(elapsed)


func _on_end() -> void:
	_clear_props()
	_stop()


## Os dois alvos (x dos jogadores quando o ataque começou).
func targets() -> Array[float]:
	var result: Array[float] = [960.0, 960.0]
	if args.size() >= 4:
		result = [args[2], args[3]]
	return result


func make_prop(kind: StringName, pink: bool, index: int) -> MagicProp:
	var prop := MagicProp.new()
	prop.kind = kind
	prop.pink = pink
	prop.parry_id = "%s:%d:%d" % [name, rng.seed, index]
	add_child(prop)
	_props.append(prop)
	return prop


## Objeto que sai de `origin` andando reto com `velocity` a partir de agora.
func launch(kind: StringName, pink: bool, index: int, origin: Vector2, velocity: Vector2, life: float) -> MagicProp:
	var prop := make_prop(kind, pink, index)
	prop.heading = velocity.normalized()
	prop.global_position = origin
	_straight.append([prop, origin, velocity, elapsed, life])
	return prop


## Leque de cartas: `angles` em graus a partir de `direction` (negativo = para cima),
## sem a carta `gap`; a carta `pink_index` é um ás rosa.
func throw_fan(origin: Vector2, direction: Vector2, angles: Array, gap: int, pink_index: int, index_base: int,
		speed := 720.0) -> void:
	for i in angles.size():
		if i == gap:
			continue
		var dir := direction.rotated(deg_to_rad(angles[i]) * signf(direction.x if direction.x != 0.0 else 1.0))
		launch(&"card", i == pink_index, index_base + i, origin, dir * speed, 3.2)


func _clear_props() -> void:
	for prop in _props:
		if is_instance_valid(prop):
			prop.queue_free()
	_props.clear()
	_straight.clear()
	_homing.clear()


func _start() -> void:
	pass


func _tick(_t: float) -> void:
	pass


func _stop() -> void:
	pass


# --- Objetos que perseguem ---
# A trajetória é uma conta fechada: reto até `delay`, depois `steps` trechos de STEER_STEP segundos, cada
# um com giro constante (rad/s), e reto de novo. Quem decide o giro de cada trecho é o host, no começo do
# trecho, com a posição do alvo que ele vê (`_steer_homing`), e manda para o cliente; os dois PCs calculam a
# mesma trajetória a partir dos mesmos números. O cliente, enquanto o giro de um trecho não chega, repete o
# do trecho anterior e corrige quando chega.

const STEER_STEP := 0.1
## Para de virar se o alvo ficar mais que isto fora da frente (sem meia-volta nem órbita).
const STEER_GIVE_UP := deg_to_rad(120.0)


## Objeto que sai reto de `origin` no ângulo `angle` e, depois de `delay`, vira para o jogador do slot
## `target_slot` (-1 = ninguém, segue reto) por `steps` trechos, no máximo `max_turn` rad/s.
func launch_homing(kind: StringName, pink: bool, index: int, origin: Vector2, angle: float, speed: float,
		life: float, target_slot: int, delay: float, steps: int, max_turn: float) -> MagicProp:
	var prop := make_prop(kind, pink, index)
	prop.heading = Vector2.from_angle(angle)
	prop.homing = true
	prop.global_position = origin
	var turns: Array[float] = []
	turns.resize(steps)
	turns.fill(NAN)
	_homing[index] = {"prop": prop, "origin": origin, "angle": angle, "speed": speed, "start": elapsed,
			"life": life, "slot": target_slot, "delay": delay, "turns": turns, "max_turn": max_turn,
			"stopped": target_slot < 0, "decided": 0}
	return prop


## Giro de um trecho que chegou do host (cliente).
func set_homing_turn(index: int, step: int, turn: float) -> void:
	if _homing.has(index) and step < _homing[index].turns.size():
		_homing[index].turns[step] = turn


## Alvo de um objeto que persegue (o host decide; o cliente recebe). -1 = ninguém.
func set_homing_target(index: int, target_slot: int) -> void:
	if _homing.has(index):
		_homing[index].slot = target_slot


## Jogador do slot (0 = P1, 1 = P2) que está na luta; null se saiu.
func player_in_slot(target_slot: int) -> Player:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.slot == target_slot:
			return player
	return null


## Posição e ângulo do objeto `since` segundos depois de sair, pelos giros conhecidos (os que faltam repetem
## o anterior).
func homing_state(id: int, since: float) -> Array:
	var h: Dictionary = _homing[id]
	var speed: float = h.speed
	var angle: float = h.angle
	var pos: Vector2 = h.origin
	var straight := minf(since, h.delay)
	pos += Vector2.from_angle(angle) * speed * straight
	var t: float = since - straight
	var turn := 0.0
	for k in (h.turns as Array).size():
		if t <= 0.0:
			break
		var known: float = h.turns[k]
		if not is_nan(known):
			turn = known
		var span := minf(t, STEER_STEP)
		pos += _arc(angle, turn, speed, span)
		angle += turn * span
		t -= span
	if t > 0.0:
		pos += Vector2.from_angle(angle) * speed * t
	return [pos, angle]


static func _arc(angle: float, turn: float, speed: float, span: float) -> Vector2:
	if absf(turn) < 0.000001:
		return Vector2.from_angle(angle) * speed * span
	return Vector2(sin(angle + turn * span) - sin(angle), cos(angle) - cos(angle + turn * span)) * (speed / turn)


func _move_homing(id: int) -> void:
	var h: Dictionary = _homing[id]
	var prop: MagicProp = h.prop if is_instance_valid(h.prop) else null
	if prop == null:
		return
	var since: float = elapsed - h.start
	if since > h.life:
		prop.queue_free()
		return
	if boss.is_brain():
		_steer_homing(id, since)
	var state := homing_state(id, since)
	prop.global_position = state[0]
	prop.heading = Vector2.from_angle(state[1])


## Host: decide o giro de cada trecho que já começou (com a posição do alvo agora) e manda para o cliente.
func _steer_homing(id: int, since: float) -> void:
	var h: Dictionary = _homing[id]
	var turns: Array = h.turns
	while h.decided < turns.size() and since >= h.delay + h.decided * STEER_STEP:
		var k: int = h.decided
		var turn := 0.0
		if not h.stopped:
			var state := homing_state(id, h.delay + k * STEER_STEP)
			var target := player_in_slot(h.slot)
			if target == null or target.player_health.is_downed:
				h.stopped = true
			else:
				var aim := target.target_position() + Vector2(0, -60)
				var off := wrapf((aim - (state[0] as Vector2)).angle() - float(state[1]), -PI, PI)
				if absf(off) > STEER_GIVE_UP:
					h.stopped = true
				else:
					turn = clampf(off / STEER_STEP, -h.max_turn, h.max_turn)
		turns[k] = turn
		h.decided = k + 1
		boss.sync.send_attack_event(name, run_seed, [&"turn", id, k, turn])


func _on_event(data: Array) -> void:
	if data.size() >= 4 and data[0] == &"turn":
		set_homing_turn(data[1], data[2], data[3])
