extends CanvasLayer
## Menu de pausa (Esc ou Start): continuar, Camarim (só no mapa), voltar ao mapa (fora dele), configurações,
## voltar ao menu e sair.
## Sozinho, congela o jogo. Online, a pausa de QUALQUER UM congela os dois PCs (pedido do usuário em 06/10/2026;
## até então só a do host congelava); o outro vê a faixa "Pausa do parceiro". Se os dois pausarem, o jogo só volta
## quando os dois continuarem.

const MAIN_MENU := "res://core/ui/main_menu.tscn"

var _root: Control
var _main_panel: PanelContainer
var _settings_menu: SettingsMenu
var _continue_button: Button
var _dressing_room: DressingRoom
var _dressing_button: Button
var _map_button: Button
## O parceiro pausou (o jogo fica congelado aqui até ele continuar).
var _partner_paused := false
var _partner_banner: Control
var _both_note: Label
## Esta pausa está congelando os dois PCs (online).
var _sharing := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.build()
	add_child(_root)

	UiTheme.backdrop(_root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	_main_panel = PosterPanel.new()
	center.add_child(_main_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	_main_panel.add_child(layout)
	layout.add_child(UiTheme.page_header("Intervalo", "O espetáculo continua quando você estiver pronto."))
	_both_note = Label.new()
	_both_note.text = "Pausado para os dois."
	_both_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_both_note.add_theme_color_override("font_color", UiTheme.GOLD)
	layout.add_child(_both_note)
	_continue_button = _add_button(layout, "Continuar", close)
	_dressing_button = _add_button(layout, "Camarim", _open_dressing_room)
	_map_button = _add_button(layout, "Voltar ao mapa", _back_to_map)
	_add_button(layout, "Configurações", _open_settings)
	_add_button(layout, "Voltar ao menu", _back_to_menu)
	_add_button(layout, "Sair do jogo", func() -> void: get_tree().quit())

	_settings_menu = SettingsMenu.new()
	_settings_menu.hide()
	_settings_menu.closed.connect(_on_settings_closed)
	center.add_child(_settings_menu)

	_dressing_room = DressingRoom.new()
	_dressing_room.hide()
	# Voltar do Camarim volta direto para o mapa (pedido do usuário em 04/10/2026: pela tenda, caía na pausa).
	_dressing_room.closed.connect(close)
	center.add_child(_dressing_room)

	_root.hide()
	_build_partner_banner()
	Network.host_lost.connect(_back_to_menu)
	# Parceiro que sai no meio da pausa dele não deixa o jogo congelado aqui.
	Network.partner_disconnected.connect(func(_peer_id: int) -> void: _set_partner_paused(false))
	# Parceiro que entra (ou volta) com o host pausado também congela.
	Network.peer_ready.connect(func(peer_id: int) -> void:
		if Network.is_host() and _shares_pause():
			_receive_partner_pause.rpc_id(peer_id, true))


func _unhandled_input(event: InputEvent) -> void:
	var scene := get_tree().current_scene
	if not event.is_action_pressed("pause") or scene == null or scene.is_in_group(&"menu_screen"):
		return
	if not _root.visible:
		open()
	elif _main_panel.visible:
		close()
	get_viewport().set_input_as_handled()


## `share`: online, a pausa congela os dois PCs (falso no Camarim aberto pela tenda do mapa: só quem entrou fica
## parado escolhendo roupa).
func open(share := true) -> void:
	_root.show()
	_main_panel.show()
	_settings_menu.hide()
	_dressing_room.hide()
	# O Camarim só abre no mapa (não no meio da luta).
	var scene := get_tree().current_scene
	_dressing_button.visible = scene != null and scene.scene_file_path == Levels.MAP
	# Voltar ao mapa: no meio de uma luta ou do trem. Online, só o host (ele leva os dois).
	_map_button.visible = scene != null and scene.scene_file_path != Levels.MAP and (not Network.is_online() or Network.is_host())
	_sharing = share and Network.is_online()
	_both_note.visible = _sharing
	if _sharing:
		_send_pause(true)
	get_tree().paused = not Network.is_online() or _sharing or _partner_paused
	_continue_button.grab_focus()


func close() -> void:
	_root.hide()
	if _sharing:
		_sharing = false
		_send_pause(false)
	get_tree().paused = _partner_paused and Network.is_online()


func _open_settings() -> void:
	_main_panel.hide()
	_settings_menu.open()


func _open_dressing_room() -> void:
	_main_panel.hide()
	_dressing_room.open()


func _on_settings_closed() -> void:
	_main_panel.show()
	_continue_button.grab_focus()


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func is_open() -> bool:
	return _root.visible


## O parceiro pausou o jogo para os dois agora.
func is_partner_paused() -> bool:
	return _partner_paused


## Larga a luta ou a fase e volta para o parque, na frente da atração por onde entraram.
func _back_to_map() -> void:
	close()
	Network.change_level(Levels.MAP)


func _back_to_menu() -> void:
	_set_partner_paused(false)
	close()
	Network.leave()
	get_tree().change_scene_to_file(MAIN_MENU)


# --- Pausa de um para os dois ---------------------------------------------------------------

func _shares_pause() -> bool:
	return _sharing and _root.visible


func _send_pause(on: bool) -> void:
	if Network.is_host():
		for peer_id in Network.ready_peers:
			_receive_partner_pause.rpc_id(peer_id, on)
	else:
		_receive_partner_pause.rpc_id(1, on)


@rpc("any_peer", "call_remote", "reliable")
func _receive_partner_pause(on: bool) -> void:
	Network.deliver(_set_partner_paused.bind(on), false)


func _set_partner_paused(on: bool) -> void:
	_partner_paused = on
	_partner_banner.visible = on
	get_tree().paused = on or (_root.visible and not Network.is_online())


## Faixa "Pausa do parceiro" no alto da tela de quem não pausou.
func _build_partner_banner() -> void:
	var holder := VBoxContainer.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.offset_top = 40
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	holder.add_child(UiTheme.banner("Pausa do parceiro", 56))
	var hint := Label.new()
	hint.text = "O jogo continua quando o parceiro voltar."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", UiTheme.BODY_FONT)
	hint.add_theme_font_size_override("font_size", 30)
	hint.add_theme_color_override("font_color", UiTheme.CREAM)
	hint.add_theme_color_override("font_outline_color", UiTheme.INK)
	hint.add_theme_constant_override("outline_size", 8)
	holder.add_child(hint)
	_partner_banner = holder
	_partner_banner.hide()
