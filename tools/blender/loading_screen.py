"""Tela de carregamento a partir da arte de referência (docs/referencias/remap/carregamento_referencia.png).

blender --background --factory-startup --python tools/blender/loading_screen.py

Separa a pintura em camadas para a Godot animar (core/ui/boot_screen.gd):
- stage.png: o palco 1920x1080 sem os dois personagens (o lugar deles é preenchido pelos arredores, só
  aparece nas frestas quando eles respiram e acenam) e com a barra vazia;
- clown.png / acrobat.png: os personagens recortados pelo contorno de tinta;
- bar_fill.png: o preenchimento dourado da barra, do tamanho do trilho, revelado pelo progresso real;
- bulbs.png: mapa das lâmpadas (R: lâmpada, G: halo, B: fase; moldura/letreiro abaixo de 0,5, varais acima);
- loading_layout.gd: posições, pivôs, olhos e braços (em pixels da tela 1920x1080).
Só numpy (vem com o Blender). Os polígonos são aproximados à mão e o recorte encaixa no contorno preto.
"""
import bpy
import json
import math
import os
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
REF = os.path.join(ROOT, "docs/referencias/remap/carregamento_referencia.png")
OUT = os.path.join(ROOT, "core/ui/art/loading")
W, H = 1920, 1080
PAD = 28  # folga em volta dos recortes, para o balanço não cortar a arte

# Contornos aproximados (pixels da referência, 1672x941), um pouco por fora do traço preto.
CLOWN = [[310,382],[416,376],[420,432],[447,434],[472,447],[486,470],[490,497],[506,518],[506,545],[492,554],
    [468,560],[476,580],[505,574],[532,565],[556,536],[580,534],[590,553],[615,563],[632,585],[630,608],[614,620],
    [560,618],[535,612],[490,622],[484,632],[484,692],[460,706],[448,725],[446,775],[452,790],[480,800],[514,815],
    [520,862],[502,878],[358,878],[346,850],[352,805],[362,785],[364,770],[372,730],[352,742],[333,765],[326,790],
    [322,812],[324,850],[302,875],[178,874],[154,852],[158,812],[188,782],[238,770],[248,742],[272,716],[238,722],
    [218,708],[207,680],[211,652],[238,630],[272,624],[292,600],[306,586],[312,576],[284,580],[252,568],[243,540],
    [245,500],[240,470],[244,440],[262,418],[288,413],[298,400]]
ACROBAT = [[1086,540],[1098,518],[1138,500],[1162,512],[1180,522],[1215,540],[1238,548],[1222,530],[1220,500],
    [1236,470],[1238,455],[1262,418],[1300,404],[1345,398],[1412,402],[1425,440],[1418,490],[1410,525],[1392,560],
    [1375,575],[1400,605],[1425,628],[1452,640],[1498,658],[1506,690],[1478,698],[1430,700],[1410,685],[1395,690],
    [1400,700],[1432,760],[1450,792],[1478,820],[1500,845],[1495,875],[1470,882],[1420,880],[1405,860],[1400,830],
    [1398,805],[1360,770],[1322,735],[1290,770],[1272,800],[1268,830],[1262,860],[1240,882],[1170,882],[1158,860],
    [1165,835],[1195,812],[1215,790],[1232,760],[1240,722],[1236,700],[1242,680],[1250,640],[1250,592],[1215,592],
    [1178,578],[1150,575],[1120,568],[1092,562]]
# Encaixe no traço: limiar de escuro, dilatação do traço (fecha falhas) e alcance a partir da borda.
SNAP = {"clown": (0.14, 1, 14), "acrobat": (0.18, 1, 14)}
# Personagem: pés (linha do chão), olhos [centro, raios por fora do traço], braços [ombro, mão, raio] (referência).
RIG = {
    "clown": {"feet": 872, "eyes": [[413, 506, 23, 29], [461, 494, 10, 18]],
        "arms": [[[468, 588], [612, 585], 44], [[312, 606], [238, 668], 40]], "skin": [404, 468]},
    "acrobat": {"feet": 878, "eyes": [[1256, 492, 10, 18], [1305, 502, 19, 23]],
        "arms": [[[1252, 580], [1104, 538], 40], [[1372, 598], [1470, 676], 40]], "skin": [1282, 470]},
}
# Barra: trilho interno, onde o dourado termina, e o trecho vazio usado para apagar o dourado.
TRACK = (620, 757, 1044, 798)
FILL_END = 849
EMPTY = (915, 1030)


def load(path):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    return px[..., :3].copy()


def save(path, arr):
    h, w = arr.shape[:2]
    if arr.shape[2] == 3:
        arr = np.dstack([arr, np.ones((h, w), np.float32)])
    img = bpy.data.images.new(os.path.basename(path), w, h, alpha=True)
    img.pixels = np.clip(arr, 0, 1)[::-1].ravel()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()


def polygon_mask(poly, h, w):
    poly = np.array(poly, np.float32)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32) + .5
    inside = np.zeros((h, w), bool)
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        inside ^= ((yi > yy) != (yj > yy)) & (xx < (xj - xi) * (yy - yi) / (yj - yi + 1e-9) + xi)
        j = i
    return inside


def grow(mask, steps=1):
    for _ in range(steps):
        d = mask.copy()
        d[1:] |= mask[:-1]; d[:-1] |= mask[1:]; d[:, 1:] |= mask[:, :-1]; d[:, :-1] |= mask[:, 1:]
        mask = d
    return mask


def cutout(px, poly, threshold, close, reach_steps):
    """Polígono aproximado, depois retira o fundo entre ele e o traço preto (sem atravessar o traço)."""
    h, w = px.shape[:2]
    inside = polygon_mask(poly, h, w)
    dark = grow((px @ np.array([.3, .59, .11], np.float32)) < threshold, close)
    reach = ~inside & ~dark
    for _ in range(reach_steps):
        d = grow(reach) & ~dark
        if (d == reach).all():
            break
        reach = d
    return inside & ~reach


def box_blur(a, r):
    """Média numa janela (2r+1)², por somas acumuladas."""
    pad = np.pad(a, ((r + 1, r), (r + 1, r)) + ((0, 0),) * (a.ndim - 2), mode="edge")
    c = pad.cumsum(0).cumsum(1)
    s = c[2*r+1:, 2*r+1:] - c[:-2*r-1, 2*r+1:] - c[2*r+1:, :-2*r-1] + c[:-2*r-1, :-2*r-1]
    return s / (2*r + 1) ** 2


def fill_holes(px, known):
    """Preenche o que não é conhecido com as cores dos arredores (pirâmide empurra-puxa)."""
    levels = [(px * known[..., None], known.astype(np.float32))]
    while min(levels[-1][1].shape) > 2:
        c, wgt = levels[-1]
        h, w = wgt.shape
        c = np.pad(c, ((0, h % 2), (0, w % 2), (0, 0)))
        wgt = np.pad(wgt, ((0, h % 2), (0, w % 2)))
        cs = c[0::2, 0::2] + c[1::2, 0::2] + c[0::2, 1::2] + c[1::2, 1::2]
        ws = wgt[0::2, 0::2] + wgt[1::2, 0::2] + wgt[0::2, 1::2] + wgt[1::2, 1::2]
        scale = np.minimum(ws, 1) / np.maximum(ws, 1e-6)
        levels.append((cs * scale[..., None], np.minimum(ws, 1)))
    c, wgt = levels[-1]
    for c_fine, w_fine in reversed(levels[:-1]):
        up = c.repeat(2, 0).repeat(2, 1)[:w_fine.shape[0], :w_fine.shape[1]]
        up = box_blur(up, 1)
        c = c_fine + (1 - w_fine)[..., None] * up
    return c


def blobs(mask):
    """Componentes conectados (4-vizinhos): [centro x, centro y, área, largura, altura] de cada um."""
    h, w = mask.shape
    label = np.where(mask, np.arange(h * w, dtype=np.int64).reshape(h, w), h * w)
    big = h * w
    while True:
        new = label.copy()
        new[1:] = np.minimum(new[1:], label[:-1]); new[:-1] = np.minimum(new[:-1], label[1:])
        new[:, 1:] = np.minimum(new[:, 1:], label[:, :-1]); new[:, :-1] = np.minimum(new[:, :-1], label[:, 1:])
        new = np.where(mask, new, big)
        # Salto pela raiz do rótulo: converge em poucas dezenas de passos.
        flat = new.ravel()
        flat = np.where(flat < big, np.minimum(flat, flat[np.minimum(flat, big - 1)]), big)
        new = flat.reshape(h, w)
        if (new == label).all():
            break
        label = new
    ys, xs = np.nonzero(mask)
    ids = label[ys, xs]
    out = []
    order = np.argsort(ids, kind="stable")
    ids, ys, xs = ids[order], ys[order], xs[order]
    starts = np.r_[0, np.nonzero(np.diff(ids))[0] + 1, ids.size]
    for a, b in zip(starts[:-1], starts[1:]):
        bx, by = xs[a:b], ys[a:b]
        out.append((float(bx.mean()), float(by.mean()), b - a, bx.max() - bx.min() + 1, by.max() - by.min() + 1))
    return out


def resize(a, w, h):
    sh, sw = a.shape[:2]
    def axis(n_dst, n_src):
        s = np.clip((np.arange(n_dst) + .5) * n_src / n_dst - .5, 0, n_src - 1)
        i0 = np.floor(s).astype(int)
        i1 = np.minimum(i0 + 1, n_src - 1)
        return i0, i1, (s - i0).astype(np.float32)
    y0, y1, fy = axis(h, sh)
    x0, x1, fx = axis(w, sw)
    extra = (None,) * (a.ndim - 2)
    rows = a[y0] * (1 - fy)[(slice(None), None) + extra] + a[y1] * fy[(slice(None), None) + extra]
    return rows[:, x0] * (1 - fx)[(None, slice(None)) + extra] + rows[:, x1] * fx[(None, slice(None)) + extra]


def sharpen(a, amount=.35):
    return np.clip(a + (a - box_blur(a, 1)) * amount, 0, 1)


def main():
    os.makedirs(OUT, exist_ok=True)
    px = load(REF)
    rh, rw = px.shape[:2]
    sx, sy = W / rw, H / rh
    masks = {"clown": cutout(px, CLOWN, *SNAP["clown"]), "acrobat": cutout(px, ACROBAT, *SNAP["acrobat"])}
    hidden = grow(masks["clown"] | masks["acrobat"], 2)
    plate = fill_holes(px, ~hidden)
    plate = np.where(hidden[..., None], plate, px)
    # Barra vazia: o dourado vira o fundo escuro do próprio trilho.
    x0, y0, x1, y1 = TRACK
    lum = px @ np.array([.3, .59, .11], np.float32)
    fill = np.zeros((rh, rw), bool)
    fill[y0:y1, x0 - 6:FILL_END + 2] = lum[y0:y1, x0 - 6:FILL_END + 2] > .34
    fill[y0 + 1:y1 - 1, FILL_END - 2:EMPTY[0]] = True  # o brilho que o dourado deixava no trilho
    span = EMPTY[1] - EMPTY[0]
    for x in range(x0 - 6, EMPTY[0]):
        col = fill[:, x]
        plate[col, x] = px[col, EMPTY[0] + (x - x0 + 6) % span]
    # Preenchimento do trilho inteiro: o dourado da referência estendido até o fim.
    track = np.zeros((y1 - y0, x1 - x0, 4), np.float32)
    # O perfil vertical médio do dourado (sem emendas), com a ponta esquerda original misturada.
    gold = px[y0:y1, x0:FILL_END - 4]
    profile = px[y0:y1, 680:820].mean(1, keepdims=True)
    body = np.repeat(profile, x1 - x0, axis=1)
    detail = px[y0:y1, 680:820] - profile
    tile = np.concatenate([detail, detail[:, ::-1]], axis=1)
    body += np.tile(tile, (1, math.ceil((x1 - x0) / tile.shape[1]), 1))[:, :x1 - x0] * .6
    blend = np.clip(1 - np.arange(x1 - x0) / 70.0, 0, 1)[None, :, None]
    body[:, :70] = gold[:, :70] * blend[:, :70] + body[:, :70] * (1 - blend[:, :70])
    track[..., :3] = body
    interior = (lum[y0:y1, x0:x1] > .34) | (lum[y0:y1, x0:x1] < .2)
    interior[:, FILL_END - x0:] = lum[y0:y1, FILL_END:x1] < .22
    for r in range(interior.shape[0]):
        cols = np.nonzero(interior[r])[0]
        if cols.size:
            interior[r, cols[0]:cols[-1] + 1] = True
    track[..., 3] = interior
    tx0, ty0 = round(x0 * sx), round(y0 * sy)
    tw, th = round(x1 * sx) - tx0, round(y1 * sy) - ty0
    save(os.path.join(OUT, "bar_fill.png"), sharpen(resize(track, tw, th)))
    # Lâmpadas: manchas claras e redondas (o letreiro, a lua e os textos ficam de fora). Cada lâmpada vira um
    # disco no mapa; na moldura e no letreiro elas acendem em sequência de três, nos varais piscam soltas.
    yy, xx = np.mgrid[0:rh, 0:rw].astype(np.float32)
    candidate = (lum > .8) & (px[..., 0] >= px[..., 2])
    candidate[(xx > 450) & (xx < 1240) & (yy > 92) & (yy < 286)] = False  # letras
    candidate[(xx > 560) & (xx < 1115) & (yy > 690) & (yy < 815)] = False  # Carregando… e a barra
    candidate[(xx - 705) ** 2 + (yy - 360) ** 2 < 50 ** 2] = False  # lua
    candidate[hidden] = False
    bulbs = []
    for (cx, cy, area, bw, bh) in blobs(candidate):
        if area < 5 or area > 1100 or max(bw, bh) > 2.2 * min(bw, bh) or area < .45 * bw * bh:
            continue
        if not (cx < 110 or cx > 1560 or (cy < 340 and 300 < cx < 1380)) and (area > 260 or cy > 760):
            continue
        frame = cx < 110 or cx > 1560
        sign = not frame and cy < 340 and 300 < cx < 1380
        bulbs.append([cx, cy, math.sqrt(area / math.pi) * 1.15 + 1.0, 1 if (frame or sign) else 0])
    chains = {"left": [b for b in bulbs if b[3] and b[0] < 110], "right": [b for b in bulbs if b[3] and b[0] > 1560],
        "sign": [b for b in bulbs if b[3] and 110 <= b[0] <= 1560]}
    phases = {}
    for name, chain in chains.items():
        if name == "sign":
            chain.sort(key=lambda b: math.atan2((b[1] - 185) * 2.4, b[0] - 836))
        else:
            chain.sort(key=lambda b: b[1])
        for i, b in enumerate(chain):
            phases[id(b)] = (i % 3) / 3.0
    rng = np.random.default_rng(7)
    sx_map = np.zeros((rh, rw, 3), np.float32)
    for b in bulbs:
        cx, cy, r, kind = b
        # B: fase da moldura/letreiro em [0; 0,45) e fase solta dos varais em [0,5; 1).
        code = phases[id(b)] * .45 / (2 / 3) if kind else .5 + rng.random() * .5
        reach = r * 3.5 + 2
        x0b, x1b = int(max(cx - reach, 0)), int(min(cx + reach + 1, rw))
        y0b, y1b = int(max(cy - reach, 0)), int(min(cy + reach + 1, rh))
        d = np.sqrt((xx[y0b:y1b, x0b:x1b] - cx) ** 2 + (yy[y0b:y1b, x0b:x1b] - cy) ** 2)
        disk = np.clip(r + .5 - d, 0, 1)
        halo = np.exp(-(d / (r * 1.5)) ** 2)
        region = sx_map[y0b:y1b, x0b:x1b]
        take = halo > region[..., 1]
        region[..., 0] = np.maximum(region[..., 0], disk)
        region[..., 1][take] = halo[take]
        region[..., 2][take] = code
    save(os.path.join(OUT, "bulbs.png"), resize(sx_map, W, H))
    save(os.path.join(OUT, "stage.png"), sharpen(resize(plate, W, H)))
    layout = {"size": [W, H], "track": [tx0, ty0, tw, th]}
    for name, mask in masks.items():
        ys, xs = np.nonzero(mask)
        bx0, bx1 = xs.min(), xs.max() + 1
        by0, by1 = ys.min(), ys.max() + 1
        ox0, oy0 = math.floor(bx0 * sx) - PAD, math.floor(by0 * sy) - PAD
        ox1, oy1 = math.ceil(bx1 * sx) + PAD, math.ceil(by1 * sy) + PAD
        big_rgb = resize(px, W, H)
        big_a = resize(mask.astype(np.float32), W, H)
        sprite = np.dstack([sharpen(big_rgb[oy0:oy1, ox0:ox1]), big_a[oy0:oy1, ox0:ox1]])
        sprite[sprite[..., 3] < .02] = 0
        save(os.path.join(OUT, name + ".png"), sprite)
        rig = RIG[name]
        to_local = lambda p: [round(p[0] * sx - ox0, 1), round(p[1] * sy - oy0, 1)]
        skin = px[rig["skin"][1], rig["skin"][0]]
        layout[name] = {
            "position": [ox0, oy0], "size": [ox1 - ox0, oy1 - oy0],
            "feet": round(rig["feet"] * sy - oy0, 1),
            "eyes": [to_local(e[:2]) + [round(e[2] * sx, 1), round(e[3] * sy, 1)] for e in rig["eyes"]],
            "arms": [to_local(a[0]) + to_local(a[1]) + [round(a[2] * sx, 1)] for a in rig["arms"]],
            "skin": [round(float(c), 4) for c in skin],
        }
    # A Godot lê o leiaute como script (vai junto na exportação sem filtro extra).
    with open(os.path.join(OUT, "loading_layout.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("extends RefCounted\n## Gerado por tools/blender/loading_screen.py. Pixels da tela 1920x1080.\n")
        f.write("const DATA := " + json.dumps(layout, indent="\t") + "\n")
    print("LOADING_SCREEN", json.dumps(layout))


main()
