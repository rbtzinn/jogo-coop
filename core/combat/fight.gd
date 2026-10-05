class_name Fight
extends Node
## Uma luta contra chefão: anuncia o começo, percebe vitória (chefão vencido) ou derrota
## (todos os jogadores caídos) e mostra a tela de fim. Online, quem decide é o host.
## Também cria o DuoActs (bônus em dupla). Na vitória calcula a nota da dupla (FightGrade),
## registra no save (SaveGame) e manda o resultado para o cliente.

const END_SCREEN := preload("res://core/ui/fight_end_screen.gd")

## O chefão precisa ter o sinal `defeated`.
@export var boss_path: NodePath
@export var intro_text := "Que comece o espetáculo!"
## Identifica o chefão no save (vazio = não salva).
@export var boss_id := ""
## Tempo de uma luta bem jogada, em segundos (para a nota).
@export var target_time := 150.0

var _ended := false
## Duração da luta (conta a partir de quando os dois PCs estão prontos).
var _elapsed := 0.0

@onready var boss: Node = get_node(boss_path)


func _ready() -> void:
	# Bônus em dupla (Número Perfeito, Grande Número em Dupla). Nome fixo: as mensagens de rede
	# acham o nó pelo caminho, igual nos dois PCs.
	var duo_acts := DuoActs.new()
	duo_acts.name = "DuoActs"
	add_child(duo_acts)
	boss.defeated.connect(_on_boss_defeated)
	if boss.has_signal(&"phase_started"):
		boss.phase_started.connect(func(_phase: int, title: String) -> void: _show_banner(title))
	_show_banner(intro_text)


func _physics_process(delta: float) -> void:
	if not _ended and (not Network.is_online() or not Network.ready_peers.is_empty()):
		_elapsed += delta
	if _ended or (Network.is_online() and not Network.is_host()):
		return
	var players := get_tree().get_nodes_in_group(&"players")
	if players.is_empty():
		return
	for player: Player in players:
		if not player.player_health.is_downed:
			return
	_end(false)


func _end(victory: bool, result := {}) -> void:
	if _ended:
		return
	_ended = true
	if victory and result.is_empty() and (not Network.is_online() or Network.is_host()):
		result = _victory_result()
	# Ninguém mais se mexe (e os botões da tela de fim não são apertados sem querer).
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
	if Network.is_online() and Network.is_host():
		for peer_id in Network.ready_peers:
			_receive_end.rpc_id(peer_id, victory, result)
	_show_banner("Nocaute!" if victory else "", victory)
	get_tree().create_timer(2.3 if victory else 1.0).timeout.connect(_show_end_screen.bind(victory, result))


## Online, o cliente espera o host mandar o fim (com a nota), em vez de decidir sozinho.
func _on_boss_defeated() -> void:
	if Network.is_online() and not Network.is_host():
		return
	_end(true)


@rpc("authority", "call_remote", "reliable")
func _receive_end(victory: bool, result: Dictionary) -> void:
	Network.deliver(_end.bind(victory, result), false)


## Nota da dupla e o que mudou no save (só no host ou jogando sozinho).
func _victory_result() -> Dictionary:
	var health := 0
	var max_health := 0
	var parries := 0
	var stars_used := 0
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		max_health += player.player_health.health.maximum
		if not player.player_health.is_downed:
			health += player.player_health.health.current
		parries += player.applause.parries
		stars_used += player.applause.stars_used
	var result := FightGrade.compute(_elapsed, target_time, health, max_health, parries, stars_used)
	if not boss_id.is_empty():
		result.merge(SaveGame.record_victory(boss_id, result.grade, _elapsed))
	return result


func _show_end_screen(victory: bool, result: Dictionary) -> void:
	var screen: CanvasLayer = END_SCREEN.new()
	screen.victory = victory
	screen.result = result
	add_child(screen)


## Faixa de circo no meio da tela (ver CircusBanner.show_on).
func _show_banner(text: String, burst := false) -> void:
	CircusBanner.show_on(self, text, burst)
