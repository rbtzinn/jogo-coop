extends Control
## Abertura: o palco com cortinas, letreiro e a rua do circo ao fundo (pintura separada em camadas por
## tools/blender/loading_screen.py), o palhaço e a acrobata apresentando, lâmpadas correndo e a barra
## mostrando o progresso real do carregamento do menu, sem nenhum atraso artificial.
const ART := "res://core/ui/art/loading/"
const LAYOUT := preload("res://core/ui/art/loading/loading_layout.gd")
const STAGE_SHADER := preload("res://shaders/loading_stage.gdshader")
const PUPPET_SHADER := preload("res://shaders/loading_puppet.gdshader")
## Ritmo de cada personagem: [tempo, fase, respiração, balanço, braço da frente, outro braço].
const MOTION := {
	"clown": [1.15, 0.0, 0.011, 0.010, 0.07, 0.05],
	"acrobat": [0.9, 1.7, 0.008, 0.007, 0.05, 0.045],
}
const BLINK_TIME := 0.16

var _progress := TextureProgressBar.new()
var _status := Label.new()
var _requested := false
var _puppets := {}
## Por personagem: segundos até a próxima piscada e quanto da piscada já passou (-1 = olhos abertos).
var _blinks := {}


func _ready() -> void:
	theme = UiTheme.build()
	var data: Dictionary = LAYOUT.DATA
	var stage := TextureRect.new()
	stage.texture = load(ART + "stage.png")
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.stretch_mode = TextureRect.STRETCH_SCALE
	var stage_material := ShaderMaterial.new()
	stage_material.shader = STAGE_SHADER
	stage_material.set_shader_parameter("bulbs", load(ART + "bulbs.png"))
	stage_material.set_shader_parameter("mist_noise", _mist_noise())
	stage.material = stage_material
	add_child(stage)
	var track: Array = data["track"]
	_progress.texture_progress = load(ART + "bar_fill.png")
	_progress.position = Vector2(track[0], track[1])
	_progress.size = Vector2(track[2], track[3])
	_progress.max_value = 100.0
	add_child(_progress)
	for kind in ["clown", "acrobat"]:
		_puppets[kind] = _puppet(kind, data[kind])
		_blinks[kind] = [randf_range(0.8, 2.5), -1.0]
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 26)
	_status.add_theme_color_override("font_color", UiTheme.CREAM)
	_status.add_theme_color_override("font_outline_color", UiTheme.INK)
	_status.add_theme_constant_override("outline_size", 6)
	_status.position = Vector2(0, track[1] + track[3] + 26)
	_status.size = Vector2(1920, 40)
	add_child(_status)
	# Um quadro garante que a abertura apareça antes do pedido, sem um timer artificial.
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(Levels.MENU)
	_requested = error == OK
	if not _requested:
		_status.text = "Não foi possível abrir o menu. Pressione Enter para tentar novamente."


func _process(delta: float) -> void:
	_animate_blinks(delta)
	if not _requested:
		return
	var progress := []
	var state := ResourceLoader.load_threaded_get_status(Levels.MENU, progress)
	if not progress.is_empty():
		_progress.value = progress[0] * 100.0
	if state == ResourceLoader.THREAD_LOAD_LOADED:
		# Auditoria visual (tools/visual_audit): fica na abertura para medir.
		if Engine.get_meta(&"hold_boot", false):
			return
		_requested = false
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(Levels.MENU))
	elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_requested = false
		_status.text = "Não foi possível abrir o menu. Pressione Enter para tentar novamente."


func _unhandled_input(event: InputEvent) -> void:
	if not _requested and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(Levels.MENU)


func _puppet(kind: String, info: Dictionary) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = load(ART + kind + ".png")
	sprite.position = Vector2(info["position"][0], info["position"][1])
	sprite.size = Vector2(info["size"][0], info["size"][1])
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var motion: Array = MOTION[kind]
	var material := ShaderMaterial.new()
	material.shader = PUPPET_SHADER
	material.set_shader_parameter("sprite_size", sprite.size)
	material.set_shader_parameter("feet", info["feet"])
	material.set_shader_parameter("tempo", motion[0])
	material.set_shader_parameter("phase", motion[1])
	material.set_shader_parameter("breath", motion[2])
	material.set_shader_parameter("sway", motion[3])
	for i in 2:
		var arm: Array = info["arms"][i]
		material.set_shader_parameter("arm%d" % i, Vector4(arm[0], arm[1], arm[2], arm[3]))
		material.set_shader_parameter("arm%d_radius" % i, arm[4])
		material.set_shader_parameter("arm%d_swing" % i, motion[4 + i])
		var eye: Array = info["eyes"][i]
		material.set_shader_parameter("eye%d" % i, Vector4(eye[0], eye[1], eye[2], eye[3]))
	var skin: Array = info["skin"]
	material.set_shader_parameter("skin", Color(skin[0], skin[1], skin[2]))
	sprite.material = material
	add_child(sprite)
	return sprite


## Piscadas em intervalos soltos; de vez em quando, duas seguidas.
func _animate_blinks(delta: float) -> void:
	for kind: String in _blinks:
		var state: Array = _blinks[kind]
		var amount := 0.0
		if state[1] < 0.0:
			state[0] -= delta
			if state[0] <= 0.0:
				state[1] = 0.0
		else:
			state[1] += delta
			var t: float = state[1] / BLINK_TIME
			amount = 1.0 - absf(t * 2.0 - 1.0)
			if t >= 1.0:
				state[1] = -1.0
				state[0] = 0.18 if randf() < 0.2 else randf_range(2.0, 4.5)
				amount = 0.0
		(_puppets[kind].material as ShaderMaterial).set_shader_parameter("blink", clampf(amount * 1.4, 0.0, 1.0))


func _mist_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	return texture
