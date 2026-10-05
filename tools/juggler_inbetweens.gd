extends SceneTree
## Monta os intermediários do braço da frente do parado dos Malabaristas (E2 normalizada,
## docs/referencias/pecas/malabaristas/tico_malabares.png) e grava a folha de 12 desenhos na ordem de
## tocar: 1, 2, C, 3, A, 4, 5, D, 6, 7, B, 8 (4 × 3 células de 512).
## Uso:
##   Godot --headless --script res://tools/juggler_inbetweens.gd -- <tico_malabares.png> <saída.png>
## Cada intermediário = corpo e rosto de um desenho vizinho (a raiz do braço dele fica na mesma altura
## da raiz do braço novo, então não sobra pedaço), sem o braço da frente, mais o braço da frente (luva e
## braço inteiros, desenhados à mão) de outro desenho, deslocado pela diferença do corpo (ponta direita
## da gola) e posto ATRÁS do corpo.
## O braço (o que sai e o que entra) é tudo o que está ligado à luva à direita da linha do tronco
## (x mínimo) e acima do quadril (y máximo).
## C = corpo do 2 com o braço do 6 (2→3); A = corpo do 4 com o braço do 2 (3→4); D = corpo do 5 com o
## braço do 2 (5→6); B = corpo do 8 com o braço do 2 (7→8).

## Ponta direita da gola em cada desenho (medida nas ampliações), o ponto de referência do corpo.
const COLLAR := {2: Vector2i(338, 230), 4: Vector2i(355, 237), 5: Vector2i(350, 237), 6: Vector2i(351, 230), 8: Vector2i(361, 237)}
## Braço a tirar de cada corpo: [meio da luva, ponto da pele do braço, x da linha depois da ponta da gola,
## y de baixo da luva]. Sai o miolo da luva e da pele do braço (cheio a partir desses pontos sem passar
## pela tinta) e a tinta que só encosta nele; a tinta que também encosta no tronco fica (vira o contorno
## do tronco). À direita da linha (onde só há braço) sai tudo o que está ligado a ele, até o y de baixo
## (os vincos da luva dividem o branco em pedaços).
## Braço a usar como novo: [meio da luva, x mínimo, y máximo, cantos protegidos] (tudo ligado à luva; o
## que pega do ombro fica escondido atrás do corpo).
const ERASE := {
	2: [Vector2i(425, 226), Vector2i(365, 275), 345, 300],
	4: [Vector2i(413, 293), Vector2i(360, 302), 362, 335],
	5: [Vector2i(416, 270), Vector2i(365, 295), 357, 312],
	8: [Vector2i(417, 289), Vector2i(360, 300), 368, 333],
}
## ...e para usar como braço novo (pega um pouco do ombro, que fica escondido atrás do corpo).
const ARM := {
	2: [Vector2i(425, 226), 326, 335, [Vector2i(386, 200)]],
	6: [Vector2i(432, 194), 330, 335, [Vector2i(398, 185)]],
}
## [célula de saída, corpo, braço]
## Abaixo disto é tinta (contorno).
const INK_V := 0.35
const PLAN := [[9, 2, 6], [10, 4, 2], [11, 5, 2], [12, 8, 2]]
## Ordem de tocar (números 1–8 = desenhos da folha; 9–12 = C, A, D, B).
const ORDER := [1, 2, 9, 3, 10, 4, 5, 11, 6, 7, 12, 8]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var sheet := Image.load_from_file(args[0])
	sheet.convert(Image.FORMAT_RGBA8)
	var out := Image.create(2048, 1536, false, Image.FORMAT_RGBA8)
	out.blit_rect(sheet, Rect2i(0, 0, 2048, 1024), Vector2i.ZERO)
	for step in PLAN:
		var body := _cell(sheet, step[1])
		var arm_src := _cell(sheet, step[2])
		_erase_arm(body, ERASE[step[1]])
		var shift: Vector2i = COLLAR[step[1]] - COLLAR[step[2]]
		var composed := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		for p in _arm(arm_src, ARM[step[2]]):
			var to: Vector2i = p + shift
			if Rect2i(0, 0, 512, 512).has_point(to):
				composed.set_pixelv(to, arm_src.get_pixelv(p))
		composed.blend_rect(body, Rect2i(0, 0, 512, 512), Vector2i.ZERO)
		var specks := _drop_specks(composed, 400)
		var index: int = step[0] - 1
		out.blit_rect(composed, Rect2i(0, 0, 512, 512), Vector2i((index % 4) * 512, (index / 4) * 512))
		var glove: Vector2i = (ARM[step[2]][0] as Vector2i) + shift
		print("célula %d: corpo %d + braço %d deslocado %s; meio da luva em %s; %d px soltos tirados" % [step[0], step[1], step[2], shift, glove, specks])
	var ordered := Image.create(2048, 1536, false, Image.FORMAT_RGBA8)
	for k in ORDER.size():
		var n: int = ORDER[k]
		ordered.blit_rect(out, Rect2i(((n - 1) % 4) * 512, ((n - 1) / 4) * 512, 512, 512), Vector2i((k % 4) * 512, (k / 4) * 512))
	ordered.save_png(args[1])
	print("salvo %s: 12 desenhos na ordem %s" % [args[1], ORDER])
	quit()


func _cell(sheet: Image, n: int) -> Image:
	return sheet.get_region(Rect2i(((n - 1) % 4) * 512, ((n - 1) / 4) * 512, 512, 512))


## Tira grupos soltos (alpha > 0,05, vizinhança de 8) com menos de `limit` pixels: as sobras de tinta do
## braço antigo. Retorna quantos pixels tirou.
func _drop_specks(image: Image, limit: int) -> int:
	var seen := {}
	var removed := 0
	for y in 512:
		for x in 512:
			var start := Vector2i(x, y)
			if seen.has(start) or image.get_pixelv(start).a <= 0.05:
				continue
			var group: Array[Vector2i] = [start]
			seen[start] = true
			var i := 0
			while i < group.size():
				var p := group[i]
				i += 1
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var q := p + Vector2i(dx, dy)
						if not seen.has(q) and Rect2i(0, 0, 512, 512).has_point(q) and image.get_pixelv(q).a > 0.05:
							seen[q] = true
							group.append(q)
			if group.size() < limit:
				for p in group:
					image.set_pixelv(p, Color(0, 0, 0, 0))
				removed += group.size()
	return removed


## Tira o braço da frente do corpo (ver ERASE).
func _erase_arm(image: Image, seeds: Array) -> void:
	var inner := {}
	for seed: Vector2i in [seeds[0], seeds[1]]:
		var c := image.get_pixelv(seed)
		print("semente %s: alpha %.2f V %.2f S %.2f" % [seed, c.a, c.v, c.s])
		var stack: Array[Vector2i] = [seed]
		inner[seed] = true
		while not stack.is_empty():
			var p: Vector2i = stack.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + d
				if inner.has(q) or not Rect2i(0, 0, 512, 512).has_point(q):
					continue
				var k := image.get_pixelv(q)
				if k.a > 0.5 and k.v >= INK_V:
					inner[q] = true
					stack.append(q)
	var clear: Array[Vector2i] = []
	for p: Vector2i in inner:
		clear.append(p)
	# A tinta em volta (até 8 px do miolo) sai se nenhum pixel claro de fora do braço estiver a 3 px.
	var checked := {}
	for p: Vector2i in inner:
		for dy in range(-8, 9):
			for dx in range(-8, 9):
				var q := p + Vector2i(dx, dy)
				if checked.has(q) or inner.has(q) or not Rect2i(0, 0, 512, 512).has_point(q):
					continue
				checked[q] = true
				var k := image.get_pixelv(q)
				if k.a < 0.05 or k.v >= INK_V:
					continue
				var touches_body := false
				for ey in range(-3, 4):
					for ex in range(-3, 4):
						var r := q + Vector2i(ex, ey)
						if inner.has(r) or not Rect2i(0, 0, 512, 512).has_point(r):
							continue
						var m := image.get_pixelv(r)
						if m.a > 0.5 and m.v >= INK_V:
							touches_body = true
				if not touches_body:
					clear.append(q)
	# À direita da linha: tudo o que está ligado ao braço.
	var line_x: int = seeds[2]
	var bottom: int = seeds[3]
	var reach := {}
	var stack: Array[Vector2i] = []
	for p in clear:
		if p.x >= line_x:
			reach[p] = true
			stack.append(p)
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var q := p + Vector2i(dx, dy)
				if reach.has(q) or q.x < line_x or q.y > bottom or q.x >= 512 or q.y < 0:
					continue
				if image.get_pixelv(q).a > 0.05:
					reach[q] = true
					stack.append(q)
	for p: Vector2i in reach:
		clear.append(p)
	for p in clear:
		image.set_pixelv(p, Color(0, 0, 0, 0))


func _protected(p: Vector2i, corners: Array) -> bool:
	for c: Vector2i in corners:
		if p.x < c.x and p.y < c.y:
			return true
	return false


## Pixels ligados à luva (alpha > 0,05, vizinhança de 8) com x >= x mínimo e y <= y máximo.
func _arm(image: Image, spec: Array) -> Array[Vector2i]:
	var seed: Vector2i = spec[0]
	var min_x: int = spec[1]
	var max_y: int = spec[2]
	var corners: Array = spec[3]
	var seen := {seed: true}
	var stack: Array[Vector2i] = [seed]
	var out: Array[Vector2i] = []
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		out.append(p)
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var q := p + Vector2i(dx, dy)
				if seen.has(q) or q.x < min_x or q.y > max_y or q.x >= 512 or q.y < 0 or _protected(q, corners):
					continue
				seen[q] = true
				if image.get_pixelv(q).a > 0.05:
					stack.append(q)
	return out
