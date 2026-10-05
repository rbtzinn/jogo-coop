"""Cenografia de Respeitável Público. Blender 4.5, sem dependências ou assets externos.

blender --background --factory-startup --python tools/blender/visual_remap.py -- menu|arenas|landmarks
PNG: luz/sombra renderizadas antes do jogo. GLB: uma malha, materiais compartilhados,
sem luzes ou colisões exportadas. Medidas do gameplay ficam no Godot.
"""
import bpy
import math
import os
import random
import sys
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
ART = os.path.join(ROOT, "components/stage/art/remap")
MODELS = os.path.join(ROOT, "core/world/models/remap")
PALETTE = {"night": "101d28", "teal": "255762", "red": "792f40", "gold": "bb8b46",
           "ivory": "e8dac0", "wood": "53372d", "dark": "19202b", "glow": "ffc87a"}
MATS = {}

def linear(v):
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4

def mat(name):
    if name in MATS:
        return MATS[name]
    code = PALETTE.get(name, name)
    color = tuple(linear(int(code[i:i+2], 16)/255) for i in (0, 2, 4)) + (1,)
    m = bpy.data.materials.new(name)
    m.diffuse_color = color
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = color
    bs.inputs["Roughness"].default_value = .76
    if name == "gold":
        bs.inputs["Metallic"].default_value = .4
    if name == "glow":
        bs.inputs["Emission Color"].default_value = color
        bs.inputs["Emission Strength"].default_value = 2.5
    MATS[name] = m
    return m

def assign(obj, material):
    obj.data.materials.append(mat(material))
    return obj

def box(name, pos, scale, material="wood", bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(obj, material)
    if bevel:
        mod = obj.modifiers.new("Aresta pintada", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
        obj.modifiers.new("Normais", "WEIGHTED_NORMAL")
    return obj

def sphere(name, pos, scale, material="gold", segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=8, radius=1, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    assign(obj, material)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj

def cylinder(name, pos, radius, depth, material="gold", top=None, vertices=24):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
        radius2=radius if top is None else top, depth=depth, location=pos)
    obj = bpy.context.object
    obj.name = name
    assign(obj, material)
    for face in obj.data.polygons:
        face.use_smooth = len(face.vertices) == 4
    return obj

def torus(name, pos, radius, minor=.04, material="gold", rotate=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=8,
        major_radius=radius, minor_radius=minor, location=pos)
    obj = bpy.context.object
    obj.name = name
    if rotate:
        obj.rotation_euler = rotate
    assign(obj, material)
    return obj

def curve(name, points, material="gold", radius=.03):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.resolution_u = 1
    data.bevel_depth = radius
    data.bevel_resolution = 1
    spline = data.splines.new("POLY")
    spline.points.add(len(points)-1)
    for p, co in zip(spline.points, points):
        p.co = (*co, 1)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    assign(obj, material)
    return obj

def star(pos, radius=.18, material="gold"):
    x,y,z = pos
    pts = []
    for i in range(10):
        a = math.pi/2 + i*math.pi/5
        r = radius if i%2 == 0 else radius*.43
        pts.append((x+math.cos(a)*r,y,z+math.sin(a)*r))
    mesh = bpy.data.meshes.new("Estrela")
    mesh.from_pydata(pts, [], [list(range(10))])
    obj = bpy.data.objects.new("Estrela", mesh)
    bpy.context.collection.objects.link(obj)
    assign(obj, material)
    return obj

def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def light(name, pos, color, energy, size=6):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = (Vector((2,2,3))-obj.location).to_track_quat("-Z", "Y").to_euler()

def render(name, target=(0,0,5.4), location=(0,-25,5.4), ortho=19.2):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.cycles.device = "CPU"
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 6
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("Noite de estreia")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (.04,.065,.10,1)
    world.node_tree.nodes["Background"].inputs[1].default_value = .65
    scene.world = world
    light("Ribalta", (0,-6,9), (1,.66,.33), 1800)
    light("Luar", (-6,0,7), (.25,.58,.8), 1400)
    light("Recorte", (7,4,7), (1,.38,.2), 2200, 4)
    data = bpy.data.cameras.new("Camera")
    data.type = "ORTHO"
    data.ortho_scale = ortho
    cam = bpy.data.objects.new("Camera", data)
    bpy.context.collection.objects.link(cam)
    cam.location = location
    cam.rotation_euler = (Vector(target)-cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.filepath = os.path.join(ART, name+".png")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,"build",name+".blend"))
    bpy.ops.render.render(write_still=True)
    print("REMAP_RENDER", scene.render.filepath, flush=True)

def arch(x,y,z,width,height):
    for side in (-1,1):
        box("Coluna", (x+side*width/2,y,z+height*.36), (.26,.42,height*.72), "teal", .035)
        box("Capitel", (x+side*width/2,y,z+height*.7), (.5,.55,.12), "gold", .025)
        box("Base", (x+side*width/2,y,z+.13), (.5,.55,.24), "gold", .025)
    pts = [(x+math.cos(math.pi*i/32)*width/2,y-.03,z+height*.7+math.sin(math.pi*i/32)*height*.3) for i in range(33)]
    curve("Arco",pts,"gold",.12)

def curtain(x,y,bottom,height,width,material="red"):
    # Tecido contínuo com pregas, bainha e ondulação suave, em vez de gomos soltos.
    verts=[]; faces=[]
    nx=72; nz=12
    for j in range(nz+1):
        v=j/nz
        for i in range(nx+1):
            u=i/nx
            verts.append((x+(u-.5)*width, y+.13*math.cos(u*math.tau*9)*(1+.2*(1-v)),
                bottom+v*height+.025*math.sin(u*math.tau*9)*(1-v)))
    for j in range(nz):
        for i in range(nx):
            k=j*(nx+1)+i
            faces.append((k,k+1,k+nx+2,k+nx+1))
    mesh=bpy.data.meshes.new("Veludo")
    mesh.from_pydata(verts,[],faces)
    obj=bpy.data.objects.new("Veludo",mesh)
    bpy.context.collection.objects.link(obj)
    assign(obj,material)
    for p in mesh.polygons: p.use_smooth=True
    curve("Bainha",[(x+(i/nx-.5)*width,y-.02+.13*math.cos(i/nx*math.tau*9),bottom+.07) for i in range(nx+1)],"gold",.022)
    curve("Cordão",[(x-width*.48,y-.2,bottom+height*.62),(x,y-.3,bottom+height*.55),
        (x+width*.48,y-.2,bottom+height*.62)],"gold",.045)
    for side in (-1,1):
        cylinder("Borla",(x+side*width*.42,y-.22,bottom+height*.5),.07,.32,"gold",top=.035)

def theatre(kind="menu"):
    reset()
    box("Fundo",(0,7,5.4),(23,.35,12),"night")
    box("Palco",(0,1,.4),(23,18,.7),"wood",.03)
    for i in range(36):
        x = (i-18)*.62
        box("Tabua",(x,1,.765),(.59,17,.035),"wood" if i%3 else "dark")
        for j in (-3,1,5):
            sphere("Prego",(x+.23,j,.79),(.014,.014,.004),"gold",8)
    box("Friso",(0,-3.8,.72),(22,.10,.12),"gold",.02)
    for side in (-1,1):
        arch(side*8.2,1.8,1,2.3,7.5)
        curtain(side*8.5,2.8,1.0,8.5,2.8)
        cylinder("Coluna cênica",(side*9.2,1,4.4),.25,8,"teal")
        for z in (1,1.5,7.8,8.3):
            cylinder("Friso latão",(side*9.2,1,z),.32,.12,"gold")
    for i in range(13):
        x=(i-6)*1.5
        sphere("Lambrequim",(x,2.0,10.1),(.84,.38,.9),"red")
        sphere("Roseta",(x,1.56,9.5),(.10,.06,.10),"gold")
        sphere("Lampada",(x,1.5,9.25),(.07,.06,.07),"glow")
    for side in (-1,1):
        for row in range(3):
            box("Arquibancada",(side*5.6,5.3,1.25+row*.38),(5.2,1.1,.18),"red",.04)
            for i in range(9):
                sphere("Publico assombrado",(side*5.6+(i-4)*.45,5.4,1.6+row*.38),(.13,.12,.18),"dark")
    # A área central fica limpa; os ataques continuam sendo a informação mais contrastante.
    if kind == "tamer":
        for side in (-1,1):
            x=side*6.7
            for i in range(11):
                cylinder("Barra da jaula",(x+(i-5)*.19,4.6,2.4),.024,2.9,"gold",vertices=8)
            box("Travessa",(x,4.6,3.8),(2.4,.10,.10),"gold")
            sphere("Juba",(x,4.3,4.5),(.85,.19,.88),"gold")
            sphere("Leao",(x,4.0,4.5),(.52,.13,.58),"wood")
            for dx in (-.2,.2):
                sphere("Olho",(x+dx,3.83,4.65),(.055,.05,.055),"glow")
            cylinder("Altar",(side*7,3,1.1),.48,.65,"red")
            cylinder("Chama",(side*7,3,1.72),.22,.65,"glow",top=0)
    elif kind == "jugglers":
        for side in (-1,1):
            x=side*6.4
            torus("Roda de equilibrio",(x,4.0,4.4),1.2,.09,"gold",(math.pi/2,0,0))
            for i in range(12):
                a=i*math.tau/12
                curve("Raio",[(x,4.0,4.4),(x+math.cos(a)*1.18,4.0,4.4+math.sin(a)*1.18)],"gold",.025)
            for i in range(3):
                sphere("Bola",(x+(i-1)*.53,3.8,6.2+(.3 if i==1 else 0)),(.24,.24,.24),["teal","gold","red"][i])
            box("Painel listrado",(x,5.4,3.8),(3,.15,4),"teal" if side<0 else "red",.04)
    elif kind == "magician":
        for side in (-1,1):
            x=side*6.4
            torus("Astrolabio",(x,4.2,4.9),1.25,.07,"gold",(math.pi/2,0,0))
            torus("Astrolabio interno",(x,4.1,4.9),.91,.025,"gold",(math.pi/2,0,0))
            for i in range(10):
                a=i*math.tau/10
                star((x+math.cos(a)*1.55,4,4.9+math.sin(a)*1.55),.13)
            cylinder("Cartola",(x,3.5,1.45),.65,1.1,"dark",top=.75)
            cylinder("Aba",(x,3.5,.92),1.0,.09,"dark")
            cylinder("Faixa",(x,3.5,1.13),.68,.22,"red")
        for i in range(17):
            star(((i-8)*.65,6.5,7.3+.3*math.sin(i)),.07)
    elif kind == "menu":
        # Bilheteria e picadeiro assimétricos: à esquerda fica espaço real para o menu.
        curtain(-5.7,-.6,.8,9.2,6.8,"night")
        for x in (1.3,6.9):
            arch(x,3,.9,4,7.6)
        cylinder("Picadeiro",(3.8,.5,.86),3.0,.22,"teal",vertices=64)
        torus("Borda",(3.8,.5,1),2.9,.07,"gold")
        for i in range(12):
            a=i*math.tau/12
            star((3.8+math.cos(a)*2.75,-.4,1.2+math.sin(a)*.28),.10)
        box("Bilheteria",(7,-.3,2.0),(2.0,1.0,2.4),"red",.06)
        box("Balcao",(7,-.6,2.7),(2.25,1.4,.16),"gold",.04)
        arch(7,-.3,2.9,1.8,2.4)
        box("Bilhetes",(7,-1.32,2.2),(1.0,.04,.43),"ivory",.02)
        for i in range(5):
            sphere("Lampada",(7+(i-2)*.38,-.7,5.2),(.07,.07,.07),"glow")
        # Um pequeno circo dentro do teatro, com lona modelada.
        tent(3.8,3.0,1.05,1.55,2.15,"red")
    render(kind)

def tent(x,y,z,radius,height,color="red"):
    n=48
    verts=[]; faces=[]
    for zz,rr in ((z,radius),(z+height*.52,radius),(z+height*.59,radius*1.10),(z+height,0.02)):
        for i in range(n):
            a=math.tau*i/n
            verts.append((x+math.cos(a)*rr,y+math.sin(a)*rr,zz))
    for row in range(3):
        for i in range(n):
            faces.append((row*n+i,row*n+(i+1)%n,(row+1)*n+(i+1)%n,(row+1)*n+i))
    mesh=bpy.data.meshes.new("Lona listrada")
    mesh.from_pydata(verts,[],faces)
    obj=bpy.data.objects.new("Lona listrada",mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(mat(color)); mesh.materials.append(mat("ivory"))
    for p in mesh.polygons:
        p.material_index=(p.index % n)//4%2
    for i in range(12):
        a=math.tau*i/12
        curve("Costura dourada",[(x+math.cos(a)*radius*1.10,y+math.sin(a)*radius*1.10,z+height*.59),
            (x,y,z+height)],"gold",.018)
    cylinder("Coroa",(x,y,z+height+.10),.035,.28,"gold",vertices=8)
    for i in range(24):
        a=math.tau*i/24
        sphere("Luz da lona",(x+math.cos(a)*radius*1.04,y+math.sin(a)*radius*1.04,z+height*.55),(.045,.045,.045),"glow",8)
    # Frente no Blender -y = +z no Godot.
    curtain(x-radius*.34,y-radius*.97,z+.04,height*.48,radius*.42)
    curtain(x+radius*.34,y-radius*.97,z+.04,height*.48,radius*.42)
    box("Porta",(x,y-radius,z+height*.20),(radius*.34,.06,height*.4),"night")
    cylinder("Base pintada",(x,y,z+.045),radius*1.04,.09,"teal",vertices=48)

def export_glb(name):
    # Curvas e detalhes reunidos numa única malha. No máximo oito superfícies compartilhadas.
    bpy.ops.object.select_all(action="DESELECT")
    objects=[o for o in bpy.context.scene.objects if o.type in {"MESH","CURVE"}]
    for o in objects: o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    # Unifica referências iguais a materiais depois do join.
    slots=list(obj.data.materials)
    unique=[]; mapping={}
    for i,m in enumerate(slots):
        if m not in unique: unique.append(m)
        mapping[i]=unique.index(m)
    indices=[mapping[p.material_index] for p in obj.data.polygons]
    obj.data.materials.clear()
    for m in unique: obj.data.materials.append(m)
    for p,idx in zip(obj.data.polygons,indices): p.material_index=idx
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,"build",name+".blend"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(MODELS,name+".glb"),export_format="GLB",
        use_selection=True,export_cameras=False,export_lights=False,export_yup=True)
    print("REMAP_MODEL",name,len(obj.data.vertices),len(unique),flush=True)

def landmarks():
    for name,radius,height,color in (("tamer",2.2,4.4,"red"),("jugglers",2.2,4.4,"teal"),("magician",3.1,5.9,"teal")):
        reset(); tent(0,0,0,radius,height,color)
        if name=="tamer":
            sphere("Medalhao leao",(0,-radius-.03,2.0),(.6,.13,.66),"gold")
            sphere("Focinho",(0,-radius-.17,1.97),(.37,.12,.39),"wood")
            for x in (-.15,.15): sphere("Olho",(x,-radius-.3,2.11),(.04,.04,.04),"glow")
        elif name=="jugglers":
            for side in (-1,1):
                sphere("Bola",(side*radius*.73,-radius*.73,2.5),(.22,.22,.22),"gold")
                cylinder("Clava",(side*radius*.73,-radius*.73,1.9),.14,.8,"gold",top=.05)
        else:
            for i in range(9):
                a=math.pi*(i/8)
                star((math.cos(a)*1.3,-radius-.02,2.3+math.sin(a)*1.4),.15)
        export_glb(name)
    for name in ("shop","dressing","station"):
        reset()
        if name=="station":
            box("Plataforma",(0,0,.2),(4.6,1.8,.4),"wood",.04)
            for x in (-2,2): box("Pilar",(x,.45,1.6),(.16,.16,2.5),"teal",.02)
            box("Cobertura",(0,.45,2.9),(4.8,2.0,.18),"red",.04)
            for x in (-2,-1,0,1,2): sphere("Luz",(x,-.5,2.7),(.06,.06,.06),"glow")
            for x in (-1,1): box("Banco",(x,.3,.65),(1.6,.5,.12),"teal",.03)
        else:
            width=3.6 if name=="shop" else 3.2
            color="teal" if name=="shop" else "red"
            box("Carrocao",(0,0,1.3),(width,1.8,2.0),color,.05)
            box("Teto",(0,0,2.4),(width+.24,2.0,.22),"gold",.08)
            for x in (-width*.35,width*.35):
                for y in (-.9,.9):
                    torus("Roda",(x,y,.45),.38,.07,"wood",(math.pi/2,0,0))
                    cylinder("Calota",(x,y,.45),.13,.06,"gold").rotation_euler.x=math.pi/2
            for x in (-width*.37,width*.37):
                box("Moldura",(x,-.94,1.6),(.66,.07,.95),"gold",.03)
                box("Vidro",(x,-.99,1.6),(.52,.035,.78),"night",.02)
            if name=="shop":
                box("Balcao",(0,-1.28,1.15),(2.9,.75,.13),"wood",.03)
                for i in range(7): sphere("Mercadoria",((i-3)*.37,-1.18,1.4),(.10,.1,.15),["red","gold","teal"][i%3])
            else:
                box("Porta",(0,-.95,1.4),(.78,.06,1.6),"wood",.02)
                star((0,-1.0,1.9),.22)
            for i in range(9):
                sphere("Lampada",((i-4)*width/9,-1.04,2.25),(.04,.04,.04),"glow",8)
        export_glb(name)

if __name__ == "__main__":
    os.makedirs(ART,exist_ok=True); os.makedirs(MODELS,exist_ok=True)
    mode=sys.argv[sys.argv.index("--")+1] if "--" in sys.argv else "menu"
    if mode=="menu": theatre("menu")
    elif mode=="arenas":
        for name in ("tamer","jugglers","magician"): theatre(name)
    elif mode=="landmarks": landmarks()
    else: raise ValueError(mode)
