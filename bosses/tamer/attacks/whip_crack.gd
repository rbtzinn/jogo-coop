extends BossAttack
## Chicotada: o domador ergue o chicote (aviso) e estala no chão; uma onda corre
## pelo picadeiro até sair pela esquerda. Às vezes estala duas vezes.
## Às vezes a última onda vem rosa (parry: pular por cima e apertar pulo de novo).

const WAVE_SPEED := 950.0
const RAISE_TIME := 0.55
const FIRST_CRACK := 0.75
const SECOND_CRACK := 1.55
const EXIT_X := -120.0
const PINK_CHANCE := 0.5

@export var tamer_path: NodePath
## Altura do chão do picadeiro (y global).
@export var floor_y := 1000.0

var _cracks: Array[float] = []
var _waves: Array[WhipWave] = []
var _start_x := 0.0
var _pink_index := -1

@onready var tamer: Tamer = get_node(tamer_path)


func _on_begin() -> void:
	_cracks = [FIRST_CRACK]
	if rng.randf() < 0.45:
		_cracks.append(SECOND_CRACK)
	_pink_index = _cracks.size() - 1 if rng.randf() < PINK_CHANCE else -1
	_start_x = tamer.global_position.x - 150.0
	_waves.clear()


func _on_tick(_delta: float) -> void:
	tamer.whip_pose = _whip_pose(elapsed)
	for i in _cracks.size():
		var since := elapsed - _cracks[i]
		if since < 0.0:
			continue
		if i >= _waves.size():
			_waves.append(_spawn_wave(since, i))
		var wave := _waves[i]
		if wave != null:
			wave.global_position = Vector2(_start_x - WAVE_SPEED * since, floor_y)
			if wave.global_position.x < EXIT_X:
				wave.queue_free()
				_waves[i] = null


func _is_done() -> bool:
	return elapsed > _cracks[-1] + (_start_x - EXIT_X) / WAVE_SPEED + 0.05


func _on_end() -> void:
	for wave in _waves:
		if wave != null:
			wave.queue_free()
	_waves.clear()
	tamer.whip_pose = 0.0


func _spawn_wave(since: float, index: int) -> WhipWave:
	var wave := WhipWave.new()
	wave.pink = index == _pink_index
	wave.parry_id = "%s:%d:%d" % [name, rng.seed, index]
	add_child(wave)
	wave.global_position = Vector2(_start_x - WAVE_SPEED * since, floor_y)
	wave.reset_physics_interpolation()
	if since < 0.1:
		Fx.spawn(preload("res://components/fx/dust_puff.tscn"), Vector2(_start_x, floor_y))
	return wave


## 0 = caído, 1 = erguido, 2 = estalado (ver Tamer.whip_pose).
func _whip_pose(t: float) -> float:
	for crack in _cracks:
		if t < crack - RAISE_TIME - 0.05:
			return 0.0
		if t < crack:
			return clampf((t - (crack - RAISE_TIME - 0.05)) / (RAISE_TIME * 0.7), 0.0, 1.0)
		if t < crack + 0.08:
			return 1.0 + (t - crack) / 0.08
		if t < crack + 0.3:
			return 2.0
	return 0.0
