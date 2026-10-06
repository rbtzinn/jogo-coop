class_name PlushLion
extends ConfettiCannon
## Leãozinho de Pelúcia (Trem, vagão LEÕES): cabeça de leão de pano assombrada que sai de uma escotilha no teto
## do vagão como caixa de surpresas, cospe um novelo que rola rente ao teto (pular por cima; a cada quatro, um
## rosa para o parry) e volta para dentro. Antes de sair, a tampa chacoalha. Só leva tiro e só machuca quando
## está fora. 5 tiros derrubam. Os novelos seguem o relógio da fase, como as bolas do canhão.
## Desenho provisório por código (pedido de arte D3 em docs/prompts/chatgpt_trem_desafiantes.md); o novelo
## ainda é a bola do canhão.

## Quanto antes do cuspe a tampa chacoalha e a cabeça sai, e quanto tempo fica fora depois.
const RATTLE_TIME := 1.1
const OUT_BEFORE := 0.6
const OUT_AFTER := 0.5
const PLUSH := Color("d9a441")
const MANE := Color("a3582a")
const HATCH := Color("8a6a3a")

## 0 = dentro, 1 = toda para fora.
var _out := 0.0
var _rattle := false


func _init() -> void:
	max_health = 5
	body_size = Vector2(90, 100)
	period = 2.6
	ball_range = 700.0


func _move(t: float) -> void:
	super(t)
	var up := _to_shot < OUT_BEFORE or _since_shot < OUT_AFTER
	_rattle = not up and _to_shot < RATTLE_TIME
	_out = move_toward(_out, 1.0 if up else 0.0, get_physics_process_delta_time() * 6.0)
	var exposed := _out > 0.5 and not dead
	if hurtbox.monitorable != exposed:
		hurtbox.set_deferred(&"monitorable", exposed)
	hitbox.active = exposed


func _update_art() -> void:
	queue_redraw()


func _draw() -> void:
	var rise := -_out * 90.0
	if _out > 0.05:
		# Pescoço de mola e a cabeça de pelúcia.
		draw_line(Vector2(0, -6), Vector2(0, rise - 10), INK, 12.0)
		draw_line(Vector2(0, -6), Vector2(0, rise - 10), Color("c9b48a"), 6.0)
		var head := Vector2(0, rise - 40)
		draw_circle(head, 48.0, INK)
		draw_circle(head, 44.0, MANE)
		draw_circle(head, 30.0, PLUSH)
		draw_circle(head + Vector2(-11, -6), 6.0, INK)
		draw_circle(head + Vector2(11, -6), 6.0, INK)
		var mouth := 4.0 + 10.0 * clampf(1.0 - _since_shot / 0.3, 0.0, 1.0)
		draw_circle(head + Vector2(-8, 14), mouth, INK)
	# Escotilha (anel de latão), a tampa chacoalhando antes de abrir.
	var shake := sin(Time.get_ticks_msec() * 0.06) * 4.0 if _rattle else 0.0
	draw_rect(Rect2(-60, -10, 120, 14), INK)
	draw_rect(Rect2(-56, -8, 112, 10), HATCH)
	if _out < 0.05:
		draw_rect(Rect2(-50 + shake, -18, 100, 10), INK)
		draw_rect(Rect2(-46 + shake, -16, 92, 6), PLUSH.darkened(0.3))
