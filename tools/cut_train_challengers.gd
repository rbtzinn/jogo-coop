extends "res://tools/cut_train_art.gd"
## Recorta as folhas dos desafiantes dos vagões do Trem (docs/prompts/chatgpt_trem_desafiantes.md), do mesmo
## jeito das folhas do Pedido B (cada quadro justo no desenho, com a própria âncora). As folhas vieram com
## franjas coloridas (vermelho e amarelo) na beira semitransparente do desenho: elas viram cinza.
## Uso: Godot --headless --script res://tools/cut_train_challengers.gd

const CHALLENGERS := "desafiantes/"
## Beira mais transparente que isto perde a cor (fica cinza com o mesmo brilho).
const FRINGE_ALPHA := 0.7

## [folha, colunas, linhas, células, escala (jogo por pixel da folha), âncora, saída]
const SHEETS := [
	["saltimbanco.png", 4, 2, [0, 1, 2, 3, 4, 5, 6, 7], 0.75, "feet", ENEMY_ART + "spring_acrobat"],
	["onda_impacto.png", 4, 1, [0, 1, 2, 3], 0.5, "feet", ENEMY_ART + "shockwave"],
]


func _initialize() -> void:
	for s in SHEETS:
		if FileAccess.file_exists(ProjectSettings.globalize_path(SOURCES + CHALLENGERS + s[0])):
			_cut(CHALLENGERS + s[0], s[1], s[3], s[4], s[5], s[6], s[2])
	quit()


func _clean(sheet: Image) -> void:
	super(sheet)
	for y in sheet.get_height():
		for x in sheet.get_width():
			var c := sheet.get_pixel(x, y)
			if c.a > 0.0 and c.a < FRINGE_ALPHA:
				var gray := c.get_luminance()
				sheet.set_pixel(x, y, Color(gray, gray, gray, c.a))
