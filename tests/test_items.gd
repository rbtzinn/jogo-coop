extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_items.tscn
## Efeito de cada item da loja (docs/shop.md): pistolas e Tiros EX, truques do dash,
## adereços e números de dupla. Cada grupo monta a luta do Domador de novo com o equipamento.

var failures := 0
var _scene: Node
var clown: Player
var acrobat: Player
var boss: BossBrain


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func press(action: StringName, hold := 2) -> void:
	Input.action_press(action)
	await frames(hold)
	Input.action_release(action)


func _ready() -> void:
	get_tree().create_timer(200.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


## Monta a luta com o equipamento pedido (o resto fica o inicial).
func setup(clown_items: Dictionary, acrobat_items := {}) -> void:
	if _scene != null:
		_scene.queue_free()
		for projectile in projectiles():
			projectile.queue_free()
		await frames(2)
	SaveGame.reset()
	for key in ["clown", "acrobat"]:
		var wanted: Dictionary = clown_items if key == "clown" else acrobat_items
		for slot in wanted:
			SaveGame.data.players[key].items.append(wanted[slot])
			SaveGame.data.players[key].equipped[slot] = wanted[slot]
	_scene = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(_scene)
	await frames(5)
	boss = _scene.get_node("TamerBoss")
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	clown = _scene.get_node("PlayerSpawner/Player_1")
	acrobat = _scene.get_node("PlayerSpawner/Player_2")
	await frames(20)


func projectiles() -> Array:
	return get_tree().current_scene.get_children().filter(func(n: Node) -> bool: return n is Projectile)


func _run() -> void:
	SaveGame.path = "user://test_save_items.json"

	# --- Pistolas ---
	await setup({"gun": "confetti_fan"})
	check(clown.gun.weapon == "confetti_fan", "loadout gives the confetti fan")
	await press(&"shoot")
	await frames(1)
	var shots := projectiles()
	check(shots.size() == 3 and shots.all(func(p: Projectile) -> bool: return p.look == &"confetti"), "confetti: 3 pellets (%d)" % shots.size())
	clown.gun.spawn_ex(Vector2.RIGHT, clown.rig.get_muzzle_position())
	await frames(1)
	check(get_tree().current_scene.get_children().any(func(n: Node) -> bool: return n is AreaBlast), "confetti EX: blast around the player")

	await setup({"gun": "juggling_club"})
	clown.global_position = Vector2(700, 1000)
	await frames(2)
	await press(&"shoot")
	await frames(1)
	var club: Projectile = projectiles()[0] if not projectiles().is_empty() else null
	check(club != null and club.boomerang, "club is a boomerang")
	var farthest := 0.0
	for i in 90:
		await get_tree().physics_frame
		if is_instance_valid(club):
			farthest = maxf(farthest, club.global_position.x - clown.global_position.x)
	check(farthest > 250.0 and not is_instance_valid(club), "club goes out and comes back (%.0f px)" % farthest)
	clown.gun.spawn_ex(Vector2.RIGHT, clown.rig.get_muzzle_position())
	await frames(1)
	check(projectiles().filter(func(p: Projectile) -> bool: return p.look == &"club" and p.pierce).size() == 5, "club EX: 5 clubs fall ahead")

	await setup({"gun": "soap_bubble"})
	clown.global_position = Vector2(1000, 1000)
	await frames(2)
	clown.gun.spawn_projectile(Vector2.UP, clown.rig.get_muzzle_position())
	await frames(1)
	var bubble: Projectile = projectiles()[0]
	await frames(20)
	check(is_instance_valid(bubble) and bubble.direction.x > 0.3, "bubble turns toward the boss (%s)" % (bubble.direction if is_instance_valid(bubble) else "?"))
	var before := boss.health.current
	clown.global_position = Vector2(1300, 1000)
	await frames(2)
	clown.gun.spawn_ex(Vector2.RIGHT, clown.rig.get_muzzle_position())
	await frames(150)
	check(boss.health.current <= before - 35, "big bubble bursts on the boss (%d)" % (before - boss.health.current))

	# --- Truques ---
	await setup({"trick": "magic_smoke"})
	var start_x := clown.global_position.x
	await press(&"dash")
	await frames(1)
	check(not clown.visual.visible and clown.duo.decoy != Vector2.INF, "smoke: vanishes and leaves a decoy")
	check(clown.target_position() == clown.duo.decoy, "attacks aim at the decoy")
	await frames(30)
	var smoke_distance := clown.global_position.x - start_x
	check(clown.visual.visible and smoke_distance > 150.0 and smoke_distance < 260.0, "smoke dash is shorter (%.0f)" % smoke_distance)
	await frames(60)
	check(clown.duo.decoy == Vector2.INF, "decoy gone after 1 s")

	await setup({"trick": "cannonball"})
	clown.global_position = Vector2(1300, 1000)
	await frames(2)
	await press(&"dash")
	await frames(2)
	check(clown.is_dashing() and clown._can_be_hit(), "cannonball: no invincibility while dashing")
	check(clown._dash_damage != null and clown._dash_damage.monitoring, "cannonball: dash hurts")

	await setup({"trick": "pirouette"})
	Input.action_press(&"lock_aim")
	Input.action_press(&"move_up")
	await frames(1)
	await press(&"dash")
	await frames(1)
	check(clown.velocity.y < -1000.0, "pirouette: dash upward (%.0f)" % clown.velocity.y)
	Input.action_release(&"move_up")
	Input.action_release(&"lock_aim")

	# --- Adereços ---
	await setup({"prop": "cloth_heart"})
	check(clown.player_health.health.maximum == 4 and clown.player_health.health.current == 4, "cloth heart: 4 hearts")
	check(is_equal_approx(clown.gun.damage_scale, 0.95), "cloth heart: 5% less damage")
	await setup({"prop": "honk_nose"})
	var hitbox := EnemyHitbox.new()
	_scene.add_child(hitbox)
	clown.player_health._take_hit(hitbox)
	check(clown.player_health.health.current == 3, "honk nose: first hit absorbed")
	clown.player_health._invincible_timer = 0.0
	clown.player_health._take_hit(hitbox)
	check(clown.player_health.health.current == 2, "honk nose: only the first")
	await setup({"prop": "mime_gloves"})
	check(is_equal_approx(clown.parry.window, PlayerParry.WINDOW * 1.5), "mime gloves: bigger parry window")
	await setup({"prop": "spring_shoes"})
	check(is_equal_approx(clown.jump_height, 270.0 * 1.15) and is_equal_approx(acrobat.jump_height, 270.0), "spring shoes: higher jump (only the clown)")
	await setup({"prop": "lucky_clover"})
	clown.applause.add_stars(1.0)
	check(is_equal_approx(clown.applause.stars, 1.25), "lucky clover: bar fills 25% faster")

	# --- Números de dupla ---
	await setup({"duo": "catapult"})
	acrobat.global_position = clown.global_position + Vector2(30, 0)
	await frames(2)
	await press(&"dash")
	await frames(2)
	check(clown.velocity.y < -1000.0 and clown.duo.is_flying() and not clown._can_be_hit(), "catapult: launched high, invincible")

	await setup({"duo": "human_pyramid"})
	acrobat.global_position = Vector2(1000, 1000)
	clown.global_position = Vector2(1000, 600)
	clown.velocity = Vector2.ZERO
	var stars_before := clown.applause.stars
	var bounced := false
	for i in 40:
		await get_tree().physics_frame
		if clown.velocity.y < -500.0:
			bounced = true
			break
	check(bounced and clown.applause.stars > stars_before, "human pyramid: head counts as parry")

	await setup({"duo": "safety_net"}, {})
	acrobat.player_health.health.damage(3)
	await frames(2)
	check(is_equal_approx(acrobat.duo.balloon_rise_factor(), 0.5), "safety net: partner balloon rises slower")
	clown.global_position = acrobat.balloon.global_position + Vector2(0, 70)
	await frames(5)
	check(not acrobat.player_health.is_downed, "safety net: revive just by touching")

	# Resgate sem item: encostado no balão por 1 s (não é mais com parry).
	await setup({}, {})
	acrobat.player_health.health.damage(3)
	await frames(2)
	clown.global_position = acrobat.balloon.global_position + Vector2(0, 70)
	await frames(20)
	check(acrobat.player_health.is_downed and acrobat.balloon.rescue_progress > 0.2, "rescue: a short touch is not enough")
	for i in 60:
		clown.global_position = acrobat.balloon.global_position + Vector2(0, 70)
		await get_tree().physics_frame
	check(not acrobat.player_health.is_downed, "rescue: one second touching the balloon revives")

	await setup({"duo": "turbo_cork"})
	acrobat.global_position = clown.global_position + Vector2(160, 0)
	await frames(2)
	clown.gun.spawn_projectile(Vector2.RIGHT, clown.global_position + Vector2(40, -66))
	await frames(1)
	var boosted: Projectile = projectiles()[0]
	await frames(8)
	check(not is_instance_valid(boosted) or boosted.turbo == false, "turbo cork: shot through the partner gets stronger")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)
