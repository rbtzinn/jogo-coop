extends BossAttack
## Chuva de Argolas (fase 3): o leão de fogo ruge e argolas de fogo caem do teto em duas
## levas. Antes de cada argola cair, uma chama pisca no alto marcando a coluna. Em cada leva
## uma coluna fica livre; a última argola de cada leva é rosa (parry, etapa 4b).

const COLUMNS := [210.0, 520.0, 830.0, 1140.0, 1450.0]
const WAVE_TIMES := [0.0, 1.8]
const WARNING := 0.75
const STAGGER := 0.16
const GRAVITY := 2600.0
const START_Y := -160.0
const EMBER_TEXTURE := preload("res://bosses/tamer/art/ember.svg")

@export var lion_path: NodePath
@export var floor_y := 1000.0

## Cada argola: [nó, tempo em que cai, x, rosa?, estourou?].
var _rings: Array = []
var _markers: Array[Sprite2D] = []
var _embers := EmberShower.new()
var _ring_radius_y := 112.0

@onready var lion: TamerLion = get_node(lion_path)


func _ready() -> void:
	add_child(_embers)


func _on_begin() -> void:
	_rings.clear()
	_clear_markers()
	_embers.clear()
	_embers.floor_y = floor_y
	lion.place(lion.global_position)
	lion.idle = false
	for wave_time in WAVE_TIMES:
		var gap := rng.randi_range(0, COLUMNS.size() - 1)
		var columns: Array = []
		for i in COLUMNS.size():
			if i != gap:
				columns.append(COLUMNS[i])
		for i in range(columns.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var swap = columns[i]
			columns[i] = columns[j]
			columns[j] = swap
		for k in columns.size():
			var drop_time: float = wave_time + WARNING + k * STAGGER
			_rings.append([null, drop_time, columns[k], k == columns.size() - 1, false])
	for ring in _rings:
		var marker := Sprite2D.new()
		marker.texture = EMBER_TEXTURE
		marker.position = Vector2(ring[2], 60)
		marker.hide()
		add_child(marker)
		_markers.append(marker)
		var land := _fall_time()
		for side in [-1.0, 1.0]:
			var velocity := Vector2(side * rng.randf_range(150.0, 280.0), -rng.randf_range(300.0, 450.0))
			_embers.add(ring[1] + land, Vector2(ring[2], floor_y - 30.0), velocity)


func _on_tick(_delta: float) -> void:
	var t := elapsed
	lion.set_roaring(t < WAVE_TIMES[-1] + WARNING + 0.6)
	_embers.update(t)
	for i in _rings.size():
		var ring: Array = _rings[i]
		var marker := _markers[i]
		var since: float = t - ring[1]
		# Aviso no alto da coluna antes de cair.
		marker.visible = since < 0.0 and since > -WARNING
		if marker.visible:
			marker.modulate.a = 0.5 + 0.5 * absf(sin(t * 18.0))
			marker.scale = Vector2.ONE * (1.0 + (WARNING + since) * 0.6)
		if since < 0.0 or ring[4]:
			continue
		if ring[0] == null:
			var node := FireRing.new()
			node.pink = ring[3]
			node.parry_id = "%s:%d:%d" % [name, rng.seed, i]
			add_child(node)
			node.strength = 1.0
			ring[0] = node
		var node: FireRing = ring[0]
		var y := START_Y + 0.5 * GRAVITY * since * since
		node.global_position = Vector2(ring[2], y)
		if y + _ring_radius_y >= floor_y:
			ring[4] = true
			node.queue_free()
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), Vector2(ring[2], floor_y))


func _is_done() -> bool:
	var last: float = _rings[-1][1] + _fall_time() if not _rings.is_empty() else 0.0
	return elapsed >= maxf(last + 0.3, _embers.end_time())


func _on_end() -> void:
	for ring in _rings:
		if not ring[4] and ring[0] != null and is_instance_valid(ring[0]):
			ring[0].queue_free()
	_rings.clear()
	_clear_markers()
	_embers.clear()
	lion.set_roaring(false)
	lion.place(lion.global_position)


func _fall_time() -> float:
	return sqrt(2.0 * (floor_y - _ring_radius_y - START_Y) / GRAVITY)


func _clear_markers() -> void:
	for marker in _markers:
		marker.queue_free()
	_markers.clear()
