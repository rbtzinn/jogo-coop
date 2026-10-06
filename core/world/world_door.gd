class_name WorldDoor
extends Area3D
## Entrada no mapa da aventura: uma tenda (chefão ou fase), a barraca da loja ou o carroção do Camarim.
## Quem chega na frente e aperta Atirar entra. O desenho vem da pintura do mapa; aqui ficam só a área de
## entrada e o aviso (status_text/status_color, que o mapa mostra numa plaquinha).
## Tenda de chefão online: os DOIS precisam estar na frente dela (ninguém é levado para a luta sem
## ter ido até lá); quem chega primeiro vê "Esperando o parceiro". Quem troca a fase é o host.

## Tamanho da área de entrada, na frente da atração (metros).
const ZONE := Vector3(3.0, 2.0, 2.2)

@export var title := ""
## Cena que abre ao entrar (vazio = "Em breve").
@export_file("*.tscn") var target_scene := ""
## Identifica o chefão/fase no save (para a nota e para os cadeados).
@export var level_id := ""
## Só abre depois de vencer estes (ids do save).
@export var requires: Array[String] = []
## Em vez de trocar de fase, abre a loja para quem entrou.
@export var opens_shop := false
## Em vez de trocar de fase, abre o Camarim.
@export var opens_dressing_room := false
## Tamanho da atração (raio em metros): afasta a área de entrada do meio dela.
@export var radius := 2.2
## Tipo da atração (muda a distância do meio até a frente): "tent", "stall", "wagon", "station", "big_top",
## "lion_tent".
@export_enum("tent", "stall", "wagon", "station", "big_top", "lion_tent") var landmark := "tent"

var _message := ""
var _message_time := 0.0
var _waiting := false
var _zone_center := Vector3.ZERO
## O aviso atual (vazio = nada) e o tipo: "enter" (pode entrar), "closed", "grade" ou "message".
var status_text := ""
var status_kind := ""
var status_color := UiTheme.CREAM


func _ready() -> void:
	add_to_group(&"world_doors")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_zone_center = Vector3(0, 1.0, _front_distance() + ZONE.z * 0.5 - 0.2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = ZONE
	shape.shape = box
	shape.position = _zone_center
	add_child(shape)


## Distância do meio da atração até a frente dela (onde fica a área de entrada).
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
	var color := UiTheme.CREAM
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
