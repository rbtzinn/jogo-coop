extends MagmaAttack
## Rajada: ele derrete até a altura certa, a boca brilha e uma linha fina mostra por onde o jato vai
## passar (aviso); depois cospe um jato contínuo de magma que atravessa a tela, numa de três alturas:
## nas jangadas (quem está nelas desce), no peito (abaixar) ou rente ao chão (pular ou subir numa jangada).

const SINK := 0.35
const CHARGE := 0.8
const FIRE := 1.3
const RECOVER := 0.35
## Mais fundo no chão (atrás da margem) = jato mais baixo: nas jangadas passa em y ~ 700, no peito em
## ~ 860 e rente ao chão em ~ 950.
const SINKS := [30.0, 190.0, 280.0]
const END_X := -120.0

var _sink := 0.0
var _jet: MagmaProp
var _home := Vector2.ZERO
var _warning: Line2D


func _start() -> void:
	_home = king.global_position
	_sink = SINKS[rng.randi_range(0, SINKS.size() - 1)]
	_jet = null
	_warning = null


func _tick(t: float) -> void:
	var depth := _sink * clampf(t / SINK, 0.0, 1.0)
	if t > SINK + CHARGE + FIRE:
		depth = _sink * (1.0 - clampf((t - SINK - CHARGE - FIRE) / RECOVER, 0.0, 1.0))
	king.global_position = _home + Vector2(0, depth)
	var mouth := king.mouth()
	if t < SINK + CHARGE:
		king.pose(&"molten", 4)
		king.shake = 0.4 if t > SINK else 0.0
		if t > SINK:
			if _warning == null:
				_warning = Line2D.new()
				_warning.width = 6.0
				_warning.default_color = Color(1.0, 0.85, 0.4, 0.0)
				add_child(_warning)
			_warning.points = PackedVector2Array([to_local(mouth), to_local(Vector2(END_X, mouth.y))])
			# Pisca cada vez mais forte.
			_warning.default_color.a = 0.25 + 0.5 * absf(sin(t * 18.0)) * (t - SINK) / CHARGE
		return
	king.shake = 0.0
	if _warning != null:
		_warning.queue_free()
		_warning = null
	if t < SINK + CHARGE + FIRE:
		king.pose(&"molten", 5)
		if _jet == null:
			_jet = spawn(&"jet", mouth)
			_jet.set_jet_length(mouth.x - END_X)
		_jet.global_position = mouth
	else:
		king.pose(&"molten", 2)
		if _jet != null:
			free_prop(_jet)
			_jet = null


func _is_done() -> bool:
	return elapsed > SINK + CHARGE + FIRE + RECOVER


func _stop() -> void:
	if _warning != null and is_instance_valid(_warning):
		_warning.queue_free()
	_warning = null
	king.global_position = _home
