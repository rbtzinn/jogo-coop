class_name VolcanoHeartBoss
extends BossBrain
## Final do Vulcão. O host arbitra as válvulas; cada PC resolve a queda do seu jogador na lava.
const HOME := Vector2(1680, 540)
## Onde ele fica depois da Travessia para a esquerda.
const HOME_LEFT := Vector2(240, 540)
## Dano dos tiros com a máscara aberta (só aí ele leva dano na fase dos selos).
const OPEN_DAMAGE := 3
const VALVES := [400.0, 1420.0]
## Válvulas (ideia do usuário, 08/10/2026): pisou, ela trava acesa por VALVE_LATCH; com as duas acesas ao mesmo
## tempo a máscara abre por OPEN_TIME, depois fecha sozinha e as duas apagam (pisar de novo). Sozinho dá tempo de
## acender uma e correr até a outra.
const VALVE_LATCH := 4.0
const OPEN_TIME := 5.0

var stage_clock := 0.0
## Lado da arena em que ele está: 1 direita, -1 esquerda (troca na Travessia, nos dois PCs).
var side := 1
var _clock := 0.0
var _open_until := -1.0
var _cooldown_until := -1.0
var _pressed_until: Array[float] = [-1.0, -1.0]
var valve_charge := 0.0
var valve_pressed := [false, false]
var _send_timer := 0.0
var _valve_sprites: Array[Sprite2D] = []
var _seals: Array[Sprite2D] = []
var _open_mask := Sprite2D.new()
var _valve_anim: FrameAnimation
var _mask_anim: FrameAnimation
@onready var actor: PaintedBossActor = $Actor


func _init() -> void:
	max_health = 1650
	pause_between_attacks = Vector2(0.2, 0.44)
	phase_shares = [0.35, 0.35, 0.3]
	phase_titles = ["Batimento", "Os Três Selos!", "Erupção!"]
	phase_attacks = [[&"Pulse", &"Arteries", &"TurquoiseDrops"],
		[&"EchoCrown", &"EchoFeathers", &"EchoHorseshoes", &"Cross"], [&"MagmaFan", &"Charge", &"Cross"]]
	phase_intros = [&"", &"IntroSeals", &"IntroEruption"]


func _ready() -> void:
	super()
	z_index = 2
	actor.position = HOME
	actor.right_edge = 1908.0
	actor.left_edge = 12.0
	actor.hitbox.active = false
	connect_hurtbox(actor.hurtbox, actor, "mask")
	_valve_anim = load(actor.art_folder + "valve.tres")
	_mask_anim = load(actor.art_folder + "mask.tres")
	for x in VALVES:
		var sprite := Sprite2D.new()
		# Em pé no chão, na frente do fundo e atrás dos jogadores (que ficam em z 3). Antes ficava em y = 1072,
		# quase toda abaixo da tela e embaixo do ingresso: não dava para ver que era para pisar nela.
		sprite.position = Vector2(x, 942)
		sprite.z_index = 1
		get_parent().add_child.call_deferred(sprite)
		_valve_sprites.append(sprite)
	for i in 3:
		var sprite := Sprite2D.new()
		sprite.texture = load(actor.art_folder + "seal_%d.png" % (i + 1))
		sprite.z_index = 1
		sprite.scale = Vector2.ONE * 0.15
		sprite.position = [Vector2(962, 350), Vector2(830, 575), Vector2(1100, 575)][i]
		get_parent().add_child.call_deferred(sprite)
		_seals.append(sprite)
	actor._holder.add_child(_open_mask)
	_open_mask.position = Vector2(-65, 20)
	Network.peer_ready.connect(_send_stage)
	var clock := BossStageClock.new()
	clock.name = "StageClock"
	add_child(clock)
	set_stage.call_deferred(0)


func _physics_process(delta: float) -> void:
	_clock += delta
	stage_clock += delta
	if phase == 1 and not is_defeated and is_brain():
		_tick_valves(delta)
	if phase == 2 and not is_defeated:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.is_multiplayer_authority() and not player.player_health.is_downed and player.global_position.y > 950:
				rescue(player, true)
	if is_brain() and phase == 1:
		_send_timer -= delta
		if _send_timer <= 0.0:
			_send_timer = 0.15
			for peer_id in Network.ready_peers:
				_receive_valves.rpc_id(peer_id, valve_pressed, valve_charge, maxf(_open_until - _clock, 0))
	super(delta)


func _process(_delta: float) -> void:
	for i in _valve_sprites.size():
		var sprite := _valve_sprites[i]
		_valve_anim.show_on(sprite, 1 if valve_pressed[i] else 0)
		sprite.scale = Vector2.ONE * 0.21
		sprite.visible = phase == 1 and not is_defeated
	for i in _seals.size():
		_seals[i].modulate = Color(1.3, 1.1, 0.9) if phase >= 1 else Color(0.5, 0.4, 0.4)
	_open_mask.visible = is_mask_open() and phase == 1 and not is_defeated
	if _open_mask.visible:
		_mask_anim.show_on(_open_mask, 3)
		_open_mask.scale = Vector2.ONE * _mask_anim.frame_scale


func _tick_valves(_delta: float) -> void:
	var waiting := not is_mask_open() and _clock >= _cooldown_until
	for player in alive_players():
		if not waiting or absf(player.global_position.y - 1000) > 14 or absf(player.velocity.y) > 30:
			continue
		for i in 2:
			if absf(player.global_position.x - VALVES[i]) < 90:
				_pressed_until[i] = _clock + VALVE_LATCH
	# Acesa = pisada há menos de VALVE_LATCH (ou a máscara está aberta).
	for i in 2:
		valve_pressed[i] = is_mask_open() or _pressed_until[i] > _clock
	# Quanto falta para a última acesa apagar (vai para o cliente junto).
	valve_charge = maxf(maxf(_pressed_until[0], _pressed_until[1]) - _clock, 0.0)
	if waiting and _pressed_until[0] > _clock and _pressed_until[1] > _clock:
		_open_until = _clock + OPEN_TIME
		_cooldown_until = _open_until + 1.0
		_pressed_until = [-1.0, -1.0]
		valve_charge = 0.0
		CheerText.spawn(actor.global_position + Vector2(0, -220), "Máscara aberta!", Color("ffcf6a"))


func is_mask_open() -> bool:
	return _open_until > _clock


func apply_damage(amount: int, source := "", part := "") -> void:
	# Na fase dos selos, a máscara de pedra realmente protege o coração. Abrir as válvulas cria uma janela
	# clara de dano dobrado; insistir em tiros contra a máscara fechada não substitui a mecânica.
	if phase == 1 and not is_mask_open():
		return
	super(amount * (OPEN_DAMAGE if phase == 1 else 1), source, part)


## Onde ele fica agora e para que lado os ataques dele correm (-1 para a esquerda quando está na direita).
func home() -> Vector2:
	return HOME if side > 0 else HOME_LEFT


func toward() -> float:
	return -float(side)


func _args_for(attack_name: StringName) -> Array:
	if attack_name in [&"Arteries", &"TurquoiseDrops", &"Cross"]:
		var count := 3 if attack_name == &"Arteries" else (4 if attack_name == &"Cross" else 5)
		var result: Array = []
		for player in alive_players():
			result.append(clampf(player.global_position.x, 24, 1520))
		while result.size() < count:
			result.append(_brain_rng.randf_range(40, 1510))
		return result
	return []


func platforms() -> Array[ClockPlatform]:
	var result: Array[ClockPlatform] = []
	for child in get_parent().get_children():
		if child is ClockPlatform:
			result.append(child)
	return result


func rescue(player: Player, penalty: bool) -> void:
	var choices := platforms()
	if choices.is_empty():
		return
	var nearest: ClockPlatform = choices[0]
	for platform in choices:
		if absf(platform.global_position.x - player.global_position.x) < absf(nearest.global_position.x - player.global_position.x):
			nearest = platform
	if penalty:
		player.player_health.hurt_by(1, Vector2(player.global_position.x, 1080))
	player.global_position = nearest.global_position + Vector2(0, -3)
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	player.player_health.protect(1.5)


func set_stage(index: int) -> void:
	get_parent().get_node("BackgroundHot").visible = index == 2
	get_parent().get_node("Floor/CollisionShape2D").set_deferred("disabled", index == 2)
	for platform in platforms():
		platform.set_enabled(index == 2)
	actor.idle_animation = &"free" if index == 2 else &"beat"
	actor.idle_frames = PackedInt32Array([1, 2] if index == 2 else [0, 1, 2, 3])
	actor.idle()
	actor.hitbox.active = false
	if index == 2:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.is_multiplayer_authority() and not player.player_health.is_downed and player.global_position.y > 900:
				rescue(player, false)


func _send_stage(peer_id: int) -> void:
	if Network.is_host():
		_receive_stage.rpc_id(peer_id, phase, stage_clock, side)


@rpc("authority", "call_remote", "reliable")
func _receive_stage(index: int, clock: float, from_side: int) -> void:
	Network.deliver(func() -> void:
		side = from_side
		catch_up(index)
		stage_clock = clock + sync._one_way_delay()
		set_stage(phase), false)


@rpc("authority", "call_remote", "reliable")
func _receive_valves(pressed: Array, charge: float, remaining: float) -> void:
	Network.deliver(func() -> void:
		valve_pressed = pressed
		valve_charge = charge
		_open_until = _clock + remaining, false)


func _on_catch_up() -> void:
	actor.position = home()
	actor.facing = int(toward())
	set_stage(phase)
	actor.reset_physics_interpolation()


func _on_defeated() -> void:
	actor.hitbox.active = false
	actor.hurtbox.set_deferred("monitorable", false)
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(actor.pose.bind(&"defeat", i))
		tween.tween_interval(0.55)
	# O caminho revelado é o gancho da próxima área, ainda sem uma cena jogável.
	CheerText.spawn(Vector2(960, 340), "O Festival do Fogo está livre!", Color("ffcf6a"))


func prop_kinds() -> Dictionary:
	return {
		# Ataques maiores e com contorno claro: no cenário de lava eles sumiam (pedido do usuário, 08/10/2026).
		&"_look": 1.15,
		&"ring": {"frames": ["ring_1", "ring_2", "ring_3", "ring_4"], "scale": 0.55, "fps": 12.0, "rect": Vector2(185, 58), "at": Vector2(0, -29), "anchor": "bottom"},
		&"ball": {"frames": ["ball_1", "ball_2", "ball_3", "ball_4"], "scale": 0.48, "fps": 12.0, "circle": 32.0, "anchor": "center"},
		&"drop_parry": {"frames": ["drop_parry_1", "drop_parry_2", "drop_parry_3", "drop_parry_4"], "scale": 0.48, "fps": 10.0, "circle": 28.0, "anchor": "center"},
		&"echo_crown": {"frames": ["echo_crown_1", "echo_crown_2"], "scale": 0.62, "fps": 12.0, "circle": 48.0, "anchor": "center"},
		&"echo_feather": {"frames": ["echo_feather_1", "echo_feather_2"], "scale": 0.5, "fps": 12.0, "circle": 28.0, "anchor": "center"},
		&"echo_shoe": {"frames": ["echo_shoe_1", "echo_shoe_2"], "scale": 0.58, "fps": 12.0, "circle": 34.0, "anchor": "center"},
		&"artery": {"frames": ["artery_1", "artery_2", "artery_3", "artery_4"], "scale": 0.65, "fps": 0.0, "circle": 1.0, "anchor": "center"},
		&"jet": {"frames": ["jet_1", "jet_2", "jet_3", "jet_4"], "scale": 0.58, "fps": 10.0, "rect": Vector2(82, 760), "anchor": "center"},
		&"surge": {"frames": ["free_6"], "scale": 0.45, "fps": 0.0, "rect": Vector2(190, 135), "anchor": "center"},
	}
