class_name PlayerLoadout
extends Node
## Equipamento do jogador (docs/shop.md), lido do save quando ele nasce na fase:
## Pistola, Truque, Adereço e Número de dupla. Os dois PCs leem o mesmo save (o cliente
## recebe a cópia do host antes de carregar a fase), então cada um sabe o equipamento dos dois.
## Os efeitos ficam em quem usa: PlayerGun (pistola), Player (truque, números de dupla),
## PlayerHealth, PlayerParry e PlayerApplause (adereços).

var gun := "cork_gun"
var trick := "tumble"
var prop := ""
var duo := ""
## Vida de cada um no modo de teste ("Testar sozinho"), para ver todas as fases dos chefões.
const TEST_HEALTH := 99

@onready var _player: Player = owner


## Lê o equipamento do personagem deste jogador e aplica os adereços.
func load_from_save() -> void:
	var players: Dictionary = SaveGame.data.get("players", {})
	var equipped: Dictionary = players.get(Shop.key_for(_player), {}).get("equipped", {})
	gun = equipped.get("gun", "cork_gun")
	trick = equipped.get("trick", "tumble")
	prop = equipped.get("prop", "")
	duo = equipped.get("duo", "")
	_apply_prop()
	if SaveGame.test_mode:
		_player.player_health.health.maximum = TEST_HEALTH
		_player.player_health.health.current = TEST_HEALTH


func has(item_id: String) -> bool:
	return item_id in [gun, trick, prop, duo]


## Equipamento do outro jogador (para os números de dupla e a Rede de Segurança).
static func of(player: Player) -> PlayerLoadout:
	return player.loadout


func _apply_prop() -> void:
	match prop:
		"cloth_heart":
			# +1 de vida; o tiro causa 5% menos dano.
			_player.player_health.health.maximum += 1
			_player.player_health.health.current = _player.player_health.health.maximum
			_player.gun.damage_scale = 0.95
		"honk_nose":
			_player.player_health.shield_hits = 1
		"mime_gloves":
			_player.parry.window = PlayerParry.WINDOW * 1.5
		"spring_shoes":
			_player.jump_height *= 1.15
		"lucky_clover":
			_player.applause.gain = 1.25
