extends SceneTree
## Recorta as folhas da fase do Trem (Pedido B, docs/prompts/chatgpt_armas_trem_itens.md).
## Uso: Godot --headless --script res://tools/cut_train_art.gd
##
## - Peças inteiras (vagões, locomotiva, fundos, ponte, placa) são copiadas como estão: o jogo
##   ajusta a escala na hora de desenhar.
## - Animações (inimigos, fumaça, ingresso): cada quadro é recortado justo no desenho. A IA
##   encaixou cada quadro na célula com uma escala própria, então cada quadro tem a própria
##   âncora: o pé (meio de baixo) para quem fica no chão e o meio para quem voa.
##   Os tracinhos soltos entre as células (sujeira da IA, até 12 px de largura) são apagados.

const SOURCES := "res://docs/referencias/pecas/trem/"
const LEVEL_ART := "res://levels/train/art/"
const ENEMY_ART := "res://components/enemies/art/"
const STAGE_ART := "res://components/stage/art/"
## Pixels de textura por pixel de jogo.
const TEXTURE_SCALE := 2.0
const MIN_ALPHA := 0.15
## Pedaços soltos mais finos que isto (em pixels da folha) são apagados.
const SPECK_WIDTH := 12

const COPIES := [
	["vagao_1.png", LEVEL_ART + "wagon_1.png"],
	["vagao_2.png", LEVEL_ART + "wagon_2.png"],
	["vagao_3.png", LEVEL_ART + "wagon_3.png"],
	["vagao_4.png", LEVEL_ART + "wagon_4.png"],
	["locomotiva.png", LEVEL_ART + "locomotive.png"],
	["fundo_morros.png", LEVEL_ART + "back_hills.png"],
	["fundo_postes.png", LEVEL_ART + "back_poles.png"],
	["ponte.png", LEVEL_ART + "bridge.png"],
	["placa_abaixe.png", LEVEL_ART + "duck_sign.png"],
]

## [folha, colunas, células, escala (jogo por pixel da folha), âncora ("feet" ou "center"), saída]
const ANIMATIONS := [
	["fantasma.png", 4, [0, 1, 2, 3], 0.25, "feet", ENEMY_ART + "ghost_hop"],
	["fantasma_derrota.png", 4, [0, 1, 2, 3], 0.25, "feet", ENEMY_ART + "ghost_defeat"],
	["pombo.png", 4, [0, 1, 2, 3], 0.22, "center", ENEMY_ART + "pigeon"],
	["pombo_rosa.png", 4, [0, 1, 2, 3], 0.22, "center", ENEMY_ART + "pigeon_pink"],
	["canhao.png", 4, [0, 1, 2, 3], 0.25, "feet", ENEMY_ART + "cannon"],
	["bola_canhao.png", 4, [0, 3], 0.26, "center", ENEMY_ART + "ball"],
	["rodas.png", 4, [0], 0.62, "center", LEVEL_ART + "wheel"],
	["fumaca.png", 4, [0, 1, 2, 3], 0.8, "center", LEVEL_ART + "smoke"],
	["ingresso_escondido.png", 4, [0, 1, 2, 3], 0.42, "center", STAGE_ART + "ticket"],
]


func _initialize() -> void:
	for dir in [LEVEL_ART, ENEMY_ART, STAGE_ART]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for copy in COPIES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + copy[0]))
		image.save_png(copy[1])
		print(copy[1], " ", image.get_size())
	for a in ANIMATIONS:
		_cut(a[0], a[1], a[2], a[3], a[4], a[5])
	quit()


func _cut(sheet_name: String, columns: int, cells: Array, scale: float, anchor: String, out: String) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + sheet_name))
	sheet.convert(Image.FORMAT_RGBA8)
	_erase_specks(sheet)
	var cell_size := Vector2i(sheet.get_width() / columns, sheet.get_height())
	var paths: Array[String] = []
	var origins: Array[Vector2] = []
	for i in cells.size():
		var cell := sheet.get_region(Rect2i(Vector2i(cells[i] * cell_size.x, 0), cell_size))
		var used := cell.get_used_rect().grow(2).intersection(Rect2i(Vector2i.ZERO, cell_size))
		var point := Vector2(used.get_center().x, used.end.y) if anchor == "feet" else Vector2(used.get_center())
		var frame := cell.get_region(used)
		frame.resize(maxi(roundi(used.size.x * scale * TEXTURE_SCALE), 1),
				maxi(roundi(used.size.y * scale * TEXTURE_SCALE), 1), Image.INTERPOLATE_LANCZOS)
		var path := out + "_%d.png" % (i + 1)
		frame.save_png(path)
		paths.append(path)
		origins.append((Vector2(used.position) - point) * scale)
	_write_resource(out + ".tres", paths, 1.0 / TEXTURE_SCALE, origins)


## Apaga pixels quase transparentes e os pedaços soltos finos (em blocos de 4 px, como uma
## busca de regiões ligadas).
func _erase_specks(img: Image) -> void:
	var block := 4
	var grid := Vector2i(img.get_width() / block, img.get_height() / block)
	var filled := PackedByteArray()
	filled.resize(grid.x * grid.y)
	for gy in grid.y:
		for gx in grid.x:
			var any := false
			for d in [Vector2i(1, 1), Vector2i(3, 3), Vector2i(1, 3), Vector2i(3, 1)]:
				if img.get_pixel(gx * block + d.x, gy * block + d.y).a > 0.4:
					any = true
			filled[gy * grid.x + gx] = 1 if any else 0
	var seen := PackedByteArray()
	seen.resize(filled.size())
	for start in filled.size():
		if filled[start] == 0 or seen[start] == 1:
			continue
		var stack: Array[int] = [start]
		seen[start] = 1
		var members: Array[int] = []
		var min_x := grid.x
		var max_x := 0
		while not stack.is_empty():
			var k: int = stack.pop_back()
			members.append(k)
			var x := k % grid.x
			var y := k / grid.x
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or ny < 0 or nx >= grid.x or ny >= grid.y:
						continue
					var n := ny * grid.x + nx
					if filled[n] == 1 and seen[n] == 0:
						seen[n] = 1
						stack.append(n)
		if (max_x - min_x + 1) * block <= SPECK_WIDTH:
			for k in members:
				var at := Vector2i(k % grid.x, k / grid.x) * block
				img.fill_rect(Rect2i(at - Vector2i(2, 2), Vector2i(block + 4, block + 4)), Color(0, 0, 0, 0))
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c.a < MIN_ALPHA:
				img.set_pixel(x, y, Color(c, 0.0))


## Escreve o .tres à mão (os PNGs ainda não foram importados, então não dá para load()).
## `origins`: canto de cima à esquerda de cada quadro em relação à âncora (pixels de jogo).
func _write_resource(path: String, frames: Array[String], scale: float, origins: Array[Vector2]) -> void:
	var text := "[gd_resource type=\"Resource\" script_class=\"FrameAnimation\" load_steps=%d format=3]\n\n" % (frames.size() + 2)
	text += "[ext_resource type=\"Script\" path=\"res://core/player/characters/frame_animation.gd\" id=\"1_script\"]\n"
	for i in frames.size():
		text += "[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%d_frame\"]\n" % [frames[i], i + 2]
	text += "\n[resource]\nscript = ExtResource(\"1_script\")\n"
	var refs := PackedStringArray()
	for i in frames.size():
		refs.append("ExtResource(\"%d_frame\")" % (i + 2))
	text += "frames = Array[Texture2D]([%s])\n" % ", ".join(refs)
	text += "frame_scale = %s\n" % scale
	text += "origin = Vector2(%.1f, %.1f)\n" % [origins[0].x, origins[0].y]
	var moved := PackedStringArray()
	for o in origins:
		moved.append("%.1f, %.1f" % [o.x - origins[0].x, o.y - origins[0].y])
	text += "offsets = PackedVector2Array(%s)\n" % ", ".join(moved)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	print(path, " origem ", origins[0])
