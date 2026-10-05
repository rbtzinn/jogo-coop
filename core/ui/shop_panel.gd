class_name ShopPanel
extends CanvasLayer
## Barraca de Curiosidades: a loja, aberta só na tela de quem entrou (docs/shop.md).
## Prateleira com os itens de cada espaço, detalhes do item escolhido, comprar (com
## confirmação), dar ingressos ao parceiro e sair. Quem decide as compras é o Shop (host).
## Enquanto a loja está aberta, os personagens deste PC não se mexem (grupo "blocking_ui").

const INK := Color("1b1410")

var key := "clown"
var player: Node

var _selected := ""
var _confirming := false
var _line: Label
var _tickets: Label
var _shelf: VBoxContainer
var _name: Label
var _details: RichTextLabel
var _buy: Button
var _gift_amount: SpinBox
var _gift: Button
var _first_button: Button


static func open_for(player_key: String, who: Node) -> ShopPanel:
	var tree := Engine.get_main_loop() as SceneTree
	var panel := ShopPanel.new()
	panel.key = player_key
	panel.player = who
	tree.current_scene.add_child(panel)
	return panel


func _ready() -> void:
	layer = 19
	add_to_group(&"blocking_ui")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.build()
	add_child(root)
	UiTheme.backdrop(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PosterPanel.new()
	panel.custom_minimum_size = Vector2(1560, 900)
	panel.star_min_width = 100000.0
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	layout.add_child(UiTheme.banner("Barraca de Curiosidades", 50))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 30)
	layout.add_child(top)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.add_theme_color_override("font_color", UiTheme.RED_DARK)
	_line.add_theme_font_size_override("font_size", 27)
	top.add_child(_line)
	_tickets = UiTheme.title_label("", 30)
	_tickets.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_tickets)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 30)
	layout.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_shelf = VBoxContainer.new()
	_shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shelf.add_theme_constant_override("separation", 8)
	scroll.add_child(_shelf)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.card_box())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(card)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 14)
	card.add_child(info)
	_name = UiTheme.title_label("", 44)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_name)
	info.add_child(HSeparator.new())
	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.fit_content = true
	_details.scroll_active = false
	_details.custom_minimum_size = Vector2(620, 0)
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(_details)
	_buy = Button.new()
	_buy.pressed.connect(_on_buy_pressed)
	info.add_child(_buy)

	var gift_row := HBoxContainer.new()
	gift_row.add_theme_constant_override("separation", 14)
	layout.add_child(gift_row)
	var gift_label := Label.new()
	gift_label.text = "Dar ingressos ao parceiro:"
	gift_row.add_child(gift_label)
	_gift_amount = SpinBox.new()
	_gift_amount.min_value = 1
	gift_row.add_child(_gift_amount)
	_gift = Button.new()
	_gift.text = "Dar"
	_gift.pressed.connect(func() -> void: Shop.gift(key, int(_gift_amount.value)))
	gift_row.add_child(_gift)
	var close_button := Button.new()
	close_button.text = "Sair da barraca"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	close_button.pressed.connect(close)
	gift_row.add_child(close_button)

	_line.text = "%s: \"%s\"" % [Catalog.shopkeeper_name(), Catalog.line("boas_vindas")]
	SaveGame.changed.connect(_refresh)
	Shop.done.connect(_on_shop_done)
	_build_shelf()
	_refresh()
	if _first_button != null:
		_first_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	if is_queued_for_deletion():
		return
	remove_from_group(&"blocking_ui")
	queue_free()


func _build_shelf() -> void:
	for slot: String in Catalog.SLOTS:
		_shelf.add_child(UiTheme.section_label(Catalog.SLOT_NAMES[slot]))
		for item_id in Catalog.ids_for_slot(slot):
			var button := Button.new()
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(0, 54)
			button.set_meta(&"item", item_id)
			button.focus_entered.connect(_select.bind(item_id))
			button.pressed.connect(_select.bind(item_id))
			# Preço num canhoto de ingresso dourado, à direita (lê bem no papel e no vermelho).
			var price := Label.new()
			price.name = "Price"
			price.add_theme_font_size_override("font_size", 24)
			price.mouse_filter = Control.MOUSE_FILTER_IGNORE
			price.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			price.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			price.grow_vertical = Control.GROW_DIRECTION_BOTH
			price.offset_right = -12
			button.add_child(price)
			_shelf.add_child(button)
			if _first_button == null:
				_first_button = button
				_selected = item_id


func _select(item_id: String) -> void:
	_selected = item_id
	_confirming = false
	_refresh()


func _refresh() -> void:
	var tickets := Shop.tickets(key)
	_tickets.text = "Seus ingressos: %d" % tickets
	_gift_amount.max_value = maxi(tickets, 1)
	_gift.disabled = tickets <= 0
	for button in _shelf.get_children():
		if not button is Button:
			continue
		var item_id: String = button.get_meta(&"item")
		var item := Catalog.item(item_id)
		var owned := Shop.owns(key, item_id)
		button.text = item.name
		var price: Label = button.get_node("Price")
		price.text = "já é seu" if owned else ("%d ingresso" % item.price if item.price == 1 else "%d ingressos" % item.price)
		var stub := StyleBoxFlat.new()
		stub.bg_color = UiTheme.PAPER_SHADE if owned else UiTheme.GOLD
		stub.border_color = UiTheme.INK
		stub.set_border_width_all(2)
		stub.set_corner_radius_all(6)
		stub.content_margin_left = 12
		stub.content_margin_right = 12
		price.add_theme_stylebox_override("normal", stub)
		price.add_theme_color_override("font_color", UiTheme.INK_SOFT if owned else UiTheme.INK)
	var item := Catalog.item(_selected)
	if item.is_empty():
		return
	_name.text = item.name
	var text: String = item.description
	if item.has("ex"):
		text += "\n\n[b][color=#6e1c1b]Tiro EX:[/color][/b] " + item.ex
	if item.has("downside"):
		text += "\n\n[b][color=#6e1c1b]Troca:[/color][/b] " + item.downside
	_details.text = text
	if Shop.owns(key, _selected):
		_buy.text = "Já é seu"
		_buy.disabled = true
	elif _confirming:
		_buy.text = "Levar por %d ingressos? (aperte de novo)" % item.price
		_buy.disabled = false
	else:
		_buy.text = "Comprar por %d ingressos" % item.price
		_buy.disabled = false


func _on_buy_pressed() -> void:
	if not _confirming:
		_confirming = true
		_refresh()
		return
	_confirming = false
	Shop.buy(key, _selected)


func _on_shop_done(operation: String, ok: bool, message: String) -> void:
	var kind := "compra" if operation == "buy" else "doacao"
	if not ok:
		kind = message if message in ["sem_ingressos", "ja_tem"] else "sem_ingressos"
	_line.text = "%s: \"%s\"" % [Catalog.shopkeeper_name(), Catalog.line(kind)]
	_refresh()
