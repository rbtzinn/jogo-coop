class_name DuoActs
extends Node
## Bônus em dupla da luta (docs/combat.md). O Fight cria este nó em toda luta.
## - Número Perfeito: os dois dão parry no MESMO objeto rosa com até 0,3 s de diferença.
##   Cada um ganha 2 estrelas (a de sempre + 1 de bônus).
## - Grande Número em Dupla: os dois soltam o Grande Número com até 1 s de diferença.
##   Sai a Torta de Ouro (DuoFinale), com dano extra: o total fica maior que a soma dos dois.
## Cada PC fica sabendo dos dois lados (o próprio na hora, o do parceiro quando a mensagem
## chega). Se em QUALQUER um dos PCs a diferença couber na janela, aquele PC declara o bônus e
## avisa o outro: favorável a quem joga, e os dois sempre concordam.

const PERFECT_WINDOW := EnemyHitbox.PARTNER_PARRY_WINDOW
const DUO_WINDOW := 1.0
## Depois de um Grande Número em Dupla, outro só conta passado este tempo (evita contar duas
## vezes quando os dois PCs declaram ao mesmo tempo).
const DUO_COOLDOWN := 3.0
const DUO_BONUS_DAMAGE := 120
const GOLD_FLASH := Color(1.0, 0.85, 0.4, 0.22)

## parry_id -> {"time", "players": Array[String], "at": Vector2, "perfect": bool}
var _parries := {}
## Grandes Números recentes: {"time", "player"}.
var _grand_numbers: Array[Dictionary] = []
var _last_duo := -INF


static func find(tree: SceneTree) -> DuoActs:
	return tree.get_first_node_in_group(&"duo_acts") as DuoActs


func _ready() -> void:
	add_to_group(&"duo_acts")


## Um jogador deu parry num objeto rosa (o deste PC na hora; o parceiro quando a mensagem chega).
func report_parry(parry_id: String, player: Player, at: Vector2) -> void:
	var now := _now()
	_forget_old_parries(now)
	var player_name := String(player.name)
	if not _parries.has(parry_id):
		_parries[parry_id] = {"time": now, "players": [player_name], "at": at, "perfect": false}
		return
	var entry: Dictionary = _parries[parry_id]
	if player_name in entry.players:
		return
	entry.players.append(player_name)
	if now - entry.time <= PERFECT_WINDOW:
		_perfect(parry_id)
		for peer_id in Network.ready_peers:
			_receive_perfect.rpc_id(peer_id, parry_id)


## Um jogador soltou o Grande Número (o deste PC na hora; o parceiro quando aparece na tela).
func report_grand_number(player: Player) -> void:
	var now := _now()
	_grand_numbers = _grand_numbers.filter(func(entry: Dictionary) -> bool: return now - entry.time <= DUO_WINDOW)
	var player_name := String(player.name)
	var paired := _grand_numbers.any(func(entry: Dictionary) -> bool: return entry.player != player_name)
	_grand_numbers.append({"time": now, "player": player_name})
	if paired and _duo():
		for peer_id in Network.ready_peers:
			_receive_duo.rpc_id(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _receive_perfect(parry_id: String) -> void:
	Network.deliver(_perfect.bind(parry_id), false)


@rpc("any_peer", "call_remote", "reliable")
func _receive_duo() -> void:
	Network.deliver(_duo, false)


## Número Perfeito: +1 estrela para cada jogador DESTE PC que participou (as estrelas são
## contadas no PC do dono) e a festa na tela.
func _perfect(parry_id: String) -> void:
	if not _parries.has(parry_id):
		return
	var entry: Dictionary = _parries[parry_id]
	if entry.perfect:
		return
	entry.perfect = true
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_multiplayer_authority() and String(player.name) in entry.players:
			player.applause.add_stars(1.0)
	ParryFlash.spawn_gold(entry.at, 1.8)
	CheerText.spawn(entry.at + Vector2(0, -130), "Número Perfeito!")
	ScreenFlash.spawn(GOLD_FLASH, 0.25)


## Grande Número em Dupla. Retorna falso se já tinha acontecido agora há pouco.
func _duo() -> bool:
	var now := _now()
	if now - _last_duo <= DUO_COOLDOWN:
		return false
	_last_duo = now
	CheerText.spawn(Vector2(960, 330), "Grande Número em Dupla!")
	ScreenFlash.spawn(Color(GOLD_FLASH, 0.3), 0.35)
	# Quem causa o dano é o "cérebro" da luta (host ou jogo sozinho): conta uma vez só.
	var is_brain := not Network.is_online() or Network.is_host()
	DuoFinale.spawn(_pair_center(), DUO_BONUS_DAMAGE, is_brain)
	return true


## Ponto entre os dois jogadores, um pouco acima (de onde sai a Torta de Ouro).
func _pair_center() -> Vector2:
	var players := get_tree().get_nodes_in_group(&"players")
	if players.is_empty():
		return Vector2(400, 600)
	var sum := Vector2.ZERO
	for player: Player in players:
		sum += player.global_position
	return sum / players.size() + Vector2(0, -220)


func _forget_old_parries(now: float) -> void:
	for parry_id in _parries.keys():
		if now - _parries[parry_id].time > 5.0:
			_parries.erase(parry_id)


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
