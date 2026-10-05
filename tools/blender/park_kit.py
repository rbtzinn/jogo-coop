"""Kit de cenografia do parque (usado por tools/blender/park_render.py).

Geo junta muitas peças pequenas numa malha só (uma por grupo), com materiais compartilhados: o Cycles
renderiza rápido e o .blend fica leve. Materiais com a paleta do circo assombrado à noite.
Peças modeladas com a frente para -y do Blender (o sul do mapa, +z na Godot).
"""
import bpy
import bmesh
import math
import os
import numpy as np
from mathutils import Vector, Matrix

MATS = {}
# nome: (cor, aspereza, metal, emissão, ruído) — ruído escurece/clareia a cor em manchas (madeira, lona gasta).
PALETTE = {
    "canvas_red": ("a3252b", .78, 0, 0, .25), "canvas_cream": ("eadbbd", .8, 0, 0, .2),
    "canvas_navy": ("1d2a5e", .8, 0, 0, .25), "gold": ("d0a040", .32, .85, 0, .1),
    "gold_dark": ("8e6624", .45, .7, 0, .15), "wood": ("7a4a2a", .82, 0, 0, .45),
    "wood_dark": ("3d2617", .85, 0, 0, .4), "wood_light": ("a7774a", .8, 0, 0, .4),
    "paint_red": ("8c2027", .55, 0, 0, .2), "paint_cream": ("e2cfa6", .6, 0, 0, .15),
    "paint_teal": ("24525b", .6, 0, 0, .2), "iron": ("1c1e24", .5, .55, 0, .1),
    "lamp_green": ("1f3a33", .45, .35, 0, .1), "stone": ("8e877a", .9, 0, 0, .35),
    "stone_dark": ("5c564e", .9, 0, 0, .35), "brick": ("8a5a44", .9, 0, 0, .35),
    "glass_warm": ("ffb35c", .2, 0, 9.0, 0), "bulb": ("ffd08a", .2, 0, 30.0, 0),
    "window": ("ffaa52", .3, 0, 5.0, 0), "interior": ("ff8a3c", .9, 0, 1.6, 0),
    "curtain": ("6a1119", .8, 0, 0, .25), "curtain_blue": ("1b1f4a", .8, 0, 0, .25),
    "leaf_dark": ("1b3420", .85, 0, 0, .5), "leaf": ("2c512b", .85, 0, 0, .5),
    "leaf_light": ("4f7234", .85, 0, 0, .5), "pine": ("17321f", .85, 0, 0, .45),
    "trunk": ("4a3222", .9, 0, 0, .4), "hay": ("c9a24a", .9, 0, 0, .4),
    "flower_white": ("f2efe6", .6, 0, 0, 0), "flower_yellow": ("f4c332", .6, 0, 0, 0),
    "flower_pink": ("e7719a", .6, 0, 0, 0), "flower_purple": ("8d5ccc", .6, 0, 0, 0),
    "flower_red": ("cf3440", .6, 0, 0, 0), "flower_orange": ("f08a2c", .6, 0, 0, 0),
    "loco_black": ("17181d", .35, .5, 0, .1), "loco_red": ("962026", .45, .1, 0, .15),
    "rail": ("74747a", .3, .9, 0, .1), "gravel": ("4b443d", .95, 0, 0, .5),
    "crystal": ("9fc2ff", .05, 0, 4.0, 0), "carpet": ("8b1d24", .9, 0, 0, .2),
    "black_hat": ("141418", .5, 0, 0, .1), "bronze": ("6d5a40", .45, .75, 0, .3),
    "cloth_blue": ("3b6db0", .8, 0, 0, .2), "cloth_orange": ("cd5a2c", .8, 0, 0, .2),
    "cloth_yellow": ("e6cf6b", .8, 0, 0, .2), "cloth_purple": ("6b3c8d", .8, 0, 0, .2),
    "cloth_white": ("eeeae0", .8, 0, 0, .1), "bottle_green": ("2f8a5a", .15, 0, .6, 0),
    "bottle_amber": ("d08a2a", .15, 0, .8, 0), "bottle_violet": ("7a4ac8", .15, 0, .8, 0),
    "dirt": ("6d5038", .95, 0, 0, .4), "night": ("101a26", .9, 0, 0, 0),
    "ink": ("120d0a", .7, 0, 0, 0), "clock_face": ("f1e6c8", .6, 0, .3, 0),
}


def srgb(code):
    c = [int(code[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in c) + (1,)


def mat(name):
    if name in MATS:
        return MATS[name]
    color, rough, metal, emit, grain = PALETTE[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = metal
    base = srgb(color)
    if grain:
        # Manchas: a cor varia em volta da base (lona gasta, veios da madeira, folhas).
        coord = nt.nodes.new("ShaderNodeTexCoord")
        tex = nt.nodes.new("ShaderNodeTexNoise")
        tex.inputs["Scale"].default_value = 7.0
        tex.inputs["Detail"].default_value = 6.0
        nt.links.new(coord.outputs["Object"], tex.inputs["Vector"])
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        dark = tuple(c * (1 - grain) for c in base[:3]) + (1,)
        light = tuple(min(c * (1 + grain * .8), 1) for c in base[:3]) + (1,)
        ramp.color_ramp.elements[0].color = dark
        ramp.color_ramp.elements[1].color = light
        ramp.color_ramp.elements[0].position = .3
        ramp.color_ramp.elements[1].position = .7
        nt.links.new(tex.outputs["Fac"], ramp.inputs["Fac"])
        nt.links.new(ramp.outputs["Color"], bs.inputs["Base Color"])
    else:
        bs.inputs["Base Color"].default_value = base
    if emit:
        bs.inputs["Emission Color"].default_value = base
        bs.inputs["Emission Strength"].default_value = emit
    MATS[name] = m
    return m


def stripes(name, a, b, count, rings=False):
    """Listras radiais (em volta do eixo z do objeto): lonas de tenda e toldos redondos."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = .8
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    angle = nt.nodes.new("ShaderNodeMath")
    angle.operation = "ARCTAN2"
    nt.links.new(sep.outputs["Y"], angle.inputs[0])
    nt.links.new(sep.outputs["X"], angle.inputs[1])
    scale = nt.nodes.new("ShaderNodeMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = count / (2 * math.pi)
    nt.links.new(angle.outputs[0], scale.inputs[0])
    frac = nt.nodes.new("ShaderNodeMath")
    frac.operation = "FRACT"
    nt.links.new(scale.outputs[0], frac.inputs[0])
    step = nt.nodes.new("ShaderNodeMath")
    step.operation = "GREATER_THAN"
    step.inputs[1].default_value = .5
    nt.links.new(frac.outputs[0], step.inputs[0])
    noise_tex = nt.nodes.new("ShaderNodeTexNoise")
    noise_tex.inputs["Scale"].default_value = 5.0
    nt.links.new(coord.outputs["Object"], noise_tex.inputs["Vector"])
    shade = nt.nodes.new("ShaderNodeMath")
    shade.operation = "MULTIPLY_ADD"
    shade.inputs[1].default_value = .35
    shade.inputs[2].default_value = .8
    nt.links.new(noise_tex.outputs["Fac"], shade.inputs[0])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs[6].default_value = srgb(a)
    mix.inputs[7].default_value = srgb(b)
    nt.links.new(step.outputs[0], mix.inputs["Factor"])
    tint = nt.nodes.new("ShaderNodeMix")
    tint.data_type = "RGBA"
    tint.blend_type = "MULTIPLY"
    tint.inputs["Factor"].default_value = 1.0
    nt.links.new(mix.outputs[2], tint.inputs[6])
    nt.links.new(shade.outputs[0], tint.inputs[7])
    nt.links.new(tint.outputs[2], bs.inputs["Base Color"])
    MATS[name] = m
    return m


def linear_stripes(name, a, b, width):
    """Listras em x do objeto (toldos retos, painéis de cerca)."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = .75
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["UV"], sep.inputs["Vector"])
    scale = nt.nodes.new("ShaderNodeMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = 1 / width
    nt.links.new(sep.outputs["X"], scale.inputs[0])
    frac = nt.nodes.new("ShaderNodeMath")
    frac.operation = "FRACT"
    nt.links.new(scale.outputs[0], frac.inputs[0])
    step = nt.nodes.new("ShaderNodeMath")
    step.operation = "GREATER_THAN"
    step.inputs[1].default_value = .5
    nt.links.new(frac.outputs[0], step.inputs[0])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs[6].default_value = srgb(a)
    mix.inputs[7].default_value = srgb(b)
    nt.links.new(step.outputs[0], mix.inputs["Factor"])
    nt.links.new(mix.outputs[2], bs.inputs["Base Color"])
    MATS[name] = m
    return m


def rings(name, a, b, count):
    """Anéis concêntricos no plano xy do objeto (o alvo dos Malabaristas)."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = .8
    coord = nt.nodes.new("ShaderNodeTexCoord")
    length = nt.nodes.new("ShaderNodeVectorMath")
    length.operation = "LENGTH"
    nt.links.new(coord.outputs["Object"], length.inputs[0])
    scale = nt.nodes.new("ShaderNodeMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = count
    nt.links.new(length.outputs["Value"], scale.inputs[0])
    frac = nt.nodes.new("ShaderNodeMath")
    frac.operation = "FRACT"
    nt.links.new(scale.outputs[0], frac.inputs[0])
    step = nt.nodes.new("ShaderNodeMath")
    step.operation = "GREATER_THAN"
    step.inputs[1].default_value = .5
    nt.links.new(frac.outputs[0], step.inputs[0])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs[6].default_value = srgb(a)
    mix.inputs[7].default_value = srgb(b)
    nt.links.new(step.outputs[0], mix.inputs["Factor"])
    nt.links.new(mix.outputs[2], bs.inputs["Base Color"])
    MATS[name] = m
    return m


def decal(name, path):
    """Imagem com transparência (emblemas e cartazes recortados da referência)."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = .55
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(path)
    nt.links.new(tex.outputs["Color"], bs.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bs.inputs["Alpha"])
    # Um pouco de brilho próprio: a pintura de referência já vem iluminada.
    nt.links.new(tex.outputs["Color"], bs.inputs["Emission Color"])
    bs.inputs["Emission Strength"].default_value = .35
    MATS[name] = m
    return m


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def R(angle, axis="Z"):
    return Matrix.Rotation(angle, 4, axis)


def S(x, y=None, z=None):
    return Matrix.Diagonal((x, x if y is None else y, x if z is None else z, 1))


class Geo:
    """Acumula peças numa malha; commit() cria um objeto com origem em `origin`."""

    def __init__(self, name, origin=(0, 0, 0)):
        self.name = name
        self.origin = Vector(origin)
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new()
        self.mats = []

    def _tag(self, verts, material, smooth):
        if material not in self.mats:
            self.mats.append(material)
        index = self.mats.index(material)
        for f in {f for v in verts for f in v.link_faces}:
            f.material_index = index
            f.smooth = smooth

    def box(self, material, M, size, smooth=False):
        r = bmesh.ops.create_cube(self.bm, size=1.0, matrix=M @ S(*size))
        self._tag(r["verts"], material, smooth)
        # UV em metros ao longo de x (listras de toldo e painel).
        for v in r["verts"]:
            for loop in v.link_loops:
                loop[self.uv].uv = (v.co.x, v.co.z)

    def cyl(self, material, M, r1, r2, depth, seg=16, smooth=True, cap=True):
        r = bmesh.ops.create_cone(self.bm, cap_ends=cap, cap_tris=False, segments=seg, radius1=r1,
            radius2=r2, depth=depth, matrix=M)
        self._tag(r["verts"], material, smooth)

    def sphere(self, material, M, radius, seg=12, rings_=7, smooth=True):
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=seg, v_segments=rings_, radius=radius, matrix=M)
        self._tag(r["verts"], material, smooth)

    def ico(self, material, M, radius, sub=1, smooth=True):
        r = bmesh.ops.create_icosphere(self.bm, subdivisions=sub, radius=radius, matrix=M)
        self._tag(r["verts"], material, smooth)

    def torus(self, material, M, major, minor, seg=24, minor_seg=6, smooth=True):
        ring = []
        for i in range(seg):
            a = math.tau * i / seg
            row = []
            for j in range(minor_seg):
                b = math.tau * j / minor_seg
                p = Vector(((major + minor * math.cos(b)) * math.cos(a), (major + minor * math.cos(b)) * math.sin(a),
                    minor * math.sin(b)))
                row.append(self.bm.verts.new(M @ p))
            ring.append(row)
        verts = []
        for i in range(seg):
            for j in range(minor_seg):
                a, b = ring[i], ring[(i + 1) % seg]
                self.bm.faces.new((a[j], b[j], b[(j + 1) % minor_seg], a[(j + 1) % minor_seg]))
            verts += ring[i]
        self._tag(verts, material, smooth)

    def tube(self, material, points, radius, seg=6, smooth=True, cap=False):
        pts = [Vector(p) for p in points]
        rings_ = []
        for i, p in enumerate(pts):
            t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
            n = t.cross(Vector((0, 0, 1)))
            if n.length < 1e-3:
                n = t.cross(Vector((1, 0, 0)))
            n.normalize()
            b = t.cross(n)
            rings_.append([self.bm.verts.new(p + (n * math.cos(math.tau * k / seg) + b * math.sin(math.tau * k / seg))
                * radius) for k in range(seg)])
        verts = []
        for a, b in zip(rings_[:-1], rings_[1:]):
            for k in range(seg):
                self.bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
        for r_ in rings_:
            verts += r_
        if cap:
            self.bm.faces.new(rings_[0][::-1])
            self.bm.faces.new(rings_[-1])
        self._tag(verts, material, smooth)

    def poly(self, material, verts, faces, uvs=None, smooth=False):
        vs = [self.bm.verts.new(Vector(v)) for v in verts]
        for fi, f in enumerate(faces):
            face = self.bm.faces.new([vs[i] for i in f])
            if uvs:
                for loop, i in zip(face.loops, f):
                    loop[self.uv].uv = uvs[i]
        self._tag(vs, material, smooth)

    def quad(self, material, center, right, up, uv=((0, 0), (1, 0), (1, 1), (0, 1))):
        c, r, u = Vector(center), Vector(right), Vector(up)
        self.poly(material, [c - r - u, c + r - u, c + r + u, c - r + u], [(0, 1, 2, 3)], list(uv))

    def star(self, material, M, radius, depth=.04):
        pts = []
        for i in range(10):
            a = math.pi / 2 + i * math.pi / 5
            rr = radius if i % 2 == 0 else radius * .45
            pts.append((math.cos(a) * rr, 0, math.sin(a) * rr))
        verts = [M @ Vector((x, -depth / 2, z)) for x, _, z in pts] + [M @ Vector((x, depth / 2, z)) for x, _, z in pts]
        faces = [tuple(range(10))[::-1], tuple(range(10, 20))]
        for i in range(10):
            faces.append((i, (i + 1) % 10, 10 + (i + 1) % 10, 10 + i))
        self.poly(material, verts, faces)

    def commit(self):
        me = bpy.data.meshes.new(self.name)
        bmesh.ops.translate(self.bm, vec=-self.origin, verts=self.bm.verts)
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(m)
        obj = bpy.data.objects.new(self.name, me)
        obj.location = self.origin
        bpy.context.scene.collection.objects.link(obj)
        return obj


def point_light(name, at, energy, color=(1, .66, .36), radius=.08):
    data = bpy.data.lights.new(name, "POINT")
    data.energy = energy
    data.color = color
    data.shadow_soft_size = radius
    obj = bpy.data.objects.new(name, data)
    obj.location = at
    bpy.context.scene.collection.objects.link(obj)
    return obj


def area_light(name, at, energy, size, color=(1, .6, .3), aim=(0, 0, -1)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.size = size
    obj = bpy.data.objects.new(name, data)
    obj.location = at
    obj.rotation_euler = Vector(aim).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(obj)
    return obj


def crop_decal(ref_path, out_path, box, shape="ellipse", feather=.08):
    """Recorta um pedaço da referência com borda transparente (elipse ou retângulo arredondado)."""
    img = bpy.data.images.load(ref_path)
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)[::-1]
    x0, y0, x1, y1 = box
    crop = px[y0:y1, x0:x1].copy()
    ch, cw = crop.shape[:2]
    yy, xx = np.mgrid[0:ch, 0:cw].astype(np.float32)
    u = (xx + .5) / cw * 2 - 1
    v = (yy + .5) / ch * 2 - 1
    if shape == "ellipse":
        d = np.sqrt(u * u + v * v)
    else:
        d = np.maximum(np.abs(u), np.abs(v))
    crop[..., 3] = np.clip((1 - d) / feather, 0, 1)
    out = bpy.data.images.new(os.path.basename(out_path), cw, ch, alpha=True)
    out.pixels = crop[::-1].ravel()
    out.filepath_raw = out_path
    out.file_format = "PNG"
    out.save()
    return out_path
