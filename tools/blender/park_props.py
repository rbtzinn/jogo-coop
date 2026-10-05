"""Atrações e enfeites do parque (usados por tools/blender/park_render.py).

Cada função recebe um ponto no chão do Blender (Vector) e o giro; a frente fica para -y (sul).
As medidas das atrações acompanham as colisões das portas na Godot (build/park/layout.json).
"""
import math
import random
from mathutils import Vector
from park_kit import Geo, mat, stripes, linear_stripes, rings, decal, point_light, area_light, T, R, S

LAMP_COLOR = (1.0, .64, .34)


def frame(at, yaw=0.0):
    return T(*at) @ R(yaw)


# ---------------------------------------------------------------- tendas
def tent(name, at, radius, wall, roof, fabric, trim="gold", emblem=None, emblem_size=(1.6, 1.4), bulbs=True,
         valance="canvas_red", seed=1):
    """Tenda redonda: parede listrada, teto côncavo, lambrequim recortado, entrada com cortinas abertas."""
    g = Geo(name, at)
    M = frame(at)
    n = 64
    # Parede (sem tampa) e o chão de dentro, escuro.
    g.cyl(fabric, M @ T(0, 0, wall / 2), radius, radius, wall, seg=n, cap=False)
    # Teto: anéis cada vez mais íngremes perto do mastro.
    profile = [(radius * 1.06 * (1 - t), wall + roof * (t ** 1.6)) for t in [i / 8 for i in range(9)]]
    verts, faces = [], []
    for k, (rr, zz) in enumerate(profile):
        sag = 0
        for i in range(n):
            a = math.tau * i / n
            # Lona caída entre as varetas (16 gomos).
            dip = .05 * radius * (1 - abs(math.cos(a * 8))) * math.sin(math.pi * k / 8)
            verts.append(M @ Vector((math.cos(a) * rr, math.sin(a) * rr, zz - dip)))
    for k in range(len(profile) - 1):
        for i in range(n):
            a0, a1 = k * n + i, k * n + (i + 1) % n
            faces.append((a0, a1, a1 + n, a0 + n))
    g.poly(fabric, verts, faces, smooth=True)
    # Lambrequim: faixa com a borda de baixo em arcos e um cordão dourado.
    scallops = 16
    top, depth = wall + .02, .55
    vv, ff = [], []
    m = scallops * 8
    for i in range(m + 1):
        a = math.tau * i / m
        r_ = radius * 1.075
        lobe = abs(math.sin(math.pi * (i % 8) / 8))
        vv.append(M @ Vector((math.cos(a) * r_, math.sin(a) * r_, top)))
        vv.append(M @ Vector((math.cos(a) * r_, math.sin(a) * r_, top - depth * (.45 + .55 * lobe))))
    for i in range(m):
        ff.append((2 * i, 2 * i + 2, 2 * i + 3, 2 * i + 1))
    g.poly(mat(valance), vv, ff, smooth=True)
    edge = [M @ Vector((math.cos(math.tau * i / m) * radius * 1.085, math.sin(math.tau * i / m) * radius * 1.085,
        top - depth * (.45 + .55 * abs(math.sin(math.pi * (i % 8) / 8))))) for i in range(m + 1)]
    g.tube(mat(trim), edge, .025, seg=5)
    g.torus(mat(trim), M @ T(0, 0, top), radius * 1.08, .045, seg=64)
    # Mastro, bola e bandeirinha.
    g.cyl(mat("wood_dark"), M @ T(0, 0, wall + roof + .45), .05, .04, .9, seg=8)
    g.sphere(mat("gold"), M @ T(0, 0, wall + roof + .95), .12)
    g.poly(mat("canvas_red"), [M @ Vector(p) for p in ((0, 0, wall + roof + .85), (.55, -.05, wall + roof + .72),
        (0, 0, wall + roof + .58))], [(0, 1, 2)])
    # Entrada: vão escuro e quente, cortinas presas dos lados, arco dourado com lâmpadas.
    door_w, door_h = radius * .55, wall * .92
    front = -radius - .02
    g.quad(mat("interior"), M @ Vector((0, front + .01, door_h / 2)), M.to_3x3() @ Vector((door_w / 2, 0, 0)),
        M.to_3x3() @ Vector((0, 0, door_h / 2)))
    for side in (-1, 1):
        pts = []
        for j in range(9):
            t = j / 8
            x = side * (door_w / 2 + .05 - .28 * math.sin(math.pi * t) * (1 - t * .3))
            pts.append(M @ Vector((x, front - .06, door_h * (1 - t))))
        g.tube(mat("curtain"), pts, .17, seg=8)
    arch = []
    for i in range(17):
        a = math.pi * i / 16
        arch.append(M @ Vector((math.cos(a) * (door_w / 2 + .12), front - .1, door_h * .78 + math.sin(a) * .45)))
    g.tube(mat(trim), arch, .045, seg=6)
    for side in (-1, 1):
        g.tube(mat(trim), [M @ Vector((side * (door_w / 2 + .12), front - .1, 0)),
            M @ Vector((side * (door_w / 2 + .12), front - .1, door_h * .78))], .045, seg=6)
    if bulbs:
        for p in arch[::2]:
            g.sphere(mat("bulb"), T(*(p + Vector((0, -.05, 0)))), .055, seg=8, rings_=5)
        for i in range(32):
            a = math.tau * i / 32
            g.sphere(mat("bulb"), M @ T(math.cos(a) * radius * 1.1, math.sin(a) * radius * 1.1, top - .62), .045,
                seg=8, rings_=5)
    if emblem:
        ew, eh = emblem_size
        g.quad(decal(emblem[0], emblem[1]), M @ Vector((0, front - .2, door_h + eh * .32)),
            M.to_3x3() @ Vector((ew / 2, 0, 0)), M.to_3x3() @ Vector((0, 0, eh / 2)))
    obj = g.commit()
    # Luz de dentro, saindo pela entrada.
    point_light(name + " luz", M @ Vector((0, -radius * .45, door_h * .55)), 320, LAMP_COLOR, .5)
    return obj


# ---------------------------------------------------------------- carroções
def wagon(name, at, yaw, length, depth, height, body="paint_red", trim="gold", roof="canvas_cream"):
    """Carroção de circo: caixa pintada com friso dourado, teto arredondado, janelas acesas, rodas."""
    g = Geo(name, at)
    M = frame(at, yaw)
    floor = .55
    g.box(mat(body), M @ T(0, 0, floor + height / 2), (length, depth, height))
    for z in (floor + .06, floor + height - .06):
        g.box(mat(trim), M @ T(0, 0, z), (length + .06, depth + .06, .1))
    for x in (-length / 2, length / 2):
        for y in (-depth / 2, depth / 2):
            g.box(mat(trim), M @ T(x, y, floor + height / 2), (.1, .1, height))
    # Teto em arco.
    n = 12
    verts, faces = [], []
    for i in range(n + 1):
        a = math.pi * i / n
        y = -math.cos(a) * (depth / 2 + .18)
        z = floor + height + math.sin(a) * .45
        verts.append(M @ Vector((-length / 2 - .2, y, z)))
        verts.append(M @ Vector((length / 2 + .2, y, z)))
    for i in range(n):
        faces.append((2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2))
    g.poly(mat(roof), verts, faces, smooth=True)
    for x in (-length / 2 - .2, length / 2 + .2):
        g.tube(mat(trim), [M @ Vector((x, -math.cos(math.pi * i / n) * (depth / 2 + .18),
            floor + height + math.sin(math.pi * i / n) * .45)) for i in range(n + 1)], .04)
    g.box(mat("wood_dark"), M @ T(0, 0, floor - .08), (length + .1, depth * .9, .16))
    # Rodas com raios.
    for x in (-length * .32, length * .32):
        for y in (-depth / 2 - .06, depth / 2 + .06):
            W = M @ T(x, y, .5) @ R(math.pi / 2, "X")
            g.torus(mat("wood_dark"), W, .42, .05, seg=20)
            g.cyl(mat("gold"), W, .09, .09, .12, seg=10)
            for k in range(8):
                a = math.tau * k / 8
                g.tube(mat("wood"), [W @ Vector((0, 0, 0)), W @ Vector((math.cos(a) * .4, math.sin(a) * .4, 0))],
                    .022, seg=4)
    return g, M, floor


def windows(g, M, xs, y, z, w=.55, h=.65):
    for x in xs:
        g.box(mat("gold"), M @ T(x, y, z), (w + .12, .06, h + .12))
        g.box(mat("window"), M @ T(x, y - .03, z), (w, .05, h))
        g.box(mat("wood_dark"), M @ T(x, y - .06, z), (.04, .03, h))
        g.box(mat("wood_dark"), M @ T(x, y - .06, z), (w, .03, .04))
        point_light("janela", M @ Vector((x, y - .5, z)), 35, LAMP_COLOR, .3)


def dressing_wagon(at):
    """Camarim: carroção vermelho com estrela, porta com escadinha e janelas acesas."""
    length, depth, height = 3.1, 1.75, 1.9
    g, M, floor = wagon("Camarim", at, 0, length, depth, height, roof="wood_dark")
    front = -depth / 2 - .02
    windows(g, M, (-.95, .95), front, floor + 1.15)
    g.box(mat("wood"), M @ T(0, front - .01, floor + .85), (.75, .05, 1.5))
    g.box(mat("gold"), M @ T(0, front - .03, floor + .85), (.85, .04, 1.6))
    g.box(mat("wood"), M @ T(0, front - .02, floor + .85), (.68, .05, 1.42))
    g.star(mat("gold"), M @ T(0, front - .07, floor + 1.25), .17)
    for k in range(3):
        g.box(mat("wood"), M @ T(0, front - .25 - k * .22, floor - .12 - k * .17), (.8, .26, .06))
    g.sphere(mat("glass_warm"), M @ T(.55, front - .12, floor + 1.75), .08)
    return g.commit()


def shop_wagon(at, sign_decal):
    """Cartomante (loja): carroção com toldo listrado, balcão, bola de cristal e prateleiras."""
    length, depth, height = 3.3, 1.9, 1.95
    g, M, floor = wagon("Cartomante", at, 0, length, depth, height, body="paint_teal", roof="canvas_red")
    front = -depth / 2 - .02
    # Abertura da vitrine: fundo quente, prateleiras com vidros coloridos.
    g.box(mat("interior"), M @ T(0, front, floor + 1.05), (2.3, .04, 1.05))
    for z in (floor + .72, floor + 1.15, floor + 1.55):
        g.box(mat("wood"), M @ T(0, front - .08, z), (2.3, .22, .05))
    rng = random.Random(9)
    for z in (floor + .75, floor + 1.18):
        for i in range(10):
            x = -1.05 + i * .235
            kind = rng.choice(["bottle_green", "bottle_amber", "bottle_violet", "gold"])
            hgt = rng.uniform(.12, .24)
            g.cyl(mat(kind), M @ T(x, front - .1, z + hgt / 2 + .02), .045, .03, hgt, seg=8)
    # Balcão e bola de cristal.
    g.box(mat("wood_dark"), M @ T(0, front - .45, floor + .25), (2.6, .55, .7))
    g.box(mat("gold"), M @ T(0, front - .45, floor + .62), (2.7, .62, .06))
    g.cyl(mat("gold"), M @ T(.2, front - .45, floor + .72), .1, .14, .14, seg=10)
    g.sphere(mat("crystal"), M @ T(.2, front - .45, floor + .9), .16, seg=16, rings_=10)
    point_light("bola de cristal", M @ Vector((.2, front - .7, floor + 1.0)), 25, (.55, .7, 1.0), .2)
    g.cyl(mat("glass_warm"), M @ T(-.75, front - .45, floor + .78), .06, .06, .18, seg=8)
    # Toldo listrado inclinado, com franja em arcos.
    aw_y0, aw_y1 = front, front - 1.05
    z0, z1 = floor + height + .05, floor + height - .55
    verts = [M @ Vector(p) for p in ((-1.55, aw_y0, z0), (1.55, aw_y0, z0), (1.55, aw_y1, z1), (-1.55, aw_y1, z1))]
    g.poly(linear_stripes("toldo_listrado", "a3252b", "eadbbd", .36), verts, [(0, 1, 2, 3)],
        [(-1.55, 0), (1.55, 0), (1.55, 1), (-1.55, 1)])
    for i in range(9):
        x0 = -1.55 + i * 3.1 / 9
        x1 = x0 + 3.1 / 9
        tri = [M @ Vector((x0, aw_y1, z1)), M @ Vector((x1, aw_y1, z1)), M @ Vector(((x0 + x1) / 2, aw_y1 - .02, z1 - .2))]
        g.poly(mat("canvas_red" if i % 2 else "canvas_cream"), tri, [(0, 1, 2)])
    for x in (-1.5, 1.5):
        g.tube(mat("wood_dark"), [M @ Vector((x, aw_y1, z1)), M @ Vector((x, aw_y1, 0))], .035)
    for i in range(7):
        g.sphere(mat("bulb"), M @ T(-1.35 + i * .45, aw_y1 - .03, z1 - .05), .045, seg=8, rings_=5)
    obj = g.commit()
    # Placa da cartomante num cavalete, ao lado.
    s = Geo("Placa da cartomante", M @ Vector((2.25, front - .9, 0)))
    E = M @ T(2.25, front - .9, 0)
    for x in (-.35, .35):
        s.tube(mat("wood"), [E @ Vector((x, .1, 0)), E @ Vector((x * .8, 0, 1.45))], .03)
    s.tube(mat("wood"), [E @ Vector((0, .35, 0)), E @ Vector((0, .05, 1.3))], .025)
    s.box(mat("wood_dark"), E @ T(0, -.02, .95) @ R(-.12, "X"), (.86, .05, 1.0))
    s.quad(decal("placa_cartomante", sign_decal), E @ Vector((0, -.08, .95)), E.to_3x3() @ Vector((.39, 0, 0)),
        E.to_3x3() @ R(-.12, "X").to_3x3() @ Vector((0, 0, .46)))
    s.commit()
    return obj


def clothes_rack(at, yaw=0.0):
    g = Geo("Arara de roupas", at)
    M = frame(at, yaw)
    for x in (-.8, .8):
        g.cyl(mat("wood_dark"), M @ T(x, 0, .8), .035, .035, 1.6, seg=8)
        g.box(mat("wood_dark"), M @ T(x, 0, .03), (.08, .5, .06))
    g.tube(mat("gold"), [M @ Vector((-.85, 0, 1.55)), M @ Vector((.85, 0, 1.55))], .025)
    colors = ["cloth_blue", "cloth_orange", "cloth_white", "cloth_purple", "canvas_red", "cloth_yellow"]
    for i, c in enumerate(colors):
        x = -.62 + i * .25
        g.tube(mat("iron"), [M @ Vector((x - .1, 0, 1.42)), M @ Vector((x, 0, 1.53)), M @ Vector((x + .1, 0, 1.42))], .008)
        top, bottom = 1.42, 1.42 - (.75 if i % 2 else .9)
        verts = [M @ Vector(p) for p in ((x - .11, -.03, top), (x + .11, -.03, top), (x + .14, -.05, bottom),
            (x - .14, -.05, bottom), (x - .11, .03, top), (x + .11, .03, top), (x + .14, .05, bottom), (x - .14, .05, bottom))]
        g.poly(mat(c), verts, [(0, 1, 2, 3), (5, 4, 7, 6), (1, 5, 6, 2), (4, 0, 3, 7)], smooth=False)
    return g.commit()


# ---------------------------------------------------------------- estação e trem
def station(at, rail_y, loco_x):
    """Plataforma 4,6 x 1,8 m (a colisão da porta do Trem), cobertura listrada, relógio e malas."""
    g = Geo("Estação", at)
    M = frame(at)
    h = .9
    g.box(mat("stone_dark"), M @ T(0, 0, h / 2 - .1), (4.6, 1.8, h + .2))
    g.box(mat("wood_light"), M @ T(0, 0, h + .02), (4.7, 1.9, .06))
    for i in range(16):
        g.box(mat("wood_dark"), M @ T(-2.3 + i * .3, 0, h + .055), (.02, 1.88, .01))
    g.box(mat("gold"), M @ T(0, -.96, h - .05), (4.72, .05, .1))
    # Cobertura só na metade oeste (a locomotiva aparece do outro lado): colunas verdes, toldo listrado.
    x0r, x1r = -2.4, .5
    for x in (-2.0, .2):
        for y in (-.65, .65):
            g.cyl(mat("lamp_green"), M @ T(x, y, h + 1.2), .06, .06, 2.4, seg=10)
    roof_z = h + 2.45
    for side in (-1, 1):
        verts = [M @ Vector(p) for p in ((x0r, 0, roof_z + .55), (x1r, 0, roof_z + .55), (x1r, side * 1.25, roof_z),
            (x0r, side * 1.25, roof_z))]
        g.poly(linear_stripes("toldo_listrado", "a3252b", "eadbbd", .36), verts, [(0, 1, 2, 3)],
            [(x0r, 0), (x1r, 0), (x1r, 1), (x0r, 1)])
    for i in range(9):
        x0 = x0r + i * (x1r - x0r) / 9
        x1 = x0 + (x1r - x0r) / 9
        tri = [M @ Vector((x0, -1.25, roof_z)), M @ Vector((x1, -1.25, roof_z)), M @ Vector(((x0 + x1) / 2, -1.27, roof_z - .22))]
        g.poly(mat("canvas_red" if i % 2 else "canvas_cream"), tri, [(0, 1, 2)])
    g.box(mat("gold"), M @ T((x0r + x1r) / 2, -1.25, roof_z + .02), (x1r - x0r + .05, .05, .06))
    for i in range(6):
        g.sphere(mat("bulb"), M @ T(x0r + .25 + i * .47, -1.2, roof_z - .08), .045, seg=8, rings_=5)
    # Relógio pendurado.
    C = M @ T(-1.1, -.9, roof_z - .45) @ R(math.pi / 2, "X")
    g.cyl(mat("clock_face"), C, .26, .26, .06, seg=24)
    g.torus(mat("gold"), C, .27, .03, seg=24)
    g.box(mat("ink"), M @ T(-1.1, -.94, roof_z - .38), (.02, .01, .16))
    g.box(mat("ink"), M @ T(-1.04, -.94, roof_z - .45) @ R(.9, "Y"), (.02, .01, .12))
    # Banco e malas.
    g.box(mat("wood"), M @ T(1.3, -.3, h + .45), (1.4, .4, .06))
    g.box(mat("wood"), M @ T(1.3, -.12, h + .7), (1.4, .05, .4))
    for x in (.7, 1.9):
        g.box(mat("iron"), M @ T(x, -.3, h + .22), (.05, .4, .45))
    for i, (x, c) in enumerate(((-1.8, "cloth_blue"), (-1.45, "loco_red"), (-1.6, "wood"))):
        hz = h + .2 + (.42 if i == 2 else 0)
        g.box(mat(c), M @ T(x, .3, hz), (.5, .3, .38))
        g.box(mat("gold"), M @ T(x, .3, hz + .2), (.16, .05, .04))
    obj = g.commit()
    point_light("estação luz", M @ Vector((-1.0, -.4, roof_z - .5)), 260, LAMP_COLOR, .6)
    return obj


def rails(points, ground):
    """Trilhos sobre brita: dormentes e dois trilhos seguindo os pontos (x, z da Godot)."""
    g = Geo("Trilhos", ground(*points[0]))
    for (x0, z0), (x1, z1) in zip(points[:-1], points[1:]):
        length = math.hypot(x1 - x0, z1 - z0)
        steps = max(int(length / .55), 1)
        for k in range(steps):
            t = (k + .5) / steps
            x, z = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
            yaw = math.atan2(-(z1 - z0), x1 - x0)
            p = ground(x, z)
            g.box(mat("wood_dark"), T(*p) @ R(yaw) @ T(0, 0, .06), (.18, 1.5, .1))
            g.box(mat("gravel"), T(*p) @ R(yaw) @ T(0, 0, .02), (.6, 1.9, .08))
    for side in (-.45, .45):
        line = []
        for (x0, z0), (x1, z1) in zip(points[:-1], points[1:]):
            yaw = math.atan2(-(z1 - z0), x1 - x0)
            n = Vector((-math.sin(yaw), math.cos(yaw), 0)) * side
            for k in range(6):
                t = k / 5
                line.append(ground(x0 + (x1 - x0) * t, z0 + (z1 - z0) * t) + n + Vector((0, 0, .15)))
        g.tube(mat("rail"), line, .04, seg=5)
    for (x, z) in (points[0], points[-1]):
        p = ground(x, z)
        g.box(mat("loco_red"), T(*p) @ T(0, 0, .45), (.3, 1.4, .5))
    return g.commit()


def locomotive(at, yaw):
    """Locomotiva preta e vermelha com aros dourados, farol aceso e tênder com carvão."""
    g = Geo("Locomotiva", at)
    M = frame(at, yaw)
    g.box(mat("loco_red"), M @ T(0, 0, .55), (4.4, 1.3, .22))
    B = M @ T(.55, 0, 1.25) @ R(math.pi / 2, "Y")
    g.cyl(mat("loco_black"), B, .55, .55, 2.6, seg=24)
    for x in (-.5, .25, 1.0, 1.75):
        g.torus(mat("gold"), M @ T(x, 0, 1.25) @ R(math.pi / 2, "Y"), .56, .035, seg=24)
    g.cyl(mat("loco_black"), M @ T(1.95, 0, 1.25) @ R(math.pi / 2, "Y"), .6, .6, .25, seg=24)
    g.cyl(mat("loco_black"), M @ T(1.65, 0, 2.05), .14, .26, .75, seg=12)
    g.torus(mat("gold"), M @ T(1.65, 0, 2.4), .26, .04, seg=16)
    g.sphere(mat("gold"), M @ T(.6, 0, 1.85), .22)
    g.cyl(mat("gold"), M @ T(2.1, 0, 1.7), .12, .16, .22, seg=10)
    g.sphere(mat("glass_warm"), M @ T(2.22, 0, 1.7), .11)
    # Cabine.
    g.box(mat("loco_red"), M @ T(-1.25, 0, 1.45), (1.2, 1.35, 1.5))
    g.box(mat("loco_black"), M @ T(-1.25, 0, 2.28), (1.45, 1.6, .14))
    for y in (-.69, .69):
        g.box(mat("window"), M @ T(-1.2, y, 1.65), (.55, .03, .45))
        g.box(mat("gold"), M @ T(-1.2, y, 1.65), (.65, .02, .55))
    g.box(mat("gold"), M @ T(-1.25, 0, .75), (1.25, 1.4, .06))
    # Limpa-trilhos.
    g.poly(mat("loco_red"), [M @ Vector(p) for p in ((2.2, -.6, .65), (2.2, .6, .65), (2.75, 0, .2), (2.75, 0, .2))],
        [(0, 1, 2)])
    g.poly(mat("loco_red"), [M @ Vector(p) for p in ((2.2, -.6, .65), (2.75, 0, .2), (2.2, -.6, .2))], [(0, 1, 2)])
    g.poly(mat("loco_red"), [M @ Vector(p) for p in ((2.2, .6, .65), (2.2, .6, .2), (2.75, 0, .2))], [(0, 1, 2)])
    # Rodas vermelhas com raios e a biela.
    for x, r in ((1.55, .32), (.55, .5), (-.45, .5), (-1.4, .32)):
        for y in (-.68, .68):
            W = M @ T(x, y, r) @ R(math.pi / 2, "X")
            g.torus(mat("loco_red"), W, r - .04, .05, seg=20)
            g.cyl(mat("gold"), W, .08, .08, .1, seg=10)
            for k in range(8):
                a = math.tau * k / 8
                g.tube(mat("loco_red"), [W @ Vector((0, 0, 0)), W @ Vector((math.cos(a) * (r - .05),
                    math.sin(a) * (r - .05), 0))], .025, seg=4)
    for y in (-.76, .76):
        g.box(mat("gold"), M @ T(.05, y, .55), (1.1, .03, .06))
    # Tênder.
    g.box(mat("loco_black"), M @ T(-2.95, 0, 1.05), (1.7, 1.3, 1.0))
    g.box(mat("gold"), M @ T(-2.95, 0, 1.56), (1.75, 1.35, .05))
    g.ico(mat("ink"), M @ T(-2.95, 0, 1.55) @ S(.8, .55, .22), 1.0, sub=2)
    for x in (-3.45, -2.45):
        for y in (-.68, .68):
            W = M @ T(x, y, .32) @ R(math.pi / 2, "X")
            g.torus(mat("loco_red"), W, .28, .05, seg=16)
    obj = g.commit()
    point_light("farol", M @ Vector((2.6, 0, 1.7)), 60, (1, .75, .45), .1)
    point_light("fornalha", M @ Vector((-1.25, 0, 1.6)), 40, (1, .45, .2), .3)
    return obj


# ---------------------------------------------------------------- portão de entrada
def entrance(at, width, font_path):
    """Arco do portão: pilares creme com estrela vermelha, arco listrado com lâmpadas e o letreiro."""
    g = Geo("Portão", at)
    M = frame(at)
    hgt = 2.6
    for side in (-1, 1):
        x = side * width / 2
        g.box(mat("paint_cream"), M @ T(x, 0, hgt / 2), (.6, .6, hgt))
        g.box(mat("stone"), M @ T(x, 0, .12), (.72, .72, .24))
        g.box(mat("gold"), M @ T(x, 0, hgt + .05), (.72, .72, .1))
        g.box(mat("paint_cream"), M @ T(x, 0, hgt + .25), (.5, .5, .3))
        g.sphere(mat("glass_warm"), M @ T(x, 0, hgt + .55), .16)
        g.cyl(mat("paint_red"), M @ T(x, -.31, hgt * .55) @ R(math.pi / 2, "X"), .2, .2, .03, seg=24)
        g.star(mat("gold"), M @ T(x, -.34, hgt * .55), .15)
        point_light("pilar", M @ Vector((x, -.4, hgt + .6)), 40, LAMP_COLOR, .15)
    # Arco: faixa listrada com borda dourada e lâmpadas.
    n = 24
    outer, inner = [], []
    for i in range(n + 1):
        a = math.pi * i / n
        outer.append(M @ Vector((math.cos(a) * (width / 2 + .3), 0, hgt + .3 + math.sin(a) * 1.25)))
        inner.append(M @ Vector((math.cos(a) * (width / 2 - .25), 0, hgt + .3 + math.sin(a) * .85)))
    verts = outer + inner
    faces = [(i, i + 1, n + 2 + i, n + 1 + i) for i in range(n)]
    uvs = [(i * .3, 1) for i in range(n + 1)] + [(i * .3, 0) for i in range(n + 1)]
    g.poly(linear_stripes("arco_listrado", "8c2027", "e2cfa6", .3), verts, faces, uvs)
    g.poly(linear_stripes("arco_listrado", "8c2027", "e2cfa6", .3), [v + Vector((0, .2, 0)) for v in verts],
        [f[::-1] for f in faces], uvs)
    g.tube(mat("gold"), outer, .05)
    g.tube(mat("gold"), inner, .05)
    for p in outer[1::2]:
        g.sphere(mat("bulb"), T(*(p + Vector((0, -.06, 0)))), .06, seg=8, rings_=5)
    # Portões de ferro abertos para dentro.
    for side in (-1, 1):
        G = M @ T(side * (width / 2 - .3), .1, 0) @ R(side * 1.1)
        for k in range(9):
            g.cyl(mat("iron"), G @ T(-side * (.1 + k * .17), 0, .95), .015, .015, 1.9, seg=5)
        for z in (.25, 1.0, 1.85):
            g.box(mat("iron"), G @ T(-side * .78, 0, z), (1.5, .03, .04))
    obj = g.commit()
    # Letreiro em cima do arco.
    import bpy
    font = bpy.data.fonts.load(font_path)
    curve = bpy.data.curves.new("Letreiro", "FONT")
    curve.body = "O Grande Picadeiro"
    curve.font = font
    curve.align_x = "CENTER"
    curve.size = .42
    curve.extrude = .03
    text = bpy.data.objects.new("Letreiro", curve)
    text.location = M @ Vector((0, -.12, hgt + 1.05))
    text.rotation_euler = (math.pi / 2, 0, 0)
    curve.materials.append(mat("gold"))
    bpy.context.scene.collection.objects.link(text)
    return obj


def striped_fence(points, ground, name="Cerca listrada"):
    """Muro baixo de painéis listrados entre pilaretes creme com medalhão de estrela (a borda da frente)."""
    g = Geo(name, ground(*points[0]))
    for (x0, z0), (x1, z1) in zip(points[:-1], points[1:]):
        a, b = ground(x0, z0), ground(x1, z1)
        mid = (a + b) / 2
        d = b - a
        yaw = math.atan2(d.y, d.x)
        length = d.length
        F = T(*mid) @ R(yaw)
        verts = [F @ Vector(p) for p in ((-length / 2, 0, 0), (length / 2, 0, 0), (length / 2, 0, .95), (-length / 2, 0, .95))]
        uv = [(0, 0), (length, 0), (length, 1), (0, 1)]
        g.poly(linear_stripes("cerca_listrada", "8c2027", "e2cfa6", .4), verts, [(0, 1, 2, 3)], uv)
        g.poly(linear_stripes("cerca_listrada", "8c2027", "e2cfa6", .4), verts, [(3, 2, 1, 0)], uv)
        g.box(mat("gold"), F @ T(0, 0, .97), (length, .08, .06))
    for (x, z) in points:
        p = ground(x, z)
        g.box(mat("paint_cream"), T(*p) @ T(0, 0, .65), (.42, .42, 1.3))
        g.box(mat("gold"), T(*p) @ T(0, 0, 1.33), (.5, .5, .08))
        g.box(mat("paint_cream"), T(*p) @ T(0, 0, 1.48), (.3, .3, .24))
        g.cyl(mat("paint_red"), T(*p) @ T(0, -.22, .75) @ R(math.pi / 2, "X"), .15, .15, .02, seg=20)
        g.star(mat("gold"), T(*p) @ T(0, -.24, .75), .11)
    return g.commit()


# ---------------------------------------------------------------- enfeites
def lamp_post(g, p, energy=520):
    """Poste de ferro verde-escuro com lanterna de vidro âmbar (e a luz de verdade)."""
    g.cyl(mat("lamp_green"), T(*p) @ T(0, 0, .15), .14, .1, .3, seg=10)
    g.cyl(mat("lamp_green"), T(*p) @ T(0, 0, 1.25), .05, .05, 2.2, seg=8)
    g.torus(mat("gold"), T(*p) @ T(0, 0, .6), .06, .02, seg=10)
    g.cyl(mat("glass_warm"), T(*p) @ T(0, 0, 2.55), .1, .14, .36, seg=8)
    g.cyl(mat("lamp_green"), T(*p) @ T(0, 0, 2.8), .2, .04, .16, seg=8)
    g.cyl(mat("lamp_green"), T(*p) @ T(0, 0, 2.36), .1, .15, .06, seg=8)
    for k in range(4):
        a = math.tau * k / 4 + math.pi / 4
        g.tube(mat("lamp_green"), [p + Vector((math.cos(a) * .13, math.sin(a) * .13, 2.36)),
            p + Vector((math.cos(a) * .1, math.sin(a) * .1, 2.74))], .012, seg=4)
    g.sphere(mat("gold"), T(*p) @ T(0, 0, 2.92), .05, seg=8, rings_=5)
    point_light("lampião", p + Vector((0, 0, 2.55)), energy, LAMP_COLOR, .12)


def festoon(g, a, b, sag, spacing=.42, light_every=4, energy=22):
    """Varal de lâmpadas em catenária entre dois pontos (Blender)."""
    a, b = Vector(a), Vector(b)
    n = max(int((b - a).length / spacing), 2)
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append(a.lerp(b, t) - Vector((0, 0, sag * 4 * t * (1 - t))))
    g.tube(mat("ink"), pts, .008, seg=4)
    for i, p in enumerate(pts[1:-1]):
        g.sphere(mat("bulb"), T(*(p - Vector((0, 0, .05)))), .04, seg=8, rings_=5)
        if light_every and i % light_every == 0:
            point_light("varal", p - Vector((0, 0, .12)), energy, (1, .72, .42), .05)


def bunting(g, a, b, sag, rng):
    a, b = Vector(a), Vector(b)
    n = max(int((b - a).length / .38), 2)
    pts = [a.lerp(b, i / n) - Vector((0, 0, sag * 4 * (i / n) * (1 - i / n))) for i in range(n + 1)]
    g.tube(mat("ink"), pts, .008, seg=4)
    colors = ["canvas_red", "canvas_cream", "paint_teal", "gold", "canvas_navy"]
    for i in range(n):
        p, q = pts[i], pts[i + 1]
        mid = (p + q) / 2 - Vector((0, 0, .32))
        g.poly(mat(colors[i % len(colors)]), [p, q, mid], [(0, 1, 2)])
        g.poly(mat(colors[i % len(colors)]), [q, p, mid], [(0, 1, 2)])


def pole(g, p, height=4.0):
    g.cyl(mat("wood_dark"), T(*p) @ T(0, 0, height / 2), .07, .05, height, seg=8)
    g.sphere(mat("gold"), T(*p) @ T(0, 0, height + .05), .08, seg=8, rings_=5)
    return p + Vector((0, 0, height - .1))


def fence(g, pts):
    """Cerca de madeira: mourões a cada ponto e duas travessas (pontos já no chão, Blender)."""
    for p in pts:
        g.box(mat("wood_dark"), T(*p) @ T(0, 0, .45), (.12, .12, .9))
        g.box(mat("wood"), T(*p) @ T(0, 0, .93), (.16, .16, .06))
    for a, b in zip(pts[:-1], pts[1:]):
        d = b - a
        yaw = math.atan2(d.y, d.x)
        mid = (a + b) / 2
        for z in (.35, .75):
            g.box(mat("wood"), T(*mid) @ R(yaw) @ T(0, 0, z) @ R(-math.atan2(d.z, d.xy.length), "Y"),
                (d.length + .1, .06, .1))


def bush(g, p, size, rng):
    for k in range(rng.randint(3, 6)):
        off = Vector((rng.uniform(-.5, .5), rng.uniform(-.5, .5), 0)) * size
        r = size * rng.uniform(.45, .75)
        g.ico(mat(rng.choice(["leaf_dark", "leaf", "leaf"])), T(*(p + off)) @ T(0, 0, r * .7) @ S(1, 1, .85), r, sub=2)


def round_tree(g, p, height, rng):
    g.cyl(mat("trunk"), T(*p) @ T(0, 0, height * .3), .16, .1, height * .6, seg=8)
    for k in range(rng.randint(6, 9)):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(.2, .9)
        r = rng.uniform(.65, 1.05) * height / 4
        c = p + Vector((math.cos(a) * d, math.sin(a) * d, height * rng.uniform(.55, .85)))
        g.ico(mat(rng.choice(["leaf_dark", "leaf", "leaf_light", "leaf"])), T(*c), r, sub=2)


def pine(g, p, height, rng):
    g.cyl(mat("trunk"), T(*p) @ T(0, 0, .3), .1, .08, .6, seg=6)
    tiers = 4
    for k in range(tiers):
        t = k / tiers
        r = (1 - t * .75) * height * .3
        z = .35 + t * height * .7
        g.cyl(mat(rng.choice(["pine", "pine", "leaf_dark"])), T(*p) @ T(0, 0, z + height * .2) @ R(rng.uniform(0, 6)),
            r, 0, height * .42, seg=9, smooth=False)


def flowers(g, p, rng, count=8, spread=.45, palette=None):
    palette = palette or ["flower_white", "flower_yellow", "flower_pink", "flower_purple", "flower_red", "flower_orange"]
    color = rng.choice(palette)
    for k in range(count):
        q = p + Vector((rng.uniform(-spread, spread), rng.uniform(-spread, spread), rng.uniform(.06, .18)))
        g.ico(mat(color if rng.random() < .8 else rng.choice(palette)), T(*q), rng.uniform(.035, .06), sub=1)
        g.ico(mat("leaf"), T(*(q - Vector((0, 0, .07)))), .05, sub=0)


def crate(g, p, size, yaw):
    M = T(*p) @ R(yaw)
    g.box(mat("wood"), M @ T(0, 0, size / 2), (size, size, size))
    for z in (.08, .92):
        g.box(mat("wood_dark"), M @ T(0, 0, size * z), (size + .02, size + .02, size * .1))


def star_box(g, p, size, yaw):
    M = T(*p) @ R(yaw)
    g.box(mat("paint_red"), M @ T(0, 0, size / 2), (size, size, size))
    g.box(mat("gold"), M @ T(0, 0, size), (size + .02, size + .02, .04))
    g.star(mat("gold"), M @ T(0, -size / 2 - .01, size / 2), size * .3)


def barrel(g, p):
    g.cyl(mat("wood"), T(*p) @ T(0, 0, .38), .32, .3, .76, seg=14)
    for z in (.12, .64):
        g.torus(mat("iron"), T(*p) @ T(0, 0, z), .32, .02, seg=14)


def pedestal(g, p, r=.5, h=.6, top="paint_red"):
    g.cyl(stripes("pedestal_listrado", "a3252b", "eadbbd", 14), T(*p) @ T(0, 0, h / 2), r, r * .9, h, seg=24)
    g.cyl(mat("gold"), T(*p) @ T(0, 0, h + .03), r + .04, r + .04, .06, seg=24)
    g.cyl(mat("gold"), T(*p) @ T(0, 0, .03), r + .04, r + .04, .06, seg=24)


def cage(g, p, yaw):
    M = T(*p) @ R(yaw)
    g.box(mat("paint_red"), M @ T(0, 0, .35), (2.0, 1.2, .2))
    g.box(mat("paint_red"), M @ T(0, 0, 2.0), (2.1, 1.3, .14))
    g.box(mat("gold"), M @ T(0, 0, 2.1), (2.15, 1.35, .05))
    for x in [-.95 + i * .19 for i in range(11)]:
        for y in (-.58, .58):
            g.cyl(mat("gold"), M @ T(x, y, 1.18), .018, .018, 1.65, seg=6)
    for y in [-.58 + i * .19 for i in range(7)]:
        for x in (-.98, .98):
            g.cyl(mat("gold"), M @ T(x, y, 1.18), .018, .018, 1.65, seg=6)
    g.box(mat("hay"), M @ T(0, 0, .5), (1.9, 1.1, .1))
    for x in (-.7, .7):
        for y in (-.62, .62):
            W = M @ T(x, y, .32) @ R(math.pi / 2, "X")
            g.torus(mat("wood_dark"), W, .28, .04, seg=14)


def hay(g, p, yaw):
    M = T(*p) @ R(yaw)
    g.box(mat("hay"), M @ T(0, 0, .25), (.9, .5, .5))
    for x in (-.25, .25):
        g.box(mat("wood_dark"), M @ T(x, 0, .25), (.03, .52, .52))


def top_hat(g, p, scale=1.0):
    g.cyl(mat("black_hat"), T(*p) @ T(0, 0, .05 * scale), .5 * scale, .5 * scale, .06 * scale, seg=24)
    g.cyl(mat("black_hat"), T(*p) @ T(0, 0, .45 * scale), .33 * scale, .3 * scale, .8 * scale, seg=24)
    g.cyl(mat("paint_red"), T(*p) @ T(0, 0, .18 * scale), .305 * scale, .305 * scale, .16 * scale, seg=24)


def easel_poster(g, p, yaw, poster_mat, w=.7, h=.95):
    M = T(*p) @ R(yaw)
    for x in (-w * .45, w * .45):
        g.tube(mat("wood"), [M @ Vector((x, .1, 0)), M @ Vector((x * .8, 0, h + .55))], .025)
    g.tube(mat("wood"), [M @ Vector((0, .4, 0)), M @ Vector((0, .05, h + .3))], .02)
    g.box(mat("gold"), M @ T(0, -.02, .4 + h / 2) @ R(-.12, "X"), (w + .08, .04, h + .08))
    g.quad(poster_mat, M @ Vector((0, -.06, .4 + h / 2)), M.to_3x3() @ Vector((w / 2, 0, 0)),
        M.to_3x3() @ R(-.12, "X").to_3x3() @ Vector((0, 0, h / 2)))


def juggling_pin(g, p, color, tilt):
    M = T(*p) @ R(tilt, "Y")
    g.cyl(mat("paint_cream"), M @ T(0, 0, .5), .2, .07, 1.0, seg=14)
    g.sphere(mat("paint_cream"), M @ T(0, 0, .25), .24, seg=14)
    g.cyl(mat(color), M @ T(0, 0, .72), .08, .08, .12, seg=14)
    g.sphere(mat(color), M @ T(0, 0, 1.05), .1, seg=12)


def signpost(g, p, arrows):
    g.cyl(mat("wood_dark"), T(*p) @ T(0, 0, 1.0), .06, .06, 2.0, seg=8)
    for i, (yaw, color) in enumerate(arrows):
        A = T(*p) @ T(0, 0, 1.75 - i * .32) @ R(yaw)
        g.box(mat(color), A @ T(.45, 0, 0), (.9, .05, .22))
        g.poly(mat(color), [A @ Vector((.9, -.03, .16)), A @ Vector((1.12, -.03, 0)), A @ Vector((.9, -.03, -.16))], [(0, 1, 2)])


def bench(g, p, yaw):
    M = T(*p) @ R(yaw)
    g.box(mat("wood"), M @ T(0, 0, .45), (1.4, .42, .06))
    g.box(mat("wood"), M @ T(0, .2, .72), (1.4, .05, .4))
    for x in (-.6, .6):
        g.box(mat("iron"), M @ T(x, 0, .22), (.05, .42, .45))


def elephant(g, p, rng):
    """Estátua de elefante de bronze sobre um tambor de circo, tromba erguida, na praça."""
    M = T(*p)
    g.cyl(mat("stone"), M @ T(0, 0, .2), 1.0, 1.05, .4, seg=32)
    g.cyl(mat("stone_dark"), M @ T(0, 0, .5), .82, .9, .2, seg=32)
    g.cyl(stripes("tambor", "a3252b", "eadbbd", 16), M @ T(0, 0, .95), .66, .66, .7, seg=32)
    g.torus(mat("gold"), M @ T(0, 0, .62), .67, .04, seg=32)
    g.torus(mat("gold"), M @ T(0, 0, 1.29), .67, .04, seg=32)
    E = M @ T(0, 0, 1.3) @ S(1.3)
    b = mat("bronze")
    g.ico(b, E @ T(0, .1, .75) @ S(.55, .75, .5), 1.0, sub=3)
    g.ico(b, E @ T(0, -.62, 1.05) @ S(.4, .38, .42), 1.0, sub=3)
    for side in (-1, 1):
        g.ico(b, E @ T(side * .45, -.5, 1.08) @ R(side * .35) @ S(.36, .06, .42), 1.0, sub=2)
        g.sphere(mat("ink"), E @ T(side * .17, -.95, 1.15), .04, seg=8, rings_=5)
        for y in (-.35, .5):
            g.cyl(b, E @ T(side * .3, y, .28), .17, .2, .6, seg=12)
        g.tube(mat("paint_cream"), [E @ Vector((side * .14, -.88, .88)), E @ Vector((side * .2, -1.05, .82)),
            E @ Vector((side * .22, -1.15, .9))], .035, seg=6)
    trunk = [E @ Vector((0, -.9, .95)), E @ Vector((0, -1.12, .78)), E @ Vector((0, -1.25, .95)),
        E @ Vector((0, -1.28, 1.3)), E @ Vector((0, -1.15, 1.6))]
    g.tube(b, trunk, .1, seg=10, cap=True)
    g.tube(b, [E @ Vector((0, .85, .85)), E @ Vector((0, 1.0, .6))], .03, seg=5)
    # Mantinha vermelha e dourada nas costas.
    g.ico(mat("carpet"), E @ T(0, .1, 1.08) @ S(.5, .5, .12), 1.0, sub=2)
    g.cyl(mat("gold"), E @ T(0, .1, 1.24), .1, .06, .2, seg=10)
