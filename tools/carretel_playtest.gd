extends Node
## Teste jogável com save próprio, sem mexer nos saves da campanha.
func _ready() -> void:
	_start.call_deferred()

func _start() -> void:
	var tree := get_tree()
	# Sobrevive só ao carregamento para abrir a pausa antes de o boss atacar.
	get_parent().remove_child(self)
	tree.root.add_child(self)
	SaveGame.path = "user://carretel_playtest_solo.json"
	SaveGame.reset()
	SaveGame.data.area = 3
	PlayerSpawner.solo_slot = 0
	Levels.return_door = "madame_carretel"
	get_window().title = "Madame Carretel — luta jogável (teste)"
	tree.change_scene_to_file("res://bosses/madame_carretel/madame_carretel_fight.tscn")
	await tree.scene_changed
	PauseMenu.open()
	queue_free()
