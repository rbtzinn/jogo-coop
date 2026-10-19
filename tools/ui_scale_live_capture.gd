extends Node
## Foto das configurações abertas logo depois de trocar o tamanho da interface (sem reabrir o jogo).
## Uso: Godot --path . res://tools/ui_scale_live_capture.tscn (precisa de janela; salva em build/qa/ui_live).


func _ready() -> void:
	var saved := Settings.ui_scale_index
	Settings.set_option(&"ui_scale_index", 0)
	var menu: Control = load("res://core/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var settings: SettingsMenu = menu._settings_menu
	settings.open()
	for index in [0, 2]:
		Settings.set_option(&"ui_scale_index", index)
		for i in 10:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://build/qa/ui_live/settings_%d.png" % index)
	Settings.set_option(&"ui_scale_index", saved)
	get_tree().quit()
