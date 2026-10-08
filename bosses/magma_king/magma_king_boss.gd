class_name MagmaKingBoss
extends BossBrain
## O Rei Magma (Área 2, docs/bosses.md). A parte genérica (fases, saco de ataques, dano, rede) fica no
## BossBrain; aqui ficam as listas de ataques, os dados que o host escolhe e o palco que esquenta na
## fase 3. Três fases: "Audiência Real" (no trono), "O Rei Desce do Trono" (no lago) e "Coroação
## Derretida" (magma puro na margem).

## Onde ele senta no trono (pés no degrau) e por onde anda no lago.
const THRONE_SPOT := Vector2(1615, 897)
const LAKE_X := Vector2(1180, 1720)
const DRIPS := 7

## Fundo e beira da margem da fase 3 (aparecem por cima dos da fase 1 na troca).
@export var hot_background_path: NodePath
@export var hot_lip_path: NodePath

@onready var king: MagmaKing = $King
@onready var heavy_crown: Node = $Attacks/HeavyCrown


func _init() -> void:
	max_health = 1350
	pause_between_attacks = Vector2(0.22, 0.48)
	phase_shares = [0.4, 0.35, 0.25]
	phase_titles = ["Audiência Real", "O Rei Desce do Trono!", "Coroação Derretida!"]
	phase_attacks = [
		[&"Spit", &"Scepter", &"CrownThrow"],
		[&"LavaWave", &"Drip", &"HeavyCrown"],
		[&"Jet", &"CrownOrbit", &"SpitFast"],
	]
	phase_intros = [&"", &"IntroLake", &"IntroMolten"]


func _ready() -> void:
	super()
	connect_hurtbox(king.hurtbox, king)
	king.global_position = THRONE_SPOT


## Dados que só o host sabe (onde estão os jogadores, para onde ele anda) e os dois PCs precisam.
## Fase 3 quase sem respiro entre os ataques (era a fase mais fácil, com menos vida).
func _on_attack_finished() -> void:
	super()
	if phase == 2:
		_wait *= 0.45


func _args_for(attack_name: StringName) -> Array:
	match attack_name:
		&"Spit":
			return _spit_targets(3)
		&"SpitFast":
			return _spit_targets(6)
		&"LavaWave":
			return _wade()
		&"Drip":
			var spots := _wade()
			var xs := _player_xs()
			for i in DRIPS:
				# Metade cai em cima de quem está de pé; o resto se espalha pela arena.
				if i % 2 == 0 and not xs.is_empty():
					spots.append(clampf(xs[(i / 2) % xs.size()] + _brain_rng.randf_range(-40.0, 40.0), 80.0, 1840.0))
				else:
					spots.append(_brain_rng.randf_range(120.0, 1500.0))
			return spots
		&"HeavyCrown":
			var spots := _wade()
			var xs := _player_xs()
			var middle: float = 700.0 if xs.is_empty() else xs.reduce(func(a: float, b: float) -> float: return a + b) / xs.size()
			spots.append(clampf(middle + _brain_rng.randf_range(-120.0, 120.0), 260.0, 1000.0))
			# Em dupla só com os dois de pé online (igual ao damage_scale: offline é sempre um jogador só).
			spots.append(1 if damage_scale() == 1 else 0)
			return spots
	return []


## Tiro numa das mãos da Coroa Pesada: é da mão, não do rei.
func apply_damage(amount: int, source := "", part := "") -> void:
	if part.begins_with("hand"):
		if not is_defeated:
			heavy_crown.hand_damage(int(part.trim_prefix("hand")), amount)
		return
	super(amount, source, part)


## Fase 3: o fundo e a beira da margem "quentes" aparecem por cima dos normais.
func heat_stage(animated: bool) -> void:
	for path in [hot_background_path, hot_lip_path]:
		var node := get_node_or_null(path) as CanvasItem
		if node == null:
			continue
		node.show()
		if animated:
			node.modulate.a = 0.0
			create_tween().tween_property(node, "modulate:a", 1.0, 1.4)
		else:
			node.modulate.a = 1.0


func _on_catch_up() -> void:
	king.idle()
	if phase == 1:
		king.set_mode(MagmaKing.Mode.LAKE)
		king.global_position = Vector2(1450, 1000)
	elif phase >= 2:
		king.set_mode(MagmaKing.Mode.MOLTEN)
		king.global_position = Vector2(1610, 1000)
		heat_stage(false)
	king.reset_physics_interpolation()


func _on_defeated() -> void:
	king.hurtbox.set_deferred("monitorable", false)
	king.hitbox.active = false
	king.shake = 0.0
	if king.mode != MagmaKing.Mode.THRONE:
		# Esfria na margem, de pé.
		king.global_position = Vector2(1610, 1000)
		king.reset_physics_interpolation()
	# Esfria, vira estátua e faz uma reverência para os jogadores (finalmente ele se curva).
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(king.pose.bind(&"defeat", i))
		tween.tween_interval(0.7)


func _spit_targets(count: int) -> Array:
	var targets: Array = []
	for x in _player_xs():
		if targets.size() < count:
			targets.append(clampf(x + _brain_rng.randf_range(-60.0, 60.0), 120.0, 1400.0))
	while targets.size() < count:
		targets.append(_brain_rng.randf_range(160.0, 1350.0))
	return targets


## [x de onde sai, x para onde anda] no lago.
func _wade() -> Array:
	return [king.global_position.x, _brain_rng.randf_range(LAKE_X.x, LAKE_X.y)]


func _player_xs() -> Array:
	var xs: Array = []
	for player in alive_players():
		xs.append(player.global_position.x)
	return xs
