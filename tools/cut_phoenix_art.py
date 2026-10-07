"""Recorta a arte da Fênix das Cinzas (pedido do Vulcão, docs/prompts/chatgpt_chefoes_vulcao.md) para o jogo.
Como as folhas são lidas está em tools/sheet_cut.py.

Uso (da raiz do projeto): python -I tools/cut_phoenix_art.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet_cut import SheetCutter  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CUT = SheetCutter(os.path.join(ROOT, "docs", "referencias", "pecas", "vulcao"),
        os.path.join(ROOT, "bosses", "phoenix", "art"), "res://bosses/phoenix/art")

# Animações: folha, colunas, linhas, quadros, escala no jogo (px do jogo por px da folha), âncora, nome.
# As escalas igualam o tamanho da ave entre folhas (~330 px de altura no jogo; o ovo também).
ANIMATIONS = [
    ("fenix/fenix_voo.png", 4, 2, 8, 0.7, "center", "fly"),
    ("fenix/fenix_asas.png", 4, 1, 4, 0.55, "center", "wings"),
    ("fenix/fenix_ninho.png", 4, 2, 8, 0.85, "feet", "perch"),
    ("fenix/fenix_ovo.png", 4, 2, 8, 0.92, "feet", "egg"),
    ("fenix/fenix_derrota.png", 4, 1, 4, 0.66, "feet", "defeat"),
    ("fenix/anel_fogo.png", 4, 1, 4, 0.56, "feet", "ring"),
    ("fenix/ventania.png", 4, 1, 4, 0.8, "center", "wind"),
]

# fenix_efeitos.png: 4 linhas de alturas diferentes (começam em y 0, 285, 540 e 760), da esquerda para a
# direita. A escala de cada um fica em PhoenixProp.
EFFECT_ROWS = [0, 285, 540, 760]
EFFECTS = [
    ["fx_feather_1", "fx_feather_2", "fx_feather_3", "fx_feather_4",
            "fx_feather_parry_1", "fx_feather_parry_2", "fx_feather_parry_3", "fx_feather_parry_4"],
    ["fx_egg_1", "fx_egg_2", "fx_egg_crack_1", "fx_egg_crack_2",
            "fx_egg_parry_1", "fx_egg_parry_2", "fx_egg_splash_1", "fx_egg_splash_2"],
    ["fx_chick_1", "fx_chick_2", "fx_chick_3", "fx_chick_4", "fx_chick_poof_1", "fx_chick_poof_2",
            "fx_spark_1", "fx_spark_2"],
    ["fx_trail_1", "fx_trail_2", "fx_trail_3", "fx_trail_4"],
]


def main():
    CUT.clean()
    for entry in ANIMATIONS:
        CUT.animation(*entry)
    # O rastro (última linha) é feito de pontinhos: junta de mais longe.
    CUT.row_effects("fenix/fenix_efeitos.png", EFFECT_ROWS, EFFECTS, reach=[3, 3, 3, 14])
    # Só a rocha (os caquinhos soltos em volta ficavam boiando ao lado).
    CUT.grid_effects("arenas/rocha_flutuante.png", 3, 1, ["rock_1", "rock_2", "rock_3"], ratio=0.3)
    CUT.single("arenas/arena_fenix.png", "arena.png", False)
    CUT.single("arenas/arena_fenix_fase2.png", "arena_storm.png", False)
    CUT.single("arenas/arena_fenix_fase3.png", "arena_reborn.png", False)


if __name__ == "__main__":
    main()
