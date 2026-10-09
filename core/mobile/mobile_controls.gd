extends CanvasLayer
## Multitoque para o mesmo InputMap usado no PC. Não altera os comandos da rede.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const ACTIONS: Array[StringName] = [&"jump", &"shoot", &"dash", &"lock_aim", &"special"]
const INK := Color("1b1410")
const CREAM := Color("ffe2ac")
const GOLD := Color("e1b65c")

class Surface extends Control:
	var controls: Node

	func _draw() -> void:
		controls.draw_surface(self)

var force_enabled := false
var _surface: Surface
var _active := false
var _map_mode := false
var _scene: Node
var _joystick_finger := -1
var _joystick_center := Vector2.ZERO
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
	if not force_enabled and not OS.has_feature("mobile"):
		set_process(false)
		set_process_input(false)
		return
	_surface = Surface.new()
	_surface.controls = self
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_surface)
	_surface.hide()
	get_viewport().size_changed.connect(_layout)
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


func _can_control() -> bool:
	return get_tree().current_scene != null and not get_tree().paused \
			and not PauseMenu.is_open() \
			and get_tree().get_first_node_in_group(&"blocking_ui") == null \
			and (get_tree().get_first_node_in_group(&"players") != null \
			or get_tree().get_first_node_in_group(&"walkers") != null)


func _layout() -> void:
	if _surface == null:
		return
	release_all()
	_viewport_size = get_viewport().get_visible_rect().size
	_scale = minf(_viewport_size.x / 1920.0, _viewport_size.y / 1080.0)
	var w := _viewport_size.x
	var h := _viewport_size.y
	_joystick_radius = 125.0 * _scale
	_joystick_center = Vector2(220.0 * _scale, h - 210.0 * _scale)
	_buttons.clear()
	_buttons[&"pause"] = {"at": Vector2(w - 110.0 * _scale, 90.0 * _scale), "r": 65.0 * _scale, "text": "PAUSA"}
	_buttons[&"shoot"] = {"at": Vector2(w - 150.0 * _scale, h - 280.0 * _scale), "r": 76.0 * _scale, "text": "ENTRAR" if _map_mode else "TIRO"}
	if _map_mode:
		if not Network.is_online():
			_buttons[&"swap"] = {"at": Vector2(w - 310.0 * _scale, h - 130.0 * _scale), "r": 76.0 * _scale, "text": "TROCAR"}
	else:
		_buttons[&"jump"] = {"at": Vector2(w - 320.0 * _scale, h - 125.0 * _scale), "r": 76.0 * _scale, "text": "PULAR"}
		_buttons[&"dash"] = {"at": Vector2(w - 150.0 * _scale, h - 110.0 * _scale), "r": 65.0 * _scale, "text": "DASH"}
		_buttons[&"special"] = {"at": Vector2(w - 490.0 * _scale, h - 125.0 * _scale), "r": 65.0 * _scale, "text": "EX"}
		_buttons[&"lock_aim"] = {"at": Vector2(w - 330.0 * _scale, h - 310.0 * _scale), "r": 65.0 * _scale, "text": "MIRA"}


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
	if _joystick_finger < 0 and at.distance_to(_joystick_center) <= _joystick_radius * 1.45:
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


func _touch_up(finger: int) -> void:
	if finger == _joystick_finger:
		_joystick_finger = -1
		_joystick_offset = Vector2.ZERO
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_all()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and _surface != null:
		release_all()
		if PauseMenu.is_open():
			PauseMenu.close()
		elif _can_control():
			PauseMenu.open()


func _exit_tree() -> void:
	release_all()


func draw_surface(surface: Control) -> void:
	var font := ThemeDB.fallback_font
	var ring := Color(INK, 0.56)
	var rim := Color(CREAM, 0.65)
	surface.draw_circle(_joystick_center, _joystick_radius, ring)
	surface.draw_arc(_joystick_center, _joystick_radius, 0, TAU, 64, rim, 4.0 * _scale, true)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var at := _joystick_center + direction * _joystick_radius * 0.72
		var side := direction.orthogonal() * 12.0 * _scale
		surface.draw_colored_polygon(PackedVector2Array([at + direction * 13.0 * _scale, at - direction * 10.0 * _scale + side, at - direction * 10.0 * _scale - side]), rim)
	surface.draw_circle(_joystick_center + _joystick_offset * 0.6, 52.0 * _scale, Color(GOLD, 0.85))
	for action: StringName in _buttons:
		var button: Dictionary = _buttons[action]
		var pressed := _pressed.has(action)
		var fill := Color("862f24") if action == &"shoot" else INK
		fill.a = 0.8 if pressed else 0.58
		surface.draw_circle(button.at, button.r, fill)
		surface.draw_arc(button.at, button.r, 0, TAU, 48, GOLD if pressed else rim, (5.0 if pressed else 3.0) * _scale, true)
		var font_size := int(27.0 * _scale)
		var text: String = button.text
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		surface.draw_string(font, button.at + Vector2(-width * 0.5, 10.0 * _scale), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CREAM)
