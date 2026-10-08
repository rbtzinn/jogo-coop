class_name ClockPlatform
extends AnimatableBody2D
## Plataforma pelo relógio do chefão: balança na forja ou pulsa na cratera.
@export var clock_path: NodePath
@export var texture: Texture2D
@export var width := 300.0
@export var amplitude := Vector2(45, 0)
@export var period := 3.2
@export var offset := 0.0
@export var hanging := false
@export var art_top := 0.0

var _rest := Vector2.ZERO
var _clock: Node
var _sprite := Sprite2D.new()
var _chain_x: Array[float] = []
## Dois elos da corrente na textura das plataformas penduradas (pixels da textura, medido no desenho).
const CHAIN_PERIOD := 155.0


func _ready() -> void:
	_rest = position
	_clock = get_node(clock_path)
	collision_layer = 16
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 24)
	shape.shape = rectangle
	shape.one_way_collision = true
	shape.position.y = 12
	add_child(shape)
	_sprite.texture = texture
	_sprite.centered = false
	var ratio := (width + 24.0) / texture.get_width()
	_sprite.scale = Vector2.ONE * ratio
	_sprite.position = Vector2(-(width + 24.0) * 0.5, -art_top * ratio)
	add_child(_sprite)
	if hanging:
		var image := texture.get_image()
		var half := image.get_width() / 2
		# Meio de cada corrente pelos pixels bem opacos (o brilho fraco em volta puxava o meio para o lado e a
		# corrente esticada saía quase toda transparente).
		for i in 2:
			var left := INF
			var right := -INF
			for y in range(20, 120, 10):
				for x in range(half * i, half * (i + 1)):
					if image.get_pixel(x, y).a > 0.6:
						left = minf(left, x)
						right = maxf(right, x)
			_chain_x.append((left + right) * 0.5)


func _physics_process(_delta: float) -> void:
	var t: float = _clock.stage_clock
	position = _rest + amplitude * sin(TAU * t / period + offset)
	if hanging:
		queue_redraw()


func set_enabled(enabled: bool) -> void:
	visible = enabled
	(get_child(0) as CollisionShape2D).set_deferred("disabled", not enabled)


func _draw() -> void:
	if not hanging:
		return
	var ratio := _sprite.scale.x
	var top := -global_position.y - 10.0
	for center in _chain_x:
		# Do topo do desenho para cima, de dois em dois elos: cada pedaço termina no mesmo ponto do elo em que o
		# desenho começa, então a corrente continua sem emenda até o alto da tela.
		var y := _sprite.position.y
		while y > top:
			var h := minf(CHAIN_PERIOD * ratio, y - top)
			var target := Rect2(_sprite.position.x + (center - 40) * ratio, y - h, 80 * ratio, h)
			draw_texture_rect_region(texture, target, Rect2(center - 40, CHAIN_PERIOD - h / ratio, 80, h / ratio))
			y -= h
