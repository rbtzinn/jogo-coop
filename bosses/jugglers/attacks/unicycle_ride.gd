extends JugglerAttack
## Monociclo Gigante (fase 3): os irmãos balançam para trás (aviso) e atravessam a arena de
## monociclo, ida e volta. Só a roda machuca: dá para pular por cima dela, atravessar com o
## dash ou ficar num pedestal (o vão entre a roda e o selim passa pelo pedestal).

const WIND := 0.6
const RIDE := 1.7
const PAUSE := 0.35
const ENDS := Vector2(230.0, 1690.0)

var _from_x := 0.0
var _to_x := 0.0


func _start() -> void:
	_from_x = boss.unicycle.global_position.x
	_to_x = ENDS.y if _from_x < 960.0 else ENDS.x


func _tick(t: float) -> void:
	var x := _from_x
	var direction := 1 if _to_x > _from_x else -1
	if t < WIND:
		# Aviso: balança para trás, pegando impulso.
		x = _from_x - direction * sin(t / WIND * PI) * 40.0
	elif t < WIND + RIDE:
		x = lerpf(_from_x, _to_x, ease((t - WIND) / RIDE, -1.6))
	elif t < WIND + RIDE + PAUSE:
		x = _to_x
		direction = -direction
	else:
		x = lerpf(_to_x, _from_x, ease(clampf((t - WIND - RIDE - PAUSE) / RIDE, 0.0, 1.0), -1.6))
		direction = -direction
	boss.place_group(x)
	boss.base().facing = direction
	boss.top().facing = direction


func _is_done() -> bool:
	return elapsed >= WIND + RIDE * 2.0 + PAUSE + 0.2


func _stop() -> void:
	boss.place_group(_from_x)
