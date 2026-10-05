extends Node
## Só para testes (versão de desenvolvimento, nunca no jogo exportado): F2 no mapa dá +50 ingressos para
## os dois personagens, para testar as pistolas e os artefatos da loja sem farmar. Quem guarda o save
## (sozinho ou o host) é quem soma; o parceiro recebe a cópia.

const AMOUNT := 50


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not SaveGame.is_keeper():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F2:
		for key in SaveGame.PLAYER_KEYS:
			SaveGame.data.players[key].tickets += AMOUNT
		SaveGame.save_game()
		SaveGame.share()
		SaveGame.changed.emit()
		get_viewport().set_input_as_handled()
