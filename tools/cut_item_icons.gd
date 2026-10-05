extends SceneTree
## Recorta os ícones dos itens da loja (Pedido C, docs/prompts/chatgpt_armas_trem_itens.md):
## docs/referencias/pecas/itens/icones.png tem 6 x 3 células de 256, na ordem de
## dialogues/items.json (a última célula fica vazia). Cada ícone vira core/shop/icons/<id>.png.
## Cada ícone é recortado justo no desenho, num quadrado.
## Uso: Godot --headless --script res://tools/cut_item_icons.gd

const SHEET := "res://docs/referencias/pecas/itens/icones.png"
const ITEMS := "res://dialogues/items.json"
const OUT := "res://core/shop/icons/"
const COLUMNS := 6
const CELL := 256
## Tamanho salvo (a maior exibição é o cartão de detalhes da loja, 120 px).
const SIZE := 128
## Pixels com menos opacidade que isto são apagados (sujeirinhas da IA).
const MIN_ALPHA := 0.15


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	sheet.convert(Image.FORMAT_RGBA8)
	var items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ITEMS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var index := 0
	for item_id: String in items:
		var cell := sheet.get_region(Rect2i(Vector2i(index % COLUMNS, index / COLUMNS) * CELL, Vector2i(CELL, CELL)))
		for y in CELL:
			for x in CELL:
				var c := cell.get_pixel(x, y)
				if c.a > 0.0 and c.a < MIN_ALPHA:
					cell.set_pixel(x, y, Color(c, 0.0))
		# Recorta justo no desenho, num quadrado (o ícone ocupa o espaço todo do botão).
		var used := cell.get_used_rect()
		var side := maxi(used.size.x, used.size.y) + 8
		var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
		square.blit_rect(cell, used, (Vector2i(side, side) - used.size) / 2)
		square.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		square.save_png(OUT + item_id + ".png")
		print(OUT + item_id + ".png")
		index += 1
	quit()
