extends Node
const FIGHT := "res://bosses/madame_carretel/madame_carretel_fight.tscn"
const PORT := 24736
var role := ""
var failures := 0
var _arrived := {}
var boss: MadameCarretelBoss

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not "host" in args and not "client" in args:
		get_tree().quit()
		return
	role = "host" if "host" in args else "client"
	if "ruim" in args: Network.simulation_index = 3
	_move.call_deferred()

func _move() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()

func check(ok: bool,label: String) -> void:
	print("[%s] %s %s" % [role,"OK" if ok else "FAIL",label])
	if not ok: failures += 1

func wait(seconds := 0.1) -> void:
	await get_tree().create_timer(seconds).timeout

func until(condition: Callable) -> bool:
	for i in 150:
		if condition.call(): return true
		await wait()
	return false

@rpc("any_peer","call_remote","reliable")
func _arrive(tag: String) -> void:
	_arrived[tag] = true

func meet(tag: String) -> void:
	for i in 100:
		for peer in multiplayer.get_peers(): _arrive.rpc_id(peer,tag)
		if _arrived.has(tag):
			await wait(0.35)
			return
		await wait()
	check(false,"checkpoint "+tag)

func _run() -> void:
	get_tree().create_timer(95.0).timeout.connect(func() -> void: get_tree().quit(99))
	SaveGame.path = "user://test_carretel_online_%s.json" % role
	SaveGame.reset()
	if role=="host":
		check(Network.host(PORT)==OK,"host starts")
		get_tree().change_scene_to_file(FIGHT)
	else:
		await wait(0.8)
		check(Network.join("127.0.0.1:%d" % PORT)==OK,"client connects")
		await Network.joined
	if not await until(func() -> bool: return get_tree().current_scene!=null and get_tree().current_scene.scene_file_path==FIGHT and not Network.ready_peers.is_empty()):
		check(false,"fight loaded on both peers")
		get_tree().quit(1)
		return
	boss = get_tree().current_scene.get_node("MadameCarretelBoss")
	boss._wait = 99999
	boss.pause_between_attacks = Vector2(99999,99999)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
		player.player_health._invincible_timer = 99999
	check(get_tree().get_nodes_in_group(&"players").size()==2,"two network players spawned")
	await meet("loaded")
	if role=="client":
		boss.actor.hurtbox.take_hit(3,"online-client")
	check(await until(func() -> bool: return boss.health.current==1247),"client shot damages host and health returns")
	await meet("damage")
	if role=="host": boss.sync.start_attack(&"Needles",404,[Vector2(27,875),Vector2(1473,605)])
	check(await until(func() -> bool: return boss._current!=null and boss._current.run_seed==404),"same attack seed delivered")
	check(boss._current.args==[Vector2(27,875),Vector2(1473,605)],"both peers receive identical corner/air targets")
	# Amostrar a mesma hora prova a trajetória, independentemente do atraso da rede.
	boss._current.elapsed = 1.7
	boss._current._on_tick(0.0)
	var needle: CarretelThreat = boss._current._props["needle:0:0"]
	var origin := MadameCarretelBoss.HOME+Vector2(-275,-410)
	var expected := origin+origin.direction_to(Vector2(27,875))*0.8*640
	check(needle.position.distance_to(expected)<0.05,"deterministic trajectory matches host snapshot")
	var parry: CarretelThreat = boss._current._props["needle:0:1"]
	check(parry.parry_id=="Carretel:Needles:404:needle:0:1","same parry object identity on both peers")
	await meet("trajectory")
	if role=="client":
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.is_multiplayer_authority(): player.parry._succeed(parry)
	check(await until(func() -> bool: return parry.popped and not parry.active),"client parry removes same projectile on both peers")
	await meet("parry")
	for combo in [&"NeedlesTape",&"CurtainsNeedles",&"ButtonsScissors"]:
		if role=="host": boss.sync.start_attack(combo,405,[Vector2(27,875),Vector2(1473,605)])
		check(await until(func() -> bool: return boss._current!=null and boss._current.name==combo),String(combo)+" reaches both peers")
		# A barreira de rede não deve consumir a vida do projétil amostrado.
		boss._current.set_physics_process(false)
		boss._current.elapsed = 2.4
		boss._current._on_tick(0)
		var expected_kind: StringName = &"cut" if combo==&"ButtonsScissors" else &"needle_parry"
		var live := 0
		var found := false
		for prop: CarretelThreat in boss._current._props.values():
			if prop.active:
				live += 1
				found = found or prop.kind==expected_kind
		check(found and live>=3,String(combo)+" synchronizes overlapping live hazards")
		if combo==&"NeedlesTape":
			var combo_parry: CarretelThreat = boss._current._props["needle:0:1"]
			check(combo_parry.parry_id=="Carretel:NeedlesTape:405:needle:0:1","combo parry keeps identical identity")
			await meet("combo_parry_ready")
			if role=="client":
				for player: Player in get_tree().get_nodes_in_group(&"players"):
					if player.is_multiplayer_authority():
						player.set_physics_process(false)
						player.position = combo_parry.global_position+Vector2(0,85)
						player.input.scripted = true
						player._dash_timer = player.dash_duration*0.5
						player._coyote_timer = 0
						player.parry._available = true
						await get_tree().physics_frame
						await get_tree().physics_frame
						player.input.jump_pressed = true
						player._physics_process(1.0/60.0)
						player.input.jump_pressed = false
						check(combo_parry.popped and not player.is_dashing() and player.velocity.y<0,"client jump input parries mid-dash and bounces")
						player.input.scripted = false
						player.set_physics_process(true)
			check(await until(func() -> bool: return combo_parry.popped),"combo parry is shared while floor wave continues")
		await meet(String(combo))
	if role=="host": boss.health.damage(422)
	check(await until(func() -> bool: return boss.phase==1),"phase 2 arrives on both peers")
	await meet("phase2")
	if role=="host": boss.health.damage(boss.health.current-boss.phase_end_health())
	check(await until(func() -> bool: return boss.phase==2 and boss.actor.armored),"phase 3 transformation synchronized")
	await meet("phase3")
	if role=="host": boss.apply_damage(boss.health.current)
	check(await until(func() -> bool: return boss.is_defeated and get_tree().current_scene.get_node("Fight")._ended),"victory synchronized")
	check(await until(func() -> bool: return SaveGame.is_defeated("madame_carretel")),"victory/save shared with client")
	await meet("finished")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("[%s] FAILURES: %d" % [role,failures])
	get_tree().quit(failures)
