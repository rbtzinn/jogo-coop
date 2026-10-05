"""Parque da Área 1 renderizado no Blender (referência: docs/referencias/remap/mapa_referencia.png).

1. Godot --headless --path . res://tools/world_layout_export.tscn   (chão, trilhas e portas -> build/park/layout.json)
2. blender --background --factory-startup --python tools/blender/park_render.py -- [preview|final]

O parque inteiro vira uma imagem só, vista pela mesma câmera ortográfica do mapa (inclinação de
CAMERA_PITCH), com luz e sombra calculadas aqui (lampiões, varais, luar). Junto vai a profundidade de
cada pixel: na Godot, levels/world/park_backdrop.gdshader desenha a imagem e grava essa profundidade,
então os bonecos 3D passam atrás das tendas e na frente do chão sem nenhuma malha do cenário.
Saídas em levels/world/art/: park_color.png, park_depth.png (16 bits em R e G) e park_backdrop_data.gd.
Coordenadas: Godot (x, y, z) = Blender (x, z, -y). A frente das atrações é o sul (+z na Godot).
"""
import bpy
import bmesh
import json
import math
import os
import random
import shutil
import sys
import numpy as np
from mathutils import Vector, Matrix, noise

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
LAYOUT = os.path.join(ROOT, "build/park/layout.json")
OUT = os.path.join(ROOT, "levels/world/art")
WORK = os.path.join(ROOT, "build/park")
MODE = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "preview"
## Pixels por metro no plano da câmera (a câmera do mapa mostra 13,5 m de altura em 1080 linhas).
PPM = {"final": 80, "medium": 40}.get(MODE, 24)
## Faixa coberta no plano da câmera: largura (x) e altura (eixo "para cima" da câmera), em metros.
SPAN_X = (-24.0, 24.0)
SPAN_V = (-10.8, 15.6)
## Profundidade gravada: de DEPTH_NEAR a DEPTH_FAR metros à frente do plano da câmera do Blender.
CAMERA_BACK = 60.0
DEPTH_NEAR, DEPTH_FAR = 30.0, 100.0

D = json.load(open(LAYOUT, encoding="utf-8"))
PITCH = math.radians(-D["camera_pitch"])
RIGHT = Vector((1, 0, 0))
UP_G = Vector((0, math.cos(PITCH), -math.sin(PITCH)))
FWD_G = Vector((0, -math.sin(PITCH), -math.cos(PITCH)))
rng = random.Random(2026)


def g2b(x, y, z):
    return Vector((x, -z, y))


# ---------------------------------------------------------------- terreno
SIZE = D["size"]
CELLS = D["cells"]
HEIGHTS = np.array(D["heights"], np.float32).reshape(CELLS[1] + 1, CELLS[0] + 1)


def height_at(x, z):
    fx = min(max((x + SIZE[0] / 2) / SIZE[0] * CELLS[0], 0), CELLS[0] - 0.001)
    fz = min(max((z + SIZE[1] / 2) / SIZE[1] * CELLS[1], 0), CELLS[1] - 0.001)
    i, j = int(fx), int(fz)
    u, v = fx - i, fz - j
    h0 = HEIGHTS[j, i] * (1 - u) + HEIGHTS[j, i + 1] * u
    h1 = HEIGHTS[j + 1, i] * (1 - u) + HEIGHTS[j + 1, i + 1] * u
    return float(h0 * (1 - v) + h1 * v)


def ground(x, z, lift=0.0):
    return g2b(x, height_at(x, z) + lift, z)


PATH_POINTS = np.array([p for path in D["paths"] for p in path], np.float32)


def path_distance(x, z):
    d = PATH_POINTS - np.array([x, z], np.float32)
    return float(np.sqrt((d * d).sum(1)).min())


# ---------------------------------------------------------------- materiais
MATS = {}


def srgb(code):
    c = [int(code[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in c) + (1,)


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def mesh_object(name, bm, mat=None, smooth=False):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    if mat is not None:
        me.materials.append(mat)
    return link(obj)


def terrain():
    w, h = CELLS[0] * 2, CELLS[1] * 2
    bm = bmesh.new()
    verts = []
    for j in range(h + 1):
        for i in range(w + 1):
            x = -SIZE[0] / 2 + SIZE[0] * i / w
            z = -SIZE[1] / 2 + SIZE[1] * j / h
            verts.append(bm.verts.new(ground(x, z)))
    uv = bm.loops.layers.uv.new()
    for j in range(h):
        for i in range(w):
            k = j * (w + 1) + i
            f = bm.faces.new((verts[k], verts[k + 1], verts[k + w + 2], verts[k + w + 1])[::-1])
            for loop in f.loops:
                co = loop.vert.co
                loop[uv].uv = ((co.x + SIZE[0] / 2) / SIZE[0], (co.y + SIZE[1] / 2) / SIZE[1])
    mat = ground_material()
    return mesh_object("Chão do parque", bm, mat, smooth=True)


def ground_material():
    """Grama e terra batida misturadas pela máscara das trilhas (gerada aqui, com borda irregular)."""
    res = (int(SIZE[0] * 40), int(SIZE[1] * 40))
    yy, xx = np.mgrid[0:res[1], 0:res[0]].astype(np.float32)
    # Linha 0 da imagem = v 0 = sul (Blender y = -z da Godot).
    gx = (xx + .5) / res[0] * SIZE[0] - SIZE[0] / 2
    gz = SIZE[1] / 2 - (yy + .5) / res[1] * SIZE[1]
    dist = np.full(gx.shape, 1e9, np.float32)
    for path in D["paths"]:
        pts = np.array(path, np.float32)
        for a, b in zip(pts[:-1], pts[1:]):
            ab = b - a
            t = np.clip(((gx - a[0]) * ab[0] + (gz - a[1]) * ab[1]) / max(float(ab @ ab), 1e-6), 0, 1)
            dx = gx - (a[0] + ab[0] * t)
            dz = gz - (a[1] + ab[1] * t)
            dist = np.minimum(dist, np.sqrt(dx * dx + dz * dz))
    for door in D["doors"]:
        fx, _, fz = door["front"]
        dist = np.minimum(dist, np.sqrt((gx - fx) ** 2 + (gz - fz + .4) ** 2) - 0.9)
    wobble = np.sin(gx * 2.3 + np.sin(gz * 1.7) * 2) * .12 + np.sin(gz * 3.1 + gx * .7) * .08
    half = D["path_width"] * .5 + .35
    mask = np.clip((half + wobble - dist) / .35, 0, 1)
    img = bpy.data.images.new("Mascara das trilhas", res[0], res[1])
    # G: grama gasta (mais escura e amarelada) numa faixa em volta das trilhas.
    worn = np.clip((half + 1.0 + wobble - dist) / 1.0, 0, 1)
    img.colorspace_settings.name = "Non-Color"  # antes dos pixels: trocar depois apaga a imagem
    img.pixels = np.dstack([mask, worn, mask, np.ones_like(mask)]).ravel()
    img.filepath_raw = os.path.join(WORK, "path_mask.png")
    img.file_format = "PNG"
    img.save()
    m = bpy.data.materials.new("Chão")
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = .92
    tex_mask = nt.nodes.new("ShaderNodeTexImage")
    tex_mask.image = img
    tex_mask.interpolation = "Linear"
    coord = nt.nodes.new("ShaderNodeTexCoord")
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (SIZE[0] / 4, SIZE[1] / 4, 1)
    nt.links.new(coord.outputs["UV"], mapping.inputs["Vector"])
    grass = nt.nodes.new("ShaderNodeTexImage")
    grass.image = bpy.data.images.load(os.path.join(ROOT, "core/world/art/grass_albedo.png"))
    dirt = nt.nodes.new("ShaderNodeTexImage")
    dirt.image = bpy.data.images.load(os.path.join(ROOT, "core/world/art/dirt_albedo.png"))
    for t in (grass, dirt):
        nt.links.new(mapping.outputs["Vector"], t.inputs["Vector"])
    nt.links.new(coord.outputs["UV"], tex_mask.inputs["Vector"])
    # Terra clara e quente como na referência; grama verde viva.
    tones = []
    for tex, hue, sat, val in ((grass, .54, 1.45, 1.25), (dirt, .5, .95, 2.2)):
        hsv = nt.nodes.new("ShaderNodeHueSaturation")
        hsv.inputs["Hue"].default_value = hue
        hsv.inputs["Saturation"].default_value = sat
        hsv.inputs["Value"].default_value = val
        nt.links.new(tex.outputs["Color"], hsv.inputs["Color"])
        tones.append(hsv)
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(tex_mask.outputs["Color"], sep.inputs["Color"])
    worn = nt.nodes.new("ShaderNodeMix")
    worn.data_type = "RGBA"
    worn.blend_type = "MULTIPLY"
    worn.inputs[7].default_value = (.85, .78, .55, 1)
    nt.links.new(sep.outputs["Green"], worn.inputs["Factor"])
    nt.links.new(tones[0].outputs["Color"], worn.inputs[6])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    nt.links.new(sep.outputs["Red"], mix.inputs["Factor"])
    nt.links.new(worn.outputs[2], mix.inputs[6])
    nt.links.new(tones[1].outputs["Color"], mix.inputs[7])
    nt.links.new(mix.outputs[2], bs.inputs["Base Color"])
    return m


# ---------------------------------------------------------------- câmera, luz e saída
def camera():
    data = bpy.data.cameras.new("Câmera do mapa")
    data.type = "ORTHO"
    width = SPAN_X[1] - SPAN_X[0]
    height = SPAN_V[1] - SPAN_V[0]
    data.ortho_scale = max(width, height)
    data.clip_start = 1.0
    data.clip_end = 200.0
    cam = link(bpy.data.objects.new("Câmera do mapa", data))
    center_g = RIGHT * ((SPAN_X[0] + SPAN_X[1]) / 2) + UP_G * ((SPAN_V[0] + SPAN_V[1]) / 2) - FWD_G * CAMERA_BACK
    cam.location = g2b(*center_g)
    cam.rotation_euler = (math.pi / 2 - PITCH, 0, 0)
    scene = bpy.context.scene
    scene.camera = cam
    scene.render.resolution_x = round(width * PPM)
    scene.render.resolution_y = round(height * PPM)
    scene.render.resolution_percentage = 100
    return center_g


def render_settings():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = {"final": 48, "medium": 24}.get(MODE, 16)
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.render.threads_mode = "AUTO"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = .4
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("Noite")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = srgb("0b1a28")
    world.node_tree.nodes["Background"].inputs[1].default_value = .9
    scene.world = world
    vl = scene.view_layers[0]
    vl.use_pass_position = True
    # Nós do compositor: grava a posição (mundo) num EXR à parte.
    scene.use_nodes = True
    nt = scene.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    rl = nt.nodes.new("CompositorNodeRLayers")
    comp = nt.nodes.new("CompositorNodeComposite")
    # Brilho em volta das lâmpadas (bloom), já gravado na imagem.
    glare = nt.nodes.new("CompositorNodeGlare")
    glare.glare_type = "BLOOM" if "BLOOM" in [i.identifier for i in glare.bl_rna.properties["glare_type"].enum_items] else "FOG_GLOW"
    for key, value in (("Threshold", 1.2), ("Strength", .55), ("Size", .5)):
        if key in glare.inputs:
            glare.inputs[key].default_value = value
    nt.links.new(rl.outputs["Image"], glare.inputs["Image"])
    nt.links.new(glare.outputs["Image"], comp.inputs["Image"])
    out = nt.nodes.new("CompositorNodeOutputFile")
    out.base_path = WORK
    out.format.file_format = "OPEN_EXR"
    out.format.color_depth = "32"
    out.file_slots[0].path = "position_"
    nt.links.new(rl.outputs["Position"], out.inputs[0])


def moon():
    """Luar azulado de trás e um calor geral de frente (a noite de festa da referência é bem iluminada)."""
    for name, energy, color, rot in (("Luar", .5, (.55, .72, 1.0), (40, -25, 160)),
            ("Calor do parque", .5, (1.0, .7, .42), (55, 18, -15))):
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.color = color
        data.angle = math.radians(8)
        obj = link(bpy.data.objects.new(name, data))
        obj.rotation_euler = tuple(math.radians(v) for v in rot)


def finish(center_g):
    scene = bpy.context.scene
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(WORK, exist_ok=True)
    scene.render.filepath = os.path.join(WORK, "color.png")
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "park.blend"))
    bpy.ops.render.render(write_still=True)
    pos = bpy.data.images.load(os.path.join(WORK, "position_0001.exr"))
    w, h = pos.size
    p = np.array(pos.pixels[:], np.float32).reshape(h, w, 4)[::-1]
    # Posição Blender -> Godot, profundidade ao longo da câmera a partir do centro dela.
    pg = np.stack([p[..., 0], p[..., 2], -p[..., 1]], -1)
    hit = np.abs(p[..., :3]).sum(-1) > 1e-6
    depth = (pg - np.array(center_g)) @ np.array(FWD_G)
    depth = np.where(hit, depth, DEPTH_FAR)
    q = np.clip((depth - DEPTH_NEAR) / (DEPTH_FAR - DEPTH_NEAR), 0, 1)
    q = np.round(q * 65535).astype(np.int64)
    hi, lo = (q // 256) / 255.0, (q % 256) / 255.0
    # Metade da resolução basta para a profundidade (o contorno da cor continua inteiro).
    hi, lo = hi[::2, ::2], lo[::2, ::2]
    img = bpy.data.images.new("park_depth", hi.shape[1], hi.shape[0])
    img.colorspace_settings.name = "Non-Color"
    img.pixels = np.dstack([hi, lo, np.zeros_like(hi), np.ones_like(hi)])[::-1].ravel()
    img.filepath_raw = os.path.join(OUT, "park_depth.png")
    img.file_format = "PNG"
    img.save()
    shutil.copyfile(os.path.join(WORK, "color.png"), os.path.join(OUT, "park_color.png"))
    data = {"origin": list(center_g), "size": [SPAN_X[1] - SPAN_X[0], SPAN_V[1] - SPAN_V[0]],
        "depth_range": [DEPTH_NEAR, DEPTH_FAR], "span_x": list(SPAN_X), "span_v": list(SPAN_V)}
    with open(os.path.join(OUT, "park_backdrop_data.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("extends RefCounted\n## Gerado por tools/blender/park_render.py: onde a imagem do parque fica no mundo.\n")
        f.write("const DATA := " + json.dumps(data) + "\n")
    print("PARK_RENDER", MODE, w, h, json.dumps(data), flush=True)


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    render_settings()
    center = camera()
    terrain()
    moon()
    scenery()
    finish(center)


def scenery():
    import park_scene
    park_scene.Park(D, ground, path_distance, ROOT, WORK).build()


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
main()
