extends PaintedAttack
## Padrões da forja, calculados pelo tempo do ataque; o host só arbitra a mão que agarra.
enum Pattern { HAMMER, SHOES, BELLOWS, CHANNEL, ANVILS, GRIP, SPIN, STOMP, CHEST, INTRO_FORGE, INTRO_ARMOR }
@export var pattern := Pattern.HAMMER

var _from := Vector2.ZERO
var _side := 0
var _channel := 0
var _held := ""
var _hits := 0
var _decided := false
var _released := false
var _hand := Vector2.ZERO


func _start() -> void:
	_from = actor.global_position
	_side = rng.randi_range(0, 1)
	_channel = rng.randi_range(0, 2)
	_held = ""
	_hits = 0
	_decided = false
	_released = false


func _tick(t: float) -> void:
	actor.position.x = AnvilMasterBoss.HOME.x
	actor.facing = -1
	match pattern:
		Pattern.HAMMER:
			actor.pose(&"hammer", 0 if t < 0.8 else (1 if t < 0.95 else (2 if t < 1.25 else 3)))
			boss.get_parent().get_node("Anvil").visible = not (t >= 0.95 and t < 1.25)
			_waves(t, 0.95, actor.global_position.x - 160)
			for i in 5:
				var s := t - 0.95
				if s >= 0 and s < 1.4:
					prop("spark%d" % i, &"spark", Vector2(actor.global_position.x - 160 + (i - 2) * s * 210, 850 - 450 * s + 450 * s * s))
		Pattern.SHOES:
			actor.pose(&"throw", 0 if t < 0.5 else (1 if t < 0.9 else (2 if t < 1.65 else 3)))
			var levels := surface_levels()
			for lane in levels.size():
				for i in 3:
					var s := t - 0.9 - i * 0.4 - lane * 0.12
					var key := "shoe%d:%d" % [lane, i]
					if s >= 0 and s < 3.8:
						var at := Vector2(actor.global_position.x - 120 - s * 520, levels[lane] - 55 - absf(sin(s * PI * 2 + i * TAU / 3)) * 170)
						prop(key, &"shoe_parry" if i == 1 else &"shoe", at, i == 1)
					elif s >= 3.8:
						hide_prop(key)
		Pattern.BELLOWS:
			actor.pose(&"bellows", mini(int(t / 0.45), 3))
			var levels := surface_levels()
			for lane in levels.size():
				var y := levels[lane] - (130 if _side == 0 else 360)
				for i in 7:
					var s := t - 0.95 - i * 0.16 - lane * 0.1
					var key := "ember%d:%d" % [lane, i]
					if s >= 0 and s < 2.9:
						prop(key, &"ember", Vector2(actor.global_position.x - 170 - s * 640, y + sin(s * 3 + i) * 10))
					elif s >= 2.9:
						hide_prop(key)
		Pattern.CHANNEL:
			_forge_pose(t)
			var hot := t >= 1.0 and t < 4.0
			var x := 320.0 + _channel * 640
			var channel := prop("channel0", &"channel", Vector2(x, 1000))
			channel.frame = 1 if hot else 0
			channel.active = hot
			warning("channel0", Vector2(x, 996), minf(t, 1.0), 285)
			for platform in boss.get_parent().get_children():
				if not platform is ClockPlatform or not platform.visible:
					continue
				var left := maxf(x - 295, platform.global_position.x - platform.width * 0.5)
				var right := minf(x + 295, platform.global_position.x + platform.width * 0.5)
				var key := "heat:%s" % platform.name
				if right <= left:
					hide_prop(key)
					continue
				var heat := prop(key, &"platform_heat", Vector2((left + right) * 0.5, platform.global_position.y), false, platform)
				heat.draw_size = Vector2(right - left, 38)
				(heat._shape.shape as RectangleShape2D).size.x = right - left
				heat.active = hot
				heat.visible = hot
				warning(key, heat.global_position + Vector2(0, -4), minf(t, 1.0), (right - left) * 0.5)
		Pattern.ANVILS, Pattern.STOMP:
			if pattern == Pattern.ANVILS:
				_forge_pose(t)
				actor.pose(&"walk", 4)
			else:
				# O quadro com chão quebrado só aparece depois da aterrissagem.
				actor.pose(&"armor", 4 if t < 0.8 else (1 if t < 1.6 else 5))
				actor.global_position = _from + Vector2(0, -sin(clampf((t - 0.8) / 0.8, 0, 1) * PI) * 220)
				_waves(t, 1.6, actor.global_position.x)
			for i in 4:
				var launch := 0.7 + i * 0.45 if pattern == Pattern.ANVILS else 1.7 + i * 0.2
				var x: float = float(args[i]) if args.size() > i else 250 + i * 400
				var amount := clampf((t - launch + 0.65) / 0.65, 0, 1)
				warning("fall%d" % i, Vector2(x, 1000), amount, 72)
				for platform in boss.get_parent().get_children():
					if platform is ClockPlatform and absf(x - platform.global_position.x) < platform.width * 0.5 + 50:
						warning("fall%d:%s" % [i, platform.name], Vector2(x, platform.global_position.y), amount, 72)
				var s := t - launch
				if s >= 0 and s < 0.85:
					# A queda continua até o chão, atravessando também quem se esconde sob a plataforma.
					prop("fall%d" % i, &"anvil" if pattern == Pattern.ANVILS else &"rock", Vector2(x, lerpf(-90, 965, pow(s / 0.85, 2))))
				elif s >= 0.85:
					hide_prop("fall%d" % i)
		Pattern.SPIN:
			_forge_pose(t, true)
			actor.pose(&"armor", 1 if t < 0.9 else 3)
			if t >= 0.9:
				var angle := (t - 0.9) * TAU * 0.75
				var head := prop("hammer", &"hammer", actor.global_position + Vector2(-140 + cos(angle) * 180, -180 + sin(angle) * 130))
				head.spin = angle
				queue_redraw()
			_waves(t, 1.2, actor.global_position.x - 140)
		Pattern.CHEST:
			actor.pose(&"armor", 6 if t < 2.2 else 2)
			boss.set_chest(t >= 0.5 and t < 2.2)
			_waves(t, 2.3, actor.global_position.x)
		Pattern.GRIP:
			_grab_tick(t)
		Pattern.INTRO_FORGE:
			boss.set_stage(1)
			actor.pose(&"walk", mini(int(t * 4), 3))
		Pattern.INTRO_ARMOR:
			boss.set_stage(2)
			actor.pose(&"armor", 0 if t < 0.9 else 1)


func _forge_pose(t: float, armored := false) -> void:
	actor.position = AnvilMasterBoss.HOME
	actor.pose(&"armor" if armored else &"walk", (1 + int(t * 3) % 2) if armored else int(t * 6) % 4)


func _waves(t: float, start: float, x: float) -> void:
	var levels := surface_levels()
	for lane in levels.size():
		var s := t - start - lane * 0.12
		var key := "wave%d" % lane
		if s >= 0 and s < 3.0:
			if lane == 0:
				prop(key, &"wave", Vector2(x - s * 640, 1000))
			else:
				# Sem apoio contínuo: brasas no ar, sem pedras ou pedaços de piso.
				prop(key, &"air_wave", Vector2(x - s * 640, levels[lane] - 32))
		elif s >= 3.0:
			hide_prop(key)


func _grab_tick(t: float) -> void:
	if args.size() < 2:
		return
	var target_y := float(args[2]) if args.size() > 2 else 1000.0
	var goal := Vector2(clampf(float(args[1]), 24, 1520), target_y - 230)
	_hand = (AnvilMasterBoss.HOME + Vector2(-150, -300)).lerp(goal, clampf(t / 0.8, 0, 1))
	var hand := prop("grip_hand", &"grip_hand", _hand)
	hand.active = false
	boss.grip.global_position = _hand - Vector2(-150, -300)
	warning("grab", Vector2(goal.x, target_y), minf(t / 0.9, 1.0), 140)
	queue_redraw()
	actor.pose(&"walk", 5 if t < 0.9 else (7 if _released else 6))
	if t >= 0.9 and not _decided and boss.is_brain():
		_decided = true
		var target := _player(String(args[0]))
		if target != null and not target.player_health.is_downed and not target.is_dashing() \
				and absf(target.global_position.x - float(args[1])) < 150 and absf(target.global_position.y - target_y) < 80:
			_event(["hold", String(target.name)])
		else:
			_event(["release", false])
	if not _held.is_empty() and not _released:
		var target := _player(_held)
		if target != null:
			target.boss_hold = _hand + Vector2(0, 60)
		boss.grip.set_deferred("monitorable", true)
		if boss.is_brain():
			if boss.alive_players().size() < 2:
				_event(["release", false])
			elif t >= 3.9:
				_event(["release", true])


func hit_grip(source: String) -> void:
	if _held.is_empty() or _released or source == _held:
		return
	_hits += 1
	if _hits >= 8:
		_event(["release", false])


func _event(data: Array) -> void:
	_on_event(data)
	boss.sync.send_attack_event(name, run_seed, data)


func _on_event(data: Array) -> void:
	if data[0] == "hold" and not _released:
		_held = data[1]
	elif data[0] == "release" and not _released:
		var target := _player(_held)
		_released = true
		if target != null:
			target.boss_hold = Vector2.INF
			target.player_health.protect(0.5)
			if data[1] and target.is_multiplayer_authority():
				target.player_health.hurt_by(1, actor.global_position)
		boss.grip.set_deferred("monitorable", false)


func _player(player_name: String) -> Player:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if String(player.name) == player_name:
			return player
	return null


func _stop() -> void:
	boss.set_chest(false)
	boss.grip.set_deferred("monitorable", false)
	boss.grip.position = Vector2.ZERO
	actor.position = AnvilMasterBoss.HOME
	var target := _player(_held)
	if target != null:
		target.boss_hold = Vector2.INF
	if pattern == Pattern.HAMMER and not boss.is_defeated:
		boss.get_parent().get_node("Anvil").show()


func _is_done() -> bool:
	var durations := [4.4, 5.9, 5.3, 4.2, 3.7, 4.3, 4.6, 5.1, 5.8, 1.5, 1.5]
	return elapsed >= durations[pattern]


func _draw() -> void:
	if pattern == Pattern.SPIN and is_running() and _props.has("hammer"):
		var head: PaintedProp = _props["hammer"]
		var hand := to_local(actor.global_position + Vector2(0, -180))
		var tip := to_local(head.global_position)
		draw_line(hand, tip, Color("1b1410"), 14, true)
		draw_line(hand, tip, Color("785030"), 8, true)
	elif pattern == Pattern.GRIP and is_running():
		var start := to_local(actor.global_position + Vector2(-150, -300))
		var tip := to_local(_hand)
		var length := start.distance_to(tip)
		for i in int(length / 26):
			var at := start.lerp(tip, float(i) * 26 / maxf(length, 1))
			draw_ellipse_link(at)


func draw_ellipse_link(at: Vector2) -> void:
	draw_arc(at, 12, 0, TAU, 12, Color("171713"), 8, true)
	draw_arc(at, 12, 0, TAU, 12, Color("a09070"), 3, true)
