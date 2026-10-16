class_name PosterPanel
extends PanelContainer
## Cartaz de circo para os menus (pausa, configurações, Camarim, loja, menu inicial): papel velho pintado
## com moldura vermelha (UiTheme.poster_box, em pé ou deitado conforme o formato do painel), lâmpadas de
## letreiro correndo em volta (opcional) e a luva apontando o botão escolhido (só nos botões largos das
## listas de menu).

## Lâmpadas de letreiro em volta do cartaz.
@export var marquee := false
## Botões a partir desta largura ganham a luva de "escolhido".
@export var star_min_width := 280.0

var _overlay := _Overlay.new()


var _tall := false


func _ready() -> void:
	_set_poster(false)
	resized.connect(func() -> void: _set_poster(size.y > size.x))
	_overlay.panel = self
	_overlay.lights = marquee
	add_child(_overlay)


func _set_poster(tall: bool) -> void:
	if tall == _tall and has_theme_stylebox_override("panel"):
		return
	_tall = tall
	add_theme_stylebox_override("panel", UiTheme.poster_box(tall))


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
	var _redraw_clock := 0.0

	func _ready() -> void:
		top_level = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_time += delta
		if not panel.is_visible_in_tree():
			hide()
			return
		var rect := panel.get_global_rect()
		global_position = rect.position
		size = rect.size
		visible = panel.is_visible_in_tree()
		_redraw_clock += delta
		if _redraw_clock >= 0.08:
			_redraw_clock = 0.0
			queue_redraw()

	func _draw() -> void:
		if lights:
			_draw_lights()
		var focused := get_viewport().gui_get_focus_owner() as BaseButton
		if focused == null or not panel.is_ancestor_of(focused) or focused.size.x < panel.star_min_width:
			return
		# Luva à esquerda do botão, apontando para ele e cutucando de leve.
		var box := focused.get_global_rect()
		# Botão de texto centralizado e sem caixa (itens do menu inicial): a luva encosta na palavra.
		var button := focused as Button
		if button != null and button.get_theme_stylebox("normal") is StyleBoxEmpty and button.icon == null:
			var font := button.get_theme_font("font")
			var text_width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
					button.get_theme_font_size("font_size")).x
			var start := box.get_center().x - text_width * 0.5 - 24.0
			box.position.x = maxf(box.position.x, start)
		var hand := UiTheme.POINTING_HAND
		var hand_size := hand.get_size() * (58.0 / hand.get_height())
		var poke := (1.0 - absf(sin(_time * 4.0))) * 8.0
		var at := Vector2(box.position.x - global_position.x - hand_size.x - 10.0 + poke,
				box.get_center().y - global_position.y - hand_size.y * 0.5)
		draw_texture_rect(hand, Rect2(at, hand_size), false)

	func _draw_lights() -> void:
		var rect := Rect2(Vector2.ZERO, size).grow(-6.0)
		var spacing := 90.0
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
