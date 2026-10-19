"""Recorta o desenho-base do Maestro Ferrugem em peças para o boneco articulado da luta.

Uso (na pasta do projeto): python3 tools/cut_maestro_rig.py
Lê bosses/rust_maestro/art/p01_base.png e grava bosses/rust_maestro/art/rig/<peça>.png.
Cada peça é cortada no próprio retângulo visível; o canto (x, y) no desenho-base sai no
terminal e fica em MaestroActor.PIECES. Os pixels não são alterados, só separados; some só o
chuvisco quase invisível (alfa até 4) que a geração deixou espalhado pelo fundo.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "bosses/rust_maestro/art/p01_base.png"
OUT = ROOT / "bosses/rust_maestro/art/rig"

# Contornos no desenho-base (1254x1254). O que não cai em nenhum vai para o tronco.
REGIONS = {
    "baton_arm": [(0, 0), (618, 0), (618, 400), (632, 400), (632, 520), (600, 560), (560, 585), (0, 585)],
    "head": [(615, 120), (850, 120), (850, 252), (822, 252), (822, 396), (615, 396)],
    "free_arm": [(965, 380), (1254, 380), (1254, 700), (880, 700), (880, 528), (965, 528)],
    "legs": [(0, 700), (1254, 700), (1254, 1254), (0, 1254)],
}


def mask(size, points):
    image = Image.new("L", size, 0)
    ImageDraw.Draw(image).polygon(points, fill=255)
    return np.array(image) > 0


def main():
    base = np.array(Image.open(SOURCE).convert("RGBA"))
    base[base[:, :, 3] <= 4] = 0
    size = (base.shape[1], base.shape[0])
    taken = np.zeros(base.shape[:2], bool)
    pieces = {}
    for name, points in REGIONS.items():
        region = mask(size, points) & ~taken
        taken |= region
        pieces[name] = region
    pieces["torso"] = ~taken
    OUT.mkdir(parents=True, exist_ok=True)
    for name, region in pieces.items():
        piece = base.copy()
        piece[~region] = 0
        ys, xs = np.nonzero(piece[:, :, 3] > 0)
        left, top, right, bottom = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        Image.fromarray(piece[top:bottom, left:right]).save(OUT / f"{name}.png", optimize=True)
        print(f'"{name}": Vector2({left}, {top}),  # {right - left}x{bottom - top}')


if __name__ == "__main__":
    main()
