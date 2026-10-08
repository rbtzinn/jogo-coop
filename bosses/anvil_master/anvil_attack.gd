extends PaintedAttack
## Padrões da forja, calculados pelo tempo do ataque; o host só arbitra a mão que agarra.
enum Pattern { HAMMER, SHOES, BELLOWS, CHANNEL, ANVILS, GRIP, SPIN, STOMP, CHEST, INTRO_FORGE, INTRO_ARMOR }
@export var pattern := Pattern.HAMMER

const GRIP_WINDUP_END := 0.34
## Giro e pisão: a partir daqui ele fica cansado com o peito aberto até o fim do ataque.
const TIRED_FROM := 3.5
const GRIP_CAST_END := 0.95
## Segurando: puxa o boneco (REEL), gira ele no alto da corrente (WHIRL) e bate no chão (SLAM).
const GRIP_REEL := 0.45
const GRIP_WHIRL := 1.2
const GRIP_SLAM := 0.22
const GRIP_RADIUS := 170.0
## Golpes do parceiro na mão que soltam o preso.
const GRIP_FREE_HITS := 6
const GRIP_RETRACT_TIME := 0.45
const GRIP_CUFF_OFFSET := Vector2(0, -90)

var _from := Vector2.ZERO
var _side := 0
var _channel := 0
var _held := ""
var _hits := 0
var _decided := false
var _released := false
var _hand := Vector2.ZERO
var _held_from := Vector2.ZERO
var _hold_at := INF
var _release_at := INF
var _release_from := Vector2.ZERO


func _start() -> void:
	_from = actor.global_position
	_side = rng.randi_range(0, 1)
	_channel = rng.randi_range(0, 2)
	_held = ""
	_hits = 0
	_decided = false
	_released = false
	_hand = _grip_origin()
	_held_from = Vector2.ZERO
	_hold_at = INF
	_release_at = INF
	_release_from = Vector2.ZERO


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
				# Um arremesso desenhado para cada uma das 4 bigorninhas (0,45 s cada); depois volta a ficar parado.
				var since := t - 0.4
				if since >= 0.0 and since < 4 * 0.45:
					actor.pose(&"throw", int(fposmod(since, 0.45) / 0.45 * 4.0))
			elif t >= TIRED_FROM:
				_tired()
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
			if t >= TIRED_FROM:
				hide_prop("hammer")
				_tired()
			elif t >= 0.9:
				var angle := (t - 0.9) * TAU * 0.75
				var head := prop("hammer", &"hammer", actor.global_position + Vector2(-140 + cos(angle) * 180, -180 + sin(angle) * 130) * actor.scale.x)
				head.spin = angle
				# O desenho do giro já traz o martelo e o rastro de fogo: o martelo solto só machuca (sem aparecer
				# por cima, que dava três martelos na tela).
				head.visible = false
			_waves(t, 1.2, actor.global_position.x - 140)
		Pattern.CHEST:
			actor.pose(&"armor", 6 if t < 2.2 else 2)
			boss.set_chest(t >= 0.5 and t < 2.2)
			_waves(t, 2.3, actor.global_position.x)
		Pattern.GRIP:
			_grab_tick(t)
		Pattern.INTRO_FORGE:
			boss.set_stage(1)
			actor.pose(&"idle", int(t * 5) % 4)
		Pattern.INTRO_ARMOR:
			boss.set_stage(2)
			actor.pose(&"armor", 0 if t < 0.9 else 1)


## Parado no lugar trabalhando: o parado de sempre, no ritmo calmo (antes era o "andar" no lugar).
func _forge_pose(t: float, armored := false) -> void:
	actor.position = AnvilMasterBoss.HOME
	if armored:
		actor.pose(&"armor", 1 + int(t * 3) % 2)
	else:
		actor.idle()


## Fase 3: cansado depois do giro e do pisão, ele abre o peito por um instante (a hora de atacar). Antes o peito
## só abria no ataque próprio e a armadura parecia não levar dano nenhum.
func _tired() -> void:
	actor.pose(&"armor", 6)
	boss.set_chest(true)


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
	var target_origin := Vector2(clampf(float(args[1]), 24, 1520), target_y)
	var catch_point := target_origin + GRIP_CUFF_OFFSET
	var chain_start := _grip_origin()
	if t < GRIP_WINDUP_END:
		_hand = chain_start
	elif t < GRIP_CAST_END:
		var cast := ease(clampf((t - GRIP_WINDUP_END) / (GRIP_CAST_END - GRIP_WINDUP_END), 0, 1), -1.8)
		_hand = arc_point(chain_start, catch_point, 115, cast)
	elif _held.is_empty() and not _released:
		_hand = catch_point

	if t >= GRIP_CAST_END and not _decided and boss.is_brain():
		_decided = true
		var target := _player(String(args[0]))
		if target != null and not target.player_health.is_downed and not target.is_dashing() \
				and absf(target.global_position.x - float(args[1])) < 150 and absf(target.global_position.y - target_y) < 80:
			_event(["hold", String(target.name), t])
		else:
			_event(["release", false, t])
	if not _held.is_empty() and not _released:
		var target := _player(_held)
		if target != null:
			target.boss_hold = _held_point(t - _hold_at)
			_hand = target.boss_hold + GRIP_CUFF_OFFSET
			boss.grip.set_deferred("monitorable", true)
			if boss.is_brain():
				if boss.alive_players().size() < 2:
					_event(["release", false, t])
				elif t >= _hold_at + GRIP_REEL + GRIP_WHIRL + GRIP_SLAM:
					_event(["release", true, t])
	if _released:
		var retract := ease(clampf((t - _release_at) / GRIP_RETRACT_TIME, 0, 1), -1.8)
		_hand = _release_from.lerp(chain_start, retract)

	# Sequência própria: prepara a corrente, arremessa, fecha a mão e faz força enquanto segura.
	if t < GRIP_WINDUP_END:
		actor.pose(&"grip", 0)
	elif t < GRIP_CAST_END:
		actor.pose(&"grip", 1 if t < 0.55 else 2)
	elif not _held.is_empty() and not _released:
		# Fazendo força enquanto gira; no arremesso, o braço desce (quadro do lançamento).
		var slam := t - _hold_at >= GRIP_REEL + GRIP_WHIRL
		actor.pose(&"grip", 1 if slam else 3 + int((t - _hold_at) * 6.0) % 2)
	else:
		actor.pose(&"grip", 4)
	boss.grip.global_position = _hand - Vector2(-150, -300)
	warning("grab", target_origin, minf(t / GRIP_CAST_END, 1.0), 140)
	queue_redraw()


func hit_grip(source: String) -> void:
	if _held.is_empty() or _released or source == _held:
		return
	_hits += 1
	if _hits >= GRIP_FREE_HITS:
		_event(["release", false, elapsed])


func _event(data: Array) -> void:
	_on_event(data)
	boss.sync.send_attack_event(name, run_seed, data)


func _on_event(data: Array) -> void:
	if data[0] == "hold" and not _released:
		_held = data[1]
		_hold_at = float(data[2]) if data.size() > 2 else elapsed
		var target := _player(_held)
		if target != null:
			_held_from = target.global_position
			target.rig.set_boss_captured(true)
	elif data[0] == "release" and not _released:
		var target := _player(_held)
		_released = true
		_release_at = float(data[2]) if data.size() > 2 else elapsed
		_release_from = _hand
		if target != null:
			target.boss_hold = Vector2.INF
			target.rig.set_boss_captured(false)
			target.player_health.protect(0.5)
			if data[1]:
				# Esborrachado no chão: poeira e tremor no lugar da batida.
				Fx.spawn(preload("res://components/fx/dust_puff.tscn"), target.global_position)
				if target.is_multiplayer_authority():
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
		target.rig.set_boss_captured(false)
	if pattern == Pattern.HAMMER and not boss.is_defeated:
		boss.get_parent().get_node("Anvil").show()


func _is_done() -> bool:
	var durations := [4.4, 5.9, 5.3, 4.2, 3.7, 4.7, 4.6, 5.1, 5.8, 1.5, 1.5]
	return elapsed >= durations[pattern]


func _draw() -> void:
	if pattern == Pattern.SPIN and is_running() and _props.has("hammer"):
		var head: PaintedProp = _props["hammer"]
		var hand := to_local(actor.global_position + Vector2(0, -180) * actor.scale.x)
		var tip := to_local(head.global_position)
		draw_line(hand, tip, Color("1b1410"), 14, true)
		draw_line(hand, tip, Color("785030"), 8, true)
	elif pattern == Pattern.GRIP and is_running():
		var start := to_local(_grip_origin())
		var tip := to_local(_hand)
		_draw_chain(start, tip)
		_draw_cuff(tip)


func _grip_origin() -> Vector2:
	return actor.global_position + Vector2(-150, -300) * actor.scale.x


## Onde o preso está `s` segundos depois de laçado: puxado em arco até a frente do Bigorna, girado no alto
## (a corrente esticada) e jogado no chão. Mesma conta nos dois PCs (sai só do tempo).
func _held_point(s: float) -> Vector2:
	var center := actor.global_position + Vector2(-430, -430)
	var start := center + Vector2(-GRIP_RADIUS, 0)
	if s < GRIP_REEL:
		return arc_point(_held_from, start, 90, ease(s / GRIP_REEL, -1.8))
	var turns := 1.5
	if s < GRIP_REEL + GRIP_WHIRL:
		# Acelera o giro (começa devagar, termina rápido).
		var u := pow((s - GRIP_REEL) / GRIP_WHIRL, 1.4)
		var angle := PI + u * TAU * turns
		return center + Vector2(cos(angle), sin(angle)) * GRIP_RADIUS
	var top := center + Vector2(cos(PI + TAU * turns), sin(PI + TAU * turns)) * GRIP_RADIUS
	var floor_at := Vector2(clampf(center.x - 260, 60, 1500), 1000)
	return top.lerp(floor_at, pow(clampf((s - GRIP_REEL - GRIP_WHIRL) / GRIP_SLAM, 0, 1), 2))


func _draw_chain(start: Vector2, tip: Vector2) -> void:
	var length := start.distance_to(tip)
	if length < 3:
		return
	var links := maxi(int(length / 25), 1)
	var sag := minf(length * (0.025 if not _held.is_empty() and not _released else 0.07), 52.0)
	for i in links + 1:
		var u := float(i) / links
		var at := start.lerp(tip, u) + Vector2(0, sin(u * PI) * sag)
		draw_ellipse_link(at)


func _draw_cuff(at: Vector2) -> void:
	# A algema fica por cima do personagem (IronGrip tem z_index maior), deixando claro o acerto.
	draw_circle(at, 22, Color("171713"))
	draw_arc(at, 20, 0, TAU, 20, Color("a09070"), 7, true)
	draw_arc(at, 15, 0, TAU, 20, Color("3f3428"), 3, true)
	draw_line(at + Vector2(-25, -8), at + Vector2(-13, -17), Color("d8c39a"), 5, true)
	draw_line(at + Vector2(25, -8), at + Vector2(13, -17), Color("d8c39a"), 5, true)


func draw_ellipse_link(at: Vector2) -> void:
	draw_arc(at, 12, 0, TAU, 12, Color("171713"), 8, true)
	draw_arc(at, 12, 0, TAU, 12, Color("a09070"), 3, true)
