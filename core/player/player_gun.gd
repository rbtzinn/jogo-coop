class_name PlayerGun
extends Node
## Arma do jogador: controla a cadência e cria os projéteis na direção da mira.

const PROJECTILE_SCENE := preload("res://components/projectile/projectile.tscn")

@export var fire_interval := 0.12

var _cooldown := 0.0


## Retorna true no quadro em que um tiro sai.
func tick(delta: float, aim: Vector2, trigger_held: bool, muzzle_position: Vector2) -> bool:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not trigger_held or _cooldown > 0.0:
		return false
	spawn_projectile(aim, muzzle_position)
	_cooldown = fire_interval
	return true


## Também usado para mostrar os tiros do jogador remoto (aí `deals_damage` = false).
func spawn_projectile(aim: Vector2, muzzle_position: Vector2, deals_damage := true) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.direction = aim
	projectile.deals_damage = deals_damage
	projectile.source = String(get_parent().name)
	if deals_damage:
		projectile.shooter = get_parent()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle_position
	projectile.reset_physics_interpolation()
