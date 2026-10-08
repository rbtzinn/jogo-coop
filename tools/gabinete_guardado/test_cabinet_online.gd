extends Node
## Regressão do Gabinete Sem Fundo com dois processos reais ENet.
## Executar host e client juntos, acrescentando "ruim" para a simulação de rede ruim.

const PORT := 24694
const FIGHT := "res://bosses/magician/magician_fight.tscn"
var role := ""
var failures := 0
var _arrived := {}


func _ready() -> void:
	role = "host" if "host" in OS.get_cmdline_user_args() else "client"
	if "ruim" in OS.get_cmdline_user_args():
		Network.simulation_index = Network.SIMULATIONS.size() - 1
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	tree.create_timer(160.0).timeout.connect(func() -> void: get_tree().quit(99))
	_run()


func check(ok: bool, label: String) -> void:
	print("[%s] %s %s" % [role, "OK" if ok else "FAIL", label])
	if not ok:
		failures += 1


func until(condition: Callable, limit := 12.0) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < limit:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return condition.call()


func meet(tag: String) -> void:
	while not _arrived.has(tag):
		for peer_id in multiplayer.get_peers():
			_arrive.rpc_id(peer_id, tag)
		await get_tree().create_timer(0.2).timeout
	for peer_id in multiplayer.get_peers():
		_arrive.rpc_id(peer_id, tag)
	await get_tree().create_timer(0.3).timeout


@rpc("any_peer", "call_remote", "reliable")
func _arrive(tag: String) -> void:
	_arrived[tag] = true


func _run() -> void:
	SaveGame.path = "user://test_save_cabinet_%s.json" % role
	SaveGame.reset()
	if role == "host":
		check(Network.host(PORT) == OK, "server opened")
		Network.change_level(FIGHT)
	else:
		await get_tree().create_timer(1.0).timeout
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "client started")
		await Network.joined
	var loaded := await until(func() -> bool:
		return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == FIGHT \
				and not Network.ready_peers.is_empty() and get_tree().get_nodes_in_group(&"players").size() == 2)
	check(loaded, "both players in magician arena")
	if not loaded:
		get_tree().quit(1)
		return
	var boss: MagicianBoss = get_tree().current_scene.get_node("MagicianBoss")
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000, 100000)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await meet("ready")
	if role == "host":
		boss.apply_damage(boss.health.current - boss.phase_end_health())
	await until(func() -> bool: return boss.phase == 1 and not boss.get_node("Attacks/IntroSawing").is_running())
	await meet("phase_two")
	if role == "host":
		boss.apply_damage(boss.health.current - boss.phase_end_health())
	check(await until(func() -> bool:
		return boss.phase == 2 and boss.giant.visible and boss.giant.hurtbox.monitorable \
				and not boss.get_node("Attacks/IntroGiant").is_running()), "cabinet unfolded and vulnerable on this peer")
	var health_before := boss.health.current
	await meet("panel")
	if role == "client":
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.is_multiplayer_authority():
				boss.giant.hurtbox.take_hit(10, String(player.name))
	check(await until(func() -> bool: return boss.health.current == health_before - 10),
			"client shot damages the central panel once on both peers")
	await meet("panel_hit")
	for attack_name: StringName in [&"GrabHands", &"GiantCards", &"HatPour"]:
		var attack: Node = boss.get_node(NodePath("Attacks/" + String(attack_name)))
		await meet("before_" + String(attack_name))
		if role == "host":
			boss.sync.start_attack(attack_name, 731, boss._args_for(attack_name))
		check(await until(func() -> bool: return attack.is_running(), 4.0), "attack replicated: " + String(attack_name))
		if attack_name == &"GrabHands":
			check(await until(func() -> bool: return boss.left_hand.hitbox.active or boss.right_hand.hitbox.active, 5.0),
					"stamp reaches its damage window")
		elif attack_name == &"GiantCards":
			check(boss.left_hand.prop_mode == GiantHand.PropMode.ROLL and not boss.left_hand.hitbox.active,
					"ticket emitter is visible and harmless")
		else:
			check(await until(func() -> bool: return absf(boss.giant.hat_tilt) > 0.2), "drawer opening replicated")
		check(await until(func() -> bool: return not attack.is_running()), "attack completed: " + String(attack_name))
		check(not boss.left_hand.hitbox.active and not boss.right_hand.hitbox.active, "props harmless after attack")
		await meet("after_" + String(attack_name))
	# Entrar novamente na fase final deve restaurar o gabinete sem replay da introdução.
	if role == "client":
		Network.leave()
		await get_tree().create_timer(1.0).timeout
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "rejoining final act")
		await Network.joined
	check(await until(func() -> bool: return not Network.ready_peers.is_empty() \
			and get_tree().get_nodes_in_group(&"players").size() == 2), "players ready after reconnection")
	if role == "client":
		boss = get_tree().current_scene.get_node("MagicianBoss")
	check(await until(func() -> bool: return boss.phase == 2 and boss.giant.visible and boss.giant.hurtbox.monitorable),
			"reconnected peer catches up to cabinet")
	await meet("rejoined")
	if role == "host":
		boss.apply_damage(boss.health.current)
	check(await until(func() -> bool: return boss.is_defeated and boss.giant.defeated), "defeat replicated")
	check(await until(func() -> bool: return not boss.giant.hurtbox.monitorable), "defeated panel no longer receives shots")
	await get_tree().create_timer(2.0).timeout
	var tickets := get_tree().get_nodes_in_group(&"hidden_tickets").filter(
			func(node: HiddenTicket) -> bool: return node.ticket_id == "area1:golden")
	check(tickets.size() == 1, "one golden ticket on this peer")
	await meet("finished")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("[%s] FAILURES: %d" % [role, failures])
	get_tree().quit(failures)
