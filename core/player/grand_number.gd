class_name GrandNumber
extends Node2D
## Grande Número (gasta as 5 estrelas): o golpe máximo, diferente para cada personagem.
## Cada personagem aponta a sua cena no CharacterRig (`grand_number`). A cena fica dentro do
## Player e é tocada pelo PlayerSpecial:
## - no PC do dono (`local` = verdadeiro) ela move o personagem e causa dano;
## - no outro PC é uma cópia só visual, que começa no mesmo "passado" em que o parceiro é
##   mostrado (o movimento chega pela posição sincronizada).
## Durante o número o personagem fica invencível e sem controle.

## Duração total.
@export var duration := 0.8
## Proteção extra depois do fim (para não levar dano na hora de pousar).
@export var grace := 0.25

var player: Player
var local := true
var aim := Vector2.RIGHT
var elapsed := 0.0
var running := false


func begin(owner_player: Player, is_local: bool, aim_direction: Vector2) -> void:
	player = owner_player
	local = is_local
	aim = aim_direction
	elapsed = 0.0
	running = true
	_on_begin()


func tick(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	_on_tick(delta)
	if running and elapsed >= duration:
		finish()


func finish() -> void:
	if not running:
		return
	running = false
	_on_end()


# --- Para cada personagem sobrescrever ---

## Velocidade do personagem neste quadro (só no PC do dono). Padrão: fica parado, até no ar.
func move(_delta: float, _velocity: Vector2) -> Vector2:
	return Vector2.ZERO


## Mira mostrada no braço (espaço do mundo).
func pose_aim(default_aim: Vector2) -> Vector2:
	return default_aim


## Voltas do corpo (0 = sem giro).
func spin() -> float:
	return 0.0


## Desenho agachado (preparo de um pulo).
func crouch_pose() -> bool:
	return false


## Qual quadro da folha desenhada do número mostrar agora (padrão: pelo tempo, de ponta a ponta).
func drawn_frame(count: int) -> int:
	return mini(int(elapsed / maxf(duration, 0.01) * count), count - 1)


func _on_begin() -> void:
	pass


func _on_tick(_delta: float) -> void:
	pass


func _on_end() -> void:
	pass
