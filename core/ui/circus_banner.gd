class_name CircusBanner
extends Control
## Faixa de circo (fita vermelha com pontas dobradas e bordas douradas) com um texto grande.
## Usada nos letreiros da luta: abertura, troca de fase e "Picadeiro conquistado!".

@export var text := ""
@export var font_size := 96
## Raios de luz girando atrás (para o "Picadeiro conquistado!").
@export var burst := false

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var font := UiTheme.TITLE_FONT
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var center := size * 0.5
	if burst:
		_draw_burst(center, maxf(text_size.x, 600.0) * 0.75)
	var half := Vector2(text_size.x * 0.5 + 70.0, font_size * 0.62)
	var ink := UiTheme.INK
	# Pontas dobradas atrás da fita.
	for side in [-1.0, 1.0]:
		var tip_x: float = center.x + side * (half.x + 70.0)
		var base_x: float = center.x + side * (half.x - 30.0)
		var tail := PackedVector2Array([
			Vector2(base_x, center.y - half.y + 26), Vector2(tip_x, center.y - half.y + 26),
			Vector2(tip_x - side * 34.0, center.y + 10), Vector2(tip_x, center.y + half.y + 26),
			Vector2(base_x, center.y + half.y + 26)])
		draw_colored_polygon(tail, UiTheme.RED_DARK)
		tail.append(tail[0])
		draw_polyline(tail, ink, 5.0, true)
	# Fita principal, levemente curvada.
	var ribbon := PackedVector2Array()
	var steps := 24
	for i in steps + 1:
		var u := float(i) / steps
		var x := lerpf(center.x - half.x, center.x + half.x, u)
		ribbon.append(Vector2(x, center.y - half.y - sin(u * PI) * 14.0))
	for i in range(steps, -1, -1):
		var u := float(i) / steps
		var x := lerpf(center.x - half.x, center.x + half.x, u)
		ribbon.append(Vector2(x, center.y + half.y - sin(u * PI) * 14.0))
	draw_colored_polygon(ribbon, UiTheme.RED)
	var outline := ribbon.duplicate()
	outline.append(ribbon[0])
	draw_polyline(outline, ink, 6.0, true)
	# Frisos dourados.
	for offset in [-half.y + 12.0, half.y - 12.0]:
		var stripe := PackedVector2Array()
		for i in steps + 1:
			var u := float(i) / steps
			stripe.append(Vector2(lerpf(center.x - half.x + 10.0, center.x + half.x - 10.0, u),
					center.y + offset - sin(u * PI) * 14.0))
		draw_polyline(stripe, UiTheme.GOLD, 4.0, true)
	# Texto com contorno escuro.
	var baseline := Vector2(center.x - text_size.x * 0.5, center.y + font_size * 0.33 - 10.0)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 22, ink)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiTheme.CREAM)


func _draw_burst(center: Vector2, reach: float) -> void:
	var rays := 16
	for i in rays:
		var angle := TAU * i / rays + _time * 0.6
		var a := Vector2.from_angle(angle - 0.09) * reach
		var b := Vector2.from_angle(angle + 0.09) * reach
		var color := Color(UiTheme.GOLD, 0.55) if i % 2 == 0 else Color(UiTheme.CREAM, 0.35)
		draw_colored_polygon(PackedVector2Array([center, center + a, center + b]), color)
	for i in 8:
		var angle := TAU * i / 8.0 - _time * 0.9
		_draw_star(center + Vector2.from_angle(angle) * reach * 0.62, 22.0 + sin(_time * 6.0 + i) * 5.0)


func _draw_star(at: Vector2, r: float) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, UiTheme.GOLD)
	points.append(points[0])
	draw_polyline(points, UiTheme.INK, 3.0, true)


## Mostra uma faixa no meio da tela que entra quicando e sai voando para cima.
## `burst`: raios de luz girando atrás (vitória).
static func show_on(parent: Node, message: String, burst_rays := false) -> void:
	if message.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 15
	parent.add_child(layer)
	var banner := CircusBanner.new()
	banner.text = message
	banner.burst = burst_rays
	banner.font_size = 110 if burst_rays else 88
	banner.size = Vector2(1920, 1080)
	banner.pivot_offset = Vector2(960, 540)
	layer.add_child(banner)
	banner.scale = Vector2(0.3, 0.3)
	banner.rotation = -0.12
	var tween := banner.create_tween()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner, "rotation", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.6 if burst_rays else 1.0)
	tween.tween_property(banner, "position:y", -700.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(layer.queue_free)
