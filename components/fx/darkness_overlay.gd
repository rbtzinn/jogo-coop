class_name DarknessOverlay
extends CanvasLayer
## Escuridão por cima da arena com um holofote seguindo cada jogador (shaders/darkness.gdshader).
## Quanto mais perto os dois ficam, maiores os holofotes (ficar junto ilumina mais).
## `darkness` de 0 (luz acesa) a 1 (apagada); quem liga e desliga é o ataque.

const SHADER := preload("res://shaders/darkness.gdshader")
const BASE_RADIUS := 230.0
const CLOSE_RADIUS := 340.0
## Distância em que os holofotes começam a crescer.
const CLOSE_DISTANCE := 500.0

var darkness := 0.0

var _rect := ColorRect.new()
var _material := ShaderMaterial.new()


func _ready() -> void:
	layer = 5
	_material.shader = SHADER
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func _process(_delta: float) -> void:
	_rect.visible = darkness > 0.001
	if not _rect.visible:
		return
	var centers: Array[Vector2] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_inside_tree() and not player.player_health.is_out:
			centers.append(player.get_global_transform_with_canvas().origin + Vector2(0, -70))
	while centers.size() < 2:
		centers.append(Vector2(-9999, -9999))
	var radius := BASE_RADIUS
	if centers[0].distance_to(centers[1]) < CLOSE_DISTANCE:
		radius = lerpf(CLOSE_RADIUS, BASE_RADIUS, centers[0].distance_to(centers[1]) / CLOSE_DISTANCE)
	_material.set_shader_parameter(&"rect_size", _rect.size)
	_material.set_shader_parameter(&"light_a", centers[0])
	_material.set_shader_parameter(&"light_b", centers[1])
	_material.set_shader_parameter(&"radius_a", radius)
	_material.set_shader_parameter(&"radius_b", radius)
	_material.set_shader_parameter(&"darkness", darkness)
