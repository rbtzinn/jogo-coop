class_name SoundWave
extends EnemyHitbox
## Onda do rugido: um arco alto que anda para a esquerda, com um buraco por onde passar.
## Dá para atravessar pelo buraco ou com o dash.

const SEGMENT_RADIUS := 16.0
## Desenho (tools/cut_tamer_effects.gd): o trecho do meio, que se repete ao longo do arco, e as pontas,
## em 3 quadros de vibração. Na folha a faixa é vertical, com a frente em x 100 e os ecos atrás (à
## direita); o jogo desenha pela metade, dobrando a faixa pela curva do arco.
const MIDDLE := [preload("res://bosses/tamer/art/effects/sound_middle_1.png"), preload("res://bosses/tamer/art/effects/sound_middle_2.png"),
		preload("res://bosses/tamer/art/effects/sound_middle_3.png")]
const TOP_CAP := [preload("res://bosses/tamer/art/effects/sound_top_1.png"), preload("res://bosses/tamer/art/effects/sound_top_2.png"), preload("res://bosses/tamer/art/effects/sound_top_3.png")]
const BOTTOM_CAP := [preload("res://bosses/tamer/art/effects/sound_bottom_1.png"), preload("res://bosses/tamer/art/effects/sound_bottom_2.png"),
		preload("res://bosses/tamer/art/effects/sound_bottom_3.png")]
const ART_SCALE := 0.5
const ART_WIDTH := 256.0
const ART_FRONT := 100.0
const FRAME_TIME := 0.08

## Altura coberta pelo arco (y global de cima e de baixo).
@export var top := 300.0
@export var bottom := 1000.0
## Centro e tamanho do buraco (y global).
@export var gap_center := 880.0
@export var gap_size := 300.0
## Quanto o arco se curva (as pontas ficam atrás do meio).
@export var bend := 70.0

var _time := 0.0
var _frame := 0


func _ready() -> void:
	super()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var y := top
	while y <= bottom:
		if absf(y - gap_center) > gap_size * 0.5:
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = SEGMENT_RADIUS
			shape.shape = circle
			shape.position = Vector2(_curve_x(y), y - global_position.y)
			add_child(shape)
		y += SEGMENT_RADIUS * 1.6


func _process(delta: float) -> void:
	# Tremida (escala) e troca do quadro de vibração.
	_time += delta
	scale.x = 1.0 + sin(_time * 30.0) * 0.06
	var frame := int(_time / FRAME_TIME) % MIDDLE.size()
	if frame != _frame:
		_frame = frame
		queue_redraw()


func _draw() -> void:
	var cap := TOP_CAP[0].get_height() * ART_SCALE
	var tile := MIDDLE[0].get_height() * ART_SCALE
	for piece in [[top, gap_center - gap_size * 0.5], [gap_center + gap_size * 0.5, bottom]]:
		var y0: float = piece[0]
		var y1: float = piece[1]
		if y1 - y0 < 4.0:
			continue
		# As pontas ocupam até metade do trecho cada; o meio repete a imagem pela altura.
		var end := minf(cap, (y1 - y0) * 0.5)
		_strip(TOP_CAP[_frame], y0, y0 + end, 0.0, end / cap)
		if y1 - y0 > end * 2.0:
			_strip(MIDDLE[_frame], y0 + end, y1 - end, 0.0, (y1 - y0 - end * 2.0) / tile)
		_strip(BOTTOM_CAP[_frame], y1 - end, y1, 1.0 - end / cap, 1.0)


## Um pedaço da faixa entre as alturas globais `y0` e `y1`, seguindo a curva do arco: a largura da
## imagem fica atravessada na curva (a frente à esquerda) e `v0`..`v1` é o trecho da imagem na altura.
func _strip(texture: Texture2D, y0: float, y1: float, v0: float, v1: float) -> void:
	var steps := maxi(int((y1 - y0) / 24.0), 1)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var left_uv := PackedVector2Array()
	var right_uv := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var y := lerpf(y0, y1, k)
		var center := Vector2(_curve_x(y), y - global_position.y)
		var tangent := Vector2(_curve_x(y + 1.0) - _curve_x(y - 1.0), 2.0).normalized()
		var normal := Vector2(tangent.y, -tangent.x)
		left.append(center + normal * (0.0 - ART_FRONT) * ART_SCALE)
		right.append(center + normal * (ART_WIDTH - ART_FRONT) * ART_SCALE)
		var v := lerpf(v0, v1, k)
		left_uv.append(Vector2(0.0, v))
		right_uv.append(Vector2(1.0, v))
	right.reverse()
	right_uv.reverse()
	draw_polygon(left + right, PackedColorArray([Color.WHITE]), left_uv + right_uv, texture)


## A frente do arco (meio da altura) fica mais à esquerda; as pontas, atrás.
func _curve_x(y: float) -> float:
	var middle := (top + bottom) * 0.5
	var u := (y - middle) / ((bottom - top) * 0.5)
	return bend * u * u
