extends Node
const FIGHT := "res://bosses/madame_carretel/madame_carretel_fight.tscn"
var failures := 0
var fixture: Node
var boss: MadameCarretelBoss
var player: Player
var capture_dir := ""

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()>1 and args[0]=="capture": capture_dir = args[1]
	get_tree().create_timer(600.0,true,false,true).timeout.connect(func() -> void: get_tree().quit(99))
	_run.call_deferred()

func check(ok: bool,label: String) -> void:
	print(("OK " if ok else "FAIL ")+label)
	if not ok: failures += 1

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func photo(label: String) -> void:
	if capture_dir.is_empty(): return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		p.visual.show()
		p.player_health._blink_timer = 1000
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label+".png"))

func spawn() -> void:
	fixture = load(FIGHT).instantiate()
	get_tree().root.add_child(fixture)
	get_tree().current_scene = fixture
	boss = fixture.get_node("MadameCarretelBoss")
	player = get_tree().get_first_node_in_group(&"players")
	await frames(3)
	freeze()

func freeze() -> void:
	boss._wait = 99999
	boss.pause_between_attacks = Vector2(99999,99999)
	fixture.get_node("Fight").set_physics_process(false)
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		p.set_physics_process(false)
		p.player_health.health.maximum = 1000
		p.player_health.health.set_current(1000)
		p.player_health._invincible_timer = 1000

func stationary(at: Vector2,crouched := false) -> void:
	player.position = at
	player.velocity = Vector2.ZERO
	player.player_health._invincible_timer = 0
	player.hurt_shape.position.y = -42 if crouched else -66
	(player.hurt_shape.shape as RectangleShape2D).size.y = 80 if crouched else 118

func run_attack(key: StringName,args: Array,manual_damage := false) -> Dictionary:
	boss.sync.start_attack(key,74,args)
	var seen := {}
	while boss._current.is_running():
		await frames(1)
		if manual_damage: player.player_health.tick(1.0/60.0,true)
		for prop: Node in boss._current.get_children():
			if prop is CarretelThreat and prop.visible: seen[prop.kind] = true
	return seen

func advance() -> void:
	boss.health.damage(boss.health.current-boss.phase_end_health())
	await frames(120)
	freeze()

func _run() -> void:
	SaveGame.path = "user://test_carretel_gameplay.json"
	SaveGame.reset()
	var map: PackedScene = load(Levels.MAPS[3])
	var world := map.instantiate()
	add_child(world)
	var door: WorldDoor = world.get_node("DoorCarretel")
	check(door.target_scene==FIGHT and ResourceLoader.exists(FIGHT),"workshops door references real Madame fight")
	world.queue_free()
	await frames(3)
	PlayerSpawner.solo_slot = 0
	await spawn()
	check(boss.health.maximum==1250 and boss.phase_shares.size()==3,"1250 HP / three phases")
	check(boss.alive_players().size()==1,"solo spawns one real player")
	check(fixture.get_node("Arena").z_index<fixture.get_node("PlayerSpawner").z_index,"painting never hides player")
	var before := boss.health.current
	boss.actor.hurtbox.take_hit(3,String(player.name))
	check(before-boss.health.current==6,"solo shot scaling uses common boss rules")
	await _hit_feedback()
	await _combos()
	# Caminhada, pulo e dash REAIS não levam às costas do boss.
	player.set_physics_process(true)
	player.input.local_control = true
	Input.action_press(&"move_right")
	await frames(190)
	check(player.position.x<=1473.5,"walking cannot access behind boss")
	Input.action_press(&"jump")
	await frames(2)
	Input.action_release(&"jump")
	Input.action_press(&"dash")
	await frames(8)
	Input.action_release(&"dash")
	await frames(60)
	check(player.position.x<=1473.5,"air dash also cannot cross behind boss")
	Input.action_release(&"move_right")
	player.set_physics_process(false)
	for phase in 3:
		if phase>0: await advance()
		check(boss.phase==phase,"phase %d loaded" % phase)
		await photo("phase%d" % phase)
		# Pontos fixos: ambos os cantos, perto do corpo, centro e três alturas/caixas.
		for x in [27.0,250.0,600.0,1000.0,1320.0,1473.0]:
			for stance in 3:
				var feet := Vector2(x,660 if stance==2 else 930)
				stationary(feet,stance==1)
				var hp := player.player_health.health.current
				await run_attack(&"NeedlesTape",[feet+Vector2(0,-55)],true)
				check(player.player_health.health.current<hp,"phase %d fixed x%d / stance%d is not a safe spot" % [phase,int(x),stance])
				boss._wait = 99999
		# Ciclo sorteado não pode omitir o ataque direcionado.
		boss._bag.clear()
		var chosen := {}
		for i in boss.phase_attacks[phase].size(): chosen[boss._draw_from_bag()] = true
		check(chosen.has(&"NeedlesTape"),"phase %d bag guarantees aimed + ground combo" % phase)
	for key in [&"Scissors",&"Tape",&"Curtains",&"Buttons"]:
		stationary(Vector2(500,930))
		var hp := player.player_health.health.current
		var seen := await run_attack(key,[Vector2(500,875)],true)
		check(not seen.is_empty() and player.player_health.health.current<hp,String(key)+" draws visible effects and actually damages")
	# Desviar durante aviso é possível: alvo NÃO acompanha o jogador depois de travado.
	stationary(Vector2(400,930))
	var hp := player.player_health.health.current
	boss.sync.start_attack(&"Curtains",42,[Vector2(400,875)])
	await frames(35)
	stationary(Vector2(1000,930))
	while boss._current.is_running():
		await frames(1)
		player.player_health.tick(1.0/60.0,true)
	check(hp==player.player_health.health.current,"moving after curtain warning safely evades locked target")
	# Parry real: nó identificado, ativo e limpo nos dois PCs pelo sistema existente.
	boss.sync.start_attack(&"NeedlesTape",11,[Vector2(500,875)])
	await frames(112)
	var parry: CarretelThreat
	for prop in boss._current.get_children():
		if prop is CarretelThreat and prop.parryable: parry = prop
	check(parry!=null and parry.can_parry(String(player.name)),"turquoise needle exposes real parry")
	if parry!=null:
		player.position = parry.global_position+Vector2(0,85)
		await frames(2)
		check(player.parry.tick(1.0/60.0,false,true),"player parry detects physical needle overlap")
		check(parry.popped and not parry.active and not parry.visible,"parry removes projectile and its danger")
	boss._current.cancel()
	await frames(2)
	check(boss.get_node("Attacks/NeedlesTape").get_child_count()==0,"cancel clears both combo hazards")
	# Fase mecânica: os três botões destacados são vulneráveis, sem hitboxes invisíveis.
	boss.sync.start_attack(&"Buttons",12,[Vector2(500,875)])
	await frames(180)
	check(boss.actor.weak_open and boss.actor.buttons.all(func(b: Hurtbox) -> bool: return b.monitorable),"three button weak points open visibly")
	before = boss.health.current
	boss.actor.buttons[2].take_hit(3,String(player.name))
	check(before-boss.health.current==12,"weak button doubles shot damage plus solo scaling")
	before = boss.health.current
	player.gun.spawn_projectile(Vector2.RIGHT,Vector2(900,820))
	await frames(24)
	check(before-boss.health.current==4,"real cork reaches weak button through player boundary")
	await photo("mechanical_buttons")
	boss._current.cancel()
	fixture.get_node("Fight").set_physics_process(true)
	boss.apply_damage(boss.health.current)
	await frames(150)
	check(boss.is_defeated and SaveGame.is_defeated("madame_carretel"),"victory / grade / tickets recorded through normal Fight")
	check(not boss.actor.hitbox.active,"defeat clears body contact")
	await photo("victory")
	fixture.queue_free()
	await frames(4)
	await _mobile()
	await _afk()
	PlayerSpawner.solo_slot = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ",failures)
	get_tree().quit(failures)

func _hit_feedback() -> void:
	# Simula mais acertos do que o autofire: dano continua, pose nunca é substituída.
	var actor := boss.actor
	actor.pose(&"needles",2)
	var home := actor.position
	var hp := boss.health.current
	var white_frames := 0
	var stable := true
	for i in 60:
		actor.hurtbox.take_hit(1,String(player.name))
		actor._process(1.0/60.0)
		stable = stable and actor.sprite.animation==&"needles" and actor.sprite.frame==2 and actor.position==home
		if actor.sprite.modulate==Color.WHITE: white_frames += 1
	check(stable,"continuous shots never replace attack pose or move boss")
	check(hp-boss.health.current==120,"flash cooldown never suppresses real shot damage")
	check(white_frames>=35,"brief hit flash returns to normal even under constant shooting")
	actor.idle()

func _combos() -> void:
	for key in [&"NeedlesTape",&"CurtainsNeedles",&"ButtonsScissors"]:
		boss.sync.start_attack(key,86,[Vector2(400,875),Vector2(950,605)])
		var attack := boss._current
		attack.elapsed = 0.7
		attack._on_tick(0)
		check(attack._warnings.size()>=3,String(key)+" warns both hazards before damage")
		var harmless := true
		for prop: CarretelThreat in attack._props.values(): harmless = harmless and not prop.active
		check(harmless,String(key)+" warning is not an invisible damaging hitbox")
		attack.elapsed = 2.4
		attack._on_tick(0)
		var kinds := {}
		for prop: CarretelThreat in attack._props.values():
			if prop.active and prop.visible: kinds[prop.kind] = true
		var expected: Array = {&"NeedlesTape":[&"needle_parry",&"tape"],
			&"CurtainsNeedles":[&"cloth",&"needle_parry"],
			&"ButtonsScissors":[&"button",&"cut"]}[key]
		check(expected.all(func(kind: StringName) -> bool: return kinds.has(kind)),String(key)+" visibly overlaps two real dangers")
		check(attack._props.size()<=6,String(key)+" limits simultaneous props for duo/mobile")
		# Reentrada com atraso recebe o mesmo relógio e os mesmos alvos do host.
		var positions := {}
		for id: String in attack._props: positions[id] = attack._props[id].position
		attack.cancel()
		await frames(2)
		check(attack.get_child_count()==0,String(key)+" cancel removes every component")
		boss.play_attack(key,86,2.4,[Vector2(400,875),Vector2(950,605)])
		var matches := true
		for id: String in positions:
			matches = matches and attack._props.has(id) and attack._props[id].position.distance_to(positions[id])<0.01
		check(matches,String(key)+" late start preserves deterministic trajectories")
		if key==&"ButtonsScissors":
			boss.actor.armored = true
			attack.elapsed = 4.35
			attack._on_tick(0)
			check(boss.actor.weak_open and not attack._props["cut"].active,"mechanical combo keeps a clear counterattack window after cut")
			boss.actor.armored = false
		attack.cancel()
		await frames(2)

func _mobile() -> void:
	SaveGame.reset()
	await spawn()
	get_tree().current_scene = fixture
	MobileControls.enable()
	player.set_physics_process(true)
	player.input.local_control = true
	await frames(12)
	check(MobileControls._active and not MobileControls._map_mode,"mobile detects the new combat scene")
	check(player.input.shoot_held,"mobile auto-fire works without changing player scripts")
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	touch.position = MobileControls._buttons[&"jump"].at
	MobileControls._input(touch)
	await frames(6)
	check(player.position.y<920,"real touch button jumps in Madame fight")
	touch.pressed = false
	MobileControls._input(touch)
	MobileControls.release_all()
	fixture.get_node("Fight").set_physics_process(true)
	player.player_health.health.damage(1000)
	await frames(80)
	check(fixture.get_node("Fight")._ended and not SaveGame.is_defeated("madame_carretel"),"defeat offers normal restart without saving victory")
	fixture.queue_free()
	get_tree().current_scene = self
	await frames(4)

func _afk() -> void:
	# Reproduz o exploit relatado: ficar parado, só atirar, com vida normal.
	for x in [27.0,1473.0]:
		SaveGame.reset()
		await spawn()
		fixture.get_node("Fight").set_physics_process(true)
		player.position = Vector2(x,930)
		player.player_health.health.maximum = 3
		player.player_health.health.set_current(3)
		player.player_health._invincible_timer = 0
		player.set_physics_process(true)
		player.input.scripted = true
		player.input.shoot_held = true
		player.input.move = Vector2.ZERO
		boss.pause_between_attacks = Vector2(0.24,0.42)
		boss._brain_rng.seed = 103
		boss._wait = 0.1
		for i in 2100:
			await frames(1)
			if fixture.get_node("Fight")._ended: break
		check(player.player_health.is_downed and not boss.is_defeated,"idle autofire x%d loses instead of cheesing victory" % int(x))
		fixture.queue_free()
		await frames(4)
