extends MagmaAttack
## Troca para a fase 3, "Coroação Derretida": ele sai do lago para a margem, a casca racha e cai e
## ele vira magma puro, com a coroa flutuando. O fundo esquenta (lago mais alto, bandeiras pegando fogo).

const CRACK := 0.7
const BREAK := 0.8
const SPOT := Vector2(1610, 1000)


func _start() -> void:
	king.set_mode(MagmaKing.Mode.MOLTEN)
	king.global_position = SPOT
	king.reset_physics_interpolation()
	boss.heat_stage(true)


func _tick(t: float) -> void:
	king.pose(&"molten", 0 if t < CRACK else 1)
	king.shake = 0.7 if t < CRACK + BREAK else 0.0


func _is_done() -> bool:
	return elapsed > CRACK + BREAK + 0.3
