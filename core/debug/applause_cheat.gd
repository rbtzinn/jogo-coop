extends Node
## Só para testes (versão de desenvolvimento, nunca no jogo exportado): F1 enche as 5 estrelas
## de Aplauso dos jogadores deste PC, para testar o Tiro EX e o Grande Número sem farmar.


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.is_multiplayer_authority():
				player.applause.add_stars(PlayerApplause.MAX_STARS)
		get_viewport().set_input_as_handled()
