extends SceneTree
## Arruma uma folha de animação que veio no tamanho errado ou com quadros fora do lugar:
## amplia (ou reduz) a folha inteira por igual até a largura certa (sem distorcer), e
## recoloca cada quadro no meio da sua célula de 512 x 512.
## Âncora "ar": o meio do desenho vai para (256, 280) da célula (quadros no ar: parry, salto).
## Âncora "chao": a sola vai para y = 486 e o meio para x = 256 (quadros no chão).
## Âncora "cintura": o meio do maiô vai para (alvo_x, alvo_y), 256 e 280 se não disser (acrobata).
## Âncora "balao": o meio do oval rosa do balão vai para (256, alvo_y).
## Uso:
##   Godot --headless --script res://tools/regrid_sheet.gd -- <entrada.png> <saída.png> <colunas> <linhas> [ar|chao|pes|cintura|balao]
## Avisa se algum desenho encostava na borda da célula (pode ter sido cortado) ou não cabe.

const CELL := 512
const AIR_CENTER := Vector2i(256, 280)
const GROUND_Y := 486
## Alpha abaixo disto vira transparente (sujeira da ampliação).
const ALPHA_FLOOR := 0.03
## Tamanho da célula (opção "celula=LxA", ex.: celula=1024x512 para o leão; padrão 512 x 512).
var _cell := Vector2i(CELL, CELL)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		print("uso: -- <entrada.png> <saída.png> <colunas> <linhas> [ar|chao|pes|cintura|balao]")
		quit(1)
		return
	var columns := int(args[2])
	var rows := int(args[3])
	var anchor := args[4] if args.size() > 4 else "ar"
	for option: String in args.slice(5):
		if option.begins_with("celula="):
			var size := option.substr(7).split("x")
			_cell = Vector2i(size[0].to_int(), size[1].to_int())
	var source := Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	var target := Vector2i(columns * _cell.x, rows * _cell.y)
	var factor := float(target.x) / source.get_width()
	var scaled_height := source.get_height() * factor
	print("entrada %dx%d, fator %.4f, altura ampliada %.1f (alvo %d)" % [source.get_width(), source.get_height(), factor, scaled_height, target.y])
	if absf(scaled_height - target.y) > 2.0:
		print("AVISO: a proporção da folha não bate com a grade; as células seguem a largura")
	source.resize(target.x, roundi(scaled_height), Image.INTERPOLATE_LANCZOS)
	_clean_alpha(source)
	var result := Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)
	var problems := 0
	# Divide pelos vãos transparentes mais perto das linhas da grade (um efeito, como faíscas,
	# pode passar um pouco da linha; assim ele fica com o quadro dele).
	# Primeiro as colunas (pela altura toda), depois o vão entre as filas dentro de cada coluna.
	var column_cuts := _cuts(source, columns, true, Rect2i(Vector2i.ZERO, source.get_size()))
	var row_cuts_by_column := []
	for column in columns:
		var strip := Rect2i(column_cuts[column], 0, column_cuts[column + 1] - column_cuts[column], source.get_height())
		row_cuts_by_column.append(_cuts(source, rows, false, strip))
	# Opções extras: "limpar" (tira pedaços soltos pequenos), "medir" (proporções de cada
	# figura) e "altura=N" (escala uniforme por fila até a altura N, mantendo a respiração).
	var options := args.slice(5)
	var clean := "limpar" in options
	var measure := "medir" in options
	var target_height := 0
	var uniform_scale := 1.0
	var waist_y := AIR_CENTER.y
	var waist_x := 256
	# Por quadro (opções que podem repetir): "escala_quadro=N:F" troca o fator do quadro N;
	# "nariz_quadro=N:X,Y" põe o meio do nariz de bola do quadro N em (X, Y) da célula;
	# "meio_quadro=N:X,Y" põe o meio do desenho do quadro N em (X, Y); "nao_limpar=N" deixa o
	# quadro N sem a limpeza (confete, faíscas soltas de propósito).
	var frame_scale := {}
	var frame_nose := {}
	var frame_middle := {}
	var keep_specks := []
	for option: String in options:
		var value := option.get_slice("=", 1)
		if option.begins_with("escala_quadro="):
			frame_scale[value.get_slice(":", 0).to_int()] = value.get_slice(":", 1).to_float()
		elif option.begins_with("nariz_quadro=") or option.begins_with("meio_quadro="):
			var point := value.get_slice(":", 1)
			var spot := Vector2i(point.get_slice(",", 0).to_int(), point.get_slice(",", 1).to_int())
			(frame_nose if option.begins_with("nariz") else frame_middle)[value.get_slice(":", 0).to_int()] = spot
		elif option.begins_with("nao_limpar="):
			keep_specks.append(value.to_int())
	for option: String in options:
		if option.begins_with("altura="):
			target_height = option.substr(7).to_int()
		elif option.begins_with("alvo_y="):
			waist_y = option.substr(7).to_int()
		elif option.begins_with("alvo_x="):
			waist_x = option.substr(7).to_int()
		elif option.begins_with("escala="):
			uniform_scale = option.substr(7).to_float()
	var frames := []
	for row in rows:
		for column in columns:
			var row_cuts: Array = row_cuts_by_column[column]
			var cell_rect := Rect2i(column_cuts[column], row_cuts[row], column_cuts[column + 1] - column_cuts[column], row_cuts[row + 1] - row_cuts[row])
			var cell := source.get_region(cell_rect)
			_clean_alpha(cell)
			var index := row * columns + column + 1
			if clean and not index in keep_specks:
				var removed := _remove_specks(cell)
				if removed > 0:
					print("quadro %d: limpeza tirou %d pixels soltos" % [index, removed])
			var used := cell.get_used_rect()
			if used.size == Vector2i.ZERO:
				print("quadro %d: vazio" % index)
				continue
			if used.position.x == 0 or used.position.y == 0 or used.end.x >= cell.get_width() or used.end.y >= cell.get_height():
				print("AVISO quadro %d: o desenho encosta na borda da célula (%s)" % [index, used])
				problems += 1
			frames.append({"index": index, "row": row, "column": column, "sprite": cell.get_region(used)})
	if measure:
		for frame in frames:
			_measure(frame.index, frame.sprite)
	if not is_equal_approx(uniform_scale, 1.0):
		# Um fator só para a folha inteira (mantém a diferença de altura entre as poses).
		print("escala única %.4f" % uniform_scale)
		for frame in frames:
			if frame_scale.has(frame.index):
				continue
			var sprite: Image = frame.sprite
			sprite.resize(maxi(roundi(sprite.get_width() * uniform_scale), 1), maxi(roundi(sprite.get_height() * uniform_scale), 1), Image.INTERPOLATE_LANCZOS)
			_clean_alpha(sprite)
	for frame in frames:
		if frame_scale.has(frame.index):
			var k: float = frame_scale[frame.index]
			print("quadro %d: escala própria %.4f" % [frame.index, k])
			var sprite: Image = frame.sprite
			sprite.resize(maxi(roundi(sprite.get_width() * k), 1), maxi(roundi(sprite.get_height() * k), 1), Image.INTERPOLATE_LANCZOS)
			_clean_alpha(sprite)
	if target_height > 0:
		# Escala por fila: a altura mediana de cada fila vai para N (sem distorcer; a diferença
		# pequena entre os quadros da mesma fila, a respiração, continua).
		for row in rows:
			var heights := []
			for frame in frames:
				if frame.row == row:
					heights.append(frame.sprite.get_height())
			if heights.is_empty():
				continue
			heights.sort()
			var k: float = float(target_height) / heights[heights.size() / 2]
			print("fila %d: altura mediana %d, escala %.4f" % [row + 1, heights[heights.size() / 2], k])
			for frame in frames:
				if frame.row == row:
					var sprite: Image = frame.sprite
					sprite.resize(maxi(roundi(sprite.get_width() * k), 1), maxi(roundi(sprite.get_height() * k), 1), Image.INTERPOLATE_LANCZOS)
					_clean_alpha(sprite)
	for frame in frames:
		var index: int = frame.index
		var row: int = frame.row
		var column: int = frame.column
		var sprite: Image = frame.sprite
		var used := Rect2i(Vector2i.ZERO, sprite.get_size())
		var at: Vector2i
		if frame_nose.has(index):
			var nose := _round_nose(sprite)
			at = (frame_nose[index] as Vector2i) - nose
			print("quadro %d: nariz em %s do desenho" % [index, nose])
		elif frame_middle.has(index):
			at = (frame_middle[index] as Vector2i) - used.size / 2
		elif anchor == "balao":
			# Balão: o meio do oval rosa (elipse ajustada à silhueta de fora, sem cabelo, chapéu,
			# nó nem barbante) em (256, alvo_y).
			var oval := _balloon_oval(sprite)
			at = Vector2i(waist_x, waist_y) - Vector2i(roundi(oval.x), roundi(oval.y))
			print("quadro %d: oval do balão com meio em (%.1f, %.1f) do desenho, %.1f x %.1f" % [index, oval.x, oval.y, oval.z, oval.w])
		elif anchor == "cintura":
			# Cintura fixa: o meio do maiô (o maior grupo azul-petróleo, a roupa da acrobata) em
			# (256, alvo_y). Mantém o corpo parado entre os quadros mesmo com as pernas mudando.
			var waist := _waist_center(sprite)
			at = Vector2i(waist_x, waist_y) - waist
			print("quadro %d: cintura em %s do desenho" % [index, waist])
		elif anchor == "pes":
			# Pés plantados: o meio dos pés (as 40 linhas de baixo) em x = 256, a sola em 486.
			var feet_x := _feet_center(sprite)
			at = Vector2i(256 - feet_x, GROUND_Y - used.size.y)
			print("quadro %d: meio dos pés em x = %d do desenho" % [index, feet_x])
		elif anchor == "chao":
			at = Vector2i(256 - used.size.x / 2, GROUND_Y - used.size.y)
		else:
			at = AIR_CENTER - used.size / 2
		if at.x < 0 or at.y < 0 or at.x + used.size.x > _cell.x or at.y + used.size.y > _cell.y:
			print("AVISO quadro %d: não cabe na célula (%s)" % [index, used.size])
			problems += 1
			at = at.clamp(Vector2i.ZERO, _cell - used.size)
		result.blit_rect(sprite, Rect2i(Vector2i.ZERO, used.size), Vector2i(column * _cell.x, row * _cell.y) + at)
		print("quadro %d: tamanho %s, colocado em %s" % [index, used.size, at])
	result.save_png(args[1])
	print("salvo %s (%d avisos)" % [args[1], problems])
	quit(problems)


## Tira pedaços soltos: grupos de pixels (ligados entre si, alpha > 0) que não tocam a figura
## principal (o maior grupo) e têm menos de 400 pixels. Não mexe em nada ligado ao desenho.
## Retorna quantos pixels tirou.
func _remove_specks(image: Image) -> int:
	var width := image.get_width()
	var height := image.get_height()
	var labels := PackedInt32Array()
	labels.resize(width * height)
	var sizes := [0]
	var groups := []
	for start in width * height:
		if labels[start] != 0 or image.get_pixel(start % width, start / width).a <= 0.0:
			continue
		var label := sizes.size()
		var members := PackedInt32Array([start])
		labels[start] = label
		var i := 0
		while i < members.size():
			var p := members[i]
			i += 1
			var px := p % width
			var py := p / width
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = px + dx
					var ny: int = py + dy
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					var q := ny * width + nx
					if labels[q] == 0 and image.get_pixel(nx, ny).a > 0.0:
						labels[q] = label
						members.append(q)
		sizes.append(members.size())
		groups.append(members)
	var biggest := 0
	for label in range(1, sizes.size()):
		if biggest == 0 or sizes[label] > sizes[biggest]:
			biggest = label
	var removed := 0
	for label in range(1, sizes.size()):
		if label != biggest and sizes[label] < 400:
			for p in groups[label - 1]:
				image.set_pixel(p % width, p / width, Color(0, 0, 0, 0))
			removed += sizes[label]
	return removed


## Proporções da figura, para saber se a diferença entre quadros é só de escala:
## altura, largura/altura e onde está o nariz vermelho (fração da altura, de cima).
## Nariz (personagem de lado, olhando para a direita): o vermelho mais à direita na metade de cima,
## e o meio do grupo vermelho ligado a ele. (Antes era a primeira linha com vermelho, que no
## palhaço é o cabelo: dava 73 px do topo em vez dos 164 do nariz.)
func _measure(index: int, sprite: Image) -> void:
	var seed := Vector2i(-1, -1)
	for y in sprite.get_height() / 2:
		for x in range(sprite.get_width() - 1, -1, -1):
			if _is_red(sprite.get_pixel(x, y)):
				if x > seed.x:
					seed = Vector2i(x, y)
				break
	var nose_y := -1
	if seed.x >= 0:
		var group := [seed]
		var seen := {seed: true}
		var box := Rect2i(seed, Vector2i.ONE)
		var i := 0
		while i < group.size():
			var q: Vector2i = group[i]
			i += 1
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n := q + d
				var inside := n.x >= 0 and n.y >= 0 and n.x < sprite.get_width() and n.y < sprite.get_height()
				if inside and not seen.has(n) and _is_red(sprite.get_pixel(n.x, n.y)):
					seen[n] = true
					group.append(n)
					box = box.expand(n)
		nose_y = box.position.y + (box.size.y + 1) / 2
	print("medida quadro %d: altura %d, largura/altura %.3f, nariz a %.3f da altura (%d px do topo)" % [index,
			sprite.get_height(), float(sprite.get_width()) / sprite.get_height(), float(nose_y) / sprite.get_height(), nose_y])


## Meio do maior grupo de pixels azul-petróleo escuros (o maiô da acrobata; os sapatos são
## grupos menores).
func _waist_center(sprite: Image) -> Vector2i:
	var width := sprite.get_width()
	var height := sprite.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var best := PackedInt32Array()
	for start in width * height:
		if seen[start] != 0 or not _is_teal(sprite.get_pixel(start % width, start / width)):
			continue
		seen[start] = 1
		var group := PackedInt32Array([start])
		var i := 0
		while i < group.size():
			var p := group[i]
			i += 1
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := p % width + d.x
				var ny := p / width + d.y
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				var q := ny * width + nx
				if seen[q] == 0 and _is_teal(sprite.get_pixel(nx, ny)):
					seen[q] = 1
					group.append(q)
		if group.size() > best.size():
			best = group
	var sum := Vector2.ZERO
	for p in best:
		sum += Vector2(p % width, p / width)
	return Vector2i(sum / maxf(best.size(), 1.0))


func _is_teal(c: Color) -> bool:
	return c.a > 0.9 and c.b > c.r + 0.04 and c.g > c.r + 0.04 and c.get_luminance() < 0.5


## Meio do nariz de bola: entre os grupos vermelhos (o cabelo também é vermelho), o mais redondo.
func _round_nose(sprite: Image) -> Vector2i:
	var width := sprite.get_width()
	var height := sprite.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var best := Rect2i()
	var best_score := 0.0
	for start in width * height:
		if seen[start] != 0 or not _is_red(sprite.get_pixel(start % width, start / width)):
			continue
		seen[start] = 1
		var group := PackedInt32Array([start])
		var box := Rect2i(start % width, start / width, 1, 1)
		var i := 0
		while i < group.size():
			var p := group[i]
			i += 1
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := p % width + d.x
				var ny := p / width + d.y
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				var q := ny * width + nx
				if seen[q] == 0 and _is_red(sprite.get_pixel(nx, ny)):
					seen[q] = 1
					group.append(q)
					box = box.expand(Vector2i(nx, ny))
		box.size += Vector2i.ONE
		if group.size() < 150 or box.size.x < 12:
			continue
		var aspect := float(box.size.x) / box.size.y
		var fill := group.size() / (PI / 4.0 * box.size.x * box.size.y)
		var score := fill * (1.0 - absf(1.0 - aspect))
		if score > best_score:
			best_score = score
			best = box
	return best.get_center()


func _is_red(c: Color) -> bool:
	return c.a > 0.9 and c.r > 0.7 and c.g < 0.35 and c.b < 0.35


## Elipse (eixos retos) do balão rosa: meio (x, y) e tamanho (z = largura, w = altura).
## Varre cada linha pelos dois lados e cada coluna por cima e por baixo até o primeiro pixel
## opaco; o ponto vale se logo depois vier rosa (e não cabelo vermelho, barbante creme ou chapéu).
## Ajusta, tira os pontos fora da curva (nó, sobras) e ajusta de novo.
func _balloon_oval(sprite: Image) -> Vector4:
	var size := sprite.get_size()
	var points: Array[Vector2] = []
	for y in size.y:
		for side in [1, -1]:
			var x: int = 0 if side == 1 else size.x - 1
			while x >= 0 and x < size.x and sprite.get_pixel(x, y).a < 0.5:
				x += side
			if x >= 0 and x < size.x and _leads_to_pink(sprite, Vector2i(x, y), Vector2i(side, 0)):
				points.append(Vector2(x, y))
	for x in size.x:
		for side in [1, -1]:
			var y: int = 0 if side == 1 else size.y - 1
			while y >= 0 and y < size.y and sprite.get_pixel(x, y).a < 0.5:
				y += side
			if y >= 0 and y < size.y and _leads_to_pink(sprite, Vector2i(x, y), Vector2i(0, side)):
				points.append(Vector2(x, y))
	var oval := _fit_ellipse(points)
	var kept: Array[Vector2] = []
	for p in points:
		var d := Vector2((p.x - oval.x) / (oval.z / 2.0), (p.y - oval.y) / (oval.w / 2.0)).length()
		if absf(d - 1.0) < 0.06:
			kept.append(p)
	return _fit_ellipse(kept)


func _leads_to_pink(sprite: Image, start: Vector2i, step: Vector2i) -> bool:
	var dark_run := 0
	for k in 24:
		var p := start + step * k
		if p.x < 0 or p.y < 0 or p.x >= sprite.get_width() or p.y >= sprite.get_height():
			return false
		var c := sprite.get_pixel(p.x, p.y)
		if c.a < 0.5:
			return false
		if c.a > 0.9 and c.r > 0.75 and c.g > 0.3 and c.g < 0.75 and c.b > 0.4 and c.b < 0.85 and c.r - c.g > 0.2:
			return true
		if c.r > 0.6 and c.g < 0.3 and c.b < 0.3:
			return false
		if c.r > 0.8 and c.g > 0.75 and c.b > 0.6:
			return false
		if c.get_luminance() < 0.2:
			dark_run += 1
			if dark_run > 14:
				return false
	return false


## Mínimos quadrados de A x² + B y² + C x + D y = 1.
func _fit_ellipse(points: Array[Vector2]) -> Vector4:
	var m := []
	for r in 4:
		m.append([0.0, 0.0, 0.0, 0.0, 0.0])
	for v in points:
		var row := [v.x * v.x, v.y * v.y, v.x, v.y]
		for r in 4:
			for c in 4:
				m[r][c] += row[r] * row[c]
			m[r][4] += row[r]
	for column in 4:
		for r in 4:
			if r != column:
				var f: float = m[r][column] / m[column][column]
				for c in 5:
					m[r][c] -= f * m[column][c]
	var a: float = m[0][4] / m[0][0]
	var b: float = m[1][4] / m[1][1]
	var cx: float = -(m[2][4] / m[2][2]) / (2.0 * a)
	var cy: float = -(m[3][4] / m[3][3]) / (2.0 * b)
	var rhs := 1.0 + a * cx * cx + b * cy * cy
	return Vector4(cx, cy, 2.0 * sqrt(rhs / a), 2.0 * sqrt(rhs / b))


## Meio (x) dos pixels opacos nas 40 linhas de baixo do desenho (os pés).
func _feet_center(sprite: Image) -> int:
	var total := 0
	var count := 0
	for y in range(maxi(sprite.get_height() - 40, 0), sprite.get_height()):
		for x in sprite.get_width():
			if sprite.get_pixel(x, y).a > 0.5:
				total += x
				count += 1
	return total / maxi(count, 1)


## Onde cortar (colunas se `vertical`, senão linhas): em cada linha da grade, a coluna (ou
## linha) totalmente transparente mais perto dela, até 120 px para cada lado. Sem vão, a linha
## da grade mesmo.
func _cuts(image: Image, count: int, vertical: bool, area: Rect2i) -> Array[int]:
	var cuts: Array[int] = [area.position.x if vertical else area.position.y]
	for k in range(1, count):
		var ideal := (area.position.x if vertical else area.position.y) + k * (_cell.x if vertical else _cell.y)
		var best := ideal
		for distance in 121:
			var found := false
			for candidate in [ideal - distance, ideal + distance]:
				if _is_empty_line(image, candidate, vertical, area):
					best = candidate
					found = true
					break
			if found:
				break
		cuts.append(best)
	cuts.append(area.end.x if vertical else area.end.y)
	return cuts


func _is_empty_line(image: Image, at: int, vertical: bool, area: Rect2i) -> bool:
	if vertical:
		if at < 0 or at >= image.get_width():
			return false
		for y in range(area.position.y, area.end.y):
			if image.get_pixel(at, y).a > 0.0:
				return false
	else:
		if at < 0 or at >= image.get_height():
			return false
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, at).a > 0.0:
				return false
	return true


func _clean_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_FLOOR:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
