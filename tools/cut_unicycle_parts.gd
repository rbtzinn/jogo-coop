extends SceneTree
## Recorta o monociclo em peças (Pedido 2 de docs/prompts/chatgpt_monociclo.md) para o Unicycle dos
## Malabaristas: a roda (gira pelo código) e a armação (garfo, haste, pedais e selim).
## Uso: Godot --headless --script res://tools/cut_unicycle_parts.gd
##
## Medidas na folha (2048 x 1024): a roda é um círculo de 898 px com o eixo em (511, 511); na
## armação, o eixo fica em (1533, 944) e o fundo do selim, onde os irmãos sentam, em (1533, 110).
## No jogo a roda tem raio 110 e o selim fica 220 px acima do eixo (Unicycle.WHEEL_RADIUS e
## SEAT_HEIGHT), então cada peça tem a própria escala.

const SHEET := "res://docs/referencias/pecas/malabaristas/monociclo_pecas_candidata.png"
const OUT := "res://bosses/jugglers/art/unicycle/"
## Pixels de textura por pixel de jogo.
const TEXTURE_SCALE := 2.0
const MIN_ALPHA := 0.15

const WHEEL_RECT := Rect2i(56, 56, 912, 912)
const WHEEL_HUB := Vector2(511, 511)
const WHEEL_DIAMETER := 898.0
const FRAME_RECT := Rect2i(1300, 70, 490, 930)
const FRAME_AXLE := Vector2(1533, 944)
const FRAME_SEAT := Vector2(1533, 110)


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	sheet.convert(Image.FORMAT_RGBA8)
	_save(sheet, WHEEL_RECT, 220.0 / WHEEL_DIAMETER, WHEEL_HUB, "wheel")
	_save(sheet, FRAME_RECT, 220.0 / FRAME_AXLE.distance_to(FRAME_SEAT), FRAME_AXLE, "frame")
	quit()


## Salva a peça e imprime o deslocamento do centro da textura em relação ao eixo (pixels de jogo).
func _save(sheet: Image, rect: Rect2i, scale: float, axle: Vector2, name: String) -> void:
	var piece := sheet.get_region(rect)
	for y in piece.get_height():
		for x in piece.get_width():
			var c := piece.get_pixel(x, y)
			if c.a > 0.0 and c.a < MIN_ALPHA:
				piece.set_pixel(x, y, Color(c, 0.0))
	piece.resize(roundi(rect.size.x * scale * TEXTURE_SCALE), roundi(rect.size.y * scale * TEXTURE_SCALE),
			Image.INTERPOLATE_LANCZOS)
	piece.save_png(OUT + name + ".png")
	var center := (Vector2(rect.get_center()) - axle) * scale
	print(OUT, name, ".png escala ", scale, " centro em relação ao eixo ", center)
