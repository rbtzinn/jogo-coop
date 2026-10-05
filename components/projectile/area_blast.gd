class_name AreaBlast
extends Node2D
## Explosão em área que dura um instante (Canhão de Confete, Bolhona): um anel que cresce e
## um DamageArea redondo que acerta o chefão algumas vezes. Na cópia do parceiro é só visual.
## Com `art` (desenho quadro a quadro), o desenho toma o lugar do anel; na qualidade Baixa
## (sem efeitos) o anel volta.

const DURATION := 0.4

var radius := 200.0
var color := Color("ffc93c")
## Desenha o anel (falso quando o desenho quadro a quadro está tocando).
var ring := true

var _time := 0.0
var _damage: DamageArea


static func spawn(at: Vector2, blast_radius: float, damage: int, hits: int, deals_damage: bool, source: String,
		blast_color := Color("ffc93c"), art: FrameAnimation = null) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var blast := AreaBlast.new()
	blast.radius = blast_radius
	blast.color = blast_color
	blast._damage = DamageArea.new()
	blast._damage.damage = damage
	blast._damage.max_hits = hits
	blast._damage.interval = DURATION / maxf(hits, 1)
	blast._damage.deals_damage = deals_damage
	blast._damage.source = source
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = blast_radius
	shape.shape = circle
	blast._damage.add_child(shape)
	blast.add_child(blast._damage)
	# Pode nascer no meio de uma colisão (tiro acertando): entra na cena no fim do quadro.
	blast.position = at
	blast.z_index = 40
	tree.current_scene.add_child.call_deferred(blast)
	ParryFlash.spawn(at, blast_radius / 90.0, blast_color, Color.WHITE)
	if art != null and Settings.quality != Settings.Quality.LOW:
		blast.ring = false
		Fx.burst(art, at, 0.0, art.frame_count() / DURATION)


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if not ring:
		return
	var k := _time / DURATION
	draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * k), Color(color, 0.25 * (1.0 - k)))
	draw_arc(Vector2.ZERO, radius * (0.4 + 0.6 * k), 0.0, TAU, 40, Color(color, 1.0 - k), 8.0)
