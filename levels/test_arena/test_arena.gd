extends Node2D
## Arena de teste. No modo "Testar sozinho", Tab troca qual personagem você controla.

@onready var _hint: Label = $Hud/HintLabel


func _ready() -> void:
	if Network.is_online():
		_hint.text = "Esc / Start: pausa e configurações"


func _unhandled_input(event: InputEvent) -> void:
	if Network.is_online():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			player.input.local_control = not player.input.local_control
		get_viewport().set_input_as_handled()
