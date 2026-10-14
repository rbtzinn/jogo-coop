class_name PaintedObstacle
extends StaticBody3D
## Colisão de um objeto pintado: retângulo em pixels convertido no mesmo plano do mapa.
@export var painted_footprint := Rect2(0,0,100,50)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	get_parent().ready.connect(_place)

func _place() -> void:
	var world := get_parent() as PaintedWorld
	var first := world.pixel_to_world(painted_footprint.position)
	var last := world.pixel_to_world(painted_footprint.end)
	position = (first+last)*0.5
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(last.x-first.x,3.0,last.z-first.z)
	collision.shape = box
	collision.position.y = 1.5
	add_child(collision)
