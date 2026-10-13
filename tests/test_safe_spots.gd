extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_safe_spots.tscn [-- <luta> <fase> <semente>]
## Procura lugares seguros demais nas lutas (bug de 13/10/2026: cantos onde o chefão não chegava e
## o boneco ficava invulnerável). Os dois jogadores ficam PARADOS em pontos da arena, sem pular nem
## desviar: o chão inteiro, de 160 em 160 px a partir de cada parede, e o topo de cada plataforma.
## Mede de quanto em quanto tempo algum ataque acerta cada ponto. Falha se um jogador parado passa
## mais de MAX_SAFE_GAP segundos sem golpe (decisão do usuário: ninguém descansa parado).
## Os jogadores não morrem: a vida é reposta e a invencibilidade zerada a cada quadro.

const FIGHTS := [
	"res://bosses/tamer/tamer_fight.tscn",
	"res://bosses/jugglers/jugglers_fight.tscn",
	"res://bosses/magician/magician_fight.tscn",
	"res://bosses/magma_king/magma_king_fight.tscn",
	"res://bosses/phoenix/phoenix_fight.tscn",
	"res://bosses/anvil_master/anvil_master_fight.tscn",
	"res://bosses/volcano_heart/volcano_heart_fight.tscn",
]
## Distâncias da parede (cada uma vale para a esquerda e para a direita) até o meio da arena.
const FLOOR_STEPS := [20.0, 160.0, 320.0, 480.0, 640.0, 800.0, 940.0]
const SECONDS_PER_PHASE := 30.0
const SETTLE_SECONDS := 4.0
## Maior intervalo aceitável sem nenhum golpe num jogador parado (segundos).
const MAX_SAFE_GAP := 10.0
const SEEDS := [11]

var failures := 0
## Pontos de cada luta, calculados com a cena na árvore (posições globais).
var _spots_by_fight := {}


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	get_tree().create_timer(14400.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_safe_spots_%d.json" % OS.get_process_id()
	SaveGame.reset()
	var args := OS.get_cmdline_user_args()
	var only_fight := args[0] if args.size() > 0 else ""
	var only_phase := int(args[1]) - 1 if args.size() > 1 else -1
	var seeds: Array = [int(args[2])] if args.size() > 2 else SEEDS
	for path: String in FIGHTS:
		if not only_fight.is_empty() and not path.contains(only_fight):
			continue
		var phases: int = await _phase_count(path)
		for phase in phases:
			if only_phase >= 0 and phase != only_phase:
				continue
			for seed_value: int in seeds:
				await _measure_phase(path, phase, seed_value)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _phase_count(path: String) -> int:
	var scene: Node = load(path).instantiate()
	add_child(scene)
	var count: int = (scene.get_node("Fight") as Fight).boss.phase_shares.size()
	var spots := _spots(scene)
	_spots_by_fight[path] = spots
	print("# %s: %d fases, %d pontos" % [path.get_file().get_basename(), count, spots.size()])
	scene.queue_free()
	await get_tree().process_frame
	return count


## Mede todos os pontos de uma fase, dois por vez (um por jogador).
func _measure_phase(path: String, phase: int, seed_value: int) -> void:
	var spots: Array = _spots_by_fight[path]
	var index := 0
	while index < spots.size():
		var pair: Array = [spots[index], spots[mini(index + 1, spots.size() - 1)]]
		await _measure(path, phase, seed_value, pair)
		index += 2


func _measure(path: String, phase: int, seed_value: int, pair: Array) -> void:
	var scene: Node = load(path).instantiate()
	add_child(scene)
	var fight: Fight = scene.get_node("Fight")
	var boss: BossBrain = fight.boss
	boss._brain_rng.seed = seed_value
	await get_tree().physics_frame
	var players: Array[Player] = []
	for node in get_tree().get_nodes_in_group(&"players"):
		players.append(node as Player)
	players.sort_custom(func(a: Player, b: Player) -> bool: return a.name < b.name)
	for p in phase:
		_end_phase(boss)
		await _hold(scene, players, pair, 0.5)
	await _hold(scene, players, pair, SETTLE_SECONDS)
	var hit_frames: Array = [[], []]
	var attack_hits := [0, 0]
	for i in players.size():
		var slot := i
		var player := players[i]
		player.player_health.hurt.connect(func(_from: Vector2) -> void:
			(hit_frames[slot] as Array).append(Engine.get_physics_frames())
			if not _hit_by_hazard(player):
				attack_hits[slot] += 1)
	var start := Engine.get_physics_frames()
	await _hold(scene, players, pair, SECONDS_PER_PHASE)
	var end := Engine.get_physics_frames()
	var fight_name := path.get_file().get_basename()
	for i in mini(players.size(), 2):
		if i == 1 and pair[1] == pair[0]:
			break
		var times: Array = hit_frames[i]
		var gap := 0
		var previous := start
		for frame: int in times:
			gap = maxi(gap, frame - previous)
			previous = frame
		gap = maxi(gap, end - previous)
		var spot: Dictionary = pair[i]
		check(gap / 60.0 <= MAX_SAFE_GAP, "%s fase %d semente %d, %s: %d golpes (%d de ataques), maior intervalo %.1fs" % [
			fight_name, phase + 1, seed_value, spot.label, times.size(), attack_hits[i], gap / 60.0])
		if attack_hits[i] == 0:
			print("AVISO só o perigo do cenário acerta: %s fase %d semente %d, %s" % [fight_name, phase + 1, seed_value, spot.label])
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## O golpe veio do perigo do cenário (StageHazard), não de um ataque do chefão?
func _hit_by_hazard(player: Player) -> bool:
	for area in player.player_health.hurtbox.get_overlapping_areas():
		if area.is_in_group(&"stage_hazard"):
			return true
	return false


## Segura os jogadores parados nos pontos, com vida cheia e sem invencibilidade.
func _hold(scene: Node, players: Array[Player], pair: Array, seconds: float) -> void:
	for i in int(seconds * 60):
		await get_tree().physics_frame
		for index in mini(players.size(), 2):
			var player := players[index]
			if not is_instance_valid(player):
				continue
			var spot: Dictionary = pair[index]
			player.global_position.x = spot.x
			player.velocity.x = 0.0
			if spot.has("body"):
				# Em cima de plataforma (que pode se mexer): acompanha o topo dela.
				var top := _top_of(scene.get_node(spot.body) as CollisionObject2D)
				player.global_position = Vector2(top.x + spot.dx, top.y - 1.0)
				player.velocity = Vector2.ZERO
			player.player_health._invincible_timer = 0.0
			if player.player_health.is_downed:
				continue
			player.player_health.health.set_current(player.player_health.health.maximum)


func _end_phase(boss: BossBrain) -> void:
	if boss is VolcanoHeartBoss and boss.phase == 1:
		(boss as VolcanoHeartBoss)._open_until = (boss as VolcanoHeartBoss)._clock + 1.0
	var parts: Array = [""]
	if boss.has_method(&"sub_bars"):
		parts = boss.sub_bars().map(func(entry: Array) -> String: return entry[0])
	for part: String in parts:
		var damage: int = boss.health.current - boss.phase_end_health() if part.is_empty() else boss.health.current
		if boss is VolcanoHeartBoss and boss.phase == 1:
			damage = ceili(damage / 2.0)
		boss.apply_damage(damage, "", part)


## Pontos onde os jogadores ficam: chão inteiro e topo de cada plataforma (corpo sólido que
## não é chão nem parede).
func _spots(scene: Node) -> Array:
	var walls := _wall_limits(scene)
	var spots := []
	var platforms := _platforms(scene)
	for step: float in FLOOR_STEPS:
		for side in [[walls.x + step, "esquerda"], [walls.y - step, "direita"]]:
			# Ponto do chão coberto por um bloco sólido (ex.: a base do leão) não existe: quem
			# está ali está em cima do bloco, que é medido à parte.
			if not _inside_platform(platforms, side[0]):
				spots.append({"x": side[0], "label": "chão a %dpx da parede %s" % [int(step), side[1]]})
	for body in platforms:
		var top := _top_of(body)
		var path := String(scene.get_path_to(body))
		spots.append({"x": top.x, "dx": 0.0, "body": path, "label": "em cima de %s" % path})
	return spots


## O x cai dentro de um bloco que encosta no chão?
func _inside_platform(platforms: Array, x: float) -> bool:
	for body: CollisionObject2D in platforms:
		var shape := _shape_of(body)
		var size := (shape.shape as RectangleShape2D).size * shape.global_scale.abs()
		var center := shape.global_position
		if absf(x - center.x) < size.x / 2.0 + 20.0 and center.y + size.y / 2.0 >= 990.0:
			return true
	return false


func _platforms(node: Node) -> Array:
	var found := []
	for child in node.get_children():
		if child is StaticBody2D or child is AnimatableBody2D:
			if not String(child.name) in ["Floor", "WallLeft", "WallRight", "Ceiling"] and _shape_of(child) != null:
				found.append(child)
		elif not child is BossBrain:
			found.append_array(_platforms(child))
	return found


func _shape_of(body: Node) -> CollisionShape2D:
	for child in body.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			return child
	return null


## Meio do topo da forma de colisão do corpo (coordenadas globais).
func _top_of(body: CollisionObject2D) -> Vector2:
	var shape := _shape_of(body)
	var size := (shape.shape as RectangleShape2D).size * shape.global_scale.abs()
	return shape.global_position - Vector2(0.0, size.y / 2.0)


## Borda de dentro das paredes (x da esquerda, x da direita).
func _wall_limits(scene: Node) -> Vector2:
	var limits := Vector2(0.0, 1920.0)
	for side in ["WallLeft", "WallRight"]:
		var wall := scene.get_node_or_null(side) as Node2D
		if wall == null:
			continue
		var shape := (wall.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
		if side == "WallLeft":
			limits.x = wall.global_position.x + shape.size.x / 2.0
		else:
			limits.y = wall.global_position.x - shape.size.x / 2.0
	return limits
