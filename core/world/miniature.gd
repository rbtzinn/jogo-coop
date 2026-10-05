class_name Miniature
extends Node3D
## Miniatura 3D de um personagem para o mundo da aventura: o palhaço ou a acrobata como bonequinhos
## pintados (formas arredondadas, cores chapadas com sombra em degraus e contorno de tinta), montados
## por código a partir de esferas, cápsulas e cilindros, com um esqueleto de pivôs.
## Os pés pisam de verdade: cada pé fica PLANTADO no mundo enquanto apoia (cinemática inversa de duas
## partes, coxa e canela, leva o quadril até ele) e só dá o passo quando fica longe demais do quadril,
## um pé de cada vez, para a frente na direção do movimento. Assim o pé de apoio não desliza no chão,
## e o ritmo dos passos sai da velocidade. Braços opostos às pernas, quadril subindo e descendo, giro
## suave para onde anda, respiração e piscadas parado, e o chapéu ou o coque balançando.
## O desenho olha para +z; o nó gira em y.

const INK := Color("1b1410")
const OUTLINE := preload("res://shaders/ink_outline.gdshader")
const PAINT := preload("res://shaders/miniature.gdshader")
const TURN_SPEED := 10.0
## Altura do passo (fração da perna) e quanto do alcance o pé anda à frente do quadril ao pousar.
const STEP_LIFT := 0.22
const STEP_LEAD := 0.8
## Parado por este tempo, vira de frente para a câmera do mapa (que fica alta, atrás da dupla): sem isso
## só aparecia a nuca (pedido do usuário em 04/10/2026: as miniaturas estavam feias no mapa).
const FACE_CAMERA_DELAY := 0.6
const FACE_CAMERA_SPEED := 5.0
## Cabeça erguida para o rosto aparecer na câmera alta.
const HEAD_TILT := -0.24
## Piloto 3D (04/10/2026): o palhaço modelado no Blender (tools/blender/palhaco_miniatura.py), com esqueleto e
## pele. O andar continua o procedural daqui (pés plantados por IK): um esqueleto de controle invisível, com as
## mesmas juntas do modelo, é posado como antes e os ossos do modelo copiam esse esqueleto a cada quadro.
const CLOWN_MODEL := preload("res://core/world/models/clown.glb")
## Pivô do esqueleto de controle -> osso do modelo.
const CLOWN_BONES := {"hips": "quadril", "torso": "torso", "head": "cabeca", "bouncy": "chapeu",
		"hip0": "coxa_n", "knee0": "canela_n", "ankle0": "pe_n", "hip1": "coxa_p", "knee1": "canela_p", "ankle1": "pe_p",
		"shoulder0": "braco_n", "elbow0": "antebraco_n", "shoulder1": "braco_p", "elbow1": "antebraco_p"}

@export_enum("clown", "acrobat") var kind := "clown"
## Palhaço: o modelo do Blender (falso: o boneco montado por código, a baseline do piloto 3D).
@export var use_model := true
## Desliga o modelo em todas as miniaturas (comparação com a baseline: `-- mundo_piloto <pasta> boneco`).
static var use_models := true

var _mats := {}
var _star_mesh: ArrayMesh
var _hips := Node3D.new()
var _torso := Node3D.new()
var _head := Node3D.new()
var _bouncy := Node3D.new()  # chapéu do palhaço ou coque da acrobata (balança)
var _legs: Array[Dictionary] = []
var _arms: Array[Dictionary] = []
var _eyes: Array[Node3D] = []
var _p := {}  # proporções do personagem
var _walk := 0.0  # 0 parado, 1 andando (suave)
var _time := 0.0
var _yaw := 0.0
var _blink_timer := 2.0
var _bounce_angle := Vector2.ZERO
var _bounce_speed := Vector2.ZERO
var _last_velocity := Vector3.ZERO
## Pés no mundo: posição (do tornozelo no chão), passo em andamento (de, para, progresso).
var _feet: Array[Dictionary] = []
var _step_kick := 0.0
var _still := 0.0
## Modelo do Blender: o esqueleto, os pares [pivô, osso, ajuste do descanso] na ordem pai -> filho e o rosto
## (com a shape key do piscar).
var _skeleton: Skeleton3D
var _drive: Array = []
var _face_mesh: MeshInstance3D
var _blink_shape := -1


func _ready() -> void:
	_build_star_mesh()
	if kind == "acrobat":
		_build_acrobat()
	elif use_model and use_models:
		_build_clown_rig()
		_attach_model(CLOWN_MODEL.instantiate(), CLOWN_BONES)
	else:
		_build_clown()
	_blink_timer = randf_range(1.5, 4.0)


## Chamado a cada quadro pelo andador: velocidade no chão (x, z) em m/s.
func update_pose(delta: float, velocity: Vector3) -> void:
	_time += delta
	var flat := Vector3(velocity.x, 0, velocity.z)
	var speed := flat.length()
	_walk = move_toward(_walk, 1.0 if speed > 0.3 else 0.0, delta * 6.0)
	if speed > 0.3:
		_still = 0.0
		var target := atan2(flat.x, flat.z)
		_yaw = lerp_angle(_yaw, target, 1.0 - exp(-TURN_SPEED * delta))
	else:
		_still += delta
		if _still > FACE_CAMERA_DELAY:
			_yaw = lerp_angle(_yaw, 0.0, 1.0 - exp(-FACE_CAMERA_SPEED * delta))
	rotation.y = _yaw
	_step_feet(delta, flat)
	_pose_body(delta)
	_pose_legs()
	_pose_arms()
	_pose_secondary(delta, velocity)
	_blink(delta)
	_drive_model()


## Cabeça para medir (piloto 3D): [meio no mundo, raio vertical no mundo, para onde o rosto olha (mundo)].
func head_sphere() -> Array:
	var radius: float = _p.get("head_r", 0.23) * _head.global_basis.get_scale().y
	return [_head.global_position, radius, _head.global_basis.z.normalized()]


## Posição no mundo dos tornozelos (para medir se o pé desliza).
func feet_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for leg in _legs:
		out.append((leg.ankle as Node3D).global_position)
	return out


## Onde o pé `i` fica parado embaixo do quadril (no mundo, na altura do chão do personagem).
func _neutral(i: int) -> Vector3:
	var leg: Dictionary = _legs[i]
	var local := Vector3((leg.hip as Node3D).position.x, _p.ankle_h, 0.0)
	return global_transform * local


## Alcance horizontal máximo do pé (em metros do mundo), com a perna quase esticada.
func _reach() -> float:
	var length: float = _p.thigh + _p.shin
	var down: float = _p.hip_y - _p.ankle_h
	return sqrt(maxf(length * length * 0.94 - down * down, 0.0001)) * global_transform.basis.get_scale().x


func _step_feet(delta: float, flat: Vector3) -> void:
	if _feet.is_empty():
		for i in _legs.size():
			_feet.append({"pos": _neutral(i), "from": Vector3.ZERO, "to": Vector3.ZERO, "t": -1.0})
	var reach := _reach()
	var speed := flat.length()
	var dir := flat / speed if speed > 0.05 else Vector3.ZERO
	# O passo leva quase o tempo de o corpo andar um passo (o outro pé apoia enquanto isso).
	var step_length := reach * (0.85 + STEP_LEAD)
	var swing_time := clampf(0.8 * step_length / maxf(speed, 0.5), 0.12, 0.3)
	var swinging := false
	for i in _feet.size():
		var foot: Dictionary = _feet[i]
		if foot.t >= 0.0:
			swinging = true
			# O pouso acompanha o corpo (freando ou virando, o pé não passa do alcance).
			var remaining: float = (1.0 - foot.t) * swing_time
			foot.to = _neutral(i) + dir * reach * STEP_LEAD * clampf(speed / 1.2, 0.0, 1.0) + flat * remaining * 0.5
			foot.t = minf(foot.t + delta / swing_time, 1.0)
			var u: float = foot.t
			var s := u * u * (3.0 - 2.0 * u)
			foot.pos = (foot.from as Vector3).lerp(foot.to, s) + Vector3.UP * sin(PI * u) * STEP_LIFT * _p.thigh * 2.0 * global_transform.basis.get_scale().x
			if foot.t >= 1.0:
				foot.t = -1.0
				foot.pos = foot.to
				_step_kick = 1.0
	_step_kick = maxf(_step_kick - delta * 6.0, 0.0)
	# Nenhum pé no ar: o que estiver mais longe do lugar dele dá o passo (se passou do alcance; ou,
	# parado, se ficou fora do lugar).
	var worst := -1
	var worst_d := 0.0
	for i in _feet.size():
		var n := _neutral(i)
		# Distância do lugar do pé; o pé fora da altura do chão (ex.: o personagem acabou de cair no
		# chão ou subiu um degrau) também conta, para ele se ajeitar.
		var d := maxf(Vector2(_feet[i].pos.x - n.x, _feet[i].pos.z - n.z).length(), absf(_feet[i].pos.y - n.y) * 3.0)
		if _feet[i].t >= 0.0:
			continue
		# Andando, o pé passa do alcance: passo (com o outro pé no ar, só se já estiver no limite, num
		# pulinho, para não arrastar). Parado, ajeita o pé fora do lugar.
		var limit := (reach * 0.85 if not swinging else reach * 0.98) if speed > 0.05 else reach * 0.18
		# Virando no lugar, o pé de apoio pode acabar cruzado embaixo do corpo (do outro lado da linha do
		# meio): a perna não alcança de lado e o tornozelo arrasta. Esse pé dá o passo logo (só com o
		# outro no chão, para não sair pulando).
		var side: float = (_legs[i].hip as Node3D).position.x
		if not swinging and to_local(_feet[i].pos).x * side < 0.0:
			d = maxf(d, limit + 0.001)
		if d > limit and d > worst_d:
			worst = i
			worst_d = d
	if worst >= 0:
		var foot: Dictionary = _feet[worst]
		foot.from = foot.pos
		foot.to = _neutral(worst) + dir * reach * STEP_LEAD + flat * swing_time * 0.5
		foot.t = 0.0


func _pose_legs() -> void:
	for i in _legs.size():
		var leg: Dictionary = _legs[i]
		var hip: Node3D = leg.hip
		var target: Vector3 = _hips.to_local(_feet[i].pos) - hip.position
		# Rolagem pequena para o lado (pé fora da linha do quadril), depois o plano da perna.
		var roll := atan2(target.x, -target.y)
		var down := sqrt(target.x * target.x + target.y * target.y)
		var forward := target.z
		var a: float = _p.thigh
		var b: float = _p.shin
		var d := clampf(sqrt(down * down + forward * forward), absf(a - b) + 0.001, a + b - 0.001)
		var beta := atan2(forward, down)
		var gamma := acos(clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0))
		var t1 := beta + gamma
		var knee_z := a * sin(t1)
		var knee_y := a * cos(t1)
		var t2 := atan2(forward - knee_z, down - knee_y)
		hip.rotation = Vector3(-t1, 0, clampf(roll, -0.9, 0.9))
		(leg.knee as Node3D).rotation.x = t1 - t2
		# Rolagem da sola: no fim do apoio (pé atrás do quadril) o calcanhar sobe; no ar a ponta desce e
		# volta reta para pousar.
		var roll_foot := 0.0
		if _feet[i].t >= 0.0:
			roll_foot = 0.35 * sin(PI * _feet[i].t) * (1.0 - _feet[i].t)
		else:
			roll_foot = clampf(-forward / maxf(_reach() / global_transform.basis.get_scale().x, 0.01) - 0.4, 0.0, 0.6) * 0.6
		(leg.ankle as Node3D).rotation.x = t2 + roll_foot


func _pose_body(_delta: float) -> void:
	# Quadril sobe no meio da passada e desce quando os dois pés estão no chão; a cintura gira com as
	# pernas e o tronco ao contrário.
	var lift := 0.0
	var twist := 0.0
	for i in _feet.size():
		if _feet[i].t >= 0.0:
			lift = maxf(lift, sin(PI * _feet[i].t))
	if _feet.size() == 2:
		var local0 := to_local(_feet[0].pos)
		var local1 := to_local(_feet[1].pos)
		twist = clampf((local0.z - local1.z) / maxf(_reach() / global_transform.basis.get_scale().x, 0.01), -1.0, 1.0)
	var breathe := sin(_time * 2.2) * 0.012 * (1.0 - _walk)
	_hips.position.y = _p.hip_y - _p.bob * _walk + lift * _p.bob * 0.6 * _walk - _step_kick * _p.bob * 0.5
	_hips.rotation.y = twist * 0.14 * _walk
	# Parado, troca o peso de um pé para o outro devagar (balança o corpo de lado).
	var sway := sin(_time * 1.5) * (1.0 - _walk)
	_hips.rotation.z = sway * 0.045
	_torso.rotation.y = -twist * 0.22 * _walk
	_torso.rotation.x = 0.1 * _walk
	_torso.scale = Vector3(1.0 - breathe * 0.5, 1.0 + breathe, 1.0 - breathe * 0.5)
	_head.rotation.y = twist * 0.1 * _walk + sin(_time * 0.7) * 0.15 * (1.0 - _walk)
	_head.rotation.z = twist * 0.05 * _walk - sway * 0.07
	_head.rotation.x = HEAD_TILT + sin(_time * 1.1) * 0.035 * (1.0 - _walk)
	_p.twist = twist


func _pose_arms() -> void:
	var twist: float = _p.get("twist", 0.0)
	for i in _arms.size():
		var arm: Dictionary = _arms[i]
		var side := 1.0 if i == 0 else -1.0
		var idle := sin(_time * 2.2 + i) * 0.04 * (1.0 - _walk)
		# Braço oposto à perna: o braço deste lado vai para a frente quando a perna dele vai para trás.
		var swing: float = twist * side * _p.arm_swing * _walk
		(arm.shoulder as Node3D).rotation.x = swing + idle
		(arm.shoulder as Node3D).rotation.z = side * (_p.arm_out + 0.05 * _walk)
		(arm.elbow as Node3D).rotation.x = -0.35 - 0.3 * maxf(-swing, 0.0)


## Chapéu ou coque: mola que fica para trás quando acelera e balança com o passo.
func _pose_secondary(delta: float, velocity: Vector3) -> void:
	var accel := (velocity - _last_velocity) / maxf(delta, 0.001)
	_last_velocity = velocity
	var local := accel.rotated(Vector3.UP, -_yaw)
	var push := Vector2(-local.z, local.x) * 0.004 + Vector2(_step_kick * 0.06, 0)
	_bounce_speed += (push * 60.0 - _bounce_angle * 90.0) * delta
	_bounce_speed *= exp(-7.0 * delta)
	_bounce_angle += _bounce_speed * delta
	_bounce_angle = _bounce_angle.clamp(Vector2(-0.4, -0.4), Vector2(0.4, 0.4))
	_bouncy.rotation.x = _p.bouncy_tilt + _bounce_angle.x
	_bouncy.rotation.z = _bounce_angle.y


func _blink(delta: float) -> void:
	_blink_timer -= delta
	var closed := _blink_timer < 0.0
	if _blink_timer < -0.12:
		_blink_timer = randf_range(2.0, 4.5)
	for eye in _eyes:
		eye.scale.y = 0.12 if closed else 1.0
	if _blink_shape >= 0:
		_face_mesh.set_blend_shape_value(_blink_shape, 1.0 if closed else 0.0)

## Esqueleto de controle do palhaço modelado (piloto 3D): só pivôs, sem malha, com as MESMAS juntas do modelo
## (tools/blender/palhaco_miniatura.py: quadril a 0,36, coxa e canela de 0,14, tronco 0,02 acima do quadril,
## cabeça 0,64 acima do tronco, ombros a ±0,2 e 0,33, braço 0,12 e antebraço 0,11). O andar é o mesmo do
## boneco (pés plantados, passo pela velocidade).
func _build_clown_rig() -> void:
	_p = {
		"thigh": 0.14, "shin": 0.14, "ankle_h": 0.105, "bob": 0.03, "arm_swing": 0.7, "arm_out": 0.3,
		"hip_y": 0.36, "bouncy_tilt": -0.1, "face": Color("fdf0e4"), "head_r": 0.27,
	}
	add_child(_hips)
	_hips.position.y = _p.hip_y
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		_hips.add_child(hip)
		hip.position = Vector3(side * 0.095, 0, 0)
		var knee := Node3D.new()
		hip.add_child(knee)
		knee.position.y = -_p.thigh
		var ankle := Node3D.new()
		knee.add_child(ankle)
		ankle.position.y = -_p.shin
		_legs.append({"hip": hip, "knee": knee, "ankle": ankle})
	_hips.add_child(_torso)
	_torso.position.y = 0.02
	_torso.add_child(_head)
	_head.position.y = 0.64
	_head.add_child(_bouncy)
	_bouncy.position = Vector3(0.04, 0.2, -0.02)
	for side in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		_torso.add_child(shoulder)
		shoulder.position = Vector3(side * 0.2, 0.33, 0)
		var elbow := Node3D.new()
		shoulder.add_child(elbow)
		elbow.position.y = -0.12
		_arms.append({"shoulder": shoulder, "elbow": elbow})


## Põe o modelo do Blender e liga cada osso a um pivô do esqueleto de controle. O ajuste do descanso (pivô no
## descanso -> osso no descanso) absorve a diferença de eixo entre o pivô e o osso do Blender.
func _attach_model(model: Node3D, bones: Dictionary) -> void:
	add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	var pivots := {"hips": _hips, "torso": _torso, "head": _head, "bouncy": _bouncy}
	for i in _legs.size():
		pivots["hip%d" % i] = _legs[i].hip
		pivots["knee%d" % i] = _legs[i].knee
		pivots["ankle%d" % i] = _legs[i].ankle
	for i in _arms.size():
		pivots["shoulder%d" % i] = _arms[i].shoulder
		pivots["elbow%d" % i] = _arms[i].elbow
	var to_skeleton := _skeleton.global_transform.affine_inverse()
	var order: Array = []
	for key: String in bones:
		var bone := _skeleton.find_bone(bones[key])
		var pivot: Node3D = pivots[key]
		var rest := (to_skeleton * pivot.global_transform).affine_inverse() * _skeleton.get_bone_global_rest(bone)
		order.append([pivot, bone, rest])
	# Pais antes dos filhos (a pose global do filho é guardada em relação à do pai).
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	_drive = order
	# Contorno de tinta em todos os materiais (como os bonecos e o cenário), e o rosto com o piscar.
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(s)
			if source == null:
				continue
			var copy := source.duplicate() as Material
			var ink := ShaderMaterial.new()
			ink.shader = OUTLINE
			ink.set_shader_parameter("ink", INK)
			ink.set_shader_parameter("thickness", 0.006)
			copy.next_pass = ink
			mesh.set_surface_override_material(s, copy)
		var shape := mesh.find_blend_shape_by_name(&"piscar")
		if shape >= 0:
			_face_mesh = mesh
			_blink_shape = shape


## Ossos do modelo = pivôs do esqueleto de controle (depois de posar o boneco no quadro).
func _drive_model() -> void:
	if _skeleton == null:
		return
	var to_skeleton := _skeleton.global_transform.affine_inverse()
	for entry: Array in _drive:
		var pivot: Node3D = entry[0]
		_skeleton.set_bone_global_pose(entry[1], to_skeleton * pivot.global_transform * (entry[2] as Transform3D))


# --- Construção -----------------------------------------------------------------------

func _build_clown() -> void:
	_p = {
		"thigh": 0.15, "shin": 0.15, "ankle_h": 0.105, "bob": 0.03, "arm_swing": 0.7, "arm_out": 0.3,
		"hip_y": 0.36, "bouncy_tilt": -0.1, "face": Color("fdf0e4"), "head_r": 0.23,
	}
	var red := Color("c8302c")
	var cream := Color("f2e2c4")
	var skin: Color = _p.face
	var checker := _paint(red, cream, 0.0, true, 6.0)
	add_child(_hips)
	_hips.position.y = _p.hip_y
	for side in [-1.0, 1.0]:
		var leg := _leg(Vector3(side * 0.095, 0, 0), _p.thigh, _p.shin, 0.06, _paint(red, cream, 0.0, true, 3.0))
		# Babado creme no tornozelo e sapatão marrom grande, de bico redondo, com sola clara.
		for k in 6:
			var a := TAU * k / 6.0
			_ellipsoid(leg.ankle, Vector3(0.035, 0.03, 0.035), cream, Vector3(sin(a) * 0.055, 0.03, cos(a) * 0.055))
		_ellipsoid(leg.ankle, Vector3(0.1, 0.07, 0.19), Color("6b3a1e"), Vector3(0, -0.035, 0.07))
		_ellipsoid(leg.ankle, Vector3(0.095, 0.015, 0.18), Color("e8d3b0"), Vector3(0, -0.09, 0.07))
		_legs.append(leg)
	_hips.add_child(_torso)
	_torso.position.y = 0.02
	# Macacão de quadrados vermelhos e creme (xadrez), redondo, com dois botões dourados grandes.
	_ellipsoid(_torso, Vector3(0.21, 0.23, 0.19), red, Vector3(0, 0.19, 0), checker)
	for y in [0.28, 0.14]:
		_ellipsoid(_torso, Vector3(0.034, 0.034, 0.024), Color("e8b33a"), Vector3(0.08, y, 0.18))
	# Gola de babado grande: dois anéis de gomos creme.
	for ring in 2:
		for i in 16:
			var a := TAU * (i + 0.5 * ring) / 16.0
			var rr := 0.16 + 0.03 * ring
			_ellipsoid(_torso, Vector3(0.07, 0.04, 0.05), cream, Vector3(sin(a) * rr, 0.42 + 0.03 * ring, cos(a) * rr * 0.9),
					null, Vector3(0, a, 0.35))
	_torso.add_child(_head)
	_head.position.y = 0.63
	_ellipsoid(_head, Vector3(0.24, 0.23, 0.22), skin, Vector3.ZERO)
	_face(0.23, 0.055, Color("e23a33"), true)
	# Tufos de cabelo vermelho dos lados: pompons redondos.
	for side in [-1.0, 1.0]:
		for k in 4:
			_ellipsoid(_head, Vector3(0.075, 0.075, 0.075), Color("e0312b"),
					Vector3(side * (0.22 + 0.015 * (k % 2)), 0.06 - 0.06 * k, -0.04 + 0.025 * k))
	# Coroa de tufos vermelhos por trás da cabeça, de um lado ao outro: a câmera do mapa fica atrás e
	# no alto, e sem ela a nuca era um ovo branco.
	for k in 7:
		var a := PI * (0.62 + 0.76 * k / 6.0)
		for row in 2:
			_ellipsoid(_head, Vector3(0.08, 0.075, 0.075), Color("e0312b"),
					Vector3(sin(a) * 0.205, 0.02 - 0.085 * row, cos(a) * 0.19))
	# Cartolinha preta com faixa dourada e margarida grande, um pouco de lado.
	_head.add_child(_bouncy)
	_bouncy.position = Vector3(0.04, 0.2, -0.02)
	var hat := Node3D.new()
	_bouncy.add_child(hat)
	hat.rotation.z = -0.2
	_cylinder(hat, 0.16, 0.16, 0.025, Color("1d1a22"), Vector3(0, 0.01, 0))
	_cylinder(hat, 0.1, 0.115, 0.18, Color("1d1a22"), Vector3(0, 0.1, 0))
	_cylinder(hat, 0.117, 0.118, 0.045, Color("e8b33a"), Vector3(0, 0.045, 0))
	_daisy(hat, Vector3(-0.1, 0.07, 0.06), 1.6)
	for side in [-1.0, 1.0]:
		_arm(Vector3(side * 0.2, 0.34, 0), 0.11, 0.1, 0.045, checker, 0.085)


func _build_acrobat() -> void:
	_p = {
		"thigh": 0.25, "shin": 0.25, "ankle_h": 0.085, "bob": 0.03, "arm_swing": 0.6, "arm_out": 0.22,
		"hip_y": 0.55, "bouncy_tilt": 0.0, "face": Color("f6cfb3"), "head_r": 0.205,
	}
	var teal := Color("1f5a66")
	var gold := Color("e8b33a")
	var skin: Color = _p.face
	var hair := Color("2a1a1c")
	add_child(_hips)
	_hips.position.y = _p.hip_y
	for side in [-1.0, 1.0]:
		var leg := _leg(Vector3(side * 0.065, 0, 0), _p.thigh, _p.shin, 0.05, _paint(skin))
		# Sapato de salto azul-petróleo com tira e bolinha douradas na ponta.
		_ellipsoid(leg.ankle, Vector3(0.055, 0.05, 0.1), teal, Vector3(0, -0.035, 0.045))
		_cylinder(leg.ankle, 0.016, 0.02, 0.07, teal, Vector3(0, -0.05, -0.035))
		_torus(leg.ankle, 0.04, 0.054, gold, Vector3(0, 0.0, 0))
		_ellipsoid(leg.ankle, Vector3(0.032, 0.032, 0.032), gold, Vector3(0, -0.035, 0.145))
		_legs.append(leg)
	_hips.add_child(_torso)
	# Maiô azul-petróleo: quadril, saiote rodado em zigue-zague dourado, cintura fina e peito com a
	# borda dourada em coração; estrela dourada grande na cintura.
	_ellipsoid(_torso, Vector3(0.13, 0.1, 0.1), teal, Vector3(0, 0.03, 0))
	_cylinder(_torso, 0.11, 0.19, 0.08, teal, Vector3(0, -0.03, 0))
	for i in 16:
		var a := TAU * i / 16.0
		_cone(_torso, 0.032, 0.06, gold, Vector3(sin(a) * 0.185, -0.085, cos(a) * 0.17), Vector3(PI, 0, 0))
	_ellipsoid(_torso, Vector3(0.105, 0.1, 0.085), teal, Vector3(0, 0.13, 0))
	_ellipsoid(_torso, Vector3(0.135, 0.11, 0.105), teal, Vector3(0, 0.22, 0.005))
	for side in [-1.0, 1.0]:
		_torus(_torso, 0.05, 0.064, gold, Vector3(side * 0.05, 0.3, 0.06), Vector3(0.6, side * 0.4, 0))
		_cylinder(_torso, 0.008, 0.008, 0.12, gold, Vector3(side * 0.09, 0.34, 0.0), Vector3(0, 0, side * 0.2))
	_star(_torso, 0.075, gold, Vector3(0, 0.07, 0.105))
	_ellipsoid(_torso, Vector3(0.12, 0.06, 0.09), skin, Vector3(0, 0.32, -0.01))
	_cylinder(_torso, 0.04, 0.045, 0.08, skin, Vector3(0, 0.39, 0))
	_torso.add_child(_head)
	_head.position.y = 0.6
	# Cabeça um pouco erguida, para o rosto aparecer na câmera alta do mapa.
	_ellipsoid(_head, Vector3(0.21, 0.205, 0.19), skin, Vector3.ZERO)
	_face(0.21, 0.035, Color("e23a33"), false)
	# Cabelo: calota por trás e por cima (deixa a testa livre), cachos dos lados e coque redondo atrás
	# do alto da cabeça, com tiara de estrelas (balança).
	_ellipsoid(_head, Vector3(0.22, 0.2, 0.19), hair, Vector3(0, 0.05, -0.06))
	for side in [-1.0, 1.0]:
		_ellipsoid(_head, Vector3(0.08, 0.09, 0.08), hair, Vector3(side * 0.17, 0.05, 0.05))
	_head.add_child(_bouncy)
	_bouncy.position = Vector3(0, 0.17, -0.11)
	_ellipsoid(_bouncy, Vector3(0.11, 0.105, 0.11), hair, Vector3(0, 0.08, 0))
	_torus(_bouncy, 0.13, 0.15, gold, Vector3(0, 0.0, 0.08), Vector3(0.55, 0, 0))
	for k in 3:
		_star(_bouncy, 0.035 if k != 1 else 0.05, gold, Vector3((k - 1) * 0.085, 0.05 + (0.03 if k == 1 else 0.0), 0.16), Vector3(-0.4, 0, 0))
	for side in [-1.0, 1.0]:
		_star(_head, 0.045, gold, Vector3(side * 0.2, -0.13, 0.06))
		_arm(Vector3(side * 0.14, 0.3, 0), 0.15, 0.14, 0.035, _paint(skin), 0.06)


## Rosto: olhos grandes de desenho dos anos 30 (muito branco, pupila preta com o "corte de torta" e
## brilho), nariz redondo vermelho, bochechas, sobrancelhas e um sorriso largo em lua com a língua;
## na acrobata, cílios.
func _face(r: float, nose: float, nose_color: Color, clown: bool) -> void:
	var skin: Color = _p.face
	for side in [-1.0, 1.0]:
		var eye := Node3D.new()
		_head.add_child(eye)
		eye.position = Vector3(side * r * 0.27, r * 0.2, r * 0.86)
		eye.rotation.y = side * 0.25
		_ellipsoid(eye, Vector3(r * 0.25, r * 0.36, r * 0.12), Color("fbfaf4"), Vector3.ZERO)
		_ellipsoid(eye, Vector3(r * 0.13, r * 0.22, r * 0.07), Color("15111a"),
				Vector3(side * r * 0.03, -r * 0.05, r * 0.08), null, Vector3.ZERO, false)
		# Corte de torta: uma fatia clara no alto da pupila.
		_ellipsoid(eye, Vector3(r * 0.045, r * 0.08, r * 0.02), Color("fbfaf4"), Vector3(side * r * 0.06, r * 0.05, r * 0.145),
				null, Vector3(0, 0, -side * 0.5), false)
		_eyes.append(eye)
		if not clown:
			for k in 3:
				_box(eye, Vector3(r * 0.03, r * 0.13, r * 0.02), Color("15111a"),
						Vector3(side * r * (0.15 + 0.05 * k), r * 0.34, r * 0.02), Vector3(0, 0, -side * (0.4 + 0.35 * k)))
		_ellipsoid(_head, Vector3(r * 0.13, r * 0.022, r * 0.03), Color("15111a"),
				Vector3(side * r * 0.28, r * 0.64, r * 0.76), null, Vector3(0, side * 0.3, -side * 0.12), false)
		_ellipsoid(_head, Vector3(r * 0.14, r * 0.085, r * 0.05), Color("f08a86"),
				Vector3(side * r * 0.56, -r * 0.18, r * 0.76), null, Vector3(0, side * 0.7, 0), false)
	_ellipsoid(_head, Vector3(nose, nose, nose), nose_color, Vector3(0, -r * 0.04, r + nose * 0.3))
	# Sorriso largo em lua (as pontas para cima): a boca escura e, por cima, uma faixa da cor do rosto
	# que deixa só a curva de baixo; a língua no fundo.
	_ellipsoid(_head, Vector3(r * 0.36, r * 0.22, r * 0.08), Color("3a0f12"), Vector3(0, -r * 0.42, r * 0.84),
			null, Vector3(0.3, 0, 0), false)
	_ellipsoid(_head, Vector3(r * 0.17, r * 0.08, r * 0.06), Color("e2626a"), Vector3(0, -r * 0.55, r * 0.86),
			null, Vector3(0.3, 0, 0), false)
	_ellipsoid(_head, Vector3(r * 0.42, r * 0.16, r * 0.1), skin, Vector3(0, -r * 0.26, r * 0.9),
			null, Vector3(0.25, 0, 0), false)


func _leg(at: Vector3, thigh: float, shin: float, radius: float, material: Material) -> Dictionary:
	var hip := Node3D.new()
	_hips.add_child(hip)
	hip.position = at
	_capsule(hip, radius, thigh, material)
	var knee := Node3D.new()
	hip.add_child(knee)
	knee.position.y = -thigh
	_capsule(knee, radius * 0.92, shin, material)
	var ankle := Node3D.new()
	knee.add_child(ankle)
	ankle.position.y = -shin
	return {"hip": hip, "knee": knee, "ankle": ankle}


func _arm(at: Vector3, upper: float, lower: float, radius: float, material: Material, glove: float) -> void:
	var shoulder := Node3D.new()
	_torso.add_child(shoulder)
	shoulder.position = at
	_capsule(shoulder, radius, upper, material)
	var elbow := Node3D.new()
	shoulder.add_child(elbow)
	elbow.position.y = -upper
	_capsule(elbow, radius * 0.9, lower, material)
	# Luva branca de desenho animado, com o polegar.
	_ellipsoid(elbow, Vector3(glove, glove * 1.1, glove), Color("fbfaf4"), Vector3(0, -lower - glove * 0.6, 0))
	_ellipsoid(elbow, Vector3(glove * 0.4, glove * 0.55, glove * 0.4), Color("fbfaf4"),
			Vector3(0, -lower - glove * 0.3, glove * 0.75))
	_arms.append({"shoulder": shoulder, "elbow": elbow})


func _daisy(parent: Node3D, at: Vector3, size := 1.0) -> void:
	var flower := Node3D.new()
	parent.add_child(flower)
	flower.position = at
	flower.scale = Vector3.ONE * size
	flower.rotation.y = 0.9
	for i in 8:
		var a := TAU * i / 8.0
		_ellipsoid(flower, Vector3(0.02, 0.008, 0.035), Color("fbfaf4"), Vector3(sin(a) * 0.03, 0, cos(a) * 0.03),
				null, Vector3(0, a, 0), false)
	_ellipsoid(flower, Vector3(0.018, 0.012, 0.018), Color("f2c230"), Vector3(0, 0.006, 0))


# --- Peças ------------------------------------------------------------------------------

## Material pintado (com o contorno de tinta). `diamonds` > 0 desenha losangos de arlequim;
## `checker` > 0, quadrados (xadrez) em volta.
func _paint(color: Color, pattern := Color.WHITE, diamonds := 0.0, outline := true, checker := 0.0) -> ShaderMaterial:
	var key := "%s|%s|%s|%s|%s" % [color, pattern, diamonds, outline, checker]
	if _mats.has(key):
		return _mats[key]
	var material := ShaderMaterial.new()
	material.shader = PAINT
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("pattern_color", pattern)
	material.set_shader_parameter("diamonds", diamonds)
	material.set_shader_parameter("checker", checker)
	if outline:
		var ink := ShaderMaterial.new()
		ink.shader = OUTLINE
		ink.set_shader_parameter("ink", INK)
		ink.set_shader_parameter("thickness", 0.008 if kind == "acrobat" else 0.01)
		material.next_pass = ink
	_mats[key] = material
	return material


func _mesh(parent: Node3D, mesh: Mesh, color: Color, at: Vector3, material: Material, rot := Vector3.ZERO,
		outline := true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material if material != null else _paint(color, Color.WHITE, 0.0, outline)
	node.position = at
	node.rotation = rot
	parent.add_child(node)
	return node


func _ellipsoid(parent: Node3D, radii: Vector3, color: Color, at: Vector3, material: Material = null,
		rot := Vector3.ZERO, outline := true) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 20
	sphere.rings = 12
	var node := _mesh(parent, sphere, color, at, material, rot, outline)
	node.scale = radii * 2.0
	return node


## Cápsula pendurada do pivô para baixo (coxa, canela, braço).
func _capsule(parent: Node3D, radius: float, length: float, material: Material) -> MeshInstance3D:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = length + radius * 2.0
	capsule.radial_segments = 14
	capsule.rings = 6
	return _mesh(parent, capsule, Color.WHITE, Vector3(0, -length * 0.5, 0), material)


func _cylinder(parent: Node3D, top: float, bottom: float, height: float, color: Color, at: Vector3,
		rot := Vector3.ZERO) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = 20
	return _mesh(parent, cylinder, color, at, null, rot)


func _cone(parent: Node3D, radius: float, height: float, color: Color, at: Vector3, rot := Vector3.ZERO) -> void:
	_cylinder(parent, 0.0, radius, height, color, at, rot)


func _torus(parent: Node3D, inner: float, outer: float, color: Color, at: Vector3, rot := Vector3.ZERO) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 24
	torus.ring_segments = 8
	_mesh(parent, torus, color, at, null, rot)


func _box(parent: Node3D, size: Vector3, color: Color, at: Vector3, rot := Vector3.ZERO) -> void:
	var box := BoxMesh.new()
	box.size = size
	_mesh(parent, box, color, at, null, rot, false)


## Estrela de 5 pontas com espessura, virada para +z.
func _star(parent: Node3D, radius: float, color: Color, at: Vector3, rot := Vector3.ZERO) -> void:
	var node := _mesh(parent, _star_mesh, color, at, null, rot)
	node.scale = Vector3.ONE * radius


func _build_star_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for i in 10:
		var a := TAU * i / 10.0 - PI * 0.5
		var r := 1.0 if i % 2 == 0 else 0.45
		points.append(Vector3(cos(a) * r, -sin(a) * r, 0))
	var depth := 0.35
	for face in [1.0, -1.0]:
		for i in 10:
			var a := points[i] + Vector3(0, 0, depth * face)
			var b := points[(i + 1) % 10] + Vector3(0, 0, depth * face)
			var c := Vector3(0, 0, depth * face * 1.4)
			if face > 0:
				st.add_vertex(c); st.add_vertex(a); st.add_vertex(b)
			else:
				st.add_vertex(c); st.add_vertex(b); st.add_vertex(a)
	for i in 10:
		var a := points[i]
		var b := points[(i + 1) % 10]
		var f := Vector3(0, 0, depth)
		st.add_vertex(a + f); st.add_vertex(b - f); st.add_vertex(b + f)
		st.add_vertex(a + f); st.add_vertex(a - f); st.add_vertex(b - f)
	st.generate_normals()
	_star_mesh = st.commit()
