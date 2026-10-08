extends PaintedAttack
## O coração fica num lado da arena (começa na direita); batidas, ecos e projeções correm para o outro lado e
## ameaçam todos os níveis. Na Travessia (CROSS) ele pulsa (aviso), atravessa a arena pelo alto soltando gotas
## de lava onde os jogadores estavam (sombras no chão antes) e passa a atacar do outro lado.
enum Pattern { PULSE, ARTERIES, DROPS, CROWN, FEATHERS, SHOES, FAN, CHARGE, INTRO_SEALS, INTRO_ERUPTION, CROSS }
@export var pattern := Pattern.PULSE

## Travessia: aviso pulsando, viagem pelo alto, altura do arco e queda de cada gota.
const CROSS_WIND := 0.9
const CROSS_TRAVEL := 1.6
const CROSS_ARC := 280.0
const CROSS_DROP := 0.55
## Giro da bola de fogo (desenhada indo para a esquerda) para ela cair de cabeça para baixo.
const BALL_DOWN := -PI / 2


func _start() -> void:
	if pattern == Pattern.INTRO_SEALS:
		boss.set_stage(1)
	elif pattern == Pattern.INTRO_ERUPTION:
		boss.stage_clock = 0.0
		boss.set_stage(2)


func _tick(t: float) -> void:
	# Para onde os ataques correm: para a esquerda com ele na direita, para a direita com ele na esquerda.
	var d: float = boss.toward()
	if pattern != Pattern.CROSS:
		actor.position = boss.home()
		actor.facing = int(d)
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
						prop(key, &"ring", Vector2(actor.global_position.x + d * s * 720, levels[lane]))
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
					var drop := prop("drop%d" % i, &"drop_parry" if i == 2 else &"ball", Vector2(x, 100 + s * 470), i == 2)
					# A bola de fogo é desenhada indo para a esquerda: gira para cair de cabeça para baixo.
					drop.spin = 0.0 if i == 2 else BALL_DOWN
				elif s >= 2.0:
					hide_prop("drop%d" % i)
		Pattern.CROWN:
			actor.pose(&"echo", 0 if t < 0.8 else 1)
			var s := t - 0.8
			if s >= 0 and s < 3.2:
				var u := s / 3.2
				var far := -120.0 if d < 0 else 2040.0
				var x := lerpf(actor.global_position.x + d * 160, far, 1 - absf(u * 2 - 1))
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
					var feather := prop("feather%d" % i, &"echo_feather", Vector2(x + sin(s * 4) * 35, -60 + s * 440))
					# O desenho é uma pena deitada na diagonal (ponta para cima e para a esquerda): gira para cair de
					# ponta para baixo, balançando um pouco.
					# Só o primeiro quadro: o segundo é desenhado em outro ângulo e, girado igual, ficava de lado.
					feather.hold_frame = 0
					feather.spin = -2.1 + sin(s * 4) * 0.15
				elif s >= 2.6:
					hide_prop("feather%d" % i)
		Pattern.SHOES:
			actor.pose(&"echo", 0 if t < 0.8 else 3)
			var levels := surface_levels()
			# Três ferraduras quicando em arcos altos e iguais, bem separadas: passar por baixo do arco (com dash)
			# ou pular quando ela desce. Antes eram quatro coladas, cada uma num tempo de
			# quique diferente, e não dava para desviar (relato do usuário, 08/10/2026).
			for lane in levels.size():
				for i in 3:
					var s := t - 0.8 - i * 0.7 - lane * 0.12
					var key := "shoe%d:%d" % [lane, i]
					if s >= 0 and s < 3.8:
						var shoe := prop(key, &"echo_shoe", Vector2(actor.global_position.x + d * s * 500, levels[lane] - 40 - absf(sin(s * 3.5)) * 280))
						shoe.flip = d > 0
					elif s >= 3.8:
						hide_prop(key)
		Pattern.FAN:
			actor.pose(&"free", 4 if t < 0.8 else 3)
			var levels := surface_levels()
			for wave in 2:
				for lane in levels.size():
					var from := Vector2(actor.global_position.x + d * 140, levels[lane] - 100)
					warning("fan%d:%d" % [wave, lane], Vector2(from.x, levels[lane]), clampf(t / (0.8 + wave * 1.0 + lane * 0.1), 0, 1), 65)
					for i in 3:
						var s := t - 0.8 - wave * 1.0 - lane * 0.1
						var key := "ball%d:%d:%d" % [wave, lane, i]
						if s >= 0 and s < 3.0:
							var velocity := Vector2(640 * d, (i - 1) * 65)
							var ball := prop(key, &"ball", from + velocity * s)
							ball.flip = d > 0
						elif s >= 3.0:
							hide_prop(key)
		Pattern.CHARGE:
			actor.pose(&"free", 4 if t < 0.85 else (3 if t < 3.5 else 7))
			var levels := surface_levels()
			for lane in levels.size():
				var s := t - 0.85 - lane * 0.18
				var key := "surge%d" % lane
				var y := levels[lane] - 80
				warning(key, Vector2(actor.global_position.x + d * 200, levels[lane]), clampf(t / (0.85 + lane * 0.18), 0, 1), 70)
				if s >= 0 and s < 2.7:
					var surge := prop(key, &"surge", Vector2(actor.global_position.x + d * (100 + s * 680), y))
					surge._sprite.modulate = Color(1.3, 0.7, 0.4, 0.85)
					surge.flip = d > 0
				elif s >= 2.7:
					hide_prop(key)
		Pattern.CROSS:
			_cross(t)
		Pattern.INTRO_SEALS:
			actor.pose(&"echo", 0)
		Pattern.INTRO_ERUPTION:
			boss.stage_clock = t
			actor.pose(&"free", 0 if t < 0.8 else 1)


## Travessia: pulsa no lugar enquanto as sombras das gotas aparecem; depois voa em arco pelo alto até o outro
## lado (o corpo machuca quem pular nele) e solta cada gota quando passa por cima da sombra dela.
func _cross(t: float) -> void:
	var from: Vector2 = boss.home()
	var to: Vector2 = VolcanoHeartBoss.HOME_LEFT if boss.side > 0 else VolcanoHeartBoss.HOME
	var idle := &"free" if boss.phase >= 2 else &"beat"
	if t < CROSS_WIND:
		actor.position = from
		actor.facing = int(boss.toward())
		actor.pose(&"beat", 1 + int(t * 8.0) % 2)
	elif t < CROSS_WIND + CROSS_TRAVEL:
		var u := (t - CROSS_WIND) / CROSS_TRAVEL
		actor.position = Vector2(lerpf(from.x, to.x, u), from.y - sin(u * PI) * CROSS_ARC)
		actor.facing = int(signf(to.x - from.x))
		actor.pose(idle, 3 if idle == &"free" else 2)
		actor.hitbox.active = true
	else:
		actor.position = to
		actor.facing = int(signf(from.x - to.x))
		actor.pose(idle, 1)
		actor.hitbox.active = false
	for i in args.size():
		var x := float(args[i])
		# Quando o coração passa por cima da sombra (ele anda em linha reta no x).
		var u := clampf((x - from.x) / (to.x - from.x), 0.0, 1.0)
		var release := CROSS_WIND + u * CROSS_TRAVEL
		var key := "cross%d" % i
		warning(key, Vector2(x, 1000), clampf(t / (release + CROSS_DROP), 0, 1), 55, true)
		var s := t - release
		if s >= 0 and s < CROSS_DROP:
			var top := from.y - sin(u * PI) * CROSS_ARC + 120
			var ball := prop(key, &"ball", Vector2(x, lerpf(top, 975, pow(s / CROSS_DROP, 2))))
			ball.spin = BALL_DOWN
		elif s >= CROSS_DROP:
			hide_prop(key)


func _stop() -> void:
	actor.hitbox.active = false
	# Passou do aviso: chega do outro lado (nos dois PCs, sem mensagem a mais).
	if pattern == Pattern.CROSS and elapsed >= CROSS_WIND:
		boss.side = -boss.side
	if pattern in [Pattern.CHARGE, Pattern.CROSS]:
		actor.position = boss.home()
		actor.facing = int(boss.toward())
		actor.reset_physics_interpolation()


func _is_done() -> bool:
	return elapsed >= [6.4, 4.1, 4.1, 4.2, 3.8, 6.2, 5.3, 4.2, 1.5, 1.8, 2.9][pattern]
