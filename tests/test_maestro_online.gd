extends Node
## Rodar: TEST_SCENE=res://tests/test_maestro_online.tscn sh tests/run_online.sh [ruim]
## Maestro online: tiro do cliente, mesma partitura e trajetórias nos dois PCs, parry da nota turquesa
## compartilhado, combos, troca de fase, caixa de música da reverência e vitória salva nos dois.

const FIGHT := "res://bosses/rust_maestro/rust_maestro_fight.tscn"
const PORT := 24737
const TARGETS := [Vector2(27, 875), Vector2(1473, 605)]
const MaestroAttackScript := preload("res://bosses/rust_maestro/maestro_attack.gd")

var role := ""
var failures := 0
var _arrived := {}
var boss: RustMaestroBoss


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


func wait(seconds := 0.1) -> void:
	await get_tree().create_timer(seconds).timeout


func until(condition: Callable) -> bool:
	for i in 150:
		if condition.call():
			return true
		await wait()
	return false


@rpc("any_peer", "call_remote", "reliable")
func _arrive(tag: String) -> void:
	_arrived[tag] = true


func meet(tag: String) -> void:
	for i in 100:
		for peer in multiplayer.get_peers():
			_arrive.rpc_id(peer, tag)
		if _arrived.has(tag):
			await wait(0.35)
			return
		await wait()
	check(false, "checkpoint " + tag)


func _run() -> void:
	get_tree().create_timer(110.0).timeout.connect(func() -> void: get_tree().quit(99))
	SaveGame.path = "user://test_maestro_online_%s.json" % role
	SaveGame.reset()
	if role == "host":
		check(Network.host(PORT) == OK, "host starts")
		get_tree().change_scene_to_file(FIGHT)
	else:
		await wait(0.8)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "client connects")
		await Network.joined
	if not await until(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == FIGHT and not Network.ready_peers.is_empty()):
		check(false, "fight loaded on both peers")
		get_tree().quit(1)
		return
	boss = get_tree().current_scene.get_node("RustMaestroBoss")
	boss._wait = 99999
	boss.pause_between_attacks = Vector2(99999, 99999)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
		player.player_health._invincible_timer = 99999
	check(get_tree().get_nodes_in_group(&"players").size() == 2, "two network players spawned")
	await meet("loaded")
	if role == "client":
		boss.actor.hurtbox.take_hit(3, "online-client")
	check(await until(func() -> bool: return boss.health.current == 1247), "client shot damages host and health returns")
	await meet("damage")
	if role == "host":
		boss.sync.start_attack(&"Staff", 404, TARGETS)
	check(await until(func() -> bool: return boss._current != null and boss._current.run_seed == 404), "same attack seed delivered")
	var attack := boss._current
	check(attack.args == TARGETS, "both peers receive identical corner/air targets")
	print("[%s] score %s" % [role, str(attack.notes)])
	# Amostrar o mesmo instante prova a mesma partitura e trajetória, seja qual for o atraso.
	attack.set_physics_process(false)
	var parry_index := -1
	for i in attack.notes.size():
		if attack.notes[i][2]:
			parry_index = i
	var launch: float = attack.notes[parry_index][0] * RustMaestroBoss.BEAT
	attack.elapsed = launch + 0.5
	attack._on_tick(0.0)
	var parry: MaestroThreat = attack._props["note:%d" % parry_index]
	var expected := Vector2(MaestroAttackScript.SPAWN_X - 0.5 * MaestroAttackScript.SPEED, MaestroAttackScript.LANES[attack.notes[parry_index][1]])
	check(parry.position.distance_to(expected) < 0.05, "deterministic note trajectory matches host snapshot")
	check(parry.parry_id == "Maestro:Staff:404:note:%d" % parry_index, "same parry object identity on both peers")
	await meet("trajectory")
	if role == "client":
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.is_multiplayer_authority():
				player.parry._succeed(parry)
	check(await until(func() -> bool: return parry.popped and not parry.active), "client parry removes the same note on both peers")
	await meet("parry")
	var samples := {&"StaffWaves": [4.0, &"wave"], &"StaffEighths": [2.85, &"eighths"], &"BatonWaves": [4.0, &"crescent"]}
	for combo: StringName in samples:
		if role == "host":
			if combo == &"StaffEighths":
				boss.phase = 2
			boss.sync.start_attack(combo, 405, TARGETS)
		check(await until(func() -> bool: return boss._current != null and boss._current.name == combo), String(combo) + " reaches both peers")
		boss._current.set_physics_process(false)
		boss._current.elapsed = samples[combo][0]
		boss._current._on_tick(0)
		var live := 0
		var found := false
		for prop: MaestroThreat in boss._current._props.values():
			if prop.active:
				live += 1
				found = found or prop.kind == samples[combo][1]
		check(found and live >= 2, String(combo) + " synchronizes overlapping live hazards")
		await meet(String(combo))
		boss._current.set_physics_process(true)
	if role == "host":
		boss._current.cancel()
		boss.phase = 0
		boss.health.damage(422)
	check(await until(func() -> bool: return boss.phase == 1 and boss.actor.organ_awake), "Crescendo (organ awake) arrives on both peers")
	await meet("phase2")
	if role == "host":
		boss.health.damage(boss.health.current - boss.phase_end_health())
	check(await until(func() -> bool: return boss.phase == 2), "Fortíssimo arrives on both peers")
	await meet("phase3")
	if role == "host":
		boss.sync.start_attack(&"Eighths", 406, TARGETS)
	check(await until(func() -> bool: return boss._current != null and boss._current.run_seed == 406), "phase 3 attack reaches both peers")
	check(await until(func() -> bool: return boss.actor.chest_open), "bow opens the music box on both peers")
	var before := boss.health.current
	await meet("chest")
	if role == "client":
		boss.actor.chest.take_hit(3, "online-client")
	check(await until(func() -> bool: return boss.health.current <= before - 6), "client shot in the open music box counts double")
	await meet("bow")
	if role == "host":
		boss.apply_damage(boss.health.current)
	check(await until(func() -> bool: return boss.is_defeated and get_tree().current_scene.get_node("Fight")._ended), "victory synchronized")
	check(await until(func() -> bool: return SaveGame.is_defeated("rust_maestro")), "victory/save shared with client")
	await meet("finished")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("[%s] FAILURES: %d" % [role, failures])
	get_tree().quit(failures)
