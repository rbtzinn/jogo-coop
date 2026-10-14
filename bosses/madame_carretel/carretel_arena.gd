extends Node2D
## Fundo único, estático e atrás de toda a ação. Não há decoração de primeiro plano.
const VIEW_SIZE := Vector2(1920,1080)
const GROUND_Y := 930.0
const SOURCE_GROUND_Y := 783.0
const ART := preload("res://bosses/madame_carretel/art/arena/atelier_clean.png")
var painting := Sprite2D.new()

func _ready() -> void:
	z_index = -20
	painting.name = "Painting"
	painting.texture = ART
	painting.centered = false
	# Escala uniforme: alinha o piso pintado com os pés sem esticar a arte.
	var fit := GROUND_Y/SOURCE_GROUND_Y
	painting.scale = Vector2.ONE*fit
	painting.position.x = (VIEW_SIZE.x-ART.get_width()*fit)*0.5
	add_child(painting)
