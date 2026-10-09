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
var shoot_held := false
## Apertou atirar agora (no mapa, "atirar" serve para entrar nas tendas).
var shoot_pressed := false
var dash_pressed := false
var lock_held := false
var special_pressed := false
## Testes e pilotos: ligado, `update()` não lê o teclado e deixa os campos como o roteiro (bot) pôs.
var scripted := false
## Desligado (mapa 3D, onde não se pula): a opção "Cima também pula" não vale e "cima" sempre anda.
var up_can_jump := true

var _prev_jump_held := false
var _prev_up_key := false
## A tecla "cima" está valendo como pulo (foi apertada sem travar a mira).
var _up_is_jumping := false


func update() -> void:
	if scripted:
		return
	# Menu de pausa ou outra tela por cima (loja, Camarim): o personagem não obedece.
	if not local_control or PauseMenu.is_open() or get_tree().get_first_node_in_group(&"blocking_ui") != null:
		clear()
		return
	move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	shoot_held = Input.is_action_pressed("shoot") or (up_can_jump and MobileControls.wants_auto_shoot())
	shoot_pressed = Input.is_action_just_pressed("shoot")
	dash_pressed = Input.is_action_just_pressed("dash")
	lock_held = Input.is_action_pressed("lock_aim")
	special_pressed = Input.is_action_just_pressed("special")
	_update_jump()


func clear() -> void:
	move = Vector2.ZERO
	jump_pressed = false
	jump_held = false
	shoot_held = false
	shoot_pressed = false
	dash_pressed = false
	lock_held = false
	special_pressed = false
	_prev_jump_held = false
	_prev_up_key = false
	_up_is_jumping = false


## -1, 0 ou 1. Analógico vira digital para o controle ficar preciso.
func get_horizontal() -> int:
	return _digital(move.x, HORIZONTAL_DEADZONE)


## -1 (cima), 0 ou 1 (baixo).
func get_vertical() -> int:
	return _digital(move.y, VERTICAL_DEADZONE)


## Opção "Cima também pula" (só teclado): sem travar a mira, a tecla de cima pula;
## travando a mira, ela volta a mirar para cima. Só vale um aperto novo da tecla,
## para soltar a trava segurando cima não fazer o boneco pular sozinho.
func _update_jump() -> void:
	var up_key := Settings.up_jumps and up_can_jump and _is_keyboard_up_pressed()
	if up_key and not _prev_up_key and not lock_held:
		_up_is_jumping = true
	elif not up_key:
		_up_is_jumping = false
	_prev_up_key = up_key
	if up_key and (_up_is_jumping or not lock_held):
		move.y = maxf(move.y, 0.0)

	jump_held = Input.is_action_pressed("jump") or _up_is_jumping
	jump_pressed = jump_held and not _prev_jump_held
	_prev_jump_held = jump_held


func _is_keyboard_up_pressed() -> bool:
	for slot in Settings.KEYBOARD_SLOTS:
		var event := Settings.get_binding(&"move_up", slot) as InputEventKey
		if event != null and Input.is_physical_key_pressed(event.physical_keycode):
			return true
	return false


static func _digital(value: float, deadzone: float) -> int:
	if absf(value) < deadzone:
		return 0
	return int(signf(value))

