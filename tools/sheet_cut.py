"""Recorte das folhas de arte do ChatGPT para o jogo (usado pelos scripts cut_*_art.py dos chefões).

As folhas não vêm na grade pedida (a ferramenta dele gera em tamanhos fixos), então:
- animações: a grade é achada pela coluna/linha mais vazia perto de cada divisão esperada; cada quadro é
  recortado, ancorado no ponto de apoio (meio da base do desenho, ou o meio dele) e posto numa tela do
  mesmo tamanho para a animação toda; sai um FrameAnimation (.tres) com escala e origem;
- efeitos soltos: cada desenho (agrupado pelo vazio entre eles), ordenado por linha e coluna;
- efeitos em grade regular: uma célula por desenho.
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ALPHA = 40


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


def keep_main(cell, ratio=0.02, reach=12):
    """Só o desenho principal da célula e o que está perto dele (pedaços soltos de vizinhos saem)."""
    mask = cell[:, :, 3] > ALPHA
    label, n = ndimage.label(ndimage.binary_dilation(mask, iterations=reach))
    if n <= 1:
        return cell
    sizes = ndimage.sum(mask, label, range(1, n + 1))
    keep = np.isin(label, [i + 1 for i, s in enumerate(sizes) if s > sizes.max() * ratio])
    cell = cell.copy()
    cell[~keep] = 0
    return cell


class SheetCutter:
    def __init__(self, src, out, res_out):
        self.src = src
        self.out = out
        self.res_out = res_out

    def clean(self):
        """Começa do zero (os .import da Godot ficam, para não reimportar o que não mudou)."""
        os.makedirs(self.out, exist_ok=True)
        for file in os.listdir(self.out):
            if file.endswith((".png", ".tres")):
                os.remove(os.path.join(self.out, file))

    def load(self, name):
        return np.array(Image.open(os.path.join(self.src, name)).convert("RGBA"))

    def write_tres(self, name, files, scale, origin):
        lines = ['[gd_resource type="Resource" script_class="FrameAnimation" load_steps=%d format=3]' % (len(files) + 2), ""]
        lines.append('[ext_resource type="Script" path="res://core/player/characters/frame_animation.gd" id="1_script"]')
        for i, f in enumerate(files):
            lines.append('[ext_resource type="Texture2D" path="%s/%s" id="%d_frame"]' % (self.res_out, f, i + 2))
        lines += ["", "[resource]", 'script = ExtResource("1_script")']
        refs = ", ".join('ExtResource("%d_frame")' % (i + 2) for i in range(len(files)))
        lines.append("frames = Array[Texture2D]([%s])" % refs)
        lines.append("frame_scale = %s" % scale)
        lines.append("origin = Vector2(%.2f, %.2f)" % origin)
        with open(os.path.join(self.out, name + ".tres"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(lines) + "\n")

    def animation(self, sheet, cols, rows, count, scale, kind, name, first=0):
        """Folha em grade (cols x rows), `count` quadros a partir do quadro `first`. `kind`: "feet" ou "center"."""
        image = self.load(sheet)
        alpha = image[:, :, 3] > ALPHA
        h, w = alpha.shape
        xs = split_points(alpha, w, cols, 0)
        ys = split_points(alpha, h, rows, 1)
        crops = []
        for index in range(first, first + count):
            r, c = divmod(index, cols)
            cell = keep_main(image[ys[r]:ys[r + 1], xs[c]:xs[c + 1]])
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
            canvas.save(os.path.join(self.out, file))
            files.append(file)
        self.write_tres(name, files, scale, (-left * scale, -top * scale))
        print("%-14s %d quadros, tela %dx%d, escala %.2f" % (name, len(files), width, height, scale))

    def loose_effects(self, sheet, names, reach=6, min_area=1500, row_band=200):
        """Desenhos soltos, em ordem de leitura (linha por faixa de `row_band` px, depois da esquerda)."""
        image = self.load(sheet)
        mask = image[:, :, 3] > ALPHA
        label, n = ndimage.label(ndimage.binary_dilation(mask, iterations=reach))
        objects = ndimage.find_objects(label)
        sizes = ndimage.sum(mask, label, range(1, n + 1))
        blobs = [(o, i + 1) for i, o in enumerate(objects) if sizes[i] > min_area]
        blobs.sort(key=lambda b: (int((b[0][0].start + b[0][0].stop) / 2 // row_band), b[0][1].start))
        if len(blobs) != len(names):
            sys.exit("%s: achei %d desenhos, esperava %d" % (sheet, len(blobs), len(names)))
        for (obj, index), name in zip(blobs, names):
            crop = image[obj].copy()
            crop[label[obj] != index] = 0
            Image.fromarray(crop).save(os.path.join(self.out, name + ".png"))
        print("%-14s %d desenhos" % (os.path.basename(sheet), len(blobs)))

    def grid_effects(self, sheet, cols, rows, names):
        """Um desenho por célula de uma grade regular; `names` em ordem de leitura (None pula a célula)."""
        image = self.load(sheet)
        h, w = image.shape[:2]
        count = 0
        for index, name in enumerate(names):
            if name is None:
                continue
            r, c = divmod(index, cols)
            cell = keep_main(image[int(r * h / rows):int((r + 1) * h / rows), int(c * w / cols):int((c + 1) * w / cols)])
            yy, xx = np.nonzero(cell[:, :, 3] > 8)
            Image.fromarray(cell[yy.min():yy.max() + 1, xx.min():xx.max() + 1]).save(os.path.join(self.out, name + ".png"))
            count += 1
        print("%-14s %d desenhos" % (os.path.basename(sheet), count))

    def single(self, sheet, name, crop_alpha=True):
        image = Image.open(os.path.join(self.src, sheet)).convert("RGBA")
        if crop_alpha:
            # Só o que é desenho de verdade (a ferramenta deixa um brilho quase invisível em volta).
            solid = image.getchannel("A").point(lambda a: 255 if a > 8 else 0)
            image = image.crop(solid.getbbox())
        image.save(os.path.join(self.out, name))
        print("%-14s %dx%d" % (name, image.width, image.height))
