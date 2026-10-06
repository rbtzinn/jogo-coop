extends "res://tools/cut_train_art.gd"
## Recorta as folhas dos desafiantes dos vagões do Trem (docs/prompts/chatgpt_trem_desafiantes.md), do mesmo
## jeito das folhas do Pedido B (cada quadro justo no desenho, com a própria âncora). As folhas vieram com
## franjas coloridas (vermelho e amarelo) na beira semitransparente do desenho: elas viram cinza.
## Uso: Godot --headless --script res://tools/cut_train_challengers.gd

const CHALLENGERS := "desafiantes/"
## Beira mais transparente que isto perde a cor (fica cinza com o mesmo brilho).
const FRINGE_ALPHA := 0.7
## Tábua do trapézio dos jogadores: só a parte de baixo da imagem (nós das cordas e a tábua), na largura da
## tábua do jogo; as cordas são desenhadas pelo jogo, indo até o ponto do balanço.
const SEAT_SHEET := "trapezio_tabua.png"
const SEAT_FROM_Y := 0.8
const SEAT_WIDTH := 320.0

## [folha, colunas, linhas, células, escala (jogo por pixel da folha), âncora, saída]
const SHEETS := [
	["saltimbanco.png", 4, 2, [0, 1, 2, 3, 4, 5, 6, 7], 0.75, "feet", ENEMY_ART + "spring_acrobat"],
	["onda_impacto.png", 4, 1, [0, 1, 2, 3], 0.5, "feet", ENEMY_ART + "shockwave"],
	["trapezista.png", 4, 2, [0, 1, 2, 3, 4, 5, 6, 7], 0.5, "bar", ENEMY_ART + "trapeze_ghost"],
	["leaozinho.png", 4, 2, [0, 1, 2, 3, 4, 5, 6, 7], 0.45, "base", ENEMY_ART + "plush_lion"],
	["novelo.png", 4, 1, [0, 1, 2, 3], 0.2, "center", ENEMY_ART + "yarn"],
	["baloeiro.png", 4, 2, [0, 1, 2, 3, 4, 5, 6, 7], 0.6, "center", ENEMY_ART + "balloon_ghost"],
	["bexiga_agua.png", 4, 1, [0, 1, 2, 3], 0.22, "center", ENEMY_ART + "water_balloon"],
	["balao_plataforma.png", 4, 1, [0, 1, 2, 3], 0.65, "feet", STAGE_ART + "balloon_platform"],
	["lanterninha.png", 4, 2, [0, 1, 2, 3, 4, 5, 6, 7], 0.52, "feet", ENEMY_ART + "lantern_ghost"],
]


func _initialize() -> void:
	for s in SHEETS:
		if FileAccess.file_exists(ProjectSettings.globalize_path(SOURCES + CHALLENGERS + s[0])):
			_cut(CHALLENGERS + s[0], s[1], s[3], s[4], s[5], s[6], s[2])
	_cut_seat()
	quit()


func _clean(sheet: Image) -> void:
	super(sheet)
	for y in sheet.get_height():
		for x in sheet.get_width():
			var c := sheet.get_pixel(x, y)
			if c.a > 0.0 and c.a < FRINGE_ALPHA:
				var gray := c.get_luminance()
				sheet.set_pixel(x, y, Color(gray, gray, gray, c.a))


func _cut_seat() -> void:
	var path := ProjectSettings.globalize_path(SOURCES + CHALLENGERS + SEAT_SHEET)
	if not FileAccess.file_exists(path):
		return
	var image := Image.load_from_file(path)
	image.convert(Image.FORMAT_RGBA8)
	var top := roundi(image.get_height() * SEAT_FROM_Y)
	var bottom := image.get_region(Rect2i(0, top, image.get_width(), image.get_height() - top))
	var used := bottom.get_used_rect()
	var seat := bottom.get_region(used)
	var scale := SEAT_WIDTH * TEXTURE_SCALE / used.size.x
	seat.resize(roundi(used.size.x * scale), roundi(used.size.y * scale), Image.INTERPOLATE_LANCZOS)
	seat.save_png(STAGE_ART + "trapeze_seat.png")
	print(STAGE_ART + "trapeze_seat.png ", seat.get_size())
