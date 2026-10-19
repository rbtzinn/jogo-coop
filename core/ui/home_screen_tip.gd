class_name HomeScreenTip
extends Control
## Aviso do menu no Safari do iPhone: a Apple não deixa site nenhum ficar em tela cheia no iPhone, então o jogo
## explica como pôr o ícone na Tela de Início (aberto por ele, some a barra do Safari). Só aparece na primeira
## vez, e nunca quando o jogo já foi aberto pelo ícone (pedido do usuário em 19/10/2026).

signal closed


## Deve aparecer agora?
static func wanted() -> bool:
	return Device.is_ios_web() and not Device.is_installed_web_app() and not Settings.home_screen_tip_seen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var poster := PosterPanel.new()
	poster.custom_minimum_size = Vector2(1080, 0)
	center.add_child(poster)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	poster.add_child(layout)
	layout.add_child(UiTheme.title_label("Tela cheia no iPhone", 54))
	var steps := Label.new()
	steps.text = "O Safari não deixa jogo nenhum ocupar a tela toda. Para jogar sem as barras do navegador:\n\n" \
		+ "1. Toque em Compartilhar (o quadrado com a seta para cima).\n" \
		+ "2. Escolha \"Adicionar à Tela de Início\".\n" \
		+ "3. Abra o jogo pelo ícone do palhaço.\n\n" \
		+ "Atenção: pelo ícone o jogo tem um save próprio, separado do Safari."
	steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	steps.custom_minimum_size = Vector2(960, 0)
	steps.add_theme_font_size_override("font_size", UiTheme.body_size(30))
	steps.add_theme_color_override("font_color", UiTheme.PAPER_INK)
	layout.add_child(steps)
	var ok := Button.new()
	ok.text = "Entendi"
	ok.custom_minimum_size = Vector2(320, 84)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close)
	layout.add_child(ok)
	ok.grab_focus.call_deferred()


func _close() -> void:
	Settings.mark_home_screen_tip_seen()
	closed.emit()
	queue_free()
