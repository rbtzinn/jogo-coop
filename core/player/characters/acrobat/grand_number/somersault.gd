extends GrandNumber
## Salto Mortal (Grande Número da acrobata): agacha e salta girando em arco para o lado em que
## olha (por cima do chefão), acertando tudo que atravessa. Invencível durante o salto.
## Com a folha desenhada (`special_animation` do rig, acrobata_salto_mortal.png) a cambalhota é
## quadro a quadro: agachada, saída, a volta inteira com o chute e o pouso; sem ela, o corpo de
## peças gira por código.

const HIT_SPARK := preload("res://components/fx/hit_spark.tscn")
## Desenho: a volta (quadros 2 a 7) termina nesta fração do arco; o chute (7) fica até LAND_FROM,
## quando entra o pouso (8). Pousando antes num pedestal, o número acaba no chute.
const TURN_UNTIL := 0.6
const LAND_FROM := 0.88

@export var crouch_time := 0.12
@export var leap_time := 0.75
@export var distance := 760.0
@export var height := 400.0
@export var turns := 2.0
## Até onde o pouso pode ir (as paredes da arena).
@export var arena_x := Vector2(90, 1830)

var _from := Vector2.ZERO
var _to := Vector2.ZERO

@onready var _damage: DamageArea = $DamageArea


func _ready() -> void:
	_damage.monitoring = false
	_damage.hit_landed.connect(_on_hit_landed)


func _on_begin() -> void:
	duration = crouch_time + leap_time
	_from = player.global_position
	_to = Vector2(clampf(_from.x + player.facing * distance, arena_x.x, arena_x.y), _from.y)
	_damage.deals_damage = local
	_damage.source = String(player.name)
	_damage.hits = 0
	_damage.set_deferred(&"monitoring", true)


func _on_tick(_delta: float) -> void:
	# Pousou antes do fim do arco (ex.: num pedestal): acaba ali.
	if local and _leap_progress() > 0.55 and player.is_on_floor():
		finish()


func _on_end() -> void:
	_damage.set_deferred(&"monitoring", false)


## Segue a curva do salto (pela velocidade, para paredes e pedestais ainda segurarem).
func move(_delta: float, _velocity: Vector2) -> Vector2:
	if elapsed < crouch_time:
		return Vector2.ZERO
	var u := _leap_progress()
	return Vector2((_to.x - _from.x) / leap_time, -4.0 * height * (1.0 - 2.0 * u) / leap_time)


func pose_aim(_default_aim: Vector2) -> Vector2:
	return Vector2(player.facing, 0.6).normalized()


func spin() -> float:
	if _drawn() or elapsed < crouch_time:
		return 0.0
	return turns * ease(_leap_progress(), -1.8)


func crouch_pose() -> bool:
	return elapsed < crouch_time


func _leap_progress() -> float:
	return clampf((elapsed - crouch_time) / leap_time, 0.0, 1.0)


func _on_hit_landed() -> void:
	var at := _damage.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	Fx.spawn(HIT_SPARK, at, randf() * TAU)
	ParryFlash.spawn_gold(at, 0.5)


## Quadros desenhados: 1 agachada; 2 a 7 a volta (mais rápida no meio, como o giro de peças) até
## TURN_UNTIL; o chute segura até LAND_FROM; 8 o pouso.
func drawn_frame(count: int) -> int:
	if elapsed < crouch_time:
		return 0
	var u := _leap_progress()
	if u >= LAND_FROM:
		return count - 1
	return 1 + mini(int(ease(minf(u / TURN_UNTIL, 1.0), -1.8) * (count - 2)), count - 3)


func _drawn() -> bool:
	return player != null and player.rig.special_animation != null
