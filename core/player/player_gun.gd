class_name PlayerGun
extends Node2D
## Arma do jogador: controla a cadência e cria os projéteis na direção da mira.

const PROJECTILE_SCENE := preload("res://components/projectile/projectile.tscn")

@export var fire_interval := 0.12
@export var muzzle_distance := 60.0

var _cooldown := 0.0


func tick(delta: float, aim: Vector2, trigger_held: bool) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if trigger_held and _cooldown == 0.0:
		_fire(aim)
		_cooldown = fire_interval


func _fire(aim: Vector2) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.direction = aim
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + aim * muzzle_distance
