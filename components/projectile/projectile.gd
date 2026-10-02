class_name Projectile
extends Area2D
## Projétil que anda em linha reta e some ao bater no cenário ou num inimigo (com faíscas)
## ou depois de um tempo.

const HIT_SPARK_SCENE := preload("res://components/fx/hit_spark.tscn")

@export var speed := 1800.0
@export var lifetime := 1.0
@export var damage := 1

var direction := Vector2.RIGHT
## Só o tiro do jogador deste PC causa dano. A cópia do tiro do parceiro é só visual:
## o dano dela já foi contado no PC dele.
var deals_damage := true


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(_body: Node2D) -> void:
	_explode()


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or is_queued_for_deletion():
		return
	if deals_damage:
		(area as Hurtbox).take_hit(damage)
	_explode()


func _explode() -> void:
	Fx.spawn(HIT_SPARK_SCENE, global_position + direction * 20.0, rotation)
	queue_free()
