class_name AnvilMasterBoss
extends BossBrain
## Mestre Bigorna: forja, canais, Braço de Ferro e armadura. Decisões de dano/grab são do host.

const HOME := Vector2(1710, 1000)
var stage_clock := 0.0
var chest: Hurtbox
var grip: Hurtbox
@onready var actor: PaintedBossActor = $Actor


func _init() -> void:
	max_health = 1550
	pause_between_attacks = Vector2(0.2, 0.44)
	phase_shares = [0.35, 0.35, 0.3]
	phase_titles = ["Malhando o Ferro", "Forja Aberta!", "Armadura Recém-Forjada!"]
	phase_attacks = [[&"Hammer", &"Horseshoes", &"Bellows"],
		[&"Channel", &"SmallAnvils", &"IronGrip"], [&"SpinHammer", &"Stomp", &"OpenChest"]]
	phase_intros = [&"", &"IntroForge", &"IntroArmor"]


func _ready() -> void:
	super()
	z_index = 2
	actor.position = HOME
	actor.right_edge = 1908.0
	chest = actor.add_target("Chest", Vector2(-15, -225), Vector2(125, 150))
	grip = actor.add_target("Grip", Vector2(-150, -300), Vector2(150, 130))
	connect_hurtbox(actor.hurtbox, actor)
	connect_hurtbox(chest, actor, "chest")
	connect_hurtbox(grip, actor, "grip")
	var clock := BossStageClock.new()
	clock.name = "StageClock"
	add_child(clock)


func _physics_process(delta: float) -> void:
	stage_clock += delta
	actor.hitbox.active = phase > 0 and not is_defeated
	super(delta)


func _args_for(attack_name: StringName) -> Array:
	if attack_name == &"IronGrip":
		var players := alive_players()
		if players.size() < 2:
			return []
		var player: Player = players[_brain_rng.randi_range(0, players.size() - 1)]
		return [String(player.name), clampf(player.global_position.x, 24, 1520), player.global_position.y]
	if attack_name in [&"SmallAnvils", &"Stomp"]:
		var targets: Array = []
		for player in alive_players():
			targets.append(clampf(player.global_position.x, 24, 1520))
		while targets.size() < 4:
			targets.append(_brain_rng.randf_range(40, 1510))
		return targets
	return []


func _can_choose(attack_name: StringName) -> bool:
	return attack_name != &"IronGrip" or alive_players().size() >= 2


func apply_damage(amount: int, source := "", part := "") -> void:
	if part == "grip":
		if _current != null and _current.is_running() and _current.has_method(&"hit_grip"):
			_current.call(&"hit_grip", source)
		return
	super(amount * (2 if part == "chest" and actor.chest_open else 1), source, part)


func set_chest(open: bool) -> void:
	actor.chest_open = open
	chest.set_deferred("monitorable", open)
	# A armadura leva tiro normal (até 08/10/2026 só o peito aberto levava, e parecia que ele não tomava dano);
	# o peito aberto, grande e luminoso, leva dano dobrado: atacar na hora certa acelera a luta.
	actor.hurtbox.set_deferred("monitorable", not open and not is_defeated)


func set_stage(index: int) -> void:
	get_parent().get_node("BackgroundHot").visible = index == 2
	get_parent().get_node("Anvil").visible = index == 0
	# Ele fica parado entre ataques. A caminhada só aparece quando uma ação realmente a usa;
	# repetir o ciclo andando no mesmo ponto fazia o personagem parecer travado.
	actor.idle_animation = &"idle" if index < 2 else &"armor"
	actor.idle_frames = PackedInt32Array([0, 1, 2, 3] if index < 2 else [1, 2])
	actor.idle()
	actor.hurtbox.set_deferred("monitorable", not is_defeated)


func _on_catch_up() -> void:
	actor.position = HOME
	set_stage(phase)
	actor.reset_physics_interpolation()


func _on_defeated() -> void:
	set_chest(false)
	actor.hurtbox.set_deferred("monitorable", false)
	grip.set_deferred("monitorable", false)
	actor.hitbox.active = false
	get_parent().get_node("Anvil").hide()
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(actor.pose.bind(&"defeat", i))
		tween.tween_interval(0.55)


func prop_kinds() -> Dictionary:
	return {
		&"shoe": {"frames": ["shoe_1", "shoe_2", "shoe_3", "shoe_4"], "scale": 0.55, "fps": 12.0, "circle": 34.0, "anchor": "center"},
		&"shoe_parry": {"frames": ["shoe_parry_1", "shoe_parry_2", "shoe_parry_3", "shoe_parry_4"], "scale": 0.55, "fps": 12.0, "circle": 34.0, "anchor": "center"},
		&"anvil": {"frames": ["small_anvil_1", "small_anvil_2", "small_anvil_3", "small_anvil_4"], "scale": 0.65, "fps": 10.0, "rect": Vector2(100, 90), "anchor": "center"},
		&"hammer": {"frames": ["hammer_head"], "scale": 0.7, "fps": 0.0, "circle": 58.0, "anchor": "center"},
		&"rock": {"frames": ["rock_1", "rock_2"], "scale": 0.6, "fps": 8.0, "circle": 40.0, "anchor": "center"},
		&"spark": {"frames": ["spark_1", "spark_2", "spark_3", "spark_4"], "scale": 0.28, "fps": 10.0, "circle": 20.0, "anchor": "center"},
		&"ember": {"frames": ["ember_1", "ember_2", "ember_3", "ember_4"], "scale": 0.32, "fps": 10.0, "circle": 24.0, "anchor": "center"},
		&"wave": {"frames": ["wave_1", "wave_2", "wave_3", "wave_4"], "scale": 0.5, "fps": 10.0, "rect": Vector2(170, 64), "at": Vector2(0, -32), "anchor": "bottom"},
		&"air_wave": {"frames": ["ember_1", "ember_2", "ember_3", "ember_4"], "scale": 0.72, "draw_size": Vector2(170, 64), "fps": 10.0, "rect": Vector2(170, 64), "anchor": "center"},
		&"channel": {"frames": ["channel_1", "channel_2"], "scale": 0.42, "fps": 0.0, "rect": Vector2(590, 38), "at": Vector2(0, -19), "anchor": "bottom"},
		&"platform_heat": {"frames": ["ember_1", "ember_2", "ember_3", "ember_4"], "scale": 0.32, "fps": 10.0, "rect": Vector2(280, 38), "at": Vector2(0, -19), "anchor": "bottom"},
		&"grip_hand": {"frames": ["walk_7"], "region": Rect2(70, 7, 115, 125), "scale": 1.0, "fps": 0.0, "circle": 1.0, "anchor": "center"},
	}
