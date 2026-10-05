extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_boss_smoke.tscn
## "Teste de fumaça" de cada luta: roda os ataques de verdade, passando por todas as fases, com
## os jogadores invencíveis, até vencer. Falha se algum ataque nunca aparecer ou se a luta não
## acabar. (Erros de script aparecem no log como SCRIPT ERROR; o run_all.sh mostra.)

const FIGHTS := [
	"res://bosses/tamer/tamer_fight.tscn",
	"res://bosses/jugglers/jugglers_fight.tscn",
	"res://bosses/magician/magician_fight.tscn",
]
## Tempo de jogo em cada fase (segundos).
const SECONDS_PER_PHASE := 45.0

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	get_tree().create_timer(600.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_smoke.json"
	SaveGame.reset()
	for path: String in FIGHTS:
		await _smoke(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _smoke(path: String) -> void:
	var scene: Node = load(path).instantiate()
	add_child(scene)
	var fight: Fight = scene.get_node("Fight")
	var boss: BossBrain = fight.boss
	var seen := {}
	for phase in boss.phase_shares.size():
		var frames := int(SECONDS_PER_PHASE * 60)
		for i in frames:
			await get_tree().physics_frame
			for player: Player in get_tree().get_nodes_in_group(&"players"):
				player.player_health._invincible_timer = 10.0
			if boss._current != null:
				seen[boss._current.name] = true
		# Próxima fase (ou vitória na última).
		# Chefões com várias vidas (sub_bars) levam o dano em cada parte.
		var parts: Array = [""]
		if boss.has_method(&"sub_bars"):
			parts = boss.sub_bars().map(func(entry: Array) -> String: return entry[0])
		for part: String in parts:
			boss.apply_damage(boss.health.current - boss.phase_end_health() if part.is_empty() else boss.health.current, "", part)
		await get_tree().create_timer(0.1).timeout
	var expected := {}
	for list: Array in boss.phase_attacks:
		for attack_name in list:
			expected[String(attack_name)] = true
	for intro in boss.phase_intros:
		if intro != &"":
			expected[String(intro)] = true
	var missing := expected.keys().filter(func(attack_name: String) -> bool: return not seen.has(attack_name))
	check(missing.is_empty(), "%s: every attack ran (missing %s)" % [path.get_file(), missing])
	for i in 200:
		await get_tree().physics_frame
	check(fight._ended and boss.is_defeated, "%s: fight won" % path.get_file())
	scene.queue_free()
	await get_tree().physics_frame
