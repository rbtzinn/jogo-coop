extends Control
## Tela inicial: hospedar partida, entrar numa partida por IP, jogar sozinho (os dois com escolha entre dois saves,
## continuar ou começar do zero), configurações e sair (e o
## "Testar sozinho", guardado e escondido: SHOW_TEST_MODE).

const JOIN_TIMEOUT := 15.0
## Botão "Testar sozinho" (modo de teste: tudo aberto, ingressos e vida de sobra). Guardado e escondido desde
## 06/10/2026 a pedido do usuário; trocar para true para usar de novo durante o desenvolvimento.
const SHOW_TEST_MODE := false

## Fase que abre ao começar (o mapa do parque do circo).
@export_file("*.tscn") var first_level := Levels.MAP
@export var background: Texture2D

var _main_buttons: VBoxContainer
var _join_panel: VBoxContainer
var _slot_panel: VBoxContainer
## Jeito de jogar do painel de saves aberto ("coop" ou "solo").
var _slot_mode := ""
var _address_edit: LineEdit
var _status: Label
var _settings_menu: SettingsMenu
var _join_timer: SceneTreeTimer
var _waiting_host := false
## O servidor de salas está configurado (sala por código, no PC e no celular).
var _uses_rooms := false
## No PC, "Online por IP" troca para hospedar ou entrar por IP (playit.gg, Tailscale ou IP direto) nesta
## escolha; voltar ao menu volta para a sala por código.
var _via_ip := false
var _ip_buttons: VBoxContainer
var _join_label: Label


func _ready() -> void:
	add_to_group(&"menu_screen")
	_uses_rooms = not OnlineConfig.relay_url().is_empty()
	# Volta a usar o save deste PC (online como cliente, a cópia era do host).
	SaveGame.load_game()
	theme = UiTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 130)
	margin.add_theme_constant_override("margin_right", 1080)
	margin.add_theme_constant_override("margin_top", 40 if Device.is_touch() else 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16 if Device.is_touch() else 22)
	margin.add_child(layout)

	# Cartaz de papel velho, um pouco torto, com o nome do espetáculo e os itens só em texto; a luva aponta o
	# escolhido (versão B das maquetes, escolhida pelo usuário em 16/10/2026). Os painéis de entrar na
	# partida e de escolher o save aparecem no mesmo cartaz.
	var poster := PosterPanel.new()
	poster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	poster.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	poster.marquee = false
	poster.rotation_degrees = -1.2
	poster.resized.connect(func() -> void: poster.pivot_offset = poster.size * 0.5)
	layout.add_child(poster)
	var poster_layout := VBoxContainer.new()
	poster_layout.add_theme_constant_override("separation", 4 if Device.is_touch() else 8)
	poster.add_child(poster_layout)
	var eyebrow := UiTheme.section_label("O GRANDE PICADEIRO APRESENTA", 20)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poster_layout.add_child(eyebrow)
	var title := UiTheme.title_label("Respeitável\nPúblico", 62 if Device.is_touch() else 76)
	title.add_theme_constant_override("line_spacing", -12)
	poster_layout.add_child(title)
	# Três estrelinhas vermelhas entre o nome e o resto (as fontes não têm o caractere de estrela).
	var stars := Control.new()
	stars.custom_minimum_size = Vector2(0, 26)
	stars.draw.connect(func() -> void:
		for i in 3:
			PosterPanel.draw_star(stars, Vector2(stars.size.x * 0.5 + (i - 1) * 44.0, 13.0), 10.0, UiTheme.PAPER_RED))
	poster_layout.add_child(stars)
	var subtitle := Label.new()
	subtitle.text = "Um circo assombrado para dois"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", UiTheme.body_size(28))
	subtitle.add_theme_color_override("font_color", UiTheme.PAPER_INK_SOFT)
	poster_layout.add_child(subtitle)
	_main_buttons = VBoxContainer.new()
	_main_buttons.add_theme_constant_override("separation", 10)
	_main_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	poster_layout.add_child(_main_buttons)
	var host_button := _add_button(_main_buttons, "Criar sala online" if _uses_rooms else "Hospedar partida", _show_slot_panel.bind("coop"))
	_add_button(_main_buttons, "Entrar com código" if _uses_rooms else "Entrar na partida", _show_join_panel)
	_add_button(_main_buttons, "Jogar sozinho", _show_slot_panel.bind("solo"))
	if _uses_rooms and not Device.is_touch() and not Device.is_web():
		_add_button(_main_buttons, "Online por IP (avançado)", _show_ip_buttons)
	if SHOW_TEST_MODE:
		_add_button(_main_buttons, "Testar sozinho", _on_test_pressed)
	_add_button(_main_buttons, "Configurações", func() -> void: _settings_menu.open())
	if Device.can_quit():
		_add_button(_main_buttons, "Sair", func() -> void: get_tree().quit())

	_build_join_panel(poster_layout)
	_build_ip_buttons(poster_layout)
	_build_slot_panel(poster_layout)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", UiTheme.body_size(23))
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
	Network.room_created.connect(_on_room_created)
	if not GameUpdates.platform().is_empty():
		var update_button := Button.new()
		update_button.text = "Verificar atualização"
		update_button.position = Vector2(1070, 975)
		update_button.custom_minimum_size = Vector2(690, 76)
		update_button.pressed.connect(GameUpdates.open_download)
		GameUpdates.status_changed.connect(func(message: String) -> void: _status.text = message)
		GameUpdates.update_available.connect(func(_version: String) -> void: update_button.text = "Atualizar agora")
		# Instalando de dentro do jogo: o botão mostra o andamento do download (negativo = falhou).
		GameUpdates.progress_changed.connect(func(fraction: float) -> void:
			update_button.disabled = fraction >= 0.0 and fraction < 1.0
			update_button.text = "Atualizar agora" if fraction < 0.0 else "Baixando... %d%%" % roundi(fraction * 100.0))
		GameUpdates.browser_offered.connect(func() -> void: update_button.text = "Baixar pelo navegador")
		if GameUpdates.browser_fallback:
			update_button.text = "Baixar pelo navegador"
		elif not GameUpdates.download_url.is_empty():
			update_button.text = "Atualizar agora"
		add_child(update_button)
	host_button.grab_focus()
	if HomeScreenTip.wanted():
		var tip := HomeScreenTip.new()
		tip.closed.connect(host_button.grab_focus)
		add_child(tip)


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
	# Com o botão de atualização no canto, o rodapé desce e mostra a versão.
	var shows_version := not GameUpdates.platform().is_empty()
	footer.text = "Versão " + OnlineConfig.VERSION_NAME if shows_version else "PALHAÇO  &  ACROBATA                 UMA NOITE. DOIS ARTISTAS."
	footer.position = Vector2(1070, 1054 if shows_version else 997)
	footer.add_theme_font_size_override("font_size", UiTheme.body_size(20))
	footer.add_theme_color_override("font_color", UiTheme.GOLD)
	add_child(footer)
	# Palhaço e acrobata de corpo inteiro (folhas do GPT), os dois virados para o cartaz à esquerda
	# (escolha do usuário em 16/10/2026).
	for entry in [["clown", Vector2(1290, 975)], ["acrobat", Vector2(1590, 975)]]:
		var cast := MenuCast.new(entry[0], true, 470.0)
		add_child(cast)
		cast.place_feet(entry[1])


func _build_join_panel(parent: Control) -> void:
	_join_panel = VBoxContainer.new()
	_join_panel.add_theme_constant_override("separation", 14)
	_join_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_join_panel.hide()
	parent.add_child(_join_panel)

	_join_label = Label.new()
	_join_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_join_label.custom_minimum_size.x = 590
	_join_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_join_panel.add_child(_join_label)

	_address_edit = LineEdit.new()
	_address_edit.custom_minimum_size = Vector2(590, 0)
	_address_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_address_edit.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	_join_panel.add_child(_address_edit)

	_add_button(_join_panel, "Conectar", _on_connect_pressed)
	_add_button(_join_panel, "Voltar", _show_main_buttons)


## "Online por IP (avançado)", só no PC: hospedar ou entrar por IP, sem o servidor de salas.
func _build_ip_buttons(parent: Control) -> void:
	_ip_buttons = VBoxContainer.new()
	_ip_buttons.add_theme_constant_override("separation", 10)
	_ip_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ip_buttons.hide()
	parent.add_child(_ip_buttons)
	var label := Label.new()
	label.text = "Por IP: playit.gg, Tailscale ou IP direto (porta %d). Quem entra precisa estar no PC." % Network.DEFAULT_PORT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 580
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip_buttons.add_child(label)
	_add_button(_ip_buttons, "Hospedar por IP", _show_slot_panel.bind("coop"))
	_add_button(_ip_buttons, "Entrar por IP", _show_join_panel)
	_add_button(_ip_buttons, "Voltar", _show_main_buttons)


func _show_ip_buttons() -> void:
	_via_ip = true
	_main_buttons.hide()
	_ip_buttons.show()
	_status.text = ""
	_ip_buttons.get_child(1).grab_focus()


## Sala por código nesta escolha (falso sem servidor de salas ou depois de "Online por IP").
func _rooms() -> bool:
	return _uses_rooms and not _via_ip


## Escolha do save (dupla ao hospedar, ou sozinho): continuar um dos dois ou começar do zero nele.
func _build_slot_panel(parent: Control) -> void:
	_slot_panel = VBoxContainer.new()
	_slot_panel.add_theme_constant_override("separation", 12)
	_slot_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slot_panel.hide()
	parent.add_child(_slot_panel)


func _show_slot_panel(mode: String) -> void:
	_slot_mode = mode
	for child in _slot_panel.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = "Jogar sozinho: escolha o save" if mode == "solo" else ("Criar sala: escolha o save da dupla" if _rooms() else "Hospedar por IP: escolha o save da dupla")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_panel.add_child(label)
	var first: Button = null
	for slot in SaveGame.SLOT_COUNT:
		var info := SaveGame.slot_info(mode, slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_slot_panel.add_child(row)
		var play := _add_button(row, _slot_text(slot, info), _start_slot.bind(slot, false))
		play.custom_minimum_size.x = 380
		if first == null:
			first = play
		var fresh := _add_button(row, "Do zero", Callable())
		fresh.custom_minimum_size.x = 190
		fresh.disabled = not info.exists
		fresh.pressed.connect(_confirm_fresh.bind(fresh, slot))
	_add_button(_slot_panel, "Voltar", _show_main_buttons)
	_main_buttons.hide()
	_ip_buttons.hide()
	_slot_panel.show()
	_status.text = ""
	first.grab_focus()


static func _slot_text(slot: int, info: Dictionary) -> String:
	if not info.exists:
		return "Save %d: começar" % (slot + 1)
	var done: int = info.done
	return "Save %d: continuar (%d %s)" % [slot + 1, done, "atração" if done == 1 else "atrações"]


## "Do zero" pede confirmação: o primeiro clique só troca o texto, o segundo apaga e começa.
func _confirm_fresh(button: Button, slot: int) -> void:
	if button.text != "Apagar?":
		button.text = "Apagar?"
		return
	_start_slot(slot, true)


func _start_slot(slot: int, fresh: bool) -> void:
	if _slot_mode == "coop":
		SaveGame.use_slot("coop", slot, fresh)
		Network.leave()
		var error: Error = Network.host_room() if _rooms() else Network.host()
		if error != OK:
			_status.text = Network.last_message if _rooms() else "Não consegui abrir a partida (erro %d). A porta %d pode estar em uso." % [error, Network.DEFAULT_PORT]
			return
		if _rooms():
			_waiting_host = true
			_status.text = "Criando sala..."
			_join_timer = get_tree().create_timer(JOIN_TIMEOUT)
			_join_timer.timeout.connect(_on_join_timeout.bind(_join_timer))
			return
	else:
		Network.leave()
		SaveGame.use_slot("solo", slot, fresh)
		# Sozinho: um personagem só (o último escolhido; Tab no mapa troca).
		PlayerSpawner.solo_slot = int(SaveGame.data.get("solo_character", 0))
	get_tree().change_scene_to_file(_first_scene())


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 68 if Device.is_touch() else 52)
	# Só o texto no papel, como item de cartaz: o escolhido fica vermelho e a luva do PosterPanel aponta.
	var flat := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, flat)
	button.add_theme_font_size_override("font_size", UiTheme.body_size(36))
	button.add_theme_color_override("font_pressed_color", UiTheme.RED_DARK)
	button.add_theme_color_override("font_hover_pressed_color", UiTheme.RED_DARK)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			button.grab_focus())
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_join_panel() -> void:
	var rooms := _rooms()
	_join_label.text = "Digite o código de 6 caracteres do seu parceiro:" if rooms else "Endereço de quem está hospedando (IP ou endereço:porta):"
	_address_edit.placeholder_text = "ex.: A7BC9D" if rooms else "ex.: 100.101.102.103 ou endereço:porta"
	_address_edit.max_length = 6 if rooms else 0
	_address_edit.text = "" if rooms else Settings.last_join_address
	_main_buttons.hide()
	_ip_buttons.hide()
	_join_panel.show()
	_status.text = ""
	_address_edit.grab_focus()
	_address_edit.caret_column = _address_edit.text.length()


func _show_main_buttons() -> void:
	_via_ip = false
	_ip_buttons.hide()
	_waiting_host = false
	_join_timer = null
	Network.leave()
	_join_panel.hide()
	_slot_panel.hide()
	_main_buttons.show()
	_main_buttons.get_child(0).grab_focus()


## Modo de teste (guardado, sem botão enquanto SHOW_TEST_MODE for falso): os dois personagens, save à parte,
## tudo aberto, ingressos e vida de sobra.
func _on_test_pressed() -> void:
	Network.leave()
	SaveGame.use_test()
	PlayerSpawner.solo_slot = -1
	get_tree().change_scene_to_file(_first_scene())


func _on_connect_pressed() -> void:
	var address := _address_edit.text.strip_edges()
	if address.is_empty():
		_status.text = "Digite o código da sala." if _rooms() else "Digite o endereço de quem está hospedando."
		return
	_waiting_host = false
	Network.leave()
	# O cliente joga com a cópia do save do host; aqui só sai do save de sozinho ou de teste.
	SaveGame.use_slot("coop", 0)
	if not _rooms():
		Settings.set_option(&"last_join_address", address)
	var error := Network.join_room(address) if _rooms() else Network.join(address)
	if error != OK:
		_status.text = Network.last_message if _rooms() else "Esse endereço não parece válido."
		return
	_status.text = "Entrando na sala %s..." % address.to_upper() if _rooms() else "Conectando a %s..." % address
	_join_timer = get_tree().create_timer(JOIN_TIMEOUT)
	_join_timer.timeout.connect(_on_join_timeout.bind(_join_timer))


func _on_joined() -> void:
	_join_timer = null
	# O host manda a fase em que ele está (Network._on_peer_connected).
	_status.text = "Conectado! Entrando na partida..."


func _on_join_failed() -> void:
	_join_timer = null
	_waiting_host = false
	_status.text = Network.last_message if not Network.last_message.is_empty() else ("Não consegui conectar. Confira o código e tente novamente." if _rooms() else "Não consegui conectar. Confira o IP e se a partida já foi aberta.")


func _on_room_created(_code: String) -> void:
	if not _waiting_host:
		return
	_waiting_host = false
	_join_timer = null
	get_tree().change_scene_to_file(_first_scene())


func _on_join_timeout(timer: SceneTreeTimer) -> void:
	if timer != _join_timer:
		return
	Network.leave()
	_join_timer = null
	_waiting_host = false
	_status.text = "Demorou demais para conectar. Confira a internet e tente novamente."


## Cena aberta ao começar: o mapa da área onde o save parou (ou outra, se a cena do menu escolher).
func _first_scene() -> String:
	return Levels.current_map() if first_level == Levels.MAP else first_level

