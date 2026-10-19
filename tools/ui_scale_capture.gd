extends Node
## Fotos dos menus em cada "Tamanho da interface" (Normal, Grande, Enorme), para ver se algo transborda.
## Uso: Godot --path . res://tools/ui_scale_capture.tscn -- <0|1|2> (precisa de janela; salva em build/qa/ui_scale).
const OUT := "res://build/qa/ui_scale/"


func _ready() -> void:
	_run.call_deferred()


func photo(label: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + label + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var args := OS.get_cmdline_user_args()
	var index := int(args[0]) if not args.is_empty() else 2
	var saved := Settings.ui_scale_index
	Settings.ui_scale_index = index
	SaveGame.path = "user://ui_scale_capture.json"
	SaveGame.reset()
	var menu: Control = load(Levels.MENU).instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await photo("%d_main_menu" % index)
	var settings: SettingsMenu = menu.find_children("*", "SettingsMenu", true, false)[0]
	settings.open()
	await photo("%d_settings_controls" % index)
	var tabs: TabContainer = settings.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await photo("%d_settings_video" % index)
	settings.close()
	menu.queue_free()
	var map: Node = load(Levels.MAP).instantiate()
	get_tree().root.add_child(map)
	get_tree().current_scene = map
	await photo("%d_map" % index)
	ShopPanel.open_for("clown", null)
	await photo("%d_shop" % index)
	Settings.ui_scale_index = saved
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()
