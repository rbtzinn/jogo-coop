class_name Magician
extends Node2D
## O Grande Mágico Zaratan. Parado, é desenhado quadro a quadro (M2, bosses/magician/art/); nas outras
## poses ainda é desenhado por código (provisório, trocável por arte: docs/prompts/fila_animacoes_codex.md).
## Alto e magro, capa, cartola e bigode fino.
## O ponto do nó é entre os pés. Os ataques mudam `pose`, `facing`, `vanish` e a posição.
## Filhos esperados: Hurtbox (leva tiro) e Hitbox (encostar machuca).

const INK := Color("1b1410")
const SKIN := Color("e8c9a8")
const CAPE := Color("3a1f4a")
const CAPE_INSIDE := Color("a3282a")
const SUIT := Color("2a2a36")
const WAND_TIP := Color("ffc93c")
## Parado desenhado (M2): 4 quadros a 6 por segundo, olhando para a ESQUERDA na folha (o desenho é
## espelhado quando ele olha para a direita). O sumir (`vanish`) apaga junto; no Blackout (`eyes_only`)
## o desenho some e ficam só os olhos, por código.
const IDLE_ANIM := preload("res://bosses/magician/art/idle.tres")
const IDLE_FPS := 6.0
## Varinha (M3 + M3b): desenho 1 (varinha erguida) na pose `cast`; no `throw`, pelo tempo desde que a pose
## começou (os ataques põem `throw` de 0,15 s antes a 0,15 s depois de as cartas saírem): desenho 2
## (preparo) até 0,1 s, 3 (lançamento, a mão aberta a ~7 px de `hand_position()`) até 0,2 s e 4
## (acompanhamento) depois. O desenho 3 é o da M3b; o da M3 ficou com a mão a ~56 px e foi trocado.
const WAND_ANIM := preload("res://bosses/magician/art/wand.tres")
## Batendo na cartola (M4), na pose `tap` (Coelhos). O ataque põe `tap` por 0,7 s no começo e depois em
## pulsos de 0,15 s a cada 0,5 s; o desenho não sabe qual pulso é o último, então segue um ciclo de 0,3 s
## pelo tempo na pose: 2 (bate) até 0,08 s, 3 (repique) até 0,16 s e 1 (erguer) até 0,3 s; cada pulso
## curto mostra bate e repique, e o começo longo bate duas vezes. Ao sair do `tap`, o 4 (varinha abaixada,
## orgulhoso) fica TAP_SETTLE antes do parado.
const TAP_ANIM := preload("res://bosses/magician/art/tap.tres")
const TAP_SETTLE := 0.15
## Sumindo na capa (M5): com `vanish` > 0 (Teleporte, Jogo das Três Caixas), o desenho sai do valor dele
## (1 até 0,25, 2 até 0,5, 3 até 0,75, 4 depois), sobre qualquer pose; a transparência continua por cima e
## a fumaça e a estrela são do jogo. Na volta o `vanish` desce e os desenhos tocam ao contrário.
const VANISH_ANIM := preload("res://bosses/magician/art/vanish.tres")
## Reverência e medo (M6), células mais largas (a reverência funda com a cartola na mão não cabe em 512).
## `bow` (entrada da fase 2, Jogo das Três Caixas): desenho 1 (tirando a cartola) até BOW_DEEP e 2 (reverência
## funda) depois. `scared` (entrada da fase 3, derrota ainda pequeno): 3 e 4 alternando a SCARED_FPS. O tempo
## na pose só conta com ele à vista, então a reverência recomeça do 1 quando ele reaparece da caixa. Ao sair
## da reverência para o parado ou a varinha, o 1 fica BOW_SETTLE (recolocando a cartola, o tirar ao contrário),
## em vez de saltar da reverência funda direto para ele em pé.
const BOW_ANIM := preload("res://bosses/magician/art/bow.tres")
const BOW_DEEP := 0.3
const SCARED_FPS := 12.0
const BOW_SETTLE := 0.1

## Para onde olha (1 = direita, -1 = esquerda).
var facing := -1
## idle, cast (varinha para cima), throw (braço para a frente), tap (bate na cartola), bow, scared.
var pose := &"idle"
## 0 = visível, 1 = sumiu (some na fumaça).
var vanish := 0.0
## Só os olhos brilhando (no escuro do Blackout).
var eyes_only := false

var _time := 0.0
var _flash := 0.0
## O desenho quadro a quadro, atrás do que o código desenha.
var _art_holder := Node2D.new()
var _art := Sprite2D.new()
## Tempo desde que a pose `throw` começou.
var _throw_time := 0.0
## O lançamento veio direto da varinha erguida (o primeiro leque logo depois do preparo): sem o desenho de
## preparo, que já foi o `cast`; as cartas saem uns 0,05 s depois de a pose começar.
var _throw_from_cast := false
## Tempo desde que a pose `tap` começou, e quanto falta do desenho 4 depois dela.
var _tap_time := 0.0
var _tap_settle := 0.0
var _prev_pose := &"idle"
## Tempo na pose atual com ele à vista (`vanish` = 0), para a reverência e o medo.
var _pose_time := 0.0
## Quanto falta do desenho 1 da reverência depois dela.
var _bow_settle := 0.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	_art_holder.show_behind_parent = true
	add_child(_art_holder)
	_art.centered = false
	_art_holder.add_child(_art)


func _process(delta: float) -> void:
	_time += delta
	_tap_settle = maxf(_tap_settle - delta, 0.0)
	if _prev_pose == &"tap" and pose == &"idle":
		_tap_settle = TAP_SETTLE
	elif pose != &"idle":
		_tap_settle = 0.0
	_tap_time = _tap_time + delta if pose == &"tap" else 0.0
	if pose == &"throw" and _prev_pose != &"throw":
		_throw_from_cast = _prev_pose == &"cast"
	_bow_settle = maxf(_bow_settle - delta, 0.0)
	if _prev_pose == &"bow" and pose in [&"idle", &"cast"]:
		_bow_settle = BOW_SETTLE
	elif pose not in [&"idle", &"cast"]:
		_bow_settle = 0.0
	_pose_time = _pose_time + delta if pose == _prev_pose and vanish == 0.0 else 0.0
	_prev_pose = pose
	_throw_time = _throw_time + delta if pose == &"throw" else 0.0
	_flash = maxf(_flash - delta * 6.0, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6, 1.0 - vanish)
	var drawn := uses_art()
	_art_holder.visible = drawn
	if drawn:
		var animation: FrameAnimation = WAND_ANIM
		if vanish > 0.0:
			animation = VANISH_ANIM
		elif pose == &"tap" or _tap_settle > 0.0:
			animation = TAP_ANIM
		elif pose in [&"bow", &"scared"] or _bow_settle > 0.0:
			animation = BOW_ANIM
		elif pose == &"idle":
			animation = IDLE_ANIM
		_art.texture = animation.frames[art_frame()]
		_art.scale = Vector2.ONE * animation.frame_scale
		_art.position = animation.origin
		_art_holder.scale.x = -facing
	queue_redraw()


## À vista (não no Blackout), em qualquer pose: usa o desenho quadro a quadro. O boneco por código sobra
## só para os olhos no escuro.
func uses_art() -> bool:
	if eyes_only:
		return false
	return vanish > 0.0 or pose in [&"idle", &"cast", &"throw", &"tap", &"bow", &"scared"]


## Quadro da folha atual (parado: 0 a 3; varinha: 0 erguida, 1 a 3 o lançamento).
func art_frame() -> int:
	if vanish > 0.0:
		return mini(int(vanish * 4.0), 3)
	if _bow_settle > 0.0:
		return 0
	if pose == &"tap":
		var cycle := fmod(_tap_time, 0.3)
		return 1 if cycle < 0.08 else (2 if cycle < 0.16 else 0)
	if pose == &"idle" and _tap_settle > 0.0:
		return 3
	if pose == &"bow":
		return 0 if _pose_time < BOW_DEEP else 1
	if pose == &"scared":
		return 2 + int(_pose_time * SCARED_FPS) % 2
	if pose == &"cast":
		return 0
	if pose == &"throw":
		if _throw_from_cast:
			return 2 if _throw_time < 0.15 else 3
		return 1 if _throw_time < 0.1 else (2 if _throw_time < 0.2 else 3)
	return idle_frame()


## Quadro do parado (0 a 3) agora.
func idle_frame() -> int:
	return int(_time * IDLE_FPS) % IDLE_ANIM.frame_count()


func flash() -> void:
	_flash = 0.5


## Leva tiro e machuca só quando está à vista.
func set_present(value: bool) -> void:
	hurtbox.monitorable = value
	hitbox.active = value


## Ponta da varinha / mão que joga, no mundo.
func hand_position() -> Vector2:
	match pose:
		&"cast":
			return global_position + Vector2(facing * 40, -300)
		&"throw":
			return global_position + Vector2(facing * 90, -190)
	return global_position + Vector2(facing * 50, -170)


func _draw() -> void:
	var f := float(facing)
	if eyes_only:
		for side in [-1.0, 1.0]:
			draw_circle(Vector2(side * 10 + 8 * f, -232), 7, Color("ffe36a"))
		return
	if uses_art():
		return
	var sway := sin(_time * 2.2) * 6.0
	var bow := 0.5 if pose == &"bow" else 0.0
	draw_set_transform(Vector2(0, -120), -bow * f, Vector2.ONE)
	var o := Vector2(0, 120)
	# Capa (atrás), balançando.
	var cape := PackedVector2Array([o + Vector2(-34, -200), o + Vector2(34, -200), o + Vector2(52 - f * 10 + sway, -10),
			o + Vector2(-52 - f * 10 + sway, -10)])
	draw_colored_polygon(cape, CAPE)
	cape.append(cape[0])
	draw_polyline(cape, INK, 4.0, true)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-20, -196), o + Vector2(20, -196), o + Vector2(30 + sway, -30),
			o + Vector2(-30 + sway, -30)]), CAPE_INSIDE)
	# Pernas finas e sapatos.
	for side in [-1.0, 1.0]:
		var hip := o + Vector2(side * 12, -96)
		var foot := o + Vector2(side * 14, 0)
		draw_line(hip, foot, INK, 14.0)
		draw_line(hip, foot, SUIT, 9.0)
		draw_circle(foot + Vector2(8 * f, -4), 9, INK)
	# Fraque.
	var coat := PackedVector2Array([o + Vector2(-30, -200), o + Vector2(30, -200), o + Vector2(26, -92), o + Vector2(-26, -92)])
	draw_colored_polygon(coat, SUIT)
	coat.append(coat[0])
	draw_polyline(coat, INK, 4.0, true)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-8, -200), o + Vector2(8, -200), o + Vector2(0, -150)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-10, -196), o + Vector2(0, -188), o + Vector2(10, -196),
			o + Vector2(0, -204)]), CAPE_INSIDE)
	# Braços: o da varinha muda com a pose.
	var shoulder := o + Vector2(24 * f, -190)
	var hand := _hand_local(o, f)
	draw_line(shoulder, hand, INK, 12.0)
	draw_line(shoulder, hand, SUIT, 7.0)
	draw_circle(hand, 9, INK)
	draw_circle(hand, 7, Color.WHITE)
	var wand_dir := (hand - shoulder).normalized()
	draw_line(hand, hand + wand_dir * 46, INK, 6.0)
	var glow := 1.0 + sin(_time * 14.0) * 0.2 if pose == &"cast" else 1.0
	draw_circle(hand + wand_dir * 48, 6 * glow, WAND_TIP)
	var back_hand := o + Vector2(-26 * f, -110)
	draw_line(o + Vector2(-24 * f, -190), back_hand, INK, 12.0)
	draw_line(o + Vector2(-24 * f, -190), back_hand, SUIT, 7.0)
	draw_circle(back_hand, 8, Color.WHITE)
	# Cabeça comprida, bigode fino e cavanhaque.
	var head := o + Vector2(0, -232)
	var face := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		face.append(head + Vector2(cos(a) * 24, sin(a) * 34))
	draw_colored_polygon(face, SKIN)
	face.append(face[0])
	draw_polyline(face, INK, 4.0, true)
	_draw_face(head, f)
	# Cartola.
	draw_rect(Rect2(head + Vector2(-38, -30), Vector2(76, 10)), INK)
	draw_rect(Rect2(head + Vector2(-24, -92), Vector2(48, 64)), INK)
	draw_rect(Rect2(head + Vector2(-24, -44), Vector2(48, 10)), CAPE_INSIDE)
	draw_set_transform(Vector2.ZERO)


func _hand_local(o: Vector2, f: float) -> Vector2:
	match pose:
		&"cast":
			return o + Vector2(36 * f, -290)
		&"throw":
			return o + Vector2(86 * f, -186)
		&"tap":
			return o + Vector2(30 * f, -300)
		&"bow":
			return o + Vector2(60 * f, -120)
		&"scared":
			return o + Vector2(40 * f, -250)
	return o + Vector2(44 * f, -150 + sin(_time * 3.0) * 6.0)


func _draw_face(head: Vector2, f: float) -> void:
	var angry := pose in [&"cast", &"throw"]
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * 9 + 6 * f, -8)
		if pose == &"bow":
			draw_arc(eye, 5, PI, TAU, 6, INK, 3.0)
			continue
		draw_circle(eye, 6 if pose != &"scared" else 8, Color.WHITE)
		draw_circle(eye + Vector2(2 * f, 0), 3, INK)
		var brow_tilt: float = -side * f * (4.0 if angry else -2.0)
		draw_line(eye + Vector2(-7, -9 + brow_tilt), eye + Vector2(7, -9 - brow_tilt), INK, 3.0)
	# Bigode fino e enrolado.
	var lip := head + Vector2(6 * f, 12)
	for side in [-1.0, 1.0]:
		draw_line(lip, lip + Vector2(side * 18, -2), INK, 3.0)
		draw_arc(lip + Vector2(side * 22, -6), 5, 0.0 if side > 0 else PI, PI if side > 0 else TAU, 6, INK, 3.0)
	match pose:
		&"scared":
			draw_circle(lip + Vector2(0, 10), 6, INK)
		&"cast", &"throw":
			draw_line(lip + Vector2(-8, 9), lip + Vector2(8, 7), INK, 3.0)
		_:
			draw_arc(lip + Vector2(0, 4), 8, 0.3, PI - 0.3, 8, INK, 3.0)
	# Cavanhaque.
	draw_colored_polygon(PackedVector2Array([head + Vector2(-5, 28), head + Vector2(5, 28), head + Vector2(0, 44)]), INK)
