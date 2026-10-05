class_name MapSprite
extends Node3D
## Personagem no mapa desenhado com os mesmos quadros da luta (parado e corrida, os PNGs do rig), só que
## menor (pedido do usuário em 05/10/2026: a miniatura 3D ficou feia). O desenho fica de frente para a
## câmera, com os pés no ponto do boneco, e vira para o lado em que ele anda.

## Altura do personagem no mapa (metros na tela; na câmera do mapa dá uns 12% da altura da tela).
const HEIGHT := 1.9
## Metros andados por ciclo da corrida (os pés acompanham o chão).
const CYCLE_LENGTH := 1.9
## Quadros por segundo da animação parada (a mesma da luta).
const IDLE_FPS := 8.0
## Luz da noite por cima do desenho (os quadros são pintados claros, para o dia do picadeiro).
const NIGHT_TINT := Color(1.0, 0.93, 0.84)

var idle: FrameAnimation
var run: FrameAnimation
var run_weights := PackedFloat32Array()
## 1 = olhando para a direita, -1 = esquerda.
var facing := 1

var _sprite := Sprite3D.new()
var _meters := 0.01
var _phase := 0.0
var _idle_time := 0.0


## Lê os quadros do rig da luta (a cena do personagem).
func setup(rig_scene: PackedScene) -> void:
	var rig: CharacterRig = rig_scene.instantiate()
	idle = rig.idle_animation
	run = rig.run_animation
	run_weights = rig.run_frame_weights
	rig.free()
	_meters = HEIGHT / maxf(-idle.origin.y, 1.0)


func _ready() -> void:
	_sprite.centered = true
	_sprite.shaded = false
	_sprite.double_sided = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sprite.modulate = NIGHT_TINT
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)


## `velocity` no chão (m/s); parado, volta para a animação parada.
func update_pose(delta: float, velocity: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		global_basis = camera.global_basis
	if idle == null:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	var animation := idle
	var index := 0
	if speed > 0.3 and run != null:
		_phase = fposmod(_phase + speed * delta / CYCLE_LENGTH, 1.0)
		_idle_time = 0.0
		animation = run
		index = run.index_at(_phase, run_weights)
	else:
		_idle_time += delta
		index = int(_idle_time * IDLE_FPS) % idle.frame_count()
	var texture := animation.frames[index]
	var center := animation.origin_of(index) + texture.get_size() * animation.frame_scale * 0.5
	_sprite.texture = texture
	_sprite.pixel_size = animation.frame_scale * _meters
	_sprite.flip_h = facing < 0
	_sprite.position = Vector3(center.x * facing, -center.y, 0.0) * _meters
