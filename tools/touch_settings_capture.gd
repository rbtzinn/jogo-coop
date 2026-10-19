extends Node
## Fotos da aba Controles do celular e do editor de posição (o PC não monta a aba de toque sozinho).
## Uso: Godot --path . res://tools/touch_settings_capture.tscn (precisa de janela; salva em build/qa/touch).
const OUT := "res://build/qa/touch/"


func _ready() -> void:
	_run.call_deferred()


func photo(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + label + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var menu := SettingsMenu.new()
	center.add_child(menu)
	await get_tree().process_frame
	var tabs: TabContainer = menu.find_children("*", "TabContainer", true, false)[0]
	var touch_tab: Control = menu._build_touch_tab()
	tabs.add_child(touch_tab)
	tabs.move_child(touch_tab, 0)
	tabs.current_tab = 0
	for i in 3:
		await get_tree().process_frame
	await photo("settings_touch_tab")
	menu.hide()
	var editor := TouchLayoutEditor.open(self)
	await get_tree().process_frame
	editor.drag_to(&"jump", Vector2(1500, 700))
	editor._press(1, Vector2(1500, 700), true)
	await get_tree().process_frame
	await photo("layout_editor")
	get_tree().quit()
