class_name TamerBoss
extends BossBrain
## O Domador e Leopoldo. A parte genérica (fases, saco de ataques, dano, rede) fica no
## BossBrain; aqui ficam só as listas de ataques e o que é deste chefão.
## Três fases (docs/bosses.md): "O Número Ensaiado", "Fora de Controle" e "O Leão de Fogo".

var _pounce_turn := 0

@onready var tamer: Tamer = $Tamer
@onready var lion: TamerLion = $Lion


func _init() -> void:
	phase_shares = [0.4, 0.35, 0.25]
	phase_titles = ["O Número Ensaiado", "Fora de Controle!", "O Leão de Fogo!"]
	phase_attacks = [
		[&"WhipCrack", &"FireRings", &"Roar", &"Lap"],
		[&"Charge", &"Pounce", &"Chase"],
		[&"Hops", &"FallingRings", &"Charge"],
	]
	phase_intros = [&"", &"IntroOutOfControl", &"IntroFire"]
	# A Patada pode vir duas vezes seguidas (um jogador de cada vez).
	repeatable = [&"Pounce"]


func _ready() -> void:
	super()
	connect_hurtbox($Tamer/Hurtbox, tamer)
	connect_hurtbox($Lion/HurtboxFront, lion)
	connect_hurtbox($Lion/HurtboxBack, lion)


func _physics_process(delta: float) -> void:
	super(delta)
	# Nas fases 2 e 3 o domador estala o chicote de medo no pedestal (fora das trocas de fase).
	var intro := _current != null and _current.is_running() and _current.name in phase_intros
	tamer.fear_lashes = phase >= 1 and not is_defeated and not intro


## Dados que só o host sabe (posição atual do leão, jogadores) e os dois PCs precisam.
func _args_for(attack_name: StringName) -> Array:
	var at := lion.global_position
	match attack_name:
		&"Charge":
			return [at.x]
		&"Pounce":
			return [at.x, at.y, _pounce_target_x()]
		&"Chase":
			# Isca: quem bateu mais no leão nos últimos segundos.
			return [at.x, most_dangerous_player()]
		&"Hops", &"IntroFire":
			return [at.x, at.y]
	return []


func _on_catch_up() -> void:
	tamer.whip_pose = 0.0
	tamer.flee_to(lion.home_position)
	if phase >= 2:
		lion.set_on_fire(true)


func _on_defeated() -> void:
	tamer.fear_lashes = false
	for hitbox: EnemyHitbox in [$Tamer/Hitbox, $Lion/Hitbox]:
		hitbox.active = false
	tamer.whip_pose = 0.0
	tamer.cowering = false
	# O domador, sem graça, tenta uma reverência para a plateia; o leão deita, cansado.
	tamer.create_tween().tween_property(tamer, "bow", 1.0, 0.6).set_delay(0.8)
	lion.lie_down()


## Patada: um jogador de cada vez.
func _pounce_target_x() -> float:
	var alive := alive_players()
	if alive.is_empty():
		return lion.global_position.x
	_pounce_turn += 1
	return alive[_pounce_turn % alive.size()].target_position().x
