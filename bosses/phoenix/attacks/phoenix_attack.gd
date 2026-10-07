class_name PhoenixAttack
extends BossAttack
## Base dos ataques da Fênix: acesso ao chefão, à ave e ao chão (com as rochas), e a criação dos objetos.

const FLOOR_Y := 1000.0
## Rochas flutuantes da arena: x do meio, y do tampo e metade da largura do tampo (batem com RockLeft,
## RockMiddle e RockRight de phoenix_fight.tscn).
const ROCKS := [Vector3(380, 780, 115), Vector3(820, 620, 145), Vector3(1250, 780, 175)]
## Onde ela paira na fase 1, onde pousa na fase 2 e onde fica o ovo na fase 3 (com espaço à direita do ovo
## para um jogador atirar na rachadura de lá).
const HOME := Vector2(1450, 330)
const PERCH := Vector2(1660, 1000)
const EGG := Vector2(1620, 1000)

var boss: PhoenixBoss
var bird: Phoenix


func _ready() -> void:
	boss = get_parent().get_parent()
	bird = boss.get_node("Phoenix")


## Onde algo que cai em `x` para: no tampo de uma rocha, se tiver uma ali, ou no chão.
static func surface_y(x: float) -> float:
	for rock: Vector3 in ROCKS:
		if absf(x - rock.x) <= rock.z:
			return rock.y
	return FLOOR_Y


## A rocha debaixo de `x` (Vector3.ZERO se for chão).
static func rock_at(x: float) -> Vector3:
	for rock: Vector3 in ROCKS:
		if absf(x - rock.x) <= rock.z:
			return rock
	return Vector3.ZERO


func _on_begin() -> void:
	_start()


func _on_tick(_delta: float) -> void:
	_tick(elapsed)


func _on_end() -> void:
	_stop()
	for child in get_children():
		if child is BossProp or child is LandingShadow:
			child.queue_free()
	if not boss.is_defeated:
		bird.idle()


## Cria um objeto deste ataque. `index` identifica o objeto nos dois PCs (parry).
func spawn(kind: StringName, at: Vector2, pink := false, index := 0) -> PhoenixProp:
	var prop := PhoenixProp.new()
	prop.kind = kind
	prop.pink = pink
	prop.parry_id = "%s:%d:%d" % [name, run_seed, index]
	add_child(prop)
	prop.global_position = at
	prop.reset_physics_interpolation()
	return prop


static func free_prop(prop: Node) -> void:
	if prop != null and is_instance_valid(prop):
		prop.queue_free()


# --- Para cada ataque ---

func _start() -> void:
	pass


func _tick(_t: float) -> void:
	pass


func _stop() -> void:
	pass
