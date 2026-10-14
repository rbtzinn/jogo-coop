class_name MadameCarretelBoss
extends BossBrain
const HOME := Vector2(1530,930)
const FLOOR := 930.0
const PLAY_LEFT := 27.0
const PLAY_RIGHT := 1473.0
var started := false
@onready var actor: CarretelActor = $Actor

func _init() -> void:
	max_health = 1250
	pause_between_attacks = Vector2(0.24,0.42)
	phase_shares = [0.34,0.33,0.33]
	phase_titles = ["Tirando as Medidas", "Prova de Roupa", "Manequim de Guerra"]
	phase_attacks = [[&"Needles",&"Scissors",&"Tape"],
		[&"Needles",&"Curtains",&"Tape"],[&"Needles",&"Buttons",&"Scissors",&"Curtains"]]
	phase_intros = [&"",&"IntroCloth",&"IntroArmor"]

func _ready() -> void:
	super()
	z_index = 2
	actor.position = HOME
	connect_hurtbox(actor.hurtbox,actor)
	connect_hurtbox(actor.head,actor)
	for target in actor.buttons: connect_hurtbox(target,actor,"button")

func _physics_process(delta: float) -> void:
	actor.hitbox.active = started and not is_defeated
	super(delta)

func play_attack(attack_name: StringName,seed_value: int,skip: float,extra: Array = []) -> void:
	started = true
	super(attack_name,seed_value,skip,extra)

func _args_for(_attack_name: StringName) -> Array:
	var players := alive_players()
	players.sort_custom(func(a: Player,b: Player) -> bool: return a.slot<b.slot)
	var targets: Array = []
	for player in players:
		# Trava o alvo no aviso, nunca persegue sem aviso depois do disparo.
		targets.append(Vector2(clampf(player.global_position.x,PLAY_LEFT,PLAY_RIGHT),
			clampf(player.global_position.y-55.0,180.0,FLOOR-35.0)))
	return targets

func set_stage(index: int) -> void:
	actor.armored = index==2
	actor.set_weak(false)
	actor.idle()

func apply_damage(amount: int,source := "",part := "") -> void:
	super(amount*(2 if part=="button" and actor.weak_open else 1),source,part)

func _on_catch_up() -> void:
	actor.position = HOME
	set_stage(phase)

func _on_defeated() -> void:
	actor.defeated = true
	actor.hitbox.active = false
	actor.set_weak(false)
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(actor.pose.bind(&"defeat",i))
		tween.tween_interval(0.5)
