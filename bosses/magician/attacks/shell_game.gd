extends MagicianAttack
## Jogo das Três Caixas (fase 2): o mágico entra numa de três caixas no chão e elas se
## embaralham. Depois vem um tempo para adivinhar: atirar na caixa certa machuca 50% a mais;
## a errada se abre e solta duas pombas que cruzam o palco. No fim ele aparece na caixa certa.
## Quem decide o dano é o host (ver MagicianBoss.apply_damage); abrir uma caixa errada vale
## nos dois PCs.

const SLOTS := [560.0, 960.0, 1360.0]
const FLOOR_Y := 1000.0
const STEP_IN := 0.9
const SHUFFLE := 1.2
const SWAPS := 5
const SWAP_TIME := 0.45
const GUESS := 3.6
const REVEAL := 0.9
const DOVE_SPEED := 520.0
## Entrada (dentro do STEP_IN), sem andar à vista: até BOW_IN a tampa da caixa dele abre e ele faz a
## reverência no lugar; até ARRIVE some pela capa no lugar (o desenho da M5); totalmente invisível, vai para a
## caixa e reaparece na frente dela, enrolado na capa (`vanish` SHOWN), até SINK; então afunda na caixa e a
## tampa fecha com um tranco. A pista de qual caixa é ele mesmo na frente da tampa aberta (se ele começa
## parado na frente de outra caixa, sumir ali sozinho enganaria).
const BOW_IN := 0.2
const ARRIVE := 0.4
const SHOW := 0.15
const SHOWN := 0.25
const SINK := 0.75
## Na revelação ele desenrola da capa na caixa certa (o sumir da M5 ao contrário) antes da reverência.
const UNWRAP := 0.25
const POOF := preload("res://components/fx/dust_puff.tscn")

## Caixa (índice do nó) em que ele está.
var _hidden_in := 0
## Para cada caixa, em qual lugar ela está.
var _slot_of: Array[int] = [0, 1, 2]
## Trocas: [tempo, caixa a, caixa b].
## (a sobe no arco por cima, b passa por baixo.)
var _swaps: Array = []
var _opened: Array[bool] = [false, false, false]
## Pombas: [objeto, origem, direção, tempo em que saiu].
var _doves: Array = []
var _revealed := false
var _revealed_at := 0.0
var _arrived := false
var _faded := false


func correct_box() -> int:
	return _hidden_in


## Abre uma caixa errada (solta as pombas). Retorna falso se já estava aberta ou é a certa.
func open_box(index: int) -> bool:
	if index == _hidden_in or _opened[index] or not is_running():
		return false
	_opened[index] = true
	var box: MagicBox = boss.boxes[index]
	box.open = 1.0
	box.hurtbox.monitorable = false
	for side in [-1.0, 1.0]:
		var dove := make_prop(&"dove", false, 10 + index * 2 + (0 if side < 0 else 1))
		dove.heading = Vector2(side, 0)
		_doves.append([dove, box.global_position + Vector2(0, -150), side, elapsed])
	return true


func _start() -> void:
	_slot_of = [0, 1, 2]
	_opened = [false, false, false]
	_doves.clear()
	_revealed = false
	_arrived = false
	_faded = false
	_hidden_in = rng.randi_range(0, 2)
	_swaps.clear()
	# Cada troca usa um par diferente do da anterior (nenhuma desfaz a anterior); com 3 caixas, a que fica
	# de fora nunca é a mesma duas vezes seguidas, então a caixa dele se mexe pelo menos 2 vezes em 5.
	var left_out := -1
	for i in SWAPS:
		left_out = rng.randi_range(0, 2) if left_out < 0 else (left_out + 1 + rng.randi_range(0, 1)) % 3
		var a := (left_out + 1) % 3
		var b := (left_out + 2) % 3
		if rng.randi_range(0, 1) == 1:
			var tmp := a
			a = b
			b = tmp
		_swaps.append([SHUFFLE + i * SWAP_TIME, a, b])
	for i in 3:
		var box: MagicBox = boss.boxes[i]
		box.show()
		box.open = 0.0
		box.shake = 0.0
		box.saw_line = NAN
		box.hurtbox.monitorable = false
		box.global_position = Vector2(SLOTS[i], FLOOR_Y)
		box.reset_physics_interpolation()
	boss.zaratan.pose = &"bow"


func _tick(t: float) -> void:
	var zaratan := boss.zaratan
	var hiding_box: MagicBox = boss.boxes[_hidden_in]
	if t < STEP_IN:
		# Reverência no lugar com a tampa abrindo, some pela capa no lugar, invisível vai para a caixa, aparece
		# enrolado na frente dela e afunda.
		if t >= BOW_IN and not _faded:
			_faded = true
			Fx.spawn(POOF, zaratan.global_position + Vector2(0, -120))
		zaratan.vanish = _step_in_vanish(t)
		if t >= ARRIVE and not _arrived:
			_arrived = true
			zaratan.vanish = 1.0
			zaratan.global_position = hiding_box.global_position
			zaratan.reset_physics_interpolation()
			Fx.spawn(POOF, hiding_box.global_position + Vector2(0, -120))
		if t < SINK:
			hiding_box.open = clampf(t / BOW_IN, 0.0, 1.0)
		else:
			hiding_box.open = clampf(1.0 - (t - SINK) / (STEP_IN - SINK), 0.0, 1.0)
		if t > 0.45:
			zaratan.set_present(false)
	elif not _revealed:
		# Escondido durante o embaralhar: totalmente invisível (antes ficava em ~0,96, uma cartola quase
		# transparente no lugar de entrada).
		hiding_box.open = 0.0
		zaratan.vanish = 1.0
	if _revealed:
		zaratan.vanish = clampf(1.0 - (t - _revealed_at) / UNWRAP, 0.0, 1.0)
	_update_shuffle(t)
	var guess_start := SHUFFLE + SWAPS * SWAP_TIME
	var guessing := t >= guess_start and t < guess_start + GUESS
	for i in 3:
		var box: MagicBox = boss.boxes[i]
		if not _opened[i]:
			box.hurtbox.monitorable = guessing
			var slam := i == _hidden_in and t >= SINK and t < STEP_IN
			box.shake = 0.3 if guessing else (0.8 if slam else 0.0)
	if t >= guess_start + GUESS and not _revealed:
		_reveal()
	_update_doves(t)


func _update_shuffle(t: float) -> void:
	# Posição de cada caixa: trocas já feitas + a troca em andamento (em arco).
	var slots := [0, 1, 2]
	var moving := -1
	for i in _swaps.size():
		var swap: Array = _swaps[i]
		if t >= swap[0] + SWAP_TIME:
			var tmp: int = slots[swap[1]]
			slots[swap[1]] = slots[swap[2]]
			slots[swap[2]] = tmp
		elif t >= swap[0]:
			moving = i
	for i in 3:
		var box: MagicBox = boss.boxes[i]
		box.global_position = Vector2(SLOTS[slots[i]], FLOOR_Y)
	if moving >= 0:
		var swap: Array = _swaps[moving]
		var u: float = (t - swap[0]) / SWAP_TIME
		var a: MagicBox = boss.boxes[swap[1]]
		var b: MagicBox = boss.boxes[swap[2]]
		var from_a := Vector2(SLOTS[slots[swap[1]]], FLOOR_Y)
		var from_b := Vector2(SLOTS[slots[swap[2]]], FLOOR_Y)
		a.global_position = arc_point(from_a, from_b, 60.0, u)
		b.global_position = arc_point(from_b, from_a, -30.0, u)


func _reveal() -> void:
	_revealed = true
	_revealed_at = elapsed
	var box: MagicBox = boss.boxes[_hidden_in]
	box.open = 1.0
	var zaratan := boss.zaratan
	zaratan.global_position = box.global_position
	zaratan.reset_physics_interpolation()
	zaratan.vanish = 1.0
	Fx.spawn(POOF, box.global_position + Vector2(0, -120))
	zaratan.set_present(true)
	zaratan.pose = &"bow"
	CheerText.spawn(box.global_position + Vector2(0, -320), "Ta-dá!", Color("ffe36a"))


func _update_doves(t: float) -> void:
	for dove in _doves:
		var prop: MagicProp = dove[0] if is_instance_valid(dove[0]) else null
		if prop == null:
			continue
		var since: float = t - dove[3]
		var x: float = dove[1].x + dove[2] * DOVE_SPEED * since
		prop.global_position = Vector2(x, 790.0 + sin(since * 5.0) * 50.0)
		if x < -80.0 or x > 2000.0:
			prop.queue_free()


func _is_done() -> bool:
	return elapsed >= SHUFFLE + SWAPS * SWAP_TIME + GUESS + REVEAL


func _stop() -> void:
	for box: MagicBox in boss.boxes:
		box.hide()
		box.hurtbox.monitorable = false
	var zaratan := boss.zaratan
	if not _revealed:
		zaratan.global_position = boss.boxes[_hidden_in].global_position
	zaratan.vanish = 0.0
	zaratan.set_present(true)
	zaratan.pose = &"idle"
	zaratan.facing = -1 if zaratan.global_position.x > 960.0 else 1


## O plano desta rodada (para os testes e pilotos): [caixa em que ele entra, trocas [tempo, a, b]].
func plan() -> Array:
	return [_hidden_in, _swaps.duplicate(true)]


## Quanto ele sumiu na entrada, pelo tempo: 0 na reverência, sobe a 1 no lugar, cai a SHOWN na frente da
## caixa e volta a 1 afundando nela.
func _step_in_vanish(t: float) -> float:
	if t < BOW_IN:
		return 0.0
	if t < ARRIVE:
		return (t - BOW_IN) / (ARRIVE - BOW_IN)
	if t < ARRIVE + SHOW:
		return lerpf(1.0, SHOWN, (t - ARRIVE) / SHOW)
	if t < SINK:
		return SHOWN
	return lerpf(SHOWN, 1.0, clampf((t - SINK) / (STEP_IN - SINK), 0.0, 1.0))
