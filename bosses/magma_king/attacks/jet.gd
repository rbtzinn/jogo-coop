extends MagmaAttack
## Rajada: ele toma a pose da altura do jato (esticado = jangadas; cabeça para a frente = peito; curvado com a
## cara no chão = rente ao chão), as bochechas brilham e uma linha fina mostra por onde o jato vai passar
## (aviso); depois cospe um jato contínuo de magma até a parede (JetBeam). Jangadas: quem está nelas desce;
## peito: abaixar; chão: pular ou subir numa jangada. Poses em docs/prompts/chatgpt_rei_magma_jato.md.

const WARN := 0.75
const OPEN := 0.3
const FIRE := 1.3
const RECOVER := 0.35
const POSES := [&"jet_high", &"jet_mid", &"jet_low"]
## O clarão do jato começa um pouco para dentro dos lábios.
const LIPS := Vector2(40, 0)
const WALL_X := -10.0

var _pose := &"jet_mid"
var _beam: JetBeam
var _warning: Line2D


func _start() -> void:
	_pose = POSES[rng.randi_range(0, POSES.size() - 1)]
	_beam = null
	_warning = null


func _mouth() -> Vector2:
	return king.global_position + MagmaKing.JET_MOUTHS[_pose] + LIPS


func _tick(t: float) -> void:
	var mouth := _mouth()
	if t < WARN + OPEN:
		king.pose(_pose, 0 if t < WARN else 1)
		king.shake = 0.35 if t < WARN else 0.0
		if _warning == null:
			_warning = Line2D.new()
			_warning.width = 6.0
			add_child(_warning)
		_warning.points = PackedVector2Array([to_local(mouth), to_local(Vector2(WALL_X, mouth.y))])
		# Pisca cada vez mais forte.
		_warning.default_color = Color(1.0, 0.85, 0.4, 0.25 + 0.5 * absf(sin(t * 18.0)) * minf(t / WARN, 1.0))
		return
	if _warning != null:
		_warning.queue_free()
		_warning = null
	if t < WARN + OPEN + FIRE:
		king.pose(_pose, 2)
		king.shake = 0.15
		if _beam == null:
			_beam = JetBeam.new()
			_beam.wall_x = WALL_X
			add_child(_beam)
		_beam.global_position = mouth
	else:
		king.pose(_pose, 3)
		king.shake = 0.0
		if _beam != null:
			_beam.queue_free()
			_beam = null


func _is_done() -> bool:
	return elapsed > WARN + OPEN + FIRE + RECOVER


func _stop() -> void:
	for node in [_warning, _beam]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_warning = null
	_beam = null
