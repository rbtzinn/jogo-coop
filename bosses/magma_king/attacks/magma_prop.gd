class_name MagmaProp
extends EnemyHitbox
## Objeto de ataque do Rei Magma: bola de lava, poça, gema, coroa, pingo, coluna, onda ou jato.
## Quem move é o ataque (posição pelo tempo, igual nos dois PCs); este nó desenha, anima e machuca.
## Os turquesa (`pink`) aceitam parry e estouram nos dois PCs (`parry_id`).

const ART := "res://bosses/magma_king/art/"

## Por tipo: desenhos, escala, quadros por segundo (0 = o ataque escolhe o quadro), forma
## (raio de círculo, ou tamanho de retângulo), meio da forma e ponto de apoio do desenho
## ("center" ou "bottom": a base do desenho no ponto do nó).
const KINDS := {
	&"ball": {"frames": ["fx_ball_1", "fx_ball_2", "fx_ball_3", "fx_ball_4"], "scale": 0.55, "fps": 12.0,
			"circle": 34.0, "anchor": "center"},
	&"puddle": {"frames": ["fx_puddle_1", "fx_puddle_2", "fx_puddle_3", "fx_puddle_4"], "scale": 0.75, "fps": 0.0,
			"rect": Vector2(150, 26), "at": Vector2(0, -13), "anchor": "bottom"},
	&"gem": {"frames": ["fx_gem_1", "fx_gem_2"], "scale": 0.55, "fps": 6.0, "circle": 32.0, "anchor": "center"},
	&"crown": {"frames": ["fx_crown_1", "fx_crown_2", "fx_crown_3", "fx_crown_4"], "scale": 0.7, "fps": 14.0,
			"circle": 62.0, "anchor": "center"},
	&"drop": {"frames": ["fx_drop_1", "fx_drop_2"], "scale": 0.55, "fps": 10.0, "circle": 24.0, "anchor": "center"},
	&"drop_parry": {"frames": ["fx_drop_parry"], "scale": 0.55, "fps": 0.0, "circle": 26.0, "anchor": "center"},
	&"splash": {"frames": ["fx_splash_1", "fx_splash_2", "fx_splash_3"], "scale": 0.55, "fps": 0.0,
			"rect": Vector2(110, 40), "at": Vector2(0, -20), "anchor": "bottom"},
	&"column": {"frames": ["column_1", "column_2", "column_3", "column_4"], "scale": 0.36, "fps": 0.0,
			"rect": Vector2(96, 225), "at": Vector2(0, -112), "anchor": "bottom"},
	&"wave": {"frames": ["wave_1", "wave_2", "wave_3", "wave_4"], "scale": 0.4, "fps": 0.0,
			"rect": Vector2(170, 150), "at": Vector2(-10, -75), "anchor": "bottom"},
	&"jet": {"frames": ["jet_1", "jet_2"], "scale": 0.5, "fps": 12.0, "rect": Vector2(1000, 84), "at": Vector2(-500, 0),
			"anchor": "jet"},
	&"orbit_crown": {"frames": ["fx_crown_1", "fx_crown_2", "fx_crown_3", "fx_crown_4"], "scale": 0.55,
			"fps": 16.0, "circle": 50.0, "anchor": "center"},
}

static var _cache := {}

@export var kind := &"ball"
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

var _time := 0.0
var _sprite := Sprite2D.new()
var _shape := CollisionShape2D.new()
var _info: Dictionary


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	_info = KINDS[kind]
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
	var texture := _texture(names[index % names.size()])
	_sprite.texture = texture
	_sprite.flip_h = flip
	var size := texture.get_size()
	match _info.anchor:
		"bottom":
			_sprite.centered = false
			_sprite.offset = Vector2(-size.x * 0.5, -size.y)
		"jet":
			# O jato sai da boca (borda direita do desenho) para a esquerda, no meio da altura.
			_sprite.centered = false
			_sprite.offset = Vector2(-size.x, -size.y * 0.5)
		_:
			_sprite.centered = true
			_sprite.offset = Vector2.ZERO


## Comprimento do jato (estica o desenho e a área que machuca, a partir da boca).
func set_jet_length(length: float) -> void:
	var base: float = _texture("jet_1").get_width() * float(_info.scale)
	_sprite.scale.x = float(_info.scale) * length / base
	(_shape.shape as RectangleShape2D).size.x = length - 60.0
	_shape.position.x = -(length - 60.0) * 0.5 - 30.0


func _draw() -> void:
	if pink and not popped:
		ParryStyle.draw_sparkle(self, Vector2(26, -26), 10.0, _time)


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.3)


static func _texture(file: String) -> Texture2D:
	if not _cache.has(file):
		_cache[file] = load(ART + file + ".png")
	return _cache[file]
