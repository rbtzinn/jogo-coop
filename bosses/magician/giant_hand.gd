class_name GiantHand
extends Node2D
## Mão enorme do mágico gigante (luva branca). Aberta pairando, fechada quando agarra. A área que
## machuca (EnemyHitbox filho "Hitbox") só fica ligada no golpe.
## Desenhada quadro a quadro (M7): a folha é a mão da esquerda da tela (polegar para a direita); a da
## direita é a mesma espelhada. O desenho sai do `closed`: 1 (aberta) até 0,17, 2 até 0,5, 3 até 0,83 e
## 4 (punho) depois. O pivô do desenho é o nó (meio do punho, ~110 px acima do fundo dele).

const HAND_ANIM := preload("res://bosses/magician/art/hand.tres")
const STEPS := [0.17, 0.5, 0.83]

## -1 = mão esquerda (polegar à direita), 1 = mão direita.
@export var side := 1.0
## 0 = aberta, 1 = fechada (punho).
var closed := 0.0
## 0 = some na escuridão, 1 = à vista.
var presence := 1.0

var _art_holder := Node2D.new()
var _art := Sprite2D.new()

@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	hitbox.active = false
	_art.centered = false
	_art.scale = Vector2.ONE * HAND_ANIM.frame_scale
	_art.position = HAND_ANIM.origin
	_art_holder.add_child(_art)
	_art_holder.show_behind_parent = true
	add_child(_art_holder)
	_process(0.0)


func _process(_delta: float) -> void:
	modulate.a = presence
	_art.texture = HAND_ANIM.frames[art_frame()]
	_art_holder.scale.x = -side


## Desenho da folha (0 a 3) para o `closed` de agora.
func art_frame() -> int:
	var frame := 0
	for step: float in STEPS:
		if closed >= step:
			frame += 1
	return frame
