class_name WorldTerrain
extends Node3D
## Terreno do diorama: chão com relevo suave (morrinhos), bordas que sobem como a beira de uma
## maquete, e trilhas de tábuas que seguem curvas (splines) entre os pontos do roteiro. O chão é
## achatado embaixo das trilhas e nos pátios das atrações. Tem colisão (os personagens andam por cima).
## A cor varia por vértice: terra batida, palha perto das trilhas e escuro nos cantos e nas bases.

const GROUND_SHADER := preload("res://shaders/world_ground.gdshader")
## Textura da terra batida (Pedido T1 do Codex, normalizada para 1024 e com a média acertada), 4 m por repetição.
const DIRT_ALBEDO := preload("res://core/world/art/dirt_albedo.png")
## Textura da grama baixa (Pedido T2 do Codex), 4 m por repetição.
const GRASS_ALBEDO := preload("res://core/world/art/grass_albedo.png")

@export var size := Vector2(46, 30)
@export var cells := Vector2i(92, 60)
@export var path_width := 2.3
## Falso: só o chão com colisão, sem desenho (o mapa usa o parque renderizado no Blender).
@export var draw := true

## Trilhas: cada uma é uma lista de pontos (x, z) por onde a curva passa.
var paths: Array[PackedVector2Array] = []
## Pátios planos: [centro (x, z), raio].
var pads: Array = []
var _samples: Array[PackedVector2Array] = []
var _grid := PackedFloat32Array()


## Altura do chão em (x, z), lida da grade já calculada (rápido; vale depois de build()).
func height_at(x: float, z: float) -> float:
	if _grid.is_empty():
		return _raw_height(x, z)
	var fx := clampf((x + size.x * 0.5) / size.x * cells.x, 0.0, cells.x - 0.001)
	var fz := clampf((z + size.y * 0.5) / size.y * cells.y, 0.0, cells.y - 0.001)
	var i := int(fx)
	var j := int(fz)
	var u := fx - i
	var v := fz - j
	var w := cells.x + 1
	var h0 := lerpf(_grid[j * w + i], _grid[j * w + i + 1], u)
	var h1 := lerpf(_grid[(j + 1) * w + i], _grid[(j + 1) * w + i + 1], u)
	return lerpf(h0, h1, v)


func _raw_height(x: float, z: float) -> float:
	var base := 0.25 * sin(x * 0.17 + z * 0.23) + 0.18 * cos(x * 0.09 - z * 0.31)
	var bumps := 0.32 * sin(x * 0.61) * cos(z * 0.53) + 0.18 * sin(x * 1.3 + z * 0.9)
	# Beira da maquete: sobe perto das bordas.
	var edge := maxf(absf(x) / (size.x * 0.5), absf(z) / (size.y * 0.5))
	var rim := smoothstep(0.78, 1.0, edge) * 2.4
	var flat := 1.0 - smoothstep(path_width * 0.55, path_width * 0.55 + 2.2, _distance_to_paths(x, z))
	for pad in pads:
		var d := Vector2(x, z).distance_to(pad[0])
		flat = maxf(flat, 1.0 - smoothstep(pad[1], pad[1] + 2.0, d))
	return base + bumps * (1.0 - flat) + rim


func build() -> void:
	_samples.clear()
	for path in paths:
		_samples.append(sample_path(path, 0.6))
	_build_ground()
	if not draw:
		return
	for path in paths:
		_build_edges(sample_path(path, 0.25), paths.find(path))
	_build_meadow()


## Pontos da curva (Catmull-Rom) a cada `step` metros.
static func sample_path(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points.size() - 1:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, points.size() - 1)]
		var count := maxi(int(p1.distance_to(p2) / step), 1)
		for k in count:
			var t := float(k) / count
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(points[points.size() - 1])
	return out


func _distance_to_paths(x: float, z: float) -> float:
	var best := 1e9
	var p := Vector2(x, z)
	for samples in _samples:
		for i in range(0, samples.size() - 1):
			var a := samples[i]
			var b := samples[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			best = minf(best, p.distance_to(a + ab * t))
	return best


func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heights := []
	var colors := []
	for j in cells.y + 1:
		var row := []
		var crow := []
		for i in cells.x + 1:
			var x := -size.x * 0.5 + size.x * i / cells.x
			var z := -size.y * 0.5 + size.y * j / cells.y
			row.append(_raw_height(x, z))
			crow.append(_ground_color(x, z) if draw else Color.WHITE)
		heights.append(row)
		colors.append(crow)
	_grid.resize((cells.x + 1) * (cells.y + 1))
	for j in cells.y + 1:
		for i in cells.x + 1:
			_grid[j * (cells.x + 1) + i] = heights[j][i]
	for j in cells.y:
		for i in cells.x:
			var quad := [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]
			for idx in [0, 1, 2, 0, 2, 3]:
				var c: Vector2i = quad[idx]
				var x := -size.x * 0.5 + size.x * c.x / cells.x
				var z := -size.y * 0.5 + size.y * c.y / cells.y
				st.set_color(colors[c.y][c.x])
				st.set_uv(Vector2(x, z) * 0.25)
				st.add_vertex(Vector3(x, heights[c.y][c.x], z))
	# Junta os vértices iguais para a normal sair suave (sem facetas em quadrados no tom toon).
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)
	if not draw:
		return
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("dirt_albedo", DIRT_ALBEDO)
	material.set_shader_parameter("grass_albedo", GRASS_ALBEDO)
	node.material_override = material
	body.add_child(node)


func _ground_color(x: float, z: float) -> Color:
	# Grama escura e baixa longe das trilhas, terra batida clara nas trilhas e nos pátios, com uma
	# borda de terra mais escura (a grama gasta).
	var grass := Color("3a4128").lerp(Color("4a4a2a"), 0.5 + 0.5 * sin(x * 0.7 + z * 0.4) * cos(z * 0.9 - x * 0.3))
	var dirt := Color("8a6440")
	var d := _distance_to_paths(x, z)
	var on_path := 1.0 - smoothstep(path_width * 0.42, path_width * 0.42 + 0.5, d)
	var worn := 1.0 - smoothstep(path_width * 0.5, path_width * 0.5 + 1.4, d)
	var color := grass.lerp(Color("5a4630"), worn * 0.7).lerp(dirt, on_path)
	var edge := maxf(absf(x) / (size.x * 0.5), absf(z) / (size.y * 0.5))
	color = color.lerp(Color("1e1620"), smoothstep(0.7, 1.0, edge) * 0.8)
	for pad in pads:
		var pd := Vector2(x, z).distance_to(pad[0])
		color = color.lerp(Color("7a5a3a"), (1.0 - smoothstep(pad[1] * 0.7, pad[1] + 1.2, pd)) * 0.8)
	return color


## Tábuas de madeira ao longo da trilha, atravessadas, com cor e ângulo um pouco diferentes.
func _build_planks(samples: PackedVector2Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = samples.size()
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var step := 0.34
	var travelled := 0.0
	var next := 0.0
	for i in samples.size() - 1:
		var a := samples[i]
		var b := samples[i + 1]
		var seg := a.distance_to(b)
		while next <= travelled + seg:
			var t := (next - travelled) / maxf(seg, 0.0001)
			var p := a.lerp(b, t)
			var dir := (b - a).normalized()
			var yaw := -atan2(dir.y, dir.x) + rng.randf_range(-0.05, 0.05)
			var y := height_at(p.x, p.y) + 0.035
			var basis := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(0.28, 0.06, path_width * rng.randf_range(0.92, 1.0)))
			transforms.append(Transform3D(basis, Vector3(p.x, y, p.y)))
			colors.append(Color("7a5434").lerp(Color("9a6e44"), rng.randf()).darkened(rng.randf_range(0.0, 0.25)))
			next += step
		travelled += seg
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var plank := BoxMesh.new()
	mm.mesh = plank
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.roughness = 0.9
	node.material_override = material
	add_child(node)


## Moitas de capim soltas no gramado, longe das trilhas e dos pátios: um ruído decide onde há mais
## (manchas cheias e trechos vazios), e cada ponto da grade, deslocado ao acaso, pode virar uma moita.
func _build_meadow() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var density := FastNoiseLite.new()
	density.seed = 33
	density.frequency = 0.12
	var tufts: Array[Transform3D] = []
	var stones: Array[Transform3D] = []
	var inner := size * 0.5 - Vector2(2.2, 2.2)
	var x := -inner.x
	while x < inner.x:
		var z := -inner.y
		while z < inner.y:
			var at := Vector2(x + rng.randf_range(-0.6, 0.6), z + rng.randf_range(-0.6, 0.6))
			z += 1.3
			var full := density.get_noise_2d(at.x, at.y) * 0.5 + 0.5
			if rng.randf() > (full - 0.35) * 1.4:
				continue
			if _distance_to_paths(at.x, at.y) < path_width * 0.85 or _near_pad(at, 0.6):
				continue
			_tuft_clump(tufts, rng, at, rng.randi_range(2, 6), rng.randf_range(0.12, 0.4))
			if rng.randf() < 0.08:
				_stone(stones, rng, at + Vector2(0.3, 0.1))
		x += 1.3
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 1.0
	blade.height = 1.0
	blade.radial_segments = 4
	blade.rings = 1
	_multi(tufts, blade, WorldProps.paint(Color("4e5e30")))
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 8
	rock.rings = 4
	_multi(stones, rock, WorldProps.paint(Color("6a6470"), 0.012))


func _near_pad(at: Vector2, margin: float) -> bool:
	for pad in pads:
		if at.distance_to(pad[0]) < pad[1] + margin:
			return true
	return false


## Borda das trilhas: tufos de capim e pedras em moitas irregulares. Um ruído decide onde a borda é
## cheia ou rala (há trechos vazios); cada moita tem de 2 a 7 folhas, às vezes com uma pedra junto,
## e o espaço até a próxima varia. Algumas moitas soltas na grama, longe da trilha.
func _build_edges(samples: PackedVector2Array, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 + seed_value
	var density := FastNoiseLite.new()
	density.seed = 7 + seed_value
	density.frequency = 0.22
	var tufts: Array[Transform3D] = []
	var stones: Array[Transform3D] = []
	var travelled := 0.0
	var next_spot := rng.randf_range(0.0, 0.8)
	for i in samples.size() - 1:
		var a := samples[i]
		var b := samples[i + 1]
		var seg := a.distance_to(b)
		var dir := (b - a).normalized()
		var normal := Vector2(-dir.y, dir.x)
		while next_spot <= travelled + seg:
			var p := a.lerp(b, (next_spot - travelled) / maxf(seg, 0.0001))
			var full := density.get_noise_2d(p.x, p.y) * 0.5 + 0.5
			for side in [-1.0, 1.0]:
				if rng.randf() > full * full * 1.6:
					continue
				var at: Vector2 = p + normal * side * (path_width * 0.5 + rng.randf_range(-0.1, 0.9))
				_tuft_clump(tufts, rng, at, rng.randi_range(2, 3 + int(full * 4.0)), rng.randf_range(0.12, 0.35))
				if rng.randf() < 0.22:
					_stone(stones, rng, at + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)))
			if rng.randf() < 0.12:
				# Pedra sozinha encostada na trilha, às vezes duas.
				var side := -1.0 if rng.randf() < 0.5 else 1.0
				var at: Vector2 = p + normal * side * (path_width * 0.5 + rng.randf_range(-0.05, 0.3))
				_stone(stones, rng, at)
				if rng.randf() < 0.4:
					_stone(stones, rng, at + dir * rng.randf_range(0.25, 0.4), 0.6)
			next_spot += rng.randf_range(0.35, 1.6)
			if rng.randf() < 0.3:
				# Moita solta mais longe, na grama.
				var far: Vector2 = p + normal * (-1.0 if rng.randf() < 0.5 else 1.0) * rng.randf_range(2.2, 5.0)
				if _distance_to_paths(far.x, far.y) > path_width * 0.8:
					_tuft_clump(tufts, rng, far, rng.randi_range(2, 5), rng.randf_range(0.15, 0.4))
		travelled += seg
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 1.0
	blade.height = 1.0
	blade.radial_segments = 4
	blade.rings = 1
	_multi(tufts, blade, WorldProps.paint(Color("5a6a34")))
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 8
	rock.rings = 4
	_multi(stones, rock, WorldProps.paint(Color("6a6470"), 0.012))


func _tuft_clump(tufts: Array[Transform3D], rng: RandomNumberGenerator, at: Vector2, count: int, spread: float) -> void:
	var tall := rng.randf_range(0.8, 1.3)
	for k in count:
		var spot := at + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
		var h := rng.randf_range(0.14, 0.32) * tall
		var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.45, 0.45)) * Basis.from_scale(Vector3(0.05, h, 0.05))
		tufts.append(Transform3D(basis, Vector3(spot.x, height_at(spot.x, spot.y) + h * 0.5, spot.y)))


func _stone(stones: Array[Transform3D], rng: RandomNumberGenerator, at: Vector2, scale := 1.0) -> void:
	var r := rng.randf_range(0.08, 0.26) * scale
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(r, r * rng.randf_range(0.45, 0.7), r * rng.randf_range(0.7, 1.0)))
	stones.append(Transform3D(basis, Vector3(at.x, height_at(at.x, at.y) + r * 0.12, at.y)))


func _multi(transforms: Array[Transform3D], mesh: Mesh, material: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	add_child(node)
