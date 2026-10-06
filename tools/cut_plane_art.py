# Arte da viagem de avião (pedido E2, docs/prompts/chatgpt_aviao.md) para o jogo (levels/travel/art/).
# O avião voando: cada quadro de 768 x 512 é recentrado na horizontal pelo meio do desenho (os quadros vieram com
# até 60 px de diferença, o que dava tranco no voo); a altura fica como veio (o sobe e desce é de propósito).
# O céu, a fumaça e as nuvens da frente vão como vieram.
# Uso: python tools/cut_plane_art.py
import shutil
import numpy as np
from PIL import Image

SRC = "docs/referencias/pecas/aviao/"
OUT = "levels/travel/art/"
CELL = (768, 512)
sheet = Image.open(SRC + "aviao_voando.png").convert("RGBA")
out = Image.new("RGBA", sheet.size)
for row in range(2):
    for col in range(4):
        box = (col * CELL[0], row * CELL[1], (col + 1) * CELL[0], (row + 1) * CELL[1])
        cell = sheet.crop(box)
        xs = np.nonzero(np.asarray(cell)[..., 3].max(0) > 20)[0]
        shift = CELL[0] // 2 - (xs.min() + xs.max()) // 2
        out.paste(cell, (box[0] + shift, box[1]), cell)
out.save(OUT + "aviao_voando.png")
shutil.copy(SRC + "ceu_viagem.png", OUT + "ceu.png")
shutil.copy(SRC + "fumaca.png", OUT + "fumaca.png")
shutil.copy(SRC + "nuvens_frente.png", OUT + "nuvens_frente.png")
