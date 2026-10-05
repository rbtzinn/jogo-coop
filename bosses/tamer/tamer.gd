class_name Tamer
extends Node2D
## O Domador: baixinho, bigodudo e convencido. Segura o chicote (desenhado por código,
## uma linha que balança) e o levanta antes de estalar. Quando o leão foge do controle
## (fase 2), ele sobe no pedestal e fica tremendo de medo. Lá em cima continua levando tiro,
## machuca quem encosta e, de tempos em tempos, estala o chicote de medo para um dos lados do
## pedestal (alternando), para ninguém ficar parado ali em segurança.
## Desenhado quadro a quadro (docs/referencias/pecas/domador/, recortado por
## tools/cut_animation_sheet.gd): pronto, chicote erguido, estalo, depois do estalo, o medo e a
## reverência.

const WHIP_COLOR := Color("c08a4e")
const WHIP_OUTLINE := Color("1b1410")
const WHIP_SEGMENTS := 14
const WHIP_ANIM := preload("res://bosses/tamer/art/tamer/whip.tres")
## Punho da frente (de onde sai o chicote) em cada quadro de WHIP_ANIM, no espaço do domador
## (medido na folha: meio da luva em (177, 286), (230, 110), (97, 361) e (182, 264) da célula).
const WHIP_HANDS: Array[Vector2] = [Vector2(-44, -112), Vector2(-15, -210), Vector2(-89, -70), Vector2(-41, -124)]
## Medo (fases 2 e 3): os quadros 1 a 3 tremendo em loop e, de tempos em tempos, o 4 (espiando).
const FEAR_ANIM := preload("res://bosses/tamer/art/tamer/fear.tres")
## Punho da frente em cada quadro de FEAR_ANIM (meio da luva em (192, 346), (211, 346), (187, 347)
## e (210, 345) da célula; as botas desta folha ficam no lugar das do chicote, center_x 211).
const FEAR_HANDS: Array[Vector2] = [Vector2(-11, -78), Vector2(0, -78), Vector2(-13, -78), Vector2(-1, -79)]
const FEAR_FPS := 12.0
const PEEK_EVERY := 2.4
const PEEK_TIME := 0.5
## Reverência no fim da luta, pelo `bow` (0 a 1): tirando a cartola, meio curvado, reverência
## funda e, no fim, segurando a reverência e espiando a plateia.
const BOW_ANIM := preload("res://bosses/tamer/art/tamer/bow.tres")
## Punho da frente em cada quadro de BOW_ANIM (meio da luva em (164, 312), (161, 326), (182, 348)
## e (174, 347) da célula, center_x 199).
const BOW_HANDS: Array[Vector2] = [Vector2(-20, -97), Vector2(-21, -90), Vector2(-10, -77), Vector2(-14, -78)]
## Valores de `bow` em que entra cada quadro seguinte.
const BOW_STEPS: Array[float] = [0.25, 0.6, 0.95]
## Quanto tempo o quadro "depois do estalo" fica antes de voltar ao pronto.
const AFTER_CRACK_TIME := 0.35
## Fases 2 e 3, com medo no pedestal (pedido do usuário em 04/10/2026: ficar do lado dele era seguro):
## a cada LASH_EVERY ele vira para um lado (alternando), ergue o chicote por LASH_WARN (o aviso) e o
## estalo machuca por LASH_HIT, do corpo até passar da beira do pedestal (pulando, passa por cima).
const LASH_EVERY := 2.6
const LASH_WARN := 0.5
const LASH_HIT := 0.25
## Área do estalo no espaço do domador virado para a esquerda (o corpo cobre o meio).
const LASH_AREA := Rect2(-280, -90, 250, 100)

@export var whip_length := 190.0

## 0 = chicote caído, 1 = erguido acima da cabeça, 2 = estalando no chão.
var whip_pose := 0.0
## Encolhido de medo (fases 2 e 3).
var cowering := false
## Ligado pelo chefão nas fases 2 e 3 (fora das trocas de fase): estala o chicote de medo.
var fear_lashes := false
## Reverência no fim da luta (0 a 1).
var bow := 0.0

var _time := 0.0
var _flash := 0.0
## Tempo que ainda falta do quadro "depois do estalo".
var _after_crack := 0.0
var _cracked := false
var _lash_clock := 0.0
var _lashing := false
var _lash_hitbox := EnemyHitbox.new()

@onready var body: Node2D = $Body
@onready var frames: Sprite2D = $Body/Frames
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
	var lash_shape := CollisionShape2D.new()
	var lash_rect := RectangleShape2D.new()
	lash_rect.size = LASH_AREA.size
	lash_shape.shape = lash_rect
	lash_shape.position = LASH_AREA.get_center()
	_lash_hitbox.add_child(lash_shape)
	_lash_hitbox.active = false
	add_child(_lash_hitbox)


func _process(delta: float) -> void:
	_time += delta
	_update_lash(delta)
	if cowering:
		# Encolhido e tremendo (o desenho do medo já treme; aqui só um tremidinho de lado).
		body.position = Vector2(sin(_time * 70.0) * 1.5, 0.0)
		body.scale = Vector2.ONE
		body.rotation = 0.0
	else:
		body.position = Vector2(0, sin(_time * 2.2 * TAU * 0.5) * 2.0)
		body.scale = Vector2(1.0, 1.0 + sin(_time * 2.2) * 0.01)
		body.rotation = 0.0
	_flash = maxf(_flash - delta * 6.0, 0.0)
	body.modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6)
	_show_frame(delta)
	_update_whip()


func flash() -> void:
	_flash = 0.5


## Fases 2 e 3: corre para cima do pedestal. Continua levando tiro e machucando quem encosta.
func flee_to(spot: Vector2) -> void:
	global_position = spot
	cowering = true
	whip_pose = 0.0
	set_vulnerable(true)


func set_vulnerable(value: bool) -> void:
	hurtbox.monitorable = value
	hitbox.active = value


## Chicote de medo (fases 2 e 3): vira para o lado da vez, ergue o chicote (aviso) e estala.
func _update_lash(delta: float) -> void:
	if not fear_lashes or not cowering:
		if _lash_clock > 0.0:
			_lash_clock = 0.0
			_lashing = false
			_lash_hitbox.active = false
			whip_pose = 0.0
			scale.x = 1.0
		return
	_lash_clock += delta
	var side := -1.0 if int(_lash_clock / LASH_EVERY) % 2 == 0 else 1.0
	scale.x = -side
	var t := fmod(_lash_clock, LASH_EVERY) - (LASH_EVERY - LASH_WARN - LASH_HIT)
	_lashing = t >= 0.0
	if t < 0.0:
		whip_pose = 0.0
	elif t < LASH_WARN:
		whip_pose = clampf(t / (LASH_WARN * 0.6), 0.0, 1.0)
	else:
		whip_pose = 2.0
	_lash_hitbox.active = _lashing and t >= LASH_WARN


## Estalando o chicote de medo agora (o golpe está ligado).
func is_lashing() -> bool:
	return _lash_hitbox.active


## Lado do estalo da vez: -1 esquerda, 1 direita.
func lash_side() -> float:
	return -scale.x


func lash_hitbox() -> EnemyHitbox:
	return _lash_hitbox


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


## Quadro: na reverência, pelo `bow`; com medo, o tremor em loop e a espiada; senão, pela pose
## do chicote (pronto, erguido, estalo e, logo depois de estalar, o "depois do estalo"). A mão
## (o começo do chicote) acompanha o punho desenhado.
func _show_frame(delta: float) -> void:
	if bow > 0.0:
		var step := 0
		for b in BOW_STEPS:
			if bow >= b:
				step += 1
		_set_frame(BOW_ANIM, BOW_HANDS, step)
		return
	if cowering and not _lashing:
		var peek := fmod(_time, PEEK_EVERY) > PEEK_EVERY - PEEK_TIME
		_set_frame(FEAR_ANIM, FEAR_HANDS, 3 if peek else int(_time * FEAR_FPS) % 3)
		return
	_after_crack = maxf(_after_crack - delta, 0.0)
	if whip_pose >= 1.5:
		_cracked = true
	elif _cracked and whip_pose < 0.35:
		_cracked = false
		_after_crack = AFTER_CRACK_TIME
	var index := 0
	if whip_pose >= 1.5:
		index = 2
	elif whip_pose >= 0.35:
		index = 1
	elif _after_crack > 0.0:
		index = 3
	_set_frame(WHIP_ANIM, WHIP_HANDS, index)


func _set_frame(animation: FrameAnimation, hands: Array[Vector2], index: int) -> void:
	frames.texture = animation.frames[index]
	frames.scale = Vector2.ONE * animation.frame_scale
	frames.position = animation.origin
	hand.position = hands[index]
