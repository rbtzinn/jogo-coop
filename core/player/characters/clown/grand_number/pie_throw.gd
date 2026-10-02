extends GrandNumber
## Torta na Cara (Grande Número do palhaço): ergue uma torta gigante e arremessa na direção
## da mira. A torta atravessa a tela e "afunda" no chefão, acertando várias vezes.
## O palhaço fica parado (até no ar) e invencível durante o número.
## Primeira versão animada por código (braço indo para trás e chicoteando para a frente); a arte
## quadro a quadro está pedida em docs/prompts/codex_parry_balao_especiais.md.

const PIE_SCENE := preload("res://core/player/characters/clown/grand_number/pie.tscn")
## Para onde o braço vai no preparo (espaço do personagem: atrás e para cima).
const WINDUP_ARM := Vector2(-0.45, -0.9)

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
	_held.show()
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
	pie.global_position = player.rig.get_muzzle_position() + aim * 50.0
	pie.reset_physics_interpolation()
	player.rig.play_land()
