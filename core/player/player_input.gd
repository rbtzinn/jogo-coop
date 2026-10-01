class_name PlayerInput
extends Node
## Comandos do jogador em um quadro de física.
## O jogador local lê do teclado/controle; na etapa de rede, o jogador remoto
## vai receber estes mesmos campos pela rede em vez de ler o Input.

const HORIZONTAL_DEADZONE := 0.3
const VERTICAL_DEADZONE := 0.5

## Desligado: não lê teclado/controle (jogador parado ou controlado pela rede).
@export var local_control := true

var move := Vector2.ZERO
var jump_pressed := false
var jump_held := false
var jump_released := false
var shoot_held := false
var dash_pressed := false
var lock_held := false


func update() -> void:
	if not local_control:
		clear()
		return
	move =Input.get_vector("move_left", "move_right", "move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_held = Input.is_action_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	shoot_held = Input.is_action_pressed("shoot")
	dash_pressed = Input.is_action_just_pressed("dash")
	lock_held = Input.is_action_pressed("lock_aim")


func clear() -> void:
	move = Vector2.ZERO
	jump_pressed = false
	jump_held = false
	jump_released = false
	shoot_held = false
	dash_pressed = false
	lock_held = false


## -1, 0 ou 1. Analógico vira digital para o controle ficar preciso.
func get_horizontal() -> int:
	return _digital(move.x, HORIZONTAL_DEADZONE)


## -1 (cima), 0 ou 1 (baixo).
func get_vertical() -> int:
	return _digital(move.y, VERTICAL_DEADZONE)


static func _digital(value: float, deadzone: float) -> int:
	if absf(value) < deadzone:
		return 0
	return int(signf(value))
