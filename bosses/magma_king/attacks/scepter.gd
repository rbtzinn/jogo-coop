extends MagmaAttack
## Cetro: ergue o cetro (aviso) e bate no chão; colunas de basalto sobem uma depois da outra, da
## frente dele para longe. Antes de cada uma, uma rachadura brilha no chão (0,5 s). Cada coluna fica
## pouco tempo de pé: sair de cima da rachadura (para os lados, ou numa jangada: a coluna não chega lá).

const RAISE := 0.6
const SLAM_HOLD := 0.5
const FIRST_X_GAP := 220.0
const STEP_X := 230.0
const STEP_TIME := 0.28
const WARN := 0.5
const RISE := 0.12
const STAND := 0.4
const CRUMBLE := 0.25

var _xs: Array[float] = []
var _columns: Array[MagmaProp] = []


func _start() -> void:
	_xs.clear()
	_columns.clear()
	# Às vezes começa um pouco mais longe (para ninguém decorar um lugar seguro).
	var x := king.global_position.x - FIRST_X_GAP - rng.randf_range(0.0, 90.0)
	while x > 80.0:
		_xs.append(x)
		_columns.append(null)
		x -= STEP_X


func _tick(t: float) -> void:
	if t < RAISE:
		king.pose(&"scepter", 0)
		king.shake = 0.3
	elif t < RAISE + 0.12:
		king.pose(&"scepter", 1)
		king.shake = 0.0
	elif t < RAISE + SLAM_HOLD + _xs.size() * STEP_TIME:
		king.pose(&"scepter", 2)
	else:
		king.pose(&"scepter", 3)
	for i in _xs.size():
		# A rachadura aparece WARN antes de subir; a primeira sobe logo depois da batida.
		var since := t - (RAISE + 0.1 + i * STEP_TIME)
		if since < 0.0:
			continue
		if _columns[i] == null and since < WARN + RISE + STAND + CRUMBLE:
			_columns[i] = spawn(&"column", Vector2(_xs[i], FLOOR_Y))
		var column := _columns[i]
		if column == null or not is_instance_valid(column):
			continue
		var up := since - WARN
		if up < 0.0:
			column.frame = 0
			column.active = false
		elif up < RISE:
			column.frame = 1
			column.active = true
		elif up < RISE + STAND:
			column.frame = 2
			column.active = true
		elif up < RISE + STAND + CRUMBLE:
			column.frame = 3
			column.active = false
		else:
			free_prop(column)


func _is_done() -> bool:
	return elapsed > RAISE + 0.1 + _xs.size() * STEP_TIME + WARN + RISE + STAND + CRUMBLE + 0.1
