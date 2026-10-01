extends Label
## Mostra o FPS no canto da tela, para acompanhar a meta de 60 FPS.


func _process(_delta: float) -> void:
	text = "FPS: %d" % Engine.get_frames_per_second()
