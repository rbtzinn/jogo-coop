extends Node
## Rodar: Godot --headless --path . res://tests/test_touch_settings.tscn
## Ajustes do celular: tamanho, transparência, tiro automático desligado (botão TIRO), analógico flutuante,
## editor de posição (arrastar, salvar, ficar dentro da tela, restaurar) e as opções salvas no arquivo.

var failures := 0
var controls: CanvasLayer
var input: PlayerInput
var _saved := {}

const OPTIONS := [&"touch_floating_stick", &"touch_size_index", &"touch_opacity_index", &"touch_auto_shoot",
	&"touch_vibration", &"touch_layout"]


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func touch(finger: int, at: Vector2, pressed := true) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.position = at
	event.pressed = pressed
	controls._input(event)


func drag(finger: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = finger
	event.position = at
	controls._input(event)


func _ready() -> void:
	get_tree().create_timer(90.0, true, false, true).timeout.connect(func() -> void: get_tree().quit(99))
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	for option in OPTIONS:
		_saved[option] = Settings.get(option)
	Settings.set_touch_layout({})
	Settings.set_option(&"touch_size_index", 1)
	Settings.set_option(&"touch_opacity_index", 1)
	Settings.set_option(&"touch_auto_shoot", true)
	Settings.set_option(&"touch_floating_stick", 0)
	var fixture := Node.new()
	fixture.add_to_group(&"players")
	tree.root.add_child(fixture)
	tree.current_scene = fixture
	input = PlayerInput.new()
	add_child(input)
	controls = MobileControls
	controls.enable()
	await frames(3)
	check(controls._active, "touch controls appear during gameplay")
	await _size_and_opacity()
	await _manual_shooting()
	await _floating_stick()
	await _editor()
	_saved_file()
	for option in OPTIONS:
		Settings.set(option, _saved[option])
	Settings.set_touch_layout(_saved[&"touch_layout"])
	fixture.queue_free()
	print("FAILURES: ", failures)
	tree.quit(failures)


func _size_and_opacity() -> void:
	var normal: float = controls._buttons[&"jump"].r
	var stick: float = controls._joystick_radius
	Settings.set_option(&"touch_size_index", 3)
	check(controls._buttons[&"jump"].r > normal * 1.3 and controls._joystick_radius > stick * 1.3, "Enorme makes buttons and stick bigger")
	var big_jump: Dictionary = controls._buttons[&"jump"]
	var big_dash: Dictionary = controls._buttons[&"dash"]
	check(big_jump.at.distance_to(big_dash.at) > big_jump.r + big_dash.r, "bigger buttons do not overlap")
	Settings.set_option(&"touch_size_index", 0)
	check(controls._buttons[&"jump"].r < normal, "Pequeno makes buttons smaller")
	Settings.set_option(&"touch_size_index", 1)
	var base: float = controls._faded(Color(1, 1, 1, 0.6)).a
	Settings.set_option(&"touch_opacity_index", 0)
	check(controls._faded(Color(1, 1, 1, 0.6)).a < base, "Leve makes controls more see-through")
	Settings.set_option(&"touch_opacity_index", 2)
	check(controls._faded(Color(1, 1, 1, 0.6)).a > base, "Forte makes controls more solid")
	Settings.set_option(&"touch_opacity_index", 1)


func _manual_shooting() -> void:
	input.update()
	check(input.shoot_held and not controls._buttons.has(&"shoot"), "auto shooting on: fires alone, no TIRO button")
	Settings.set_option(&"touch_auto_shoot", false)
	input.update()
	check(not input.shoot_held and controls._buttons.has(&"shoot") and controls._buttons[&"shoot"].text == "TIRO", "auto shooting off: TIRO button appears and nothing fires alone")
	var tiro: Vector2 = controls._buttons[&"shoot"].at
	for key: StringName in controls._buttons:
		if key != &"shoot":
			var other: Dictionary = controls._buttons[key]
			check(tiro.distance_to(other.at) > controls._buttons[&"shoot"].r + other.r, "TIRO does not cover " + String(key))
	touch(4, tiro)
	input.update()
	check(input.shoot_held, "holding TIRO shoots")
	touch(4, tiro, false)
	input.update()
	check(not input.shoot_held, "releasing TIRO stops")
	Settings.set_option(&"touch_auto_shoot", true)


func _floating_stick() -> void:
	var home: Vector2 = controls._joystick_center
	Settings.set_option(&"touch_floating_stick", 1)
	check(Settings.touch_floating_stick == true, "Fixo/Flutuante list saves a real on/off")
	var spot := Vector2(700, 400)
	touch(0, spot)
	check(controls._joystick_finger == 0 and controls._joystick_center == spot, "floating stick is born where the finger touches")
	drag(0, spot + Vector2(controls._joystick_radius, 0))
	input.update()
	check(input.get_horizontal() == 1, "dragging from that point moves")
	touch(0, spot, false)
	input.update()
	check(controls._joystick_center == home and input.get_horizontal() == 0, "releasing returns the stick and stops")
	touch(1, Vector2(1400, 500))
	check(controls._joystick_finger < 0, "right half never grabs the floating stick")
	touch(1, Vector2(1400, 500), false)
	touch(2, controls._buttons[&"pause"].at + Vector2(0, 0))
	check(controls._joystick_finger < 0, "buttons still win over the floating stick")
	controls.release_all()
	PauseMenu.close()
	await frames(2)
	Settings.set_option(&"touch_floating_stick", 0)
	touch(0, spot)
	check(controls._joystick_finger < 0, "fixed stick ignores touches far from it")
	touch(0, spot, false)


func _editor() -> void:
	var editor := TouchLayoutEditor.open(self)
	await get_tree().process_frame
	var target := Vector2(900, 600)
	editor.drag_to(&"jump", target)
	editor.drag_to(&"joystick", Vector2(-500, 2000))
	var stick_at := editor.position_of(&"joystick")
	var view := get_viewport().get_visible_rect().size
	check(stick_at.x >= controls._joystick_radius - 0.5 and stick_at.y <= view.y - controls._joystick_radius + 0.5, "dragging past the edge keeps the stick inside the screen")
	# Arrastar de verdade com um dedo: encosta no PULAR, move e solta.
	editor._press(3, target, true)
	editor._move(3, target + Vector2(40, -30))
	editor._press(3, target + Vector2(40, -30), false)
	var closed := [false]
	editor.closed.connect(func() -> void: closed[0] = true)
	editor.finish()
	await get_tree().process_frame
	check(closed[0] and Settings.touch_layout.has("jump"), "Pronto saves the positions")
	check(controls._buttons[&"jump"].at.distance_to(target + Vector2(40, -30)) < 1.0, "the game uses the new jump position")
	check(controls._joystick_home.distance_to(stick_at) < 1.0, "the game uses the new stick position")
	var reset := TouchLayoutEditor.open(self)
	await get_tree().process_frame
	reset.reset()
	reset.finish()
	await get_tree().process_frame
	check(controls._buttons[&"jump"].at.distance_to(target + Vector2(40, -30)) > 50.0, "Restaurar padrão puts the buttons back")


func _saved_file() -> void:
	Settings.set_option(&"touch_size_index", 2)
	Settings.set_option(&"touch_vibration", false)
	Settings.set_touch_layout({"dash": Vector2(0.5, 0.5)})
	var file := ConfigFile.new()
	file.load(Settings.PATH)
	var layout: Dictionary = file.get_value("touch", "layout", {})
	check(file.get_value("touch", "size_index", -1) == 2 and file.get_value("touch", "vibration", true) == false
		and layout.get("dash") == Vector2(0.5, 0.5), "touch options survive closing the game")
