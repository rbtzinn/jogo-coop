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
	# Trava de segurança: se algo travar (ex.: erro de script), sai com falha.
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	# --- Nota ---
	check(FightGrade.compute(100, 150, 6, 6, 3, 5, 3).grade == "S", "perfect fight is S")
	check(FightGrade.compute(150, 150, 6, 6, 3, 5, 3).grade == "S", "on target time still S")
	check(FightGrade.compute(150, 150, 6, 6, 3, 5, 0).grade == "A", "a pair without duo acts tops at A (%.1f)" % FightGrade.compute(150, 150, 6, 6, 3, 5, 0).score)
	check(FightGrade.compute(150, 150, 3, 3, 3, 5, 0, true).grade == "S", "alone can still get S")
	check(FightGrade.verdict("S") == "Ovação!" and FightGrade.verdict("C") == "Silêncio", "verdicts")
	check(FightGrade.compute(150, 150, 5, 6, 2, 4, 2).grade == "A", "good fight is A (%.1f)" % FightGrade.compute(150, 150, 5, 6, 2, 4, 2).score)
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

	# --- Gravação segura (.tmp e .bak) ---
	# Pasta de teste com o mesmo nome do save 1 de dupla, para testar também o resumo do menu (slot_info).
	var old_folder := SaveGame.slot_folder
	SaveGame.slot_folder = "user://test_safe_"
	var safe := SaveGame.slot_path("coop", 0)
	_remove_save_files(safe)
	SaveGame.path = safe
	SaveGame.reset()
	SaveGame.data.players.clown.tickets = 7
	SaveGame.save_game()
	SaveGame.data.players.clown.tickets = 8
	SaveGame.save_game()
	check(_tickets_in(safe) == 8 and not FileAccess.file_exists(safe + SaveGame.TMP_SUFFIX), "save written, no .tmp left")
	check(_tickets_in(safe + SaveGame.BACKUP_SUFFIX) == 7, "previous save kept in .bak")
	# Faltou luz logo depois de gravar: o save ficou vazio, ou pela metade.
	_write(safe, "")
	SaveGame.load_game()
	check(int(SaveGame.data.players.clown.tickets) == 7, "empty save recovers from .bak (%s)" % SaveGame.data.players.clown.tickets)
	_write(safe, '{"version": 1, "players": {"clown": {"tick')
	SaveGame.load_game()
	check(int(SaveGame.data.players.clown.tickets) == 7, "half-written save recovers from .bak (%s)" % SaveGame.data.players.clown.tickets)
	SaveGame.data.players.clown.tickets = 9
	SaveGame.save_game()
	check(_tickets_in(safe) == 9 and _tickets_in(safe + SaveGame.BACKUP_SUFFIX) == 7, "a broken save never replaces the .bak")
	# Fechou no meio da troca de nome (no Windows o save some um instante): sobra o .tmp inteiro.
	DirAccess.rename_absolute(safe, safe + SaveGame.TMP_SUFFIX)
	SaveGame.load_game()
	check(int(SaveGame.data.players.clown.tickets) == 9, "interrupted rename recovers from .tmp (%s)" % SaveGame.data.players.clown.tickets)
	check(SaveGame.slot_info("coop", 0).exists, "menu sees the .tmp save too")
	SaveGame.save_game()
	# Fechou escrevendo o .tmp: ele fica pela metade e o save continua valendo.
	_write(safe + SaveGame.TMP_SUFFIX, '{"vers')
	SaveGame.load_game()
	check(int(SaveGame.data.players.clown.tickets) == 9, "half-written .tmp is ignored (%s)" % SaveGame.data.players.clown.tickets)
	# Save apagado continua apagado: a cópia anterior não volta sozinha.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(safe))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(safe + SaveGame.TMP_SUFFIX))
	SaveGame.load_game()
	check(int(SaveGame.data.players.clown.tickets) == 0, "deleted save stays deleted (%s)" % SaveGame.data.players.clown.tickets)
	_remove_save_files(safe)
	SaveGame.slot_folder = old_folder
	SaveGame.path = "user://test_save.json"

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
	# Um número em dupla (um resgate, por exemplo): com 5 truques e vida cheia, dá A.
	DuoActs.find(get_tree()).acts = 1
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
	_remove_save_files("user://test_save.json")

	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _write(file_path: String, text: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Ingressos do palhaço gravados num arquivo (-1 se o arquivo não abrir).
func _tickets_in(file_path: String) -> int:
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	return int(loaded.players.clown.tickets) if loaded is Dictionary else -1


func _remove_save_files(save_path: String) -> void:
	for suffix in ["", SaveGame.TMP_SUFFIX, SaveGame.BACKUP_SUFFIX]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
