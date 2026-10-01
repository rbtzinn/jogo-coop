extends Sprite2D
## Canhão de luz que balança devagar. Na qualidade baixa fica parado.

@export var sway_angle := 0.12
@export var sway_speed := 0.5
@export var phase := 0.0

var _time := 0.0


func _process(delta: float) -> void:
	if Settings.quality == Settings.Quality.LOW:
		return
	_time += delta
	rotation = sin(_time * sway_speed * TAU + phase) * sway_angle
