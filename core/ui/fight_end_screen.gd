extends CanvasLayer
## Tela de fim de luta em forma de cartaz de circo (papel creme, borda vermelha, lâmpadas
## correndo em volta): vitória ou derrota, com "Tentar de novo" e "Voltar ao menu".
## Online, só o host pode recomeçar (o cliente recomeça junto).

const MAIN_MENU := "res://core/ui/main_menu.tscn"

var victory := false

var _panel: PanelContainer
var _marquee: MarqueeLights


func _ready() -> void:
	layer = 18
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.build()
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	var poster := StyleBoxFlat.new()
	poster.bg_color = Color("f2e6cc")
	poster.border_color = UiTheme.RED
	poster.set_border_width_all(12)
	poster.set_corner_radius_all(10)
	poster.shadow_color = Color(0, 0, 0, 0.5)
	poster.shadow_size = 18
	poster.content_margin_left = 60
	poster.content_margin_right = 60
	poster.content_margin_top = 44
	poster.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", poster)
	center.add_child(panel)
	# As lâmpadas ficam fora do CenterContainer (ele encolheria o Control) e seguem o cartaz.
	_panel = panel
	_marquee = MarqueeLights.new()
	_marquee.spacing = 34.0
	root.add_child(_marquee)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	var ribbon := Label.new()
	ribbon.text = "Respeitável Público"
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_theme_font_override("font", UiTheme.TITLE_FONT)
	ribbon.add_theme_font_size_override("font_size", 30)
	ribbon.add_theme_color_override("font_color", UiTheme.RED_DARK)
	layout.add_child(ribbon)
	var title := UiTheme.title_label("Vitória!" if victory else "Não foi dessa vez...", 84)
	title.add_theme_color_override("font_color", UiTheme.RED if victory else UiTheme.RED_DARK)
	title.add_theme_color_override("font_outline_color", UiTheme.GOLD)
	title.add_theme_constant_override("outline_size", 6)
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A plateia aplaude de pé!" if victory else "A plateia ainda espera um grande número."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", UiTheme.INK)
	subtitle.add_theme_font_size_override("font_size", 30)
	layout.add_child(subtitle)

	var first: Button
	if not Network.is_online() or Network.is_host():
		first = _add_button(layout, "Tentar de novo", Network.reload_level)
	else:
		var waiting := Label.new()
		waiting.text = "Esperando o host recomeçar..."
		waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting.add_theme_color_override("font_color", UiTheme.RED_DARK)
		layout.add_child(waiting)
	var menu_button := _add_button(layout, "Voltar ao menu", _back_to_menu)
	panel.pivot_offset = Vector2(400, 300)
	panel.scale = Vector2(0.4, 0.4)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var focus_target := first if first != null else menu_button
	# Espera um instante para um pulo/tiro ainda apertado não acionar o botão.
	get_tree().create_timer(0.6).timeout.connect(focus_target.grab_focus)


func _process(_delta: float) -> void:
	var rect := _panel.get_global_rect()
	_marquee.position = rect.position - Vector2(6, 6)
	_marquee.size = rect.size + Vector2(12, 12)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(520, 0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _back_to_menu() -> void:
	Network.leave()
	get_tree().change_scene_to_file(MAIN_MENU)
