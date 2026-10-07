extends MagmaAttack
## Coroa em Órbita: ele gira o dedo e a coroa dá voltas em volta da cabeça (aviso); depois sai voando
## numa espiral que se abre pela arena toda. Rente ao chão ela desliza (pular por cima).

const TWIRL := 1.2
const SPIRAL := 3.4
const ORBIT_R := 130.0
const GROW := 420.0
const SPIN := 3.0
const LOWEST := 955.0

var _crown: MagmaProp
var _center := Vector2.ZERO
var _dir := 1.0


func _start() -> void:
	_center = king.global_position + Vector2(-10, -400)
	_dir = 1.0 if rng.randf() < 0.5 else -1.0
	_crown = null


func _tick(t: float) -> void:
	king.pose(&"molten", 6 if t < TWIRL + 0.4 else 2)
	if _crown == null:
		_crown = spawn(&"orbit_crown", _center)
	var r := ORBIT_R + GROW * maxf(t - TWIRL, 0.0)
	var angle := PI + _dir * SPIN * t
	var at := _center + Vector2(cos(angle), sin(angle) * 0.85) * r
	_crown.global_position = Vector2(at.x, minf(at.y, LOWEST))
	# Na volta em torno da cabeça ainda é só o aviso.
	_crown.active = t > TWIRL


func _is_done() -> bool:
	return elapsed > TWIRL + SPIRAL
