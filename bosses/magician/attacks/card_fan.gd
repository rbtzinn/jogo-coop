extends MagicianAttack
## Leque de Cartas (fase 1): o mágico ergue a varinha (aviso) e joga três leques de cartas
## para o lado dos jogadores. Cada leque tem um buraco (uma carta a menos) e uma carta preta que
## persegue um jogador por pouco tempo (no lugar de uma reta). As salvas miram P1, P2, P1...
## (o contador fica no chefão, a luta toda); uma placa "P1"/"P2" sobre o alvo avisa antes do leque.
## No ataque todo, duas cartas são ases rosa (parry), em leques diferentes, nunca a preta.
## Quem decide o alvo e o giro da preta é o host (ver MagicianAttack.launch_homing).

const WINDUP := 0.55
const FANS := [0.55, 1.2, 1.85]
## Ângulos das cartas em graus (negativo = para cima).
const ANGLES := [-34.0, -22.0, -10.0, 2.0, 14.0]
## Quanto antes de cada leque a placa do alvo aparece (e o host decide o alvo).
const WARN := 0.5
const PINKS := 2
## Direções (índices de ANGLES) em que a rosa pode sair: as que passam na altura do pulo dos jogadores; e as
## vizinhas, na ordem, se o buraco e a preta ocuparem as duas.
const REACHABLE := [2, 3]
const FALLBACK := [1, 4]

## Carta que persegue (escolhidos pelo piloto comparativo; ver DESIGN.md, "Marco de gameplay do Mágico").
var homing_speed := 560.0
var homing_delay := 0.2
var homing_steps := 8
var homing_turn := deg_to_rad(120.0)

var _gaps: Array[int] = []
var _homers: Array[int] = []
## Ás rosa de cada leque (-1 = nenhum).
var _pinks: Array[int] = []
## Alvo (slot) de cada leque: -2 = ainda não decidido, -1 = ninguém de pé.
var _targets: Array[int] = []
## Tempo do ataque em que o alvo de cada leque ficou conhecido aqui (no cliente, quando o aviso do host
## chegou; -1 = ainda não). Para medir o atraso da placa.
var _target_known_at: Array[float] = []
var _thrown := 0
var _marker := CardTargetMarker.new()


func _ready() -> void:
	add_child(_marker)
	_marker.hide()


func _start() -> void:
	var zaratan := boss.zaratan
	zaratan.facing = -1 if zaratan.global_position.x > 960.0 else 1
	_gaps.clear()
	_homers.clear()
	_pinks.clear()
	_targets.clear()
	_target_known_at.clear()
	for i in FANS.size():
		var gap := rng.randi_range(0, ANGLES.size() - 1)
		_gaps.append(gap)
		_homers.append((gap + 1 + rng.randi_range(0, ANGLES.size() - 2)) % ANGLES.size())
		_pinks.append(-1)
		_targets.append(-2)
		_target_known_at.append(-1.0)
	var pink_fans := [0, 1, 2]
	for i in range(pink_fans.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: int = pink_fans[i]
		pink_fans[i] = pink_fans[j]
		pink_fans[j] = swap
	# A rosa sai numa direção que passa onde os jogadores alcançam pulando (REACHABLE, as de -10° e 2°); só
	# se o buraco e a preta ocuparem as duas, vai para a vizinha mais perto.
	for f: int in pink_fans.slice(0, PINKS):
		var free: Array[int] = []
		for c: int in REACHABLE + FALLBACK:
			if c != _gaps[f] and c != _homers[f]:
				free.append(c)
			if free.size() == 2 or (free.size() == 1 and c == REACHABLE[-1]):
				break
		_pinks[f] = free[rng.randi_range(0, free.size() - 1)]
	_thrown = 0
	_marker.hide()


func _tick(t: float) -> void:
	var zaratan := boss.zaratan
	if boss.is_brain():
		for i in FANS.size():
			if _targets[i] == -2 and t >= FANS[i] - WARN:
				_set_target(i, boss.next_card_target())
				boss.sync.send_attack_event(name, run_seed, [&"target", i, _targets[i]])
	_update_marker(t)
	if t < WINDUP:
		zaratan.pose = &"cast"
		return
	zaratan.pose = &"idle"
	for i in FANS.size():
		if t >= FANS[i] - 0.15 and t < FANS[i] + 0.15:
			zaratan.pose = &"throw"
	while _thrown < FANS.size() and t >= FANS[_thrown]:
		_throw(_thrown, zaratan.hand_position(), Vector2(zaratan.facing, 0))
		_thrown += 1


## Um leque: as retas, sem o buraco; a preta sai na direção dela e persegue o alvo do leque.
func _throw(fan: int, origin: Vector2, direction: Vector2) -> void:
	var base := fan * 10
	for i in ANGLES.size():
		if i == _gaps[fan] or i == _homers[fan]:
			continue
		var dir := direction.rotated(deg_to_rad(ANGLES[i]) * signf(direction.x))
		launch(&"card", i == _pinks[fan], base + i, origin, dir * 720.0, 3.2)
	var angle := direction.rotated(deg_to_rad(ANGLES[_homers[fan]]) * signf(direction.x)).angle()
	var slot := maxi(_targets[fan], -1)
	var card := launch_homing(&"card", false, base + _homers[fan], origin, angle, homing_speed, 3.2, slot,
			homing_delay, homing_steps, homing_turn)
	card.homing_label = _slot_label(slot)


func _set_target(fan: int, slot: int) -> void:
	_targets[fan] = slot
	_target_known_at[fan] = elapsed
	var id: int = fan * 10 + _homers[fan]
	set_homing_target(id, slot)
	var card: MagicProp = _homing[id].prop if _homing.has(id) and is_instance_valid(_homing[id].prop) else null
	if card != null:
		card.homing_label = _slot_label(slot)


## A placa fica sobre o alvo do próximo leque, de WARN antes até o leque sair.
func _update_marker(t: float) -> void:
	_marker.hide()
	if _thrown >= FANS.size() or t < FANS[_thrown] - WARN:
		return
	var target := player_in_slot(_targets[_thrown]) if _targets[_thrown] >= 0 else null
	if target == null or target.player_health.is_downed:
		return
	_marker.label = _slot_label(_targets[_thrown])
	_marker.global_position = target.global_position + Vector2(0, -215)
	_marker.show()


static func _slot_label(slot: int) -> String:
	return "P%d" % (slot + 1) if slot >= 0 else ""


func _on_event(data: Array) -> void:
	if data.size() >= 3 and data[0] == &"target":
		_set_target(data[1], data[2])
		return
	super(data)


## Os alvos das três salvas (para os testes e pilotos): slot, -1 ninguém, -2 ainda não decidido.
func salvo_targets() -> Array[int]:
	return _targets.duplicate()


## Quando o alvo de cada leque ficou conhecido neste PC (tempo do ataque; -1 = ainda não).
func target_known_at() -> Array[float]:
	return _target_known_at.duplicate()


func _is_done() -> bool:
	return elapsed >= FANS[-1] + 2.8


func _stop() -> void:
	_marker.hide()
	boss.zaratan.pose = &"idle"
