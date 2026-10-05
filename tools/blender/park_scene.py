"""Composição do parque da Área 1: onde vai cada atração e enfeite (usado por park_render.py).

Posições em coordenadas da Godot (x, z); `ground(x, z, lift)` devolve o ponto do Blender no chão.
As atrações ficam nas portas (build/park/layout.json); o resto fica fora das trilhas e das entradas.
"""
import math
import os
import random
import numpy as np
from mathutils import Vector, noise
import park_kit as kit
import park_props as pp

# Emblemas e cartazes recortados da referência (pixels da imagem 1672x941).
DECALS = {"lion": ((318, 60, 438, 192), "ellipse"), "jugglers": ((796, 66, 954, 172), "ellipse"),
    "moon": ((1286, 66, 1452, 190), "ellipse"), "fortune": ((704, 386, 774, 466), "rect"),
    "poster_hat": ((1508, 226, 1572, 326), "rect"), "poster_star": ((1614, 256, 1664, 326), "rect")}
## Praça da estátua do elefante (Godot x, z).
PLAZA = (-4.6, 7.6)
RAIL_Z = -0.45


class Park:
    def __init__(self, layout, ground, path_distance, root, work):
        self.D = layout
        self.ground = ground
        self.path_distance = path_distance
        self.root = root
        self.work = work

    def door(self, name):
        return next(d for d in self.D["doors"] if d["name"] == name)

    def free_spot(self, x, z, margin=1.6):
        """Longe das trilhas e das frentes das atrações (onde os bonecos andam)."""
        if self.path_distance(x, z) < self.D["path_width"] / 2 + margin:
            return False
        for d in self.D["doors"]:
            fx, _, fz = d["front"]
            if math.hypot(x - fx, z - fz) < 2.2:
                return False
        return True

    def blocked(self, x, z, extra=0.0):
        """Dentro de uma atração (pela colisão), da praça do elefante ou da estação."""
        for d in self.D["doors"]:
            for s in d["shapes"]:
                sx, _, sz = s["at"]
                if "box" in s:
                    if abs(x - sx) < s["box"][0] / 2 + .6 + extra and abs(z - sz) < s["box"][2] / 2 + .6 + extra:
                        return True
                elif math.hypot(x - sx, z - sz) < s["cylinder"][0] + .8 + extra:
                    return True
        if 7.8 < x < 15.6 and abs(z - RAIL_Z) < 1.3 + extra:
            return True
        return math.hypot(x - PLAZA[0], z - PLAZA[1]) < 2.6 + extra

    def build(self):
        g = self.ground
        D = self.D
        ref = os.path.join(self.root, "docs/referencias/remap/mapa_referencia.png")
        decals = {key: kit.crop_decal(ref, os.path.join(self.work, "decal_" + key + ".png"), box, shape)
            for key, (box, shape) in DECALS.items()}
        rng = random.Random(77)
        self.attractions(decals)
        props = kit.Geo("Enfeites", g(0, 0))
        lamps = kit.Geo("Lampiões", g(0, 0))
        self.plaza(props, lamps, rng)
        self.yards(props, decals)
        extra_lamps = [(-13.6, 9.4), (-18.0, 9.4), (-9.6, 1.0), (-5.2, 1.0), (1.2, 1.3), (5.6, -4.6), (9.4, -4.8),
            (15.0, -1.4), (20.2, -1.6), (10.0, 4.2), (15.4, 5.6), (-11.0, 5.2), (2.8, 4.4), (17.6, 2.6)]
        for x, z in [tuple(p) for p in D["lamps"]] + extra_lamps:
            pp.lamp_post(lamps, g(x, z))
        lights = kit.Geo("Varais", g(0, 0))
        self.strings(lights, rng)
        fences = kit.Geo("Cercas", g(0, 0))
        self.fences(fences)
        nature = kit.Geo("Vegetação", g(0, 0))
        self.vegetation(nature, rng)
        for geo in (props, lamps, lights, fences, nature):
            geo.commit()
        # Chão escuro de floresta em volta da maquete (a borda nunca mostra o vazio).
        outside = kit.Geo("Chão de fora", (0, 0, 0))
        outside.box(kit.mat("leaf_dark"), kit.T(0, 0, -1.2), (90, 70, .2))
        outside.commit()

    def attractions(self, decals):
        g = self.ground
        d = self.door("DoorTamer")
        pp.tent("O Domador", g(d["at"][0], d["at"][2]), d["radius"] + .25, 2.3, 3.6,
            kit.stripes("lona_vermelha", "a3252b", "eadbbd", 20), emblem=("emblema_leao", decals["lion"]),
            emblem_size=(1.7, 1.85))
        d = self.door("DoorJugglers")
        pp.tent("Os Malabaristas", g(d["at"][0], d["at"][2]), d["radius"] + .2, 2.2, 3.4,
            kit.stripes("lona_vermelha", "a3252b", "eadbbd", 20), emblem=("emblema_malabares", decals["jugglers"]),
            emblem_size=(2.1, 1.45))
        d = self.door("DoorMagician")
        radius = d["radius"] + .15
        big = pp.tent("O Grande Mágico", g(d["at"][0], d["at"][2]), radius, 2.6, 4.2,
            kit.stripes("lona_noite", "1d2a5e", "18224d", 24), valance="canvas_navy",
            emblem=("emblema_lua", decals["moon"]), emblem_size=(2.4, 1.85))
        stars = kit.Geo("Estrelas da lona", big.location)
        rng = random.Random(5)
        cx, cy, cz = big.location
        for i in range(52):
            a = rng.uniform(0, math.tau)
            t = rng.uniform(.05, .85)
            r = radius * 1.06 * (1 - t)
            z = cz + 2.6 + 4.2 * t ** 1.6 + .03
            if rng.random() < .3:
                # Na parede, longe da entrada (que fica em -y).
                if abs(math.sin(a) + 1) < .3:
                    continue
                r, z = radius + .02, cz + rng.uniform(.4, 2.0)
            p = Vector((cx + math.cos(a) * r, cy + math.sin(a) * r, z))
            stars.star(kit.mat("gold"), kit.T(*p) @ kit.R(a + math.pi / 2), rng.uniform(.12, .22), .02)
        stars.commit()
        d = self.door("DoorDressing")
        pp.dressing_wagon(g(d["at"][0], d["at"][2]))
        pp.clothes_rack(g(-10.2, 0.2), .25)
        d = self.door("DoorShop")
        pp.shop_wagon(g(d["at"][0], d["at"][2]), decals["fortune"])
        d = self.door("DoorTrain")
        pp.station(g(d["at"][0], d["at"][2]), RAIL_Z, 11.6)
        pp.rails([(8.3, RAIL_Z), (15.0, RAIL_Z)], g)
        pp.locomotive(g(12.0, RAIL_Z, .02), 0.0)
        pp.entrance(g(-15.8, 9.6), 3.2, os.path.join(self.root, "core/ui/fonts/Limelight-Regular.ttf"))
        pp.striped_fence([(-22.6, 9.9), (-20.4, 9.8), (-18.2, 9.7)], g, "Cerca do portão oeste")
        pp.striped_fence([(-13.4, 9.7), (-11.2, 9.9), (-9.0, 10.3)], g, "Cerca do portão leste")
        pp.striped_fence([(-6.0, 12.3), (-2.0, 12.4), (2.0, 12.3), (6.0, 12.4), (10.0, 12.3), (14.0, 12.4),
            (18.0, 12.3), (22.4, 12.3)], g, "Muro da frente")

    def plaza(self, props, lamps, rng):
        """Praça do elefante: cerca redonda aberta para a trilha, canteiros e quatro lampiões."""
        g = self.ground
        px, pz = PLAZA
        pp.elephant(props, g(px, pz), rng)
        ring = []
        for i in range(21):
            a = math.tau * i / 20 + .08
            # Abertura voltada para a trilha (norte, -z na Godot).
            if abs(math.sin(a) - 1) < .25:
                if len(ring) > 1:
                    pp.fence(props, ring)
                ring = []
                continue
            ring.append(g(px + math.cos(a) * 2.3, pz - math.sin(a) * 2.3))
        if len(ring) > 1:
            pp.fence(props, ring)
        for i in range(16):
            a = math.tau * i / 16
            pp.flowers(props, g(px + math.cos(a) * 1.55, pz - math.sin(a) * 1.55), rng, 10, .3)
        for a in (.6, 2.5, 3.8, 5.6):
            pp.lamp_post(lamps, g(px + math.cos(a) * 2.75, pz - math.sin(a) * 2.75), 70)

    def yards(self, props, decals):
        g = self.ground
        # Domador: jaula, pedestais, barril, feno e caixote.
        pp.cage(props, g(-11.2, -3.3), .35)
        pp.pedestal(props, g(-4.4, -0.4))
        pp.pedestal(props, g(-10.3, -0.2), .4, .45)
        pp.barrel(props, g(-10.9, -1.3))
        pp.hay(props, g(-4.2, -3.9), .3)
        pp.crate(props, g(-3.6, -3.0), .6, .4)
        # Cartomante.
        pp.crate(props, g(1.4, -2.2), .6, .2)
        pp.crate(props, g(1.9, -1.5), .45, -.3)
        pp.barrel(props, g(-4.0, 0.6))
        # Malabaristas: alvo no chão, pinos gigantes, bolas e caixas de estrela.
        target = kit.Geo("Alvo", g(7.5, -3.9, .02))
        target.cyl(kit.rings("alvo", "a3252b", "eadbbd", 2.2), kit.T(*g(7.5, -3.9, .02)), 1.25, 1.25, .03, seg=48)
        target.commit()
        pp.juggling_pin(props, g(4.6, -6.1), "canvas_red", .25)
        pp.juggling_pin(props, g(10.4, -6.5), "paint_teal", -.3)
        for k, c in enumerate(("canvas_red", "gold", "paint_teal")):
            props.sphere(kit.mat(c), kit.T(*g(10.9 + (k - 1) * .5, -4.9, .25 + (.4 if k == 1 else 0))), .25)
        pp.star_box(props, g(4.4, -4.6), .7, .2)
        pp.star_box(props, g(9.9, -8.6), .6, -.4)
        # Mágico: tapete com estrela, cartolas em pedestais e cartazes.
        carpet = kit.Geo("Tapete do Mágico", g(17.6, -1.9))
        carpet.box(kit.mat("carpet"), kit.T(*g(17.6, -1.9, .01)), (2.2, 1.6, .02))
        carpet.box(kit.mat("gold"), kit.T(*g(17.6, -1.9, .005)), (2.35, 1.75, .015))
        carpet.star(kit.mat("gold"), kit.T(*g(17.6, -1.9, .03)) @ kit.R(math.pi / 2, "X"), .5, .01)
        carpet.commit()
        for x, z in ((14.7, -3.2), (20.6, -3.0)):
            pp.pedestal(props, g(x, z), .45, .9)
            pp.top_hat(props, g(x, z, .93), .75)
        pp.easel_poster(props, g(13.8, -5.0), .35, kit.decal("cartaz_cartola", decals["poster_hat"]))
        pp.easel_poster(props, g(21.3, -4.6), -.35, kit.decal("cartaz_estrela", decals["poster_star"]), .55, .8)
        # Estação, placa de direções e bancos.
        pp.crate(props, g(9.4, 2.6), .55, .1)
        pp.crate(props, g(9.9, 2.9), .45, -.2)
        pp.signpost(props, g(1.6, 5.0), [(.5, "paint_red"), (-.2, "paint_teal"), (2.6, "wood")])
        pp.bench(props, g(-7.6, 6.0), .2)
        pp.bench(props, g(6.4, 6.2), -.15)

    def strings(self, lights, rng):
        """Mastros com varais de lâmpadas e bandeirinhas, cruzando o parque."""
        g = self.ground
        masts = {}
        for key, (x, z, h) in {"a": (-12.0, 5.6, 4.2), "b": (-6.6, 5.0, 4.2), "c": (-1.6, 4.6, 4.2),
                "d": (3.4, 3.8, 4.2), "e": (-2.6, -4.6, 4.6), "f": (4.0, -8.6, 4.6), "g": (12.4, -9.4, 4.6),
                "h": (-13.6, -6.4, 4.6), "i": (11.4, 6.6, 4.2), "j": (16.6, 7.0, 4.0), "k": (-18.6, 2.4, 4.2)}.items():
            masts[key] = pp.pole(lights, g(x, z), h)
        tamer_top = g(-7.4, -2, 6.3)
        for a, b, sag in (("k", "a", .7), ("a", "b", .8), ("b", "c", .8), ("c", "d", .7), ("d", "i", .9), ("i", "j", .6)):
            pp.festoon(lights, masts[a], masts[b], sag)
        pp.festoon(lights, masts["e"], tamer_top, .9)
        pp.festoon(lights, masts["e"], masts["f"], 1.0)
        pp.festoon(lights, masts["f"], g(7.5, -7, 5.9), .6)
        pp.festoon(lights, masts["f"], masts["g"], 1.0)
        pp.festoon(lights, masts["g"], g(17.6, -5.4, 7.1), .8)
        pp.festoon(lights, masts["h"], tamer_top, .8)
        for i in range(4):
            a = math.tau * i / 4 + .6
            pp.festoon(lights, g(*PLAZA, 3.3), g(PLAZA[0] + math.cos(a) * 2.75, PLAZA[1] - math.sin(a) * 2.75, 2.9),
                .25, .35, 0)
        pp.bunting(lights, masts["h"], masts["e"], .9, rng)
        pp.bunting(lights, masts["g"], g(21.5, -9.0, 4.0), .6, rng)
        pp.bunting(lights, masts["a"], masts["k"], .5, rng)
        pp.bunting(lights, g(-17.4, 9.6, 4.1), masts["k"], .7, rng)

    def fences(self, fences):
        """Cercas de madeira nas beiras das trilhas, em trechos (nunca na frente das portas)."""
        D = self.D
        for path in D["paths"]:
            pts = np.array(path, np.float32)
            for side in (-1, 1):
                run = []
                for i in range(0, len(pts) - 1, 3):
                    a, b = pts[i], pts[min(i + 3, len(pts) - 1)]
                    tdir = (b - a) / max(float(np.linalg.norm(b - a)), 1e-6)
                    nrm = np.array([-tdir[1], tdir[0]]) * side
                    q = a + nrm * (D["path_width"] / 2 + .55)
                    x, z = float(q[0]), float(q[1])
                    ok = self.free_spot(x, z, .3) and not self.blocked(x, z, .3) and abs(x) < 21 and abs(z) < 11.8
                    ok = ok and noise.noise(Vector((x * .16, z * .16, side * 3.0))) > -.2
                    if ok:
                        run.append(self.ground(x, z))
                    else:
                        if len(run) > 2:
                            pp.fence(fences, run)
                        run = []
                if len(run) > 2:
                    pp.fence(fences, run)

    def vegetation(self, nature, rng):
        g = self.ground
        for i in range(170):
            x = rng.uniform(-24, 24)
            z = rng.uniform(-16.5, 14.5)
            edge = max(abs(x) / 23, abs(z) / 15)
            if edge < .86 and not (z < -10.5 and rng.random() < .6):
                continue
            if self.blocked(x, z) or (z > 10 and -18.4 < x < -13.2):
                continue
            h = rng.uniform(3.5, 6.0)
            if rng.random() < .45:
                pp.pine(nature, g(x, z), h, rng)
            else:
                pp.round_tree(nature, g(x, z), h, rng)
        inner = [(-18.5, -7.0), (-15.8, -9.2), (-1.5, -8.6), (1.8, -10.0), (13.2, -10.2), (-19.0, 4.8),
            (20.8, 3.4), (5.2, 9.6), (14.6, 9.8), (-9.4, 9.8), (19.0, 9.6), (-17.4, -2.8), (21.2, -8.8),
            (-3.0, -10.6), (9.0, -11.0), (-12.6, -9.8), (0.6, 8.8), (11.0, 9.2)]
        for x, z in inner:
            if rng.random() < .5:
                pp.pine(nature, g(x, z), rng.uniform(3.0, 4.5), rng)
            else:
                pp.round_tree(nature, g(x, z), rng.uniform(3.4, 4.8), rng)
        # Faixa de baixo, depois do muro da frente: moitas e árvores baixas (a câmera vê essa beira).
        x = -24.0
        while x < 24.0:
            z = rng.uniform(13.0, 15.5)
            if not (-18.6 < x < -13.0):
                if rng.random() < .25:
                    pp.round_tree(nature, g(x, z), rng.uniform(2.6, 3.4), rng)
                else:
                    pp.bush(nature, g(x, z), rng.uniform(.6, 1.0), rng)
                if rng.random() < .5:
                    pp.flowers(nature, g(x + rng.uniform(-.5, .5), 12.9), rng, 10, .5)
            x += rng.uniform(.8, 1.6)
        for i in range(950):
            x = rng.uniform(-21.5, 21.5)
            z = rng.uniform(-13, 11.6)
            if not self.free_spot(x, z, .4) or self.blocked(x, z, -.3):
                continue
            if noise.noise(Vector((x * .22, z * .22, 1.0))) < -.05:
                continue
            p = g(x, z)
            r = rng.random()
            if r < .35:
                pp.bush(nature, p, rng.uniform(.4, .8), rng)
            elif r < .8:
                pp.flowers(nature, p, rng, rng.randint(6, 14), .4)
            else:
                nature.ico(kit.mat("stone_dark"), kit.T(*p) @ kit.S(1, 1, .6), rng.uniform(.12, .3), sub=1)
        # Pedrinhas soltas na beira das trilhas.
        for path in self.D["paths"]:
            for (x, z) in path[::2]:
                if rng.random() < .4:
                    continue
                a = rng.uniform(0, math.tau)
                q = (x + math.cos(a) * self.D["path_width"] * .55, z + math.sin(a) * self.D["path_width"] * .55)
                nature.ico(kit.mat(rng.choice(["stone", "stone_dark"])), kit.T(*g(*q)) @ kit.S(1.3, 1, .5),
                    rng.uniform(.05, .12), sub=1)
