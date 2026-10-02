extends SceneTree
## Recorta uma folha de animação quadro a quadro (grade de células iguais, fundo transparente)
## e gera os PNGs + um FrameAnimation (.tres) para o CharacterRig.
## Uso: Godot --headless --script res://tools/cut_animation_sheet.gd
##
## Alinhamento: as células da folha já vêm com o chão na mesma linha, então todos os quadros
## são recortados com o MESMO retângulo (o pulinho desenhado é preservado).
## O ombro da frente é achado a partir do nariz vermelho (ponto vermelho mais à direita na
## metade de cima da célula) mais um deslocamento medido uma vez por personagem.
## Sem "shoulder_from_nose" (ex.: o leão), não calcula ombros.

const SOURCES := "res://docs/referencias/pecas/"
## Os quadros são reduzidos para este tanto do tamanho da célula (fica ~1,7x o tamanho
## na tela: nítido e mais leve).
const TEXTURE_FACTOR := 0.75

## Uma entrada por animação.
const ANIMATIONS := [
	{
		"sheet": "palhaco_corrida.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/clown/run/",
		"name": "run",
		# Linha do chão na célula e o x da célula que fica no centro do corpo (x = 0 no rig).
		"ground_y": 486, "center_x": 290,
		# Altura do personagem em pé, em pixels da célula, e a altura dele no rig.
		"cell_height": 406.0, "rig_height": 198.0,
		"shoulder_from_nose": Vector2(-64, 60),
	},
	{
		"sheet": "acrobata_corrida.png",
		"columns": 4, "rows": 2, "count": 8,
		"out_dir": "res://core/player/characters/acrobat/run/",
		"name": "run",
		# Folha arrumada por tools/normalize_sheet.gd (chão em 486, nariz em x = 400).
		"ground_y": 486, "center_x": 313,
		"cell_height": 465.0, "rig_height": 268.0,
		"shoulder_from_nose": Vector2(-45, 55),
	},
	# Leopoldo: células de 1024 x 512, olhando para a esquerda; parado mede 396 px de altura.
	{
		"sheet": "leao/leao_parado.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "idle",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	{
		"sheet": "leao/leao_rugido.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "roar",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	{
		"sheet": "leao/leao_corrida.png",
		"columns": 2, "rows": 4, "count": 8,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "run",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
	{
		"sheet": "leao/leao_pulo.png",
		"columns": 2, "rows": 2, "count": 4,
		"out_dir": "res://bosses/tamer/art/lion/",
		"name": "leap",
		"ground_y": 486, "center_x": 512,
		"cell_height": 396.0, "rig_height": 297.0,
	},
]


func _initialize() -> void:
	for animation in ANIMATIONS:
		_cut(animation)
	quit()


func _cut(a: Dictionary) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + a.sheet))
	sheet.convert(Image.FORMAT_RGBA8)
	var cell_size := Vector2i(sheet.get_width() / a.columns, sheet.get_height() / a.rows)
	var cells: Array[Image] = []
	var union := Rect2i()
	for i in a.count:
		var cell := sheet.get_region(Rect2i(Vector2i(i % a.columns, i / a.columns) * cell_size, cell_size))
		cells.append(cell)
		var used := cell.get_used_rect()
		union = used if i == 0 else union.merge(used)
	union = union.grow(2).intersection(Rect2i(Vector2i.ZERO, cell_size))
	var scale: float = a.rig_height / a.cell_height
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(a.out_dir))
	var paths: Array[String] = []
	var shoulders: Array[Vector2] = []
	for i in a.count:
		var frame := cells[i].get_region(union)
		frame.resize(roundi(union.size.x * TEXTURE_FACTOR), roundi(union.size.y * TEXTURE_FACTOR), Image.INTERPOLATE_LANCZOS)
		var path: String = a.out_dir + "%s_%d.png" % [a.name, i + 1]
		frame.save_png(path)
		paths.append(path)
		if a.has("shoulder_from_nose"):
			var nose := _find_nose(cells[i])
			var shoulder: Vector2 = Vector2(nose) + a.shoulder_from_nose
			shoulders.append((shoulder - Vector2(a.center_x, a.ground_y)) * scale)
			print(path, " nariz ", nose)
		else:
			print(path)
	var origin := (Vector2(union.position) - Vector2(a.center_x, a.ground_y)) * scale
	_write_resource(a.out_dir + a.name + ".tres", paths, scale / TEXTURE_FACTOR, origin, shoulders)


## Ponto vermelho mais à direita na metade de cima da célula (o nariz de palhaço).
func _find_nose(cell: Image) -> Vector2i:
	var nose := Vector2i(-1, -1)
	for y in range(0, cell.get_height() / 2 + 60):
		for x in range(cell.get_width() - 1, -1, -1):
			var c := cell.get_pixel(x, y)
			if c.a > 0.9 and c.r > 0.8 and c.g < 0.25 and c.b < 0.25:
				if x > nose.x:
					nose = Vector2i(x, y)
				break
	return nose


## Escreve o .tres à mão (os PNGs ainda não foram importados, então não dá para load()).
func _write_resource(path: String, frames: Array[String], scale: float, origin: Vector2,
		shoulders: Array[Vector2]) -> void:
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
	if not shoulders.is_empty():
		var values := PackedStringArray()
		for s in shoulders:
			values.append("%.1f, %.1f" % [s.x, s.y])
		text += "shoulders = PackedVector2Array(%s)\n" % ", ".join(values)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	print(path, " escala ", scale, " origem ", origin)
