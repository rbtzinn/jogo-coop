class_name SettingsMenu
extends PanelContainer
## Tela de configurações: aba de controles (trocar teclas) e aba de vídeo (qualidade, tela, FPS).

signal closed

var _waiting_action: StringName = &""
var _waiting_slot := -1
var _binding_buttons := {}  # "ação:slot" -> Button
var _hint: Label


func _ready() -> void:
	theme = UiTheme.build()
	custom_minimum_size = Vector2(1500, 900)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)

	layout.add_child(UiTheme.title_label("Configurações", 54))

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(tabs)
	tabs.add_child(_build_controls_tab())
	tabs.add_child(_build_video_tab())

	var back := Button.new()
	back.text = "Voltar"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	layout.add_child(back)

	Settings.changed.connect(_refresh_bindings)


func open() -> void:
	show()
	_refresh_bindings()


func close() -> void:
	_stop_waiting()
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _waiting_slot >= 0:
		_capture(event)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# --- Aba Controles ---------------------------------------------------------

func _build_controls_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "Controles"
	tab.add_theme_constant_override("separation", 12)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 1 + Settings.SLOT_COUNT
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)

	for header in ["Ação", "Teclado 1", "Teclado 2", "Controle 1", "Controle 2"]:
		var label := Label.new()
		label.text = header
		label.add_theme_color_override("font_color", UiTheme.GOLD)
		grid.add_child(label)

	for action in Settings.REBINDABLE_ACTIONS:
		var name_label := Label.new()
		name_label.text = Settings.ACTION_NAMES[action]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 26)
		grid.add_child(name_label)
		for slot in Settings.SLOT_COUNT:
			var button := Button.new()
			button.custom_minimum_size = Vector2(230, 0)
			button.add_theme_font_size_override("font_size", 25)
			button.clip_text = true
			button.pressed.connect(_start_waiting.bind(action, slot))
			button.gui_input.connect(_on_binding_gui_input.bind(action, slot))
			grid.add_child(button)
			_binding_buttons["%s:%d" % [action, slot]] = button

	var up_jumps := CheckButton.new()
	up_jumps.text = "Tecla \"Cima\" também pula (segure Travar mira para mirar para cima)"
	up_jumps.add_theme_font_size_override("font_size", 25)
	up_jumps.button_pressed = Settings.up_jumps
	up_jumps.toggled.connect(func(on: bool) -> void: Settings.set_option(&"up_jumps", on))
	tab.add_child(up_jumps)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 24)
	tab.add_child(_hint)

	var reset := Button.new()
	reset.text = "Restaurar padrão"
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(Settings.reset_bindings)
	tab.add_child(reset)
	return tab


func _refresh_bindings() -> void:
	for action in Settings.REBINDABLE_ACTIONS:
		for slot in Settings.SLOT_COUNT:
			var button: Button = _binding_buttons["%s:%d" % [action, slot]]
			if action == _waiting_action and slot == _waiting_slot:
				button.text = "Aperte..."
			else:
				button.text = InputSerializer.display_name(Settings.get_binding(action, slot))
	if _waiting_slot >= 0:
		var device := "uma tecla" if Settings.is_keyboard_slot(_waiting_slot) else "um botão do controle"
		_hint.text = "Aperte %s para \"%s\". Esc cancela." % [device, Settings.ACTION_NAMES[_waiting_action]]
	else:
		_hint.text = "Clique num espaço e aperte a nova tecla. Botão direito do mouse apaga o espaço."


func _start_waiting(action: StringName, slot: int) -> void:
	_waiting_action = action
	_waiting_slot = slot
	_refresh_bindings()


func _stop_waiting() -> void:
	_waiting_action = &""
	_waiting_slot = -1
	_refresh_bindings()


func _capture(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_stop_waiting()
		elif Settings.is_keyboard_slot(_waiting_slot):
			_finish_capture(event)
	elif event is InputEventJoypadButton and event.pressed:
		if not Settings.is_keyboard_slot(_waiting_slot):
			_finish_capture(event)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		if not Settings.is_keyboard_slot(_waiting_slot):
			_finish_capture(event)


func _finish_capture(event: InputEvent) -> void:
	var action := _waiting_action
	var slot := _waiting_slot
	_waiting_action = &""
	_waiting_slot = -1
	Settings.set_binding(action, slot, InputSerializer.normalized(event))


func _on_binding_gui_input(event: InputEvent, action: StringName, slot: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_stop_waiting()
		Settings.set_binding(action, slot, null)


# --- Aba Vídeo -------------------------------------------------------------

func _build_video_tab() -> Control:
	var grid := GridContainer.new()
	grid.name = "Vídeo"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 18)

	_add_option(grid, "Qualidade gráfica", Settings.QUALITY_NAMES, Settings.quality, &"quality")
	_add_option(grid, "Modo de tela", Settings.WINDOW_MODE_NAMES, Settings.window_mode, &"window_mode")
	var sizes: Array = Settings.WINDOW_SIZES.map(func(s: Vector2i) -> String: return "%d × %d" % [s.x, s.y])
	_add_option(grid, "Tamanho da janela", sizes, Settings.window_size_index, &"window_size_index")
	var limits: Array = Settings.FPS_LIMITS.map(func(f: int) -> String: return "Sem limite" if f == 0 else str(f))
	_add_option(grid, "Limite de FPS", limits, Settings.fps_limit_index, &"fps_limit_index")
	_add_toggle(grid, "VSync (evita imagem rasgada)", Settings.vsync, &"vsync")
	_add_toggle(grid, "Mostrar FPS", Settings.show_fps, &"show_fps")

	var note := Label.new()
	note.text = "Qualidade: Baixa desliga o filtro de filme e partículas;\nMédia usa filtro leve; Alta liga tudo."
	note.add_theme_font_size_override("font_size", 24)
	note.add_theme_color_override("font_color", UiTheme.CREAM.darkened(0.25))
	grid.add_child(note)
	return grid


func _add_option(grid: GridContainer, text: String, items: Array, selected: int, property: StringName) -> void:
	var label := Label.new()
	label.text = text
	grid.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(420, 0)
	for item in items:
		option.add_item(item)
	option.select(selected)
	option.item_selected.connect(func(index: int) -> void: Settings.set_option(property, index))
	grid.add_child(option)


func _add_toggle(grid: GridContainer, text: String, value: bool, property: StringName) -> void:
	var label := Label.new()
	label.text = text
	grid.add_child(label)
	var toggle := CheckButton.new()
	toggle.button_pressed = value
	toggle.toggled.connect(func(on: bool) -> void: Settings.set_option(property, on))
	grid.add_child(toggle)
