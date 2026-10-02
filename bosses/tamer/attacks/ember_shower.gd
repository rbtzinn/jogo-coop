class_name EmberShower
extends Node2D
## Conjunto de brasas que caem com gravidade e se apagam no chão. Determinístico: a posição
## de cada brasa é calculada pelo tempo do ataque (igual nos dois PCs).
## Brasas rosa aceitam parry; `id_prefix` identifica cada uma nos dois PCs.

const GRAVITY := 1400.0
const FADE_TIME := 0.35

## Altura do chão (y global) onde as brasas se apagam.
var floor_y := 1000.0
## Começo do parry_id das brasas rosa (o ataque põe nome e semente).
var id_prefix := ""

## Cada brasa: [nó, tempo em que solta, posição inicial, velocidade inicial, já criada, rosa].
var _embers: Array = []


func add(release_time: float, from: Vector2, velocity: Vector2, pink := false) -> void:
	_embers.append([null, release_time, from, velocity, false, pink])


## Atualiza todas as brasas para o tempo `t` do ataque.
func update(t: float) -> void:
	for i in _embers.size():
		var ember: Array = _embers[i]
		var since: float = t - ember[1]
		if since < 0.0:
			continue
		if not ember[4]:
			ember[4] = true
			var created := Ember.new()
			created.pink = ember[5]
			created.parry_id = "%s:e%d" % [id_prefix, i]
			ember[0] = created
			add_child(created)
		if not is_instance_valid(ember[0]):
			continue
		var node: Ember = ember[0]
		var start: Vector2 = ember[2]
		var velocity: Vector2 = ember[3]
		var land := _landing_time(start.y, velocity.y)
		var s := minf(since, land)
		node.global_position = start + velocity * s + Vector2(0, 0.5 * GRAVITY * s * s)
		if since > land:
			var fade := (since - land) / FADE_TIME
			if fade >= 1.0:
				node.queue_free()
			else:
				node.set_fading(fade)


## Quando a última brasa terá se apagado.
func end_time() -> float:
	var latest := 0.0
	for ember in _embers:
		var start: Vector2 = ember[2]
		var velocity: Vector2 = ember[3]
		latest = maxf(latest, ember[1] + _landing_time(start.y, velocity.y) + FADE_TIME)
	return latest


func clear() -> void:
	for ember in _embers:
		if is_instance_valid(ember[0]):
			ember[0].queue_free()
	_embers.clear()


func _landing_time(y0: float, vy: float) -> float:
	var drop := maxf(floor_y - y0, 0.0)
	return (vy + sqrt(vy * vy + 2.0 * GRAVITY * drop)) / GRAVITY
