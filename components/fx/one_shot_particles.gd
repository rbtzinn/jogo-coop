extends CPUParticles2D
## Partículas que disparam uma vez e se apagam sozinhas.
## Na qualidade média usam metade das partículas.


func _ready() -> void:
	if Settings.quality == Settings.Quality.MEDIUM:
		amount = maxi(1, amount / 2)
	one_shot = true
	emitting = true
	finished.connect(queue_free)
