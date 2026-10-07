extends StaticBody2D
## Plataforma flutuando (jangada de basalto do Rei Magma, rochas da Fênix). Dá para subir por baixo (só o
## tampo é chão). Só o desenho (filho "Sprite") balança; o chão fica parado (pular nela é sempre igual).

@export var bob_phase := 0.0

var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _rest := _sprite.position


func _process(delta: float) -> void:
	_time += delta
	_sprite.position = _rest + Vector2(0, sin(_time * 1.7 + bob_phase) * 3.0)
	_sprite.rotation = sin(_time * 1.3 + bob_phase) * 0.008
