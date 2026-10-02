extends BossAttack
## Rugido: Leopoldo se prepara (aviso) e ruge; três ondas de som em arco atravessam a
## tela para a esquerda. Cada onda tem um buraco: rente ao chão (ficar no chão) ou no meio
## (um pulo normal passa, com folga). Também dá para atravessar com o dash.
## As ondas vêm espaçadas o bastante para pular uma e cair antes da próxima.

const WINDUP := 0.8
const WAVE_TIMES := [0.8, 1.65, 2.5]
const WAVE_SPEED := 600.0
## Centro do buraco: rente ao chão, ou na altura do corpo no topo de um pulo.
const GAPS := [875.0, 690.0]
const EXIT_X := -200.0

@export var lion_path: NodePath

var _waves: Array[SoundWave] = []
var _gaps: Array[float] = []
var _start_x := 0.0

@onready var lion: TamerLion = get_node(lion_path)


func _on_begin() -> void:
	_waves.clear()
	_gaps.clear()
	for i in WAVE_TIMES.size():
		_gaps.append(GAPS[rng.randi_range(0, GAPS.size() - 1)])
	_start_x = lion.home_position.x - 200.0
	lion.idle = false


func _on_tick(_delta: float) -> void:
	var t := elapsed
	var roaring := t >= WINDUP and t < WAVE_TIMES[-1] + 0.45
	lion.set_roaring(roaring)
	if t < WINDUP:
		# Aviso: puxa a cabeça para trás e treme.
		var k := t / WINDUP
		lion.body.rotation = 0.12 * k + sin(t * 60.0) * 0.015 * k
	elif roaring:
		lion.body.rotation = -0.06 + sin(t * 45.0) * 0.02
	else:
		lion.body.rotation = 0.0

	for i in WAVE_TIMES.size():
		var since: float = t - WAVE_TIMES[i]
		if since < 0.0:
			continue
		if i >= _waves.size():
			_waves.append(_spawn_wave(_gaps[i], since))
		var wave := _waves[i]
		if wave != null:
			wave.global_position.x = _start_x - WAVE_SPEED * since
			if wave.global_position.x < EXIT_X:
				wave.queue_free()
				_waves[i] = null


func _is_done() -> bool:
	return elapsed > WAVE_TIMES[-1] + (_start_x - EXIT_X) / WAVE_SPEED + 0.05


func _on_end() -> void:
	for wave in _waves:
		if wave != null:
			wave.queue_free()
	_waves.clear()
	lion.body.rotation = 0.0
	lion.go_home()


func _spawn_wave(gap: float, since: float) -> SoundWave:
	var wave := SoundWave.new()
	wave.gap_center = gap
	wave.position = Vector2(_start_x - WAVE_SPEED * since, 0.0)
	add_child(wave)
	wave.reset_physics_interpolation()
	return wave
