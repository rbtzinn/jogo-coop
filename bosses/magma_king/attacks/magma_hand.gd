class_name MagmaHand
extends Node2D
## Mão de basalto do Rei Magma que sai do lago e se arrasta pelo chão atrás da coroa (Coroa Pesada).
## Leva tiro (Hurtbox: o chefão conta os tiros como dano da mão, não do rei) e machuca quem encosta.
## Abre e fecha enquanto se arrasta; recua quando os tiros a vencem.

const ANIM := preload("res://bosses/magma_king/art/hand.tres")
const SIZE := Vector2(150, 92)

## Abrindo e fechando (0 a 1, tempo do arrasto).
var crawl := 0.0
## Recuou (vencida): some afundando.
var beaten := false

var _flash := 0.0
var _sprite := Sprite2D.new()

@onready var hurtbox := Hurtbox.new()
@onready var hitbox := EnemyHitbox.new()


func _ready() -> void:
	_sprite.centered = false
	add_child(_sprite)
	for area: Area2D in [hurtbox, hitbox]:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = SIZE
		shape.shape = rect
		shape.position = Vector2(0, -SIZE.y * 0.5)
		area.add_child(shape)
		add_child(area)


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	var index := 0 if fposmod(crawl, 1.0) < 0.5 else 1
	_sprite.texture = ANIM.frames[index]
	_sprite.scale = Vector2.ONE * ANIM.frame_scale
	_sprite.position = ANIM.origin
	var glow := 0.7 if _flash > 0.0 else 0.0
	_sprite.modulate = Color(1.0 + glow, 1.0 + glow * 0.8, 1.0 + glow * 0.6)


func set_beaten() -> void:
	beaten = true
	hurtbox.monitorable = false
	hitbox.active = false


func flash() -> void:
	_flash = 0.08
