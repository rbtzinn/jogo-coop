class_name BossBrain
extends Node2D
## Base de todo chefão: fases pela vida, ataques num "saco embaralhado", dano, vitória e rede.
## O host (ou o jogo sozinho) é o "cérebro": escolhe o próximo ataque (e os dados dele, como
## onde cair ou quem perseguir) e manda pelo BossSync; os dois PCs simulam o ataque igual.
## Cada chefão herda daqui e preenche, no `_init()`, as listas de fases, e sobrescreve o que
## for só dele (`_args_for`, `_on_defeated`, `_on_catch_up`).
## Filhos esperados: Health, BossSync e Attacks (cada ataque é um BossAttack com o nome usado
## nas listas).

signal defeated
## Uma fase nova começou (0, 1, 2...), com o nome para o letreiro.
signal phase_started(phase: int, title: String)

## Quanto tempo o "quem bateu mais" lembra (segundos).
const DAMAGE_MEMORY := 4.0
## Só um atirando: cada tiro no chefão vale por dois (pedidos do usuário em 04/10/2026). Vale no "Testar
## sozinho" e online quando o parceiro está caído ou saiu; com os dois de pé, vale 1.
const SOLO_DAMAGE := 2

@export var max_health := 1500
## Respiro entre um ataque e outro (mínimo e máximo, segundos).
@export var pause_between_attacks := Vector2(0.35, 0.7)
## Tempo antes do primeiro ataque.
@export var intro_time := 2.5

## Parte da vida de cada fase (soma 1).
var phase_shares: Array = [1.0]
## Nome de cada fase (letreiro).
var phase_titles: Array = [""]
## Ataques de cada fase (nomes dos nós em Attacks).
var phase_attacks: Array = [[]]
## Animação de troca para cada fase (índice = fase nova; a 0 não tem).
var phase_intros: Array = [&""]
## Ataques que podem vir duas vezes seguidas.
var repeatable: Array = []

var phase := 0
var is_defeated := false

var _current: BossAttack
var _wait := 0.0
var _last_attack := &""
var _repeats := 0
var _brain_rng := RandomNumberGenerator.new()
## "Saco embaralhado" de ataques da fase: ordem aleatória, mas todos aparecem antes de repetir.
var _bag: Array[StringName] = []
## Dano recente de cada jogador (para ataques que caçam quem bate mais).
var _recent_damage := {}

@onready var health: Health = $Health
@onready var sync: BossSync = $BossSync


func _ready() -> void:
	health.maximum = max_health
	health.current = max_health
	health.changed.connect(_on_health_changed)
	_wait = intro_time
	_brain_rng.randomize()
	for attack: BossAttack in $Attacks.get_children():
		attack.finished.connect(_on_attack_finished)


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


## Liga uma parte que leva tiro ao chefão. `part`: nome da parte (para chefões com várias vidas).
func connect_hurtbox(hurtbox: Hurtbox, flash_target: Node, part := "") -> void:
	hurtbox.hit.connect(_on_hurtbox_hit.bind(flash_target, part))


## Chamado nos dois PCs (pelo BossSync) quando um ataque começa.
func play_attack(attack_name: StringName, seed_value: int, skip: float, args: Array = []) -> void:
	if is_defeated:
		return
	if _current != null:
		_current.cancel()
	var intro_phase := phase_intros.find(attack_name)
	if intro_phase > 0 and intro_phase != phase:
		phase = intro_phase
		phase_started.emit(phase, phase_titles[phase])
	_current = $Attacks.get_node(NodePath(attack_name))
	_current.begin(seed_value, skip, args)


## Dado que o host decidiu no meio de um ataque (chega pelo BossSync no cliente; no host, o ataque já usou).
func attack_event(attack_name: StringName, run_seed: int, data: Array) -> void:
	var attack := $Attacks.get_node_or_null(NodePath(attack_name)) as BossAttack
	if attack != null:
		attack.receive_event(run_seed, data)


## Quanto vale cada tiro dos jogadores agora: SOLO_DAMAGE com um só atirando, 1 com os dois de pé.
func damage_scale() -> int:
	if not Network.is_online() or alive_players().size() <= 1:
		return SOLO_DAMAGE
	return 1


## Tiro de um jogador no chefão (deste PC ou, no host, do parceiro), já com o `damage_scale`. Só no cérebro.
func apply_shot(amount: int, source := "", part := "") -> void:
	apply_damage(amount * damage_scale(), source, part)


## Dano que chegou de um tiro (deste PC ou, no host, do parceiro). Só no cérebro.
func apply_damage(amount: int, source := "", _part := "") -> void:
	if is_defeated:
		return
	if not source.is_empty():
		_recent_damage[source] = _recent_damage.get(source, 0.0) + amount
	health.damage(amount)


## Vida que ainda sobra quando a fase atual termina.
func phase_end_health() -> int:
	var spent := 0.0
	for i in phase + 1:
		spent += phase_shares[i]
	return roundi(max_health * (1.0 - spent))


## Vida restante (1 = cheia, 0 = vencido).
func bar_ratio() -> float:
	return health.ratio()


## Onde cada fase nova começa na barra de vida (de 1 a 0).
func phase_markers() -> Array[float]:
	var markers: Array[float] = []
	var spent := 0.0
	for i in phase_shares.size() - 1:
		spent += phase_shares[i]
		markers.append(1.0 - spent)
	return markers


## Cliente que entrou (ou voltou) no meio da luta: pula direto para a fase atual, sem a
## animação de troca (o host continua mandando os ataques da fase certa).
func catch_up(new_phase: int) -> void:
	if new_phase <= phase or new_phase >= phase_shares.size():
		return
	phase = new_phase
	if _current != null:
		_current.cancel()
	_on_catch_up()


## Fim da luta. No cliente, chega pela rede.
func defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	if _current != null:
		_current.cancel()
	_on_defeated()
	if is_brain():
		sync.send_defeat()
	defeated.emit()


func alive_players() -> Array[Player]:
	var alive: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.player_health.is_downed:
			alive.append(player)
	return alive


## Quem bateu mais no chefão nos últimos segundos (nome do jogador; "" se ninguém de pé).
func most_dangerous_player() -> String:
	var alive := alive_players()
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


# --- Para cada chefão sobrescrever ---

## Dados que só o host sabe (posições atuais, jogadores) e os dois PCs precisam.
func _args_for(_attack_name: StringName) -> Array:
	return []


## Visual do fim da luta (desligar hitboxes, pose de derrota).
func _on_defeated() -> void:
	pass


## O ataque pode sair agora? (ex.: um malabarista tonto não troca de lugar). Só no cérebro.
func _can_choose(_attack_name: StringName) -> bool:
	return true


## Visual de quem pulou direto para a fase atual.
func _on_catch_up() -> void:
	pass


# --- Interno ---

func _choose_attack() -> void:
	var choice: StringName
	if _last_attack in repeatable and _repeats == 0 and _brain_rng.randf() < 0.5 and _can_choose(_last_attack):
		choice = _last_attack
	else:
		choice = _draw_from_bag()
		# Um ataque que não serve agora volta para o fim do saco e sai o próximo.
		for i in phase_attacks[phase].size():
			if _can_choose(choice):
				break
			_bag.append(choice)
			choice = _draw_from_bag()
	_repeats = _repeats + 1 if choice == _last_attack else 0
	_last_attack = choice
	sync.start_attack(choice, _brain_rng.randi(), _args_for(choice))


func _draw_from_bag() -> StringName:
	var pool: Array = phase_attacks[phase]
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


func _on_attack_finished() -> void:
	_wait = _brain_rng.randf_range(pause_between_attacks.x, pause_between_attacks.y)


func _on_hurtbox_hit(amount: int, source: String, flash_target: Node, part: String) -> void:
	if flash_target != null and flash_target.has_method(&"flash"):
		flash_target.flash()
	if is_defeated:
		return
	if is_brain():
		apply_shot(amount, source, part)
	else:
		sync.report_damage(amount, source, part)


func _on_health_changed(current: int, _maximum: int) -> void:
	if not is_brain():
		return
	sync.send_health(current)
	if current <= 0:
		defeat()
	elif current <= phase_end_health() and phase + 1 < phase_shares.size():
		# Troca de fase: corta o ataque atual e toca a animação da fase nova.
		var intro: StringName = phase_intros[phase + 1]
		sync.start_attack(intro, _brain_rng.randi(), _args_for(intro))
		_last_attack = intro
		_wait = 0.3
