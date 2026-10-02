extends JugglerAttack
## Troca para a fase 2, "Totem!": o irmão da direita dá um salto mortal enorme e cai sentado
## nos ombros do da esquerda. Daqui em diante andam juntos.

const CROUCH := 0.5
const FLIGHT := 1.1
const TA_DA := 0.6

var _base: Juggler
var _top: Juggler
var _from := Vector2.ZERO
var _landed := false


func _start() -> void:
	_base = boss.left()
	_top = boss.right()
	boss.base_name = String(_base.name)
	_from = _top.global_position
	_landed = false
	_base.facing = 1


func _tick(t: float) -> void:
	if t < CROUCH:
		_top.pose = &"crouch"
		_base.pose = &"idle"
		return
	var u := clampf((t - CROUCH) / FLIGHT, 0.0, 1.0)
	if u < 1.0:
		var to := _base.global_position - Vector2(0, JugglersBoss.SHOULDER)
		_top.global_position = arc_point(_from, to, 420.0, u)
		_top.pose = &"spin"
		_top.spin = -u * 2.0
		return
	if not _landed:
		_land()
	_base.pose = &"throw" if t < CROUCH + FLIGHT + TA_DA * 0.7 else &"idle"


func _is_done() -> bool:
	return elapsed >= CROUCH + FLIGHT + TA_DA


func _stop() -> void:
	if not _landed and _base != null:
		_land()
	if _base != null:
		_base.pose = &"idle"


func _land() -> void:
	_landed = true
	_top.spin = 0.0
	_top.facing = 1
	boss.set_mode(&"totem")
	boss.place_group(_base.global_position.x)
	Fx.spawn(preload("res://components/fx/dust_puff.tscn"), _base.global_position)
