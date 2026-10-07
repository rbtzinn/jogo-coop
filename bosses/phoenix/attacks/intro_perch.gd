extends PhoenixAttack
## Troca para a fase 2, "Tempestade de Cinzas": o céu escurece de cinzas e ela desce voando até a beira do
## ninho e pousa, se exibindo.

const FLY_DOWN := 1.1
const LAND := 0.6

var _from := Vector2.ZERO


func _start() -> void:
	bird.set_mode(Phoenix.Mode.FLY)
	bird.facing = -1
	_from = bird.global_position
	boss.set_stage(1, true)


func _tick(t: float) -> void:
	if t < FLY_DOWN:
		bird.pose(&"fly", 1)
		bird.global_position = arc_point(_from, PERCH + Vector2(0, -170), -120.0, smoothstep(0.0, 1.0, t / FLY_DOWN))
		return
	if bird.mode != Phoenix.Mode.PERCH:
		bird.set_mode(Phoenix.Mode.PERCH)
		bird.global_position = PERCH
		bird.reset_physics_interpolation()
	bird.pose(&"perch", 6)


func _is_done() -> bool:
	return elapsed > FLY_DOWN + LAND


func _stop() -> void:
	bird.set_mode(Phoenix.Mode.PERCH)
	bird.global_position = PERCH
	bird.reset_physics_interpolation()
