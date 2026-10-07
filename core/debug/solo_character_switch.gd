extends Node
## Sozinho ("Jogar sozinho" e "Testar sozinho"): Tab troca qual personagem você controla. Se o personagem controlado
## cair, o controle passa sozinho para o outro (para resgatar o balão dele).
## Online não faz nada.


func _physics_process(_delta: float) -> void:
	if Network.is_online():
		return
	var alive := _alive_players()
	if alive.is_empty():
		return
	for player in alive:
		if player.input.local_control:
			return
	alive[0].input.local_control = true


func _unhandled_input(event: InputEvent) -> void:
	if Network.is_online():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		var alive := _alive_players()
		if alive.size() > 1:
			for player in alive:
				player.input.local_control = not player.input.local_control
		get_viewport().set_input_as_handled()


func _alive_players() -> Array[Player]:
	var alive: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.player_health.is_downed:
			alive.append(player)
	return alive
