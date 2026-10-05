class_name GiantMagician
extends Node2D
## Fase 3, "O Grande Final": Zaratan vira um mágico gigante saindo da escuridão (só cabeça,
## cartola e as duas mãos enormes, que são nós GiantHand separados).
## O ponto do nó é o meio da cabeça. Filhos esperados: Hurtbox (a cabeça leva tiro).
## Desenhado (M8): o rosto de frente (4 desenhos) e a cartola da M1 como peça separada, girada pelo
## `hat_tilt` em volta do meio da aba (170 px acima do meio da cabeça). O desenho do rosto: 4 (tonto)
## desde a derrota e enquanto encolhe; 2 (gargalhada) com `laugh` >= 0,5; 3 (bravo) por ANGRY_TIME depois de
## levar tiro, no máximo uma vez a cada ANGRY_EVERY (debaixo de tiro ele não fica bravo o tempo todo);
## 1 (sorriso) no resto. O balanço, o clarão do tiro e o encolher continuam por código.

const FACE_ANIM := preload("res://bosses/magician/art/face.tres")
const HAT_TEXTURE := preload("res://bosses/magician/art/giant_hat.png")
## Meio da aba na imagem da cartola, e a largura da aba no jogo (a da cartola do código).
const HAT_BRIM := Vector2(191.5, 182.0)
const HAT_WIDTH := 400.0
const HAT_BRIM_WIDTH_PX := 383.0
const ANGRY_TIME := 0.25
const ANGRY_EVERY := 1.0

## Inclinação da cartola (para despejar coisas).
var hat_tilt := 0.0
## Boca aberta (0 a 1): gargalhada.
var laugh := 0.0
## Encolhendo para dentro da cartola no fim (0 a 1).
var shrink := 0.0
## Perdeu (o chefão avisa): fica tonto desde já, antes de começar a encolher.
var defeated := false

var _time := 0.0
var _flash := 0.0
var _angry := 0.0
var _angry_cooldown := 0.0
var _face_holder := Node2D.new()
var _face := Sprite2D.new()
var _hat_holder := Node2D.new()
var _hat := Sprite2D.new()

@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	_face.centered = false
	_face.scale = Vector2.ONE * FACE_ANIM.frame_scale
	_face.position = FACE_ANIM.origin
	_face_holder.add_child(_face)
	_face_holder.show_behind_parent = true
	add_child(_face_holder)
	_hat.texture = HAT_TEXTURE
	_hat.centered = false
	var hat_scale := HAT_WIDTH / HAT_BRIM_WIDTH_PX
	_hat.scale = Vector2.ONE * hat_scale
	_hat.position = -HAT_BRIM * hat_scale
	_hat_holder.add_child(_hat)
	_hat_holder.show_behind_parent = true
	add_child(_hat_holder)
	_process(0.0)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	_angry = maxf(_angry - delta, 0.0)
	_angry_cooldown = maxf(_angry_cooldown - delta, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6)
	var s := 1.0 - shrink
	_face_holder.visible = s > 0.01
	_hat_holder.visible = s > 0.01
	var head := Vector2(0, sin(_time * 1.6) * 8.0)
	var lift := Vector2(0, shrink * -200.0)
	_face_holder.position = lift + head * s
	_face_holder.scale = Vector2(s, s)
	_hat_holder.position = lift + (head + Vector2(0, -170)) * s
	_hat_holder.rotation = hat_tilt
	_hat_holder.scale = Vector2(s, s)
	_face.texture = FACE_ANIM.frames[face_frame()]


## Desenho do rosto (0 a 3) agora.
func face_frame() -> int:
	if defeated or shrink > 0.0:
		return 3
	if laugh >= 0.5:
		return 1
	if _angry > 0.0:
		return 2
	return 0


func flash() -> void:
	_flash = 0.5
	if _angry_cooldown <= 0.0:
		_angry = ANGRY_TIME
		_angry_cooldown = ANGRY_EVERY


## Boca da cartola (de onde caem as coisas), no mundo.
func hat_mouth() -> Vector2:
	return global_position + Vector2(0, -170) + Vector2(0, -300).rotated(hat_tilt)
