extends StaticBody2D
## Plataforma de madeira pendurada por cordas até o teto do circo. Dá para subir por baixo.

const ROPE_COLOR := Color("c9b48a")
const ROPE_OUTLINE := Color("1b1410")

## Distância das cordas até o centro (bate com os ganchos do desenho).
@export var rope_offset := 146.0


func _draw() -> void:
	for x in [-rope_offset, rope_offset]:
		var bottom := Vector2(x, -18)
		var top := Vector2(x, -global_position.y - 20.0)
		draw_line(top, bottom, ROPE_OUTLINE, 7.0)
		draw_line(top, bottom, ROPE_COLOR, 3.5)
