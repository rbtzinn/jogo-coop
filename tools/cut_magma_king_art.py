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
    ("rei_magma/jato_magma.png", 2, 1, 2, 0.5, "center", "jet"),
]

# Efeitos soltos de rei_efeitos.png, na ordem em que aparecem (a escala de cada um fica em MagmaProp).
EFFECTS = ["fx_ball_1", "fx_ball_2", "fx_ball_3", "fx_ball_4", "fx_puddle_1", "fx_puddle_2", "fx_puddle_3",
        "fx_puddle_4", "fx_crown_1", "fx_crown_2", "fx_crown_3", "fx_crown_4", "fx_gem_1", "fx_gem_2", "fx_drop_1",
        "fx_drop_2", "fx_drop_parry", "fx_splash_1", "fx_splash_2", "fx_splash_3"]


def main():
    CUT.clean()
    for entry in ANIMATIONS:
        CUT.animation(*entry)
    CUT.loose_effects("rei_magma/rei_efeitos.png", EFFECTS)
    CUT.single("rei_magma/rei_trono.png", "throne.png")
    CUT.single("arenas/jangada_basalto.png", "raft.png")
    CUT.single("arenas/arena_rei.png", "arena.png", False)
    CUT.single("arenas/arena_rei_fase3.png", "arena_phase3.png", False)


if __name__ == "__main__":
    main()
