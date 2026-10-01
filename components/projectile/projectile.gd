class_name Projectile
extends Area2D
## Projétil que anda em linha reta e some ao bater no cenário (com faíscas) ou depois de um tempo.

const HIT_SPARK_SCENE := preload("res://components/fx/hit_spark.tscn")

@export var speed := 1800.0
@export var lifetime := 1.0

var direction := Vector2.RIGHT


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(_body: Node2D) -> void:
	Fx.spawn(HIT_SPARK_SCENE, global_position + direction * 20.0, rotation)
	queue_free()
