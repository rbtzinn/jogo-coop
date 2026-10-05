class_name PosterPanel
extends PanelContainer
## Cartaz de circo para os menus (pausa, configurações, Camarim, loja, menu inicial): papel creme com
## moldura vermelha (UiTheme.poster_box), um filete de tinta e estrelas douradas nos cantos por dentro
## da moldura, lâmpadas de letreiro correndo em volta (opcional) e duas estrelinhas ao lado do botão
## escolhido (só nos botões largos das listas de menu).

## Lâmpadas de letreiro em volta do cartaz.
@export var marquee := true
## Botões a partir desta largura ganham as estrelas de "escolhido".
@export var star_min_width := 280.0

var _overlay := _Overlay.new()


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.poster_box())
	_overlay.panel = self
	_overlay.lights = marquee
	add_child(_overlay)


func _draw() -> void:
	# Filete de tinta por dentro da moldura e uma estrela em cada canto.
	var inner := Rect2(Vector2.ZERO, size).grow(-22.0)
	draw_rect(inner, Color(UiTheme.INK, 0.55), false, 2.0)
	for corner in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
		draw_star(self, corner, 11.0, UiTheme.GOLD)


func _process(_delta: float) -> void:
	queue_redraw()


## Estrela de 5 pontas com contorno de tinta.
static func draw_star(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	canvas.draw_colored_polygon(points, color)
	points.append(points[0])
	canvas.draw_polyline(points, UiTheme.INK, 2.0, true)


## Por cima de tudo (fora do arranjo do cartaz): lâmpadas em volta e estrelas no botão escolhido.
class _Overlay extends Control:
	var panel: PosterPanel
	var lights := true
	var _time := 0.0

	func _ready() -> void:
		top_level = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_time += delta
		var rect := panel.get_global_rect()
		global_position = rect.position
		size = rect.size
		visible = panel.is_visible_in_tree()
		queue_redraw()

	func _draw() -> void:
		if lights:
			_draw_lights()
		var focused := get_viewport().gui_get_focus_owner() as BaseButton
		if focused == null or not panel.is_ancestor_of(focused) or focused.size.x < panel.star_min_width:
			return
		var box := focused.get_global_rect()
		var middle := box.get_center() - global_position
		var pulse := 1.0 + sin(_time * 6.0) * 0.12
		for side in [-1.0, 1.0]:
			var at := middle + Vector2(side * (box.size.x / 2.0 + 26.0), 0)
			PosterPanel.draw_star(self, at, 14.0 * pulse, UiTheme.GOLD)

	func _draw_lights() -> void:
		var rect := Rect2(Vector2.ZERO, size).grow(-6.0)
		var spacing := 34.0
		var perimeter := 2.0 * (rect.size.x + rect.size.y)
		var count := maxi(4, int(perimeter / spacing))
		var step := perimeter / count
		var phase := int(_time * 4.0)
		for i in count:
			var p := MarqueeLights._point_on_border(rect, i * step)
			var lit := (i + phase) % 3 != 0
			if lit:
				draw_circle(p, 11.0, Color("fff3c4", 0.18))
			draw_circle(p, 7.0, UiTheme.INK)
			draw_circle(p, 5.5, Color("fff3c4") if lit else Color("7a5a2e"))
