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

    def _pack_animation(self, name, crops, scale, padding):
        """Normaliza quadros já isolados numa tela comum, com margem transparente de segurança."""
        left = max(ax for _, ax, _ in crops) + padding
        top = max(ay for _, _, ay in crops) + padding
        right = max(c.shape[1] - ax for c, ax, _ in crops) + padding
        bottom = max(c.shape[0] - ay for c, _, ay in crops) + padding
        width, height = int(np.ceil(left + right)), int(np.ceil(top + bottom))
        files = []
        for i, (crop, ax, ay) in enumerate(crops):
            canvas = Image.new("RGBA", (width, height))
            canvas.paste(Image.fromarray(crop), (int(round(left - ax)), int(round(top - ay))))
            file = "%s_%d.png" % (name, i + 1)
            canvas.save(os.path.join(self.out, file))
            files.append(file)
        self.write_tres(name, files, scale, (-left * scale, -top * scale))
        print("%-14s %d quadros, tela %dx%d, escala %.2f, margem %d" %
                (name, len(files), width, height, scale, padding))

    def animation(self, sheet, cols, rows, count, scale, kind, name, first=0, ratio=0.02,
            padding=16, row_specific=True):
        """Folha em grade (cols x rows), `count` quadros a partir do quadro `first`. `kind`: "feet" ou "center"."""
        image = self.load(sheet)
        alpha = image[:, :, 3] > ALPHA
        h, w = alpha.shape
        ys = split_points(alpha, h, rows, 1)
        global_xs = split_points(alpha, w, cols, 0)
        crops = []
        for index in range(first, first + count):
            r, c = divmod(index, cols)
            # Cada linha das folhas geradas pode ter uma grade horizontal diferente. Usar uma única divisão
            # para a folha inteira cortava, por exemplo, a mão do Bigorna e trazia a cabeça da Fênix vizinha.
            row_alpha = alpha[ys[r]:ys[r + 1]]
            xs = split_points(row_alpha, w, cols, 0) if row_specific else global_xs
            cell = keep_main(image[ys[r]:ys[r + 1], xs[c]:xs[c + 1]], ratio)
            mask = cell[:, :, 3] > ALPHA
            yy, xx = np.nonzero(cell[:, :, 3] > 8)
            box = (xx.min(), yy.min(), xx.max() + 1, yy.max() + 1)
            ax, ay = anchor_of(mask, kind)
            crops.append((cell[box[1]:box[3], box[0]:box[2]], ax - box[0], ay - box[1]))
        self._pack_animation(name, crops, scale, padding)

    def animation_components(self, sheet, cols, rows, count, scale, kind, name, reach=6,
            seed_ratio=0.05, near=150, padding=24):
        """Recorta poses que se sobrepõem à grade sem misturar quadros vizinhos.

        As silhuetas principais são separadas pelo alfa da folha inteira. Penas, fumaça e outros pedaços
        soltos são anexados à pose mais próxima. Depois cada pose recebe a mesma tela e uma margem transparente,
        impedindo vazamento de um quadro no outro e recorte pela filtragem da textura.
        """
        image = self.load(sheet)
        mask = image[:, :, 3] > ALPHA
        joined = ndimage.binary_dilation(mask, iterations=reach) if reach > 0 else mask
        label, n = ndimage.label(joined)
        objects = ndimage.find_objects(label)
        sizes = np.asarray(ndimage.sum(mask, label, range(1, n + 1)))
        if not sizes.size:
            raise ValueError("Animação vazia: " + sheet)
        seeds = [i + 1 for i, size in enumerate(sizes) if size > sizes.max() * seed_ratio]
        if len(seeds) != count:
            raise ValueError("%s: achei %d poses principais, esperava %d" % (sheet, len(seeds), count))

        def bounds(component):
            obj = objects[component - 1]
            return (obj[1].start, obj[0].start, obj[1].stop, obj[0].stop)

        def center(component):
            box = bounds(component)
            return ((box[0] + box[2]) * 0.5, (box[1] + box[3]) * 0.5)

        # Organiza por linha de leitura, mesmo quando uma asa ou martelo invade a linha geométrica vizinha.
        by_y = sorted(seeds, key=lambda component: center(component)[1])
        ordered = []
        for row in range(rows):
            row_seeds = by_y[row * cols:min((row + 1) * cols, count)]
            ordered.extend(sorted(row_seeds, key=lambda component: center(component)[0]))

        assigned = {component: [component] for component in ordered}

        def gap(a, b):
            aa, bb = bounds(a), bounds(b)
            dx = max(aa[0] - bb[2], bb[0] - aa[2], 0)
            dy = max(aa[1] - bb[3], bb[1] - aa[3], 0)
            return max(dx, dy)

        for component in range(1, n + 1):
            if component in assigned or objects[component - 1] is None or sizes[component - 1] < 8:
                continue
            host = min(ordered, key=lambda seed: gap(component, seed))
            if gap(component, host) <= near:
                assigned[host].append(component)

        crops = []
        for seed in ordered:
            frame_mask = np.isin(label, assigned[seed]) & mask
            seed_mask = (label == seed) & mask
            yy, xx = np.nonzero(frame_mask)
            box = (xx.min(), yy.min(), xx.max() + 1, yy.max() + 1)
            ax, ay = anchor_of(seed_mask, kind)
            crop = image[box[1]:box[3], box[0]:box[2]].copy()
            crop[~frame_mask[box[1]:box[3], box[0]:box[2]]] = 0
            crops.append((crop, ax - box[0], ay - box[1]))
        self._pack_animation(name, crops, scale, padding)

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

    def row_effects(self, sheet, row_tops, names, reach=3, min_area=150, near=40):
        """Desenhos soltos em linhas de alturas diferentes (a grade da folha não é regular). `row_tops`: o y
        onde cada linha começa; `names`: uma lista de nomes por linha, da esquerda para a direita; `reach`: um
        número, ou um por linha (o quanto juntar pontinhos vizinhos). Pedaços pequenos (labaredas e faíscas
        em volta) juntam-se ao desenho grande mais perto, se estiverem a até `near` px dele."""
        image = self.load(sheet)
        mask = image[:, :, 3] > ALPHA
        bounds = list(row_tops) + [image.shape[0]]
        count = 0
        for r, row_names in enumerate(names):
            row_reach = reach[r] if isinstance(reach, (list, tuple)) else reach
            row_mask = np.zeros_like(mask)
            row_mask[bounds[r]:bounds[r + 1]] = mask[bounds[r]:bounds[r + 1]]
            label, n = ndimage.label(ndimage.binary_dilation(row_mask, iterations=row_reach))
            label[~row_mask] = 0
            objects = ndimage.find_objects(label)
            sizes = ndimage.sum(row_mask, label, range(1, n + 1))
            blobs = [[o[1].start, o[1].stop, o[0].start, o[0].stop, [i + 1], sizes[i]]
                    for i, o in enumerate(objects) if o is not None and sizes[i] >= min_area]
            biggest = max(b[5] for b in blobs)
            big = [b for b in blobs if b[5] >= biggest * 0.1]
            for blob in [b for b in blobs if b[5] < biggest * 0.1]:
                def gap(other):
                    dx = max(other[0] - blob[1], blob[0] - other[1], 0)
                    dy = max(other[2] - blob[3], blob[2] - other[3], 0)
                    return max(dx, dy)
                host = min(big, key=gap)
                if gap(host) <= near:
                    host[0], host[1] = min(host[0], blob[0]), max(host[1], blob[1])
                    host[2], host[3] = min(host[2], blob[2]), max(host[3], blob[3])
                    host[4] += blob[4]
                elif blob[5] >= biggest * 0.03:
                    big.append(blob)
            big.sort(key=lambda b: b[0])
            if len(big) != len(row_names):
                sys.exit("%s linha %d: achei %d desenhos, esperava %d" % (sheet, r + 1, len(big), len(row_names)))
            for blob, name in zip(big, row_names):
                crop = image[blob[2]:blob[3], blob[0]:blob[1]].copy()
                crop[~np.isin(label[blob[2]:blob[3], blob[0]:blob[1]], blob[4])] = 0
                Image.fromarray(crop).save(os.path.join(self.out, name + ".png"))
                count += 1
        print("%-14s %d desenhos" % (os.path.basename(sheet), count))

    def grid_effects(self, sheet, cols, rows, names, ratio=0.02, adaptive=False):
        """Um desenho por célula; `adaptive` divide no vazio entre desenhos de larguras diferentes.
        `names` em ordem de leitura (None pula a célula)."""
        image = self.load(sheet)
        h, w = image.shape[:2]
        if adaptive:
            alpha = image[:, :, 3] > ALPHA
            xs = split_points(alpha, w, cols, 0)
            ys = split_points(alpha, h, rows, 1)
        else:
            xs = [int(c * w / cols) for c in range(cols + 1)]
            ys = [int(r * h / rows) for r in range(rows + 1)]
        count = 0
        for index, name in enumerate(names):
            if name is None:
                continue
            r, c = divmod(index, cols)
            cell = keep_main(image[ys[r]:ys[r + 1], xs[c]:xs[c + 1]], ratio)
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
