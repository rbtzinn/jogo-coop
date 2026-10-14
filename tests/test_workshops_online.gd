extends Node
## Voo escolhido pelo cliente, chegada, save e volta; saves isolados.
const PORT := 24713
var role := ""
var failures := 0
var _arrived := {}

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not "host" in args and not "client" in args:
		get_tree().quit()
		return
	role = "host" if "host" in args else "client"
	if "ruim" in args:
		Network.simulation_index = 3
	_move.call_deferred()

func _move() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()

func check(ok: bool, label: String) -> void:
	print("[%s] %s %s" % [role, "OK" if ok else "FAIL", label])
	if not ok:
		failures += 1

func wait(seconds := 0.2) -> void:
	await get_tree().create_timer(seconds).timeout

func until(condition: Callable) -> bool:
	for i in 100:
		if condition.call():
			return true
		await wait()
	return false

func scene_is(path: String) -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == path

@rpc("any_peer", "call_remote", "reliable")
func _arrive(tag: String) -> void:
	_arrived[tag] = true

func meet(tag: String) -> void:
	for i in 100:
		for id in multiplayer.get_peers():
			_arrive.rpc_id(id, tag)
		if _arrived.has(tag):
			await wait(0.5)
			return
		await wait()
	check(false, "checkpoint " + tag)

func _run() -> void:
	get_tree().create_timer(100.0).timeout.connect(func() -> void: get_tree().quit(99))
	SaveGame.path = "user://test_workshops_online_%s.json" % role
	SaveGame.reset()
	if role == "host":
		check(Network.host(PORT) == OK, "host started")
		get_tree().change_scene_to_file(Levels.TRAVEL)
	else:
		await wait(0.8)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "client joining")
		await Network.joined
	if not await until(func() -> bool: return scene_is(Levels.TRAVEL) and not multiplayer.get_peers().is_empty()):
		get_tree().quit(1)
		return
	await meet("flight")
	get_tree().current_scene._end_flight()
	await meet("menu")
	if role == "client":
		get_tree().current_scene._choose(3)
	check(await until(func() -> bool: return scene_is(Levels.MAPS[3]) and not Network.ready_peers.is_empty()), "client-selected flight reaches workshops")
	var map: PaintedWorld = get_tree().current_scene
	var plane: WorldDoor = map.get_node("DoorPlane")
	check(int(SaveGame.data.area) == 3, "area 3 on both saves")
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		if walker.is_multiplayer_authority():
			check(map.is_walkable(walker.global_position), "local arrival on path")
			check(walker.global_position.distance_to(plane.front_point()) < 3, "local arrival at plane")
	await meet("arrival")
	# Ambos estão na zona do avião; o host leva a dupla de volta ao voo.
	if role == "host":
		plane.try_enter()
	check(await until(func() -> bool: return scene_is(Levels.TRAVEL)), "both return to flight")
	get_tree().current_scene._end_flight()
	await meet("return_menu")
	if role == "host":
		get_tree().current_scene._choose(2)
	check(await until(func() -> bool: return scene_is(Levels.MAPS[2]) and not Network.ready_peers.is_empty()), "both return to Volcano")
	check(int(SaveGame.data.area) == 2, "return destination saved on both PCs")
	await meet("done")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("[%s] FAILURES: %d" % [role, failures])
	get_tree().quit(failures)
