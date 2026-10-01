extends Node
## Configurações do jogador (controles e vídeo), salvas em user://settings.cfg.
## Fica carregado o jogo todo (autoload "Settings").

signal changed

enum Quality { LOW, MEDIUM, HIGH }
enum WindowMode { WINDOWED, BORDERLESS, FULLSCREEN }

const PATH := "user://settings.cfg"

## Ações que o jogador pode trocar de tecla, na ordem em que aparecem no menu.
const REBINDABLE_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"jump", &"shoot", &"dash", &"lock_aim",
]
const ACTION_NAMES := {
	&"move_left": "Esquerda",
	&"move_right": "Direita",
	&"move_up": "Cima / mirar para cima",
	&"move_down": "Baixo / mirar para baixo",
	&"jump": "Pular",
	&"shoot": "Atirar",
	&"dash": "Dash",
	&"lock_aim": "Travar mira",
}
## Cada ação tem 2 espaços para teclado e 2 para controle.
const KEYBOARD_SLOTS: Array[int] = [0, 1]
const JOYPAD_SLOTS: Array[int] = [2, 3]
const SLOT_COUNT := 4

const QUALITY_NAMES := ["Baixa", "Média", "Alta"]
const WINDOW_MODE_NAMES := ["Janela", "Tela cheia (sem borda)", "Tela cheia (exclusiva)"]
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const FPS_LIMITS: Array[int] = [30, 60, 120, 144, 0]

var quality := Quality.HIGH
var window_mode := WindowMode.WINDOWED
var window_size_index := 0
var vsync := true
var fps_limit_index := 4
var show_fps := false
## Teclado: a tecla de "cima" também pula (travando a mira, ela mira para cima).
var up_jumps := true

## action -> Array de SLOT_COUNT eventos (ou null).
var _bindings := {}
var _default_bindings := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_default_bindings = _read_bindings_from_input_map()
	_bindings = _duplicate_bindings(_default_bindings)
	_load()
	_apply_bindings()
	apply_video()


# --- Controles -------------------------------------------------------------

func get_binding(action: StringName, slot: int) -> InputEvent:
	return _bindings[action][slot]


## Troca a tecla de um espaço. Se a tecla já era usada em outra ação, ela sai de lá.
func set_binding(action: StringName, slot: int, event: InputEvent) -> void:
	if event != null:
		for other_action in REBINDABLE_ACTIONS:
			for other_slot in SLOT_COUNT:
				var existing: InputEvent = _bindings[other_action][other_slot]
				if existing != null and _same_input(existing, event):
					_bindings[other_action][other_slot] = null
	_bindings[action][slot] = event
	_apply_bindings()
	_save()
	changed.emit()


func reset_bindings() -> void:
	_bindings = _duplicate_bindings(_default_bindings)
	_apply_bindings()
	_save()
	changed.emit()


static func is_keyboard_slot(slot: int) -> bool:
	return slot in KEYBOARD_SLOTS


func _read_bindings_from_input_map() -> Dictionary:
	var result := {}
	for action in REBINDABLE_ACTIONS:
		var slots: Array = []
		slots.resize(SLOT_COUNT)
		var keyboard_index := 0
		var joypad_index := 0
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and keyboard_index < KEYBOARD_SLOTS.size():
				slots[KEYBOARD_SLOTS[keyboard_index]] = event
				keyboard_index += 1
			elif (event is InputEventJoypadButton or event is InputEventJoypadMotion) \
					and joypad_index < JOYPAD_SLOTS.size():
				slots[JOYPAD_SLOTS[joypad_index]] = event
				joypad_index += 1
		result[action] = slots
	return result


func _apply_bindings() -> void:
	for action in REBINDABLE_ACTIONS:
		InputMap.action_erase_events(action)
		for event in _bindings[action]:
			if event != null:
				InputMap.action_add_event(action, event)


static func _duplicate_bindings(source: Dictionary) -> Dictionary:
	var copy := {}
	for action in source:
		copy[action] = source[action].duplicate()
	return copy


static func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


# --- Vídeo -----------------------------------------------------------------

func set_option(property: StringName, value: Variant) -> void:
	set(property, value)
	apply_video()
	_save()
	changed.emit()


func apply_video() -> void:
	var window := get_window()
	match window_mode:
		WindowMode.WINDOWED:
			window.mode = Window.MODE_WINDOWED
			window.size = WINDOW_SIZES[window_size_index]
			window.move_to_center()
		WindowMode.BORDERLESS:
			window.mode = Window.MODE_FULLSCREEN
		WindowMode.FULLSCREEN:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS_LIMITS[fps_limit_index]


# --- Arquivo ---------------------------------------------------------------

func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("video", "quality", quality)
	file.set_value("video", "window_mode", window_mode)
	file.set_value("video", "window_size_index", window_size_index)
	file.set_value("video", "vsync", vsync)
	file.set_value("video", "fps_limit_index", fps_limit_index)
	file.set_value("video", "show_fps", show_fps)
	file.set_value("controls", "up_jumps", up_jumps)
	for action in REBINDABLE_ACTIONS:
		var saved: Array = []
		for event in _bindings[action]:
			saved.append(InputSerializer.to_dict(event))
		file.set_value("controls", action, saved)
	file.save(PATH)


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	quality = clampi(file.get_value("video", "quality", quality), 0, QUALITY_NAMES.size() - 1)
	window_mode = clampi(file.get_value("video", "window_mode", window_mode), 0, WINDOW_MODE_NAMES.size() - 1)
	window_size_index = clampi(file.get_value("video", "window_size_index", window_size_index), 0, WINDOW_SIZES.size() - 1)
	vsync = file.get_value("video", "vsync", vsync)
	fps_limit_index = clampi(file.get_value("video", "fps_limit_index", fps_limit_index), 0, FPS_LIMITS.size() - 1)
	show_fps = file.get_value("video", "show_fps", show_fps)
	up_jumps = file.get_value("controls", "up_jumps", up_jumps)
	for action in REBINDABLE_ACTIONS:
		var saved: Array = file.get_value("controls", action, [])
		if saved.size() != SLOT_COUNT:
			continue
		for slot in SLOT_COUNT:
			_bindings[action][slot] = InputSerializer.from_dict(saved[slot])
