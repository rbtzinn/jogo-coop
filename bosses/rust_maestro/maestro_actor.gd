class_name MaestroActor
extends Node2D
## Maestro Ferrugem montado com as peças do desenho-base (tools/cut_maestro_rig.py) e animado por código como
## um boneco articulado: cada peça gira na própria junta. A luta pede a pose (`pose`); aqui ela é suavizada e,
## sem pose pedida, ele rege no compasso do metrônomo (`beat_clock`, do chefão).
## Tiro recebido só dá um brilho curto, sem trocar a pose (mesma regra da Madame Carretel).

const ART_SCALE := 0.62
## Ponto entre os pés no desenho-base: vira a origem do ator (o chão).
const FEET := Vector2(760, 1144)
const RIG := "res://bosses/rust_maestro/art/rig/"
## Peça: [canto no desenho-base (saída do cut_maestro_rig.py), junta onde gira]. Coordenadas do desenho-base.
const PIECES := {
	&"legs": [Vector2(438, 700), Vector2(880, 700)],
	&"torso": [Vector2(624, 249), Vector2(880, 700)],
	&"free_arm": [Vector2(880, 402), Vector2(890, 535)],
	&"head": [Vector2(620, 163), Vector2(712, 392)],
	&"baton_arm": [Vector2(150, 260), Vector2(628, 468)],
}
## Boca dos três tubos de órgão das costas (desenho-base): de onde sai o vapor.
const PIPE_MOUTHS := [Vector2(880, 270), Vector2(922, 335), Vector2(945, 400)]
## Caixa de música no colete (desenho-base): o ponto fraco da fase 3.
const CHEST := Vector2(728, 540)
## Ponta da batuta com o braço parado (desenho-base).
const BATON_TIP := Vector2(158, 266)
## Ângulos de cada pose (radianos): batuta (+ sobe), braço livre (+ desce), cabeça (+ para trás),
## tronco (- curva para a frente) e quanto ele afunda (pixels do jogo).
const POSES := {
	&"idle": [0.0, 0.0, 0.0, 0.0, 0.0],
	&"raise": [0.75, -0.25, 0.08, 0.06, 0.0],
	&"strike": [-0.45, 0.2, -0.08, -0.12, 6.0],
	&"point": [0.05, 0.1, 0.0, -0.05, 0.0],
	&"low": [-0.3, 0.35, -0.1, -0.2, 14.0],
	&"organ": [0.9, -0.9, 0.15, 0.1, 0.0],
	&"bow": [-0.6, 0.5, -0.25, -0.42, 10.0],
	&"defeat": [-1.1, 0.9, -0.45, -0.3, 40.0],
}

var hurtbox := Hurtbox.new()
var hitbox := EnemyHitbox.new()
## Caixa de música: só leva tiro aberta (e então leva dano dobrado, ver RustMaestroBoss).
var chest := Hurtbox.new()
var chest_open := false
## Órgão acordado (fase 2 em diante): os tubos soltam vapor parados.
var organ_awake := false
var defeated := false
## Tempo do compasso (o chefão atualiza; zero em cada começo de ataque nos dois PCs).
var beat_clock := 0.0
var pose_name: StringName = &"idle"

var _art := Node2D.new()
var _upper := Node2D.new()
var _joints := {}
var _angles := [0.0, 0.0, 0.0, 0.0, 0.0]
var _posed := false
var _flash := 0.0
var _flash_cooldown := 0.0
var _blast := 0.0
var _steam := SteamPuffs.new()
var _music_box := MusicBox.new()


## Vapor dos tubos: bolinhas que sobem, crescem e somem. Só visual (cada PC sorteia o seu).
class SteamPuffs extends Node2D:
	var puffs: Array[Dictionary] = []
	var rate := 0.0
	var _spawn := 0.0

	func _process(delta: float) -> void:
		_spawn -= delta * rate
		while _spawn <= 0.0 and rate > 0.0:
			_spawn += 1.0
			var mouth: Vector2 = MaestroActor.PIPE_MOUTHS[randi() % 3]
			puffs.append({"at": mouth, "v": Vector2(randf_range(-30, 50), randf_range(-260, -160)),
				"life": 0.0, "max": randf_range(0.7, 1.1), "size": randf_range(18, 30)})
		for puff in puffs:
			puff.life += delta
			puff.at += puff.v * delta
			puff.v *= 0.97
		puffs = puffs.filter(func(puff: Dictionary) -> bool: return puff.life < puff.max)
		queue_redraw()

	func _draw() -> void:
		for puff in puffs:
			var u: float = puff.life / puff.max
			var radius: float = puff.size * (0.6 + u * 1.6)
			draw_circle(puff.at, radius, Color(0.86, 0.84, 0.8, 0.55 * (1.0 - u)))
			draw_circle(puff.at + Vector2(-radius * 0.25, -radius * 0.25), radius * 0.55, Color(1, 1, 1, 0.35 * (1.0 - u)))


## Caixa de música do peito: a portinha do colete abre e mostra o cilindro de pinos girando, com o aro claro
## dos pontos fracos (o mesmo dos botões da Madame).
class MusicBox extends Node2D:
	var open := 0.0
	var clock := 0.0

	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()

	func _draw() -> void:
		if open <= 0.01:
			return
		var ink := Color("2a1a10")
		var size := Vector2(92, 118) * open
		var box := Rect2(-size * 0.5, size)
		draw_rect(box.grow(7), ink)
		draw_rect(box, Color("140c08"))
		# Cilindro de latão com pinos passando.
		var drum := Rect2(Vector2(-size.x * 0.36, -size.y * 0.32), Vector2(size.x * 0.72, size.y * 0.64))
		draw_rect(drum, Color("b8862f"))
		draw_rect(Rect2(drum.position, Vector2(drum.size.x, drum.size.y * 0.3)), Color("e8c06a"))
		for i in 7:
			var y := drum.position.y + fposmod(i * 17.0 + clock * 60.0, drum.size.y)
			draw_circle(Vector2(drum.position.x + 12 + (i * 23) % int(maxf(drum.size.x - 20, 1)), y), 3.5, Color("fff2cb"))
		draw_rect(drum, ink, false, 3.0)
		# Portinha aberta para a direita, presa na dobradiça.
		var door := PackedVector2Array([box.position + Vector2(box.size.x, 0), box.end + Vector2(0, 0),
			box.end + Vector2(size.x * 0.45, 12), box.position + Vector2(box.size.x + size.x * 0.45, -12)])
		draw_colored_polygon(door, Color("efe2c4"))
		draw_polyline(door + PackedVector2Array([door[0]]), ink, 3.0, true)
		var pulse := 1.0 + sin(clock * 6.0) * 0.06
		draw_arc(Vector2.ZERO, 92 * open * pulse, 0, TAU, 40, Color("fff2cb"), 5.0, true)
		draw_arc(Vector2.ZERO, 104 * open * pulse, 0, TAU, 40, Color(1.0, 0.95, 0.8, 0.35), 3.0, true)


func _ready() -> void:
	_art.name = "Art"
	_art.scale = Vector2.ONE * ART_SCALE
	_art.position = -FEET * ART_SCALE
	add_child(_art)
	_art.add_child(_piece(&"legs", Vector2.ZERO))
	_upper.name = "Upper"
	_upper.position = PIECES[&"torso"][1]
	_art.add_child(_upper)
	_upper.add_child(_piece(&"torso", _upper.position))
	_music_box.position = CHEST - _upper.position
	_upper.add_child(_music_box)
	_steam.position = -_upper.position
	for name in [&"free_arm", &"head", &"baton_arm"]:
		var joint := Node2D.new()
		joint.name = String(name).capitalize().replace(" ", "")
		joint.position = PIECES[name][1] - _upper.position
		joint.add_child(_piece(name, PIECES[name][1]))
		_upper.add_child(joint)
		_joints[name] = joint
	_upper.add_child(_steam)
	_box(hurtbox, "Hurtbox", self, Vector2(-8, -310), Vector2(190, 600))
	_box(hitbox, "Contact", self, Vector2(0, -285), Vector2(150, 550))
	hitbox.active = false
	# A caixa acompanha o tronco quando ele se curva (fica dentro da peça que gira).
	_box(chest, "Chest", _upper, CHEST - _upper.position, Vector2(130, 170))
	chest.monitorable = false
	idle()


func _piece(name: StringName, joint: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = String(name).capitalize().replace(" ", "")
	sprite.texture = load(RIG + String(name) + ".png")
	sprite.centered = false
	sprite.position = PIECES[name][0] - joint
	return sprite


func _box(area: Area2D, label: String, parent: Node, at: Vector2, size: Vector2) -> void:
	area.name = label
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	area.add_child(shape)
	parent.add_child(area)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_flash_cooldown = maxf(0.0, _flash_cooldown - delta)
	_blast = maxf(0.0, _blast - delta)
	var target: Array = POSES.get(pose_name, POSES[&"idle"]).duplicate()
	var beat := absf(sin(PI * beat_clock / RustMaestroBoss.BEAT))
	if not _posed and not defeated:
		# Regendo: a batuta desce em cada tempo do metrônomo.
		target[0] += 0.18 - 0.3 * (1.0 - beat)
		target[1] += 0.12 * beat
		target[2] += 0.04 * beat
	var rate := 1.0 - exp(-delta * (6.0 if defeated else 16.0))
	for i in _angles.size():
		_angles[i] = lerpf(_angles[i], target[i], rate)
	_joints[&"baton_arm"].rotation = _angles[0]
	_joints[&"free_arm"].rotation = _angles[1]
	_joints[&"head"].rotation = _angles[2]
	_upper.rotation = _angles[3]
	_art.position = -FEET * ART_SCALE + Vector2(0, _angles[4] + (0.0 if defeated else 3.0 * beat))
	_art.modulate = Color(1.5, 1.35, 1.2) if _flash > 0.0 else Color.WHITE
	_steam.rate = 0.0 if defeated else (40.0 if _blast > 0.0 else (5.0 if organ_awake else 0.0))
	_music_box.open = move_toward(_music_box.open, 1.0 if chest_open and not defeated else 0.0, delta * 6.0)


## Pose pedida pelo ataque (fica até `idle`).
func pose(name: StringName) -> void:
	_posed = true
	pose_name = name


## Volta a reger no compasso.
func idle() -> void:
	_posed = false
	pose_name = &"idle"


## Os tubos sopram forte por `seconds`.
func blast(seconds := 0.3) -> void:
	_blast = maxf(_blast, seconds)


## Ponta da batuta agora, no mundo (de onde saem as notas e as lâminas de som).
func baton_tip() -> Vector2:
	var joint: Node2D = _joints[&"baton_arm"]
	return joint.to_global(BATON_TIP - PIECES[&"baton_arm"][1])


func flash() -> void:
	if defeated or _flash_cooldown > 0.0:
		return
	_flash = 0.07
	_flash_cooldown = 0.24


## Abre (ou fecha) a caixa de música: aberta, o corpo para de levar tiro e só ela conta.
func set_chest(open: bool) -> void:
	chest_open = open and not defeated
	hurtbox.set_deferred("monitorable", not chest_open and not defeated)
	chest.set_deferred("monitorable", chest_open)


func defeat() -> void:
	defeated = true
	set_chest(false)
	hitbox.active = false
	pose(&"defeat")
