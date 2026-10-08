class_name PhoenixBoss
extends BossBrain
## A Fênix das Cinzas (Área 2, docs/bosses.md). A parte genérica (fases, saco de ataques, dano, rede) fica no
## BossBrain; aqui ficam as listas de ataques, os dados que o host escolhe, o céu que muda a cada fase e a
## Casca Dupla da fase 3.
##
## Casca Dupla (momento de dupla): no ovo só as rachaduras levam tiro, uma de cada lado (o tiro da esquerda
## acerta a da esquerda). Cada rachadura que leva CRACK_HP de dano se ABRE por OPEN_TIME. Se a outra abrir
## nesse tempo, o ovo se ESTILHAÇA: para de atacar e leva o dobro de dano por STUN_TIME. Se o tempo acabar
## com uma só aberta, ela fecha e o ovo recupera HEAL_SHARE da vida da fase. Sozinho: abrir uma já estilhaça.
## Quem decide é o host (o dano chega nele); o estado vai para o cliente por `_receive_shell`.

const CRACK_HP := 45
const OPEN_TIME := 3.0
const STUN_TIME := 4.0
const STUN_DAMAGE := 2
const HEAL_SHARE := 0.3

## Fundo de cada fase (céu de cinzas na 2, ninho em brasa na 3); o da fase atual aparece por cima.
@export var stage_paths: Array[NodePath] = []

var _clock := 0.0
var _crack_damage: Array[int] = [0, 0]
## Até quando cada rachadura fica aberta (no relógio do chefão; -1 = fechada).
var _open_until: Array[float] = [-1.0, -1.0]
var _stun_until := -1.0

@onready var bird: Phoenix = $Phoenix


func _init() -> void:
	max_health = 1350
	pause_between_attacks = Vector2(0.22, 0.48)
	phase_shares = [0.35, 0.35, 0.3]
	phase_titles = ["Voo de Abertura", "Tempestade de Cinzas!", "Renascimento!"]
	phase_attacks = [
		[&"Dive", &"FeatherFan", &"Gust"],
		[&"Eggs", &"SparkRain", &"LowDive"],
		[&"Rings", &"EmberBurst", &"FeatherFall"],
	]
	phase_intros = [&"", &"IntroPerch", &"IntroEgg"]


func _ready() -> void:
	super()
	connect_hurtbox(bird.hurtbox, bird)
	connect_hurtbox(bird.crack_left, bird, "crack_l")
	connect_hurtbox(bird.crack_right, bird, "crack_r")
	bird.global_position = PhoenixAttack.HOME


func _physics_process(delta: float) -> void:
	_clock += delta
	if is_brain() and not is_defeated:
		for i in 2:
			# Abriu sozinha e o tempo acabou: fecha e o ovo se recupera.
			if _open_until[i] >= 0.0 and _clock > _open_until[i] and not is_stunned():
				_open_until[i] = -1.0
				_crack_damage[i] = 0
				var start := roundi(max_health * phase_shares[2])
				health.set_current(mini(health.current + roundi(start * HEAL_SHARE), start))
				_send_shell()
	bird.cracks_open = [_open_until[0] >= 0.0, _open_until[1] >= 0.0]
	bird.stunned = is_stunned()
	if is_stunned():
		# Estilhaçado: não ataca.
		_wait = maxf(_wait, 0.4)
	super(delta)


func is_stunned() -> bool:
	return _stun_until >= 0.0 and _clock < _stun_until


func _args_for(attack_name: StringName) -> Array:
	match attack_name:
		&"Eggs":
			return _targets(3)
		&"EmberBurst":
			return _targets(5)
	return []


## Tiro numa rachadura do ovo (no cérebro; o dano do cliente chega aqui pela rede).
func apply_damage(amount: int, source := "", part := "") -> void:
	if not part.begins_with("crack"):
		super(amount, source, part)
		return
	if is_defeated:
		return
	super(amount * (STUN_DAMAGE if is_stunned() else 1), source, part)
	if is_stunned() or is_defeated:
		return
	var i := 0 if part == "crack_l" else 1
	_crack_damage[i] += amount
	if _crack_damage[i] >= CRACK_HP and _open_until[i] < 0.0:
		_open_until[i] = _clock + OPEN_TIME
		# Sozinho, abrir uma já basta.
		if damage_scale() > 1:
			_open_until[1 - i] = _clock + OPEN_TIME
		if _open_until[1 - i] >= 0.0:
			_shatter()
		_send_shell()


## Fundo da fase `index`: os de cima aparecem por cima (com `animated`, devagar).
func set_stage(index: int, animated: bool) -> void:
	for i in stage_paths.size():
		var node := get_node_or_null(stage_paths[i]) as CanvasItem
		if node == null or i == 0:
			continue
		if i > index:
			node.hide()
			continue
		if node.visible and node.modulate.a >= 1.0:
			continue
		node.show()
		if animated and i == index:
			node.modulate.a = 0.0
			create_tween().tween_property(node, "modulate:a", 1.0, 1.4)
		else:
			node.modulate.a = 1.0


## Ovo novo: rachaduras fechadas.
func reset_shell() -> void:
	_crack_damage = [0, 0]
	_open_until = [-1.0, -1.0]
	_stun_until = -1.0


func _shatter() -> void:
	_stun_until = _clock + STUN_TIME
	_open_until = [-1.0, -1.0]
	_crack_damage = [0, 0]
	if _current != null and _current.is_running():
		_current.cancel()
	_wait = STUN_TIME + 0.3


func _send_shell() -> void:
	if not Network.is_online() or not Network.is_host():
		return
	var left := maxf(_open_until[0] - _clock, -1.0)
	var right := maxf(_open_until[1] - _clock, -1.0)
	var stun := maxf(_stun_until - _clock, -1.0)
	for peer_id in Network.ready_peers:
		_receive_shell.rpc_id(peer_id, left, right, stun)


## Cliente: estado da Casca Dupla que o host mandou (tempos que faltam; -1 = fechada / sem estilhaço).
@rpc("authority", "call_remote", "reliable")
func _receive_shell(left: float, right: float, stun: float) -> void:
	Network.deliver(_apply_shell.bind(left, right, stun), false)


func _apply_shell(left: float, right: float, stun: float) -> void:
	_open_until = [_clock + left if left >= 0.0 else -1.0, _clock + right if right >= 0.0 else -1.0]
	var was_stunned := is_stunned()
	_stun_until = _clock + stun if stun >= 0.0 else -1.0
	if is_stunned() and not was_stunned and _current != null and _current.is_running():
		_current.cancel()


func _on_catch_up() -> void:
	bird.idle()
	if phase == 1:
		bird.set_mode(Phoenix.Mode.PERCH)
		bird.global_position = PhoenixAttack.PERCH
	elif phase >= 2:
		bird.set_mode(Phoenix.Mode.EGG)
		bird.global_position = PhoenixAttack.EGG
	set_stage(phase, false)
	bird.reset_physics_interpolation()


func _on_defeated() -> void:
	bird.hitbox.active = false
	bird.shake = 0.0
	bird.stunned = false
	bird.cracks_open = [false, false]
	_open_until = [-1.0, -1.0]
	_stun_until = -1.0
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.wind = 0.0
	# O ovo racha, estoura e sai um pintinho cinzento que espirra cinza e foge.
	bird.set_mode(Phoenix.Mode.EGG)
	bird.facing = -1
	bird.global_position = PhoenixAttack.EGG
	bird.reset_physics_interpolation()
	bird.hurtbox.set_deferred("monitorable", false)
	bird.crack_left.set_deferred("monitorable", false)
	bird.crack_right.set_deferred("monitorable", false)
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(bird.pose.bind(&"defeat", i))
		tween.tween_interval(0.6)
	tween.tween_property(bird, "global_position:x", 1250.0, 1.2)


func _targets(count: int) -> Array:
	var targets: Array = []
	for player in alive_players():
		if targets.size() < count:
			targets.append(clampf(player.global_position.x + _brain_rng.randf_range(-50.0, 50.0), 90.0, 1420.0))
	while targets.size() < count:
		targets.append(_brain_rng.randf_range(120.0, 1400.0))
	return targets
