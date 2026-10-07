extends MagmaAttack
## Coroa Bumerangue: tira a coroa e atira; ela vai até perto da parede da esquerda e volta. A ida e a
## volta passam em duas alturas diferentes, sorteadas entre três: rente ao chão (pular), na altura do
## peito (abaixar) e na altura das jangadas (quem está nelas desce ou pula por cima).
## Na virada, a gema turquesa se solta da coroa e cai devagar (parry). Ele espera careca, com a mão
## na cabeça, e pega a coroa de volta.

const TAKE_OFF := 0.4
const THROW := 0.55
const LEG := 1.3
const TURN := 0.2
const CATCH_HOLD := 0.35
const FAR_X := 170.0
const LOW_Y := 945.0
## Alturas da coroa (y do meio): rente ao chão, peito e jangadas.
const HEIGHTS := [945.0, 812.0, 700.0]
const GEM_FALL := 1.5
## A coroa sai de cima da cabeça dele.
const CROWN_FROM := Vector2(-10, -380)

var _out_y := 945.0
var _back_y := 812.0
var _from := Vector2.ZERO
var _crown: MagmaProp
var _gem: MagmaProp
var _gem_from := Vector2.ZERO


func _start() -> void:
	var first := rng.randi_range(0, HEIGHTS.size() - 1)
	var second := (first + rng.randi_range(1, HEIGHTS.size() - 1)) % HEIGHTS.size()
	_out_y = HEIGHTS[first]
	_back_y = HEIGHTS[second]
	_from = king.global_position + CROWN_FROM
	_crown = null
	_gem = null


func _tick(t: float) -> void:
	var back_end := THROW + LEG * 2.0 + TURN
	if t < TAKE_OFF:
		king.pose(&"crown_throw", 0)
	elif t < THROW + 0.15:
		king.pose(&"crown_throw", 1)
	elif t < back_end:
		king.pose(&"crown_throw", 2)
	else:
		king.pose(&"crown_throw", 3)
	if t >= THROW and t < back_end:
		if _crown == null:
			_crown = spawn(&"crown", _from)
		_crown.global_position = _crown_at(t - THROW)
	elif _crown != null:
		free_prop(_crown)
		_crown = null
	# Gema: solta na virada e cai balançando.
	var since := t - (THROW + LEG)
	if since >= 0.0 and since < GEM_FALL:
		if _gem == null:
			_gem_from = _crown_at(LEG)
			_gem = spawn(&"gem", _gem_from, true, 1)
		var u := since / GEM_FALL
		_gem.global_position = Vector2(_gem_from.x + sin(u * TAU * 1.5) * 40.0, lerpf(_gem_from.y, LOW_Y + 20.0, u))
	elif since >= GEM_FALL and _gem != null:
		free_prop(_gem)
		_gem = null


## Onde está a coroa `s` segundos depois de atirada.
func _crown_at(s: float) -> Vector2:
	var out_y := _out_y
	var back_y := _back_y
	if s < LEG:
		var u := s / LEG
		var x := lerpf(_from.x, FAR_X, 1.0 - pow(1.0 - u, 2.0))
		var y := lerpf(_from.y, out_y, minf(u * 4.0, 1.0))
		return Vector2(x, y)
	if s < LEG + TURN:
		var u := (s - LEG) / TURN
		return Vector2(FAR_X - sin(u * PI) * 30.0, lerpf(out_y, back_y, u))
	var u := clampf((s - LEG - TURN) / LEG, 0.0, 1.0)
	var x := lerpf(FAR_X, _from.x, u * u)
	var y := lerpf(back_y, _from.y, maxf(u * 4.0 - 3.0, 0.0))
	return Vector2(x, y)


func _is_done() -> bool:
	return elapsed > THROW + LEG * 2.0 + TURN + CATCH_HOLD
