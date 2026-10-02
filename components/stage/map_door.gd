class_name MapDoor
extends Area2D
## Entrada no mapa do parque (uma tenda): o jogador para na frente e aperta Atirar para entrar.
## Mostra o nome, a melhor nota da dupla naquele chefão e se está fechada ("Em breve" quando a
## fase ainda não existe, ou cadeado quando falta vencer outros chefões).
## Online, qualquer um dos dois pode escolher; quem troca a fase é o host (o cliente pede).
## Desenho provisório feito por código (tenda listrada), trocável por arte depois.

const INK := Color("1b1410")
const CREAM := Color("f2e6cc")
const GOLD := Color("d9a441")
const SIZE := Vector2(300, 330)

@export var title := ""
## Cena que abre ao entrar (vazio = "Em breve").
@export_file("*.tscn") var target_scene := ""
## Identifica o chefão/fase no save (para a nota e para os cadeados).
@export var level_id := ""
## Só abre depois de vencer estes (ids do save).
@export var requires: Array[String] = []
@export var stripe_color := Color("a3282a")

var _near := false
var _time := 0.0
var _shake := 0.0
var _message := ""
var _message_time := 0.0
var _key_name := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(2, true)
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SIZE.x * 0.6, 160)
	shape.shape = rect
	shape.position = Vector2(0, -80)
	add_child(shape)
	_key_name = _shoot_key_name()
	Settings.changed.connect(func() -> void: _key_name = _shoot_key_name())


func _physics_process(delta: float) -> void:
	_time += delta
	_shake = maxf(_shake - delta, 0.0)
	_message_time = maxf(_message_time - delta, 0.0)
	_near = false
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.is_inside_tree() or not player.is_multiplayer_authority() or not player.input.local_control \
				or not overlaps_body(player):
			continue
		_near = true
		if player.input.shoot_pressed:
			try_enter()
	queue_redraw()


func is_open() -> bool:
	return not target_scene.is_empty() and missing().is_empty()


## Ids que ainda faltam vencer para abrir.
func missing() -> Array[String]:
	var result: Array[String] = []
	for id in requires:
		if not SaveGame.is_defeated(id):
			result.append(id)
	return result


func try_enter() -> void:
	if not is_open():
		_shake = 0.3
		_message = "Em breve!" if target_scene.is_empty() else "Vençam os outros números primeiro!"
		_message_time = 1.8
		return
	if Network.is_online() and not Network.is_host():
		_request_enter.rpc_id(1)
	else:
		_enter()


@rpc("any_peer", "call_remote", "reliable")
func _request_enter() -> void:
	Network.deliver(_enter_if_open, false)


func _enter_if_open() -> void:
	if is_open():
		_enter()


func _enter() -> void:
	SaveGame.save_game()
	Network.change_level(target_scene)


func _draw() -> void:
	var shake := Vector2(sin(_time * 60.0) * 6.0 * _shake / 0.3, 0)
	draw_set_transform(shake)
	var w := SIZE.x
	var h := SIZE.y
	var open := is_open()
	var dim := 1.0 if open else 0.55
	# Lona listrada (triângulo do telhado + corpo).
	var body_top := -h * 0.55
	var stripes := 8
	for i in stripes:
		var x0 := -w * 0.5 + w * i / stripes
		var x1 := -w * 0.5 + w * (i + 1) / stripes
		var color := (stripe_color if i % 2 == 0 else CREAM) * Color(dim, dim, dim)
		draw_colored_polygon(PackedVector2Array([Vector2(x0, body_top), Vector2(x1, body_top), Vector2(x1, 0), Vector2(x0, 0)]), color)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -h), Vector2(x0, body_top), Vector2(x1, body_top)]), color)
	draw_polyline(PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.5, body_top), Vector2(0, -h),
			Vector2(w * 0.5, body_top), Vector2(w * 0.5, 0)]), INK, 5.0)
	# Bandeirinha no topo.
	var wave := sin(_time * 4.0) * 6.0
	draw_line(Vector2(0, -h), Vector2(0, -h - 50), INK, 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -h - 50), Vector2(40, -h - 40 + wave), Vector2(0, -h - 28)]), GOLD)
	# Porta (cortina aberta).
	var door := Rect2(-55, -150, 110, 150)
	draw_rect(door, Color("2a1f2e") if open else Color("3a3236"))
	draw_rect(door, INK, false, 4.0)
	# Placa com o nome.
	var font := UiTheme.TITLE_FONT
	var size := 24
	var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var sign_rect := Rect2(-maxf(text_size.x * 0.5 + 16, 110), body_top - 6, maxf(text_size.x + 32, 220), 44)
	draw_rect(sign_rect, CREAM)
	draw_rect(sign_rect, INK, false, 4.0)
	draw_string(font, Vector2(-text_size.x * 0.5, body_top + 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("6e1c1b"))
	# Nota da dupla (carimbo) ou cadeado.
	if not level_id.is_empty() and SaveGame.is_defeated(level_id):
		var grade: String = SaveGame.data.bosses[level_id].get("best_grade", "")
		if not grade.is_empty():
			_draw_stamp(Vector2(w * 0.32, -h * 0.72), grade)
	if target_scene.is_empty():
		_draw_ribbon("EM BREVE")
	elif not open:
		_draw_ribbon("FECHADO")
	draw_set_transform(Vector2.ZERO)
	# Dica ou mensagem em cima da tenda.
	var hint := _message if _message_time > 0.0 else ("%s: entrar" % _key_name if _near else "")
	if not hint.is_empty():
		var hint_size := UiTheme.BODY_FONT.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
		var at := Vector2(-hint_size.x * 0.5, -h - 80 + sin(_time * 5.0) * 4.0)
		draw_string_outline(UiTheme.BODY_FONT, at, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, INK)
		draw_string(UiTheme.BODY_FONT, at, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, CREAM)


func _draw_stamp(center: Vector2, text: String) -> void:
	draw_circle(center, 36, Color(GOLD, 0.95))
	draw_arc(center, 36, 0, TAU, 32, INK, 4.0)
	var font := UiTheme.TITLE_FONT
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40)
	draw_string(font, center + Vector2(-text_size.x * 0.5, 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("6e1c1b"))


func _draw_ribbon(text: String) -> void:
	var rect := Rect2(-SIZE.x * 0.45, -110, SIZE.x * 0.9, 46)
	draw_set_transform(Vector2.ZERO, -0.12)
	draw_rect(rect, Color("6e1c1b"))
	draw_rect(rect, INK, false, 4.0)
	var font := UiTheme.TITLE_FONT
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(font, Vector2(-text_size.x * 0.5, rect.position.y + 34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, CREAM)
	draw_set_transform(Vector2.ZERO)


## Nome da tecla de atirar (a 1ª do teclado), para a dica "J: entrar".
static func _shoot_key_name() -> String:
	for slot in Settings.KEYBOARD_SLOTS:
		var event := Settings.get_binding(&"shoot", slot)
		if event != null:
			return InputSerializer.display_name(event)
	return "Atirar"
