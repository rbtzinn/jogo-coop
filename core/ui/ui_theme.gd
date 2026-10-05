class_name UiTheme
## Tema dos menus: cartaz de circo dos anos 30 (papel creme, moldura vermelha, tinta escura, dourado).
## Os painéis (PosterPanel) são cartazes com lâmpadas de letreiro; os botões são ingressos de papel que
## ficam vermelhos com borda dourada quando escolhidos. Refeito em 04/10/2026 (o usuário achou os menus
## feios): antes eram caixas roxas escuras.

const TITLE_FONT := preload("res://core/ui/fonts/Limelight-Regular.ttf")
const BODY_FONT := preload("res://core/ui/fonts/Oswald.ttf")

const INK := Color("101923")
const INK_SOFT := Color("95a7aa")
const CREAM := Color("e8dac0")
## Papel mais escuro: botões e cartões dentro do cartaz.
const PAPER_SHADE := Color("25424c")
const GOLD := Color("dfbc7d")
const RED := Color("792f40")
const RED_DARK := Color("cfb17c")
const NIGHT := Color("101d28")
const NIGHT_LIGHT := Color("20333d")
static var _cached_theme: Theme


static func build() -> Theme:
	if _cached_theme != null:
		return _cached_theme
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 30

	theme.set_stylebox("panel", "PanelContainer", poster_box())
	theme.set_stylebox("panel", "Panel", poster_box())
	theme.set_color("font_color", "Label", CREAM)

	# Botões: ingresso de papel; escolhido (foco ou mouse) fica vermelho com borda dourada.
	for type in ["Button", "OptionButton", "CheckButton", "MenuButton"]:
		theme.set_stylebox("normal", type, _ticket(PAPER_SHADE, Color("58717a"), 1))
		theme.set_stylebox("hover", type, _ticket(RED, GOLD, 4))
		theme.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), GOLD, 2, 3, false))
		theme.set_stylebox("hover_pressed", type, _ticket(RED_DARK, GOLD, 4, true))
		theme.set_stylebox("pressed", type, _ticket(RED_DARK, GOLD, 4, true))
		var disabled := _ticket(Color(PAPER_SHADE, 0.55), Color(INK_SOFT, 0.5), 3)
		disabled.shadow_color = Color(0, 0, 0, 0)
		theme.set_stylebox("disabled", type, disabled)
		theme.set_color("font_color", type, CREAM)
		theme.set_color("font_hover_color", type, CREAM)
		theme.set_color("font_focus_color", type, CREAM)
		theme.set_color("font_pressed_color", type, GOLD)
		theme.set_color("font_hover_pressed_color", type, GOLD)
		theme.set_color("font_disabled_color", type, Color(INK_SOFT, 0.6))
		theme.set_color("icon_normal_color", type, CREAM)
		theme.set_color("icon_focus_color", type, CREAM)
		theme.set_color("icon_hover_color", type, CREAM)
	# A chave do CheckButton fica num ingresso só quando escolhida (normal: sem caixa).
	var plain := StyleBoxEmpty.new()
	plain.content_margin_left = 12
	plain.content_margin_right = 12
	plain.content_margin_top = 6
	plain.content_margin_bottom = 6
	theme.set_stylebox("normal", "CheckButton", plain)
	theme.set_stylebox("pressed", "CheckButton", plain)
	theme.set_stylebox("hover_pressed", "CheckButton", _ticket(RED, GOLD, 4))
	theme.set_color("font_pressed_color", "CheckButton", CREAM)
	theme.set_icon("checked", "CheckButton", _switch(true))
	theme.set_icon("unchecked", "CheckButton", _switch(false))

	var field := _box(NIGHT, Color("58717a"), 1, 3)
	field.content_margin_top = 8
	field.content_margin_bottom = 8
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), GOLD, 4, 8, false))
	theme.set_color("font_color", "LineEdit", CREAM)
	theme.set_color("font_placeholder_color", "LineEdit", Color(INK_SOFT, 0.75))
	theme.set_color("caret_color", "LineEdit", RED)
	theme.set_color("selection_color", "LineEdit", Color(GOLD, 0.5))

	var tab_selected := _box(RED, GOLD, 1, 3)
	var tab_unselected := _box(NIGHT, Color("58717a"), 1, 3)
	var tab_hovered := _box(PAPER_SHADE, GOLD, 1, 3)
	for box: StyleBoxFlat in [tab_selected, tab_unselected, tab_hovered]:
		box.corner_radius_bottom_left = 0
		box.corner_radius_bottom_right = 0
		box.content_margin_left = 26
		box.content_margin_right = 26
		box.content_margin_top = 6
		box.content_margin_bottom = 6
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_hovered)
	theme.set_stylebox("tab_focus", "TabContainer", _box(Color(0, 0, 0, 0), GOLD, 4, 10, false))
	theme.set_stylebox("panel", "TabContainer", card_box())
	theme.set_font("font", "TabContainer", TITLE_FONT)
	theme.set_font_size("font_size", "TabContainer", 26)
	theme.set_color("font_selected_color", "TabContainer", CREAM)
	theme.set_color("font_unselected_color", "TabContainer", INK_SOFT)
	theme.set_color("font_hovered_color", "TabContainer", CREAM)

	var popup := _box(NIGHT, GOLD, 1, 3)
	popup.content_margin_top = 8
	popup.content_margin_bottom = 8
	popup.content_margin_left = 8
	popup.content_margin_right = 8
	theme.set_stylebox("panel", "PopupMenu", popup)
	theme.set_stylebox("hover", "PopupMenu", _box(RED, GOLD, 2, 6))
	theme.set_color("font_color", "PopupMenu", CREAM)
	theme.set_color("font_hover_color", "PopupMenu", CREAM)
	theme.set_color("font_disabled_color", "PopupMenu", INK_SOFT)

	for bar in ["VScrollBar", "HScrollBar"]:
		var track := _box(Color(INK, 0.12), Color(0, 0, 0, 0), 0, 6)
		track.set_content_margin_all(4)
		theme.set_stylebox("scroll", bar, track)
		theme.set_stylebox("grabber", bar, _box(RED_DARK, INK, 2, 6))
		theme.set_stylebox("grabber_highlight", bar, _box(RED, GOLD, 2, 6))
		theme.set_stylebox("grabber_pressed", bar, _box(RED, GOLD, 2, 6))

	var line := StyleBoxLine.new()
	line.color = Color(INK_SOFT, 0.6)
	line.thickness = 2
	theme.set_stylebox("separator", "HSeparator", line)

	theme.set_color("default_color", "RichTextLabel", CREAM)
	theme.set_font("normal_font", "RichTextLabel", BODY_FONT)
	var bold := FontVariation.new()
	bold.base_font = BODY_FONT
	bold.variation_embolden = 0.9
	theme.set_font("bold_font", "RichTextLabel", bold)
	theme.set_font_size("normal_font_size", "RichTextLabel", 27)
	theme.set_font_size("bold_font_size", "RichTextLabel", 27)
	_cached_theme = theme
	return theme


## O cartaz: papel creme, moldura vermelha grossa, cantos arredondados e sombra.
static func poster_box() -> StyleBoxFlat:
	var box := _box(Color(NIGHT, 0.98), Color("8f7045"), 2, 4)
	box.shadow_color = Color(0, 0, 0, 0.55)
	box.shadow_size = 16
	box.shadow_offset = Vector2(0, 10)
	box.content_margin_left = 38
	box.content_margin_right = 38
	box.content_margin_top = 30
	box.content_margin_bottom = 30
	return box


## Cartão dentro do cartaz (papel mais escuro, contorno de tinta): detalhes, colunas, abas.
static func card_box() -> StyleBoxFlat:
	var box := _box(NIGHT_LIGHT, Color("4b6269"), 1, 3)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box


## Título de cartaz (letra de letreiro). `on_dark`: em cima do jogo (dourado com contorno de tinta);
## senão, no papel (vermelho com contorno dourado, como o "Vitória!").
static func title_label(text: String, size: int, on_dark := false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 3 if on_dark else 2)
	return label


## Fita vermelha de circo com o título (a mesma dos letreiros da luta), do tamanho do texto.
static func banner(text: String, size: int) -> CircusBanner:
	var ribbon := CircusBanner.new()
	ribbon.text = text
	ribbon.font_size = size
	var width := TITLE_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ribbon.custom_minimum_size = Vector2(width + 300.0, size * 1.24 + 60.0)
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return ribbon


## Rótulo pequeno de seção (tinta, letra de letreiro).
static func section_label(text: String, size := 28) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", RED_DARK)
	return label


## Fundo escuro atrás de um menu aberto por cima do jogo: escurece e fecha nas bordas (vinheta).
static func backdrop(parent: Control) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.05, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(dim)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0, 0, 0, 0.75))
	gradient.set_offset(0, 0.35)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vignette)


## Chave liga/desliga (CheckButton): pílula de tinta com bolinha; ligada é vermelha com a bolinha
## dourada à direita, desligada é papel com a bolinha à esquerda.
static func _switch(on: bool) -> ImageTexture:
	var w := 76
	var h := 40
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var body := RED if on else PAPER_SHADE
	var knob_x := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var c := Vector2(clampf(p.x, h / 2.0, w - h / 2.0), h / 2.0)
			var d := p.distance_to(c)
			var color := Color(0, 0, 0, 0)
			if d <= h / 2.0:
				color = INK
			if d <= h / 2.0 - 3.0:
				color = body
			var k := p.distance_to(Vector2(knob_x, h / 2.0))
			if k <= h / 2.0 - 5.0:
				color = INK
			if k <= h / 2.0 - 8.0:
				color = GOLD if on else CREAM
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


## Ingresso de papel (botões): contorno, cantos arredondados e uma sombra de tinta embaixo, que
## some quando apertado (o botão "afunda").
static func _ticket(background: Color, border: Color, border_width: int, sunk := false) -> StyleBoxFlat:
	var box := _box(background, border, border_width, 3)
	box.shadow_color = Color(INK, 0.85)
	box.shadow_size = 1
	box.shadow_offset = Vector2(0, 1 if sunk else 4)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 12 + (2 if sunk else 0)
	box.content_margin_bottom = 12 - (2 if sunk else 0)
	return box


static func _box(background: Color, border: Color, border_width: int, radius: int, filled := true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.draw_center = filled
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box
