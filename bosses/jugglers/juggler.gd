class_name Juggler
extends Node2D
## Um dos Irmãos Malabaristas (Tico ou Teco). Parado malabarizando, é desenhado quadro a quadro
## (E2, bosses/jugglers/art/), com os objetos (bolas do Tico, claves do Teco) desenhados por código
## por cima, de mão em mão; nas outras poses ainda é desenhado por código (provisório, trocável por
## arte: docs/prompts/fila_animacoes_codex.md).
## O ponto do nó é entre os pés. Os ataques mudam `pose`, `spin`, `facing` e a posição; o
## desenho cuida do resto (pernas andando, braços malabarizando, cara de cada momento).
## Filhos esperados: Hurtbox (leva tiro) e Hitbox (encostar machuca).

const INK := Color("1b1410")
const SKIN := Color("f1c8a0")
const CREAM := Color("f2e6cc")
const BALL_COLORS := [Color("d23a3a"), Color("ffc93c"), Color("5fbfd8")]
## Parado malabarizando, desenhado, olhando para a direita. O Teco é a mesma folha com as listras azuis
## (tools/recolor_twin.gd). Versão atual: 12 desenhos (os 8 da E2 mais 4 intermediários do braço da
## frente, tools/juggler_inbetweens.gd), com tempos desiguais. A de 8 a 12 por segundo fica para
## comparar (`smooth_idle` falso).
const TICO_IDLE := preload("res://bosses/jugglers/art/tico/idle.tres")
const TECO_IDLE := preload("res://bosses/jugglers/art/teco/idle.tres")
const TICO_IDLE12 := preload("res://bosses/jugglers/art/tico/idle12.tres")
const TECO_IDLE12 := preload("res://bosses/jugglers/art/teco/idle12.tres")
const IDLE_FPS := 12.0
## Ordem dos 12: 1, 2, C, 3, A, 4, 5, D, 6, 7, B, 8. Quanto cada um fica, em quadros do jogo a 60 por
## segundo; somam 40 (0,667 s, a mesma volta dos 8) e as solturas continuam no começo do 3 e do 7.
const IDLE12_TICKS: Array[int] = [4, 3, 3, 4, 3, 3, 4, 3, 3, 4, 3, 3]
const IDLE_LOOP := 8.0 / IDLE_FPS
## Arremesso desenhado (E3), só quando o irmão arremessa EM PÉ (vindo do parado: Troca-Troca, Bolas
## Quicando, a base do totem); sentado no totem ou no monociclo continua o boneco de código. Os ataques
## põem a pose `throw` 0,25 s antes de o objeto aparecer em `hand_position()` e tiram 0,1 s depois.
## A folha veio com a mão mais alta no desenho 2 que no 3. No jogo ela vira um arremesso por baixo (o
## lançamento do malabarismo): 4 (a mão baixa na frente), 3 (soltura: a palma aberta no queixo, a 14 px
## do ponto onde o objeto aparece) e 2 (acompanhamento, a mão subindo). O desenho 1 (preparo com a
## cabeça inclinada para a frente) ficou de fora: entrando nele o nariz pulava 47 px.
const TICO_THROW := preload("res://bosses/jugglers/art/tico/throw.tres")
const TECO_THROW := preload("res://bosses/jugglers/art/teco/throw.tres")
## Tonto desenhado (E4): pêndulo de 4 desenhos a 8 por segundo (0,5 s), em pé (no parado ou na pose
## `dizzy`; no totem continua o boneco de código). As estrelas continuam por código, em volta da cabeça
## desenhada. O meio da cabeça de cada desenho (no espaço do irmão olhando para a direita, medido na
## folha normalizada) é para onde vai a bola de cura (`head_position`): o pêndulo leva a cabeça até
## 31 px para o lado, e a bola pousava no ar ao lado dela.
const TICO_DIZZY := preload("res://bosses/jugglers/art/tico/dizzy.tres")
const TECO_DIZZY := preload("res://bosses/jugglers/art/teco/dizzy.tres")
const DIZZY_FPS := 8.0
const DIZZY_HEADS: Array[Vector2] = [Vector2(-15, -175), Vector2(1, -190), Vector2(31, -177), Vector2(1, -190)]
## Suavização do pêndulo: a cada troca de desenho o novo começa inclinado em volta dos pés de modo que a
## cabeça fique onde estava a do anterior, e endireita durante o tempo do desenho (o nariz pulava 36 px a
## cada 0,125 s). Os pés não saem do lugar; a troca de desenho continua.
const DIZZY_SETTLE := 1.0 / DIZZY_FPS
## Só metade da diferença é corrigida: a inclinação é em volta dos pés, e com a correção inteira (até 10,5°)
## a ponta do sapato subia uns 17 px na troca.
const DIZZY_SETTLE_SHARE := 0.5
## Salto mortal desenhado (E5): desenho 0 = agachado (pose `crouch`, o aviso), 1–8 = a bolinha em 8
## orientações de uma volta para a frente (escolhida pelo `spin`: o sinal dá o sentido e o espelho dá o
## lado; nunca o mesmo desenho girado), 9 = aterrissagem (LAND_TIME depois que o giro acaba e ele volta
## ao parado). O meio da bolinha fica em (0, −103), quase no meio do giro do boneco de código (0, −105).
const TICO_FLIP := preload("res://bosses/jugglers/art/tico/flip.tres")
const TECO_FLIP := preload("res://bosses/jugglers/art/teco/flip.tres")
const LAND_TIME := 0.15
## Derrota desenhada (E6): deitado de costas. Na pose `down`, os desenhos 1 a 3 (batida, quique, assentando)
## a 10 por segundo e o 4 (nocaute) parado. `defeat_delay` atrasa o começo (o Teco cai 0,1 s depois, por cima).
const TICO_DEFEAT := preload("res://bosses/jugglers/art/tico/defeat.tres")
const TECO_DEFEAT := preload("res://bosses/jugglers/art/teco/defeat.tres")
const DEFEAT_FPS := 10.0
## Totem desenhado (E7, 04/10/2026): os dois irmãos num desenho só, MENORES que nas outras folhas (decisão do
## usuário, para o totem caber por baixo das tábuas penduradas: o quadro mais alto chega a 214,8 px do chão e a tábua
## começa a 216 px: a cabeça do de cima passa rente por baixo dela, e quem está na tábua fica seguro). Quem desenha é
## a base (`totem_role` BASE): a folha com o Tico embaixo, ou a mesma com as cores trocadas quando a base é o
## Teco. O de cima (TOP) não desenha corpo: fica com as áreas de tiro e de dano, as estrelas da tontura e as
## bolinhas. Desenhos: 1 e 2 parado (alternando), 3 a 6 andando, 7 e 8 o de cima arremessando (preparo e
## soltura, mesmo andando). O giro das entradas continua com o salto (E5), no tamanho normal.
const TOTEM_TICO := preload("res://bosses/jugglers/art/totem/tico_base.tres")
const TOTEM_TECO := preload("res://bosses/jugglers/art/totem/teco_base.tres")
const TOTEM_IDLE_FPS := 3.0
## A caminhada avança pela DISTÂNCIA andada, não pelo tempo: um desenho a cada TOTEM_STEP px (metade do passo
## medido nos desenhos, ~88 px entre os sapatos). O Totem Andante acelera e freia (média de ~590 px/s); com
## um ritmo fixo o pé deslizava até ~49 px por desenho e muito mais nas pontas.
const TOTEM_STEP := 44.0
## Meio da cabeça de cada irmão em cada desenho (espaço da BASE olhando para a direita; o meio da cara a 40 px
## de célula atrás do nariz, medido na folha normalizada, na escala de 0,477 do jogo): a bola de cura e as estrelas vão para lá.
const TOTEM_TOP_HEADS: Array[Vector2] = [Vector2(7, -167), Vector2(-1, -163), Vector2(-3, -173), Vector2(-8, -172),
		Vector2(33, -157), Vector2(-2, -170), Vector2(23, -156), Vector2(25, -160)]
const TOTEM_BASE_HEADS: Array[Vector2] = [Vector2(12, -81), Vector2(13, -79), Vector2(19, -86), Vector2(9, -85),
		Vector2(12, -78), Vector2(10, -82), Vector2(15, -84), Vector2(17, -76)]
## Luva da FRENTE do de cima em cada desenho (de onde saem as claves; no 8 é a soltura, com o braço esticado),
## e as duas luvas dele nos desenhos 1 e 2 (o arco das bolinhas do parado). Espaço da base, olhando para a direita.
const TOTEM_FRONT_HANDS: Array[Vector2] = [Vector2(56, -140), Vector2(55, -141), Vector2(58, -156), Vector2(47, -147),
		Vector2(80, -136), Vector2(51, -143), Vector2(85, -142), Vector2(92, -152)]
const TOTEM_IDLE_HANDS := [[Vector2(-54, -136), Vector2(56, -140)], [Vector2(-51, -126), Vector2(55, -141)]]
## As bolinhas do de cima no totem: uma volta a cada TOTEM_JUGGLE s, no tamanho dos irmãos do totem.
const TOTEM_JUGGLE := 0.9
const TOTEM_BALL_SCALE := 0.22

## O totem desenhado cresce TOTEM_GROW (05/10/2026, pedido do usuário: a luta ficava fácil com a tábua segura).
## Com 1,3 o de cima passa na altura de quem está na tábua pendurada: lá em cima é preciso pular por cima
## dele (ou dar dash); do chão o pulo passa rente. Todas as medidas TOTEM_* acima são do tamanho antigo.
const TOTEM_GROW := 1.3

## Monociclo desenhado (E8, 05/10/2026): a mesma ideia do totem. Os dois sentados no selim num desenho só, na
## escala do totem (com TOTEM_GROW); quem desenha é a base, o de cima só tem as áreas. O ponto do nó da base é
## o selim. Desenhos: 1 a 4 pedalando (um a cada RIDE_STEP px andados, e devagar parado, se equilibrando), 5 e 6
## o de baixo arremessando (preparo e soltura), 7 e 8 o de cima.
const RIDE_TICO := preload("res://bosses/jugglers/art/unicycle/tico_base.tres")
const RIDE_TECO := preload("res://bosses/jugglers/art/unicycle/teco_base.tres")
const RIDE_STEP := 30.0
const RIDE_IDLE_FPS := 4.0
## A soltura aparece este tanto depois de a pose `throw` começar (os ataques criam o objeto 0,2 s depois).
const RIDE_RELEASE := 0.2
## Medidos na folha arrumada (espaço da base olhando para a direita, sem o TOTEM_GROW): as cabeças e a mão que
## arremessa de cada um.
const RIDE_TOP_HEAD := Vector2(0, -140)
const RIDE_BASE_HEAD := Vector2(12, -61)
const RIDE_TOP_HAND := Vector2(67, -142)
const RIDE_BASE_HAND := Vector2(67, -103)

enum TotemRole { NONE, BASE, TOP }
## Começo de cada desenho (tempo desde que a pose `throw` começou) e qual desenho da folha é.
const THROW_STEPS: Array[float] = [0.0, 0.18, 0.31]
const THROW_DRAWINGS: Array[int] = [3, 2, 1]
## Meio da palma (o objeto fica uns 17 px acima do meio da luva) em cada desenho do arremesso, no espaço
## do irmão olhando para a direita (medido na folha normalizada).
const THROW_PALMS: Array[Vector2] = [Vector2(58, -109), Vector2(78, -177), Vector2(52, -153), Vector2(80, -93)]
## Objetos recortados da folha base (sem as trilhas), no tamanho do irmão no jogo.
const BALL_TEXTURE := preload("res://bosses/jugglers/art/ball.png")
const CLUB_TEXTURE := preload("res://bosses/jugglers/art/club.png")
const BALL_SCALE := 0.33
const CLUB_SCALE := 0.27
## A clave da folha base está deitada (botão do cabo em cima à esquerda, em (23, 23) da textura). Na mão
## ela é segura pelo cabo: o ponto da pegada (CLUB_GRIP, um pouco depois do botão) fica na palma e o
## corpo aponta para cima e para a FRENTE, uns 43° acima da horizontal, longe do rosto. Antes o meio
## da clave ficava acima da luva, quase em pé, e no desenho 2 (a luva junto da boca) ela encostava no
## rosto. No ar ela gira em volta do meio; a passagem entre a pegada e o meio é suave.
const CLUB_HELD := -1.38
const CLUB_GRIP := Vector2(41, 36)
## Na mão de trás a clave aponta para cima e para TRÁS (o espelho do ângulo da frente), senão ela
## atravessava o peito até o queixo. Giro a somar ao CLUB_HELD.
const CLUB_BACK_TURN := -1.62
const GRIP_BLEND := 0.08
## Onde o objeto fica em cada quadro (meio da luva menos ~35 px da célula, no espaço do irmão, olhando
## para a direita). A mão da frente joga sempre alto (sobe nos quadros 1–3 e 5–7 e solta no 3 e no 7)
## e a de trás pega embaixo e passa baixo para a da frente: o "chuveiro" dos malabaristas. A folha
## veio assim (as duas metades com a mesma mão no alto) e o padrão aproveita os 8 desenhos.
const FRONT_PALMS: Array[Vector2] = [Vector2(79, -124), Vector2(84, -148), Vector2(83, -191), Vector2(78, -114),
		Vector2(80, -126), Vector2(88, -164), Vector2(86, -190), Vector2(80, -116)]
const BACK_PALMS: Array[Vector2] = [Vector2(-63, -84), Vector2(-61, -96), Vector2(-60, -90), Vector2(-66, -110),
		Vector2(-53, -88), Vector2(-60, -90), Vector2(-64, -93), Vector2(-71, -110)]
## Os mesmos para os 12 desenhos (C, A, D e B: a luva do braço novo; a mão de trás é a do corpo usado).
const FRONT_PALMS12: Array[Vector2] = [Vector2(79, -124), Vector2(84, -148), Vector2(82, -163), Vector2(83, -191),
		Vector2(93, -144), Vector2(78, -114), Vector2(80, -126), Vector2(91, -144), Vector2(88, -164), Vector2(86, -190),
		Vector2(96, -144), Vector2(80, -116)]
const BACK_PALMS12: Array[Vector2] = [Vector2(-63, -84), Vector2(-61, -96), Vector2(-61, -96), Vector2(-60, -90),
		Vector2(-66, -110), Vector2(-66, -110), Vector2(-53, -88), Vector2(-53, -88), Vector2(-60, -90), Vector2(-64, -93),
		Vector2(-71, -110), Vector2(-71, -110)]
## Ciclo de cada objeto (3 objetos, 2 lançamentos por volta de 8 quadros): 1 s. Solta no começo do
## quadro 3; voa alto até a mão de trás (0,5 s, pega no quadro 1 ou 5); fica nela; passa baixo para a
## da frente; fica nela até soltar de novo.
const PROP_CYCLE := 1.0
const FIRST_RELEASE := 2.0 / IDLE_FPS
const HIGH_FLIGHT := 0.5
const BACK_HOLD := 0.0833
const LOW_FLIGHT := 0.1667
## Arco alto (curva de Bézier): sobe reto da mão da frente, passa por cima da cabeça e desce por fora,
## atrás do cabelo (que vai até x −80), até a mão de trás; com uma parábola simples o objeto descia
## por cima do cabelo.
const HIGH_RISE := Vector2(40, -139)
const HIGH_DROP := Vector2(-240, -300)
## O passe baixo atravessa reto na frente do peito (com arco maior a clave passava na boca).
const LOW_ARC := 8.0

@export var stripe_color := Color("c8302c")
@export var hair_color := Color("2a1a12")
## Este é o Teco (folha recolorida e claves).
@export var teco := false
## Parado com os 12 desenhos (falso: a versão de 8, para comparar).
@export var smooth_idle := true
## Tonto com a suavização do pêndulo (falso: a versão sem, para comparar).
@export var smooth_dizzy := true

## Para onde olha (1 = direita, -1 = esquerda).
var facing := 1
## idle, throw, crouch, spin, sit (em cima do irmão), ride (no monociclo), dizzy, down.
var pose := &"idle":
	set(value):
		if value != &"throw":
			throw_released = false
		pose = value
## Voltas do corpo (salto mortal, rolando).
var spin := 0.0
## Carregando o irmão nos ombros (totem e monociclo): fica no boneco de código, como o de cima. O desenho
## quadro a quadro é maior que o boneco, e o de cima (sentado a SHOULDER px dos pés) caía na cara dele.
var carrying := false
## No totem: BASE desenha os dois, TOP só tem as áreas (ver TOTEM_TICO). Quem liga é o `set_mode` do chefão.
var totem_role := TotemRole.NONE
## O outro irmão do totem.
var totem_partner: Juggler
## Os papéis de totem valem no monociclo (verdadeiro): a base sentada no selim, com a folha RIDE_*.
var riding := false
## O objeto deste arremesso já saiu da mão (o ataque marca na hora em que cria o objeto; sai da pose `throw`,
## volta a falso). No totem desenhado, o de cima fica no preparo (7) até aí e na soltura (8) depois: assim a
## clave nasce na luva do desenho que está na tela.
var throw_released := false
## De onde começou a andar (x), para a caminhada desenhada do totem: o desenho sai da posição, igual na física
## (onde a clave nasce na mão) e no desenho do quadro.
var _walk_from_x := 0.0
## Atraso da queda desenhada na derrota (segundos).
var defeat_delay := 0.0
var _down_time := 0.0
## Andando (pernas se mexem).
var walking := false:
	set(value):
		if value and not walking:
			_walk_from_x = global_position.x
		walking = value
## Tonto: estrelas girando, olhos em X, não malabariza.
var dizzy := false
## Bolinhas girando nas mãos.
var juggling := true

var _time := 0.0
var _flash := 0.0
## O desenho quadro a quadro, atrás do que o código desenha (os objetos ficam na frente).
var _art_holder := Node2D.new()
var _art := Sprite2D.new()
## Tempo desde que a pose `throw` começou (−1 fora dela) e se ele estava em pé quando começou.
## Aterrissagem do salto: quanto falta mostrar, e a pose do quadro anterior.
var _landing := 0.0
## Inclinação de assentamento do tonto: desenho anterior, inclinação inicial e tempo desde a troca.
var _dizzy_prev := -1
var _dizzy_tilt_from := 0.0
var _dizzy_since := 0.0
var _prev_pose := &"idle"
var _throw_time := -1.0
var _throw_standing := false
var _last_pose := &"idle"

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	_art_holder.show_behind_parent = true
	add_child(_art_holder)
	_art.centered = false
	_art_holder.add_child(_art)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6)
	_track_throw(delta)
	_landing = maxf(_landing - delta, 0.0)
	if _prev_pose == &"spin" and pose == &"idle":
		_landing = LAND_TIME
	elif pose != &"idle":
		_landing = 0.0
	_prev_pose = pose
	_track_dizzy(delta)
	_down_time = _down_time + delta if pose == &"down" else 0.0
	var drawn := _uses_art()
	_art_holder.visible = drawn
	if drawn:
		var animation := _idle_animation()
		var frame := idle_frame()
		if _totem_art():
			if riding:
				animation = RIDE_TECO if teco else RIDE_TICO
				frame = ride_frame()
			else:
				animation = TOTEM_TECO if teco else TOTEM_TICO
				frame = totem_frame()
		elif _defeat_art():
			animation = TECO_DEFEAT if teco else TICO_DEFEAT
			frame = defeat_frame()
		elif _dizzy_art():
			animation = TECO_DIZZY if teco else TICO_DIZZY
			frame = dizzy_frame()
		elif _flip_art():
			animation = TECO_FLIP if teco else TICO_FLIP
			frame = flip_frame()
		elif _throw_art():
			animation = TECO_THROW if teco else TICO_THROW
			frame = throw_frame()
		_art.texture = animation.frames[frame]
		var grow := TOTEM_GROW if _totem_art() else 1.0
		_art.scale = Vector2.ONE * animation.frame_scale * grow
		_art.position = animation.origin * grow
		_art_holder.scale.x = facing
		_art_holder.rotation = dizzy_rotation() * facing if _dizzy_art() else 0.0
	queue_redraw()


## Parado no lugar e malabarizando, ou arremessando em pé: usa o desenho quadro a quadro.
func _uses_art() -> bool:
	if _totem_art():
		return true
	if _totem_hidden():
		return false
	if _defeat_art():
		return true
	if _dizzy_art():
		return true
	if _flip_art():
		return true
	if carrying or dizzy or walking or spin != 0.0:
		return false
	return pose == &"idle" or _throw_art()


## Arremesso desenhado agora (a pose `throw` vinda do parado).
func _throw_art() -> bool:
	return pose == &"throw" and _throw_standing


## Desenho do arremesso agora (0 a 3 da folha).
func throw_frame() -> int:
	var step := 0
	for k in THROW_STEPS.size():
		if _throw_time >= THROW_STEPS[k]:
			step = k
	return THROW_DRAWINGS[step]


## Arremesso que já começa na soltura (a bola de cura sai da mão na hora): mostra o desenho de soltura
## e o acompanhamento, sem o preparo.
func throw_now() -> void:
	_throw_standing = pose == &"idle"
	pose = &"throw"
	_throw_time = THROW_STEPS[1]


func _track_throw(delta: float) -> void:
	if pose == &"throw":
		if _throw_time < 0.0:
			_throw_time = 0.0
			_throw_standing = _last_pose == &"idle"
		else:
			_throw_time += delta
		return
	_throw_time = -1.0
	_last_pose = pose


func _idle_animation() -> FrameAnimation:
	if smooth_idle:
		return TECO_IDLE12 if teco else TICO_IDLE12
	return TECO_IDLE if teco else TICO_IDLE


## Desenho do parado agora (0 a 11 na versão de 12; 0 a 7 na de 8).
func idle_frame() -> int:
	return _frame_at(_time)


func flash() -> void:
	_flash = 0.5
	# No totem o desenho é um só (na base): o tiro no de cima acende o desenho inteiro.
	if totem_role == TotemRole.TOP and totem_partner != null:
		totem_partner._flash = 0.5


## Liga/desliga levar tiro e machucar ao encostar.
func set_vulnerable(value: bool) -> void:
	hurtbox.monitorable = value
	hitbox.active = value


## Altura da área que machuca (no totem o de cima fica mais baixo para os pedestais serem seguros).
func set_hitbox_height(height: float) -> void:
	var shape := hitbox.get_child(0) as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	rect.size.y = height
	shape.position.y = -height * 0.5


## Altura da área que leva tiro: de `bottom` a `top` px acima do ponto do nó (padrão: de 10 a 180).
func set_hurtbox_span(bottom: float, top: float) -> void:
	var shape := hurtbox.get_child(0) as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	rect.size.y = top - bottom
	shape.position.y = -(bottom + top) * 0.5


## Mão que joga (na frente) e a de trás, no espaço do mundo.
func hand_position() -> Vector2:
	if riding and _totem_hidden():
		return totem_partner._ride_point(RIDE_TOP_HAND)
	if riding and _totem_art():
		return _ride_point(RIDE_BASE_HAND)
	if _totem_hidden():
		var hand: Vector2 = TOTEM_FRONT_HANDS[totem_partner.totem_frame()] * TOTEM_GROW
		return totem_partner.global_position + Vector2(hand.x * totem_partner.facing, hand.y)
	return global_position + Vector2(facing * 38, -150 if pose != &"crouch" else -120)


func head_position() -> Vector2:
	if riding and _totem_art():
		return _ride_point(RIDE_BASE_HEAD)
	if riding and _totem_hidden():
		return totem_partner._ride_point(RIDE_TOP_HEAD)
	if _totem_art():
		var own: Vector2 = TOTEM_BASE_HEADS[totem_frame()] * TOTEM_GROW
		return global_position + Vector2(own.x * facing, own.y)
	if _totem_hidden():
		var top_head: Vector2 = TOTEM_TOP_HEADS[totem_partner.totem_frame()] * TOTEM_GROW
		return totem_partner.global_position + Vector2(top_head.x * totem_partner.facing, top_head.y)
	if _dizzy_art():
		var head := DIZZY_HEADS[dizzy_frame()].rotated(dizzy_rotation())
		return global_position + Vector2(head.x * facing, head.y)
	return global_position + Vector2(0, -180)


## Base do totem com os dois em pé no desenho (fora dos giros das entradas e da derrota).
func _totem_art() -> bool:
	return totem_role == TotemRole.BASE and totem_partner != null and spin == 0.0 and pose != &"down" \
			and totem_partner.spin == 0.0 and totem_partner.pose != &"down"


## O de cima do totem, desenhado pela base agora (não desenha o próprio corpo).
func _totem_hidden() -> bool:
	return totem_role == TotemRole.TOP and totem_partner != null and totem_partner._totem_art()


## Desenho do totem agora (0 a 7 da folha): andando (o arremesso andando fica com as pernas da caminhada: os
## desenhos 7 e 8 parariam as pernas 0,3 s com o totem a 590 px/s), o de cima arremessando parado (preparo até
## a soltura e soltura depois), ou parado. A soltura vem do `throw_released`, marcado pelo ataque
## quando o objeto nasce.
func totem_frame() -> int:
	var top := totem_partner
	if walking:
		return 2 + int(absf(global_position.x - _walk_from_x) / (TOTEM_STEP * TOTEM_GROW)) % 4
	if top != null and top.pose == &"throw":
		return 7 if top.throw_released else 6
	if pose == &"crouch":
		return 1
	return int(_time * TOTEM_IDLE_FPS) % 2


## Desenho do monociclo agora (0 a 7 da folha): o de baixo ou o de cima arremessando (preparo até a soltura e
## soltura depois), ou pedalando: pela distância andada e devagar no lugar, se equilibrando.
func ride_frame() -> int:
	var top := totem_partner
	if pose == &"throw":
		return 5 if _throw_time >= RIDE_RELEASE else 4
	if top != null and top.pose == &"throw":
		return 7 if top._throw_time >= RIDE_RELEASE else 6
	return posmod(floori(global_position.x / (RIDE_STEP * TOTEM_GROW) + _time * RIDE_IDLE_FPS), 4)


## Ponto medido na folha do monociclo (espaço da base olhando para a direita) no mundo.
func _ride_point(point: Vector2) -> Vector2:
	return global_position + Vector2(point.x * facing, point.y) * TOTEM_GROW


## O de cima do totem: as estrelas da tontura na cabeça desenhada e, parado, três bolinhas em arco entre as
## duas luvas dele (o desenho tem as mãos para o alto, malabarizando).
func _draw_totem_top() -> void:
	var base := totem_partner
	if dizzy:
		var head := to_local(head_position())
		for i in 3:
			var a := _time * 5.0 + TAU * i / 3.0
			_draw_star(head + Vector2(cos(a) * 40, -40 + sin(a) * 10), 8.0, Color("ffc93c"))
		return
	# No monociclo o desenho já tem as mãos de cada pose (sem bolinhas por código).
	if riding:
		return
	var frame := base.totem_frame()
	if not juggling or frame > 1:
		return
	var pair: Array = TOTEM_IDLE_HANDS[frame]
	var hands: Array[Vector2] = []
	for hand: Vector2 in pair:
		hands.append(to_local(base.global_position + Vector2(hand.x * base.facing, hand.y - 12.0) * TOTEM_GROW))
	var size := BALL_TEXTURE.get_size() * TOTEM_BALL_SCALE * TOTEM_GROW
	for i in 3:
		var u := fposmod(_time / TOTEM_JUGGLE + i / 3.0, 1.0)
		var at: Vector2
		if u < 0.5:
			at = BossAttack.arc_point(hands[0], hands[1], 70.0 * TOTEM_GROW, u * 2.0)
		else:
			at = BossAttack.arc_point(hands[1], hands[0], 30.0 * TOTEM_GROW, (u - 0.5) * 2.0)
		draw_texture_rect(BALL_TEXTURE, Rect2(at - size * 0.5, size), false)


## Tonto em pé: usa o desenho do tonto.
func _dizzy_art() -> bool:
	return not carrying and dizzy and not walking and spin == 0.0 and pose in [&"idle", &"dizzy", &"throw"]


## Derrotado (deitado): usa o desenho da derrota, mesmo carregando o irmão (no monociclo).
func _defeat_art() -> bool:
	return pose == &"down"


## Desenho da derrota agora (0 a 3).
func defeat_frame() -> int:
	return clampi(floori(maxf(_down_time - defeat_delay, 0.0) * DEFEAT_FPS), 0, 3)


## Agachado, girando ou aterrissando: usa o desenho do salto. Quem fica tonto no meio do salto (levou o tiro
## que faltava durante a Troca de Lugar) termina o salto desenhado e só fica tonto ao pousar; antes, caía no
## boneco de código.
func _flip_art() -> bool:
	if walking:
		return false
	if pose == &"crouch" or pose == &"spin":
		return true
	return not dizzy and pose == &"idle" and _landing > 0.0


## Desenho do salto agora (0 agachado, 1 a 8 a bolinha, 9 aterrissagem).
func flip_frame() -> int:
	if pose == &"crouch":
		return 0
	if pose == &"spin":
		return 1 + posmod(roundi(spin * 8.0), 8)
	return 9


## Inclinação do desenho do tonto agora (radianos, olhando para a direita; 0 sem a suavização).
func dizzy_rotation() -> float:
	if not smooth_dizzy or _dizzy_prev < 0:
		return 0.0
	return _dizzy_tilt_from * (1.0 - smoothstep(0.0, DIZZY_SETTLE, _dizzy_since))


func _track_dizzy(delta: float) -> void:
	if not _dizzy_art():
		_dizzy_prev = -1
		return
	var frame := dizzy_frame()
	if _dizzy_prev >= 0 and frame != _dizzy_prev:
		var old := DIZZY_HEADS[_dizzy_prev]
		var new := DIZZY_HEADS[frame]
		_dizzy_tilt_from = dizzy_rotation() + (atan2(old.x, -old.y) - atan2(new.x, -new.y)) * DIZZY_SETTLE_SHARE
		_dizzy_since = 0.0
	else:
		_dizzy_since += delta
	_dizzy_prev = frame


## Desenho do tonto agora (0 a 3).
func dizzy_frame() -> int:
	return int(_time * DIZZY_FPS) % 4


func _draw() -> void:
	if _totem_hidden():
		_draw_totem_top()
		return
	if _uses_art():
		if _defeat_art() or (_totem_art() and not dizzy):
			return
		if _totem_art():
			var base_head := to_local(head_position())
			for i in 3:
				var a := _time * 5.0 + TAU * i / 3.0
				_draw_star(base_head + Vector2(cos(a) * 40, -40 + sin(a) * 10), 8.0, Color("ffc93c"))
			return
		if _dizzy_art():
			var head := head_position() - global_position
			for i in 3:
				var a := _time * 5.0 + TAU * i / 3.0
				_draw_star(head + Vector2(cos(a) * 58, -58 + sin(a) * 14), 11.0, Color("ffc93c"))
			return
		if juggling and not _throw_art() and not _flip_art():
			for i in 3:
				_draw_prop(i)
		return
	var lying := pose == &"down"
	var crouch := 22.0 if pose == &"crouch" else 0.0
	var center := Vector2(0, -105 + crouch)
	var angle := spin * TAU * facing
	if lying:
		angle = -PI * 0.5 * facing
	draw_set_transform(center, angle)
	var f := float(facing)
	var o := -center
	# Pernas.
	var step := sin(_time * 12.0) * 16.0 if walking else 0.0
	var feet := [Vector2(-16 - step, 0), Vector2(16 + step, 0)]
	if pose == &"sit" or pose == &"ride":
		feet = [Vector2(-10 + 26 * f, -30), Vector2(14 + 26 * f, -24)]
	elif pose == &"spin":
		feet = [Vector2(-14, -40), Vector2(14, -44)]
	for i in 2:
		var hip := o + Vector2(-14 + 28 * i, -70 + crouch)
		var foot: Vector2 = o + feet[i]
		draw_line(hip, foot, INK, 14.0)
		draw_line(hip, foot, CREAM, 8.0)
		draw_circle(foot + Vector2(6 * f, -4), 11, INK)
		draw_circle(foot + Vector2(6 * f, -4), 8, Color("6e1c1b"))
	# Tronco listrado.
	var torso := o + center
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(torso + Vector2(cos(a) * 40, sin(a) * 52))
	draw_colored_polygon(points, CREAM)
	for k in [-30.0, -6.0, 18.0]:
		var w := sqrt(maxf(0.0, 1.0 - pow((k + 7.0) / 52.0, 2))) * 40.0
		draw_rect(Rect2(torso + Vector2(-w, k), Vector2(w * 2, 14)), stripe_color)
	points.append(points[0])
	draw_polyline(points, INK, 4.0, true)
	# Braços e mãos.
	var shoulders := [torso + Vector2(-30, -36), torso + Vector2(30, -36)]
	var hands := _hand_offsets()
	for i in 2:
		var hand: Vector2 = torso + hands[i]
		draw_line(shoulders[i], hand, INK, 11.0)
		draw_line(shoulders[i], hand, stripe_color, 6.0)
		draw_circle(hand, 10, INK)
		draw_circle(hand, 7.5, Color.WHITE)
	# Cabeça.
	var head := torso + Vector2(0, -78)
	draw_circle(head, 36, INK)
	draw_circle(head, 33, SKIN)
	draw_arc(head + Vector2(0, -4), 33, PI * 1.05, PI * 1.95, 16, hair_color, 14.0)
	draw_circle(head + Vector2(-26 * f, -14), 9, hair_color)
	_draw_face(head, f)
	if dizzy:
		for i in 3:
			var a := _time * 5.0 + TAU * i / 3.0
			_draw_star(head + Vector2(cos(a) * 46, -40 + sin(a) * 12), 9.0, Color("ffc93c"))
	# Bolinhas de malabares.
	if juggling and not dizzy and pose in [&"idle", &"sit", &"ride"]:
		for i in 3:
			var a := _time * 7.0 + TAU * i / 3.0
			var at := torso + Vector2(cos(a) * 30, -70 + sin(a) * 46)
			draw_circle(at, 9, INK)
			draw_circle(at, 7, BALL_COLORS[i])
	draw_set_transform(Vector2.ZERO)


## Onde está o objeto `i` (0 a 2) do parado agora, no espaço do irmão, e quanto ele girou: [posição,
## giro, pegada (1 = a clave está na mão, presa pelo cabo; 0 = no ar, girando no meio)]. No ar faz o
## arco; na mão segue a luva do desenho.
func prop_state(i: int) -> Array:
	var since := fposmod(_time - FIRST_RELEASE - i * PROP_CYCLE / 3.0, PROP_CYCLE)
	var released := _time - since
	var at: Vector2
	var turn := 0.0
	var grip := 1.0
	if since < HIGH_FLIGHT:
		var u := since / HIGH_FLIGHT
		var from := _front_palm(released)
		var to := _back_palm(released + HIGH_FLIGHT)
		at = from.bezier_interpolate(from + HIGH_RISE, HIGH_DROP, to, u)
		# Pouco mais de uma volta: a clave chega na mão de trás de cabo para baixo, no ângulo dela.
		turn = (CLUB_BACK_TURN - TAU) * u
		grip = maxf(1.0 - smoothstep(0.0, GRIP_BLEND, since), smoothstep(HIGH_FLIGHT - GRIP_BLEND, HIGH_FLIGHT, since))
	elif since < HIGH_FLIGHT + BACK_HOLD:
		at = _back_palm(_time)
		turn = CLUB_BACK_TURN
	elif since < HIGH_FLIGHT + BACK_HOLD + LOW_FLIGHT:
		var start := released + HIGH_FLIGHT + BACK_HOLD
		var u := (_time - start) / LOW_FLIGHT
		var from := _back_palm(start)
		var to := _front_palm(start + LOW_FLIGHT)
		at = from.lerp(to, u) + Vector2(0, -LOW_ARC * 4.0 * u * (1.0 - u))
		# Passada de mão em mão, de cabo para baixo, virando do ângulo de trás para o da frente.
		turn = CLUB_BACK_TURN * (1.0 - u)
	else:
		at = _front_palm(_time)
	return [Vector2(at.x * facing, at.y), turn * facing, grip]


func _frame_at(time: float) -> int:
	if not smooth_idle:
		return posmod(int(floorf(time * IDLE_FPS)), TICO_IDLE.frame_count())
	var tick := posmod(int(floorf(fposmod(time, IDLE_LOOP) * 60.0 + 0.0001)), 40)
	for k in IDLE12_TICKS.size():
		tick -= IDLE12_TICKS[k]
		if tick < 0:
			return k
	return IDLE12_TICKS.size() - 1


func _front_palm(time: float) -> Vector2:
	return (FRONT_PALMS12 if smooth_idle else FRONT_PALMS)[_frame_at(time)]


func _back_palm(time: float) -> Vector2:
	return (BACK_PALMS12 if smooth_idle else BACK_PALMS)[_frame_at(time)]


func _draw_prop(i: int) -> void:
	var state := prop_state(i)
	var texture: Texture2D = CLUB_TEXTURE if teco else BALL_TEXTURE
	var size := (CLUB_SCALE if teco else BALL_SCALE)
	var angle: float = state[1] + (CLUB_HELD * facing if teco else 0.0)
	# O ponto da textura que fica no lugar do objeto: a pegada da clave na mão, o meio no ar.
	var pivot := texture.get_size() * 0.5
	if teco:
		pivot = pivot.lerp(CLUB_GRIP, state[2])
	draw_set_transform(state[0], angle, Vector2(size * facing, size))
	draw_texture(texture, -pivot)
	draw_set_transform(Vector2.ZERO)


## Onde ficam as mãos (relativo ao meio do tronco) em cada pose.
func _hand_offsets() -> Array:
	var f := float(facing)
	match pose:
		&"throw":
			return [Vector2(-34 * f, -10), Vector2(38 * f, -70)]
		&"crouch":
			return [Vector2(-44, 10), Vector2(44, 10)]
		&"spin":
			return [Vector2(-20, -10), Vector2(20, -10)]
		&"dizzy", &"down":
			return [Vector2(-46, 20), Vector2(46, 20)]
	if dizzy:
		return [Vector2(-46, 20), Vector2(46, 20)]
	var bob := sin(_time * 14.0) * 12.0
	return [Vector2(-30, -6 + bob), Vector2(30, -6 - bob)]


func _draw_face(head: Vector2, f: float) -> void:
	var expression := _expression()
	var eye_y := head.y - 4
	for side in [-1.0, 1.0]:
		var eye := Vector2(head.x + side * 12 + 6 * f, eye_y)
		match expression:
			&"dizzy", &"down":
				draw_line(eye + Vector2(-6, -6), eye + Vector2(6, 6), INK, 3.0)
				draw_line(eye + Vector2(-6, 6), eye + Vector2(6, -6), INK, 3.0)
			&"focus":
				draw_line(eye + Vector2(-7, -2), eye + Vector2(7, 2 * side * f), INK, 4.0)
			_:
				var tall := 10.0 if expression in [&"shout", &"scared"] else 8.0
				draw_circle(eye, tall * 0.8, Color.WHITE)
				draw_circle(eye + Vector2(3 * f, 0), 3.5, INK)
	# Nariz e bigode enrolado.
	var nose := head + Vector2(16 * f, 6)
	draw_circle(nose, 7, Color("e09a7a"))
	for side in [-1.0, 1.0]:
		var start := nose + Vector2(-2 * f, 8)
		draw_arc(start + Vector2(side * 12, 2), 11, 0.2 if side > 0 else PI - 1.2, 1.2 if side > 0 else PI - 0.2, 8, INK, 6.0)
	# Boca.
	var mouth := head + Vector2(8 * f, 22)
	match _expression():
		&"shout", &"scared":
			draw_circle(mouth, 9, INK)
			draw_circle(mouth + Vector2(0, 3), 5, Color("c23b3b"))
		&"laugh":
			draw_arc(mouth, 10, 0.1, PI - 0.1, 10, INK, 4.0)
			draw_circle(mouth + Vector2(0, 4), 6, INK)
		&"dizzy", &"down":
			var wave := PackedVector2Array()
			for i in 7:
				wave.append(mouth + Vector2(-12 + i * 4, sin(i * 1.6 + _time * 8.0) * 3))
			draw_polyline(wave, INK, 3.0)
		&"focus":
			draw_line(mouth + Vector2(-8, 0), mouth + Vector2(8, 0), INK, 4.0)
		_:
			draw_arc(mouth + Vector2(0, -4), 11, 0.3, PI - 0.3, 10, INK, 4.0)


## Cara de cada momento (expressão diferente em cada ação).
func _expression() -> StringName:
	if dizzy:
		return &"dizzy"
	match pose:
		&"throw":
			return &"shout"
		&"crouch":
			return &"focus"
		&"spin":
			return &"laugh"
		&"down":
			return &"down"
	return &"grin"


func _draw_star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, color)
