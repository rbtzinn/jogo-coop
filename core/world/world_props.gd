class_name WorldProps
## Peças do diorama do mundo 3D (circo assombrado artesanal dos anos 30), montadas por código com
## formas simples, cor chapada com sombra em degraus (toon) e contorno de tinta nas peças grandes:
## tendas listradas, carroção, barraca de vendedor, cercas de corda, postes com lanterna, varais de
## bandeirolas, árvores secas, fardos de palha, barris, caixotes, jaula, trilhos e locomotiva.
## As peças repetidas (tábuas, estacas, cordas, bandeirolas) usam MultiMesh.

const INK := Color("1b1410")
const PAINT := preload("res://shaders/miniature.gdshader")
const OUTLINE := preload("res://shaders/ink_outline.gdshader")
const STRIPES := preload("res://shaders/world_stripes.gdshader")
const WOOD := Color("6e4a2c")
const WOOD_DARK := Color("4a3020")
const GOLD := Color("e8b33a")
const CREAM := Color("f2e2c4")
const LAMP := Color("ffb347")

static var _mats := {}


# --- Materiais ----------------------------------------------------------------------------------

static func paint(color: Color, outline := 0.0) -> Material:
	var key := "%s|%s" % [color, outline]
	if _mats.has(key):
		return _mats[key]
	var material := ShaderMaterial.new()
	material.shader = PAINT
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("rim_strength", 0.12)
	material.set_shader_parameter("roughness_value", 0.85)
	if outline > 0.0:
		var ink := ShaderMaterial.new()
		ink.shader = OUTLINE
		ink.set_shader_parameter("ink", INK)
		ink.set_shader_parameter("thickness", outline)
		material.next_pass = ink
	_mats[key] = material
	return material


static func stripes(a: Color, b: Color, count := 12.0, outline := 0.03) -> Material:
	var key := "s%s|%s|%s" % [a, b, count]
	if _mats.has(key):
		return _mats[key]
	var material := ShaderMaterial.new()
	material.shader = STRIPES
	material.set_shader_parameter("color_a", a)
	material.set_shader_parameter("color_b", b)
	material.set_shader_parameter("stripes", count)
	var ink := ShaderMaterial.new()
	ink.shader = OUTLINE
	ink.set_shader_parameter("ink", INK)
	ink.set_shader_parameter("thickness", outline)
	material.next_pass = ink
	_mats[key] = material
	return material


static func glow(color: Color, energy := 3.0) -> Material:
	var key := "g%s|%s" % [color, energy]
	if _mats.has(key):
		return _mats[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_mats[key] = material
	return material


# --- Formas -------------------------------------------------------------------------------------

static func add(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, rot := Vector3.ZERO,
		scale := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.rotation = rot
	node.scale = scale
	parent.add_child(node)
	return node


static func box(parent: Node3D, size: Vector3, material: Material, at: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add(parent, mesh, material, at, rot)


static func cylinder(parent: Node3D, top: float, bottom: float, height: float, material: Material, at: Vector3,
		rot := Vector3.ZERO, segments := 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return add(parent, mesh, material, at, rot)


static func sphere(parent: Node3D, radii: Vector3, material: Material, at: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return add(parent, mesh, material, at, Vector3.ZERO, radii * 2.0)


static func torus(parent: Node3D, inner: float, outer: float, material: Material, at: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 8
	return add(parent, mesh, material, at, rot)


## Sombra macia no chão (disco escuro transparente), para assentar as peças no terreno.
static func contact_shadow(parent: Node3D, radius: float, at := Vector3.ZERO, strength := 0.45) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.01
	mesh.radial_segments = 24
	var key := "shadow%s" % strength
	if not _mats.has(key):
		var material := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never;\nuniform float strength = 0.45;\nvoid fragment() {\n\tfloat d = length(UV - vec2(0.5)) * 2.0;\n\tALBEDO = vec3(0.04, 0.02, 0.05);\n\tALPHA = strength * (1.0 - smoothstep(0.2, 1.0, d));\n}\n"
		material.shader = shader
		material.set_shader_parameter("strength", strength)
		_mats[key] = material
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	var node := add(parent, plane, _mats[key], at + Vector3(0, 0.03, 0))
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# --- Peças --------------------------------------------------------------------------------------

## Tenda de circo: corpo listrado, telhado em cone com a aba recortada, porta com cortinas abertas e
## luz âmbar saindo, mastro com bandeirola. `height` = altura do corpo.
static func tent(parent: Node3D, radius: float, height: float, color: Color, trim: Color, dim := 1.0) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var a := color * dim
	var b := CREAM * dim
	a.a = 1.0
	b.a = 1.0
	var walls := cylinder(root, radius, radius * 1.03, height, stripes(a, b, 14.0), Vector3(0, height * 0.5, 0), Vector3.ZERO, 28)
	walls.name = "Walls"
	cylinder(root, radius * 1.18, radius * 1.18, 0.12, paint(trim * dim, 0.02), Vector3(0, height + 0.02, 0), Vector3.ZERO, 28)
	# Aba recortada (gomos pendurados em volta).
	for i in 18:
		var ang := TAU * i / 18.0
		sphere(root, Vector3(0.28, 0.16, 0.08), paint(trim * dim), Vector3(sin(ang) * radius * 1.17, height - 0.1, cos(ang) * radius * 1.17))
	var roof := cylinder(root, 0.06, radius * 1.2, radius * 1.05, stripes(b, a, 14.0), Vector3(0, height + radius * 0.52, 0), Vector3.ZERO, 28)
	roof.name = "Roof"
	var top := height + radius * 1.05
	cylinder(root, 0.04, 0.05, 1.1, paint(WOOD_DARK), Vector3(0, top + 0.4, 0))
	pennant(root, Vector3(0, top + 0.85, 0), trim * dim)
	# Porta: cortinas puxadas para os lados e o interior aceso.
	var door := Node3D.new()
	root.add_child(door)
	door.position = Vector3(0, 0, radius * 0.98)
	box(door, Vector3(radius * 0.62, height * 0.8, 0.05), glow(Color("ffb35a") * dim, 1.6 * dim), Vector3(0, height * 0.4, -0.04))
	for side in [-1.0, 1.0]:
		cylinder(door, 0.05, radius * 0.17, height * 0.82, paint(a, 0.015), Vector3(side * radius * 0.36, height * 0.41, 0.04))
	box(door, Vector3(radius * 0.8, 0.16, 0.08), paint(trim * dim, 0.015), Vector3(0, height * 0.82, 0.08))
	contact_shadow(root, radius * 1.45)
	return root


static func pennant(parent: Node3D, at: Vector3, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3(0, 0.15, 0), Vector3(0.55, 0, 0), Vector3(0, -0.15, 0)]:
		st.add_vertex(v)
	for v in [Vector3(0, -0.15, 0), Vector3(0.55, 0, 0), Vector3(0, 0.15, 0)]:
		st.add_vertex(v)
	st.generate_normals()
	add(parent, st.commit(), paint(color), at)


## Poste de ferro com lanterna âmbar e luz (as luzes ficam nos postes do caminho).
static func lamp_post(parent: Node3D, at: Vector3, with_light := true) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	cylinder(root, 0.05, 0.08, 2.6, paint(Color("231b22"), 0.012), Vector3(0, 1.3, 0))
	cylinder(root, 0.16, 0.2, 0.12, paint(Color("231b22")), Vector3(0, 0.06, 0))
	box(root, Vector3(0.4, 0.05, 0.05), paint(Color("231b22")), Vector3(0.18, 2.5, 0))
	var lantern := Node3D.new()
	root.add_child(lantern)
	lantern.position = Vector3(0.36, 2.28, 0)
	box(lantern, Vector3(0.22, 0.3, 0.22), glow(Color("ffc46a"), 3.5), Vector3.ZERO)
	cylinder(lantern, 0.0, 0.18, 0.14, paint(Color("231b22"), 0.01), Vector3(0, 0.22, 0))
	cylinder(lantern, 0.13, 0.13, 0.04, paint(Color("231b22")), Vector3(0, -0.17, 0))
	if with_light:
		var light := OmniLight3D.new()
		light.light_color = LAMP
		light.light_energy = 2.4
		light.omni_range = 6.5
		light.omni_attenuation = 1.4
		light.position = lantern.position + Vector3(0, -0.1, 0)
		root.add_child(light)
	contact_shadow(root, 0.45)
	return root


## Carroção de circo (o Camarim): caixa pintada com frisos dourados, teto arredondado, rodas de
## raios, degraus atrás e a janelinha acesa.
static func wagon(parent: Node3D, color: Color) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	box(root, Vector3(3.0, 1.5, 1.6), paint(color, 0.025), Vector3(0, 1.3, 0))
	box(root, Vector3(3.1, 0.1, 1.7), paint(GOLD, 0.015), Vector3(0, 0.55, 0))
	box(root, Vector3(3.1, 0.1, 1.7), paint(GOLD, 0.015), Vector3(0, 2.05, 0))
	cylinder(root, 0.95, 0.95, 3.2, paint(Color("3a2a3a"), 0.025), Vector3(0, 2.05, 0), Vector3(0, 0, PI * 0.5), 20)
	# Losangos pintados e o letreiro de lado (frente para a câmera).
	for i in 3:
		box(root, Vector3(0.36, 0.36, 0.03), paint(GOLD), Vector3(-1.0 + i * 1.0, 1.3, 0.81), Vector3(0, 0, PI * 0.25))
	box(root, Vector3(0.5, 0.55, 0.04), glow(Color("ffc46a"), 2.0), Vector3(1.05, 1.45, -0.81))
	for x in [-1.05, 1.05]:
		for z in [-0.85, 0.85]:
			var wheel := Node3D.new()
			root.add_child(wheel)
			wheel.position = Vector3(x, 0.55, z)
			wheel.rotation.x = PI * 0.5
			torus(wheel, 0.42, 0.52, paint(Color("8a2a24"), 0.012), Vector3.ZERO)
			for k in 6:
				box(wheel, Vector3(0.05, 0.05, 0.9), paint(GOLD), Vector3.ZERO, Vector3(0, TAU * k / 12.0, 0))
			cylinder(wheel, 0.1, 0.1, 0.1, paint(GOLD, 0.01), Vector3.ZERO)
	for k in 3:
		box(root, Vector3(0.6, 0.08, 0.3), paint(WOOD), Vector3(-1.8 - 0.25 * k, 0.6 - 0.2 * k, 0))
	contact_shadow(root, 2.1)
	return root


## Barraca de vendedor (Curiosidades): balcão de madeira, toldo listrado inclinado com babado,
## prateleiras com potes e frascos coloridos, caixotes, lanternas penduradas e a placa no alto.
static func stall(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	for x in [-1.3, 1.3]:
		for z in [-0.8, 0.9]:
			cylinder(root, 0.07, 0.08, 2.6, paint(WOOD_DARK, 0.012), Vector3(x, 1.3, z))
	box(root, Vector3(2.8, 1.0, 0.5), paint(WOOD, 0.02), Vector3(0, 0.5, 0.8))
	box(root, Vector3(3.0, 0.1, 0.65), paint(Color("8a5a34"), 0.012), Vector3(0, 1.03, 0.8))
	box(root, Vector3(2.8, 2.4, 0.1), paint(Color("3a2420"), 0.02), Vector3(0, 1.2, -0.85))
	for y in [0.9, 1.5]:
		box(root, Vector3(2.4, 0.06, 0.35), paint(WOOD), Vector3(0, y, -0.65))
		for i in 7:
			var colors := [Color("6fb3a8"), Color("c8302c"), Color("e8b33a"), Color("7a4a9a"), Color("5a8a3a")]
			var c: Color = colors[(i + int(y * 10)) % colors.size()]
			if i % 2 == 0:
				cylinder(root, 0.09, 0.1, 0.28, paint(c, 0.008), Vector3(-1.0 + i * 0.33, y + 0.17, -0.62))
			else:
				sphere(root, Vector3(0.12, 0.14, 0.12), glow(c, 0.6), Vector3(-1.0 + i * 0.33, y + 0.17, -0.62))
	# Toldo listrado inclinado para a frente, com babado recortado.
	var awning := box(root, Vector3(3.3, 0.08, 2.2), stripes(Color("2e6b5a"), CREAM, 10.0, 0.02), Vector3(0, 2.75, 0.2), Vector3(0.28, 0, 0))
	awning.name = "Awning"
	for i in 10:
		sphere(root, Vector3(0.18, 0.14, 0.05), paint(Color("2e6b5a") if i % 2 == 0 else CREAM), Vector3(-1.5 + i * 0.333, 2.32, 1.3))
	for x in [-1.1, 1.1]:
		var lantern := Node3D.new()
		root.add_child(lantern)
		lantern.position = Vector3(x, 2.05, 1.15)
		sphere(lantern, Vector3(0.14, 0.18, 0.14), glow(Color("ffb347"), 3.0), Vector3.ZERO)
		cylinder(lantern, 0.008, 0.008, 0.35, paint(INK), Vector3(0, 0.3, 0))
	var light := OmniLight3D.new()
	light.light_color = LAMP
	light.light_energy = 2.6
	light.omni_range = 5.5
	light.position = Vector3(0, 2.0, 1.2)
	root.add_child(light)
	crate(root, Vector3(-1.9, 0, 0.9), 0.3)
	crate(root, Vector3(-2.0, 0.6, 0.9), -0.2, 0.45)
	barrel(root, Vector3(1.9, 0, 1.0))
	contact_shadow(root, 2.4)
	return root


static func crate(parent: Node3D, at: Vector3, yaw := 0.0, size := 0.6) -> void:
	var node := box(parent, Vector3(size, size, size), paint(Color("8a6238"), 0.012), at + Vector3(0, size * 0.5, 0), Vector3(0, yaw, 0))
	for k in [-1.0, 1.0]:
		box(node, Vector3(size * 1.02, size * 0.12, size * 1.02), paint(WOOD_DARK), Vector3(0, k * size * 0.3, 0))


static func barrel(parent: Node3D, at: Vector3) -> void:
	cylinder(parent, 0.3, 0.3, 0.8, paint(Color("7a5030"), 0.012), at + Vector3(0, 0.4, 0), Vector3.ZERO, 14)
	sphere(parent, Vector3(0.34, 0.25, 0.34), paint(Color("7a5030")), at + Vector3(0, 0.4, 0))
	for y in [0.15, 0.65]:
		torus(parent, 0.3, 0.34, paint(Color("3a3038")), at + Vector3(0, y, 0))


## Fardo de palha (com fiapos), às vezes em pilha.
static func haystack(parent: Node3D, at: Vector3, yaw := 0.0) -> void:
	var node := box(parent, Vector3(1.0, 0.55, 0.6), paint(Color("c9a24a"), 0.012), at + Vector3(0, 0.28, 0), Vector3(0, yaw, 0))
	for k in [-0.25, 0.25]:
		box(node, Vector3(0.05, 0.57, 0.62), paint(Color("7a5a2a")), Vector3(k, 0, 0))
	contact_shadow(parent, 0.7, at)


## Árvore seca torta, de galhos finos (o parque está abandonado).
static func dead_tree(parent: Node3D, at: Vector3, height := 3.5, seed_value := 1) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.rotation.y = rng.randf() * TAU
	var trunk_color := paint(Color("2a1e22"), 0.012)
	cylinder(root, 0.12, 0.22, height, trunk_color, Vector3(0, height * 0.5, 0), Vector3(0, 0, rng.randf_range(-0.1, 0.1)), 8)
	for i in 5:
		var y := height * rng.randf_range(0.45, 0.95)
		var length := rng.randf_range(0.8, 1.6)
		var yaw := rng.randf() * TAU
		var tilt := rng.randf_range(0.6, 1.1)
		var branch := Node3D.new()
		root.add_child(branch)
		branch.position = Vector3(0, y, 0)
		branch.rotation = Vector3(0, yaw, tilt)
		cylinder(branch, 0.02, 0.07, length, trunk_color, Vector3(0, length * 0.5, 0), Vector3.ZERO, 6)
	contact_shadow(root, 0.8)
	return root


## Cerca de estacas com corda caída entre elas, ao longo de pontos (x, y, z).
static func rope_fence(parent: Node3D, points: Array[Vector3]) -> void:
	var posts := MultiMesh.new()
	posts.transform_format = MultiMesh.TRANSFORM_3D
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.05
	post_mesh.bottom_radius = 0.06
	post_mesh.height = 1.0
	post_mesh.radial_segments = 8
	posts.mesh = post_mesh
	posts.instance_count = points.size()
	for i in points.size():
		posts.set_instance_transform(i, Transform3D(Basis(), points[i] + Vector3(0, 0.5, 0)))
	var post_node := MultiMeshInstance3D.new()
	post_node.multimesh = posts
	post_node.material_override = paint(Color("5a3a24"), 0.01)
	parent.add_child(post_node)
	var segments: Array[Transform3D] = []
	for i in points.size() - 1:
		var a := points[i] + Vector3(0, 0.82, 0)
		var b := points[i + 1] + Vector3(0, 0.82, 0)
		var steps := 6
		for k in steps:
			var t0 := float(k) / steps
			var t1 := float(k + 1) / steps
			var p0 := a.lerp(b, t0) - Vector3(0, 0.22 * 4.0 * t0 * (1.0 - t0), 0)
			var p1 := a.lerp(b, t1) - Vector3(0, 0.22 * 4.0 * t1 * (1.0 - t1), 0)
			segments.append(_segment(p0, p1, 0.022))
	_multi(parent, segments, CylinderMesh.new(), paint(Color("c8a878")))


## Varal de bandeirolas entre dois pontos, triângulos coloridos alternados.
static func bunting(parent: Node3D, a: Vector3, b: Vector3, sag := 0.6) -> void:
	var colors := [Color("c8302c"), CREAM, Color("e8b33a"), Color("2e6b5a"), Color("7a4a9a")]
	var count := int(a.distance_to(b) / 0.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dir := (b - a).normalized()
	for i in count:
		var t := (i + 0.5) / count
		var p := a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		var c: Color = colors[i % colors.size()]
		st.set_color(c)
		var l := p - dir * 0.17
		var r := p + dir * 0.17
		var tip := p + Vector3(0, -0.4, 0)
		st.add_vertex(l); st.add_vertex(r); st.add_vertex(tip)
		st.add_vertex(r); st.add_vertex(l); st.add_vertex(tip)
	st.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.roughness = 0.9
	add(parent, st.commit(), material, Vector3.ZERO)
	var segments: Array[Transform3D] = []
	for k in 16:
		var t0 := k / 16.0
		var t1 := (k + 1) / 16.0
		segments.append(_segment(a.lerp(b, t0) - Vector3(0, sag * 4.0 * t0 * (1.0 - t0), 0),
				a.lerp(b, t1) - Vector3(0, sag * 4.0 * t1 * (1.0 - t1), 0), 0.012))
	_multi(parent, segments, CylinderMesh.new(), paint(INK))


## Mastro alto de madeira (para os varais).
static func pole(parent: Node3D, at: Vector3, height := 4.2) -> void:
	cylinder(parent, 0.06, 0.09, height, paint(WOOD_DARK, 0.012), at + Vector3(0, height * 0.5, 0), Vector3.ZERO, 8)
	sphere(parent, Vector3(0.11, 0.11, 0.11), paint(GOLD, 0.01), at + Vector3(0, height + 0.05, 0))


## Arco de entrada com lâmpadas e letreiro (o letreiro é um Label3D posto por quem chama).
static func arch(parent: Node3D, at: Vector3, width := 4.4, height := 3.6) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	for side in [-1.0, 1.0]:
		box(root, Vector3(0.3, height, 0.3), paint(Color("8a2a24"), 0.02), Vector3(side * width * 0.5, height * 0.5, 0))
		sphere(root, Vector3(0.22, 0.22, 0.22), paint(GOLD, 0.012), Vector3(side * width * 0.5, height + 0.1, 0))
	var segments := 14
	for i in segments + 1:
		var t := float(i) / segments
		var x := lerpf(-width * 0.5, width * 0.5, t)
		var y := height + 0.6 * sin(PI * t)
		sphere(root, Vector3(0.09, 0.09, 0.09), glow(Color("ffd27a"), 4.0), Vector3(x, y + 0.12, 0.17))
		if i < segments:
			var x1 := lerpf(-width * 0.5, width * 0.5, t + 1.0 / segments)
			var y1 := height + 0.6 * sin(PI * (t + 1.0 / segments))
			var seg := _segment(Vector3(x, y, 0), Vector3(x1, y1, 0), 0.16)
			var node := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.radial_segments = 8
			node.mesh = mesh
			node.transform = seg
			node.material_override = paint(Color("8a2a24"), 0.015)
			root.add_child(node)
	return root


## Jaula de circo sobre rodas (perto do Domador): grades, teto e um par de olhos brilhando no escuro.
static func cage(parent: Node3D, at: Vector3, yaw := 0.0) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.rotation.y = yaw
	box(root, Vector3(2.4, 0.25, 1.4), paint(Color("8a2a24"), 0.02), Vector3(0, 0.6, 0))
	box(root, Vector3(2.5, 0.2, 1.5), paint(Color("8a2a24"), 0.02), Vector3(0, 2.4, 0))
	box(root, Vector3(2.3, 1.6, 1.3), paint(Color("120c12")), Vector3(0, 1.5, 0))
	for i in 9:
		for side in [-1.0, 1.0]:
			cylinder(root, 0.03, 0.03, 1.7, paint(GOLD, 0.008), Vector3(-1.1 + i * 0.275, 1.5, side * 0.68), Vector3.ZERO, 6)
	for side in [-1.0, 1.0]:
		sphere(root, Vector3(0.06, 0.04, 0.03), glow(Color("ffe060"), 5.0), Vector3(0.3 + side * 0.13, 1.6, 0.66))
	for x in [-0.8, 0.8]:
		for z in [-0.7, 0.7]:
			var wheel := Node3D.new()
			root.add_child(wheel)
			wheel.position = Vector3(x, 0.38, z)
			wheel.rotation.x = PI * 0.5
			torus(wheel, 0.26, 0.36, paint(GOLD, 0.01), Vector3.ZERO)
	contact_shadow(root, 1.6)


## Pino de malabares gigante fincado no chão.
static func juggling_pin(parent: Node3D, at: Vector3, color: Color, tilt := 0.0) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.rotation.z = tilt
	sphere(root, Vector3(0.36, 0.7, 0.36), paint(CREAM, 0.015), Vector3(0, 0.7, 0))
	cylinder(root, 0.12, 0.2, 0.9, paint(CREAM, 0.012), Vector3(0, 1.6, 0))
	sphere(root, Vector3(0.18, 0.18, 0.18), paint(color, 0.012), Vector3(0, 2.1, 0))
	torus(root, 0.25, 0.33, paint(color), Vector3(0, 0.95, 0))
	contact_shadow(root, 0.5)


## Estação do trem: plataforma de tábuas com faixa amarela na beira, cobertura de duas águas listrada
## de verde e creme com babado, relógio pendurado, banco, malas e lampiões; trilhos que somem para o
## leste com a locomotiva (faixas douradas, limpa-trilhos, fumaça) e um vagão de passageiros.
static func station(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	var green := Color("2e6b4a")
	box(root, Vector3(4.6, 0.35, 1.8), paint(WOOD, 0.02), Vector3(0, 0.17, 0))
	for i in 7:
		box(root, Vector3(0.03, 0.02, 1.78), paint(WOOD_DARK), Vector3(-2.0 + i * 0.66, 0.355, 0))
	box(root, Vector3(4.6, 0.025, 0.12), paint(GOLD), Vector3(0, 0.36, 0.82))
	# Cobertura: quatro colunas finas e telhado de duas águas, com babado na frente.
	var canopy := Node3D.new()
	canopy.name = "Canopy"
	root.add_child(canopy)
	canopy.position = Vector3(0, 0, -0.2)
	for x in [-1.9, 1.9]:
		for z in [-0.55, 0.45]:
			cylinder(canopy, 0.06, 0.07, 2.3, paint(green.darkened(0.3), 0.012), Vector3(x, 1.5, z), Vector3.ZERO, 8)
	var roof := stripes(green, CREAM, 14.0, 0.02)
	box(canopy, Vector3(4.5, 0.08, 0.95), roof, Vector3(0, 2.92, 0.36), Vector3(0.42, 0, 0))
	box(canopy, Vector3(4.5, 0.08, 0.95), roof, Vector3(0, 2.92, -0.46), Vector3(-0.42, 0, 0))
	box(canopy, Vector3(4.6, 0.1, 0.1), paint(GOLD, 0.01), Vector3(0, 3.12, -0.05))
	for i in 15:
		sphere(canopy, Vector3(0.15, 0.12, 0.04), paint(green if i % 2 == 0 else CREAM), Vector3(-2.1 + i * 0.3, 2.62, 0.8))
	# Relógio pendurado embaixo da cumeeira.
	var clock := Node3D.new()
	canopy.add_child(clock)
	clock.position = Vector3(0, 2.35, 0.2)
	cylinder(clock, 0.02, 0.02, 0.3, paint(INK), Vector3(0, 0.3, 0))
	cylinder(clock, 0.24, 0.24, 0.08, paint(GOLD, 0.01), Vector3.ZERO, Vector3(PI * 0.5, 0, 0), 20)
	cylinder(clock, 0.2, 0.2, 0.09, glow(Color("fff2c8"), 0.8), Vector3.ZERO, Vector3(PI * 0.5, 0, 0), 20)
	box(clock, Vector3(0.02, 0.15, 0.02), paint(INK), Vector3(0, 0.06, 0.06))
	box(clock, Vector3(0.11, 0.02, 0.02), paint(INK), Vector3(0.05, 0, 0.06))
	# Banco, malas e lampiões nas colunas da frente.
	box(root, Vector3(1.2, 0.07, 0.36), paint(Color("7a2a24"), 0.012), Vector3(-0.9, 0.78, -0.5))
	box(root, Vector3(1.2, 0.4, 0.06), paint(Color("7a2a24"), 0.012), Vector3(-0.9, 1.05, -0.68))
	for x in [-1.4, -0.4]:
		box(root, Vector3(0.06, 0.42, 0.3), paint(INK), Vector3(x, 0.56, -0.5))
	var suitcase := box(root, Vector3(0.6, 0.38, 0.22), paint(Color("8a5a2a"), 0.012), Vector3(1.0, 0.54, -0.4), Vector3(0, 0.3, 0))
	box(suitcase, Vector3(0.62, 0.05, 0.24), paint(Color("5a3a1a")), Vector3(0, 0.08, 0))
	box(root, Vector3(0.42, 0.28, 0.18), paint(Color("2e5c8a"), 0.012), Vector3(1.05, 0.87, -0.42), Vector3(0, -0.2, 0))
	for x in [-1.9, 1.9]:
		box(canopy, Vector3(0.16, 0.22, 0.16), glow(Color("ffc46a"), 3.0), Vector3(x, 2.0, 0.6))
	# Trilhos: dormentes e dois trilhos, da frente da plataforma até fora do mapa.
	var sleepers: Array[Transform3D] = []
	for i in 30:
		sleepers.append(Transform3D(Basis(), Vector3(-3.0 + i * 0.6, 0.05, 1.7)))
	var sleeper_mesh := BoxMesh.new()
	sleeper_mesh.size = Vector3(0.22, 0.08, 1.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sleeper_mesh
	mm.instance_count = sleepers.size()
	for i in sleepers.size():
		mm.set_instance_transform(i, sleepers[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = paint(WOOD_DARK)
	root.add_child(node)
	for z in [1.25, 2.15]:
		box(root, Vector3(18.0, 0.08, 0.08), paint(Color("6a6870"), 0.01), Vector3(5.7, 0.13, z))
	# Locomotiva: caldeira com faixas douradas, cabine, chaminé com fumaça, limpa-trilhos e rodas.
	var loco := Node3D.new()
	loco.name = "Train"
	root.add_child(loco)
	loco.position = Vector3(3.6, 0.2, 1.7)
	cylinder(loco, 0.5, 0.5, 2.0, paint(Color("2a2a34"), 0.02), Vector3(-0.2, 0.95, 0), Vector3(0, 0, PI * 0.5), 18)
	for x in [-0.9, -0.2, 0.5]:
		cylinder(loco, 0.52, 0.52, 0.08, paint(GOLD, 0.01), Vector3(x, 0.95, 0), Vector3(0, 0, PI * 0.5), 18)
	box(loco, Vector3(1.0, 1.4, 1.2), paint(Color("8a2a24"), 0.02), Vector3(1.3, 1.2, 0))
	box(loco, Vector3(1.2, 0.12, 1.4), paint(Color("2a2a34"), 0.015), Vector3(1.3, 1.95, 0))
	cylinder(loco, 0.22, 0.14, 0.7, paint(Color("2a2a34"), 0.015), Vector3(-0.9, 1.7, 0))
	cylinder(loco, 0.26, 0.26, 0.08, paint(GOLD, 0.01), Vector3(-0.9, 2.05, 0))
	for k in 3:
		sphere(loco, Vector3.ONE * (0.2 + k * 0.08), paint(Color("c8c0cc"), 0.01), Vector3(-0.9 - k * 0.15, 2.3 + k * 0.32, -k * 0.1))
	box(loco, Vector3(0.4, 0.4, 0.05), glow(Color("ffc46a"), 2.5), Vector3(1.3, 1.35, 0.62))
	sphere(loco, Vector3(0.16, 0.16, 0.08), glow(Color("fff2c0"), 5.0), Vector3(-1.25, 1.0, 0))
	box(loco, Vector3(0.4, 0.35, 1.0), paint(Color("a3282a"), 0.012), Vector3(-1.3, 0.32, 0), Vector3(0, 0, -0.6))
	for x in [-0.7, 0.0, 0.8]:
		for z in [-0.55, 0.55]:
			var wheel := Node3D.new()
			loco.add_child(wheel)
			wheel.position = Vector3(x, 0.38, z)
			wheel.rotation.x = PI * 0.5
			cylinder(wheel, 0.36, 0.36, 0.1, paint(Color("a3282a"), 0.012), Vector3.ZERO, Vector3.ZERO, 16)
	# Vagão de passageiros atrás da locomotiva, listrado, com janelas acesas.
	var car := Node3D.new()
	loco.add_child(car)
	car.position = Vector3(3.0, 0.0, 0.0)
	box(car, Vector3(2.4, 1.1, 1.1), stripes(Color("6a2a6a"), CREAM, 10.0, 0.02), Vector3(0, 1.05, 0))
	box(car, Vector3(2.6, 0.12, 1.3), paint(Color("2a2a34"), 0.015), Vector3(0, 1.66, 0))
	for x in [-0.7, 0.0, 0.7]:
		box(car, Vector3(0.4, 0.36, 0.04), glow(Color("ffc46a"), 2.0), Vector3(x, 1.15, 0.56))
	for x in [-0.8, 0.8]:
		for z in [-0.5, 0.5]:
			var wheel := Node3D.new()
			car.add_child(wheel)
			wheel.position = Vector3(x, 0.3, z)
			wheel.rotation.x = PI * 0.5
			cylinder(wheel, 0.28, 0.28, 0.1, paint(Color("a3282a"), 0.012), Vector3.ZERO, Vector3.ZERO, 16)
	contact_shadow(root, 2.6)
	return root


## Cartola gigante de mágico com orelhas de coelho saindo (marco da tenda do Mágico).
static func magic_hat(parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.rotation.z = 0.25
	cylinder(root, 0.95, 0.95, 0.12, paint(Color("1d1a22"), 0.02), Vector3(0, 0.06, 0), Vector3.ZERO, 24)
	cylinder(root, 0.6, 0.62, 1.3, paint(Color("1d1a22"), 0.02), Vector3(0, 0.7, 0), Vector3.ZERO, 24)
	cylinder(root, 0.63, 0.63, 0.25, paint(Color("a3282a")), Vector3(0, 0.25, 0), Vector3.ZERO, 24)
	for side in [-1.0, 1.0]:
		sphere(root, Vector3(0.12, 0.42, 0.06), paint(Color("f4f0ea"), 0.012), Vector3(side * 0.18, 1.55, 0.1))
	contact_shadow(root, 1.1)


static func _segment(a: Vector3, b: Vector3, radius: float) -> Transform3D:
	var up := (b - a).normalized()
	var basis := Basis()
	if absf(up.dot(Vector3.UP)) < 0.999:
		var axis := Vector3.UP.cross(up).normalized()
		basis = Basis(axis, Vector3.UP.angle_to(up))
	elif up.y < 0.0:
		basis = Basis(Vector3.RIGHT, PI)
	basis = basis * Basis.from_scale(Vector3(radius, a.distance_to(b), radius))
	return Transform3D(basis, (a + b) * 0.5)


static func _multi(parent: Node3D, transforms: Array[Transform3D], mesh: Mesh, material: Material) -> void:
	if mesh is CylinderMesh:
		mesh.top_radius = 1.0
		mesh.bottom_radius = 1.0
		mesh.height = 1.0
		mesh.radial_segments = 6
		mesh.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	parent.add_child(node)


## Cerca de madeira rústica: mourões com a ponta arredondada e duas travessas, ao longo de pontos.
## Um mourão a cada `lantern_every` ganha uma lanterninha acesa (sem luz própria).
static func wood_fence(parent: Node3D, points: Array[Vector3], lantern_every := 0) -> void:
	var posts: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var rails: Array[Transform3D] = []
	for i in points.size():
		var p := points[i]
		posts.append(Transform3D(Basis.from_scale(Vector3(0.09, 1.0, 0.09)), p + Vector3(0, 0.5, 0)))
		caps.append(Transform3D(Basis.from_scale(Vector3(0.11, 0.08, 0.11)), p + Vector3(0, 1.02, 0)))
		if lantern_every > 0 and i % lantern_every == 0:
			box(parent, Vector3(0.14, 0.18, 0.14), glow(Color("ffc46a"), 3.0), p + Vector3(0, 1.16, 0))
		if i < points.size() - 1:
			var q := points[i + 1]
			for h in [0.42, 0.8]:
				rails.append(_beam(p + Vector3(0, h, 0), q + Vector3(0, h - 0.03, 0), Vector2(0.07, 0.1)))
	var post_mesh := CylinderMesh.new()
	post_mesh.radial_segments = 6
	_multi(parent, posts, post_mesh, paint(Color("6a4528"), 0.012))
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 1.0
	cap_mesh.height = 2.0
	cap_mesh.radial_segments = 8
	cap_mesh.rings = 4
	var mm_caps := caps
	_multi_mesh(parent, mm_caps, cap_mesh, paint(Color("5a3a22"), 0.01))
	_multi_mesh(parent, rails, BoxMesh.new(), paint(Color("7a5230"), 0.012))


## Árvore de copa redonda em cachos (verde-oliva escuro de noite), tronco torto.
static func leafy_tree(parent: Node3D, at: Vector3, height := 3.2, seed_value := 1) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	cylinder(root, 0.12, 0.22, height * 0.6, paint(Color("3a2a22"), 0.012), Vector3(0, height * 0.3, 0), Vector3(0, 0, rng.randf_range(-0.12, 0.12)), 8)
	var greens := [Color("2e3f24"), Color("37492a"), Color("2a3a2e")]
	for i in 6:
		var a := TAU * i / 6.0 + rng.randf() * 0.5
		var r := rng.randf_range(0.6, 0.95)
		var spot := Vector3(sin(a) * r * 0.8, height * 0.65 + rng.randf_range(-0.2, 0.5), cos(a) * r * 0.7)
		sphere(root, Vector3.ONE * r, paint(greens[i % 3], 0.02), spot)
	sphere(root, Vector3.ONE * 1.0, paint(greens[1], 0.02), Vector3(0, height * 0.9, 0))
	contact_shadow(root, 1.4, Vector3.ZERO, 0.5)
	return root


## Arbusto baixo (três bolas), para assentar as bordas.
static func bush(parent: Node3D, at: Vector3, size := 0.5) -> void:
	for k in 3:
		sphere(parent, Vector3(size, size * 0.8, size), paint(Color("33452a"), 0.015),
				at + Vector3((k - 1) * size * 0.8, size * 0.6, (k % 2) * size * 0.3))


## Portão em forma de cabeça de leão (a entrada do Domador): juba em camadas de chumaços laranja e
## castanhos, cara clara, olhos, nariz, sobrancelhas bravas, e a boca aberta com presas é a passagem.
static func lion_gate(parent: Node3D, at: Vector3, size := 1.6) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	var s := size
	var center := Vector3(0, s * 1.25, 0)
	for ring in 3:
		var count := 14 + ring * 4
		var rr := s * (1.15 + ring * 0.22)
		var color: Color = [Color("c8742c"), Color("a85a24"), Color("7a3a1c")][ring]
		for i in count:
			var a := TAU * (i + 0.5 * ring) / count
			sphere(root, Vector3(s * 0.32, s * 0.32, s * 0.22), paint(color, 0.015),
					center + Vector3(sin(a) * rr, cos(a) * rr * 0.95, -0.15 * ring))
	sphere(root, Vector3(s * 1.05, s * 1.0, s * 0.45), paint(Color("e8b070"), 0.02), center)
	for side in [-1.0, 1.0]:
		sphere(root, Vector3(s * 0.2, s * 0.24, s * 0.1), paint(Color("fbfaf4")), center + Vector3(side * s * 0.38, s * 0.32, s * 0.36))
		sphere(root, Vector3(s * 0.1, s * 0.15, s * 0.06), paint(INK), center + Vector3(side * s * 0.34, s * 0.3, s * 0.43))
		box(root, Vector3(s * 0.4, s * 0.07, s * 0.08), paint(Color("6a3018")), center + Vector3(side * s * 0.36, s * 0.6, s * 0.4), Vector3(0, 0, side * 0.35))
	sphere(root, Vector3(s * 0.28, s * 0.18, s * 0.16), paint(Color("5a2a1a"), 0.012), center + Vector3(0, s * 0.02, s * 0.5))
	# Boca aberta (a passagem): o escuro, a língua e quatro presas.
	sphere(root, Vector3(s * 0.62, s * 0.62, s * 0.2), glow(Color("ff9a40"), 1.2), center + Vector3(0, -s * 0.62, s * 0.36))
	box(root, Vector3(s * 1.0, s * 0.9, s * 0.3), glow(Color("ffb35a"), 1.4), Vector3(0, s * 0.45, s * 0.25))
	for side in [-1.0, 1.0]:
		for k in 2:
			cylinder(root, 0.0, s * 0.08, s * 0.3, paint(Color("fbfaf4"), 0.01),
					center + Vector3(side * s * (0.2 + 0.2 * k), -s * 0.22, s * 0.48), Vector3(PI, 0, 0), 6)
		box(root, Vector3(s * 0.3, s * 1.3, s * 0.5), paint(Color("8a2a24"), 0.02), Vector3(side * s * 0.66, s * 0.65, s * 0.2))
	contact_shadow(root, s * 1.8)
	return root


static func _beam(a: Vector3, b: Vector3, size: Vector2) -> Transform3D:
	var dir := b - a
	var yaw := atan2(dir.x, dir.z)
	var pitch := -atan2(dir.y, Vector2(dir.x, dir.z).length())
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis.from_scale(Vector3(size.x, size.y, dir.length()))
	return Transform3D(basis, (a + b) * 0.5)


static func _multi_mesh(parent: Node3D, transforms: Array[Transform3D], mesh: Mesh, material: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	parent.add_child(node)


## Carroção-loja (Curiosidades): carroção de madeira azul-petróleo com frisos dourados, a lateral da
## frente aberta como balcão, toldo listrado vermelho e creme com babado, prateleiras com frascos que
## brilham, gramofone, bola de cristal, brasão com estrela no alto, rodas grandes e lanternas.
static func shop_wagon(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var body := Color("2a4a4a")
	var trim := GOLD
	# Caixa do carroção (fundo e laterais), piso e teto.
	box(root, Vector3(3.4, 2.0, 0.12), paint(body, 0.02), Vector3(0, 1.75, -0.9))
	for x in [-1.64, 1.64]:
		box(root, Vector3(0.12, 2.0, 1.9), paint(body, 0.02), Vector3(x, 1.75, 0))
	box(root, Vector3(3.5, 0.14, 2.0), paint(Color("5a3a24"), 0.02), Vector3(0, 0.72, 0))
	box(root, Vector3(3.6, 0.16, 2.1), paint(body.darkened(0.2), 0.02), Vector3(0, 2.82, -0.05))
	# Teto visto de cima: friso dourado na volta, carga amarrada (caixotes e uma lona enrolada).
	for z in [-1.08, 0.98]:
		box(root, Vector3(3.66, 0.08, 0.08), paint(trim), Vector3(0, 2.92, z))
	for x in [-1.78, 1.78]:
		box(root, Vector3(0.08, 0.08, 2.12), paint(trim), Vector3(x, 2.92, -0.05))
	crate(root, Vector3(1.1, 2.9, -0.55), 0.3, 0.45)
	crate(root, Vector3(0.6, 2.9, -0.6), -0.2, 0.35)
	cylinder(root, 0.16, 0.16, 1.3, paint(Color("b8a07a"), 0.012), Vector3(-0.9, 3.06, -0.55), Vector3(0, 0, PI * 0.5), 12)
	for x in [-1.3, -0.5]:
		cylinder(root, 0.17, 0.17, 0.05, paint(Color("5a3a1a")), Vector3(x, 3.06, -0.55), Vector3(0, 0, PI * 0.5), 12)
	# Interior aceso.
	box(root, Vector3(3.2, 1.9, 0.05), glow(Color("6a3a20"), 0.6), Vector3(0, 1.75, -0.82))
	# Balcão com frente pintada e losangos dourados.
	box(root, Vector3(3.3, 0.7, 0.4), paint(Color("7a2a24"), 0.02), Vector3(0, 1.15, 0.85))
	box(root, Vector3(3.45, 0.08, 0.55), paint(Color("8a5a34"), 0.015), Vector3(0, 1.52, 0.85))
	for i in 4:
		box(root, Vector3(0.24, 0.24, 0.03), paint(trim), Vector3(-1.2 + i * 0.8, 1.15, 1.06), Vector3(0, 0, PI * 0.25))
	# Prateleiras com frascos, potes e a bola de cristal.
	var goods := [Color("6fb3a8"), Color("c8302c"), Color("e8b33a"), Color("9a6ad0"), Color("5a8a3a"), Color("e07a40")]
	for row in 2:
		var y := 1.75 + row * 0.5
		box(root, Vector3(3.0, 0.06, 0.3), paint(WOOD), Vector3(0, y, -0.68))
		for i in 8:
			var c: Color = goods[(i + row * 3) % goods.size()]
			var x := -1.3 + i * 0.37
			if (i + row) % 3 == 0:
				sphere(root, Vector3(0.1, 0.13, 0.1), glow(c, 0.9), Vector3(x, y + 0.16, -0.66))
			else:
				cylinder(root, 0.07, 0.09, 0.22 + 0.06 * ((i + row) % 2), paint(c, 0.008), Vector3(x, y + 0.14, -0.66))
	sphere(root, Vector3(0.16, 0.16, 0.16), glow(Color("b8a8ff"), 1.6), Vector3(-0.9, 1.74, 0.82))
	cylinder(root, 0.08, 0.12, 0.08, paint(GOLD), Vector3(-0.9, 1.58, 0.82))
	# Gramofone no balcão.
	box(root, Vector3(0.3, 0.16, 0.3), paint(Color("5a3020"), 0.01), Vector3(0.9, 1.64, 0.82))
	var horn := cylinder(root, 0.25, 0.03, 0.5, paint(GOLD, 0.01), Vector3(1.0, 1.95, 0.9), Vector3(-0.6, 0, -0.5))
	horn.name = "Horn"
	# Toldo listrado inclinado para a frente, com babado recortado.
	box(root, Vector3(3.7, 0.08, 1.4), stripes(Color("b3282a"), CREAM, 12.0, 0.02), Vector3(0, 2.62, 1.45), Vector3(0.35, 0, 0))
	for i in 12:
		sphere(root, Vector3(0.16, 0.13, 0.05), paint(Color("b3282a") if i % 2 == 0 else CREAM), Vector3(-1.7 + i * 0.31, 2.27, 2.12))
	# Brasão no alto com a estrela.
	var crest := box(root, Vector3(1.5, 0.6, 0.1), paint(body.darkened(0.1), 0.02), Vector3(0, 3.2, 0.2))
	torus(crest, 0.18, 0.24, paint(trim, 0.01), Vector3(0, 0, 0.06), Vector3(PI * 0.5, 0, 0))
	cylinder(crest, 0.17, 0.17, 0.04, paint(Color("b3282a")), Vector3(0, 0, 0.06), Vector3(PI * 0.5, 0, 0))
	for side in [-1.0, 1.0]:
		sphere(crest, Vector3(0.18, 0.18, 0.06), paint(trim, 0.01), Vector3(side * 0.72, 0.15, 0.04))
	# Rodas grandes de raios.
	for x in [-1.25, 1.25]:
		for z in [-1.0, 1.0]:
			var wheel := Node3D.new()
			root.add_child(wheel)
			wheel.position = Vector3(x, 0.55, z)
			wheel.rotation.x = PI * 0.5
			torus(wheel, 0.44, 0.55, paint(Color("6a3a20"), 0.012), Vector3.ZERO)
			for k in 6:
				box(wheel, Vector3(0.05, 0.05, 0.95), paint(GOLD), Vector3.ZERO, Vector3(0, TAU * k / 12.0, 0))
	# Lanternas penduradas nas pontas do toldo e a luz da loja.
	for x in [-1.75, 1.75]:
		var lantern := Node3D.new()
		root.add_child(lantern)
		lantern.position = Vector3(x, 2.0, 2.0)
		box(lantern, Vector3(0.2, 0.28, 0.2), glow(Color("ffc46a"), 3.5), Vector3.ZERO)
		cylinder(lantern, 0.0, 0.16, 0.12, paint(INK), Vector3(0, 0.2, 0))
	var light := OmniLight3D.new()
	light.light_color = LAMP
	light.light_energy = 2.8
	light.omni_range = 6.0
	light.position = Vector3(0, 2.0, 1.4)
	root.add_child(light)
	barrel(root, Vector3(2.2, 0, 1.0))
	crate(root, Vector3(-2.3, 0, 0.9), 0.3)
	crate(root, Vector3(-2.35, 0.6, 0.9), -0.2, 0.45)
	contact_shadow(root, 2.6)
	return root


## Carroção do Camarim: caixa roxa com frisos dourados e teto arredondado, a porta aberta com cortina
## vermelha, um espelho de camarim com lâmpadas acesas do lado, degraus, tapete e um baú.
static func dressing_wagon(parent: Node3D, color: Color) -> Node3D:
	var root := wagon(parent, color)
	box(root, Vector3(0.8, 1.2, 0.06), glow(Color("ffb35a"), 1.2), Vector3(-0.6, 1.25, 0.82))
	for side in [-1.0, 1.0]:
		cylinder(root, 0.04, 0.16, 1.2, paint(Color("a3282a"), 0.012), Vector3(-0.6 + side * 0.32, 1.25, 0.86))
	box(root, Vector3(0.95, 0.1, 0.1), paint(GOLD, 0.01), Vector3(-0.6, 1.9, 0.86))
	# Espelho com lâmpadas.
	box(root, Vector3(0.7, 0.8, 0.05), paint(Color("c8d4e0")), Vector3(0.75, 1.35, 0.84))
	for i in 10:
		var a := TAU * i / 10.0
		sphere(root, Vector3(0.05, 0.05, 0.05), glow(Color("ffe0a0"), 4.0), Vector3(0.75 + sin(a) * 0.42, 1.35 + cos(a) * 0.48, 0.88))
	# Tapete e baú na frente.
	box(root, Vector3(1.2, 0.02, 0.8), paint(Color("7a2a3a")), Vector3(-0.6, 0.02, 1.35))
	var trunk := box(root, Vector3(0.8, 0.5, 0.5), paint(Color("8a2a24"), 0.015), Vector3(1.6, 0.25, 1.25), Vector3(0, -0.3, 0))
	box(trunk, Vector3(0.84, 0.06, 0.54), paint(GOLD), Vector3(0, 0.15, 0))
	_star_on(trunk, Vector3(0, 0, 0.26))
	return root


static func _star_on(parent: Node3D, at: Vector3) -> void:
	sphere(parent, Vector3(0.08, 0.08, 0.02), paint(GOLD), at)


## Versão meio transparente de um material (para peças que ficam na frente da dupla).
static func ghost(material: Material) -> Material:
	var key := "ghost%d" % material.get_instance_id()
	if _mats.has(key):
		return _mats[key]
	var color := Color(0.6, 0.5, 0.45)
	if material is ShaderMaterial:
		var value: Variant = material.get_shader_parameter("albedo")
		if value == null:
			value = material.get_shader_parameter("color_a")
		if value is Color:
			color = value
	elif material is StandardMaterial3D:
		color = material.albedo_color
	var ghost_material := StandardMaterial3D.new()
	ghost_material.albedo_color = Color(color, 0.35)
	# Com pré-passo de profundidade as bolas da copa não se somam umas sobre as outras, e o tom toon
	# mantém o volume (sem virar um disco chapado).
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	ghost_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	ghost_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	ghost_material.cull_mode = BaseMaterial3D.CULL_BACK
	_mats[key] = ghost_material
	return ghost_material


## Varal de lâmpadas (piloto 3D, 04/10/2026): fio caído de `a` a `b` com lâmpadas âmbar acesas (uma MultiMesh
## só) e, se `lights` > 0, essa quantidade de luzes de verdade espalhadas pelo meio do fio (iluminam o chão e o
## rosto de quem passa por baixo).
static func festoon(parent: Node3D, a: Vector3, b: Vector3, sag := 0.5, spacing := 0.45, lights := 1) -> void:
	var count := maxi(int(a.distance_to(b) / spacing), 2)
	var wire: Array[Transform3D] = []
	var bulbs: Array[Transform3D] = []
	for k in count:
		var t0 := float(k) / count
		var t1 := float(k + 1) / count
		var p0 := a.lerp(b, t0) - Vector3(0, sag * 4.0 * t0 * (1.0 - t0), 0)
		var p1 := a.lerp(b, t1) - Vector3(0, sag * 4.0 * t1 * (1.0 - t1), 0)
		wire.append(_segment(p0, p1, 0.01))
		var mid := (p0 + p1) * 0.5 - Vector3(0, 0.07, 0)
		bulbs.append(Transform3D(Basis.from_scale(Vector3(0.055, 0.075, 0.055)), mid))
	_multi(parent, wire, CylinderMesh.new(), paint(INK))
	var bulb := SphereMesh.new()
	bulb.radius = 1.0
	bulb.height = 2.0
	bulb.radial_segments = 8
	bulb.rings = 4
	_multi_mesh(parent, bulbs, bulb, glow(Color("ffcf7a"), 4.0))
	for k in lights:
		var t := (k + 1.0) / (lights + 1.0)
		var light := OmniLight3D.new()
		light.light_color = LAMP
		light.light_energy = 1.6
		light.omni_range = 4.5
		light.omni_attenuation = 1.3
		light.position = a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t) + 0.25, 0)
		parent.add_child(light)


## Muitas cópias de uma malha pequena (pedras, capim, flores) numa MultiMesh só, pintada de uma cor.
static func scatter(parent: Node3D, transforms: Array[Transform3D], mesh: Mesh, color: Color, outline := 0.0) -> void:
	if transforms.is_empty():
		return
	_multi_mesh(parent, transforms, mesh, paint(color, outline))
