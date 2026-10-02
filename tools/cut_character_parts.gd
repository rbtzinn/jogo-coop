extends SceneTree
## Recorta as peças dos personagens das folhas ilustradas (docs/referencias/pecas/)
## e salva PNGs prontos para os rigs, sem distorcer: cada peça usa uma escala uniforme.
## As texturas saem em 2x (o Sprite2D usa escala 0.5) para ficarem nítidas em telas grandes.
## Uso: Godot --headless --script res://tools/cut_character_parts.gd

const SOURCES := "res://docs/referencias/pecas/"
const OUT := "res://core/player/characters/"
## Pixels de textura por pixel de jogo.
const TEXTURE_SCALE := 2.0

## [folha, região aproximada na folha, arquivo de saída, altura final em pixels de jogo
## ou o arquivo de outra peça cuja escala deve ser repetida (o piscar usa a escala da cabeça)]
const PARTS := [
	["palhaco_folha.png", Rect2i(70, 40, 455, 443), "clown/clown_head.png", 104.0],
	["palhaco_folha.png", Rect2i(70, 500, 455, 435), "clown/clown_blink.png", "clown/clown_head.png"],
	["palhaco_folha.png", Rect2i(610, 75, 430, 430), "clown/clown_torso.png", 90.0],
	["palhaco_folha.png", Rect2i(1125, 225, 520, 263), "clown/clown_shoe.png", 38.0],
	["acrobata_folha.png", Rect2i(40, 15, 515, 465), "acrobat/acrobat_head.png", 98.0],
	["acrobata_folha.png", Rect2i(40, 490, 515, 451), "acrobat/acrobat_blink.png", "acrobat/acrobat_head.png"],
	["acrobata_tronco.png", Rect2i(), "acrobat/acrobat_torso.png", 92.0],
	["acrobata_folha.png", Rect2i(1200, 235, 445, 295), "acrobat/acrobat_shoe.png", 34.0],
	["palhaco_folha.png", Rect2i(615, 610, 340, 290), "shared/glove_fist.png", 32.0],
	["luva_pistola.png", Rect2i(), "shared/glove_gun.png", 42.0],
]


func _initialize() -> void:
	var factors := {}
	for part in PARTS:
		var path: String = ProjectSettings.globalize_path(SOURCES + part[0])
		var source := Image.load_from_file(path)
		source.convert(Image.FORMAT_RGBA8)
		var region: Rect2i = part[1]
		if region.size == Vector2i.ZERO:
			region = Rect2i(Vector2i.ZERO, source.get_size())
		var piece := source.get_region(region)
		var used := _visible_rect(piece)
		piece = piece.get_region(used)
		var factor: float = factors[part[3]] if part[3] is String else part[3] * TEXTURE_SCALE / used.size.y
		factors[part[2]] = factor
		var size := Vector2i((Vector2(used.size) * factor).round())
		piece.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		var destination: String = OUT + part[2]
		piece.save_png(destination)
		print(destination, " ", size, " (fonte ", Rect2i(region.position + used.position, used.size), ")")
	quit()


func _visible_rect(img: Image) -> Rect2i:
	var first := img.get_size()
	var last := Vector2i.ZERO
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a >= 0.08:
				first = Vector2i(mini(first.x, x), mini(first.y, y))
				last = Vector2i(maxi(last.x, x + 1), maxi(last.y, y + 1))
	return Rect2i(first, last - first).grow(2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
