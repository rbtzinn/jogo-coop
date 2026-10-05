extends SceneTree
## Recorta as folhas dos efeitos do Domador (Pedido D, docs/prompts/chatgpt_efeitos_domador.md) para
## bosses/tamer/art/effects/.
## Uso: Godot --headless --script res://tools/cut_tamer_effects.gd
##
## - Argolas: cada célula (512 x 640) pela metade, 256 x 320 (o miolo livre fica com 140 x 224, o tamanho
##   da argola no jogo). A rosa só veio num desenho; o segundo quadro é ela espelhada.
## - Brasas: cada célula (128) pela metade, 64 x 64, com a brasa no meio.
## - Onda da Chicotada: cada célula (256) inteira; o jogo desenha pela metade (base em y 236, meio em x 128).
## - Ondas de som: o trecho do meio (linha 1, emenda em cima e embaixo) e as pontas. A IA desenhou as
##   pontas como uma peça inteira (y 346 a 677 na folha), então a ponta de cima é o começo dela e a de
##   baixo é o fim (64 px cada). Ficam no tamanho da folha; o jogo desenha pela metade.

const SOURCES := "res://docs/referencias/pecas/domador/efeitos/"
const OUT := "res://bosses/tamer/art/effects/"
const MIN_ALPHA := 0.15
const CAP_HEIGHT := 64
const CAPSULE_TOP := 346
const CAPSULE_BOTTOM := 678


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var rings := _load("argolas.png")
	var ring_names := ["ring_unlit", "ring_fire_a", "ring_fire_b", "ring_pink_a"]
	for i in 4:
		var cell := rings.get_region(Rect2i(i * 512, 0, 512, 640))
		cell.resize(256, 320, Image.INTERPOLATE_LANCZOS)
		_save(cell, ring_names[i])
		if i == 3:
			cell.flip_x()
			_save(cell, "ring_pink_b")
	var embers := _load("brasas.png")
	var ember_names := ["ember_a", "ember_b", "ember_pink_a", "ember_pink_b"]
	for i in 4:
		var cell := embers.get_region(Rect2i(i * 128, 0, 128, 128))
		cell.resize(64, 64, Image.INTERPOLATE_LANCZOS)
		_save(cell, ember_names[i])
	var whip := _load("onda_chicote.png")
	for row in 2:
		for i in 4:
			_save(whip.get_region(Rect2i(i * 256, row * 256, 256, 256)), "whip%s_%d" % ["_pink" if row == 1 else "", i + 1])
	var sound := _load("ondas_som.png")
	for i in 3:
		_save(sound.get_region(Rect2i(i * 256, 0, 256, 256)), "sound_middle_%d" % (i + 1))
		_save(sound.get_region(Rect2i(i * 256, CAPSULE_TOP, 256, CAP_HEIGHT)), "sound_top_%d" % (i + 1))
		_save(sound.get_region(Rect2i(i * 256, CAPSULE_BOTTOM - CAP_HEIGHT, 256, CAP_HEIGHT)), "sound_bottom_%d" % (i + 1))
	quit()


func _load(sheet: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + sheet))
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.0 and c.a < MIN_ALPHA:
				image.set_pixel(x, y, Color(c, 0.0))
	return image


func _save(image: Image, name: String) -> void:
	image.save_png(OUT + name + ".png")
	print(OUT + name + ".png ", image.get_size())
