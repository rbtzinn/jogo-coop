extends GrandNumber
## Torta na Cara (Grande Número do palhaço): ergue uma torta gigante e arremessa na direção
## da mira. A torta atravessa a tela e "afunda" no chefão, acertando várias vezes.
## O palhaço fica parado (até no ar) e invencível durante o número.
## Com a folha desenhada (`special_animation` do rig, palhaco_torta.png) o palhaço segura a torta
## nos quadros e o braço da pistola some; sem ela, o braço vai para trás e chicoteia para a frente
## com a torta solta na mão.

const PIE_SCENE := preload("res://core/player/characters/clown/grand_number/pie.tscn")
## Para onde o braço vai no preparo (espaço do personagem: atrás e para cima).
const WINDUP_ARM := Vector2(-0.45, -0.9)
## Com a folha desenhada: onde a torta está na mão no quadro do arremesso (espaço do desenho,
## meio da torta em (424, 270) da célula do 4º quadro).
const DRAWN_RELEASE := Vector2(82, -105)

## Quando a torta sai da mão.
@export var throw_time := 0.38
## Tamanho da torta na mão (cresce no preparo).
@export var held_scale := Vector2(0.3, 0.62)

var _thrown := false

@onready var _held: Sprite2D = $HeldPie


func _ready() -> void:
	_held.hide()
	# A posição é refeita a cada quadro de física, presa à mão.
	_held.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _on_begin() -> void:
	_thrown = false
	_held.visible = not _drawn()
	_update_held()


func _on_tick(_delta: float) -> void:
	if _thrown:
		return
	_update_held()
	if elapsed >= throw_time:
		_throw()


func _on_end() -> void:
	_held.hide()


func pose_aim(_default_aim: Vector2) -> Vector2:
	var back := Vector2(WINDUP_ARM.x * player.facing, WINDUP_ARM.y).normalized()
	if elapsed < throw_time:
		return aim.slerp(back, ease(elapsed / throw_time, 0.5))
	# Chicoteia para a frente logo depois de soltar.
	var follow := clampf((elapsed - throw_time) / 0.08, 0.0, 1.0)
	return back.slerp(aim, follow)


func _update_held() -> void:
	var k := clampf(elapsed / throw_time, 0.0, 1.0)
	var size := lerpf(held_scale.x, held_scale.y, ease(k, -2.0))
	_held.scale = Vector2(size * player.facing, size)
	_held.rotation = -0.35 * k * player.facing
	_held.global_position = player.rig.get_muzzle_position() + Vector2(0, -40.0 * size)


func _throw() -> void:
	_thrown = true
	_held.hide()
	var pie: PiercingProjectile = PIE_SCENE.instantiate()
	pie.direction = aim
	pie.deals_damage = local
	pie.source = String(player.name)
	player.get_tree().current_scene.add_child(pie)
	pie.global_position = (player.rig.to_global(DRAWN_RELEASE) if _drawn()
			else player.rig.get_muzzle_position() + aim * 50.0)
	pie.reset_physics_interpolation()
	player.rig.play_land()


## Quadros desenhados: 1 a 3 no preparo (até soltar a torta), 4 no arremesso e 5 a 8 depois.
func drawn_frame(count: int) -> int:
	if elapsed < throw_time:
		return mini(int(elapsed / throw_time * 3.0), 2)
	var after := (elapsed - throw_time) / maxf(duration - throw_time, 0.01)
	return mini(3 + int(after * (count - 3)), count - 1)


## O palhaço desenhado já segura a torta.
func _drawn() -> bool:
	return player.rig.special_animation != null
