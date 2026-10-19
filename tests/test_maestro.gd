extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_maestro.tscn
## Luta do Maestro Ferrugem: porta do mapa, vida e fases, compasso, nenhum ponto seguro parado (pauta em toda
## fase), cada ataque desenha e machuca, avisos travados, parry da nota turquesa, combos, reverência com a
## caixa de música (dano dobrado e tiro de verdade), vitória, derrota, toque e quem fica parado atirando.

const FIGHT := "res://bosses/rust_maestro/rust_maestro_fight.tscn"
## Pauta garantida de cada fase.
const STAFF := [&"Staff", &"StaffWaves", &"StaffEighths"]

var failures := 0
var fixture: Node
var boss: RustMaestroBoss
var player: Player


func _ready() -> void:
	get_tree().create_timer(900.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func spawn() -> void:
	fixture = load(FIGHT).instantiate()
	get_tree().root.add_child(fixture)
	get_tree().current_scene = fixture
	boss = fixture.get_node("RustMaestroBoss")
	player = get_tree().get_first_node_in_group(&"players")
	await frames(3)
	freeze()


func freeze() -> void:
	boss._wait = 99999
	boss.pause_between_attacks = Vector2(99999, 99999)
	fixture.get_node("Fight").set_physics_process(false)
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		p.set_physics_process(false)
		p.player_health.health.maximum = 1000
		p.player_health.health.set_current(1000)
		p.player_health._invincible_timer = 1000


func stationary(at: Vector2, crouched := false) -> void:
	player.position = at
	player.velocity = Vector2.ZERO
	player.player_health._invincible_timer = 0
	player.hurt_shape.position.y = -42 if crouched else -66
	(player.hurt_shape.shape as RectangleShape2D).size.y = 80 if crouched else 118


func run_attack(key: StringName, args: Array, manual_damage := false) -> Dictionary:
	boss.sync.start_attack(key, 74, args)
	var seen := {}
	while boss._current.is_running():
		await frames(1)
		if manual_damage:
			player.player_health.tick(1.0 / 60.0, true)
		for prop: Node in boss._current.get_children():
			if prop is MaestroThreat and prop.visible and prop.active:
				seen[prop.kind] = true
	return seen


func advance() -> void:
	boss.health.damage(boss.health.current - boss.phase_end_health())
	await frames(int(RustMaestroBoss.BEAT * 4 * 60) + 20)
	freeze()


func _run() -> void:
	SaveGame.path = "user://test_maestro_gameplay.json"
	SaveGame.reset()
	var world: Node = load(Levels.MAPS[3]).instantiate()
	add_child(world)
	var door: WorldDoor = world.get_node("DoorMaestro")
	check(door.target_scene == FIGHT and ResourceLoader.exists(FIGHT) and door.is_open(), "workshops door opens the Maestro fight")
	world.queue_free()
	await frames(3)
	PlayerSpawner.solo_slot = 0
	await spawn()
	check(boss.health.maximum == 1250 and boss.phase_shares.size() == 3, "1250 HP / three phases")
	check(fixture.get_node("Arena").z_index < fixture.get_node("PlayerSpawner").z_index, "stage never hides player")
	var fresh := RustMaestroBoss.new()
	check(boss.get_node("Attacks/Staff").BEATS.size() == boss.get_node("Attacks").get_child_count()
		and fresh.pause_between_attacks == Vector2.ONE * RustMaestroBoss.BEAT
		and is_equal_approx(fresh.intro_time, RustMaestroBoss.BEAT * 4), "attacks and pauses count whole beats")
	fresh.free()
	var before := boss.health.current
	boss.actor.hurtbox.take_hit(3, String(player.name))
	check(before - boss.health.current == 6, "solo shot scaling uses common boss rules")
	await _hit_feedback()
	await _beat_clock()
	await _combos()
	# Caminhada, pulo e dash de verdade não levam às costas do Maestro.
	player.set_physics_process(true)
	player.input.local_control = true
	Input.action_press(&"move_right")
	await frames(190)
	check(player.position.x <= 1473.5, "walking cannot access behind boss")
	Input.action_press(&"jump")
	await frames(2)
	Input.action_release(&"jump")
	Input.action_press(&"dash")
	await frames(8)
	Input.action_release(&"dash")
	await frames(60)
	check(player.position.x <= 1473.5, "air dash also cannot cross behind boss")
	Input.action_release(&"move_right")
	player.set_physics_process(false)
	for phase in 3:
		if phase > 0:
			await advance()
		check(boss.phase == phase, "phase %d loaded" % phase)
		# Pontos fixos: os dois cantos, perto do corpo, o meio e três alturas/caixas.
		for x in [27.0, 250.0, 600.0, 1000.0, 1320.0, 1473.0]:
			for stance in 3:
				var feet := Vector2(x, 660 if stance == 2 else 930)
				stationary(feet, stance == 1)
				var hp := player.player_health.health.current
				await run_attack(STAFF[phase], [feet + Vector2(0, -55)], true)
				check(player.player_health.health.current < hp, "phase %d fixed x%d / stance%d is not a safe spot" % [phase, int(x), stance])
				boss._wait = 99999
		boss._bag.clear()
		var chosen := {}
		for i in boss.phase_attacks[phase].size():
			chosen[boss._draw_from_bag()] = true
		check(chosen.has(STAFF[phase]), "phase %d bag guarantees the staff" % phase)
	check(boss.actor.organ_awake, "organ on his back is awake after Crescendo")
	boss.phase = 0
	for key in [&"Baton", &"Metronome", &"Waves", &"Eighths", &"Pipes"]:
		stationary(Vector2(500, 930))
		var hp := player.player_health.health.current
		var seen := await run_attack(key, [Vector2(500, 875)], true)
		check(not seen.is_empty() and player.player_health.health.current < hp, String(key) + " draws visible effects and actually damages")
	# Jogador perto do Maestro: o golpe da batuta alcança o chão na frente dele.
	stationary(Vector2(1440, 930))
	var near_hp := player.player_health.health.current
	boss.sync.start_attack(&"Baton", 75, [Vector2(1440, 875)])
	await frames(int(2 * RustMaestroBoss.BEAT * 60) + 6)
	player.player_health.tick(1.0 / 60.0, true)
	check(player.player_health.health.current < near_hp, "baton sweep reaches the floor next to him")
	boss._current.cancel()
	# Desviar no aviso funciona: o tubo não segue o jogador depois de travado.
	stationary(Vector2(400, 930))
	var hp := player.player_health.health.current
	boss.sync.start_attack(&"Pipes", 42, [Vector2(400, 875)])
	await frames(35)
	stationary(Vector2(1000, 930))
	while boss._current.is_running():
		await frames(1)
		player.player_health.tick(1.0 / 60.0, true)
	check(hp == player.player_health.health.current, "moving after pipe warning safely evades locked target")
	await _parry()
	await _bow()
	fixture.get_node("Fight").set_physics_process(true)
	boss.apply_damage(boss.health.current)
	await frames(150)
	check(boss.is_defeated and SaveGame.is_defeated("rust_maestro"), "victory / grade / tickets recorded through normal Fight")
	check(not boss.actor.hitbox.active and not boss.actor.hurtbox.monitorable, "defeat clears body contact")
	fixture.queue_free()
	await frames(4)
	await _mobile()
	await _afk()
	PlayerSpawner.solo_slot = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _hit_feedback() -> void:
	# Mais acertos que o tiro automático: dano continua, a pose nunca é trocada nem o Maestro sai do lugar.
	var actor := boss.actor
	actor.pose(&"raise")
	var home := actor.position
	var hp := boss.health.current
	var white_frames := 0
	var stable := true
	for i in 60:
		actor.hurtbox.take_hit(1, String(player.name))
		actor._process(1.0 / 60.0)
		stable = stable and actor.pose_name == &"raise" and actor.position == home
		if actor.get_node("Art").modulate == Color.WHITE:
			white_frames += 1
	check(stable, "continuous shots never replace attack pose or move boss")
	check(hp - boss.health.current == 120, "flash cooldown never suppresses real shot damage")
	check(white_frames >= 35, "brief hit flash returns to normal even under constant shooting")
	actor.idle()


func _beat_clock() -> void:
	# O compasso zera no começo de cada ataque (nos dois PCs) e o metrônomo do palco lê o mesmo relógio.
	boss.beat_clock = 0.37
	boss.sync.start_attack(&"Staff", 5, [Vector2(500, 875)])
	check(is_zero_approx(boss.beat_clock), "beat restarts on each attack")
	boss.play_attack(&"Staff", 5, 1.2, [Vector2(500, 875)])
	check(is_equal_approx(boss.beat_clock, 1.2), "late start keeps the same beat as the host")
	check(fixture.get_node("Arena/Metronome").boss == boss, "stage metronome follows the fight beat")
	boss._current.cancel()
	await frames(2)


func _combos() -> void:
	var expected := {&"StaffWaves": [&"note", &"wave"], &"StaffEighths": [&"note", &"eighths"], &"BatonWaves": [&"crescent", &"wave"]}
	var sample := {&"StaffWaves": 4.0, &"StaffEighths": 2.85, &"BatonWaves": 4.0}
	for key: StringName in expected:
		boss.sync.start_attack(key, 86, [Vector2(400, 875), Vector2(950, 605)])
		var attack := boss._current
		attack.set_physics_process(false)
		attack.elapsed = 0.7
		attack._on_tick(0)
		var harmless := true
		for prop: MaestroThreat in attack._props.values():
			harmless = harmless and not prop.active
		check(not attack._warnings.is_empty() or attack._staff_glow > 0.0, String(key) + " warns before damage")
		check(harmless, String(key) + " warning is not an invisible damaging hitbox")
		attack.elapsed = sample[key]
		attack._on_tick(0)
		var kinds := {}
		for prop: MaestroThreat in attack._props.values():
			if prop.active and prop.visible:
				kinds[&"note" if prop.kind == &"note_parry" else prop.kind] = true
		check(expected[key].all(func(kind: StringName) -> bool: return kinds.has(kind)), String(key) + " overlaps two real dangers")
		# Quem entra atrasado recebe o mesmo relógio e os mesmos alvos do host.
		var positions := {}
		for id: String in attack._props:
			if attack._props[id].visible:
				positions[id] = attack._props[id].position
		attack.cancel()
		await frames(2)
		check(attack.get_child_count() == 0, String(key) + " cancel removes every component")
		boss.play_attack(key, 86, sample[key], [Vector2(400, 875), Vector2(950, 605)])
		attack.set_physics_process(false)
		var matches := true
		for id: String in positions:
			matches = matches and attack._props.has(id) and attack._props[id].position.distance_to(positions[id]) < 0.01
		check(matches, String(key) + " late start preserves deterministic trajectories")
		attack.set_physics_process(true)
		attack.cancel()
		await frames(2)
	# Nota alta da pauta das ondas só longe das ondas (mesma velocidade: a distância não muda).
	boss.sync.start_attack(&"StaffWaves", 3, [Vector2(400, 875)])
	var safe := true
	for note: Array in boss._current.notes:
		if note[1] == 2:
			safe = safe and not note[0] in [3, 4, 6, 7]
	check(safe, "high notes never share a column with a floor wave")
	boss._current.cancel()
	await frames(2)


func _parry() -> void:
	boss.phase = 0
	boss.sync.start_attack(&"Staff", 11, [Vector2(500, 875)])
	var attack := boss._current
	var index := -1
	for i in attack.notes.size():
		if attack.notes[i][2]:
			index = i
	var launch: float = attack.notes[index][0] * RustMaestroBoss.BEAT
	await frames(int((launch + 0.6) * 60))
	var parry: MaestroThreat = attack._props.get("note:%d" % index)
	check(parry != null and parry.kind == &"note_parry" and parry.can_parry(String(player.name)), "turquoise note exposes real parry")
	if parry != null:
		player.position = parry.global_position + Vector2(0, 85)
		await frames(2)
		check(player.parry.tick(1.0 / 60.0, false, true), "player parry detects physical note overlap")
		check(parry.popped and not parry.active and not parry.visible, "parry removes the note and its danger")
	attack.cancel()
	await frames(2)
	check(attack.get_child_count() == 0, "cancel clears every note")


func _bow() -> void:
	# Fase 3: toda música termina na reverência, com a caixa de música aberta e dano dobrado.
	boss.phase = 2
	boss.sync.start_attack(&"Pipes", 12, [Vector2(300, 875)])
	var attack := boss._current
	var open_at: float = attack.BEATS[attack.pattern] * RustMaestroBoss.BEAT + 0.6
	check(not boss.actor.chest_open, "chest closed while the pipes play")
	await frames(int(open_at * 60))
	check(boss.actor.chest_open and boss.actor.chest.monitorable and not boss.actor.hurtbox.monitorable, "bow opens the music box as the only target")
	var before := boss.health.current
	boss.actor.chest.take_hit(3, String(player.name))
	check(before - boss.health.current == 12, "open music box doubles shot damage plus solo scaling")
	before = boss.health.current
	player.gun.spawn_projectile(Vector2.RIGHT, Vector2(1100, boss.actor.chest.get_child(0).global_position.y))
	await frames(24)
	check(before - boss.health.current == 4, "real cork reaches the music box through the player boundary")
	while attack.is_running():
		await frames(1)
	check(not boss.actor.chest_open and boss.actor.hurtbox.monitorable, "music box closes when the bow ends")
	boss.phase = 0


func _mobile() -> void:
	SaveGame.reset()
	await spawn()
	MobileControls.enable()
	player.set_physics_process(true)
	player.input.local_control = true
	await frames(12)
	check(MobileControls._active and not MobileControls._map_mode, "mobile detects the Maestro fight")
	check(player.input.shoot_held, "mobile auto-fire works")
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	touch.position = MobileControls._buttons[&"jump"].at
	MobileControls._input(touch)
	await frames(6)
	check(player.position.y < 920, "real touch button jumps in the Maestro fight")
	touch.pressed = false
	MobileControls._input(touch)
	MobileControls.release_all()
	fixture.get_node("Fight").set_physics_process(true)
	player.player_health.health.damage(1000)
	await frames(80)
	check(fixture.get_node("Fight")._ended and not SaveGame.is_defeated("rust_maestro"), "defeat offers normal restart without saving victory")
	fixture.queue_free()
	get_tree().current_scene = self
	await frames(4)


func _afk() -> void:
	# Ficar parado só atirando, nos dois cantos e com vida normal, perde a luta.
	for x in [27.0, 1473.0]:
		SaveGame.reset()
		await spawn()
		fixture.get_node("Fight").set_physics_process(true)
		player.position = Vector2(x, 930)
		player.player_health.health.maximum = 3
		player.player_health.health.set_current(3)
		player.player_health._invincible_timer = 0
		player.set_physics_process(true)
		player.input.scripted = true
		player.input.shoot_held = true
		player.input.move = Vector2.ZERO
		boss.pause_between_attacks = Vector2(RustMaestroBoss.BEAT, RustMaestroBoss.BEAT)
		boss._brain_rng.seed = 103
		boss._wait = 0.1
		for i in 2400:
			await frames(1)
			if fixture.get_node("Fight")._ended:
				break
		check(player.player_health.is_downed and not boss.is_defeated, "idle autofire x%d loses instead of cheesing victory" % int(x))
		fixture.queue_free()
		await frames(4)
