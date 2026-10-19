extends CanvasLayer
## Multitoque para o mesmo InputMap usado no PC. Não altera os comandos da rede.
## Ajustes nas Configurações (19/10/2026): analógico fixo ou flutuante, tamanho, transparência, tiro automático,
## vibração ao levar dano e a posição de cada controle (editor em TouchLayoutEditor, salvo em Settings).

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const ACTIONS: Array[StringName] = [&"jump", &"shoot", &"dash", &"lock_aim", &"special"]
const INK := Color("1b1410")
const CREAM := Color("ffe2ac")
const GOLD := Color("e1b65c")

class Surface extends Control:
	var controls: Node

	func _draw() -> void:
		controls.draw_surface(self)

var _surface: Surface
var _focused := true
var _application_paused := false
var _active := false
var _map_mode := false
var _scene: Node
var _joystick_finger := -1
var _joystick_center := Vector2.ZERO
## Onde o analógico fica parado (o flutuante volta para cá ao soltar).
var _joystick_home := Vector2.ZERO
var _joystick_radius := 125.0
var _joystick_offset := Vector2.ZERO
var _button_fingers: Dictionary = {}
var _buttons: Dictionary = {}
var _pressed: Dictionary = {}
var _scale := 1.0
var _viewport_size := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	if not Device.is_touch():
		set_process(false)
		set_process_input(false)
		return
	enable()


func enable() -> void:
	if _surface != null:
		return
	set_process(true)
	set_process_input(true)
	_surface = Surface.new()
	_surface.controls = self
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_surface)
	_surface.hide()
	get_viewport().size_changed.connect(_layout)
	Settings.changed.connect(_layout)
	_layout()
	# Android envia o botão Voltar como notificação, não como uma tecla Escape.
	get_tree().auto_accept_quit = false


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		release_all()
		_scene = scene
	var map_mode := scene != null and Levels.is_map(scene.scene_file_path)
	if map_mode != _map_mode:
		release_all()
		_map_mode = map_mode
		_layout()
	var active := _can_control()
	if active != _active:
		_active = active
		if not active:
			release_all()
		_surface.visible = active
	if _active:
		_surface.queue_redraw()
	_watch_hurt()


func _can_control() -> bool:
	return _focused and not _application_paused \
			and get_tree().current_scene != null and not get_tree().paused \
			and not PauseMenu.is_open() \
			and get_tree().get_first_node_in_group(&"blocking_ui") == null \
			and (get_tree().get_first_node_in_group(&"players") != null \
			or get_tree().get_first_node_in_group(&"walkers") != null)


func wants_auto_shoot() -> bool:
	# Só o PlayerInput local usa este sinal; nenhuma ação global de tiro fica presa.
	var scene := get_tree().current_scene
	return _surface != null and Settings.touch_auto_shoot and _can_control() \
			and scene != null and not Levels.is_map(scene.scene_file_path) \
			and get_tree().get_first_node_in_group(&"players") != null


func _layout() -> void:
	if _surface == null:
		return
	release_all()
	_viewport_size = get_viewport().get_visible_rect().size
	_buttons = layout_for(_viewport_size, _map_mode)
	var stick: Dictionary = _buttons[&"joystick"]
	_buttons.erase(&"joystick")
	_joystick_home = stick.at
	_joystick_center = stick.at
	_joystick_radius = stick.r


## Onde fica cada controle numa tela de tamanho `view`: { nome: {at, r, text} }, com o analógico em "joystick".
## Posições padrão perto das bordas (fora do entalhe e da barrinha de Início), trocadas pelas que o jogador
## escolheu no editor (menos ENTRAR e TROCAR do mapa, que ficam sempre no padrão).
func layout_for(view: Vector2, map_mode: bool) -> Dictionary:
	_scale = minf(view.x / 1920.0, view.y / 1080.0)
	var unit := _scale * Settings.TOUCH_SIZES[Settings.touch_size_index]
	var safe := Device.safe_insets(view)
	var w := view.x - safe.z
	var h := view.y - safe.w
	var result := {}
	result[&"joystick"] = {"at": Vector2(safe.x + 220.0 * unit, h - 210.0 * unit), "r": 125.0 * unit, "text": "ANDAR"}
	result[&"pause"] = {"at": Vector2(w - 110.0 * unit, safe.y + 90.0 * unit), "r": 65.0 * unit, "text": "PAUSA"}
	if map_mode:
		result[&"shoot"] = {"at": Vector2(w - 150.0 * unit, h - 280.0 * unit), "r": 76.0 * unit, "text": "ENTRAR"}
		if not Network.is_online():
			result[&"swap"] = {"at": Vector2(w - 310.0 * unit, h - 130.0 * unit), "r": 76.0 * unit, "text": "TROCAR"}
	else:
		result[&"jump"] = {"at": Vector2(w - 320.0 * unit, h - 125.0 * unit), "r": 76.0 * unit, "text": "PULAR"}
		result[&"dash"] = {"at": Vector2(w - 150.0 * unit, h - 110.0 * unit), "r": 65.0 * unit, "text": "DASH"}
		result[&"special"] = {"at": Vector2(w - 490.0 * unit, h - 125.0 * unit), "r": 65.0 * unit, "text": "EX"}
		result[&"lock_aim"] = {"at": Vector2(w - 330.0 * unit, h - 310.0 * unit), "r": 65.0 * unit, "text": "MIRA"}
		if not Settings.touch_auto_shoot:
			result[&"shoot"] = {"at": Vector2(w - 150.0 * unit, h - 290.0 * unit), "r": 76.0 * unit, "text": "TIRO"}
	var area := Rect2(safe.x, safe.y, w - safe.x, h - safe.y)
	for key: StringName in result:
		if map_mode and key in [&"shoot", &"swap"]:
			continue
		if Settings.touch_layout.has(String(key)):
			var fraction: Vector2 = Settings.touch_layout[String(key)]
			result[key].at = clamp_into(fraction * view, result[key].r, area)
	return result


## Ponto mais perto de `at` em que um círculo de raio `radius` cabe inteiro dentro de `area`.
static func clamp_into(at: Vector2, radius: float, area: Rect2) -> Vector2:
	return Vector2(clampf(at.x, area.position.x + radius, maxf(area.end.x - radius, area.position.x + radius)),
		clampf(at.y, area.position.y + radius, maxf(area.end.y - radius, area.position.y + radius)))


func _input(event: InputEvent) -> void:
	if _surface == null or not _active or not _can_control():
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _joystick_finger:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()
		elif _button_fingers.has(event.index):
			var action: StringName = _button_fingers[event.index]
			var button: Dictionary = _buttons[action]
			if event.position.distance_to(button.at) > float(button.r) + 18.0 * _scale:
				_touch_up(event.index)
			get_viewport().set_input_as_handled()


func _touch_down(finger: int, at: Vector2) -> void:
	if _button_fingers.has(finger) or finger == _joystick_finger:
		return
	var floating := Settings.touch_floating_stick
	if not floating and _joystick_finger < 0 and at.distance_to(_joystick_center) <= _joystick_radius * 1.45:
		_joystick_finger = finger
		_update_joystick(at)
		get_viewport().set_input_as_handled()
		return
	for action: StringName in _buttons:
		var button: Dictionary = _buttons[action]
		if at.distance_to(button.at) > float(button.r):
			continue
		get_viewport().set_input_as_handled()
		if action == &"pause":
			release_all()
			PauseMenu.open()
		elif action == &"swap":
			release_all()
			var scene := get_tree().current_scene
			if scene != null and scene.has_method("swap_solo_character"):
				if PlayerSpawner.solo_slot >= 0:
					scene.swap_solo_character()
				else:
					for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
						walker.input.local_control = not walker.input.local_control
		else:
			_button_fingers[finger] = action
			_set_action(action, 1.0)
		return
	# Flutuante: qualquer toque na metade esquerda que não caiu num botão vira o centro do analógico.
	if floating and _joystick_finger < 0 and at.x < _viewport_size.x * 0.5:
		_joystick_finger = finger
		_joystick_center = at
		_update_joystick(at)
		get_viewport().set_input_as_handled()


func _touch_up(finger: int) -> void:
	if finger == _joystick_finger:
		_joystick_finger = -1
		_joystick_offset = Vector2.ZERO
		_joystick_center = _joystick_home
		for action in MOVE_ACTIONS:
			_set_action(action, 0.0)
		get_viewport().set_input_as_handled()
	if _button_fingers.has(finger):
		var action: StringName = _button_fingers[finger]
		_button_fingers.erase(finger)
		if not _button_fingers.values().has(action):
			_set_action(action, 0.0)
		get_viewport().set_input_as_handled()


func _update_joystick(at: Vector2) -> void:
	_joystick_offset = (at - _joystick_center).limit_length(_joystick_radius)
	var axis := _joystick_offset / _joystick_radius
	# Eixo digital evita diagonais fracas em Input.get_vector com deadzone.
	_set_action(&"move_left", 1.0 if axis.x < -0.22 else 0.0)
	_set_action(&"move_right", 1.0 if axis.x > 0.22 else 0.0)
	_set_action(&"move_up", 1.0 if axis.y < -0.22 else 0.0)
	_set_action(&"move_down", 1.0 if axis.y > 0.22 else 0.0)


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		if not _pressed.has(action):
			Input.action_press(action, strength)
			_pressed[action] = true
	elif _pressed.has(action):
		Input.action_release(action)
		_pressed.erase(action)


func release_all() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
	_button_fingers.clear()
	_joystick_finger = -1
	_joystick_offset = Vector2.ZERO
	_joystick_center = _joystick_home


## Vibra quando um jogador deste aparelho leva dano (se ligado nas Configurações). O iPhone pelo navegador
## não vibra: o Safari não deixa.
func _watch_hurt() -> void:
	for node in get_tree().get_nodes_in_group(&"players"):
		var player := node as Player
		if player == null or player.has_meta(&"touch_vibration") or not player.is_multiplayer_authority():
			continue
		player.set_meta(&"touch_vibration", true)
		player.player_health.hurt.connect(func(_from: Vector2) -> void:
			if Settings.touch_vibration:
				Input.vibrate_handheld(120))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		release_all()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_application_paused = true
		release_all()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_application_paused = false
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and _surface != null:
		release_all()
		if PauseMenu.is_open():
			PauseMenu.close()
		elif _can_control():
			PauseMenu.open()


func _exit_tree() -> void:
	release_all()


func draw_surface(surface: Control) -> void:
	var idle_float := Settings.touch_floating_stick and _joystick_finger < 0
	draw_stick(surface, _joystick_center, _joystick_radius, _joystick_offset, 0.45 if idle_float else 1.0)
	for action: StringName in _buttons:
		var button: Dictionary = _buttons[action]
		draw_button(surface, button.at, button.r, button.text, _pressed.has(action), action == &"shoot")


## Analógico em `at` (também usado pelo editor de posição). `fade` apaga mais (flutuante parado).
func draw_stick(surface: Control, at: Vector2, radius: float, offset: Vector2, fade := 1.0) -> void:
	var unit := radius / 125.0
	var ring := _faded(Color(INK, 0.56), fade)
	var rim := _faded(Color(CREAM, 0.65), fade)
	surface.draw_circle(at, radius, ring)
	surface.draw_arc(at, radius, 0, TAU, 64, rim, 4.0 * unit, true)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var tip := at + direction * radius * 0.72
		var side := direction.orthogonal() * 12.0 * unit
		surface.draw_colored_polygon(PackedVector2Array([tip + direction * 13.0 * unit, tip - direction * 10.0 * unit + side, tip - direction * 10.0 * unit - side]), rim)
	surface.draw_circle(at + offset * 0.6, 52.0 * unit, _faded(Color(GOLD, 0.85), fade))


## Botão redondo com o nome (também usado pelo editor de posição).
func draw_button(surface: Control, at: Vector2, radius: float, text: String, pressed: bool, red := false) -> void:
	var unit := radius / 76.0
	var fill := Color("862f24") if red else INK
	fill.a = 0.8 if pressed else 0.58
	var rim := Color(CREAM, 0.65)
	surface.draw_circle(at, radius, _faded(fill))
	surface.draw_arc(at, radius, 0, TAU, 48, _faded(GOLD if pressed else rim), (5.0 if pressed else 3.0) * unit, true)
	var font := ThemeDB.fallback_font
	var font_size := int(27.0 * _scale * Settings.TOUCH_SIZES[Settings.touch_size_index])
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	surface.draw_string(font, at + Vector2(-width * 0.5, 10.0 * unit), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _faded(CREAM))


## Cor com a transparência escolhida nas Configurações.
func _faded(color: Color, fade := 1.0) -> Color:
	return Color(color, clampf(color.a * Settings.TOUCH_OPACITIES[Settings.touch_opacity_index] * fade, 0.0, 1.0))
