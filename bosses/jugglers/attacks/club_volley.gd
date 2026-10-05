extends JugglerAttack
## Claves em Linha (fase 2): o irmão de cima do totem arremessa quatro claves retas pela arena,
## cada uma numa altura:
## - B (baixa, na altura da cabeça): abaixar desvia;
## - A (alta, na altura do pulo e dos pedestais): ficar no chão desvia.
## Antes de cada uma ele puxa o braço para trás (aviso).

const THROWS := [0.6, 1.2, 1.8, 2.4]
const SPEED := 1100.0
## A clave sai da mão desenhada do de cima e chega na faixa em 0,1 s (E7: com o totem desenhado ela nascia
## direto na faixa, até 149 px longe da mão).
const LEAVE_HAND := 0.1
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
			boss.top().throw_released = true
			club.append(boss.top().hand_position())
		var prop: JugglerProp = club[0] if is_instance_valid(club[0]) else null
		if not is_instance_valid(prop):
			continue
		var lane := Vector2(_start_x + _direction * (50.0 + SPEED * since), HEIGHTS[_pattern[i]])
		# Sai da mão do de cima e entra na faixa em LEAVE_HAND s (depois segue reta na faixa, como sempre).
		# No 1º quadro em que aparece ela fica na mão.
		var leave := maxf(since - 1.0 / 60.0, 0.0)
		prop.global_position = (club[2] as Vector2).lerp(lane, leave / LEAVE_HAND) if leave < LEAVE_HAND else lane
		if prop.global_position.x < -80.0 or prop.global_position.x > 2000.0:
			prop.queue_free()
	boss.top().pose = &"throw" if winding else &"sit"


func _is_done() -> bool:
	return elapsed >= THROWS[-1] + 2000.0 / SPEED


func _stop() -> void:
	boss.top().pose = &"sit"
