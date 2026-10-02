extends Node
## "Testar sozinho": Tab troca qual personagem você controla. Online não faz nada.


func _unhandled_input(event: InputEvent) -> void:
	if Network.is_online():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if not player.player_health.is_downed:
				player.input.local_control = not player.input.local_control
		get_viewport().set_input_as_handled()
