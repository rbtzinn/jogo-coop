class_name ParryStyle
extends RefCounted
## Cor e marca de tudo o que aceita parry: turquesa-fantasma (até 06/10/2026 era rosa, a marca mais conhecida
## do Cuphead; ver docs/regras_originalidade.md). Os desenhos repintados (pedido em
## docs/prompts/chatgpt_parry_turquesa.md) usam a mesma paleta; os objetos desenhados por código usam estas
## cores e ganham a estrelinha de quatro pontas, para serem reconhecidos também pela forma.

const MAIN := Color("2ee6d6")
const LIGHT := Color("b8fff7")
const DARK := Color("138f86")
const RIM := Color("f7fffd")
const INK := Color("1b1410")


## Estrelinha de quatro pontas piscando (`time` em segundos), desenhada em `canvas` no ponto `at`.
static func draw_sparkle(canvas: CanvasItem, at: Vector2, size: float, time: float) -> void:
	var s := size * (0.85 + 0.15 * sin(time * 9.0))
	var points := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI * 0.5
		points.append(at + Vector2.from_angle(a) * (s if i % 2 == 0 else s * 0.3))
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, INK, 3.0, true)
	canvas.draw_colored_polygon(points, RIM)


## Aro claro por dentro da beira de um círculo de parry.
static func draw_rim(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	canvas.draw_arc(center, radius - 2.5, 0.0, TAU, 24, Color(RIM, 0.85), 2.5, true)
