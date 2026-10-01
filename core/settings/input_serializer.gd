class_name InputSerializer
## Converte teclas/botões em dados simples para salvar, e gera o nome que aparece no menu.

const KEY_NAMES := {
	KEY_LEFT: "Seta ←", KEY_RIGHT: "Seta →", KEY_UP: "Seta ↑", KEY_DOWN: "Seta ↓",
	KEY_SPACE: "Espaço", KEY_ENTER: "Enter", KEY_BACKSPACE: "Backspace",
	KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_CAPSLOCK: "Caps Lock",
}
const JOYPAD_BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Select", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Direcional ↑", JOY_BUTTON_DPAD_DOWN: "Direcional ↓",
	JOY_BUTTON_DPAD_LEFT: "Direcional ←", JOY_BUTTON_DPAD_RIGHT: "Direcional →",
}
const JOYPAD_AXIS_NAMES := {
	JOY_AXIS_LEFT_X: ["Analógico E ←", "Analógico E →"],
	JOY_AXIS_LEFT_Y: ["Analógico E ↑", "Analógico E ↓"],
	JOY_AXIS_RIGHT_X: ["Analógico D ←", "Analógico D →"],
	JOY_AXIS_RIGHT_Y: ["Analógico D ↑", "Analógico D ↓"],
	JOY_AXIS_TRIGGER_LEFT: ["LT", "LT"],
	JOY_AXIS_TRIGGER_RIGHT: ["RT", "RT"],
}


static func to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "code": event.physical_keycode}
	if event is InputEventJoypadButton:
		return {"type": "button", "index": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "axis", "axis": event.axis, "value": signf(event.axis_value)}
	return {}


static func from_dict(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = data["code"]
			key.device = -1
			return key
		"button":
			var button := InputEventJoypadButton.new()
			button.button_index = data["index"]
			button.device = -1
			return button
		"axis":
			var motion := InputEventJoypadMotion.new()
			motion.axis = data["axis"]
			motion.axis_value = data["value"]
			motion.device = -1
			return motion
	return null


## Cópia "limpa" de um evento capturado no menu, valendo para qualquer controle.
static func normalized(event: InputEvent) -> InputEvent:
	return from_dict(to_dict(event))


static func display_name(event: InputEvent) -> String:
	if event == null:
		return "—"
	if event is InputEventKey:
		var keycode := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		return KEY_NAMES.get(keycode, OS.get_keycode_string(keycode))
	if event is InputEventJoypadButton:
		return JOYPAD_BUTTON_NAMES.get(event.button_index, "Botão %d" % event.button_index)
	if event is InputEventJoypadMotion:
		var names: Array = JOYPAD_AXIS_NAMES.get(event.axis, ["Eixo %d -" % event.axis, "Eixo %d +" % event.axis])
		return names[1] if event.axis_value > 0.0 else names[0]
	return "?"
