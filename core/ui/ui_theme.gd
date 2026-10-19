class_name UiTheme
## Tema dos menus: cartaz de circo dos anos 30 (papel creme, moldura vermelha, tinta escura, dourado).
## Os painéis (PosterPanel) são cartazes com lâmpadas de letreiro; os botões são ingressos de papel que
## ficam vermelhos com borda dourada quando escolhidos. Refeito em 04/10/2026 (o usuário achou os menus
## feios): antes eram caixas roxas escuras.
## Títulos em Rye (letreiro de circo/faroeste) desde 16/10/2026, escolha do usuário nas maquetes do menu; antes Limelight.
## Desde 16/10/2026 (versão B das maquetes) os painéis são um cartaz de papel velho pintado (arte do GPT em
## core/ui/art/poster/, esticado em 9 partes): texto em tinta escura, títulos em vermelho e o item escolhido
## em vermelho com a luva apontando (PosterPanel).

const TITLE_FONT := preload("res://core/ui/fonts/Rye-Regular.ttf")
const BODY_FONT := preload("res://core/ui/fonts/SpecialElite-Regular.ttf")
## A Special Elite (máquina de escrever, escolha do usuário em 16/10/2026) é ~45% mais larga que a Oswald
## que ela substituiu; todo tamanho de texto do corpo passa por body_size() para ocupar a mesma largura.
const BODY_SCALE := 0.72

const INK := Color("101923")
const INK_SOFT := Color("95a7aa")
const CREAM := Color("e8dac0")
## Papel mais escuro: botões e cartões dentro do cartaz.
const PAPER_SHADE := Color("25424c")
const GOLD := Color("dfbc7d")
const RED := Color("792f40")
const RED_DARK := Color("542738")
const NIGHT := Color("101d28")
const NIGHT_LIGHT := Color("20333d")
## Cores para usar EM CIMA do papel do cartaz.
const PAPER_INK := Color("2b1b12")
const PAPER_INK_SOFT := Color("6e5843")
const PAPER_RED := Color("9a1d23")
const POSTER_TALL := preload("res://core/ui/art/poster/poster_portrait.png")
const POSTER_WIDE := preload("res://core/ui/art/poster/poster_landscape.png")
const POINTING_HAND := preload("res://core/ui/art/poster/pointing_hand.png")
## Cantos do cartaz que não esticam (enfeites e moldura) e a margem do conteúdo, em pixels da tela.
const POSTER_CORNER := 116.0
const POSTER_PADDING := Vector2(100, 82)
static var _cached_theme: Theme
## Tamanho da interface com que o tema guardado foi montado (muda nas Configurações).
static var _cached_scale := 0.0
## Tamanho da interface com que os menus já abertos estão desenhados (-1: nenhum ainda), ver apply_live.
static var _live_scale := -1.0
## Marca (meta) dos controles cuja altura mínima segue o tamanho da interface (UiTheme.scaled).
const SCALED_HEIGHT_META := &"ui_scaled_height"
const BASE_SIZES_META := &"ui_base_font_sizes"


## "Tamanho da interface" das Configurações (pedido do usuário em 19/10/2026: no celular tudo ficava pequeno
## para o dedo). Multiplica os textos e as alturas dos botões dos menus; o jogo em si não muda de tamanho.
static func ui_scale() -> float:
	return Settings.UI_SCALES[Settings.ui_scale_index]


## Medida (pixels) já no tamanho da interface escolhido.
static func scaled(value: float) -> float:
	return value * ui_scale()


static func build() -> Theme:
	if _live_scale < 0.0:
		_live_scale = ui_scale()
	if _cached_theme != null and is_equal_approx(_cached_scale, ui_scale()):
		return _cached_theme
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = body_size(30)

	theme.set_stylebox("panel", "PanelContainer", poster_box())
	theme.set_stylebox("panel", "Panel", poster_box())
	theme.set_color("font_color", "Label", PAPER_INK)

	# Botões: moldura de tinta fina no papel; escolhido (foco ou mouse) fica vermelho, apertado vira
	# vermelho cheio.
	for type in ["Button", "OptionButton", "CheckButton", "MenuButton"]:
		theme.set_stylebox("normal", type, _ticket(Color(PAPER_INK, 0.05), Color(PAPER_INK, 0.38), 2))
		theme.set_stylebox("hover", type, _ticket(Color(PAPER_RED, 0.12), PAPER_RED, 3))
		theme.set_stylebox("focus", type, _box(Color(PAPER_RED, 0.12), PAPER_RED, 3, 3))
		theme.set_stylebox("hover_pressed", type, _ticket(PAPER_RED, RED_DARK, 3, true))
		theme.set_stylebox("pressed", type, _ticket(PAPER_RED, RED_DARK, 3, true))
		var disabled := _ticket(Color(0, 0, 0, 0), Color(PAPER_INK, 0.15), 2)
		disabled.shadow_color = Color(0, 0, 0, 0)
		theme.set_stylebox("disabled", type, disabled)
		theme.set_color("font_color", type, PAPER_INK)
		theme.set_color("font_hover_color", type, PAPER_RED)
		theme.set_color("font_focus_color", type, PAPER_RED)
		theme.set_color("font_pressed_color", type, CREAM)
		theme.set_color("font_hover_pressed_color", type, CREAM)
		theme.set_color("font_disabled_color", type, Color(PAPER_INK, 0.35))
		theme.set_color("icon_normal_color", type, PAPER_INK)
		theme.set_color("icon_focus_color", type, PAPER_RED)
		theme.set_color("icon_hover_color", type, PAPER_RED)
	# A chave do CheckButton fica num ingresso só quando escolhida (normal: sem caixa).
	var plain := StyleBoxEmpty.new()
	plain.content_margin_left = 12
	plain.content_margin_right = 12
	plain.content_margin_top = 6
	plain.content_margin_bottom = 6
	theme.set_stylebox("normal", "CheckButton", plain)
	theme.set_stylebox("pressed", "CheckButton", plain)
	theme.set_stylebox("hover_pressed", "CheckButton", _ticket(Color(PAPER_RED, 0.12), PAPER_RED, 3))
	theme.set_color("font_pressed_color", "CheckButton", PAPER_INK)
	theme.set_color("font_hover_pressed_color", "CheckButton", PAPER_RED)
	theme.set_icon("checked", "CheckButton", _switch(true))
	theme.set_icon("unchecked", "CheckButton", _switch(false))

	var field := _box(Color(PAPER_INK, 0.07), Color(PAPER_INK, 0.45), 2, 3)
	field.content_margin_top = 8
	field.content_margin_bottom = 8
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), PAPER_RED, 3, 3, false))
	theme.set_color("font_color", "LineEdit", PAPER_INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color(PAPER_INK_SOFT, 0.8))
	theme.set_color("caret_color", "LineEdit", PAPER_RED)
	theme.set_color("selection_color", "LineEdit", Color(PAPER_RED, 0.3))

	var tab_selected := _box(PAPER_RED, RED_DARK, 1, 3)
	var tab_unselected := _box(Color(PAPER_INK, 0.07), Color(PAPER_INK, 0.3), 1, 3)
	var tab_hovered := _box(Color(PAPER_RED, 0.12), PAPER_RED, 1, 3)
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
	theme.set_stylebox("tab_focus", "TabContainer", _box(Color(0, 0, 0, 0), PAPER_RED, 3, 4, false))
	theme.set_stylebox("panel", "TabContainer", card_box())
	theme.set_font("font", "TabContainer", TITLE_FONT)
	theme.set_font_size("font_size", "TabContainer", roundi(scaled(26)))
	theme.set_color("font_selected_color", "TabContainer", CREAM)
	theme.set_color("font_unselected_color", "TabContainer", PAPER_INK_SOFT)
	theme.set_color("font_hovered_color", "TabContainer", PAPER_RED)

	var popup := _box(Color("efe1bf"), PAPER_RED, 2, 3)
	popup.content_margin_top = 8
	popup.content_margin_bottom = 8
	popup.content_margin_left = 8
	popup.content_margin_right = 8
	theme.set_stylebox("panel", "PopupMenu", popup)
	theme.set_stylebox("hover", "PopupMenu", _box(PAPER_RED, RED_DARK, 1, 3))
	theme.set_color("font_color", "PopupMenu", PAPER_INK)
	theme.set_color("font_hover_color", "PopupMenu", CREAM)
	theme.set_color("font_disabled_color", "PopupMenu", Color(PAPER_INK, 0.4))

	for bar in ["VScrollBar", "HScrollBar"]:
		var track := _box(Color(PAPER_INK, 0.1), Color(0, 0, 0, 0), 0, 6)
		track.set_content_margin_all(4)
		theme.set_stylebox("scroll", bar, track)
		theme.set_stylebox("grabber", bar, _box(RED_DARK, INK, 2, 6))
		theme.set_stylebox("grabber_highlight", bar, _box(RED, GOLD, 2, 6))
		theme.set_stylebox("grabber_pressed", bar, _box(RED, GOLD, 2, 6))

	var line := StyleBoxLine.new()
	line.color = Color(PAPER_INK, 0.3)
	line.thickness = 2
	theme.set_stylebox("separator", "HSeparator", line)

	theme.set_color("default_color", "RichTextLabel", PAPER_INK)
	theme.set_font("normal_font", "RichTextLabel", BODY_FONT)
	var bold := FontVariation.new()
	bold.base_font = BODY_FONT
	bold.variation_embolden = 0.9
	theme.set_font("bold_font", "RichTextLabel", bold)
	theme.set_font_size("normal_font_size", "RichTextLabel", body_size(27))
	theme.set_font_size("bold_font_size", "RichTextLabel", body_size(27))
	_cached_theme = theme
	_cached_scale = ui_scale()
	return theme


## Tamanho de um texto na fonte do corpo, a partir do tamanho que ele tinha com a Oswald.
static func body_size(oswald_size: float) -> int:
	return maxi(roundi(oswald_size * BODY_SCALE * ui_scale()), 1)


## Aplica na hora o tamanho da interface escolhido a tudo que já está na tela (pedido do usuário em 19/10/2026:
## antes só valia ao abrir o jogo de novo). Troca o tema e refaz os tamanhos de texto e as alturas marcadas
## com SCALED_HEIGHT_META, a partir do tamanho original de cada um (trocar várias vezes não acumula erro).
static func apply_live(root: Node) -> void:
	var old := _live_scale
	if old < 0.0 or is_equal_approx(old, ui_scale()):
		_live_scale = ui_scale()
		return
	var old_theme := _cached_theme
	var new_theme := build()
	_live_scale = ui_scale()
	_rescale(root, old, old_theme, new_theme)


static func _rescale(node: Node, old: float, old_theme: Theme, new_theme: Theme) -> void:
	var control := node as Control
	if control != null:
		if old_theme != null and control.theme == old_theme:
			control.theme = new_theme
		# Tamanho original de cada texto e o valor que demos da última vez: se o código trocou o tamanho
		# depois disso, o original é recalculado a partir do novo.
		var base: Dictionary = control.get_meta(BASE_SIZES_META, {})
		for property in control.get_property_list():
			var key: String = property.name
			# A lista traz todas as sobreposições possíveis; só contam as que têm valor.
			if not key.begins_with("theme_override_font_sizes/") or control.get(key) == null:
				continue
			var current: int = control.get(key)
			if not base.has(key) or base[key][1] != current:
				base[key] = [current / old, current]
			var size := maxi(roundi(base[key][0] * ui_scale()), 1)
			control.set(key, size)
			base[key][1] = size
		if not base.is_empty():
			control.set_meta(BASE_SIZES_META, base)
		if control.has_meta(SCALED_HEIGHT_META):
			control.custom_minimum_size.y = scaled(control.get_meta(SCALED_HEIGHT_META))
	for child in node.get_children(true):
		_rescale(child, old, old_theme, new_theme)


## O cartaz de papel velho (arte do GPT), esticado em 9 partes: os cantos com os enfeites não esticam.
## `tall`: o cartaz em pé (painéis mais altos que largos); senão, o deitado.
static func poster_box(tall := false) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = POSTER_TALL if tall else POSTER_WIDE
	box.set_texture_margin_all(POSTER_CORNER)
	box.content_margin_left = POSTER_PADDING.x
	box.content_margin_right = POSTER_PADDING.x
	box.content_margin_top = POSTER_PADDING.y
	box.content_margin_bottom = POSTER_PADDING.y
	return box


## Cartão dentro do cartaz (papel um pouco mais escuro, contorno de tinta fina): detalhes, colunas, abas.
static func card_box() -> StyleBoxFlat:
	var box := _box(Color(PAPER_INK, 0.06), Color(PAPER_INK, 0.28), 1, 3)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box


## Título de cartaz (letra de letreiro). `on_dark`: em cima do jogo (dourado com contorno de tinta);
## senão, no papel do cartaz (vermelho, sem contorno).
static func title_label(text: String, size: int, on_dark := false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", roundi(scaled(size)))
	label.add_theme_color_override("font_color", GOLD if on_dark else PAPER_RED)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 3 if on_dark else 0)
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


## Rótulo pequeno de seção (letra de letreiro): tinta no papel do cartaz, dourado em cima do jogo.
static func section_label(text: String, size := 28, on_dark := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", roundi(scaled(size)))
	label.add_theme_color_override("font_color", GOLD if on_dark else PAPER_INK)
	return label


## Cabeçalho de seção: título e instrução legíveis, sem faixa competindo com os controles.
static func page_header(text: String, subtitle: String) -> VBoxContainer:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	var title := title_label(text, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(title)
	var hint := Label.new()
	hint.text = subtitle
	hint.add_theme_font_size_override("font_size", body_size(23))
	hint.add_theme_color_override("font_color", PAPER_INK_SOFT)
	header.add_child(hint)
	header.add_child(HSeparator.new())
	return header


static func portrait(kind: String, height := 160.0) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load("res://core/player/characters/%s/idle/idle_1.png" % kind)
	image.custom_minimum_size = Vector2(height * 0.7, height)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


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
	var body := PAPER_RED if on else Color("d9c59c")
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
				color = GOLD if on else Color("f6ead0")
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


## Botão que fica em cima do cenário escuro, fora do cartaz (ex.: "Verificar atualização" no menu): os botões
## do tema são tinta sobre papel e somem no escuro (relato do usuário em 19/10/2026).
static func dark_button(button: Button) -> void:
	var normal := _ticket(Color(NIGHT, 0.88), GOLD, 2)
	var lit := _ticket(Color(RED_DARK, 0.95), GOLD, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", lit)
	button.add_theme_stylebox_override("focus", _box(Color(RED_DARK, 0.6), GOLD, 3, 3))
	button.add_theme_stylebox_override("pressed", _ticket(PAPER_RED, GOLD, 3, true))
	button.add_theme_stylebox_override("hover_pressed", _ticket(PAPER_RED, GOLD, 3, true))
	button.add_theme_stylebox_override("disabled", _ticket(Color(NIGHT, 0.7), Color(GOLD, 0.45), 2))
	for state in ["font_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color(CREAM, 0.6))


## Ingresso de papel (botões): contorno, cantos arredondados e uma sombra de tinta embaixo, que
## some quando apertado (o botão "afunda").
static func _ticket(background: Color, border: Color, border_width: int, sunk := false) -> StyleBoxFlat:
	var box := _box(background, border, border_width, 3)
	box.shadow_color = Color(PAPER_INK, 0.25)
	box.shadow_size = 1
	box.shadow_offset = Vector2(0, 1 if sunk else 3)
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
