class_name CarretelActor
extends Node2D
## Usa os quadros aprovados, com caixas do corpo separadas das luvas/adereços.
const FRAMES := preload("res://bosses/madame_carretel/art/carretel_frames.tres")
const BUTTONS := [Vector2(0,-285),Vector2(0,-198),Vector2(0,-110)]
var sprite := AnimatedSprite2D.new()
var hurtbox := Hurtbox.new()
var head := Hurtbox.new()
var hitbox := EnemyHitbox.new()
var buttons: Array[Hurtbox] = []
var armored := false
var weak_open := false
var defeated := false
var pose_animation: StringName = &"idle"
var pose_frame := 0
var _flash := 0.0
var _flash_cooldown := 0.0
var _idle := true
var _time := 0.0
var glow := ButtonGlow.new()

class ButtonGlow extends Node2D:
	var open := false
	var clock := 0.0
	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()
	func _draw() -> void:
		if not open: return
		for at: Vector2 in CarretelActor.BUTTONS:
			draw_arc(at,39+sin(clock*5)*2,0,TAU,32,Color("fff2cb"),3.0,true)

func _ready() -> void:
	sprite.sprite_frames = FRAMES
	sprite.position = Vector2(0,-438)
	add_child(sprite)
	_box(hurtbox,"Hurtbox",Vector2(0,-190),Vector2(310,355))
	_box(head,"Head",Vector2(-25,-490),Vector2(150,155))
	_box(hitbox,"Contact",Vector2(0,-185),Vector2(250,330))
	hitbox.active = false
	for i in 3:
		var target := Hurtbox.new()
		_box(target,"Button%d" % i,BUTTONS[i],Vector2(60,62))
		target.monitorable = false
		buttons.append(target)
	add_child(glow)
	idle()

func _box(area: Area2D,label: String,at: Vector2,size: Vector2) -> void:
	area.name = label
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	area.add_child(shape)
	add_child(area)

func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0,_flash-delta)
	_flash_cooldown = maxf(0.0,_flash_cooldown-delta)
	if _idle:
		pose_animation = &"armor" if armored else &"idle"
		pose_frame = 3 if armored else int(_time*2.0)%4
	sprite.pause()
	sprite.animation = pose_animation
	sprite.frame = pose_frame
	# Tiro contínuo não troca a silhueta nem interrompe a pose de aviso/ataque.
	sprite.modulate = Color(1.5,1.35,1.2) if _flash>0.0 else Color.WHITE
	glow.open = weak_open and not defeated

func pose(animation: StringName,frame: int) -> void:
	_idle = false
	pose_animation = animation
	pose_frame = clampi(frame,0,3)
	# Atualiza também na física, antes da colisão dos golpes deste quadro.
	sprite.pause()
	sprite.animation = pose_animation
	sprite.frame = pose_frame

func idle() -> void:
	_idle = true
	pose(&"armor" if armored else &"idle",3 if armored else 0)
	_idle = true

func flash() -> void:
	if defeated or _flash_cooldown>0.0: return
	_flash = 0.07
	_flash_cooldown = 0.24

func set_weak(open: bool) -> void:
	weak_open = open and armored and not defeated
	hurtbox.set_deferred("monitorable",not weak_open and not defeated)
	head.set_deferred("monitorable",not weak_open and not defeated)
	for target in buttons:
		target.set_deferred("monitorable",weak_open)
