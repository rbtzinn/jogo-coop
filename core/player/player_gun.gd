class_name PlayerGun
extends Node
## Arma do jogador: controla a cadência e cria os projéteis na direção da mira.
## A pistola equipada (docs/shop.md) muda o tiro e o Tiro EX:
## - Rolha: reto e rápido / EX Rolhão (rolha gigante que atravessa);
## - Leque de Confete: 3 confetes em leque, alcance médio / EX Canhão de Confete (explosão em volta);
## - Clave de Malabares: clave que vai e volta / EX Chuva de Claves (5 caem à frente);
## - Bolha de Sabão: bolhas teleguiadas / EX Bolhona (bolha grande que estoura em área).

const PROJECTILE_SCENE := preload("res://components/projectile/projectile.tscn")
const EX_SCENE := preload("res://components/projectile/big_cork.tscn")
const CONFETTI_BLAST := preload("res://components/projectile/art/confetti_blast.tres")
## Cadência de cada pistola (segundos entre tiros).
const INTERVALS := {"cork_gun": 0.12, "confetti_fan": 0.2, "juggling_club": 0.4, "soap_bubble": 0.18}

## Pistola equipada (id do item).
var weapon := "cork_gun"
## Multiplicador do dano dos tiros (Coração de Pano: 0,95).
var damage_scale := 1.0

var _cooldown := 0.0
## Sobra de dano quebrado (o dano é inteiro; a sobra vai somando para os próximos tiros).
var _carry := 0.0

@onready var _player: Player = get_parent()


## Retorna true no quadro em que um tiro sai.
func tick(delta: float, aim: Vector2, trigger_held: bool, muzzle_position: Vector2) -> bool:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not trigger_held or _cooldown > 0.0:
		return false
	spawn_projectile(aim, muzzle_position)
	_cooldown = INTERVALS.get(weapon, 0.12)
	return true


## Dano inteiro depois de um multiplicador, guardando a sobra para os próximos.
func scaled(base: int, factor: float) -> int:
	var exact := base * factor + _carry
	var whole := floori(exact)
	_carry = exact - whole
	return whole


## Também usado para mostrar os tiros do jogador remoto (aí `deals_damage` = false).
func spawn_projectile(aim: Vector2, muzzle_position: Vector2, deals_damage := true) -> void:
	match weapon:
		"confetti_fan":
			# Desde 05/10/2026 (pedido do usuário: só acertava de perto) vai uns 830 px, num leque mais fechado.
			for angle in [-0.15, 0.0, 0.15]:
				var pellet := _make(aim.rotated(angle), muzzle_position, deals_damage)
				pellet.look = &"confetti"
				pellet.speed = 1500.0
				pellet.lifetime = 0.55
				_add(pellet, muzzle_position)
		"juggling_club":
			var club := _make(aim, muzzle_position, deals_damage)
			club.look = &"club"
			club.boomerang = true
			club.speed = 1300.0
			club.lifetime = 1.4
			club.damage = scaled(2, damage_scale) if deals_damage else 2
			_add(club, muzzle_position)
		"soap_bubble":
			var bubble := _make(aim, muzzle_position, deals_damage)
			bubble.look = &"bubble"
			bubble.homing = 5.0
			bubble.speed = 700.0
			bubble.lifetime = 1.6
			_add(bubble, muzzle_position)
		_:
			_add(_make(aim, muzzle_position, deals_damage), muzzle_position)


## Tiro EX (gasta 1 estrela; quem cobra é o PlayerSpecial). Remoto: só visual.
func spawn_ex(aim: Vector2, muzzle_position: Vector2, deals_damage := true) -> void:
	var source := String(_player.name)
	match weapon:
		"confetti_fan":
			AreaBlast.spawn(_player.global_position + Vector2(0, -70), 230.0, 6, 5, deals_damage, source,
					Color("ffc93c"), CONFETTI_BLAST)
		"juggling_club":
			for i in 5:
				var x := _player.global_position.x + _player.facing * (140.0 + i * 130.0)
				var start := Vector2(x, _player.global_position.y - 600.0 - i * 90.0)
				var club := _make(Vector2.DOWN, start, deals_damage)
				club.look = &"club"
				club.pierce = true
				club.speed = 1500.0
				club.lifetime = 1.2
				club.damage = 6
				club.gives_applause = false
				club.set_collision_mask_value(1, false)
				_add(club, start)
		"soap_bubble":
			var bubble := _make(aim, muzzle_position, deals_damage)
			bubble.look = &"big_bubble"
			bubble.homing = 2.5
			bubble.speed = 380.0
			bubble.lifetime = 3.0
			bubble.blast_damage = 35
			bubble.gives_applause = false
			_add(bubble, muzzle_position)
		_:
			var projectile: PiercingProjectile = EX_SCENE.instantiate()
			projectile.direction = aim
			projectile.deals_damage = deals_damage
			projectile.source = source
			get_tree().current_scene.add_child(projectile)
			projectile.global_position = muzzle_position + aim * 30.0
			projectile.reset_physics_interpolation()
	# Depois do EX a pistola espera um pouco antes do próximo tiro normal.
	_cooldown = maxf(_cooldown, 0.3)


func _make(aim: Vector2, _muzzle_position: Vector2, deals_damage: bool) -> Projectile:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.direction = aim
	projectile.deals_damage = deals_damage
	projectile.source = String(_player.name)
	projectile.origin_player = _player
	projectile.damage = scaled(1, damage_scale) if deals_damage else 1
	if deals_damage:
		projectile.shooter = _player
		projectile.turbo = _player.loadout.duo == "turbo_cork"
	return projectile


func _add(projectile: Projectile, at: Vector2) -> void:
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = at
	projectile.reset_physics_interpolation()
