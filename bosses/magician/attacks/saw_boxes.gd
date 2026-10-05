extends MagicianAttack
## Caixas com Serras (fase 2): três caixas de mágica descem do teto; uma linha vermelha pisca
## na altura em que a serra vai passar e, de cada caixa, saem duas serras, uma para cada lado.
## No ataque todo as serras vêm na mesma altura:
## - baixa (rente ao chão): pular;
## - alta (altura do pedestal e do pulo): ficar no chão.

const COLUMNS := [380.0, 700.0, 1020.0, 1340.0]
const DROP := 0.6
const SAWS := 1.4
## Atraso entre as serras de uma caixa e da próxima.
const STAGGER := 0.35
const SAW_SPEED := 900.0
const BOX_BASE_Y := 860.0
const LANES := [955.0, 780.0]

var _columns: Array = []
var _lane := 955.0
var _launched := 0


func _start() -> void:
	var columns := COLUMNS.duplicate()
	for i in range(columns.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = columns[i]
		columns[i] = columns[j]
		columns[j] = swap
	_columns = columns.slice(0, 3)
	_columns.sort()
	_lane = LANES[rng.randi_range(0, LANES.size() - 1)]
	_launched = 0
	for i in 3:
		var box: MagicBox = boss.boxes[i]
		box.show()
		box.hurtbox.monitorable = false
		box.open = 0.0
		box.shake = 0.0
		box.global_position = Vector2(_columns[i], -40.0)
		box.reset_physics_interpolation()
		box.saw_line = _lane - BOX_BASE_Y
	boss.zaratan.pose = &"cast"


func _tick(t: float) -> void:
	var drop := ease(clampf(t / DROP, 0.0, 1.0), 0.4)
	var rise := clampf((t - (SAWS + STAGGER * 2.0 + 1.0)) / 0.6, 0.0, 1.0)
	for i in 3:
		var box: MagicBox = boss.boxes[i]
		box.global_position.y = lerpf(-40.0, BOX_BASE_Y, drop) - rise * (BOX_BASE_Y + 300.0)
		box.shake = 1.0 if t > SAWS - 0.4 + i * STAGGER and t < SAWS + i * STAGGER else 0.0
	while _launched < 3 and t >= SAWS + _launched * STAGGER:
		var box: MagicBox = boss.boxes[_launched]
		box.saw_line = NAN
		var origin := Vector2(_columns[_launched], _lane)
		for side in [-1.0, 1.0]:
			launch(&"saw", false, _launched * 2 + (0 if side < 0 else 1), origin, Vector2(side * SAW_SPEED, 0), 2.4)
		_launched += 1
	boss.zaratan.pose = &"cast" if t < SAWS else &"idle"


func _is_done() -> bool:
	return elapsed >= SAWS + STAGGER * 2.0 + 2.4


func _stop() -> void:
	for box: MagicBox in boss.boxes:
		box.hide()
		box.saw_line = NAN
		box.shake = 0.0
	boss.zaratan.pose = &"idle"
