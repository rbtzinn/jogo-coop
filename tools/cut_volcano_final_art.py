"""Prepara as artes do Mestre Bigorna e do Coração, sem apagar artes de outros chefões.
Uso: python -I tools/cut_volcano_final_art.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet_cut import SheetCutter, split_points, keep_main, ALPHA

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "docs", "referencias", "pecas", "vulcao")


def cutter(folder):
    out = os.path.join(ROOT, "bosses", folder, "art")
    os.makedirs(out, exist_ok=True)
    return SheetCutter(SOURCE, out, "res://bosses/%s/art" % folder)


def effect_rows(cut, sheet, names):
    """As linhas têm quantidades diferentes; cada uma é dividida pelo vazio entre os desenhos."""
    image = cut.load(sheet)
    ys = split_points(image[:, :, 3] > ALPHA, image.shape[0], len(names), 1)
    for row, entry in enumerate(names):
        row_names, fraction = entry if isinstance(entry, tuple) else (entry, 1.0)
        strip = image[ys[row]:ys[row + 1]]
        strip = strip[:, :int(strip.shape[1] * fraction)]
        xs = split_points(strip[:, :, 3] > ALPHA, strip.shape[1], len(row_names), 0)
        for i, name in enumerate(row_names):
            cell = keep_main(strip[:, xs[i]:xs[i + 1]], ratio=0.15, reach=5)
            yy, xx = np.nonzero(cell[:, :, 3] > 8)
            if not len(xx):
                raise ValueError("Efeito vazio: " + name)
            Image.fromarray(cell[yy.min():yy.max() + 1, xx.min():xx.max() + 1]).save(
                os.path.join(cut.out, name + ".png"))


def frames(prefix, n):
    return ["%s_%d" % (prefix, i + 1) for i in range(n)]


def main():
    forge = cutter("anvil_master")
    forge_animations = [
        ("parado", 4, 1, 4, 0.78, "idle"),
        ("martelada", 4, 1, 4, 0.78, "hammer"),
        ("arremesso", 4, 1, 4, 0.78, "throw"),
        ("fole", 4, 1, 4, 0.78, "bellows"),
        ("andando", 4, 2, 8, 1.0, "walk"),
        ("armadura", 4, 2, 8, 1.22, "armor"),
        ("derrota", 4, 1, 4, 0.78, "defeat"),
    ]
    for sheet, cols, rows, n, scale, name in forge_animations:
        source = "bigorna/bigorna_%s.png" % sheet
        if rows == 1:
            # Nestes desenhos, martelo, ferradura, chama e fole invadem a célula vizinha da folha.
            reach = 8 if name == "defeat" else 2
            forge.animation_components(source, cols, rows, n, scale, "feet", name, reach=reach,
                    seed_ratio=0.05, near=130, padding=24)
        else:
            # As duas linhas têm divisões horizontais diferentes; SheetCutter mede cada uma separadamente.
            forge.animation(source, cols, rows, n, scale, "feet", name, ratio=0.2, padding=24)
    forge.animation("bigorna/onda_choque.png", 4, 1, 4, 0.65, "feet", "wave")
    forge.animation("bigorna/canal_derretido.png", 1, 2, 2, 0.42, "feet", "channel")
    # Cabeça do martelo já desenhada na pose de aviso; contorno segue o ferro, excluindo a mão.
    hammer = Image.open(os.path.join(forge.out, "hammer_1.png"))
    mask = Image.new("L", hammer.size)
    ImageDraw.Draw(mask).polygon([(393, 68), (425, 20), (480, 0), (533, 6), (558, 40),
        (579, 90), (580, 160), (551, 180), (510, 196), (490, 166), (468, 145),
        (463, 95), (431, 72)], fill=255)
    isolated = np.array(hammer)
    isolated[np.array(mask) == 0] = 0
    Image.fromarray(isolated).crop((390, 0, 584, 200)).save(os.path.join(forge.out, "hammer_head.png"))
    forge.single("bigorna/bigorna_anvil.png", "anvil.png")
    forge.grid_effects("arenas/corrente_plataforma.png", 2, 1, ["platform_1", "platform_2"], adaptive=True)
    effect_rows(forge, "bigorna/bigorna_efeitos.png", [
        frames("shoe", 4) + frames("shoe_parry", 4),
        frames("small_anvil", 4) + frames("anvil_hit", 2) + frames("warning", 2),
        frames("spark", 4) + frames("ember", 4),
        frames("rock", 2) + ["rock_warning"] + frames("dust", 2) + frames("steam", 3),
    ])
    forge.single("arenas/arena_bigorna.png", "arena.png", False)
    forge.single("arenas/arena_bigorna_fase3.png", "arena_hot.png", False)

    heart = cutter("volcano_heart")
    for sheet, cols, rows, n, scale, name in [
        ("batida", 4, 1, 4, 0.85, "beat"),
        ("ecos", 4, 1, 4, 0.85, "echo"),
        ("livre", 4, 2, 8, 1.1, "free"),
        ("derrota", 4, 1, 4, 0.85, "defeat"),
        ("mascara", 4, 1, 4, 0.44, "mask"),
    ]:
        heart.animation("coracao/coracao_%s.png" % sheet, cols, rows, n, scale, "center", name,
                ratio=0.2, padding=0, row_specific=False)
    heart.animation("coracao/anel_choque.png", 4, 1, 4, 0.6, "feet", "ring", padding=0,
            row_specific=False)
    heart.animation("coracao/valvula.png", 2, 1, 2, 0.28, "feet", "valve", padding=0,
            row_specific=False)
    heart.grid_effects("coracao/selos.png", 3, 1, frames("seal", 3), adaptive=True)
    heart.grid_effects("arenas/plataforma_erupcao.png", 3, 1, frames("platform", 3), adaptive=True)
    effect_rows(heart, "coracao/coracao_efeitos.png", [
        frames("ball", 4) + frames("drop_parry", 4),
        frames("echo_crown", 2) + frames("echo_feather", 2) + frames("echo_shoe", 2) + frames("puff", 2),
        (frames("artery", 4), 0.5), (frames("jet", 4), 0.5),
    ])
    heart.single("arenas/arena_coracao.png", "arena.png", False)
    heart.single("arenas/arena_coracao_fase3.png", "arena_hot.png", False)


if __name__ == "__main__":
    main()
