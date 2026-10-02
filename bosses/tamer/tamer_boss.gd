class_name TamerBoss
extends Node2D
## O Domador e Leopoldo. O host (ou o jogo sozinho) é o "cérebro": escolhe o próximo
## ataque (e os dados dele, como onde cair ou quem perseguir) e manda pelo BossSync;
## os dois PCs simulam o ataque do mesmo jeito.
## Três fases (docs/bosses.md): "O Número Ensaiado", "Fora de Controle" e "O Leão de Fogo".

signal defeated
## Uma fase nova começou (0, 1 ou 2), com o nome para o letreiro.
signal phase_started(phase: int, title: String)

## Parte da vida de cada fase, como em docs/bosses.md.
const PHASE_SHARES := [0.4, 0.35, 0.25]
const PHASE_TITLES := ["O Número Ensaiado", "Fora de Controle!", "O Leão de Fogo!"]
## Ataques de cada fase (nomes dos nós em Attacks).
const PHASE_ATTACKS := [
	[&"WhipCrack", &"FireRings", &"Roar", &"Lap"],
	[&"Charge", &"Pounce", &"Chase"],
	[&"Hops", &"FallingRings", &"Charge"],
]
## Animação de troca para a fase 1 e 2 (índice = fase nova).
const PHASE_INTROS := [&"", &"IntroOutOfControl", &"IntroFire"]
## A Patada pode vir duas vezes seguidas (um jogador de cada vez).
const REPEATABLE := [&"Pounce"]
## Quanto tempo o "quem bateu mais" lembra (segundos).
const DAMAGE_MEMORY := 4.0

@export var max_health := 1500
## Respiro entre um ataque e outro (mínimo e máximo, segundos).
@export var pause_between_attacks := Vector2(0.35, 0.7)
## Tempo antes do primeiro ataque.
@export var intro_time := 2.5

var phase := 0
var is_defeated := false

var _current: BossAttack
var _wait := 0.0
var _last_attack := &""
var _repeats := 0
var _pounce_turn := 0
var _brain_rng := RandomNumberGenerator.new()
## "Saco embaralhado" de ataques da fase: ordem aleatória, mas todos aparecem antes de repetir.
var _bag: Array[StringName] = []
## Dano recente de cada jogador (para a Isca).
var _recent_damage := {}

@onready var health: Health = $Health
@onready var sync: BossSync = $BossSync
@onready var tamer: Tamer = $Tamer
@onready var lion: TamerLion = $Lion


func _ready() -> void:
	health.maximum = max_health
	health.current = max_health
	health.changed.connect(_on_health_changed)
	_wait = intro_time
	_brain_rng.randomize()
	for attack: BossAttack in $Attacks.get_children():
		attack.finished.connect(_on_attack_finished)
	for hurtbox: Hurtbox in [$Tamer/Hurtbox, $Lion/HurtboxFront, $Lion/HurtboxBack]:
		hurtbox.hit.connect(_on_hurtbox_hit.bind(hurtbox.get_parent()))


func _physics_process(delta: float) -> void:
	for source in _recent_damage:
		_recent_damage[source] *= exp(-delta / DAMAGE_MEMORY)
	if is_defeated or not is_brain():
		return
	# Online, só começa quando o parceiro carregou a fase.
	if Network.is_online() and Network.ready_peers.is_empty():
		return
	if _current != null and _current.is_running():
		return
	_wait -= delta
	if _wait <= 0.0:
		_choose_attack()


## Quem decide os ataques, a vida e a vitória: o host, ou este PC quando é jogo sozinho.
func is_brain() -> bool:
	return not Network.is_online() or Network.is_host()


## Chamado nos dois PCs (pelo BossSync) quando um ataque começa.
func play_attack(attack_name: StringName, seed_value: int, skip: float, args: Array = []) -> void:
	if is_defeated:
		return
	if _current != null:
		_current.cancel()
	var intro_phase := PHASE_INTROS.find(attack_name)
	if intro_phase > 0 and intro_phase != phase:
		phase = intro_phase
		phase_started.emit(phase, PHASE_TITLES[phase])
	_current = $Attacks.get_node(NodePath(attack_name))
	_current.begin(seed_value, skip, args)


## Dano que chegou de um tiro (deste PC ou, no host, do parceiro).
func apply_damage(amount: int, source := "") -> void:
	if is_defeated:
		return
	if not source.is_empty():
		_recent_damage[source] = _recent_damage.get(source, 0.0) + amount
	health.damage(amount)


## Vida que ainda sobra quando a fase atual termina.
func phase_end_health() -> int:
	var spent := 0.0
	for i in phase + 1:
		spent += PHASE_SHARES[i]
	return roundi(max_health * (1.0 - spent))


## Vida restante (1 = cheia, 0 = vencido).
func bar_ratio() -> float:
	return health.ratio()


## Onde cada fase nova começa na barra de vida (de 1 a 0).
func phase_markers() -> Array[float]:
	var markers: Array[float] = []
	var spent := 0.0
	for i in PHASE_SHARES.size() - 1:
		spent += PHASE_SHARES[i]
		markers.append(1.0 - spent)
	return markers


## Cliente que entrou (ou voltou) no meio da luta: pula direto para a fase atual, sem a
## animação de troca (o host continua mandando os ataques da fase certa).
func catch_up(new_phase: int) -> void:
	if new_phase <= phase or new_phase >= PHASE_SHARES.size():
		return
	phase = new_phase
	if _current != null:
		_current.cancel()
	tamer.whip_pose = 0.0
	tamer.flee_to(lion.home_position)
	if phase >= 2:
		lion.set_on_fire(true)


## Fim da luta. No cliente, chega pela rede.
func defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	if _current != null:
		_current.cancel()
	for hitbox: EnemyHitbox in [$Tamer/Hitbox, $Lion/Hitbox]:
		hitbox.active = false
	tamer.whip_pose = 0.0
	tamer.cowering = false
	# O domador, sem graça, tenta uma reverência para a plateia; o leão deita, cansado.
	tamer.create_tween().tween_property(tamer, "bow", 1.0, 0.6).set_delay(0.8)
	lion.lie_down()
	if is_brain():
		sync.send_defeat()
	defeated.emit()


func _choose_attack() -> void:
	var choice: StringName
	if _last_attack in REPEATABLE and _repeats == 0 and _brain_rng.randf() < 0.5:
		choice = _last_attack
	else:
		choice = _draw_from_bag()
	_repeats = _repeats + 1 if choice == _last_attack else 0
	sync.start_attack(choice, _brain_rng.randi(), _args_for(choice))


func _draw_from_bag() -> StringName:
	var pool: Array = PHASE_ATTACKS[phase]
	_bag = _bag.filter(func(attack_name: StringName) -> bool: return attack_name in pool)
	if _bag.is_empty():
		for attack_name: StringName in pool:
			_bag.append(attack_name)
		for i in range(_bag.size() - 1, 0, -1):
			var j := _brain_rng.randi_range(0, i)
			var swap := _bag[i]
			_bag[i] = _bag[j]
			_bag[j] = swap
		# Não começa o saco novo com o mesmo ataque que acabou de acontecer.
		if _bag[0] == _last_attack and _bag.size() > 1:
			_bag.append(_bag.pop_front())
	return _bag.pop_front()


## Dados que só o host sabe (posição atual do leão, jogadores) e os dois PCs precisam.
func _args_for(attack_name: StringName) -> Array:
	var at := lion.global_position
	match attack_name:
		&"Charge":
			return [at.x]
		&"Pounce":
			return [at.x, at.y, _pounce_target_x()]
		&"Chase":
			return [at.x, _most_dangerous_player()]
		&"Hops", &"IntroFire":
			return [at.x, at.y]
	return []


func _alive_players() -> Array[Player]:
	var alive: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.player_health.is_downed:
			alive.append(player)
	return alive


## Patada: um jogador de cada vez.
func _pounce_target_x() -> float:
	var alive := _alive_players()
	if alive.is_empty():
		return lion.global_position.x
	_pounce_turn += 1
	return alive[_pounce_turn % alive.size()].global_position.x


## Isca: quem bateu mais no leão nos últimos segundos.
func _most_dangerous_player() -> String:
	var alive := _alive_players()
	if alive.is_empty():
		return ""
	var best: Player = alive[_brain_rng.randi() % alive.size()]
	var best_damage := -1.0
	for player in alive:
		var amount: float = _recent_damage.get(String(player.name), 0.0)
		if amount > best_damage + 0.5:
			best = player
			best_damage = amount
	return String(best.name)


func _on_attack_finished() -> void:
	_wait = _brain_rng.randf_range(pause_between_attacks.x, pause_between_attacks.y)


func _on_hurtbox_hit(amount: int, source: String, part: Node) -> void:
	part.flash()
	if is_defeated:
		return
	if is_brain():
		apply_damage(amount, source)
	else:
		sync.report_damage(amount, source)


func _on_health_changed(current: int, _maximum: int) -> void:
	if not is_brain():
		return
	sync.send_health(current)
	if current <= 0:
		defeat()
	elif current <= phase_end_health() and phase + 1 < PHASE_SHARES.size():
		# Troca de fase: corta o ataque atual e toca a animação da fase nova.
		var intro: StringName = PHASE_INTROS[phase + 1]
		sync.start_attack(intro, _brain_rng.randi(), _args_for(intro))
		_last_attack = intro
		_wait = 0.3
