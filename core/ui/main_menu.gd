extends Control
## Tela inicial: hospedar partida, entrar numa partida por IP, testar sozinho,
## configurações e sair.

const JOIN_TIMEOUT := 8.0

## Fase que abre ao começar (o mapa do parque do circo).
@export_file("*.tscn") var first_level := Levels.MAP
@export var background: Texture2D

var _main_buttons: VBoxContainer
var _join_panel: VBoxContainer
var _address_edit: LineEdit
var _status: Label
var _settings_menu: SettingsMenu
var _join_timer: SceneTreeTimer


func _ready() -> void:
	add_to_group(&"menu_screen")
	# Volta a usar o save deste PC (online como cliente, a cópia era do host).
	SaveGame.load_game()
	theme = UiTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 1050)
	margin.add_theme_constant_override("margin_top", 112)
	margin.add_theme_constant_override("margin_bottom", 90)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	var eyebrow := UiTheme.section_label("O GRANDE PICADEIRO", 23)
	layout.add_child(eyebrow)
	var title := UiTheme.title_label("Respeitável\nPúblico", 90, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Um circo assombrado para dois"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", UiTheme.CREAM)
	subtitle.add_theme_color_override("font_outline_color", UiTheme.INK)
	subtitle.add_theme_constant_override("outline_size", 2)
	layout.add_child(subtitle)

	# Os botões ficam num cartaz com lâmpadas (o painel de entrar na partida também).
	var poster := PosterPanel.new()
	poster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	poster.marquee = false
	layout.add_child(poster)
	var poster_layout := VBoxContainer.new()
	poster.add_child(poster_layout)
	_main_buttons = VBoxContainer.new()
	_main_buttons.add_theme_constant_override("separation", 10)
	_main_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	poster_layout.add_child(_main_buttons)
	var host_button := _add_button(_main_buttons, "Hospedar partida", _on_host_pressed)
	_add_button(_main_buttons, "Entrar na partida", _show_join_panel)
	_add_button(_main_buttons, "Jogar sozinho", _on_solo_pressed)
	# Modo de teste: save à parte, tudo aberto, ingressos e vida de sobra (SaveGame.start_test_mode).
	_add_button(_main_buttons, "Testar sozinho", _on_test_pressed)
	_add_button(_main_buttons, "Configurações", func() -> void: _settings_menu.open())
	_add_button(_main_buttons, "Sair", func() -> void: get_tree().quit())

	_build_join_panel(poster_layout)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 23)
	_status.add_theme_color_override("font_color", UiTheme.GOLD)
	_status.add_theme_color_override("font_outline_color", UiTheme.INK)
	_status.add_theme_constant_override("outline_size", 6)
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
	dim.color = Color(0.035, 0.05, 0.075, 0.12)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var footer := Label.new()
	footer.text = "PALHAÇO  &  ACROBATA                 UMA NOITE. DOIS ARTISTAS."
	footer.position = Vector2(1070, 997)
	footer.add_theme_font_size_override("font_size", 20)
	footer.add_theme_color_override("font_color", UiTheme.GOLD)
	add_child(footer)
	# Retratos mantêm o desenho e a identidade dos protagonistas, sem simular combate no menu.
	for entry in [["clown", Vector2(1150, 570), Vector2(260, 400)], ["acrobat", Vector2(1480, 555), Vector2(240, 420)]]:
		var portrait := TextureRect.new()
		portrait.texture = load("res://core/player/characters/%s/idle/idle_1.png" % entry[0])
		portrait.position = entry[1]
		portrait.size = entry[2]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(portrait)


func _build_join_panel(parent: Control) -> void:
	_join_panel = VBoxContainer.new()
	_join_panel.add_theme_constant_override("separation", 14)
	_join_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_join_panel.hide()
	parent.add_child(_join_panel)

	var label := Label.new()
	label.text = "Endereço de quem está hospedando (IP ou endereço:porta):"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 590
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_join_panel.add_child(label)

	_address_edit = LineEdit.new()
	_address_edit.custom_minimum_size = Vector2(590, 0)
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
	button.custom_minimum_size = Vector2(580, 58)
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
	SaveGame.start_normal()
	var error: Error = Network.host()
	if error != OK:
		_status.text = "Não consegui abrir a partida (erro %d). A porta %d pode estar em uso." % [error, Network.DEFAULT_PORT]
		return
	get_tree().change_scene_to_file(first_level)


func _on_solo_pressed() -> void:
	Network.leave()
	SaveGame.start_normal()
	get_tree().change_scene_to_file(first_level)


func _on_test_pressed() -> void:
	Network.leave()
	SaveGame.start_test_mode()
	get_tree().change_scene_to_file(first_level)


func _on_connect_pressed() -> void:
	var address := _address_edit.text.strip_edges()
	if address.is_empty():
		_status.text = "Digite o endereço de quem está hospedando."
		return
	Settings.set_option(&"last_join_address", address)
	Network.leave()
	SaveGame.start_normal()
	if Network.join(address) != OK:
		_status.text = "Esse endereço não parece válido."
		return
	_status.text = "Conectando a %s..." % address
	_join_timer = get_tree().create_timer(JOIN_TIMEOUT)
	_join_timer.timeout.connect(_on_join_timeout.bind(_join_timer))


func _on_joined() -> void:
	_join_timer = null
	# O host manda a fase em que ele está (Network._on_peer_connected).
	_status.text = "Conectado! Entrando na partida..."


func _on_join_failed() -> void:
	_join_timer = null
	_status.text = "Não consegui conectar. Confira o IP e se a partida já foi aberta."


func _on_join_timeout(timer: SceneTreeTimer) -> void:
	if timer != _join_timer:
		return
	Network.leave()
	_status.text = "Demorou demais para conectar. Confira o IP e se o parceiro já hospedou."
