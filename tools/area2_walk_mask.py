# Máscara da estrada onde se anda no mapa da Área 2, o Vulcão (levels/world/art/volcano_walk.png, metade da
# resolução). A estrada de laje cinza-clara é achada pela cor (clara e quase sem saturação; a lava, as rochas e a
# cinza marrom ficam de fora); fica só o pedaço principal (ligado), os furinhos (bases de lampião) são tapados, e
# as entradas que a cor não pega (frente da mina, pista do avião, frente das tendas) entram à mão.
# Mesmo jeito de tools/blender/park_walk_mask.py (Área 1), mas em Python puro (Pillow, numpy e scipy).
# Uso: python tools/area2_walk_mask.py docs/referencias/mapas/area2_vulcao_aviao/mapa_completo.png \
#   <pasta temporária> levels/world/art/volcano_walk.png
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

src, outdir, final = sys.argv[1:4]
px = np.asarray(Image.open(src).convert("RGB"), dtype=np.float32) / 255.0
h, w = px.shape[:2]
mx = px.max(-1); mn = px.min(-1)
sat = (mx - mn) / np.maximum(mx, 1e-4)
road = (mx > 0.55) & (sat < 0.2)


def box(mask, k):
    return ndimage.uniform_filter(mask.astype(np.float32), 2 * k + 1, mode="constant")


# Tira as linhas finas (trilhos, bordas claras das rochas) e junta as lajes separadas pelas juntas escuras.
m = box(road, 5) > 0.35
# Metade da resolução; fecha os vãos das escadas e das bases de lampião (lajes mais escuras).
m2 = ndimage.binary_closing(m[::2, ::2], iterations=10)
m2 = ndimage.binary_opening(m2, iterations=3)
H, W = m2.shape
yy, xx = np.mgrid[0:H, 0:W]


def ellipse(cx, cy, rx, ry, value=True):
    sel = ((xx - cx / 2) / (rx / 2)) ** 2 + ((yy - cy / 2) / (ry / 2)) ** 2 <= 1
    m2[sel] = value


# Entradas e pracinhas (pixels do mapa inteiro, 3200 x 1800).
ADD = [
    (1660, 1430, 70, 60),   # frente da mina (a estrada passa embaixo)
    (1660, 1500, 50, 50),   # descida da mina até a estrada
    (1090, 1130, 60, 40),   # pé da escada do avião
    (1040, 1110, 50, 40),   # do avião até a estrada
    (550, 1300, 90, 40),    # frente da tenda da loja
    (900, 1350, 60, 35),    # frente da tenda do Camarim
    # Escada em curva da Fênix, até a plataforma do ninho.
    (2770, 480, 50, 40), (2830, 450, 50, 40), (2870, 410, 50, 40), (2840, 365, 50, 40),
    (2790, 330, 50, 40), (2730, 290, 50, 40), (2670, 260, 50, 40), (2620, 240, 50, 40),
    (2720, 260, 120, 40),
    # Curva da frente da mina: as pedras pintadas na frente tapam a estrada e cortavam a máscara (o boneco
    # travava na curva; reclamação do usuário em 07/10/2026).
    (1140, 1530, 60, 50), (1120, 1560, 60, 40), (1165, 1580, 50, 30),
]
for e in ADD:
    ellipse(*e)
# O trem do acampamento: a cor das lajes pega o teto dos vagões; fica de fora tudo abaixo da beira da plataforma.
m2[(yy * 2 > 1215 + (xx * 2 - 200) * 0.46) & (xx * 2 < 760)] = False
lab, n = ndimage.label(m2)
sizes = ndimage.sum(np.ones_like(m2), lab, range(1, n + 1))
main = int(np.argmax(sizes)) + 1
keep = lab == main
# Tapa furos pequenos (bases de lampião, pedrinhas).
holes, nh = ndimage.label(~keep)
hs = ndimage.sum(np.ones_like(keep), holes, range(1, nh + 1))
for k, s in enumerate(hs, 1):
    if s < 600:
        keep[holes == k] = True
# Folga de uns 16 px (do mapa inteiro) para cada lado, com a beira arredondada (andar solto, como na Área 1).
keep = ndimage.binary_dilation(keep, iterations=8)
keep = ndimage.uniform_filter(keep.astype(np.float32), 7) > 0.5
holes, nh = ndimage.label(~keep)
hs = ndimage.sum(np.ones_like(keep), holes, range(1, nh + 1))
for k, s in enumerate(hs, 1):
    if s < 1500:
        keep[holes == k] = True
# Beira lisa, sem dentes de poucos pixels onde o boneco entrava e travava (tools/smooth_walk_mask.py).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from smooth_walk_mask import smooth  # noqa: E402
keep = smooth(keep)
Image.fromarray((keep * 255).astype(np.uint8)).save(final)
# Conferência: o mapa escurecido com a estrada em verde e uma grade a cada 100 px.
vis = px * 0.55
full = np.repeat(np.repeat(keep, 2, 0), 2, 1)[:h, :w]
vis[full] = vis[full] * 0.45 + np.array([0.2, 1.0, 0.3]) * 0.55
vis[:, ::100] = [0, 0.9, 1]
vis[::100, :] = [0, 0.9, 1]
Image.fromarray((vis * 255).astype(np.uint8)).resize((1600, 900)).save(outdir + "/volcano_walk_vis.png")
print("pedaços", n, "principal", int(sizes[main - 1]))
