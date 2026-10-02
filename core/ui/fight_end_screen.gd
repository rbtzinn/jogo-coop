extends CanvasLayer
## Tela de fim de luta: vitória ou derrota, com "Tentar de novo" e "Voltar ao menu".
## Online, só o host pode recomeçar (o cliente recomeça junto).

const MAIN_MENU := "res://core/ui/main_menu.tscn"

var victory := false


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
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	layout.add_child(UiTheme.title_label("Vitória!" if victory else "Não foi dessa vez...", 80))
	var subtitle := Label.new()
	subtitle.text = "A plateia aplaude de pé!" if victory else "A plateia ainda espera um grande número."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	var first: Button
	if not Network.is_online() or Network.is_host():
		first = _add_button(layout, "Tentar de novo", Network.reload_level)
	else:
		var waiting := Label.new()
		waiting.text = "Esperando o host recomeçar..."
		waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting.add_theme_color_override("font_color", UiTheme.GOLD)
		layout.add_child(waiting)
	var menu_button := _add_button(layout, "Voltar ao menu", _back_to_menu)
	var focus_target := first if first != null else menu_button
	# Espera um instante para um pulo/tiro ainda apertado não acionar o botão.
	get_tree().create_timer(0.6).timeout.connect(focus_target.grab_focus)


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
