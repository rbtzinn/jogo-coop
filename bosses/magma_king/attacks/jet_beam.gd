class_name JetBeam
extends EnemyHitbox
## Jato de magma da Rajada, montado em três peças (docs/prompts/chatgpt_rei_magma_jato.md): o clarão na boca
## (borda direita no ponto do nó), o meio que se repete correndo para a esquerda e a ponta batendo na parede.
## A área que machuca vai da boca até a parede, com a grossura do miolo do jato.

const ART := "res://bosses/magma_king/art/"
const SCALE := 0.5
const FPS := 12.0
## Velocidade com que o meio corre (px/s, para a esquerda).
const FLOW := 1400.0
## Grossura da área que machuca.
const THICK := 84.0

## Até onde o jato vai (x global da parede).
var wall_x := 0.0

var _time := 0.0
var _mouth: Array[Texture2D] = []
var _tip: Array[Texture2D] = []
var _middle: Texture2D
var _shape := CollisionShape2D.new()


func _ready() -> void:
	super()
	for i in 3:
		_mouth.append(load(ART + "jet_mouth_%d.png" % (i + 1)))
		_tip.append(load(ART + "jet_tip_%d.png" % (i + 1)))
	_middle = load(ART + "jet_middle.png")
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)


func _process(delta: float) -> void:
	_time += delta
	var length := global_position.x - wall_x
	(_shape.shape as RectangleShape2D).size = Vector2(maxf(length - 40.0, 1.0), THICK)
	_shape.position = Vector2(-length * 0.5 - 20.0, 0)
	queue_redraw()


func _draw() -> void:
	var length := global_position.x - wall_x
	var frame := int(_time * FPS) % 3
	var mouth := _mouth[frame]
	var tip := _tip[frame]
	var mouth_w := mouth.get_width() * SCALE
	var tip_w := tip.get_width() * SCALE
	# Meio: de onde a ponta termina até onde o clarão começa, repetido e correndo para a esquerda.
	var from_x := -length + tip_w * 0.5
	var to_x := -mouth_w * 0.5
	var tile_w := _middle.get_width() * SCALE
	var tile_h := _middle.get_height() * SCALE
	var x := to_x + fposmod(-_time * FLOW, tile_w)
	while x > from_x:
		var start := maxf(x - tile_w, from_x)
		var end := minf(x, to_x)
		if end > start:
			var src_x := (start - (x - tile_w)) / SCALE
			draw_texture_rect_region(_middle, Rect2(start, -tile_h * 0.5, end - start, tile_h),
					Rect2(src_x, 0, (end - start) / SCALE, _middle.get_height()))
		x -= tile_w
	draw_texture_rect(tip, Rect2(-length, -tip.get_height() * SCALE * 0.5, tip_w, tip.get_height() * SCALE), false)
	draw_texture_rect(mouth, Rect2(-mouth_w, -mouth.get_height() * SCALE * 0.5, mouth_w,
			mouth.get_height() * SCALE), false)
