extends Control
## Tela inicial: hospedar partida, entrar numa partida por IP, testar sozinho,
## configurações e sair.

const JOIN_TIMEOUT := 8.0

## Fase que abre ao começar (por enquanto, a arena de teste).
@export_file("*.tscn") var first_level := "res://levels/test_arena/test_arena.tscn"
@export var background: Texture2D

var _main_buttons: VBoxContainer
var _join_panel: VBoxContainer
var _address_edit: LineEdit
var _status: Label
var _settings_menu: SettingsMenu
var _join_timer: SceneTreeTimer


func _ready() -> void:
	add_to_group(&"menu_screen")
	theme = UiTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	center.add_child(layout)

	layout.add_child(UiTheme.title_label("Respeitável Público", 110))
	var subtitle := Label.new()
	subtitle.text = "Um circo assombrado para dois"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 34)
	layout.add_child(subtitle)

	_main_buttons = VBoxContainer.new()
	_main_buttons.add_theme_constant_override("separation", 14)
	_main_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(_main_buttons)
	var host_button := _add_button(_main_buttons, "Hospedar partida", _on_host_pressed)
	_add_button(_main_buttons, "Entrar na partida", _show_join_panel)
	_add_button(_main_buttons, "Testar sozinho", _on_solo_pressed)
	_add_button(_main_buttons, "Configurações", func() -> void: _settings_menu.open())
	_add_button(_main_buttons, "Sair", func() -> void: get_tree().quit())

	_build_join_panel(layout)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 28)
	_status.add_theme_color_override("font_color", UiTheme.GOLD)
	_status.text = Network.last_message
	Network.last_message = ""
	layout.add_child(_status)

	var settings_center := CenterContainer.new()
	settings_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(settings_center)
	_settings_menu = SettingsMenu.new()
	_settings_menu.hide()
	_settings_menu.closed.connect(func() -> void: host_button.grab_focus())
	settings_center.add_child(_settings_menu)

	Network.joined.connect(_on_joined)
	Network.join_failed.connect(_on_join_failed)
	host_button.grab_focus()


func _build_background() -> void:
	var background_rect := TextureRect.new()
	background_rect.texture = background
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background_rect)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.03, 0.06, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)


func _build_join_panel(parent: Control) -> void:
	_join_panel = VBoxContainer.new()
	_join_panel.add_theme_constant_override("separation", 14)
	_join_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_join_panel.hide()
	parent.add_child(_join_panel)

	var label := Label.new()
	label.text = "Endereço de quem está hospedando (IP ou endereço:porta):"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_join_panel.add_child(label)

	_address_edit = LineEdit.new()
	_address_edit.custom_minimum_size = Vector2(720, 0)
	_address_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_address_edit.placeholder_text = "ex.: 100.101.102.103  ou  jogo.at.ply.gg:12345"
	_address_edit.text = Settings.last_join_address
	_address_edit.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	_join_panel.add_child(_address_edit)

	_add_button(_join_panel, "Conectar", _on_connect_pressed)
	_add_button(_join_panel, "Voltar", _show_main_buttons)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(520, 0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_join_panel() -> void:
	_main_buttons.hide()
	_join_panel.show()
	_status.text = ""
	_address_edit.grab_focus()
	_address_edit.caret_column = _address_edit.text.length()


func _show_main_buttons() -> void:
	Network.leave()
	_join_panel.hide()
	_main_buttons.show()
	_main_buttons.get_child(0).grab_focus()


func _on_host_pressed() -> void:
	var error: Error = Network.host()
	if error != OK:
		_status.text = "Não consegui abrir a partida (erro %d). A porta %d pode estar em uso." % [error, Network.DEFAULT_PORT]
		return
	get_tree().change_scene_to_file(first_level)


func _on_solo_pressed() -> void:
	Network.leave()
	get_tree().change_scene_to_file(first_level)


func _on_connect_pressed() -> void:
	var address := _address_edit.text.strip_edges()
	if address.is_empty():
		_status.text = "Digite o endereço de quem está hospedando."
		return
	Settings.set_option(&"last_join_address", address)
	Network.leave()
	if Network.join(address) != OK:
		_status.text = "Esse endereço não parece válido."
		return
	_status.text = "Conectando a %s..." % address
	_join_timer = get_tree().create_timer(JOIN_TIMEOUT)
	_join_timer.timeout.connect(_on_join_timeout.bind(_join_timer))


func _on_joined() -> void:
	_join_timer = null
	get_tree().change_scene_to_file(first_level)


func _on_join_failed() -> void:
	_join_timer = null
	_status.text = "Não consegui conectar. Confira o IP e se a partida já foi aberta."


func _on_join_timeout(timer: SceneTreeTimer) -> void:
	if timer != _join_timer:
		return
	Network.leave()
	_status.text = "Demorou demais para conectar. Confira o IP e se o parceiro já hospedou."
