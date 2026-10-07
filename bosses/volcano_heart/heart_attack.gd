extends PaintedAttack
## O coração fica na direita; batidas, ecos e projeções ameaçam todos os níveis da arena.
enum Pattern { PULSE, ARTERIES, DROPS, CROWN, FEATHERS, SHOES, FAN, CHARGE, INTRO_SEALS, INTRO_ERUPTION }
@export var pattern := Pattern.PULSE


func _start() -> void:
	if pattern == Pattern.INTRO_SEALS:
		boss.set_stage(1)
	elif pattern == Pattern.INTRO_ERUPTION:
		boss.stage_clock = 0.0
		boss.set_stage(2)


func _tick(t: float) -> void:
	actor.position = VolcanoHeartBoss.HOME
	actor.facing = -1
	match pattern:
		Pattern.PULSE:
			var times := [0.9, 2.0, 2.85, 3.55]
			actor.pose(&"beat", 0)
			for i in times.size():
				var s: float = t - times[i]
				if s > -0.5 and s < 0:
					actor.pose(&"beat", 1)
				elif s >= 0 and s < 0.3:
					actor.pose(&"beat", 2)
				var levels := surface_levels()
				for lane in levels.size():
					var key := "ring%d:%d" % [i, lane]
					if s >= 0 and s < 2.7:
						prop(key, &"ring", Vector2(actor.global_position.x - s * 720, levels[lane]))
					elif s >= 2.7:
						hide_prop(key)
		Pattern.ARTERIES:
			actor.pose(&"beat", 1 if t < 1.0 else 3)
			for i in 3:
				var x: float = float(args[i]) if args.size() > i else 60 + i * 700
				var start := 1.0 + i * 0.4
				warning("artery%d" % i, Vector2(x, 1000), clampf(t / start, 0, 1), 65)
				var artery := prop("artery%d" % i, &"artery", Vector2(x, 160))
				artery.active = false
				artery.frame = 1 if t < start else 3
				if t >= start and t < start + 1.4:
					var jet := prop("jet%d" % i, &"jet", Vector2(x, 620))
					jet._sprite.scale.y = 760.0 / jet._sprite.texture.get_height()
				elif t >= start + 1.4:
					hide_prop("jet%d" % i)
		Pattern.DROPS:
			actor.pose(&"beat", 3)
			for i in 5:
				var s := t - 0.65 - i * 0.3
				var x: float = float(args[i]) if args.size() > i else 40 + i * 355
				warning("drop%d" % i, Vector2(x, 1000), clampf(t / (0.65 + i * 0.3), 0, 1), 40)
				if s >= 0 and s < 2.0:
					prop("drop%d" % i, &"drop_parry" if i == 2 else &"ball", Vector2(x, 100 + s * 470), i == 2)
				elif s >= 2.0:
					hide_prop("drop%d" % i)
		Pattern.CROWN:
			actor.pose(&"echo", 0 if t < 0.8 else 1)
			var s := t - 0.8
			if s >= 0 and s < 3.2:
				var u := s / 3.2
				var x := lerpf(actor.global_position.x - 160, -120, 1 - absf(u * 2 - 1))
				prop("crown", &"echo_crown", Vector2(x, 940 - absf(sin(u * TAU)) * 270))
		Pattern.FEATHERS:
			actor.pose(&"echo", 0 if t < 0.8 else 2)
			for i in 7:
				if i == run_seed % 7:
					continue
				var s := t - 0.8 - i * 0.05
				var x := 40 + i * 235
				warning("feather%d" % i, Vector2(x, 1000), clampf(t / (0.8 + i * 0.05), 0, 1), 40)
				if s >= 0 and s < 2.6:
					prop("feather%d" % i, &"echo_feather", Vector2(x + sin(s * 4) * 35, -60 + s * 440))
				elif s >= 2.6:
					hide_prop("feather%d" % i)
		Pattern.SHOES:
			actor.pose(&"echo", 0 if t < 0.8 else 3)
			var levels := surface_levels()
			for lane in levels.size():
				for i in 4:
					var s := t - 0.8 - i * 0.32 - lane * 0.12
					var key := "shoe%d:%d" % [lane, i]
					if s >= 0 and s < 3.8:
						prop(key, &"echo_shoe", Vector2(actor.global_position.x - s * 570, levels[lane] - 50 - absf(sin(s * 7 + i * PI / 4)) * 170))
					elif s >= 3.8:
						hide_prop(key)
		Pattern.FAN:
			actor.pose(&"free", 4 if t < 0.8 else 3)
			var levels := surface_levels()
			for wave in 2:
				for lane in levels.size():
					var from := Vector2(actor.global_position.x - 140, levels[lane] - 100)
					warning("fan%d:%d" % [wave, lane], Vector2(from.x, levels[lane]), clampf(t / (0.8 + wave * 1.0 + lane * 0.1), 0, 1), 65)
					for i in 3:
						var s := t - 0.8 - wave * 1.0 - lane * 0.1
						var key := "ball%d:%d:%d" % [wave, lane, i]
						if s >= 0 and s < 3.0:
							var velocity := Vector2(-640, (i - 1) * 65)
							prop(key, &"ball", from + velocity * s)
						elif s >= 3.0:
							hide_prop(key)
		Pattern.CHARGE:
			actor.pose(&"free", 4 if t < 0.85 else (3 if t < 3.5 else 7))
			var levels := surface_levels()
			for lane in levels.size():
				var s := t - 0.85 - lane * 0.18
				var key := "surge%d" % lane
				var y := levels[lane] - 80
				warning(key, Vector2(1480, levels[lane]), clampf(t / (0.85 + lane * 0.18), 0, 1), 70)
				if s >= 0 and s < 2.7:
					var surge := prop(key, &"surge", Vector2(actor.global_position.x - 100 - s * 680, y))
					surge._sprite.modulate = Color(1.3, 0.7, 0.4, 0.85)
				elif s >= 2.7:
					hide_prop(key)
		Pattern.INTRO_SEALS:
			actor.pose(&"echo", 0)
		Pattern.INTRO_ERUPTION:
			boss.stage_clock = t
			actor.pose(&"free", 0 if t < 0.8 else 1)


func _stop() -> void:
	actor.hitbox.active = false
	if pattern == Pattern.CHARGE:
		actor.position = VolcanoHeartBoss.HOME


func _is_done() -> bool:
	return elapsed >= [6.4, 4.1, 4.1, 4.2, 3.8, 5.8, 5.3, 4.2, 1.5, 1.8][pattern]
