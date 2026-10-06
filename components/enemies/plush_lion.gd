class_name PlushLion
extends ConfettiCannon
## Leãozinho de Pelúcia (Trem, vagão LEÕES): cabeça de leão de pano assombrada que sai de uma escotilha no teto
## do vagão como caixa de surpresas, cospe um novelo que rola rente ao teto (pular por cima; a cada quatro, um
## rosa para o parry) e volta para dentro. Antes de sair, a tampa chacoalha. Só leva tiro e só machuca quando
## está fora. 5 tiros derrubam. Os novelos seguem o relógio da fase, como as bolas do canhão.
## Desenho do pedido de arte D3 (docs/prompts/chatgpt_trem_desafiantes.md), recortado por
## tools/cut_train_challengers.gd com a âncora no meio da escotilha.

const LION_ART := preload("res://components/enemies/art/plush_lion.tres")
const YARN_ART := preload("res://components/enemies/art/yarn.tres")
## Quanto antes do cuspe a tampa chacoalha e a cabeça sai, e quanto tempo fica fora depois.
const RATTLE_TIME := 1.1
const OUT_BEFORE := 0.6
const OUT_AFTER := 0.5

## 0 = dentro, 1 = toda para fora.
var _out := 0.0
var _rattle := false


func _init() -> void:
	max_health = 5
	body_size = Vector2(90, 120)
	period = 2.6
	ball_range = 700.0
	death_drawn = true
	death_duration = 0.8


func _move(t: float) -> void:
	super(t)
	var up := _to_shot < OUT_BEFORE or _since_shot < OUT_AFTER
	_rattle = not up and _to_shot < RATTLE_TIME
	_out = move_toward(_out, 1.0 if up else 0.0, get_physics_process_delta_time() * 6.0)
	var exposed := _out > 0.5 and not dead
	if hurtbox.monitorable != exposed:
		hurtbox.set_deferred(&"monitorable", exposed)
	hitbox.active = exposed


func _make_ball(k: int) -> Node2D:
	var ball := ConfettiBall.new()
	ball.art = YARN_ART
	ball.pink_frame = 3
	ball.roll_frames = 3
	ball.pink = k % 4 == 3
	ball.parry_id = "%s:%d" % [parry_id, k]
	add_child(ball)
	return ball


func _update_art() -> void:
	# Quadros: 0 tampa fechada, 1 saindo com sorrisão, 2 cuspindo, 3 voltando, 4 rugido, 5 tonto, 6 levou tiro.
	var index := 0
	if _flash > 0.3:
		index = 6
	elif _flash > 0.1:
		index = 5
	elif _out < 0.1:
		index = 0
	elif _since_shot < 0.3:
		index = 2
	elif _since_shot < OUT_AFTER:
		index = 3
	elif _out < 0.6:
		index = 1
	else:
		index = 4 if _to_shot < 0.3 else 1
	_show(index)
	# A tampa chacoalha antes de abrir.
	_art.position.x = sin(Time.get_ticks_msec() * 0.06) * 4.0 if _rattle and index == 0 else 0.0


func _update_death(_progress: float) -> void:
	_show(7)


func _show(index: int) -> void:
	LION_ART.show_on(_art, index)
	_art.scale = Vector2.ONE * LION_ART.frame_scale
