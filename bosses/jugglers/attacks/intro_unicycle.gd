extends JugglerAttack
## Troca para a fase 3, "Monociclo Gigante!": um monociclo enorme entra rolando pela direita
## e os irmãos saltam do totem direto para o selim (um nos ombros do outro).

const ROLL_IN := 1.2
const JUMP := 0.9
const START_X := 2150.0

var _target_x := 0.0
var _base_from := Vector2.ZERO
var _top_from := Vector2.ZERO
var _landed := false


func _start() -> void:
	_target_x = JugglersBoss.HOME_RIGHT.x - 60.0
	boss.unicycle.global_position = Vector2(START_X, JugglersBoss.HOME_LEFT.y)
	boss.unicycle.reset_physics_interpolation()
	boss.unicycle.show()
	_base_from = boss.base().global_position
	_top_from = boss.top().global_position
	_landed = false


func _tick(t: float) -> void:
	if t < ROLL_IN:
		boss.unicycle.global_position.x = lerpf(START_X, _target_x, ease(t / ROLL_IN, -2.0))
		boss.base().pose = &"idle"
		boss.top().pose = &"throw"
		return
	var u := clampf((t - ROLL_IN) / JUMP, 0.0, 1.0)
	if u < 1.0:
		var seat := boss.unicycle.seat_position()
		boss.base().global_position = arc_point(_base_from, seat, 300.0, u)
		boss.top().global_position = arc_point(_top_from, seat - Vector2(0, JugglersBoss.SHOULDER), 340.0, u)
		for juggler: Juggler in [boss.base(), boss.top()]:
			juggler.pose = &"spin"
			juggler.spin = u
		return
	if not _landed:
		_land()


func _is_done() -> bool:
	return elapsed >= ROLL_IN + JUMP + 0.3


func _stop() -> void:
	if not _landed:
		_land()


func _land() -> void:
	_landed = true
	for juggler: Juggler in [boss.base(), boss.top()]:
		juggler.spin = 0.0
		juggler.facing = -1
	boss.set_mode(&"unicycle")
	boss.place_group(_target_x)
