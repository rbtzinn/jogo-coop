extends Node
## Só para testes no PC de desenvolvimento: com duas cópias do jogo abertas, a segunda
## janela abre deslocada e com "(janela 2)" no título, para não ficar uma em cima da outra.
## No jogo exportado (versão final) não faz nada.

const LOCK_PORT := 24679

var _lock := PacketPeerUDP.new()


func _ready() -> void:
	if not OS.is_debug_build() or DisplayServer.get_name() == "headless":
		return
	if _lock.bind(LOCK_PORT, "127.0.0.1") == OK:
		return
	var window := get_window()
	window.title += " (janela 2)"
	if window.mode == Window.MODE_WINDOWED:
		window.position += Vector2i(360, 200)
