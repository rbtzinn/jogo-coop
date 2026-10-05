"""Miniatura 3D do palhaço (piloto 3D, 04/10/2026), feita inteira por este script, sem trabalho manual escondido.

Rodar (Blender 4.5 LTS, sem janela):
    blender.exe --background --factory-startup --python tools/blender/palhaco_miniatura.py -- <saida.glb> [previa.png]

Referências aprovadas: docs/referencias/pecas/palhaco_folha.png, palhaco_parado.png e palhaco_corrida.png.

- Formas: cabeça alta (testa larga, queixo estreito); corpo de pera, calças e mangas bufantes por perfil de
  torno (lathe); tufos de cabelo em nuvem e luvas de 4 dedos por metaball; cartolinha inclinada com faixa
  dourada e margarida; gola e babados ondulados; sapatão com faixa e sola creme.
- Rosto: decalques (olhos com o corte de torta, sobrancelhas, sorriso com língua, bochechas) construídos sobre
  a própria superfície da cabeça, uns milímetros acima dela. O piscar é uma shape key ("piscar").
- Xadrez bordô e creme: textura gerada aqui, com UV do torno (sem esticar).
- Esqueleto com as MESMAS juntas da miniatura do Godot (core/world/miniature.gd, tipo "clown"): o Godot
  dirige os ossos com o andar procedural dele. Pernas e braços têm pele com pesos explícitos; o resto é rígido
  num osso.

Eixos: o Blender usa z para cima e o boneco olha para -y; no glTF isso vira y para cima e +z para a frente,
como no Godot. As medidas abaixo estão em metros do modelo (a miniatura no mundo usa escala 1,55).
"""

import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

# --- Proporções (iguais às do Godot: miniature.gd, _build_clown_rig) -----------------------------------------
HIP_Y = 0.36
HIP_X = 0.095
THIGH = 0.14
SHIN = 0.14
ANKLE_H = HIP_Y - THIGH - SHIN  # tornozelo no descanso (pernas retas)
TORSO_Y = HIP_Y + 0.02
HEAD_Y = TORSO_Y + 0.64
SHOULDER = (0.2, TORSO_Y + 0.33)
UPPER = 0.12
LOWER = 0.11
GLOVE = 0.095
HAT_OFFSET = Vector((0.04, 0.02, 0.2))  # do meio da cabeça (x, y Blender, z)
HEAD_R = (0.225, 0.215, 0.27)  # x, profundidade, altura

COLORS = {
    "pele": (1.0, 0.93, 0.86),
    "cabelo": (0.86, 0.17, 0.14),
    "nariz": (0.90, 0.16, 0.14),
    "chapeu": (0.09, 0.08, 0.10),
    "ouro": (0.91, 0.70, 0.23),
    "creme": (0.95, 0.89, 0.77),
    "bordo": (0.55, 0.15, 0.16),
    "sapato": (0.42, 0.22, 0.12),
    "sola": (0.93, 0.85, 0.71),
    "luva": (0.98, 0.97, 0.94),
    "olho": (0.99, 0.99, 0.97),
    "tinta": (0.08, 0.06, 0.07),
    "boca": (0.24, 0.05, 0.07),
    "lingua": (0.89, 0.40, 0.42),
    "bochecha": (0.95, 0.60, 0.58),
    "miolo": (0.97, 0.78, 0.18),
}


def srgb(c):
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c) + (1.0,)


def material(name, color, rough=0.62, metal=0.0, texture=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb(color)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if texture is not None:
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = texture
        mat.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def checker_texture():
    size = 256
    img = bpy.data.images.new("xadrez", size, size)
    pixels = []
    a = srgb(COLORS["bordo"])
    b = srgb(COLORS["creme"])
    for y in range(size):
        for x in range(size):
            # 8 x 8 quadrados com uma borda escura fininha (tinta) entre eles e um leve desgaste de impressão.
            cx = x * 8 // size
            cy = y * 8 // size
            c = a if (cx + cy) % 2 == 0 else b
            edge = min(x % (size // 8), y % (size // 8))
            k = 0.82 if edge < 1 else 1.0
            n = 1.0 - 0.04 * (((x * 73 + y * 151) % 17) / 17.0)
            pixels.extend([c[0] * k * n, c[1] * k * n, c[2] * k * n, 1.0])
    img.pixels = pixels
    img.pack()
    return img


# --- Construção de malhas ----------------------------------------------------------------------------------

class Builder:
    """Junta tudo numa malha só: vértices, faces, UV, material por face e peso de osso por vértice."""

    def __init__(self):
        self.verts = []
        self.faces = []
        self.uvs = []  # por face: lista de (u, v)
        self.mats = []
        self.weights = []  # por vértice: {osso: peso}
        self.mat_index = {}

    def mat(self, name):
        if name not in self.mat_index:
            self.mat_index[name] = len(self.mat_index)
        return self.mat_index[name]

    def add(self, verts, faces, mat, weights, uvs=None):
        base = len(self.verts)
        self.verts.extend(verts)
        for i, face in enumerate(faces):
            self.faces.append([base + k for k in face])
            self.mats.append(self.mat(mat))
            self.uvs.append(uvs[i] if uvs else [(0.5, 0.5)] * len(face))
        if callable(weights):
            self.weights.extend(weights(v) for v in verts)
        else:
            self.weights.extend([weights] * len(verts))
        return base


def lathe(builder, profile, segments, mat, weights, center=Vector(), depth=1.0, uv_repeat=(1.0, 1.0), wave=None):
    """Torno em volta do eixo z: `profile` = [(raio, z), ...] de baixo para cima. `wave(theta, z)` multiplica o raio."""
    verts = []
    rows = len(profile)
    for j, (r, z) in enumerate(profile):
        for i in range(segments):
            t = 2.0 * math.pi * i / segments
            k = wave(t, z) if wave else 1.0
            verts.append(center + Vector((math.sin(t) * r * k, -math.cos(t) * r * k * depth, z)))
    faces = []
    uvs = []
    for j in range(rows - 1):
        for i in range(segments):
            a = j * segments + i
            b = j * segments + (i + 1) % segments
            c = (j + 1) * segments + (i + 1) % segments
            d = (j + 1) * segments + i
            faces.append([a, b, c, d])
            u0 = i / segments * uv_repeat[0]
            u1 = (i + 1) / segments * uv_repeat[0]
            v0 = j / (rows - 1) * uv_repeat[1]
            v1 = (j + 1) / (rows - 1) * uv_repeat[1]
            uvs.append([(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
    return builder.add(verts, faces, mat, weights, uvs)


def ellipsoid(builder, center, radii, mat, weights, seg=24, rings=16, deform=None, rotation=None):
    verts = []
    faces = []
    for j in range(rings + 1):
        p = math.pi * j / rings - math.pi / 2
        for i in range(seg):
            t = 2.0 * math.pi * i / seg
            v = Vector((math.cos(p) * math.sin(t) * radii[0], -math.cos(p) * math.cos(t) * radii[1], math.sin(p) * radii[2]))
            if deform:
                v = deform(v)
            if rotation:
                v = rotation @ v
            verts.append(center + v)
    for j in range(rings):
        for i in range(seg):
            a = j * seg + i
            b = j * seg + (i + 1) % seg
            c = (j + 1) * seg + (i + 1) % seg
            d = (j + 1) * seg + i
            faces.append([a, b, c, d])
    return builder.add(verts, faces, mat, weights)


def metaball_mesh(builder, balls, mat, weights, resolution=0.012, threshold=0.6):
    """Nuvem de esferas fundidas (metaball) convertida em malha."""
    mb = bpy.data.metaballs.new("mb")
    mb.resolution = resolution
    mb.threshold = threshold
    obj = bpy.data.objects.new("mb", mb)
    bpy.context.collection.objects.link(obj)
    for center, radius in balls:
        el = mb.elements.new()
        el.co = center
        # O raio do metaball é o da influência: a superfície fica bem dentro dele. 1,6x dá o tamanho pedido.
        el.radius = radius * 1.45
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh = obj.evaluated_get(depsgraph).to_mesh()
    verts = [v.co.copy() for v in mesh.vertices]
    faces = [list(p.vertices) for p in mesh.polygons]
    obj.evaluated_get(depsgraph).to_mesh_clear()
    bpy.data.objects.remove(obj)
    bpy.data.metaballs.remove(mb)
    return builder.add(verts, faces, mat, weights)


# --- Cabeça e rosto em decalques ---------------------------------------------------------------------------

HEAD_C = Vector((0.0, 0.0, HEAD_Y))


def head_shape(v):
    """Ellipsoide da cabeça com testa larga e queixo estreito (o desenho aprovado)."""
    z = v.z / HEAD_R[2]
    k = 1.0
    if z < 0:
        k = 1.0 - 0.38 * (-z) ** 1.4
    elif z > 0.4:
        k = 1.0 + 0.04 * (z - 0.4)
    out = Vector((v.x * k, v.y * k, v.z))
    # Bochechas e focinho um pouco para a frente na metade de baixo (o rosto do desenho avança).
    if out.y < 0 and z < 0.2:
        out.y *= 1.0 + 0.10 * (0.2 - z) * max(0.0, 1.0 - abs(v.x) / HEAD_R[0])
    return out


def head_point(theta, phi, lift=0.0):
    """Ponto da superfície da cabeça (theta 0 = de frente, para a direita do boneco +x; phi 0 = equador)."""
    def raw(t, p):
        v = Vector((math.cos(p) * math.sin(t) * HEAD_R[0], -math.cos(p) * math.cos(t) * HEAD_R[1], math.sin(p) * HEAD_R[2]))
        return head_shape(v)
    p0 = raw(theta, phi)
    dt = raw(theta + 0.001, phi) - raw(theta - 0.001, phi)
    dp = raw(theta, phi + 0.001) - raw(theta, phi - 0.001)
    n = dp.cross(dt).normalized()
    if n.dot(p0) < 0:
        n = -n
    return HEAD_C + p0 + n * lift, n


def decal(builder, outline, mat, lift, weights, center=None):
    """Polígono em (theta, phi) sobre a cabeça, em leque a partir do meio (formas convexas)."""
    if center is None:
        center = (sum(p[0] for p in outline) / len(outline), sum(p[1] for p in outline) / len(outline))
    verts = [head_point(center[0], center[1], lift)[0]] + [head_point(t, p, lift)[0] for t, p in outline]
    faces = [[0, i + 1, (i + 1) % len(outline) + 1] for i in range(len(outline))]
    return builder.add(verts, faces, mat, weights), len(verts)


def strip(builder, upper, lower, mat, lift, weights):
    """Faixa entre duas curvas em (theta, phi) (sorriso, sobrancelha)."""
    verts = [head_point(t, p, lift)[0] for t, p in upper] + [head_point(t, p, lift)[0] for t, p in lower]
    n = len(upper)
    faces = [[i, i + 1, n + i + 1, n + i] for i in range(n - 1)]
    return builder.add(verts, faces, mat, weights), len(verts)


def ellipse(cx, cy, rx, ry, n=28, rot=0.0):
    out = []
    for i in range(n):
        a = 2.0 * math.pi * i / n
        x = math.cos(a) * rx
        y = math.sin(a) * ry
        out.append((cx + x * math.cos(rot) - y * math.sin(rot), cy + x * math.sin(rot) + y * math.cos(rot)))
    return out


# --- Montagem ----------------------------------------------------------------------------------------------

def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    checker = checker_texture()
    body = Builder()
    face = Builder()  # rosto (rígido na cabeça, com a shape key do piscar)
    blink_targets = {}  # índice do vértice no rosto -> posição com o olho fechado

    def bone(name):
        return {name: 1.0}

    torso_c = Vector((0, 0, TORSO_Y))

    # Corpo de pera em xadrez (raio, z a partir do quadril do tronco).
    pear = [(0.0, -0.06), (0.06, -0.058), (0.12, -0.048), (0.165, -0.025), (0.195, 0.01), (0.212, 0.06), (0.217, 0.12),
            (0.21, 0.18), (0.195, 0.24), (0.172, 0.29), (0.145, 0.335), (0.11, 0.375), (0.075, 0.402), (0.035, 0.416), (0.0, 0.42)]
    lathe(body, pear, 48, "xadrez", bone("torso"), torso_c, depth=0.88, uv_repeat=(2.0, 1.1))
    # Botões dourados.
    for z in (0.26, 0.13):
        r = 0.205 if z < 0.2 else 0.18
        ellipsoid(body, torso_c + Vector((0.07, -r * 0.88 + 0.005, z)), (0.03, 0.02, 0.03), "ouro", bone("torso"), 16, 10)
    # Gola de babado: dois anéis ondulados (o de cima menor), creme.
    for k, (r, z, h) in enumerate([(0.17, 0.40, 0.05), (0.14, 0.44, 0.045)]):
        prof = [(r * 0.55, z - h * 0.4), (r * 0.85, z - h * 0.3), (r, z - h * 0.1), (r * 1.08, z + h * 0.25), (r * 1.02, z + h * 0.5),
                (r * 0.8, z + h * 0.62), (r * 0.45, z + h * 0.5)]
        lathe(body, prof, 112, "creme", bone("torso"), torso_c, depth=0.92,
              wave=lambda t, zz, k=k: 1.0 + 0.09 * math.sin(t * 14 + k * 1.6) + 0.02 * math.sin(t * 28))

    # Pernas: calça bufante em xadrez com babado creme no tornozelo; peso coxa/canela pela altura.
    for side, tag in ((-1, "n"), (1, "p")):
        hip = Vector((side * HIP_X, 0, HIP_Y))

        def leg_w(v, tag=tag):
            t = (HIP_Y - v.z) / THIGH
            s = min(max((t - 0.75) / 0.5, 0.0), 1.0)
            return {"coxa_" + tag: 1.0 - s, "canela_" + tag: s}
        prof = [(0.0, -0.005), (0.055, 0.0), (0.072, 0.05), (0.085, 0.13), (0.08, 0.19), (0.07, 0.24), (0.068, 0.29),
                (0.075, 0.31), (0.0, 0.32)]
        # O perfil vai de baixo (tornozelo) para cima (quadril).
        prof = [(r, z - 0.0) for r, z in prof]
        lathe(body, prof, 24, "xadrez", leg_w, Vector((hip.x, 0, ANKLE_H)), depth=1.0, uv_repeat=(1.0, 0.75))
        lathe(body, [(0.05, 0.0), (0.085, 0.015), (0.09, 0.04), (0.06, 0.055)], 40, "creme", bone("canela_" + tag),
              Vector((hip.x, 0, ANKLE_H + 0.0)), wave=lambda t, z: 1.0 + 0.12 * math.sin(t * 10))
        # Sapatão: bico redondo grande à frente, faixa creme e sola clara.
        foot_c = Vector((hip.x, -0.07, ANKLE_H - 0.035))

        def shoe_shape(v):
            # Frente (y < 0) mais larga e alta, calcanhar menor.
            front = max(0.0, -v.y / 0.2)
            return Vector((v.x * (0.85 + 0.25 * front), v.y, v.z * (0.9 + 0.2 * front) + (0.012 * front if v.z > 0 else 0.0)))
        base = ellipsoid(body, foot_c, (0.1, 0.2, 0.07), "sapato", bone("pe_" + tag), 28, 18, deform=shoe_shape)
        # Faixa creme: as faces no meio do comprimento; sola: as de baixo.
        count = 28 * 19
        for fi in range(len(body.faces)):
            face_v = body.faces[fi]
            if face_v[0] < base or face_v[0] >= base + count:
                continue
            c = sum((body.verts[i] for i in face_v), Vector()) / len(face_v)
            local = c - foot_c
            if local.z < -0.045:
                body.mats[fi] = body.mat("sola")
            elif -0.02 < local.y < 0.035 and local.z > -0.04:
                body.mats[fi] = body.mat("sola")
        ellipsoid(body, foot_c + Vector((0, 0.005, -0.068)), (0.098, 0.2, 0.012), "sola", bone("pe_" + tag), 24, 8)

    # Braços: manga bufante em xadrez, punho de babado e luva de 4 dedos.
    for side, tag in ((-1, "n"), (1, "p")):
        sh = Vector((side * SHOULDER[0], 0, SHOULDER[1]))

        def arm_w(v, tag=tag):
            t = (SHOULDER[1] - v.z) / UPPER
            s = min(max((t - 0.75) / 0.5, 0.0), 1.0)
            return {"braco_" + tag: 1.0 - s, "antebraco_" + tag: s}
        prof = [(0.0, -UPPER - LOWER), (0.04, -UPPER - LOWER + 0.005), (0.05, -UPPER - 0.05), (0.058, -UPPER + 0.01),
                (0.062, -0.05), (0.058, -0.01), (0.048, 0.015), (0.03, 0.03), (0.0, 0.036)]
        prof = [(r, z) for r, z in prof]
        lathe(body, prof, 20, "xadrez", arm_w, sh, uv_repeat=(0.75, 0.6))
        wrist = sh + Vector((0, 0, -UPPER - LOWER))
        lathe(body, [(0.035, -0.01), (0.06, 0.0), (0.065, 0.02), (0.04, 0.03)], 32, "creme", bone("antebraco_" + tag),
              wrist, wave=lambda t, z: 1.0 + 0.12 * math.sin(t * 9))
        hand = wrist + Vector((0, 0, -GLOVE * 0.6))
        balls = [((0, 0, 0), GLOVE * 0.95)]
        for f in range(3):
            balls.append(((side * (-0.02 + 0.02 * f) * 1.2, -0.02, -GLOVE * 0.9), GLOVE * 0.42))
        balls.append(((side * -0.05, -0.045, -0.01), GLOVE * 0.4))
        start = len(body.verts)
        metaball_mesh(body, balls, "luva", bone("mao_" + tag), resolution=0.008)
        for i in range(start, len(body.verts)):
            body.verts[i] = body.verts[i] + hand

    # Cabeça.
    ellipsoid(body, HEAD_C, HEAD_R, "pele", bone("cabeca"), 48, 32, deform=head_shape)
    # Nariz de bola, com brilho de verniz.
    nose_p, nose_n = head_point(0.0, -0.06, 0.0)
    ellipsoid(body, nose_p + nose_n * 0.03, (0.06, 0.055, 0.058), "nariz", bone("cabeca"), 24, 16)
    # Tufos de cabelo em nuvem: dos lados e uma coroa atrás.
    balls = []
    # Gomos de nuvem: bolas menores e separadas o bastante para os gomos aparecerem.
    for side in (-1, 1):
        for (x, y, z, r) in [(0.235, 0.0, 0.03, 0.075), (0.265, 0.06, -0.04, 0.07), (0.245, -0.05, -0.08, 0.062),
                             (0.215, 0.1, 0.07, 0.065), (0.24, 0.09, -0.12, 0.06)]:
            balls.append(((side * x, y, z), r))
    # Na nuca, só uma fileira baixa de gomos (de cima, a câmera do mapa via uma massa vermelha).
    for k in range(5):
        a = math.pi * (0.7 + 0.6 * k / 4.0)
        balls.append(((math.sin(a) * 0.19, -math.cos(a) * 0.19, -0.1), 0.05))
    start = len(body.verts)
    metaball_mesh(body, balls, "cabelo", bone("cabeca"), resolution=0.01)
    for i in range(start, len(body.verts)):
        body.verts[i] = body.verts[i] + HEAD_C

    # Cartolinha (osso "chapeu", que balança): aba com as bordas viradas, copa, faixa dourada e margarida.
    hat_c = HEAD_C + HAT_OFFSET
    tilt = Matrix.Rotation(-0.22, 3, "Y") @ Matrix.Rotation(-0.12, 3, "X")

    def hat(builder, profile, mat, seg=40, wave=None):
        start = len(builder.verts)
        lathe(builder, profile, seg, mat, bone("chapeu"), Vector(), wave=wave)
        for i in range(start, len(builder.verts)):
            builder.verts[i] = hat_c + tilt @ builder.verts[i]
    hat(body, [(0.0, -0.005), (0.15, -0.01), (0.175, 0.012), (0.16, 0.02), (0.11, 0.012), (0.0, 0.015)], "chapeu",
        wave=lambda t, z: 1.0 + 0.05 * abs(math.sin(t)))
    hat(body, [(0.105, 0.0), (0.108, 0.06), (0.1, 0.16), (0.095, 0.175), (0.0, 0.18)], "chapeu")
    hat(body, [(0.11, 0.012), (0.112, 0.045), (0.109, 0.05)], "ouro")
    daisy_c = Vector((-0.1, -0.05, 0.07))
    for k in range(9):
        a = 2.0 * math.pi * k / 9
        start = len(body.verts)
        ellipsoid(body, Vector((math.cos(a) * 0.038, 0, math.sin(a) * 0.038)), (0.022, 0.006, 0.012), "olho", bone("chapeu"), 10, 6,
                  rotation=Matrix.Rotation(a, 3, "Y").inverted())
        for i in range(start, len(body.verts)):
            body.verts[i] = hat_c + tilt @ (body.verts[i] + daisy_c)
    start = len(body.verts)
    ellipsoid(body, Vector(), (0.02, 0.01, 0.02), "miolo", bone("chapeu"), 12, 8)
    for i in range(start, len(body.verts)):
        body.verts[i] = hat_c + tilt @ (body.verts[i] + daisy_c + Vector((0, -0.006, 0)))

    # Rosto em decalques (no objeto "rosto"): contorno e branco dos olhos, pupila com o corte de torta, brilho,
    # sobrancelhas, sorriso com língua e bochechas. Ordem de baixo para cima com alturas crescentes.
    head_w = bone("cabeca")
    for side in (-1, 1):
        ex, ey, rx, ry = side * 0.25, 0.16, 0.22, 0.33
        decal(face, ellipse(ex, ey, rx + 0.022, ry + 0.022), "tinta", 0.003, head_w)
        base, n = decal(face, ellipse(ex, ey, rx, ry), "olho", 0.0045, head_w)
        px, py = ex - side * 0.06, ey - 0.07
        b2, n2 = decal(face, ellipse(px, py, 0.12, 0.2), "tinta", 0.006, head_w)
        # Corte de torta: um entalhe pequeno no alto da pupila, do lado de fora.
        b3, n3 = decal(face, [(px + side * 0.02, py + 0.09), (px + side * 0.075, py + 0.17), (px + side * 0.01, py + 0.205)], "olho", 0.0075, head_w,
                       center=(px + side * 0.035, py + 0.155))
        b4, n4 = decal(face, ellipse(px + side * 0.05, py - 0.1, 0.028, 0.034), "olho", 0.0075, head_w)
        # Piscar: tudo do olho achata na linha do meio do olho.
        for (start, count) in ((base, n), (b2, n2), (b3, n3), (b4, n4)):
            for i in range(start, start + count):
                p = face.verts[i]
                c = head_point(ex, ey, 0.0)[0]
                blink_targets[i] = Vector((p.x, p.y, c.z + (p.z - c.z) * 0.06))
        # Contorno: no piscar ele vira o traço do olho fechado.
        for i in range(base - (n + 0), base):
            pass
        # Sobrancelha em arco.
        upper = [(ex + side * (-0.17 + 0.34 * k / 8), ey + 0.43 + 0.05 * math.sin(math.pi * k / 8)) for k in range(9)]
        lower = [(t, p - 0.035) for t, p in upper]
        strip(face, upper, lower, "tinta", 0.005, head_w)
        # Bochecha.
        decal(face, ellipse(side * 0.52, -0.16, 0.12, 0.07), "bochecha", 0.0035, head_w)
    # Contorno dos olhos também fecha no piscar (vira o traço).
    for i in range(len(face.verts)):
        pass
    # Sorriso largo com as pontas para cima, contorno de tinta, boca escura e língua.
    smile_up = [(-0.5 + k / 12.0, -0.25 + 0.09 * ((-0.5 + k / 12.0) / 0.5) ** 2) for k in range(13)]
    smile_lo = [(t, -0.25 - 0.20 * (1 - (t / 0.5) ** 2)) for t, _ in smile_up]
    strip(face, [(t, p + 0.02) for t, p in smile_up], [(t, p - 0.02) for t, p in smile_lo], "tinta", 0.003, head_w)
    strip(face, smile_up, smile_lo, "boca", 0.0045, head_w)
    decal(face, ellipse(0.04, -0.4, 0.17, 0.065), "lingua", 0.006, head_w)

    # --- Objetos, materiais, esqueleto e pele ---------------------------------------------------------------
    mats = {
        "xadrez": material("xadrez", COLORS["creme"], 0.7, texture=checker),
        "pele": material("pele", COLORS["pele"], 0.55),
        "cabelo": material("cabelo", COLORS["cabelo"], 0.8),
        "nariz": material("nariz", COLORS["nariz"], 0.22),
        "chapeu": material("chapeu", COLORS["chapeu"], 0.45),
        "ouro": material("ouro", COLORS["ouro"], 0.35, 0.6),
        "creme": material("creme", COLORS["creme"], 0.75),
        "sapato": material("sapato", COLORS["sapato"], 0.3),
        "sola": material("sola", COLORS["sola"], 0.6),
        "luva": material("luva", COLORS["luva"], 0.6),
        "olho": material("olho", COLORS["olho"], 0.3),
        "tinta": material("tinta", COLORS["tinta"], 0.5),
        "boca": material("boca", COLORS["boca"], 0.5),
        "lingua": material("lingua", COLORS["lingua"], 0.45),
        "bochecha": material("bochecha", COLORS["bochecha"], 0.7),
        "miolo": material("miolo", COLORS["miolo"], 0.5),
    }

    arm_data = bpy.data.armatures.new("esqueleto")
    rig = bpy.data.objects.new("palhaco", arm_data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones

    def add_bone(name, head, tail, parent=None):
        b = eb.new(name)
        b.head = head
        b.tail = tail
        if parent:
            b.parent = eb[parent]
        return b
    add_bone("quadril", (0, 0, HIP_Y), (0, 0, HIP_Y + 0.08))
    add_bone("torso", (0, 0, TORSO_Y), (0, 0, TORSO_Y + 0.3), "quadril")
    add_bone("cabeca", (0, 0, HEAD_Y), (0, 0, HEAD_Y + 0.2), "torso")
    add_bone("chapeu", tuple(HEAD_C + HAT_OFFSET), tuple(HEAD_C + HAT_OFFSET + Vector((0, 0, 0.15))), "cabeca")
    for side, tag in ((-1, "n"), (1, "p")):
        x = side * HIP_X
        add_bone("coxa_" + tag, (x, 0, HIP_Y), (x, 0, HIP_Y - THIGH), "quadril")
        add_bone("canela_" + tag, (x, 0, HIP_Y - THIGH), (x, 0, ANKLE_H), "coxa_" + tag)
        add_bone("pe_" + tag, (x, 0, ANKLE_H), (x, -0.18, ANKLE_H), "canela_" + tag)
        sx = side * SHOULDER[0]
        add_bone("braco_" + tag, (sx, 0, SHOULDER[1]), (sx, 0, SHOULDER[1] - UPPER), "torso")
        add_bone("antebraco_" + tag, (sx, 0, SHOULDER[1] - UPPER), (sx, 0, SHOULDER[1] - UPPER - LOWER), "braco_" + tag)
        add_bone("mao_" + tag, (sx, 0, SHOULDER[1] - UPPER - LOWER), (sx, 0, SHOULDER[1] - UPPER - LOWER - 0.08), "antebraco_" + tag)
    bpy.ops.object.mode_set(mode="OBJECT")

    def make_object(name, builder, shape_key=None):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([tuple(v) for v in builder.verts], [], builder.faces)
        mesh.update()
        names = sorted(builder.mat_index, key=lambda k: builder.mat_index[k])
        for n in names:
            mesh.materials.append(mats[n])
        for poly, mi in zip(mesh.polygons, builder.mats):
            poly.material_index = mi
            poly.use_smooth = True
        uv = mesh.uv_layers.new(name="UV")
        for poly, face_uv in zip(mesh.polygons, builder.uvs):
            for k, loop in enumerate(poly.loop_indices):
                uv.data[loop].uv = face_uv[k % len(face_uv)]
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        groups = {}
        for i, w in enumerate(builder.weights):
            for bone_name, value in w.items():
                if value <= 0.0:
                    continue
                if bone_name not in groups:
                    groups[bone_name] = obj.vertex_groups.new(name=bone_name)
                groups[bone_name].add([i], value, "REPLACE")
        mod = obj.modifiers.new("esqueleto", "ARMATURE")
        mod.object = rig
        obj.parent = rig
        if shape_key:
            obj.shape_key_add(name="Basis")
            key = obj.shape_key_add(name=shape_key[0])
            for i, pos in shape_key[1].items():
                key.data[i].co = pos
        # Normais suaves, sem costura nos tornos.
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001) if not shape_key else None
        bm.to_mesh(mesh)
        bm.free()
        return obj
    make_object("corpo", body)
    make_object("rosto", face, ("piscar", blink_targets))
    return rig


def export(path):
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_morph=True,
                              export_animations=False, export_yup=True, export_apply=False)


def preview(path):
    """Prévia em 4 vistas (frente, 3/4, perfil, costas) numa faixa, para conferir com a folha."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 768
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("mundo")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.33, 0.38, 1)
    scene.world = world
    sun = bpy.data.objects.new("sol", bpy.data.lights.new("sol", "SUN"))
    sun.data.energy = 4.0
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
    bpy.context.collection.objects.link(sun)
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 1.75
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    for k, angle in enumerate([0, 45, 90, 180]):
        a = math.radians(angle)
        cam.location = (math.sin(a) * 4, -math.cos(a) * 4, 0.75)
        cam.rotation_euler = (math.radians(90), 0, a)
        scene.render.filepath = path.replace(".png", "_%d.png" % k)
        bpy.ops.render.render(write_still=True)
    # Rosto ampliado, de frente e de 3/4.
    cam_data.ortho_scale = 0.75
    for k, angle in enumerate([0, 35]):
        a = math.radians(angle)
        cam.location = (math.sin(a) * 4, -math.cos(a) * 4, HEAD_Y)
        cam.rotation_euler = (math.radians(90), 0, a)
        scene.render.filepath = path.replace(".png", "_rosto%d.png" % k)
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build()
    if args:
        export(args[0])
    if len(args) > 1:
        preview(args[1])
