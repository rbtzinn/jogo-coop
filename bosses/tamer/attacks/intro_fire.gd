extends BossAttack
## Troca para a fase 3, "O Leão de Fogo": o domador, desesperado, joga a tocha no leão para
## espantá-lo; Leopoldo engole a tocha, a juba pega fogo e ele ruge soltando brasas.
## args: [x do leão, y do leão].

const STAND_UP := 0.5
const THROW := Vector2(0.7, 1.3)
const SWALLOW := 1.35
const ROAR := Vector2(1.5, 2.5)
const END := 2.8

@export var tamer_path: NodePath
@export var lion_path: NodePath

var _torch := TamerTorch.new()
var _embers := EmberShower.new()
var _lit := false

@onready var tamer: Tamer = get_node(tamer_path)
@onready var lion: TamerLion = get_node(lion_path)


func _ready() -> void:
	add_child(_torch)
	add_child(_embers)
	_torch.hide()


func _on_begin() -> void:
	var at := Vector2(args[0], args[1]) if args.size() >= 2 else lion.global_position
	lion.place(at)
	lion.idle = false
	_lit = false
	_embers.clear()
	_embers.floor_y = 1000.0
	var mouth := _mouth()
	for n in 8:
		var velocity := Vector2(rng.randf_range(-320.0, 320.0), -rng.randf_range(250.0, 520.0))
		_embers.add(ROAR.x, mouth, velocity)


func _on_tick(_delta: float) -> void:
	var t := elapsed
	_embers.update(t)
	tamer.cowering = t < STAND_UP or t > THROW.y + 0.2
	if t >= STAND_UP and t < THROW.x:
		_torch.show()
		_torch.global_position = tamer.hand.global_position + Vector2(0, -20)
	elif t >= THROW.x and t < THROW.y:
		var u := (t - THROW.x) / (THROW.y - THROW.x)
		_torch.global_position = arc_point(tamer.hand.global_position, _mouth(), 220.0, u)
		_torch.rotation = -u * TAU
	elif t >= THROW.y:
		_torch.hide()
	lion.set_roaring((t >= SWALLOW - 0.15 and t < SWALLOW + 0.1) or (t >= ROAR.x and t < ROAR.y))
	if t >= SWALLOW and not _lit:
		_lit = true
		lion.set_on_fire(true)
	if t >= ROAR.x and t < ROAR.y:
		lion.body.rotation = sin(t * 45.0) * 0.04


func _is_done() -> bool:
	return elapsed >= maxf(END, _embers.end_time())


func _on_end() -> void:
	_torch.hide()
	_embers.clear()
	tamer.cowering = true
	lion.set_on_fire(true)
	lion.place(lion.global_position)


func _mouth() -> Vector2:
	return lion.head_closed.global_position + Vector2(-40.0 * lion.scale.x, 20)
