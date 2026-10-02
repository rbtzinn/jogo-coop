class_name FightHud
extends Control
## Placar da luta em estilo de circo, desenhado por código:
## - no topo, o letreiro do chefão com lâmpadas correndo, barra de vida listrada,
##   rastro do dano e estrelas marcando onde cada fase começa;
## - nos cantos de baixo, um "ingresso" para cada jogador com os corações.

const BAR_PANEL := Vector2(820, 100)
const BAR_SIZE := Vector2(720, 26)
const TICKET := Vector2(290, 62)
const MARGIN := 12.0
const HEART_RED := Color("d23a3a")
const HEART_EMPTY := Color(0.55, 0.45, 0.38, 0.55)
const TICKET_PAPER := Color("f2e6cc")
const TICKET_RED := Color("a3282a")

## O chefão precisa ter `bar_ratio()`; `phase_markers()` é opcional.
@export var boss_path: NodePath
@export var boss_name := ""

var _boss: Node
var _time := 0.0
## Barra "atrasada" que mostra o dano recente sumindo devagar.
var _trail := 1.0
var _shown := 1.0
var _shake := 0.0
var _passed_markers: Array[float] = []
var _marker_pop := {}
## Corações de cada jogador no quadro anterior (para animar o coração perdido).
var _last_hearts := {}
var _heart_pops: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss = get_node_or_null(boss_path)
	if _boss != null:
		var marquee := MarqueeLights.new()
		marquee.position = Vector2((1920.0 - BAR_PANEL.x) * 0.5, 14)
		marquee.size = BAR_PANEL
		add_child(marquee)


func _process(delta: float) -> void:
	_time += delta
	if _boss != null:
		var ratio: float = _boss.bar_ratio()
		if ratio < _shown - 0.0001:
			_shake = 0.12
		_shown = ratio
		# O rastro espera um pouco e desce suave atrás da vida.
		_trail = move_toward(_trail, ratio, delta * (0.25 if _trail - ratio < 0.02 else 0.6))
		if _boss.has_method("phase_markers"):
			for marker: float in _boss.phase_markers():
				if ratio <= marker and marker not in _passed_markers:
					_passed_markers.append(marker)
					_marker_pop[marker] = 1.0
	_shake = maxf(_shake - delta, 0.0)
	for key in _marker_pop:
		_marker_pop[key] = maxf(_marker_pop[key] - delta * 1.5, 0.0)
	for pop in _heart_pops:
		pop[1] += delta
	_heart_pops = _heart_pops.filter(func(pop: Array) -> bool: return pop[1] < 0.6)
	queue_redraw()


func _draw() -> void:
	var players := get_tree().get_nodes_in_group(&"players")
	for i in mini(players.size(), 2):
		var player := players[i] as Player
		var origin := Vector2(MARGIN if i == 0 else size.x - MARGIN - TICKET.x, size.y - MARGIN - TICKET.y)
		_draw_ticket(player, origin)
	for pop in _heart_pops:
		var k: float = pop[1] / 0.6
		_draw_heart(pop[0] + Vector2(0, -30.0 * k), 13.0 * (1.0 + k), Color(HEART_RED, 1.0 - k))
	if _boss != null:
		_draw_boss_marquee()


# --- Letreiro do chefão ---

func _draw_boss_marquee() -> void:
	var shake := Vector2(randf_range(-4, 4), randf_range(-2, 2)) if _shake > 0.0 else Vector2.ZERO
	var panel := Rect2(Vector2((size.x - BAR_PANEL.x) * 0.5, 14) + shake, BAR_PANEL)
	draw_rect(panel.grow(6), UiTheme.INK)
	draw_rect(panel.grow(3), UiTheme.GOLD)
	draw_rect(panel, UiTheme.RED_DARK)
	# Listras verticais discretas, como lona de circo.
	var stripe := 40.0
	var x := panel.position.x
	var odd := false
	while x < panel.end.x:
		if odd:
			draw_rect(Rect2(Vector2(x, panel.position.y), Vector2(minf(stripe, panel.end.x - x), panel.size.y)), Color(UiTheme.RED, 0.5))
		odd = not odd
		x += stripe
	var font := UiTheme.TITLE_FONT
	var title_size := font.get_string_size(boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	var title_at := Vector2(panel.get_center().x - title_size.x * 0.5, panel.position.y + 40)
	draw_string_outline(font, title_at, boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, UiTheme.INK)
	draw_string(font, title_at, boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UiTheme.CREAM)

	var bar := Rect2(Vector2(panel.get_center().x - BAR_SIZE.x * 0.5, panel.position.y + 56), BAR_SIZE)
	draw_rect(bar.grow(4), UiTheme.INK)
	draw_rect(bar, UiTheme.NIGHT)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _trail, bar.size.y)), UiTheme.GOLD)
	var fill := Rect2(bar.position, Vector2(bar.size.x * _shown, bar.size.y))
	draw_rect(fill, Color("c8302c"))
	_draw_candy_stripes(fill)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 6)), Color(1, 1, 1, 0.2))
	if _boss.has_method("phase_markers"):
		for marker: float in _boss.phase_markers():
			var passed := marker in _passed_markers
			var pop: float = _marker_pop.get(marker, 0.0)
			var at := Vector2(bar.position.x + bar.size.x * marker, bar.get_center().y)
			draw_line(at + Vector2(0, -bar.size.y * 0.5), at + Vector2(0, bar.size.y * 0.5), UiTheme.INK, 4.0)
			_draw_star(at, 15.0 + pop * 14.0, Color("6b5a40") if passed and pop <= 0.0 else UiTheme.GOLD)


func _draw_candy_stripes(fill: Rect2) -> void:
	if fill.size.x <= 0.0:
		return
	var spacing := 26.0
	var offset := fmod(_time * 40.0, spacing)
	var x := fill.position.x - fill.size.y - spacing + offset
	while x < fill.end.x:
		var a := Vector2(maxf(x, fill.position.x), fill.end.y)
		var b := Vector2(minf(x + fill.size.y, fill.end.x), fill.position.y)
		if b.x > a.x:
			draw_line(a, b, Color(1.0, 0.85, 0.7, 0.28), 8.0)
		x += spacing


# --- Ingresso de cada jogador ---

func _draw_ticket(player: Player, origin: Vector2) -> void:
	var outline := _ticket_shape(origin, TICKET, 10.0)
	draw_colored_polygon(_ticket_shape(origin + Vector2(4, 5), TICKET, 10.0), Color(0, 0, 0, 0.35))
	draw_colored_polygon(outline, TICKET_PAPER)
	var border := outline.duplicate()
	border.append(outline[0])
	draw_polyline(border, UiTheme.INK, 5.0, true)
	draw_polyline(_ticket_shape(origin + Vector2(6, 6), TICKET - Vector2(12, 12), 7.0), TICKET_RED, 2.5, true)
	# Picote do ingresso.
	var cut_x := origin.x + 116.0
	var y := origin.y + 8.0
	while y < origin.y + TICKET.y - 8.0:
		draw_line(Vector2(cut_x, y), Vector2(cut_x, y + 5.0), TICKET_RED, 2.0)
		y += 10.0
	var name_text: String = player.rig.display_name if player.rig != null else String(player.name)
	var font := UiTheme.TITLE_FONT
	draw_string(font, origin + Vector2(14, 39), name_text, HORIZONTAL_ALIGNMENT_LEFT, 100, 18, TICKET_RED)
	var health := player.player_health.health
	var key := String(player.name)
	var hearts_origin := origin + Vector2(150, TICKET.y * 0.5)
	if _last_hearts.has(key) and health.current < _last_hearts[key]:
		for h in range(health.current, _last_hearts[key]):
			_heart_pops.append([hearts_origin + Vector2(h * 38, 0), 0.0])
	_last_hearts[key] = health.current
	if player.player_health.is_downed:
		_draw_stamp(origin + Vector2(200, TICKET.y * 0.5), "CAIU!")
		return
	for h in health.maximum:
		var beat := 1.0 + (sin(_time * 8.0) * 0.08 if health.current == 1 and h == 0 else 0.0)
		_draw_heart(hearts_origin + Vector2(h * 38, 0), 13.0 * beat, HEART_RED if h < health.current else HEART_EMPTY)


static func _ticket_shape(origin: Vector2, ticket_size: Vector2, notch: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var mid := ticket_size.y * 0.5
	points.append(origin)
	points.append(origin + Vector2(ticket_size.x, 0))
	for i in 9:
		var angle := -PI * 0.5 + PI * i / 8.0
		points.append(origin + Vector2(ticket_size.x, mid) - Vector2(cos(angle), -sin(angle)) * notch)
	points.append(origin + ticket_size)
	points.append(origin + Vector2(0, ticket_size.y))
	for i in 9:
		var angle := PI * 0.5 - PI * i / 8.0
		points.append(origin + Vector2(0, mid) + Vector2(cos(angle), sin(angle)) * notch)
	return points


func _draw_stamp(center: Vector2, text: String) -> void:
	var font := UiTheme.TITLE_FONT
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	draw_set_transform(center, -0.15, Vector2.ONE)
	var box := Rect2(-text_size * 0.5 - Vector2(10, 4), text_size + Vector2(20, 8))
	draw_rect(box, Color(HEART_RED, 0.15))
	draw_rect(box, HEART_RED, false, 3.0)
	draw_string(font, Vector2(-text_size.x * 0.5, text_size.y * 0.32), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, HEART_RED)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Formas ---

func _draw_heart(center: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		# Curva de coração clássica, virada para a tela (y para baixo).
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		points.append(center + Vector2(x, y) * (r / 16.0))
	draw_colored_polygon(points, color)
	draw_polyline(points, Color(UiTheme.INK, color.a), 3.0, true)
	draw_circle(center + Vector2(-r * 0.35, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.45 * color.a))


func _draw_star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, UiTheme.INK, 3.0, true)
