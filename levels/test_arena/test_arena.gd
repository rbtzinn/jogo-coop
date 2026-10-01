extends Node2D
## Arena de teste. Tab troca qual personagem você controla (só para testar os dois).

@onready var _players: Array[Player] = [$Clown, $Acrobat]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		for player in _players:
			player.input.local_control = not player.input.local_control
		get_viewport().set_input_as_handled()
