extends Node
## Rodar: Godot --headless --path . res://tests/test_ui_scale_live.tscn
## Tamanho da interface muda na hora: com o menu e as configurações abertos, trocar para Enorme aumenta
## o tema, os textos e os botões; voltar para Normal devolve os tamanhos exatos de antes.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	get_tree().create_timer(60.0, true, false, true).timeout.connect(func() -> void: get_tree().quit(99))
	_run.call_deferred()


func _run() -> void:
	var saved := Settings.ui_scale_index
	Settings.set_option(&"ui_scale_index", 0)
	var menu: Control = load("res://core/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var settings: SettingsMenu = menu._settings_menu
	settings.open()
	var button: Button = menu.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.has_meta(UiTheme.SCALED_HEIGHT_META))[0]
	var font := button.get_theme_font_size("font_size")
	var height := button.custom_minimum_size.y
	var theme_size := menu.theme.default_font_size
	var title := _first_override(settings)
	Settings.set_option(&"ui_scale_index", 2)
	check(menu.theme.default_font_size > theme_size * 1.3, "Enorme: menu theme text grows at once")
	check(settings.theme == menu.theme, "settings panel uses the same new theme")
	check(button.get_theme_font_size("font_size") > font * 1.3, "Enorme: menu button text grows")
	check(button.custom_minimum_size.y > height * 1.3, "Enorme: menu button gets taller")
	check(title[0].get_theme_font_size("font_size") > title[1] * 1.3, "Enorme: settings texts grow")
	Settings.set_option(&"ui_scale_index", 1)
	Settings.set_option(&"ui_scale_index", 2)
	Settings.set_option(&"ui_scale_index", 0)
	check(menu.theme.default_font_size == theme_size, "Normal: theme back to the same size")
	check(button.get_theme_font_size("font_size") == font and is_equal_approx(button.custom_minimum_size.y, height), "Normal: button back exactly (no drift)")
	check(title[0].get_theme_font_size("font_size") == title[1], "Normal: settings text back exactly")
	Settings.set_option(&"ui_scale_index", saved)
	print("FAILURES: ", failures)
	get_tree().quit(failures)


## Primeiro texto com tamanho próprio dentro das configurações: [controle, tamanho].
func _first_override(node: Node) -> Array:
	for child in node.get_children():
		var control := child as Control
		if control != null and control.has_theme_font_size_override("font_size"):
			return [control, control.get_theme_font_size("font_size")]
		var found := _first_override(child)
		if not found.is_empty():
			return found
	return []
