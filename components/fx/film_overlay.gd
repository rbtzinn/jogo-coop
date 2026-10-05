extends CanvasLayer
## Aplica o filtro de filme antigo na tela toda (autoload "FilmOverlay").
## Fica abaixo da interface (HUD e menus não recebem o filtro).

const SHADER := preload("res://shaders/old_film.gdshader")

## Valores por qualidade (1 = média, 2 = alta; baixa desliga):
## [sépia, grão, tremulação, arranhões, vinheta].
const PRESETS := {
	1: [0.035, 0.012, 0.008, 0.0, 0.30],
	2: [0.055, 0.020, 0.012, 0.12, 0.40],
}

var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = 5
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)
	Settings.changed.connect(_apply_quality)
	_apply_quality()


func _apply_quality() -> void:
	_rect.visible = PRESETS.has(Settings.quality)
	if not _rect.visible:
		return
	var values: Array = PRESETS[Settings.quality]
	_material.set_shader_parameter("sepia_amount", values[0])
	_material.set_shader_parameter("grain_amount", values[1])
	_material.set_shader_parameter("flicker_amount", values[2])
	_material.set_shader_parameter("scratch_amount", values[3])
	_material.set_shader_parameter("vignette_amount", values[4])
