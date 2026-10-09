extends CanvasLayer
## Tela de fim de luta em forma de cartaz de circo (papel creme, borda vermelha, lâmpadas
## correndo em volta): vitória ou derrota, com "Tentar de novo", "Voltar ao mapa" e "Voltar ao menu".
## Online, só o host pode recomeçar (o cliente recomeça junto).
## Na vitória mostra a nota da dupla (FightGrade) e os ingressos ganhos (SaveGame).

const MAIN_MENU := Levels.MENU

var victory := false
## Nota e recompensas (Fight._victory_result); vazio na derrota.
var result := {}

var _panel: PanelContainer
var _marquee: MarqueeLights


func _ready() -> void:
	add_to_group(&"blocking_ui")
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
	poster.bg_color = UiTheme.NIGHT
	poster.border_color = UiTheme.GOLD
	poster.set_border_width_all(2)
	poster.set_corner_radius_all(4)
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
	_marquee.spacing = 90.0
	root.add_child(_marquee)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	var ribbon := Label.new()
	ribbon.text = "Respeitável Público"
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_theme_font_override("font", UiTheme.TITLE_FONT)
	ribbon.add_theme_font_size_override("font_size", 30)
	ribbon.add_theme_color_override("font_color", UiTheme.INK_SOFT)
	layout.add_child(ribbon)
	var title := UiTheme.title_label("Vitória!" if victory else "Não foi dessa vez...", 84)
	title.add_theme_color_override("font_color", UiTheme.GOLD if victory else UiTheme.CREAM)
	title.add_theme_color_override("font_outline_color", UiTheme.INK)
	title.add_theme_constant_override("outline_size", 2)
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A plateia aplaude de pé!" if victory else "A plateia ainda espera um grande número."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", UiTheme.CREAM)
	subtitle.add_theme_font_size_override("font_size", 30)
	layout.add_child(subtitle)
	if victory and result.get("level", false):
		layout.add_child(_build_level_summary(result))
	elif victory and not result.is_empty():
		layout.add_child(_build_grade(result))

	var first: Button
	if not Network.is_online() or Network.is_host():
		first = _add_button(layout, "Tentar de novo", Network.reload_level)
		_add_button(layout, "Voltar ao mapa", back_to_map)
	else:
		var waiting := Label.new()
		waiting.text = "Esperando o host recomeçar..."
		waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting.add_theme_color_override("font_color", UiTheme.GOLD)
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


## Host (ou sozinho): volta os dois para o mapa do parque.
func back_to_map() -> void:
	Network.change_level(Levels.current_map())


func _back_to_menu() -> void:
	Network.leave()
	get_tree().change_scene_to_file(MAIN_MENU)


## A reação da plateia carimbada ao lado do placar (tempo, vida, números em dupla, truques) e dos ingressos.
## (Até 06/10/2026 o carimbo era a letra da nota; a letra ainda aparece pequena no placar e fica no save.)
func _build_grade(data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	var grade := Label.new()
	grade.text = FightGrade.verdict(String(data.get("grade", "C")))
	grade.add_theme_font_override("font", UiTheme.TITLE_FONT)
	grade.add_theme_font_size_override("font_size", 96)
	grade.add_theme_color_override("font_color", UiTheme.GOLD)
	grade.add_theme_color_override("font_outline_color", UiTheme.INK)
	grade.add_theme_constant_override("outline_size", 14)
	grade.pivot_offset = Vector2(160, 60)
	grade.rotation = -0.12
	row.add_child(grade)
	# O carimbo bate depois do cartaz abrir.
	grade.scale = Vector2(2.5, 2.5)
	grade.modulate.a = 0.0
	var tween := grade.create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(grade, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(grade, "modulate:a", 1.0, 0.15)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 2)
	row.add_child(stats)
	var time: float = data.get("time", 0.0)
	var lines := [
		"Nota da plateia: %s" % String(data.get("grade", "C")),
		"Tempo: %d:%02d%s" % [int(time) / 60, int(time) % 60, "  (recorde!)" if data.get("best_time", false) and not data.get("first_win", false) else ""],
		"Vida restante: %d de %d" % [data.get("health", 0), data.get("max_health", 0)],
	]
	if not data.get("solo", false):
		lines.append("Números em dupla: %d de %d" % [mini(data.get("duo_acts", 0), FightGrade.MAX_DUO_ACTS), FightGrade.MAX_DUO_ACTS])
	var tricks: int = data.get("parries", 0) + data.get("stars_used", 0)
	lines.append("Truques (parries e estrelas): %d de %d" % [mini(tricks, FightGrade.MAX_TRICKS), FightGrade.MAX_TRICKS])
	var tickets: int = data.get("tickets", 0)
	if tickets > 0:
		lines.append("+%d %s para cada um!" % [tickets, "ingresso" if tickets == 1 else "ingressos"])
	elif data.get("best_grade", false):
		lines.append("Nova melhor nota!")
	for text in lines:
		var label := Label.new()
		label.text = text
		label.add_theme_color_override("font_color", UiTheme.GOLD if text.begins_with("+") else UiTheme.CREAM)
		label.add_theme_font_size_override("font_size", 28)
		stats.add_child(label)
	return row


## Fase de plataforma (sem nota): tempo e ingressos escondidos achados.
func _build_level_summary(data: Dictionary) -> Control:
	var stats := VBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	var time: float = data.get("time", 0.0)
	var lines := [
		"Tempo: %d:%02d" % [int(time) / 60, int(time) % 60],
		"Ingressos escondidos: %d de %d" % [data.get("tickets_found", 0), data.get("tickets_total", 0)],
	]
	var tickets: int = data.get("tickets", 0)
	if tickets > 0:
		lines.append("+%d %s para cada um!" % [tickets, "ingresso" if tickets == 1 else "ingressos"])
	for text in lines:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", UiTheme.GOLD if text.begins_with("+") else UiTheme.CREAM)
		label.add_theme_font_size_override("font_size", 30)
		stats.add_child(label)
	return stats

