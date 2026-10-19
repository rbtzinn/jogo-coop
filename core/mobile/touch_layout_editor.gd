class_name TouchLayoutEditor
extends CanvasLayer
## Editor de posição dos controles de toque (aberto nas Configurações do celular): mostra o analógico e os
## botões da luta e da pausa por cima de tudo; cada um pode ser arrastado para qualquer lugar da tela (pedido do
## usuário em 19/10/2026). "Pronto" salva em Settings.touch_layout; "Restaurar padrão" volta tudo ao lugar.

signal closed

## Controle sendo arrastado por cada dedo (o mouse conta como dedo -1, para testar no PC).
var _dragging := {}
## { nome: {at, r, text} } como em MobileControls.layout_for.
var _layout := {}
var _surface := Control.new()
var _view := Vector2.ZERO


static func open(parent: Node) -> TouchLayoutEditor:
	var editor := TouchLayoutEditor.new()
	parent.get_tree().root.add_child(editor)
	return editor


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = get_viewport().get_visible_rect().size
	_layout = MobileControls.layout_for(_view, false)
	var root := Control.new()
	root.theme = UiTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.05, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	# Cartaz com as instruções no alto; os controles são desenhados por cima dele (dá para arrastar até lá).
	var header := CenterContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 24.0
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)
	var poster := PosterPanel.new()
	header.add_child(poster)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	poster.add_child(top)
	top.add_child(UiTheme.title_label("Posição dos controles", 46))
	var hint := Label.new()
	hint.text = "Arraste cada controle para onde ficar melhor."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", UiTheme.body_size(28))
	top.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	top.add_child(row)
	row.add_child(_button("Restaurar padrão", reset))
	row.add_child(_button("Pronto", finish))
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.draw.connect(_draw_controls)
	root.add_child(_surface)


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380, 84)
	button.pressed.connect(callback)
	return button


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_press(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_move(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_press(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		_move(-1, event.position)


## Dedo encostou (ou soltou) em `at`: pega o controle que estiver embaixo.
func _press(finger: int, at: Vector2, pressed: bool) -> void:
	if not pressed:
		_dragging.erase(finger)
		return
	for key: StringName in _layout:
		var control: Dictionary = _layout[key]
		if at.distance_to(control.at) <= float(control.r) and not _dragging.values().has(key):
			_dragging[finger] = key
			get_viewport().set_input_as_handled()
			return


func _move(finger: int, at: Vector2) -> void:
	if not _dragging.has(finger):
		return
	drag_to(_dragging[finger], at)
	get_viewport().set_input_as_handled()


## Leva um controle para `at`, sempre inteiro dentro da tela.
func drag_to(key: StringName, at: Vector2) -> void:
	var control: Dictionary = _layout[key]
	control.at = MobileControls.clamp_into(at, control.r, Rect2(Vector2.ZERO, _view))
	_surface.queue_redraw()


func position_of(key: StringName) -> Vector2:
	return _layout[key].at


func reset() -> void:
	Settings.set_touch_layout({})
	_layout = MobileControls.layout_for(_view, false)
	_surface.queue_redraw()


func finish() -> void:
	var saved := {}
	for key: StringName in _layout:
		saved[String(key)] = _layout[key].at / _view
	Settings.set_touch_layout(saved)
	closed.emit()
	queue_free()


func _draw_controls() -> void:
	for key: StringName in _layout:
		var control: Dictionary = _layout[key]
		var held := _dragging.values().has(key)
		if key == &"joystick":
			MobileControls.draw_stick(_surface, control.at, control.r, Vector2.ZERO)
		else:
			MobileControls.draw_button(_surface, control.at, control.r, control.text, held, key == &"shoot")
		if held:
			_surface.draw_arc(control.at, control.r + 10.0, 0, TAU, 48, UiTheme.GOLD, 4.0, true)
