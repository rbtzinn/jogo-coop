class_name ControlSign
extends Node2D
## Placa pendurada no varal do mapa com os controles, usando as teclas que o jogador configurou
## (ou os botões do controle, se houver um conectado). Os textos ficam em dialogues/tutorial.json;
## "{ação}" vira o nome da tecla. Atualiza quando as configurações mudam.

const TEXT_FILE := "res://dialogues/tutorial.json"
const SIZE := Vector2(620, 236)
const BOARD := Color("6e1c1b")
const ROPE := Color("8a6a4a")

var _title := ""
var _lines: Array[String] = []


func _ready() -> void:
	var file := FileAccess.open(TEXT_FILE, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text()) if file != null else {}
	_title = data.get("titulo", "")
	for line in data.get("linhas", []):
		_lines.append(line)
	Settings.changed.connect(queue_redraw)
	Input.joy_connection_changed.connect(func(_device: int, _connected: bool) -> void: queue_redraw())


func _draw() -> void:
	# Cordas até o varal e a placa de madeira pintada.
	draw_line(Vector2(40, -60), Vector2(40, 0), ROPE, 4.0)
	draw_line(Vector2(SIZE.x - 40, -60), Vector2(SIZE.x - 40, 0), ROPE, 4.0)
	var board := Rect2(Vector2.ZERO, SIZE)
	draw_rect(board, BOARD)
	draw_rect(board.grow(-8), UiTheme.GOLD, false, 2.0)
	draw_rect(board, UiTheme.INK, false, 5.0)
	var title_size := UiTheme.TITLE_FONT.get_string_size(_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(UiTheme.TITLE_FONT, Vector2((SIZE.x - title_size.x) * 0.5, 44), _title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UiTheme.GOLD)
	var joypad := not Input.get_connected_joypads().is_empty()
	for i in _lines.size():
		var text := _fill(_lines[i], joypad)
		draw_string(UiTheme.BODY_FONT, Vector2(26, 92 + i * 38), text, HORIZONTAL_ALIGNMENT_LEFT,
				SIZE.x - 52, 26, UiTheme.CREAM)


## Troca "{ação}" pelo nome da tecla (ou do botão do controle) configurada.
func _fill(line: String, joypad: bool) -> String:
	for action in Settings.REBINDABLE_ACTIONS:
		var key := "{%s}" % action
		if line.contains(key):
			line = line.replace(key, _key_name(action, joypad))
	return line


func _key_name(action: StringName, joypad: bool) -> String:
	var slots: Array[int] = Settings.JOYPAD_SLOTS if joypad else Settings.KEYBOARD_SLOTS
	for slot in slots:
		var event := Settings.get_binding(action, slot)
		if event != null:
			return InputSerializer.display_name(event)
	if action == &"jump" and Settings.up_jumps and not joypad:
		return _key_name(&"move_up", false)
	return "—"
