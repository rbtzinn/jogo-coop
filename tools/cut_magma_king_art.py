"""Recorta a arte do Rei Magma (pedido do Vulcão, docs/prompts/chatgpt_chefoes_vulcao.md) para o jogo.

As folhas do ChatGPT não vieram na grade pedida (tamanhos fixos da ferramenta dele), então:
- folhas de animação: a grade é achada pela coluna/linha mais vazia perto de cada divisão esperada;
  cada quadro é recortado, ancorado no ponto de apoio (meio da base do desenho) e posto numa tela
  do mesmo tamanho para a animação toda, e sai um FrameAnimation (.tres) com escala e origem;
- efeitos: cada desenho solto (agrupado pelo vazio entre eles), ordenado por linha e coluna.

Uso (da raiz do projeto): python -I tools/cut_magma_king_art.py
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs", "referencias", "pecas", "vulcao")
OUT = os.path.join(ROOT, "bosses", "magma_king", "art")
RES_OUT = "res://bosses/magma_king/art"

# Animações: folha, colunas, linhas, quadros, escala no jogo (px do jogo por px da folha), âncora.
# "feet": meio da base do desenho fica em (0, 0); "center": meio do desenho.
# As escalas igualam o tamanho do rei entre folhas (medido pela largura da coroa).
ANIMATIONS = [
    ("rei_magma/rei_trono_parado.png", 4, 1, 4, 0.78, "feet", "throne_idle"),
    ("rei_magma/rei_cuspe.png", 4, 1, 4, 0.78, "feet", "spit"),
    ("rei_magma/rei_cetro.png", 4, 1, 4, 0.78, "feet", "scepter"),
    ("rei_magma/rei_coroa.png", 4, 1, 4, 0.78, "feet", "crown_throw"),
    ("rei_magma/rei_lago.png", 4, 2, 8, 1.1, "feet", "lake"),
    ("rei_magma/rei_derretido.png", 4, 2, 8, 1.15, "feet", "molten"),
    ("rei_magma/rei_derrota.png", 4, 1, 4, 0.78, "feet", "defeat"),
    ("rei_magma/rei_mao.png", 2, 1, 2, 0.2, "feet", "hand"),
    ("rei_magma/coluna_basalto.png", 4, 1, 4, 0.36, "feet", "column"),
    ("rei_magma/onda_lava.png", 4, 1, 4, 0.4, "feet", "wave"),
    ("rei_magma/jato_magma.png", 2, 1, 2, 0.5, "center", "jet"),
]

# Efeitos soltos de rei_efeitos.png, na ordem em que aparecem (linha por linha): nome e a escala
# usada no jogo (fica no código de cada efeito; aqui só como referência).
EFFECTS = [
    ("ball_1", 0.55), ("ball_2", 0.55), ("ball_3", 0.55), ("ball_4", 0.55),
    ("puddle_1", 0.8), ("puddle_2", 0.8), ("puddle_3", 0.8), ("puddle_4", 0.8),
    ("crown_1", 0.85), ("crown_2", 0.85), ("crown_3", 0.85), ("crown_4", 0.85),
    ("gem_1", 0.55), ("gem_2", 0.55), ("drop_1", 0.6), ("drop_2", 0.6), ("drop_parry", 0.6),
    ("splash_1", 0.6), ("splash_2", 0.6), ("splash_3", 0.6),
]

ALPHA = 40


def load(name):
    return np.array(Image.open(os.path.join(SRC, name)).convert("RGBA"))


def split_points(alpha, size, parts, axis):
    """Divisões da grade: perto de cada divisão esperada, a linha (ou coluna) com menos desenho."""
    counts = alpha.sum(axis=axis)
    points = [0]
    cell = size / parts
    for k in range(1, parts):
        lo = int(cell * k - cell * 0.15)
        hi = int(cell * k + cell * 0.15)
        window = counts[lo:hi]
        best = np.flatnonzero(window == window.min())
        points.append(lo + int(best[len(best) // 2]))
    points.append(size)
    return points


def anchor_of(mask, kind):
    ys, xs = np.nonzero(mask)
    if kind == "center":
        return (xs.min() + xs.max()) / 2.0, (ys.min() + ys.max()) / 2.0
    bottom = ys.max()
    band = ys >= bottom - 30
    return float(xs[band].mean()), float(bottom)


def write_tres(name, files, scale, origin):
    lines = ['[gd_resource type="Resource" script_class="FrameAnimation" load_steps=%d format=3]' % (len(files) + 2), ""]
    lines.append('[ext_resource type="Script" path="res://core/player/characters/frame_animation.gd" id="1_script"]')
    for i, f in enumerate(files):
        lines.append('[ext_resource type="Texture2D" path="%s/%s" id="%d_frame"]' % (RES_OUT, f, i + 2))
    lines += ["", "[resource]", 'script = ExtResource("1_script")']
    refs = ", ".join('ExtResource("%d_frame")' % (i + 2) for i in range(len(files)))
    lines.append("frames = Array[Texture2D]([%s])" % refs)
    lines.append("frame_scale = %s" % scale)
    lines.append("origin = Vector2(%.2f, %.2f)" % origin)
    with open(os.path.join(OUT, name + ".tres"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")


def cut_animation(sheet, cols, rows, count, scale, kind, name):
    image = load(sheet)
    alpha = image[:, :, 3] > ALPHA
    h, w = alpha.shape
    xs = split_points(alpha, w, cols, 0)
    ys = split_points(alpha, h, rows, 1)
    crops = []
    for r in range(rows):
        for c in range(cols):
            if len(crops) == count:
                break
            cell = image[ys[r]:ys[r + 1], xs[c]:xs[c + 1]]
            mask = cell[:, :, 3] > ALPHA
            # Só o desenho principal da célula e o que está perto dele (respingos soltos ficam).
            label, n = ndimage.label(ndimage.binary_dilation(mask, iterations=12))
            if n > 1:
                sizes = ndimage.sum(mask, label, range(1, n + 1))
                keep = np.isin(label, [i + 1 for i, s in enumerate(sizes) if s > sizes.max() * 0.02])
                cell = cell.copy()
                cell[~keep] = 0
                mask = cell[:, :, 3] > ALPHA
            yy, xx = np.nonzero(cell[:, :, 3] > 8)
            box = (xx.min(), yy.min(), xx.max() + 1, yy.max() + 1)
            ax, ay = anchor_of(mask, kind)
            crops.append((cell[box[1]:box[3], box[0]:box[2]], ax - box[0], ay - box[1]))
    left = max(ax for _, ax, _ in crops)
    top = max(ay for _, _, ay in crops)
    right = max(c.shape[1] - ax for c, ax, _ in crops)
    bottom = max(c.shape[0] - ay for c, _, ay in crops)
    width, height = int(np.ceil(left + right)), int(np.ceil(top + bottom))
    files = []
    for i, (crop, ax, ay) in enumerate(crops):
        canvas = Image.new("RGBA", (width, height))
        canvas.paste(Image.fromarray(crop), (int(round(left - ax)), int(round(top - ay))))
        file = "%s_%d.png" % (name, i + 1)
        canvas.save(os.path.join(OUT, file))
        files.append(file)
    write_tres(name, files, scale, (-left * scale, -top * scale))
    print("%-12s %d quadros, tela %dx%d, escala %.2f" % (name, len(files), width, height, scale))


def cut_effects():
    image = load("rei_magma/rei_efeitos.png")
    mask = image[:, :, 3] > ALPHA
    label, n = ndimage.label(ndimage.binary_dilation(mask, iterations=6))
    objects = ndimage.find_objects(label)
    sizes = ndimage.sum(mask, label, range(1, n + 1))
    blobs = [(o, i + 1) for i, o in enumerate(objects) if sizes[i] > 1500]
    # Linha: pelo meio vertical (as linhas da folha ficam bem separadas); depois da esquerda para a direita.
    blobs.sort(key=lambda b: (int((b[0][0].start + b[0][0].stop) / 2 // 200), b[0][1].start))
    if len(blobs) != len(EFFECTS):
        sys.exit("efeitos: achei %d desenhos, esperava %d" % (len(blobs), len(EFFECTS)))
    for (obj, index), (name, scale) in zip(blobs, EFFECTS):
        crop = image[obj].copy()
        crop[label[obj] != index] = 0
        Image.fromarray(crop).save(os.path.join(OUT, "fx_" + name + ".png"))
    print("efeitos     %d desenhos" % len(blobs))
    with open(os.path.join(OUT, "effects_scale.txt"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join("%s %s" % e for e in EFFECTS) + "\n")


def copy_single(sheet, name, crop_alpha=True):
    image = Image.open(os.path.join(SRC, sheet)).convert("RGBA")
    if crop_alpha:
        # Só o que é desenho de verdade (a ferramenta deixa um brilho quase invisível em volta).
        solid = image.getchannel("A").point(lambda a: 255 if a > 8 else 0)
        image = image.crop(solid.getbbox())
    image.save(os.path.join(OUT, name))
    print("%-12s %dx%d" % (name, image.width, image.height))


def main():
    os.makedirs(OUT, exist_ok=True)
    # Começa do zero (os .import da Godot ficam, para não reimportar o que não mudou).
    for file in os.listdir(OUT):
        if file.endswith((".png", ".tres")):
            os.remove(os.path.join(OUT, file))
    for entry in ANIMATIONS:
        cut_animation(*entry)
    cut_effects()
    copy_single("rei_magma/rei_trono.png", "throne.png")
    copy_single("arenas/jangada_basalto.png", "raft.png")
    copy_single("arenas/arena_rei.png", "arena.png", False)
    copy_single("arenas/arena_rei_fase3.png", "arena_phase3.png", False)


if __name__ == "__main__":
    main()
