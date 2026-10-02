extends JugglerAttack
## Claves em Linha (fase 2): o irmão de cima do totem arremessa quatro claves retas pela arena,
## cada uma numa altura:
## - B (baixa, na altura da cabeça): abaixar desvia;
## - A (alta, na altura do pulo e dos pedestais): ficar no chão desvia.
## Antes de cada uma ele puxa o braço para trás (aviso).

const THROWS := [0.6, 1.2, 1.8, 2.4]
const SPEED := 1100.0
## Altura (y) de cada faixa.
const HEIGHTS := {"B": 880.0, "A": 700.0}
const PATTERNS := [["B", "A", "B", "B"], ["A", "B", "A", "B"], ["B", "B", "A", "B"]]

var _pattern: Array = []
var _start_x := 0.0
var _direction := 1.0
var _clubs: Array = []


func _start() -> void:
	_pattern = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	_start_x = boss.top().global_position.x
	_direction = 1.0 if _start_x < 960.0 else -1.0
	boss.top().facing = int(_direction)
	boss.base().facing = int(_direction)
	_clubs.clear()
	for i in THROWS.size():
		_clubs.append([null, false])


func _tick(t: float) -> void:
	var winding := false
	for i in THROWS.size():
		var since: float = t - THROWS[i]
		if since >= -0.35 and since < 0.05:
			winding = true
		if since < 0.0:
			continue
		var club: Array = _clubs[i]
		if not club[1]:
			club[1] = true
			club[0] = make_prop(&"club", false, i)
			club[0].spin_speed = 4.0 * _direction
		var prop: JugglerProp = club[0] if is_instance_valid(club[0]) else null
		if not is_instance_valid(prop):
			continue
		prop.global_position = Vector2(_start_x + _direction * (50.0 + SPEED * since), HEIGHTS[_pattern[i]])
		if prop.global_position.x < -80.0 or prop.global_position.x > 2000.0:
			prop.queue_free()
	boss.top().pose = &"throw" if winding else &"sit"


func _is_done() -> bool:
	return elapsed >= THROWS[-1] + 2000.0 / SPEED


func _stop() -> void:
	boss.top().pose = &"sit"
