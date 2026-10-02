class_name TamerBoss
extends Node2D
## O Domador e Leopoldo. O host (ou o jogo sozinho) é o "cérebro": escolhe o próximo
## ataque e manda pelo BossSync; os dois PCs simulam o ataque do mesmo jeito.
## Por enquanto só a fase 1 ("O Número Ensaiado") existe; acabar com ela vence a luta.

signal defeated

## Parte da vida de cada fase (fase 1, 2, 3), como em docs/bosses.md.
const PHASE_SHARES := [0.4, 0.35, 0.25]
## Fases já construídas. Quando a última delas acaba, a luta está ganha.
const IMPLEMENTED_PHASES := 1

@export var max_health := 1500
## Respiro entre um ataque e outro (mínimo e máximo, segundos).
@export var pause_between_attacks := Vector2(0.9, 1.5)
## Tempo antes do primeiro ataque.
@export var intro_time := 2.5

var phase := 0
var is_defeated := false

var _current: BossAttack
var _wait := 0.0
var _last_attack := -1
var _brain_rng := RandomNumberGenerator.new()

@onready var health: Health = $Health
@onready var sync: BossSync = $BossSync
@onready var tamer: Tamer = $Tamer
@onready var lion: TamerLion = $Lion
@onready var attacks: Array[BossAttack] = [$Attacks/WhipCrack, $Attacks/FireRings, $Attacks/Roar]


func _ready() -> void:
	health.maximum = max_health
	health.current = max_health
	health.changed.connect(_on_health_changed)
	_wait = intro_time
	_brain_rng.randomize()
	for attack in attacks:
		attack.finished.connect(_on_attack_finished)
	for hurtbox: Hurtbox in [$Tamer/Hurtbox, $Lion/Hurtbox]:
		hurtbox.hit.connect(_on_hurtbox_hit.bind(hurtbox.get_parent()))


func _physics_process(delta: float) -> void:
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
func play_attack(index: int, seed_value: int, skip: float) -> void:
	if is_defeated:
		return
	if _current != null:
		_current.cancel()
	_last_attack = index
	_current = attacks[index]
	_current.begin(seed_value, skip)


## Dano que chegou de um tiro (deste PC ou, no host, do parceiro).
func apply_damage(amount: int) -> void:
	if not is_defeated:
		health.damage(amount)


## Vida que ainda sobra quando a fase atual termina.
func phase_end_health() -> int:
	var spent := 0.0
	for i in phase + 1:
		spent += PHASE_SHARES[i]
	return roundi(max_health * (1.0 - spent))


## Quanto falta para vencer (1 = começo, 0 = vencido), contando só as fases já construídas.
func bar_ratio() -> float:
	var spent := 0.0
	for i in IMPLEMENTED_PHASES:
		spent += PHASE_SHARES[i]
	var end_health := max_health * (1.0 - spent)
	return clampf((health.current - end_health) / (max_health - end_health), 0.0, 1.0)


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
	lion.go_home()
	if is_brain():
		sync.send_defeat()
	defeated.emit()


func _choose_attack() -> void:
	var options: Array[int] = []
	for i in attacks.size():
		if i != _last_attack:
			options.append(i)
	sync.start_attack(options[_brain_rng.randi() % options.size()], _brain_rng.randi())


func _on_attack_finished() -> void:
	_wait = _brain_rng.randf_range(pause_between_attacks.x, pause_between_attacks.y)


func _on_hurtbox_hit(amount: int, part: Node) -> void:
	part.flash()
	if is_defeated:
		return
	if is_brain():
		apply_damage(amount)
	else:
		sync.report_damage(amount)


func _on_health_changed(current: int, _maximum: int) -> void:
	if not is_brain():
		return
	sync.send_health(current)
	if current <= phase_end_health():
		if phase + 1 < IMPLEMENTED_PHASES:
			phase += 1
		else:
			defeat()
