extends Node2D
## Mapa da Área 1, "O Grande Picadeiro": o parque do circo à noite, com uma tenda para cada
## chefão/fase e a barraca da loja. Os dois andam (sem atirar) e entram numa tenda apertando
## Atirar na frente dela (MapDoor). Ao chegar aqui, o host salva o jogo.
## Fundo provisório desenhado por código.

const SKY_TOP := Color("120d18")
const SKY_BOTTOM := Color("3a2340")
const GROUND := Color("3b2a20")
const FAR := Color("241a2a")
const INK := Color("1b1410")
const BULBS := [Color("ffd25a"), Color("ff7a5a"), Color("8fe3ff")]

var _time := 0.0
var _stars: Array[Vector2] = []

@onready var _tickets: Label = $Hud/Tickets


func _ready() -> void:
	if SaveGame.is_keeper():
		SaveGame.save_game()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		_stars.append(Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 560)))


func _process(delta: float) -> void:
	_time += delta
	var players: Dictionary = SaveGame.data.get("players", {})
	_tickets.text = "Ingressos   Palhaço: %d   ·   Acrobata: %d" % [
		int(players.get("clown", {}).get("tickets", 0)), int(players.get("acrobat", {}).get("tickets", 0))]
	queue_redraw()


func _draw() -> void:
	# Céu em faixas (do escuro para o arroxeado perto do horizonte).
	var bands := 12
	for i in bands:
		var k := float(i) / bands
		draw_rect(Rect2(0, 1000.0 * k, 1920, 1000.0 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, k))
	for i in _stars.size():
		var twinkle := 0.5 + 0.5 * sin(_time * 2.0 + i * 1.7)
		draw_circle(_stars[i], 1.5 + twinkle, Color(1, 0.95, 0.8, 0.3 + 0.5 * twinkle))
	# Lua.
	draw_circle(Vector2(1640, 170), 70, Color("f2e6cc"))
	draw_circle(Vector2(1665, 150), 64, SKY_TOP.lerp(SKY_BOTTOM, 0.15))
	# Silhuetas de tendas e da roda-gigante ao fundo.
	for x: float in [160.0, 560.0, 1180.0, 1500.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 180, 760), Vector2(x, 560), Vector2(x + 180, 760)]), FAR)
		draw_rect(Rect2(x - 180, 760, 360, 240), FAR)
	var wheel := Vector2(900, 520)
	draw_arc(wheel, 220, 0, TAU, 48, FAR, 14.0)
	for i in 8:
		var angle := TAU * i / 8.0 + _time * 0.1
		draw_line(wheel, wheel + Vector2.from_angle(angle) * 220, FAR, 6.0)
		draw_circle(wheel + Vector2.from_angle(angle) * 220, 18, FAR)
	draw_colored_polygon(PackedVector2Array([wheel, Vector2(780, 1000), Vector2(1020, 1000)]), FAR)
	# Varal de lâmpadas atravessando o parque.
	var points := PackedVector2Array()
	for i in 41:
		var x := 1920.0 * i / 40.0
		points.append(Vector2(x, 330 + sin(x / 1920.0 * TAU * 2.0) * 50.0))
	draw_polyline(points, INK, 3.0)
	for i in range(0, points.size(), 2):
		var lit := int(_time * 3.0 + i) % 3
		draw_circle(points[i] + Vector2(0, 8), 7, BULBS[lit])
	# Chão de terra batida.
	draw_rect(Rect2(0, 1000, 1920, 80), GROUND)
	draw_line(Vector2(0, 1000), Vector2(1920, 1000), INK, 4.0)
