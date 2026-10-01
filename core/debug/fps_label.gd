extends Label
## Mostra o FPS no canto da tela (liga/desliga em Configurações > Vídeo).


func _process(_delta: float) -> void:
	visible = Settings.show_fps
	if visible:
		text = "FPS: %d" % Engine.get_frames_per_second()
