extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_grade_save.tscn
## Nota da luta (FightGrade), save (SaveGame, num arquivo de teste) e a vitória de verdade
## contra o Domador mostrando a nota e salvando.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	_run()


func _run() -> void:
	# --- Nota ---
	check(FightGrade.compute(100, 150, 6, 6, 3, 6).grade == "S", "perfect fight is S")
	check(FightGrade.compute(150, 150, 6, 6, 3, 6).grade == "S", "on target time still S")
	check(FightGrade.compute(150, 150, 4, 6, 2, 4).grade == "A", "good fight is A (%.1f)" % FightGrade.compute(150, 150, 4, 6, 2, 4).score)
	check(FightGrade.compute(200, 150, 2, 6, 1, 2).grade == "C", "weak fight is C (%.1f)" % FightGrade.compute(200, 150, 2, 6, 1, 2).score)
	check(FightGrade.compute(400, 150, 0, 6, 0, 0).score == 0.0, "nothing is zero")
	check(FightGrade.rank("S") > FightGrade.rank("A") and FightGrade.rank("") < FightGrade.rank("C"), "rank order")

	# --- Save (arquivo de teste, nunca o de verdade) ---
	SaveGame.path = "user://test_save.json"
	SaveGame.reset()
	var first := SaveGame.record_victory("boss_x", "B", 120.0)
	check(first.tickets == 3 and first.first_win, "first win gives 3 tickets")
	var second := SaveGame.record_victory("boss_x", "A", 130.0)
	check(second.tickets == 1 and second.best_grade and not second.best_time, "first A gives 1 ticket")
	var third := SaveGame.record_victory("boss_x", "S", 90.0)
	check(third.tickets == 1 and third.best_time, "first S gives 1 ticket and best time")
	var fourth := SaveGame.record_victory("boss_x", "S", 95.0)
	check(fourth.tickets == 0 and not fourth.best_grade, "repeat S gives nothing")
	var direct_s := SaveGame.record_victory("boss_y", "S", 80.0)
	check(direct_s.tickets == 5, "first win with S gives 5 tickets")
	SaveGame.load_game()
	check(int(SaveGame.data.players.clown.tickets) == 10 and int(SaveGame.data.players.acrobat.tickets) == 10, "tickets saved for both (%s)" % SaveGame.data.players.clown.tickets)
	check(SaveGame.data.bosses.boss_x.best_grade == "S" and is_equal_approx(SaveGame.data.bosses.boss_x.best_time, 90.0), "best grade and time saved")
	check(SaveGame.is_defeated("boss_x") and not SaveGame.is_defeated("tamer"), "defeated flags")
	check(SaveGame.data.players.clown.equipped.gun == "cork_gun", "starting equipment")

	# --- Vitória de verdade ---
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	await frames(30)
	var boss = scene.get_node("TamerBoss")
	boss._wait = 100000.0
	var clown: Player = scene.get_node("PlayerSpawner/Player_1")
	clown.applause.parries = 2
	clown.applause.stars_used = 3
	await frames(30)
	boss.apply_damage(boss.health.current)
	await frames(200)
	var fight: Fight = scene.get_node("Fight")
	check(fight._ended, "fight ended in victory")
	var screen: Node
	for child in fight.get_children():
		if child.get_script() == Fight.END_SCREEN:
			screen = child
	check(screen != null and screen.victory, "victory screen shown")
	if screen != null:
		print("result: ", screen.result)
		check(screen.result.get("tickets", 0) == 4, "first win with A shows 3 + 1 tickets")
		check(screen.result.get("parries", 0) == 2 and screen.result.get("stars_used", 0) == 3, "screen counts parries and stars")
	check(SaveGame.is_defeated("tamer"), "tamer saved as defeated")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.json"))

	print("FAILURES: ", failures)
	get_tree().quit(failures)
