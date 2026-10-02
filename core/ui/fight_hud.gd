class_name FightHud
extends Control
## Placar da luta: vida de cada jogador nos cantos de baixo e a vida do chefão no topo.
## Desenhado por código para não depender de arte.

## Placa pequena e baixa: fica sobre a borda do picadeiro, sem tampar os personagens.
const CARD_SIZE := Vector2(270, 58)
const MARGIN := 12.0
const BAR_SIZE := Vector2(760, 26)
const HEART_RED := Color("d23a3a")
const HEART_EMPTY := Color(0.25, 0.18, 0.2, 0.9)

## O chefão precisa ter `bar_ratio()`.
@export var boss_path: NodePath
@export var boss_name := ""

var _boss: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss = get_node_or_null(boss_path)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var players := get_tree().get_nodes_in_group(&"players")
	for i in mini(players.size(), 2):
		var player := players[i] as Player
		var left := i == 0
		var origin := Vector2(MARGIN if left else size.x - MARGIN - CARD_SIZE.x, size.y - MARGIN - CARD_SIZE.y)
		_draw_player_card(player, origin)
	if _boss != null:
		_draw_boss_bar()


func _draw_player_card(player: Player, origin: Vector2) -> void:
	var rect := Rect2(origin, CARD_SIZE)
	draw_rect(rect.grow(4), UiTheme.INK)
	draw_rect(rect, UiTheme.NIGHT)
	draw_rect(Rect2(origin, Vector2(CARD_SIZE.x, 6)), UiTheme.GOLD)
	var font := UiTheme.BODY_FONT
	var name_text: String = player.rig.display_name if player.rig != null else String(player.name)
	draw_string(font, origin + Vector2(14, 40), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiTheme.CREAM)
	var health := player.player_health.health
	if player.player_health.is_downed:
		draw_string(font, origin + Vector2(CARD_SIZE.x - 86, 40), "CAIU!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, HEART_RED)
		return
	for h in health.maximum:
		var center := origin + Vector2(CARD_SIZE.x - 30 - (health.maximum - 1 - h) * 36, 31)
		_draw_heart(center, 13.0, HEART_RED if h < health.current else HEART_EMPTY)


func _draw_heart(center: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		# Curva de coração clássica, virada para a tela (y para baixo).
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		points.append(center + Vector2(x, y) * (r / 16.0))
	draw_colored_polygon(points, color)
	draw_polyline(points, UiTheme.INK, 3.0, true)


func _draw_boss_bar() -> void:
	var origin := Vector2((size.x - BAR_SIZE.x) * 0.5, 64)
	var font := UiTheme.TITLE_FONT
	var text_size := font.get_string_size(boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string_outline(font, Vector2(size.x * 0.5 - text_size.x * 0.5, origin.y - 12), boss_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, UiTheme.INK)
	draw_string(font, Vector2(size.x * 0.5 - text_size.x * 0.5, origin.y - 12), boss_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UiTheme.CREAM)
	var rect := Rect2(origin, BAR_SIZE)
	draw_rect(rect.grow(4), UiTheme.INK)
	draw_rect(rect, UiTheme.NIGHT)
	var ratio: float = _boss.bar_ratio()
	draw_rect(Rect2(origin, Vector2(BAR_SIZE.x * ratio, BAR_SIZE.y)), UiTheme.RED)
	draw_rect(Rect2(origin, Vector2(BAR_SIZE.x * ratio, 6)), Color(1, 1, 1, 0.18))
