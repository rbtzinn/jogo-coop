class_name ConfettiBall
extends EnemyHitbox
## Bola de confete do canhão: rola rente ao chão (pular por cima). A rosa aceita parry.

const INK := Color("1b1410")
const COLORS := [Color("ffc93c"), Color("5fbfd8"), Color("d23a3a"), Color("8fd86a")]

@export var pink := false

var parry_id := ""
var _time := 0.0


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ConfettiCannon.BALL_RADIUS
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func on_parried() -> void:
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.1)


func _draw() -> void:
	var r := ConfettiCannon.BALL_RADIUS
	draw_circle(Vector2.ZERO, r + 3, INK)
	draw_circle(Vector2.ZERO, r, Color("ff5fa2") if pink else Color("f2e6cc"))
	for i in 6:
		var a := -_time * 9.0 + TAU * i / 6.0
		draw_circle(Vector2.from_angle(a) * r * 0.55, 3.5, Color.WHITE if pink else COLORS[i % COLORS.size()])
