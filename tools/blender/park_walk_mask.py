# Máscara da terra onde se anda no mapa ampliado (levels/world/art/park_walk.png, metade da resolução).
# A terra batida é achada pela cor; fica só o pedaço principal (ligado), os furinhos (bases de lampião,
# pedras) são tapados, e as entradas que a cor não pega (tapetes, escadas, portão, plataforma) entram à mão.
# Uso: blender -b --python tools/blender/park_walk_mask.py -- \
#   docs/referencias/remap_conceitos/mapa_amplo_4partes/mapa_completo.png <pasta temporária> levels/world/art/park_walk.png
import bpy, sys, numpy as np
from collections import deque
a = sys.argv[sys.argv.index("--")+1:]
src, outdir, final = a[0], a[1], a[2]
img = bpy.data.images.load(src); w, h = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1][..., :3]
r, g, b = px[...,0], px[...,1], px[...,2]
mx = px.max(-1); mn = px.min(-1)
sat = (mx-mn)/np.maximum(mx,1e-4)
gr = g/np.maximum(r,1e-4)
dirt = (r > g) & (g > b) & (gr > 0.5) & (gr < 0.8) & (sat > 0.3) & (sat < 0.75) & (mx > 0.35)
def box(mask, k):
    pad = np.pad(mask.astype(np.float32), k)
    c = np.cumsum(np.cumsum(pad,0),1)
    c = np.pad(c, ((1,0),(1,0)))
    s = c[2*k+1:, 2*k+1:] - c[:-2*k-1, 2*k+1:] - c[2*k+1:, :-2*k-1] + c[:-2*k-1, :-2*k-1]
    return s[:h,:w] / (2*k+1)**2
m = box(dirt, 6) > 0.45
m = box(m, 4) > 0.5
def components(mask):
    lab = np.full(mask.shape, -1, np.int32); sizes = []
    H, W = mask.shape
    for y0 in range(H):
        row = mask[y0]
        for x0 in np.nonzero(row & (lab[y0] < 0))[0]:
            if lab[y0, x0] >= 0: continue
            k = len(sizes); q = deque([(y0, x0)]); lab[y0, x0] = k; n = 0
            while q:
                y, x = q.popleft(); n += 1
                for yy, xx in ((y+1,x),(y-1,x),(y,x+1),(y,x-1)):
                    if 0 <= yy < H and 0 <= xx < W and mask[yy,xx] and lab[yy,xx] < 0:
                        lab[yy,xx] = k; q.append((yy,xx))
            sizes.append(n)
    return lab, sizes
# Work at half resolution.
m2 = m[::2, ::2].copy()
H, W = m2.shape
yy, xx = np.mgrid[0:H, 0:W]
def ellipse(cx, cy, rx, ry, value=True):
    sel = ((xx - cx/2)/(rx/2))**2 + ((yy - cy/2)/(ry/2))**2 <= 1
    m2[sel] = value
# Entradas e tapetes (pixels da imagem inteira 1672 x 941).
ADD = [
    (365, 205, 45, 14),    # tapete do Domador
    (1022, 205, 40, 14),   # tapete dos Malabaristas
    (1418, 282, 45, 13),   # tapete do Mágico
    (238, 530, 40, 18),    # escada do Camarim
    (300, 545, 70, 22),    # frente do Camarim
    (590, 585, 45, 14),    # escada da loja
    (362, 725, 35, 32),    # sob o arco do portão
    (362, 790, 35, 40),    # dentro do portão
    (355, 850, 50, 30),    # caminho de pedra
    (335, 905, 100, 36),   # chegada do portão
    (1300, 640, 30, 30),   # subida da estação
    (1320, 680, 30, 30),
    (1365, 730, 60, 30),   # plataforma da estação
]
for e in ADD: ellipse(*e)
# Obstáculos que a cor pegou como terra (pilar claro do portão).
REMOVE = [
    (432, 795, 34, 62),    # pilar direito do portão
]
for e in REMOVE: ellipse(*e, value=False)
lab, sizes = components(m2)
main = int(np.argmax(sizes))
keep = lab == main
# Tapa furos pequenos (bases de lampião, pedrinhas).
lab2, sizes2 = components(~keep)
for k, n in enumerate(sizes2):
    if n < 600: keep[lab2 == k] = True
# Folga de uns 20 px (do conjunto) para cada lado da terra, com a beira arredondada: andar solto, sem engasgar
# nos dentes da cor (pedido do usuário em 05/10/2026).
MARGIN = 10
def box_half(mask, k):
    pad = np.pad(mask.astype(np.float32), k)
    c = np.cumsum(np.cumsum(pad,0),1)
    c = np.pad(c, ((1,0),(1,0)))
    s = c[2*k+1:, 2*k+1:] - c[:-2*k-1, 2*k+1:] - c[2*k+1:, :-2*k-1] + c[:-2*k-1, :-2*k-1]
    return s[:H,:W] / (2*k+1)**2
for step in range(MARGIN):
    keep = box_half(keep, 1) > 0.05
keep = box_half(keep, 3) > 0.5
lab3, sizes3 = components(~keep)
for k, n in enumerate(sizes3):
    if n < 1500: keep[lab3 == k] = True
np.save(outdir + "/walk_half.npy", keep)
o = bpy.data.images.new("m", W, H)
g = keep.astype(np.float32)
o.pixels = np.dstack([g, g, g, np.ones_like(g)])[::-1].ravel()
o.filepath_raw = final; o.file_format = "PNG"; o.save()
vis = px*0.55
full = np.repeat(np.repeat(keep, 2, 0), 2, 1)[:h, :w]
vis[full] = vis[full]*0.45 + np.array([0.2,1.0,0.3])*0.55
for x in range(0, w, 50): vis[:, x] = [0,0.9,1] if x%100==0 else [0,0.45,0.5]
for y in range(0, h, 50): vis[y, :] = [0,0.9,1] if y%100==0 else [0,0.45,0.5]
v = bpy.data.images.new("v", w, h); v.pixels = np.dstack([vis, np.ones((h,w))])[::-1].ravel()
v.filepath_raw = outdir + "/walk_vis.png"; v.file_format="PNG"; v.save()
print("componentes", len(sizes), "principal", sizes[main])
