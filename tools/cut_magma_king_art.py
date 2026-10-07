"""Recorta a arte do Rei Magma (pedido do Vulcão, docs/prompts/chatgpt_chefoes_vulcao.md) para o jogo.
Como as folhas são lidas está em tools/sheet_cut.py.

Uso (da raiz do projeto): python -I tools/cut_magma_king_art.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet_cut import SheetCutter  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CUT = SheetCutter(os.path.join(ROOT, "docs", "referencias", "pecas", "vulcao"),
        os.path.join(ROOT, "bosses", "magma_king", "art"), "res://bosses/magma_king/art")

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
    # Rajada refeita (docs/prompts/chatgpt_rei_magma_jato.md): uma pose para cada altura do jato.
    # (os desenhos encostam uns nos outros: só o pedaço grande de cada célula fica)
    ("rei_magma/rei_jato_alto.png", 4, 1, 4, 0.72, "feet", "jet_high", 0, 0.2),
    ("rei_magma/rei_jato_medio.png", 4, 1, 4, 0.72, "feet", "jet_mid", 0, 0.2),
    ("rei_magma/rei_jato_baixo.png", 4, 1, 4, 0.72, "feet", "jet_low", 0, 0.2),
]

# Efeitos soltos de rei_efeitos.png, na ordem em que aparecem (a escala de cada um fica em MagmaProp).
EFFECTS = ["fx_ball_1", "fx_ball_2", "fx_ball_3", "fx_ball_4", "fx_puddle_1", "fx_puddle_2", "fx_puddle_3",
        "fx_puddle_4", "fx_crown_1", "fx_crown_2", "fx_crown_3", "fx_crown_4", "fx_gem_1", "fx_gem_2", "fx_drop_1",
        "fx_drop_2", "fx_drop_parry", "fx_splash_1", "fx_splash_2", "fx_splash_3"]


def jet_pieces():
    """jato_pecas.png: 3 linhas (boca, meio, ponta) de 3 quadros. Cada peça sai com a linha do meio do jato no
    meio da altura da imagem. O meio vira uma faixa só, sem emenda (as pontas misturadas), que se repete."""
    import numpy as np
    from PIL import Image
    from sheet_cut import split_points, keep_main, ALPHA
    image = CUT.load("rei_magma/jato_pecas.png")
    alpha = image[:, :, 3] > ALPHA
    ys = split_points(alpha, image.shape[0], 3, 1)

    def centered(piece, band):
        a = piece[:, band, 3] > ALPHA
        rows = np.nonzero(a.any(axis=1))[0]
        middle = int((rows.min() + rows.max()) / 2)
        half = max(middle, piece.shape[0] - middle)
        out = np.zeros((half * 2, piece.shape[1], 4), np.uint8)
        out[half - middle:half - middle + piece.shape[0]] = piece
        return out

    def trim(piece):
        yy, xx = np.nonzero(piece[:, :, 3] > 8)
        return piece[yy.min():yy.max() + 1, xx.min():xx.max() + 1]

    for row, name, band in [(0, "jet_mouth", slice(0, 80)), (2, "jet_tip", slice(-80, None))]:
        strip = image[ys[row]:ys[row + 1]]
        xs = split_points(strip[:, :, 3] > ALPHA, strip.shape[1], 3, 0)
        for k in range(3):
            piece = trim(keep_main(strip[:, xs[k]:xs[k + 1]]))
            Image.fromarray(centered(piece, band)).save(os.path.join(CUT.out, "%s_%d.png" % (name, k + 1)))
    strip = trim(image[ys[1]:ys[2]])
    blend = 160
    w = strip.shape[1]
    tile = strip[:, :w - blend].astype(np.float32)
    ramp = np.linspace(0.0, 1.0, blend)[None, :, None]
    tile[:, :blend] = strip[:, w - blend:] * (1.0 - ramp) + strip[:, :blend] * ramp
    Image.fromarray(centered(tile.astype(np.uint8), slice(None))).save(os.path.join(CUT.out, "jet_middle.png"))
    print("jato em peças  boca 3, ponta 3, meio %d px" % (w - blend))


def main():
    CUT.clean()
    for entry in ANIMATIONS:
        CUT.animation(*entry)
    CUT.loose_effects("rei_magma/rei_efeitos.png", EFFECTS)
    jet_pieces()
    CUT.single("rei_magma/rei_trono.png", "throne.png")
    CUT.single("arenas/jangada_basalto.png", "raft.png")
    CUT.single("arenas/arena_rei.png", "arena.png", False)
    CUT.single("arenas/arena_rei_fase3.png", "arena_phase3.png", False)


if __name__ == "__main__":
    main()
