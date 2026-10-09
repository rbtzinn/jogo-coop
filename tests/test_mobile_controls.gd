extends Node

var failures := 0
var controls: CanvasLayer


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


func _ready() -> void:
	get_tree().create_timer(90.0, true, false, true).timeout.connect(func() -> void: get_tree().quit(99))
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	var fixture := Node.new()
	fixture.add_to_group(&"players")
	tree.root.add_child(fixture)
	tree.current_scene = fixture
	var input := PlayerInput.new()
	add_child(input)
	input.update()
	check(not input.shoot_held, "desktop input keeps manual shooting")
	controls = MobileControls
	controls.enable()
	await frames(3)
	input.update()
	check(controls._active, "touch controls appear during gameplay")
	check(input.shoot_held and not Input.is_action_pressed("shoot"), "mobile combat fires without holding a global action")
	check(not controls._buttons.has(&"shoot"), "combat has no shooting button")
	var right: Vector2 = controls._joystick_center + Vector2(controls._joystick_radius, 0)
	var jump: Vector2 = controls._buttons[&"jump"].at
	touch(0, right)
	touch(2, jump)
	input.update()
	check(input.get_horizontal() == 1 and input.shoot_held and input.jump_held, "two fingers move and jump while firing automatically")
	touch(2, jump, false)
	input.update()
	check(not input.jump_held and input.shoot_held and input.get_horizontal() == 1, "releasing jump keeps movement and shooting held")
	touch(2, jump)
	touch(3, jump)
	touch(2, jump, false)
	check(Input.is_action_pressed("jump"), "second finger continues holding the same action")
	touch(3, jump, false)
	check(not Input.is_action_pressed("jump"), "last finger releases jumping")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = controls._joystick_center + Vector2(-controls._joystick_radius, -controls._joystick_radius)
	controls._input(drag)
	input.update()
	check(input.get_horizontal() == -1 and input.get_vertical() == -1, "dragging the joystick changes direction and aims diagonally")
	touch(0, right, false)
	check(Input.get_vector("move_left", "move_right", "move_up", "move_down") == Vector2.ZERO, "lifting the joystick stops movement")
	touch(4, jump)
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	input.update()
	check(not input.shoot_held and not Input.is_action_pressed("jump"), "switching away stops autofire and releases touches")
	await frames(3)
	input.update()
	check(not input.shoot_held, "autofire stays stopped while unfocused")
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await frames(2)
	input.update()
	check(input.shoot_held, "returning resumes automatic shooting")
	controls._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	input.update()
	check(not input.shoot_held, "backgrounding stops automatic shooting")
	controls._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var blocker := Node.new()
	blocker.add_to_group(&"blocking_ui")
	fixture.add_child(blocker)
	await frames(2)
	input.update()
	check(not controls._active and not input.shoot_held, "modal interface hides controls and stops shooting")
	blocker.queue_free()
	await frames(2)
	touch(4, jump)
	touch(5, controls._buttons[&"pause"].at)
	await frames(2)
	input.update()
	check(PauseMenu.is_open() and not input.shoot_held and not controls._active, "touch pause stops autofire and releases actions")
	PauseMenu.close()
	await frames(2)
	check(controls._active, "continuing restores touch controls")
	input.local_control = false
	input.update()
	check(not input.shoot_held, "remote players do not inherit mobile autofire")
	input.local_control = true
	input.up_can_jump = false
	input.update()
	check(not input.shoot_held, "world walkers do not automatically enter doors")
	input.up_can_jump = true
	fixture.queue_free()
	SaveGame.path = "user://test_save_mobile.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = 0
	tree.change_scene_to_file(Levels.MAP)
	await frames(25)
	check(controls._map_mode and controls._buttons.has(&"swap") and not controls._buttons.has(&"jump"), "map exposes entering and character switching")
	input.update()
	check(not input.shoot_held, "map does not fire or enter automatically")
	var enter: Vector2 = controls._buttons[&"shoot"].at
	touch(1, enter)
	input.update()
	check(input.shoot_held and input.shoot_pressed, "entering still requires a deliberate touch")
	touch(1, enter, false)
	touch(0, controls._buttons[&"swap"].at)
	await frames(4)
	var walkers := tree.get_nodes_in_group(&"walkers")
	check(walkers.size() == 1 and walkers[0].name == "Player_2", "touch changes the solo character on the real map")
	tree.change_scene_to_file("res://bosses/tamer/tamer_fight.tscn")
	await frames(25)
	check(not controls._map_mode and controls._buttons.has(&"jump"), "fight restores combat buttons")
	await frames(4)
	var players := tree.get_nodes_in_group(&"players")
	check(players.size() == 1 and players[0].input.shoot_held, "the real character receives automatic shooting")
	var shot_count := 0
	for child in tree.current_scene.get_children():
		if child is Projectile and child.origin_player == players[0]:
			shot_count += 1
	check(shot_count > 0, "automatic shooting creates real projectiles without a touch")
	tree.change_scene_to_file(Levels.MENU)
	await frames(8)
	check(not controls._active and not Input.is_action_pressed("shoot"), "returning to the menu releases inputs and hides controls")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save_mobile.json"))
	print("FAILURES: ", failures)
	tree.quit(failures)
