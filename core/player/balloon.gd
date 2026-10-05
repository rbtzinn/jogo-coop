class_name PlayerBalloon
extends Node2D
## Jogador caído vira um balão de circo rosa com a própria cara, que sobe devagar.
## O parceiro revive dando parry no balão. Com balão desenhado (FrameAnimation do personagem),
## toca os quadros; sem ele, é desenhado por código e a cara é a cabeça do personagem.
## Só muda o desenho: subida, balanço e área do parry ficam no Player e no BalloonArea.
## Com a folha de transformação: ao cair, os quadros 1-4 (virando balão) tocam uma vez antes
## do loop; no resgate, os 5-8 (estouro) tocam num efeito solto, porque o balão some na hora.

const PINK := Color("ff5fa2")
const PINK_DARK := Color("c23b78")
const INK := Color("1b1410")
const RADIUS := Vector2(66, 78)
## Quadros por segundo do loop flutuando (quadros 1 a 6).
const FLOAT_FPS := 6.0
## A partir de quanto do balanço (seno, 0 a 1) aparece o quadro inclinado.
const TILT_FROM := 0.92
## Quadros por segundo do "virando balão" (4 quadros) e do estouro do resgate (4 quadros).
const TURN_FPS := 10.0
const POP_FPS := 12.0

var _time := 0.0
var _face := Sprite2D.new()
var _frames: FrameAnimation
var _turn: FrameAnimation
var _frame_sprite := Sprite2D.new()
var _sway_speed := 1.6

@onready var area: BalloonArea = $BalloonArea


func _ready() -> void:
	add_child(_face)
	_frame_sprite.centered = false
	_frame_sprite.hide()
	add_child(_frame_sprite)
	set_active(false)


## Balão desenhado do personagem (8 quadros), a transformação e o resgate (8 quadros, opcional)
## e a velocidade do balanço do Player, para inclinar nos extremos. Sem quadros, fica o desenho
## por código.
func set_frames(frames: FrameAnimation, turn: FrameAnimation, sway_speed: float) -> void:
	_sway_speed = sway_speed
	_frames = frames if frames != null and frames.frame_count() >= 8 else null
	_turn = turn if _frames != null and turn != null and turn.frame_count() >= 8 else null
	_face.visible = _frames == null
	_frame_sprite.visible = _frames != null
	if _frames != null:
		_show(_frames, 0)


## Estouro do resgate (quadros 5-8 da transformação) num efeito solto no lugar do balão: o
## Player esconde o balão na mesma hora, e o efeito some sozinho no fim.
func pop() -> void:
	if _turn == null or not visible or get_parent() == null or get_parent().get_parent() == null:
		return
	var effect := Sprite2D.new()
	effect.centered = false
	effect.scale = Vector2.ONE * _turn.frame_scale
	effect.texture = _turn.frames[4]
	var holder := Node2D.new()
	holder.add_child(effect)
	effect.position = _turn.origin
	get_parent().get_parent().add_child(holder)
	holder.global_position = global_position
	holder.rotation = rotation
	var tween := holder.create_tween()
	for i in range(5, 8):
		tween.tween_interval(1.0 / POP_FPS)
		tween.tween_callback(effect.set_texture.bind(_turn.frames[i]))
	tween.tween_interval(1.0 / POP_FPS)
	tween.tween_callback(holder.queue_free)


func _show(animation: FrameAnimation, index: int) -> void:
	_frame_sprite.texture = animation.frames[index]
	_frame_sprite.scale = Vector2.ONE * animation.frame_scale
	_frame_sprite.position = animation.origin


## Usa a cabeça do personagem como cara do balão.
func set_face(head: Sprite2D, total_scale: float) -> void:
	_face.texture = head.texture
	_face.offset = head.offset
	_face.scale = Vector2.ONE * head.scale.x * total_scale * 0.78
	# A cabeça é desenhada a partir do pescoço; sobe para ficar no meio do balão.
	_face.position = Vector2(0, -head.offset.y * _face.scale.y * 0.5 - 6.0)


func set_active(value: bool) -> void:
	if value and not visible:
		# O balanço do Player também começa do zero quando cai.
		_time = 0.0
		if _turn != null:
			_show(_turn, 0)
	visible = value
	area.set_deferred("monitorable", value)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	rotation = sin(_time * 2.1) * 0.08
	if _turn != null and _time < 4.0 / TURN_FPS:
		_show(_turn, int(_time * TURN_FPS))
	elif _frames != null:
		_show(_frames, _frame_index())
	else:
		queue_redraw()


## 1-6 em loop; no extremo direito do balanço o 7 (inclinado para a esquerda, puxado de volta),
## no esquerdo o 8.
func _frame_index() -> int:
	var sway := sin(_time * _sway_speed)
	if sway > TILT_FROM:
		return 6
	if sway < -TILT_FROM:
		return 7
	return int(_time * FLOAT_FPS) % 6


func _draw() -> void:
	if _frames != null:
		return
	# Barbante balançando até a "mão" de baixo.
	var string := PackedVector2Array()
	for i in 9:
		var u := i / 8.0
		string.append(Vector2(sin(_time * 3.0 + u * 5.0) * 10.0 * u, RADIUS.y + 10.0 + u * 70.0))
	draw_polyline(string, INK, 3.0, true)
	# Balão.
	var body := PackedVector2Array()
	for i in 40:
		var angle := TAU * i / 40.0
		body.append(Vector2(cos(angle) * RADIUS.x, sin(angle) * RADIUS.y))
	draw_colored_polygon(body, PINK)
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, INK, 5.0, true)
	# Sombra e brilho.
	draw_arc(Vector2(8, 10), RADIUS.x * 0.85, 0.2, 1.9, 16, PINK_DARK, 10.0, true)
	draw_circle(Vector2(-RADIUS.x * 0.45, -RADIUS.y * 0.5), 12.0, Color(1, 1, 1, 0.55))
	# Nozinho.
	var knot := PackedVector2Array([Vector2(-9, RADIUS.y + 12), Vector2(9, RADIUS.y + 12), Vector2(0, RADIUS.y - 2)])
	draw_colored_polygon(knot, PINK_DARK)
	knot.append(knot[0])
	draw_polyline(knot, INK, 3.0, true)
