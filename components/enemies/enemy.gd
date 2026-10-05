class_name Enemy
extends Node2D
## Inimigo pequeno das fases de plataforma. Anda pelo relógio da fase (RunLevel.clock), igual
## nos dois PCs, sem mandar posição pela rede. Quem decide a vida e a morte é o host (o tiro
## do cliente é avisado pelo RunLevel). Os rosa aceitam parry (morrem com ele).
## As áreas são criadas aqui: Hurtbox (leva tiro) e EnemyHitbox (encostar machuca).
## Cada tipo sobrescreve `_move(t)` e mostra o desenho dele (quadros num Sprite2D, `_update_art`).
## Com `death_drawn`, a derrota é desenhada pelo tipo (`_update_death`) em vez de crescer e sumir.

const POOF := preload("res://components/fx/dust_puff.tscn")
const INK := Color("1b1410")

@export var max_health := 4
## Caixa do corpo (a área que leva tiro; a que machuca é um pouco menor).
@export var body_size := Vector2(70, 90)
@export var pink := false
## Quanto dura a derrota (segundos) e se ela é desenhada pelo tipo.
var death_duration := 0.25
var death_drawn := false

var health := 0
var dead := false
## Identifica o inimigo nos dois PCs (parry).
var parry_id := ""
var hurtbox: Hurtbox
var hitbox: EnemyHitbox
## Onde ele foi colocado (os movimentos são em volta deste ponto).
var home := Vector2.ZERO

var _flash := 0.0
var _vanish := 0.0


func _ready() -> void:
	add_to_group(&"enemies")
	health = max_health
	home = position
	parry_id = "enemy:%s" % name
	hurtbox = Hurtbox.new()
	hurtbox.add_child(_box(body_size))
	add_child(hurtbox)
	hurtbox.hit.connect(_on_hit)
	hitbox = EnemyHitbox.new()
	hitbox.parryable = pink
	if pink:
		hitbox.parry_target = self
	hitbox.add_child(_box(body_size * 0.8))
	add_child(hitbox)


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta * 6.0, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6, 1.0 - _vanish)
	if dead:
		_vanish = minf(_vanish + delta / death_duration, 1.0)
		if death_drawn:
			# O desenho da derrota toca e só some no último quarto.
			modulate.a = clampf((1.0 - _vanish) * 4.0, 0.0, 1.0)
			_update_death(_vanish)
		else:
			scale = Vector2.ONE * (1.0 + _vanish * 0.5)
		if _vanish >= 1.0:
			hide()
			set_physics_process(false)
		return
	var level := RunLevel.find(get_tree())
	_move(level.clock if level != null else 0.0)
	_update_art()


## Só no host. Retorna verdadeiro se morreu com este dano.
func take_damage(amount: int) -> bool:
	if dead:
		return false
	health -= amount
	if health <= 0:
		die()
		return true
	return false


func die() -> void:
	if dead:
		return
	dead = true
	hurtbox.set_deferred(&"monitorable", false)
	hitbox.active = false
	Fx.spawn(POOF, global_position)


## Rosa: o parry derruba na hora (nos dois PCs).
func on_parried() -> void:
	die()


func _on_hit(amount: int, _source: String) -> void:
	_flash = 0.5
	if dead:
		return
	var level := RunLevel.find(get_tree())
	if level != null:
		level.report_enemy_hit(self, amount)


func _box(box_size: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = box_size
	shape.shape = rect
	shape.position = Vector2(0, -body_size.y * 0.5)
	return shape


# --- Para cada tipo sobrescrever ---

func _move(_t: float) -> void:
	pass


## Escolhe o quadro do desenho (chamado depois de `_move`).
func _update_art() -> void:
	pass


## Derrota desenhada (`death_drawn`): `progress` vai de 0 a 1.
func _update_death(_progress: float) -> void:
	pass
