class_name BossProp
extends EnemyHitbox
## Objeto de ataque de chefão feito de desenhos (bola, pena, onda, ovo...). Quem move é o ataque (posição pelo
## tempo, igual nos dois PCs); este nó desenha, anima e machuca. Os turquesa (`pink`) aceitam parry e estouram
## nos dois PCs (`parry_id`).
## Cada chefão herda e diz os tipos em `_kinds()` (e a pasta dos desenhos em `_art()`). Por tipo: "frames"
## (nomes dos PNGs), "scale", "fps" (0 = o ataque escolhe o quadro em `frame`), a forma ("circle": raio, ou
## "rect": tamanho, com o meio em "at") e "anchor": "center" (meio do desenho no ponto do nó), "bottom" (a base
## do desenho no ponto) ou "right" (a borda direita no ponto, meio da altura: o que sai de uma boca para a
## esquerda).

static var _cache := {}

@export var kind := &""
@export var pink := false

## Identifica o objeto nos dois PCs (para estourar o mesmo quando o parceiro faz parry).
var parry_id := ""
var popped := false
## Quadro escolhido pelo ataque (para tipos com fps 0).
var frame := 0
## Prende num quadro mesmo nos tipos animados (ex.: a coroa cravada no chão para de girar); -1 = anima.
var hold_frame := -1
## Espelha o desenho (vai para a direita).
var flip := false
## Giro do desenho (radianos), sem girar a área que machuca.
var spin := 0.0

var _time := 0.0
var _sprite := Sprite2D.new()
var _shape := CollisionShape2D.new()
var _info: Dictionary


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	_info = _kinds()[kind]
	if _info.has("circle"):
		var circle := CircleShape2D.new()
		circle.radius = _info.circle
		_shape.shape = circle
	else:
		var rect := RectangleShape2D.new()
		rect.size = _info.rect
		_shape.shape = rect
		_shape.position = _info.get("at", Vector2.ZERO)
	add_child(_shape)
	_sprite.scale = Vector2.ONE * float(_info.scale)
	add_child(_sprite)
	_show(0)


func _process(delta: float) -> void:
	_time += delta
	var fps: float = _info.fps
	if hold_frame >= 0:
		_show(hold_frame)
	else:
		_show(int(_time * fps) if fps > 0.0 else frame)
	if pink:
		queue_redraw()


func _show(index: int) -> void:
	var names: Array = _info.frames
	var texture := texture_of(names[index % names.size()])
	_sprite.texture = texture
	_sprite.flip_h = flip
	_sprite.rotation = spin
	var size := texture.get_size()
	match _info.anchor:
		"bottom":
			_sprite.centered = false
			_sprite.offset = Vector2(-size.x * 0.5, -size.y)
		"right":
			_sprite.centered = false
			_sprite.offset = Vector2(-size.x, -size.y * 0.5)
		_:
			_sprite.centered = true
			_sprite.offset = Vector2.ZERO


func _draw() -> void:
	if pink and not popped:
		ParryStyle.draw_sparkle(self, Vector2(26, -26), 10.0, _time)


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.3)


## Desenho `file` (sem ".png") da pasta deste chefão.
func texture_of(file: String) -> Texture2D:
	var path := _art() + file + ".png"
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


# --- Para cada chefão ---

func _kinds() -> Dictionary:
	return {}


## Pasta dos desenhos, terminando em "/".
func _art() -> String:
	return ""
