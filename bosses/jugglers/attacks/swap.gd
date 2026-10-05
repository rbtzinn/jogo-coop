extends JugglerAttack
## Troca de Lugar (fase 1): os dois se agacham (aviso) e trocam de lado num salto mortal.
## O da esquerda passa por cima, bem alto; o da direita vem rolando baixo, na altura do
## peito: abaixar (ou dar dash) desvia.

const CROUCH := 0.6
const FLIGHT := 1.0
const HIGH_APEX := 260.0
## Altura dos pés de quem rola por baixo (abaixado, o jogador passa por baixo dele).
const LOW_FEET_Y := 900.0

var _high: Juggler
var _low: Juggler
var _high_from := Vector2.ZERO
var _low_from := Vector2.ZERO
## Um ficou tonto ainda agachado: desistem da troca (o tonto não pula).
var _aborted := false


func _start() -> void:
	_high = boss.left()
	_low = boss.right()
	_high_from = _high.global_position
	_low_from = _low.global_position
	_aborted = false


func _tick(t: float) -> void:
	if _aborted:
		return
	if t < CROUCH:
		if _high.dizzy or _low.dizzy:
			_aborted = true
			_high.pose = &"idle"
			_low.pose = &"idle"
			return
		_high.pose = &"crouch"
		_low.pose = &"crouch"
		return
	var u := clampf((t - CROUCH) / FLIGHT, 0.0, 1.0)
	_high.pose = &"spin"
	_low.pose = &"spin"
	_high.global_position = arc_point(_high_from, _low_from, _high_from.y - HIGH_APEX, u)
	_high.spin = u * 2.0
	var lift := clampf(minf(u, 1.0 - u) / 0.1, 0.0, 1.0)
	_low.global_position = Vector2(lerpf(_low_from.x, _high_from.x, u), lerpf(_low_from.y, LOW_FEET_Y, lift))
	_low.spin = -u * 3.0
	if u >= 1.0:
		_finish_swap()


func _is_done() -> bool:
	return _aborted or elapsed >= CROUCH + FLIGHT + 0.3


func _stop() -> void:
	if _high != null and not _aborted:
		_finish_swap()


func _finish_swap() -> void:
	_high.global_position = _low_from
	_low.global_position = _high_from
	for juggler: Juggler in [_high, _low]:
		juggler.spin = 0.0
		juggler.pose = &"idle"
	_high.facing = -1
	_low.facing = 1
