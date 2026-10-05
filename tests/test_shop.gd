extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_shop.tscn
## Loja e Camarim: comprar, regras (já tem, sem ingressos), doar ingressos, equipar, abrir a
## Barraca pelo mapa (o personagem fica parado) e o Camarim no menu de pausa.

var failures := 0
var _last := []


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_shop.json"
	SaveGame.reset()
	Shop.done.connect(func(operation: String, ok: bool, message: String) -> void: _last = [operation, ok, message])
	check(Catalog.items().size() == 17, "catalog has the 17 items (%d)" % Catalog.items().size())
	check(Catalog.ids_for_slot("gun")[0] == "cork_gun", "starting gun first on the shelf")
	SaveGame.data.players.clown.tickets = 10

	Shop.buy("clown", "confetti_fan")
	check(_last == ["buy", true, ""] and Shop.owns("clown", "confetti_fan") and Shop.tickets("clown") == 6, "buy an item")
	Shop.buy("clown", "confetti_fan")
	check(_last == ["buy", false, "ja_tem"], "cannot buy twice")
	Shop.buy("clown", "catapult")
	Shop.buy("clown", "lucky_clover")
	check(_last == ["buy", false, "sem_ingressos"] and Shop.tickets("clown") == 2, "not enough tickets")
	Shop.gift("clown", 2)
	check(Shop.tickets("clown") == 0 and Shop.tickets("acrobat") == 2, "gift tickets to the partner")
	Shop.gift("clown", 1)
	check(_last[1] == false, "cannot gift more than you have")

	Shop.equip("clown", "gun", "confetti_fan")
	check(Shop.equipped("clown", "gun") == "confetti_fan", "equip the new gun")
	Shop.equip("clown", "duo", "catapult")
	check(Shop.equipped("clown", "duo") == "catapult", "equip a duo number")
	Shop.equip("clown", "duo", "")
	check(Shop.equipped("clown", "duo") == "", "duo slot can be empty")
	Shop.equip("clown", "gun", "")
	check(_last[1] == false and Shop.equipped("clown", "gun") == "confetti_fan", "gun slot cannot be empty")
	Shop.equip("clown", "prop", "mime_gloves")
	check(_last[1] == false, "cannot equip an item you do not own")
	SaveGame.load_game()
	check(Shop.owns("clown", "confetti_fan") and Shop.equipped("clown", "gun") == "confetti_fan", "purchases saved")

	# Barraca no mapa.
	get_tree().change_scene_to_file(Levels.MAP)
	await frames(20)
	var map := get_tree().current_scene
	var clown: WorldWalker = map.get_node("PlayerSpawner/Player_1")
	var door: WorldDoor = map.get_node("DoorShop")
	check(door.is_open(), "shop tent is open")
	door.try_enter(clown)
	await frames(2)
	var panel := get_tree().get_first_node_in_group(&"blocking_ui") as ShopPanel
	check(panel != null and panel.key == "clown", "shop panel opens for the clown")
	var x := clown.global_position.x
	Input.action_press(&"move_right")
	await frames(30)
	Input.action_release(&"move_right")
	check(absf(clown.global_position.x - x) < 0.05, "player frozen while shopping")
	panel.close()
	await frames(2)
	check(get_tree().get_first_node_in_group(&"blocking_ui") == null, "shop closes")

	# Camarim na pausa (só no mapa).
	PauseMenu.open()
	check(PauseMenu._dressing_button.visible, "Camarim button on the map")
	PauseMenu._open_dressing_room()
	await frames(3)
	var choices := PauseMenu._dressing_room.find_children("*", "OptionButton", true, false)
	check(choices.size() == 8, "4 slots for each of the 2 players (%d)" % choices.size())
	PauseMenu._dressing_room.close()
	await frames(2)
	check(not PauseMenu.is_open(), "Voltar in the Camarim goes straight back to the map")
	# Pela tenda do Camarim: o botão Voltar de verdade fecha tudo.
	var tent: WorldDoor = get_tree().current_scene.get_node_or_null("DoorDressing")
	if tent != null:
		tent.try_enter()
		await frames(3)
		check(PauseMenu.is_open() and PauseMenu._dressing_room.visible, "Camarim tent opens the Camarim")
		var back_buttons := PauseMenu._dressing_room.find_children("*", "Button", true, false).filter(
				func(b: Button) -> bool: return b.text == "Voltar")
		if not back_buttons.is_empty():
			(back_buttons[0] as Button).pressed.emit()
		await frames(3)
		check(not PauseMenu.is_open() and not get_tree().paused, "tent Camarim: Voltar returns to the map")
	else:
		check(false, "Camarim tent on the map")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))

	print("FAILURES: ", failures)
	get_tree().quit(failures)
