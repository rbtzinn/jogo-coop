class_name Fight
extends Node
## Uma luta contra chefão: anuncia o começo, percebe vitória (chefão vencido) ou derrota
## (todos os jogadores caídos) e mostra a tela de fim. Online, quem decide é o host.

const END_SCREEN := preload("res://core/ui/fight_end_screen.gd")

## O chefão precisa ter o sinal `defeated`.
@export var boss_path: NodePath
@export var intro_text := "Que comece o espetáculo!"

var _ended := false

@onready var boss: Node = get_node(boss_path)


func _ready() -> void:
	boss.defeated.connect(_end.bind(true))
	if boss.has_signal(&"phase_started"):
		boss.phase_started.connect(func(_phase: int, title: String) -> void: _show_banner(title))
	_show_banner(intro_text)


func _physics_process(_delta: float) -> void:
	if _ended or (Network.is_online() and not Network.is_host()):
		return
	var players := get_tree().get_nodes_in_group(&"players")
	if players.is_empty():
		return
	for player: Player in players:
		if not player.player_health.is_downed:
			return
	_end(false)


func _end(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	# Ninguém mais se mexe (e os botões da tela de fim não são apertados sem querer).
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
	if Network.is_online() and Network.is_host():
		for peer_id in Network.ready_peers:
			_receive_end.rpc_id(peer_id, victory)
	_show_banner("Nocaute!" if victory else "", victory)
	get_tree().create_timer(2.3 if victory else 1.0).timeout.connect(_show_end_screen.bind(victory))


@rpc("authority", "call_remote", "reliable")
func _receive_end(victory: bool) -> void:
	Network.deliver(_end.bind(victory), false)


func _show_end_screen(victory: bool) -> void:
	var screen: CanvasLayer = END_SCREEN.new()
	screen.victory = victory
	add_child(screen)


## Faixa de circo no meio da tela que entra quicando e sai voando para cima.
## `burst`: raios de luz girando atrás (vitória).
func _show_banner(text: String, burst := false) -> void:
	if text.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var banner := CircusBanner.new()
	banner.text = text
	banner.burst = burst
	banner.font_size = 110 if burst else 88
	banner.size = Vector2(1920, 1080)
	banner.pivot_offset = Vector2(960, 540)
	layer.add_child(banner)
	banner.scale = Vector2(0.3, 0.3)
	banner.rotation = -0.12
	var tween := banner.create_tween()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner, "rotation", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.6 if burst else 1.0)
	tween.tween_property(banner, "position:y", -700.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(layer.queue_free)
