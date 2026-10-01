class_name UiTheme
## Tema dos menus: cores e fontes de cartaz de circo dos anos 30.

const TITLE_FONT := preload("res://core/ui/fonts/Limelight-Regular.ttf")
const BODY_FONT := preload("res://core/ui/fonts/Oswald.ttf")

const INK := Color("1b1410")
const CREAM := Color("f2e6cc")
const GOLD := Color("d9a441")
const RED := Color("a3282a")
const RED_DARK := Color("6e1c1b")
const NIGHT := Color("231a26")
const NIGHT_LIGHT := Color("3a2c3f")


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 30

	theme.set_stylebox("panel", "PanelContainer", _box(NIGHT, GOLD, 4, 18))
	theme.set_stylebox("panel", "Panel", _box(NIGHT, GOLD, 4, 18))

	theme.set_color("font_color", "Label", CREAM)

	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var background := RED_DARK
		match state:
			"hover", "focus":
				background = RED
			"pressed":
				background = Color("4a1312")
		var box := _box(background, GOLD if state in ["hover", "focus"] else INK, 3, 10)
		box.content_margin_left = 18
		box.content_margin_right = 18
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		theme.set_stylebox(state, "Button", box)
		theme.set_stylebox(state, "OptionButton", box)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_color", "OptionButton", CREAM)
	theme.set_color("font_color", "CheckButton", CREAM)
	theme.set_color("font_hover_color", "CheckButton", Color.WHITE)
	theme.set_color("font_focus_color", "CheckButton", Color.WHITE)

	var tab_selected := _box(RED, GOLD, 3, 10)
	var tab_unselected := _box(NIGHT_LIGHT, INK, 3, 10)
	for box in [tab_selected, tab_unselected]:
		box.content_margin_left = 24
		box.content_margin_right = 24
		box.content_margin_top = 6
		box.content_margin_bottom = 6
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_selected)
	theme.set_stylebox("panel", "TabContainer", _box(NIGHT_LIGHT, GOLD, 3, 12))
	theme.set_color("font_selected_color", "TabContainer", Color.WHITE)
	theme.set_color("font_unselected_color", "TabContainer", CREAM)
	theme.set_color("font_hovered_color", "TabContainer", Color.WHITE)

	theme.set_stylebox("popup_panel", "PopupMenu", _box(NIGHT, GOLD, 3, 8))
	theme.set_color("font_color", "PopupMenu", CREAM)
	theme.set_color("font_hover_color", "PopupMenu", GOLD)
	return theme


## Rótulo de título com a fonte de cartaz.
static func title_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 10)
	return label


static func _box(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box
