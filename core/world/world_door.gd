class_name WorldDoor
extends Area3D
## Entrada no mundo 3D da aventura: uma tenda (chefão ou fase), a barraca da loja ou o carroção do
## Camarim. Quem chega na frente e aperta Atirar entra.
## Tenda de chefão online: os DOIS precisam estar na frente dela (ninguém é levado para a luta sem
## ter ido até lá); quem chega primeiro vê "Esperando o parceiro". Quem troca a fase é o host.
## Sozinho, o parceiro segue você, então basta quem você controla.
## Mostra o nome, a melhor nota e o cadeado. Desenho provisório (formas simples), trocável por arte.

const INK := Color("1b1410")
const CREAM := Color("f2e6cc")
## Tamanho da área de entrada, na frente da tenda (metros).
const ZONE := Vector3(3.0, 2.0, 2.2)

@export var title := ""
## Cena que abre ao entrar (vazio = "Em breve").
@export_file("*.tscn") var target_scene := ""
## Identifica o chefão/fase no save (para a nota e para os cadeados).
@export var level_id := ""
## Só abre depois de vencer estes (ids do save).
@export var requires: Array[String] = []
@export var stripe_color := Color("a3282a")
## Em vez de trocar de fase, abre a loja para quem entrou.
@export var opens_shop := false
## Em vez de trocar de fase, abre o Camarim (o carroção perto do portão).
@export var opens_dressing_room := false
## Tamanho da tenda (raio em metros).
@export var radius := 2.2

## Como a atração aparece: "tent" (tenda de chefão), "stall" (barraca de vendedor), "wagon"
## (carroção), "station" (estação do trem), "big_top" (a tenda grande do Mágico), "lion_tent" (tenda
## com o portão de cabeça de leão na frente: o Domador).
@export_enum("tent", "stall", "wagon", "station", "big_top", "lion_tent") var landmark := "tent"
## Altura do corpo da tenda (metros).
@export var height := 2.2
## Falso: só colisão e área de entrada; o desenho vem do parque renderizado e o aviso vai para a tela
## (status_text/status_color, lidos pelo mapa).
@export var draw_landmark := true

var _sign := Label3D.new()
var _status := Label3D.new()
var _message := ""
var _message_time := 0.0
var _waiting := false
var _zone_center := Vector3.ZERO
## O aviso atual (vazio = nada) e o tipo: "enter" (pode entrar), "closed", "grade" ou "message".
var status_text := ""
var status_kind := ""
var status_color := CREAM


func _ready() -> void:
	add_to_group(&"world_doors")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var front := _front_distance()
	_zone_center = Vector3(0, 1.0, front + ZONE.z * 0.5 - 0.2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = ZONE
	shape.shape = box
	shape.position = _zone_center
	add_child(shape)
	_build_landmark()
	_build_sign(front)


## Distância do meio da atração até a frente dela (onde fica a placa e a área de entrada).
func _front_distance() -> float:
	match landmark:
		"stall":
			return 2.2
		"wagon":
			return 1.1
		"station":
			return 2.6
		"lion_tent":
			return radius + 0.9
	return radius + 0.2


## Placa de madeira pintada num poste, na frente da atração, com o nome; o aviso (entrar, nota,
## fechado) fica numa faixinha logo acima.
func _build_sign(front: float) -> void:
	var post := Node3D.new()
	add_child(post)
	post.position = Vector3(radius * 0.55 + 0.6, 0, front + 0.3) if landmark != "station" else Vector3(-1.6, 0, front)
	if not draw_landmark:
		_sign.free()
		_status.visible = false
		post.add_child(_status)
		return
	WorldProps.cylinder(post, 0.05, 0.06, 1.7, WorldProps.paint(WorldProps.WOOD_DARK, 0.01), Vector3(0, 0.85, 0), Vector3.ZERO, 8)
	var board_width := clampf(title.length() * 0.19 + 0.5, 1.3, 2.8)
	var board := WorldProps.box(post, Vector3(board_width, 0.55, 0.08), WorldProps.paint(stripe_color.darkened(0.35), 0.015), Vector3(0, 1.75, 0), Vector3(-0.35, 0, 0))
	WorldProps.box(board, Vector3(board_width + 0.12, 0.08, 0.1), WorldProps.paint(WorldProps.GOLD), Vector3(0, 0.3, 0))
	WorldProps.box(board, Vector3(board_width + 0.12, 0.08, 0.1), WorldProps.paint(WorldProps.GOLD), Vector3(0, -0.3, 0))
	_sign.text = title
	_sign.font = UiTheme.TITLE_FONT
	_sign.font_size = 64
	_sign.pixel_size = 0.0045
	_sign.outline_size = 10
	_sign.modulate = CREAM
	_sign.outline_modulate = INK
	_sign.position = Vector3(0, 0, 0.06)
	_sign.double_sided = false
	board.add_child(_sign)
	_status.font = UiTheme.BODY_FONT
	_status.font_size = 60
	_status.pixel_size = 0.004
	_status.outline_size = 14
	_status.outline_modulate = INK
	_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status.no_depth_test = true
	_status.position = Vector3(0, 2.45, 0)
	post.add_child(_status)


func _build_landmark() -> void:
	var dim := 1.0 if is_open() else 0.55
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	var shape := CollisionShape3D.new()
	match landmark:
		"stall":
			WorldProps.shop_wagon(body)
			var b := BoxShape3D.new()
			b.size = Vector3(3.6, 2.5, 2.2)
			shape.shape = b
			shape.position = Vector3(0, 1.25, 0)
		"wagon":
			WorldProps.dressing_wagon(body, stripe_color)
			var b := BoxShape3D.new()
			b.size = Vector3(3.2, 2.5, 1.8)
			shape.shape = b
			shape.position = Vector3(0, 1.25, 0)
		"station":
			WorldProps.station(body, Vector3.ZERO)
			var b := BoxShape3D.new()
			b.size = Vector3(4.6, 1.0, 1.8)
			shape.shape = b
			shape.position = Vector3(0, 0.5, 0)
		_:
			WorldProps.tent(body, radius, height, stripe_color, WorldProps.GOLD if landmark == "big_top" else CREAM.darkened(0.1), dim)
			if landmark == "lion_tent":
				WorldProps.lion_gate(body, Vector3(0, 0, radius + 0.2), 1.15)
			var c := CylinderShape3D.new()
			c.radius = radius
			c.height = height + radius
			shape.shape = c
			shape.position.y = c.height * 0.5
	body.add_child(shape)
	if not draw_landmark:
		for item in body.find_children("*", "GeometryInstance3D", true, false):
			item.queue_free()


func _physics_process(delta: float) -> void:
	_message_time = maxf(_message_time - delta, 0.0)
	var near := false
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		if not walker.input.local_control or not overlaps_body(walker):
			continue
		if Network.is_online() and not walker.is_multiplayer_authority():
			continue
		near = true
		if walker.input.shoot_pressed:
			# Gasta o aperto: o Camarim e a loja pausam o jogo antes de o boneco ler a entrada de novo, e o
			# aperto guardado reabria o Camarim logo depois de fechar (bug do usuário em 05/10/2026).
			walker.input.shoot_pressed = false
			try_enter(walker)
	if not near:
		_waiting = false
	_update_status(near)


func is_open() -> bool:
	return (opens_shop or opens_dressing_room or not target_scene.is_empty()) and missing().is_empty()


## Ids que ainda faltam vencer para abrir.
func missing() -> Array[String]:
	var result: Array[String] = []
	# Modo de teste: tudo aberto.
	if SaveGame.test_mode:
		return result
	for id in requires:
		if not SaveGame.is_defeated(id):
			result.append(id)
	return result


## Os dois personagens estão na frente da tenda.
func both_here() -> bool:
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	if walkers.size() < 2:
		return false
	for walker: WorldWalker in walkers:
		if not overlaps_body(walker):
			return false
	return true


func try_enter(walker: WorldWalker = null) -> void:
	if get_tree().get_first_node_in_group(&"blocking_ui") != null:
		return
	if opens_shop and is_open():
		var key := Shop.key_for(walker) if walker != null else Shop.local_keys()[0]
		ShopPanel.open_for(key, walker)
		return
	if opens_dressing_room:
		PauseMenu.open(false)
		PauseMenu._open_dressing_room()
		return
	if not is_open():
		_say("Em breve!" if target_scene.is_empty() else "Vençam os outros números primeiro!")
		return
	if Network.is_online() and not both_here():
		_waiting = true
		_say("Esperando o parceiro chegar...")
		return
	if Network.is_online() and not Network.is_host():
		_request_enter.rpc_id(1)
	else:
		_enter()


@rpc("any_peer", "call_remote", "reliable")
func _request_enter() -> void:
	Network.deliver(_enter_if_ready, false)


func _enter_if_ready() -> void:
	if is_open() and (not Network.is_online() or both_here()):
		_enter()


func _enter() -> void:
	SaveGame.save_game()
	_remember.rpc(level_id)
	Network.change_level(target_scene)


## Os dois PCs lembram por onde entraram, para voltar ao mundo na frente desta tenda.
@rpc("authority", "call_local", "reliable")
func _remember(id: String) -> void:
	Levels.return_door = id


func _say(text: String) -> void:
	_message = text
	_message_time = 2.0


func _update_status(near: bool) -> void:
	var text := ""
	var kind := ""
	var color := CREAM
	if _message_time > 0.0:
		text = _message
		kind = "message"
		color = Color("ffcf6a")
	elif not missing().is_empty():
		text = "Fechado"
		kind = "closed"
		color = Color("ff8a6a")
	elif not _best_grade().is_empty():
		text = "Nota: %s" % _best_grade()
		kind = "grade"
		color = Color("ffd25a")
	elif near:
		text = "%s: entrar" % _shoot_key_name()
		kind = "enter"
	status_text = text
	status_kind = kind
	status_color = color
	_status.text = text if draw_landmark else ""
	_status.modulate = color


static func _shoot_key_name() -> String:
	for slot in Settings.KEYBOARD_SLOTS:
		var event := Settings.get_binding(&"shoot", slot)
		if event != null:
			return InputSerializer.display_name(event)
	return "Atirar"


func _best_grade() -> String:
	if level_id.is_empty() or not SaveGame.data.get("bosses", {}).has(level_id):
		return ""
	return SaveGame.data.bosses[level_id].get("best_grade", "")


## Ponto no chão bem na frente da entrada (onde se para para entrar), em coordenadas do mundo.
func front_point() -> Vector3:
	return global_position + Vector3(_zone_center.x, 0, _zone_center.z)
