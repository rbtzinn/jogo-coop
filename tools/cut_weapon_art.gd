extends SceneTree
## Recorta as folhas das pistolas e dos tiros (Pedido A, docs/prompts/chatgpt_armas_trem_itens.md)
## e gera os PNGs + um FrameAnimation (.tres) por animação.
## Uso: Godot --headless --script res://tools/cut_weapon_art.gd
##
## Cada animação usa o MESMO retângulo em todos os quadros (a união do que está desenhado),
## com uma escala só. O ponto "anchor" da célula vira o (0, 0) do nó que mostra o desenho
## (o meio do tiro, ou o começo do clarão na boca da pistola).
## As texturas saem em 2x (frame_scale 0,5) para ficarem nítidas.

const SOURCES := "res://docs/referencias/pecas/armas/"
const SHOTS := "res://components/projectile/art/"
const GUNS := "res://core/player/characters/shared/guns/"
const TEXTURE_SCALE := 2.0
## Pixels com menos opacidade que isto não contam para o retângulo (sujeirinhas da IA).
const MIN_ALPHA := 0.15

## Uma entrada por animação. "cells": índices na grade (esquerda para a direita, de cima para
## baixo). Tamanho no jogo: "width" (largura da união dos quadros, em pixels de jogo) ou
## "scale" (pixels de jogo por pixel da célula).
const ANIMATIONS := [
	# Tiros: células de 256, desenho no meio da célula, voando para a direita.
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [0, 1, 2, 3], "anchor": Vector2(128, 128),
		"width": 72.0, "out": SHOTS + "cork_fly"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [4, 5, 6, 7], "anchor": Vector2(128, 128),
		"width": 84.0, "out": SHOTS + "cork_hit"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [8, 9, 10, 11], "anchor": Vector2(128, 128),
		"scale": 0.7, "out": SHOTS + "confetti_fly"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [12, 13, 14, 15], "anchor": Vector2(128, 128),
		"width": 70.0, "out": SHOTS + "confetti_hit"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [16, 17, 18, 19], "anchor": Vector2(128, 128),
		"width": 54.0, "out": SHOTS + "club_fly"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [20, 21, 22, 23], "anchor": Vector2(128, 128),
		"width": 74.0, "out": SHOTS + "club_hit"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [24, 25, 26, 27], "anchor": Vector2(128, 128),
		"width": 32.0, "out": SHOTS + "bubble_fly"},
	{"sheet": "tiros.png", "columns": 8, "rows": 4, "cells": [28, 29, 30, 31], "anchor": Vector2(128, 128),
		"width": 70.0, "out": SHOTS + "bubble_hit"},
	# Tiros EX: células de 512.
	{"sheet": "tiros_ex.png", "columns": 4, "rows": 2, "cells": [0, 1], "anchor": Vector2(330, 256),
		"width": 170.0, "out": SHOTS + "big_cork_fly"},
	# Canhão de Confete: o último quadro tem ~460 px na célula = o diâmetro da explosão (raio 230).
	{"sheet": "tiros_ex.png", "columns": 4, "rows": 2, "cells": [2, 3, 4, 5], "anchor": Vector2(256, 256),
		"scale": 1.0, "out": SHOTS + "confetti_blast"},
	# Bolhona: a bolha do jogo tem raio 46 (92 px).
	{"sheet": "tiros_ex.png", "columns": 4, "rows": 2, "cells": [6], "anchor": Vector2(256, 256),
		"width": 100.0, "out": SHOTS + "big_bubble_fly"},
	# Bolhona estourando: a explosão do jogo tem raio 200.
	{"sheet": "tiros_ex.png", "columns": 4, "rows": 2, "cells": [7], "anchor": Vector2(256, 256),
		"width": 400.0, "out": SHOTS + "big_bubble_pop"},
	# Clarões: células de 256, o clarão começa na borda esquerda (0, 128) = a boca da pistola.
	{"sheet": "claroes.png", "columns": 4, "rows": 1, "cells": [0], "anchor": Vector2(0, 128),
		"width": 56.0, "out": GUNS + "flash_cork_gun"},
	{"sheet": "claroes.png", "columns": 4, "rows": 1, "cells": [1], "anchor": Vector2(0, 128),
		"width": 60.0, "out": GUNS + "flash_confetti_fan"},
	{"sheet": "claroes.png", "columns": 4, "rows": 1, "cells": [2], "anchor": Vector2(0, 128),
		"width": 56.0, "out": GUNS + "flash_juggling_club"},
	{"sheet": "claroes.png", "columns": 4, "rows": 1, "cells": [3], "anchor": Vector2(0, 128),
		"width": 56.0, "out": GUNS + "flash_soap_bubble"},
]

## Luvas com as pistolas (luvas_pistolas.png, 4 células de 512): o mesmo retângulo nas 4, para o
## punho ficar no mesmo lugar. "anchor" é o ponto da célula que vira o (0, 0) da mão da arma (o
## punho, como na luva antiga), e a escala deixa a Rolha do mesmo tamanho da luva antiga.
const GLOVES := ["cork_gun", "confetti_fan", "juggling_club", "soap_bubble"]
const GLOVE_ANCHOR := Vector2(75, 262)
## Pixels de jogo por pixel da célula (a luva antiga: punho até a boca = 97 px de jogo).
const GLOVE_SCALE := 0.25


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GUNS))
	for a in ANIMATIONS:
		_cut(a)
	_cut_gloves()
	quit()


func _load(sheet: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + sheet))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _cell(sheet: Image, columns: int, rows: int, index: int) -> Image:
	var size := Vector2i(sheet.get_width() / columns, sheet.get_height() / rows)
	return sheet.get_region(Rect2i(Vector2i(index % columns, index / columns) * size, size))


func _cut(a: Dictionary) -> void:
	var sheet := _load(a.sheet)
	var cells: Array[Image] = []
	var union := Rect2i()
	for i in a.cells.size():
		var cell := _cell(sheet, a.columns, a.rows, a.cells[i])
		_clean(cell)
		cells.append(cell)
		var used := _visible_rect(cell)
		union = used if i == 0 else union.merge(used)
	union = union.grow(2).intersection(Rect2i(Vector2i.ZERO, cells[0].get_size()))
	var scale: float = a.scale if a.has("scale") else a.width / union.size.x
	var paths: Array[String] = []
	for i in cells.size():
		var frame := cells[i].get_region(union)
		frame.resize(maxi(roundi(union.size.x * scale * TEXTURE_SCALE), 1),
				maxi(roundi(union.size.y * scale * TEXTURE_SCALE), 1), Image.INTERPOLATE_LANCZOS)
		var path: String = a.out + "_%d.png" % (i + 1)
		frame.save_png(path)
		paths.append(path)
	var origin: Vector2 = (Vector2(union.position) - a.anchor) * scale
	_write_resource(a.out + ".tres", paths, 1.0 / TEXTURE_SCALE, origin)


func _cut_gloves() -> void:
	var sheet := _load("luvas_pistolas.png")
	var cells: Array[Image] = []
	var union := Rect2i()
	for i in GLOVES.size():
		var cell := _cell(sheet, 4, 1, i)
		_clean(cell)
		cells.append(cell)
		var used := _visible_rect(cell)
		union = used if i == 0 else union.merge(used)
	union = union.grow(2).intersection(Rect2i(Vector2i.ZERO, cells[0].get_size()))
	for i in GLOVES.size():
		var frame := cells[i].get_region(union)
		frame.resize(roundi(union.size.x * GLOVE_SCALE * TEXTURE_SCALE),
				roundi(union.size.y * GLOVE_SCALE * TEXTURE_SCALE), Image.INTERPOLATE_LANCZOS)
		frame.save_png(GUNS + "glove_%s.png" % GLOVES[i])
	# Centro da textura em relação ao punho, em pixels da textura (o Sprite2D da mão usa escala 0,5).
	var center := (Vector2(union.get_center()) - GLOVE_ANCHOR) * GLOVE_SCALE * TEXTURE_SCALE
	print("luvas: retângulo ", union, " offset da mão ", center)


## Apaga sujeirinhas quase transparentes (deixa o recorte e a borda limpos).
func _clean(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c.a < MIN_ALPHA:
				img.set_pixel(x, y, Color(c, 0.0))


func _visible_rect(img: Image) -> Rect2i:
	var first := img.get_size()
	var last := Vector2i.ZERO
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a >= MIN_ALPHA:
				first = Vector2i(mini(first.x, x), mini(first.y, y))
				last = Vector2i(maxi(last.x, x + 1), maxi(last.y, y + 1))
	return Rect2i(first, last - first)


## Escreve o .tres à mão (os PNGs ainda não foram importados, então não dá para load()).
func _write_resource(path: String, frames: Array[String], scale: float, origin: Vector2) -> void:
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
	text += "origin = Vector2(%s, %s)\n" % [origin.x, origin.y]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	print(path, " origem ", origin)
