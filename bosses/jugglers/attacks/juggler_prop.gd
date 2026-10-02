class_name JugglerProp
extends EnemyHitbox
## Objeto de malabares dos Irmãos: bola, clave, tocha, bola de boliche ou bola de cura.
## Quem move é o ataque (posição calculada pelo tempo, igual nos dois PCs); este nó só
## desenha, gira e machuca. Os rosa aceitam parry (estouram nos dois PCs).

const INK := Color("1b1410")
const PINK := Color("ff5fa2")
const PINK_LIGHT := Color("ffd1e6")

## ball, club, torch, bowling, heal
@export var kind := &"ball"
@export var pink := false
## Giro do desenho (voltas por segundo).
@export var spin_speed := 2.0

## Identifica o objeto nos dois PCs (para estourar o mesmo quando o parceiro faz parry).
var parry_id := ""
var popped := false

var _time := 0.0


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius()
	shape.shape = circle
	add_child(shape)


func radius() -> float:
	match kind:
		&"bowling":
			return 32.0
		&"club", &"torch":
			return 20.0
		&"heal":
			return 26.0
	return 22.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.3)


func _draw() -> void:
	var main := PINK if pink else _color()
	var angle := _time * spin_speed * TAU
	match kind:
		&"club", &"torch":
			draw_set_transform(Vector2.ZERO, angle)
			# Clave: cabo fino e corpo de garrafa.
			var body := PackedVector2Array([Vector2(-6, -34), Vector2(6, -34), Vector2(14, 6), Vector2(10, 24),
					Vector2(-10, 24), Vector2(-14, 6)])
			draw_colored_polygon(body, main)
			body.append(body[0])
			draw_polyline(body, INK, 4.0, true)
			draw_rect(Rect2(-8, 4, 16, 6), PINK_LIGHT if pink else Color.WHITE)
			if kind == &"torch" and not pink:
				var flicker := 1.0 + sin(_time * 30.0) * 0.15
				draw_circle(Vector2(0, -42), 14 * flicker, Color("ff7a2a"))
				draw_circle(Vector2(0, -44), 8 * flicker, Color("ffd25a"))
			draw_set_transform(Vector2.ZERO)
		&"heal":
			var pulse := 1.0 + sin(_time * 12.0) * 0.08
			draw_circle(Vector2.ZERO, radius() * pulse + 3, INK)
			draw_circle(Vector2.ZERO, radius() * pulse, PINK)
			# Cruz de "cura" no meio.
			draw_rect(Rect2(-5, -14, 10, 28), Color.WHITE)
			draw_rect(Rect2(-14, -5, 28, 10), Color.WHITE)
		_:
			var r := radius()
			draw_circle(Vector2.ZERO, r + 3, INK)
			draw_circle(Vector2.ZERO, r, main)
			if kind == &"bowling":
				for i in 3:
					var hole := Vector2.from_angle(angle + i * 0.7) * r * 0.45
					draw_circle(hole, 4.5, INK)
			else:
				draw_arc(Vector2.ZERO, r * 0.65, angle, angle + PI * 0.8, 10, PINK_LIGHT if pink else Color.WHITE, 4.0)
			draw_circle(Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.5))


func _color() -> Color:
	match kind:
		&"bowling":
			return Color("2a2a3a")
		&"club":
			return Color("f2e6cc")
		&"torch":
			return Color("8a5a32")
	return Color("5fbfd8")
