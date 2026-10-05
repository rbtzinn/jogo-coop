class_name GroupCamera
extends Camera2D
## Câmera das fases que andam para o lado: fica no meio dos jogadores de pé e não deixa
## ninguém sair da tela (quem fica para trás é empurrado pela borda; quem corre na frente
## espera o parceiro). A altura é fixa. Cada PC tem a sua, seguindo os dois.

## Largura da fase (a câmera não mostra além de 0..level_width).
@export var level_width := 6800.0
## Distância mínima entre o jogador e a borda da tela.
@export var edge_margin := 50.0
@export var follow_speed := 6.0

const HALF := Vector2(960, 540)


func _ready() -> void:
	make_current()
	global_position = Vector2(_target_x(), HALF.y)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	var x := lerpf(global_position.x, _target_x(), 1.0 - exp(-delta * follow_speed))
	global_position = Vector2(x, HALF.y)
	var left := x - HALF.x + edge_margin
	var right := x + HALF.x - edge_margin
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.is_inside_tree() or not player.is_multiplayer_authority() or player.player_health.is_downed:
			continue
		if player.global_position.x < left:
			player.global_position.x = left
			player.velocity.x = maxf(player.velocity.x, 0.0)
		elif player.global_position.x > right:
			player.global_position.x = right
			player.velocity.x = minf(player.velocity.x, 0.0)


## Borda esquerda e direita do que está na tela (para avisos e inimigos).
func view_rect() -> Rect2:
	return Rect2(global_position - HALF, HALF * 2.0)


func _target_x() -> float:
	var sum := 0.0
	var count := 0
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_inside_tree() and not player.player_health.is_downed:
			sum += player.global_position.x
			count += 1
	var x := sum / count if count > 0 else global_position.x
	return clampf(x, HALF.x, level_width - HALF.x)
