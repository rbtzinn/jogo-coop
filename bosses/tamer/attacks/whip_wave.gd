class_name WhipWave
extends EnemyHitbox
## Onda da chicotada: corre rente ao chão do picadeiro. Pular por cima.
## A onda rosa aceita parry: pular por cima e apertar pulo de novo encostando nela.

const SIZE := Vector2(96, 86)
## Quatro desenhos da crista em loop (tools/cut_tamer_effects.gd), na metade do tamanho da folha:
## a base em y 236 e o meio em x 128 da célula.
const FRAMES := [preload("res://bosses/tamer/art/effects/whip_1.png"), preload("res://bosses/tamer/art/effects/whip_2.png"), preload("res://bosses/tamer/art/effects/whip_3.png"),
		preload("res://bosses/tamer/art/effects/whip_4.png")]
const PINK_FRAMES := [preload("res://bosses/tamer/art/effects/whip_pink_1.png"), preload("res://bosses/tamer/art/effects/whip_pink_2.png"),
		preload("res://bosses/tamer/art/effects/whip_pink_3.png"), preload("res://bosses/tamer/art/effects/whip_pink_4.png")]
const FRAME_TIME := 0.07

@export var pink := false

## Identifica a onda nos dois PCs (para estourar a mesma quando o parceiro faz parry).
var parry_id := ""

var _time := 0.0
var _sprite := Sprite2D.new()


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE - Vector2(14, 10)
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y * 0.5)
	add_child(shape)
	_sprite.centered = false
	_sprite.scale = Vector2.ONE * 0.5
	_sprite.offset = Vector2(-128, -236)
	_sprite.texture = (PINK_FRAMES if pink else FRAMES)[0]
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	scale.y = 1.0 + sin(_time * 40.0) * 0.08
	_sprite.texture = (PINK_FRAMES if pink else FRAMES)[int(_time / FRAME_TIME) % 4]


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	active = false
	hide()
	ParryFlash.spawn(global_position + Vector2(0, -SIZE.y * 0.5), 1.4)
