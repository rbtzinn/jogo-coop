class_name Tamer
extends Node2D
## O Domador: baixinho, bigodudo e convencido. Segura o chicote (desenhado por código,
## uma linha que balança) e o levanta antes de estalar. Quando o leão foge do controle
## (fase 2), ele sobe no pedestal e fica tremendo de medo, sem levar tiro.

const WHIP_COLOR := Color("c08a4e")
const WHIP_OUTLINE := Color("1b1410")
const WHIP_SEGMENTS := 14

@export var whip_length := 190.0

## 0 = chicote caído, 1 = erguido acima da cabeça, 2 = estalando no chão.
var whip_pose := 0.0
## Encolhido de medo (fases 2 e 3).
var cowering := false
## Reverência no fim da luta (0 a 1).
var bow := 0.0

var _time := 0.0
var _flash := 0.0

@onready var body: Sprite2D = $Body
@onready var hand: Marker2D = $Body/Hand
@onready var whip: Line2D = $Whip
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: EnemyHitbox = $Hitbox
var _whip_outline := Line2D.new()


func _ready() -> void:
	# Contorno escuro por baixo para o chicote aparecer em qualquer fundo.
	_whip_outline.width = 13.0
	_whip_outline.default_color = WHIP_OUTLINE
	_whip_outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_whip_outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_whip_outline)
	move_child(_whip_outline, whip.get_index())
	whip.width = 7.0
	whip.default_color = WHIP_COLOR
	whip.begin_cap_mode = Line2D.LINE_CAP_ROUND
	whip.end_cap_mode = Line2D.LINE_CAP_ROUND
	whip.width_curve = Curve.new()
	whip.width_curve.add_point(Vector2(0, 1))
	whip.width_curve.add_point(Vector2(1, 0.3))
	_whip_outline.width_curve = whip.width_curve


func _process(delta: float) -> void:
	_time += delta
	if cowering:
		# Tremendo, encolhido e inclinado para trás, de olho no leão.
		body.position = Vector2(sin(_time * 70.0) * 3.0, 14.0)
		body.scale = Vector2(1.12, 0.78)
		body.rotation = 0.22 + sin(_time * 35.0) * 0.03
	else:
		body.position = Vector2(0, sin(_time * 2.2 * TAU * 0.5) * 2.0)
		body.scale = Vector2(1.0, 1.0 + sin(_time * 2.2) * 0.01)
		body.rotation = -bow * 0.5
	_flash = maxf(_flash - delta * 6.0, 0.0)
	body.modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6)
	_update_whip()


func flash() -> void:
	_flash = 0.5


## Fases 2 e 3: corre para cima do pedestal e não leva mais tiro nem machuca.
func flee_to(spot: Vector2) -> void:
	global_position = spot
	cowering = true
	whip_pose = 0.0
	set_vulnerable(false)


func set_vulnerable(value: bool) -> void:
	hurtbox.monitorable = value
	hitbox.active = value


## Ponta do chicote (onde nasce a onda da chicotada).
func whip_tip() -> Vector2:
	return whip.to_global(whip.points[-1])


func _update_whip() -> void:
	var start := whip.to_local(hand.global_position)
	var points := PackedVector2Array()
	for i in WHIP_SEGMENTS + 1:
		var u := float(i) / WHIP_SEGMENTS
		var hang := Vector2(-20.0 * u, 60.0 * u * u + 30.0 * u) + Vector2(sin(_time * 3.0 + u * 4.0) * 6.0 * u, 0)
		var raised := Vector2(30.0 * u - 40.0 * u * u, -whip_length * 0.75 * u) + Vector2(sin(_time * 14.0 + u * 6.0) * 8.0 * u, 0)
		var lashed := Vector2(-whip_length * u, (whip_length * 0.45) * u * u + 10.0 * u)
		var p: Vector2
		if whip_pose <= 1.0:
			p = hang.lerp(raised, whip_pose)
		else:
			p = raised.lerp(lashed, whip_pose - 1.0)
		points.append(start + p)
	whip.points = points
	_whip_outline.points = points
