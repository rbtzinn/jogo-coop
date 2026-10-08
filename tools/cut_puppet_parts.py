"""Recorta as peças do rig novo do palhaço (docs/animacao_rig.md) para o jogo.

Lê as peças geradas (docs/referencias/pecas/palhaco_rig/, 1024x1024), corta a margem e reduz cada uma para
o tamanho do jogo em 2x (o Sprite2D usa escala 0,5, como as peças antigas). Os tamanhos vêm do idle_1.png
(o desenho que está no jogo): cabeça com 122 unidades de largura, barriga com 79, gola com 84...
Chapéu e flor saem da clown_head.png antiga, separados pela cor.

Uso: python -I tools/cut_puppet_parts.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/referencias/pecas/palhaco_rig"
OUT = ROOT / "core/player/characters/clown/puppet/art"
OLD_HEAD = ROOT / "core/player/characters/clown/clown_head.png"

# Largura final da textura (pixels, 2x as unidades do rig).
WIDTHS = {
    "head_happy": 244, "head_blink": 244, "head_surprise": 244, "head_effort": 244,
    "torso": 158, "collar": 168, "leg_strip": 40, "arm_strip": 20, "glove_open": 72,
}
# A cabeça nova (sem chapéu) é 1,26x a antiga: o chapéu e a flor crescem junto.
OLD_HEAD_SCALE = 1.26


def trim(image: Image.Image) -> Image.Image:
    return image.crop(image.getbbox())


def resize_to_width(image: Image.Image, width: int) -> Image.Image:
    height = max(1, round(image.height * width / image.width))
    return image.resize((width, height), Image.LANCZOS)


def mask_from(image: Image.Image, keep, grow: int = 5) -> Image.Image:
    """Máscara dos pixels que `keep(x, y, r, g, b)` aceita, crescida para levar o contorno junto."""
    mask = Image.new("L", image.size, 0)
    px = image.load()
    mp = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = px[x, y]
            if a > 40 and keep(x, y, r, g, b):
                mp[x, y] = 255
    return mask.filter(ImageFilter.MaxFilter(grow)) if grow > 1 else mask


def cut_with(image: Image.Image, mask: Image.Image) -> Image.Image:
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    alpha = Image.composite(image.split()[3], mask, mask)
    out.paste(image, (0, 0), mask)
    out.putalpha(Image.eval(alpha, lambda v: v))
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, width in WIDTHS.items():
        image = trim(Image.open(SRC / f"{name}.png").convert("RGBA"))
        resize_to_width(image, width).save(OUT / f"{name}.png")

    head = Image.open(OLD_HEAD).convert("RGBA")
    # Chapéu: escuro ou dourado acima da linha de baixo da aba (de (50, 89) subindo até (145, 57)); o
    # dourado só à direita da flor. Sem crescer a máscara: o contorno do chapéu já é escuro.
    hat_mask = mask_from(head, lambda x, y, r, g, b: x > 38 and y < 89 - (x - 50) * 0.33
                         and (max(r, g, b) < 110 or (x > 62 and r > 180 and 110 < g < 200 and b < 90)), 1)
    # Flor: branco ou miolo amarelo no canto de cima à esquerda.
    flower_mask = mask_from(head, lambda x, y, r, g, b: x < 70 and y < 80
                            and ((r > 225 and g > 225 and b > 200) or (r > 220 and g > 170 and b < 80)))
    hat = _close_hat(cut_with(head, _fill_holes(hat_mask)))
    for name, part in (("hat", hat), ("flower", cut_with(head, flower_mask))):
        part = trim(part)
        size = (round(part.width * OLD_HEAD_SCALE), round(part.height * OLD_HEAD_SCALE))
        part.resize(size, Image.LANCZOS).save(OUT / f"{name}.png")
    print("peças em", OUT)


def _fill_holes(mask: Image.Image) -> Image.Image:
    """Tapa os buracos da máscara (reflexos claros, o lugar da flor): fora é só o que se alcança pela borda."""
    outside = mask.copy()
    ImageDraw.floodfill(outside, (0, 0), 128)
    return outside.point(lambda v: 0 if v == 128 else 255)


def _close_hat(hat: Image.Image) -> Image.Image:
    """Pinta de chapéu o que era flor (a flor balança e mostraria o desenho dela por baixo) e fecha com
    contorno a linha cortada embaixo da aba."""
    ink = (26, 18, 16, 255)
    px = hat.load()
    for y in range(hat.height):
        for x in range(hat.width):
            r, g, b, a = px[x, y]
            if a and x < 72 and (r > 150 or g > 150):
                px[x, y] = ink
    for x in range(hat.width):
        for y in range(hat.height - 1, -1, -1):
            if px[x, y][3] > 128:
                for dy in range(3):
                    if y - dy >= 0 and px[x, y - dy][3]:
                        px[x, y - dy] = ink
                break
    return hat


if __name__ == "__main__":
    main()
