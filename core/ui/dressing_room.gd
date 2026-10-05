class_name DressingRoom
extends PosterPanel
## Camarim: escolher o equipamento de cada personagem deste PC (Pistola, Truque, Adereço e
## Número de dupla) entre os itens comprados. Abre pelo menu de pausa, só no mapa (docs/shop.md).
## Quem muda o save é o Shop (o host confere).

signal closed

var _columns: HBoxContainer
var _first: Control


func _ready() -> void:
	super()
	theme = UiTheme.build()
	custom_minimum_size = Vector2(1300, 760)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)
	layout.add_child(UiTheme.banner("Camarim", 56))
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 60)
	_columns.alignment = BoxContainer.ALIGNMENT_CENTER
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_columns)
	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(320, 0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	layout.add_child(back)
	SaveGame.changed.connect(func() -> void:
		if visible:
			_rebuild())


func open() -> void:
	show()
	_rebuild()
	if _first != null:
		_first.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	for child in _columns.get_children():
		child.queue_free()
	_first = null
	for key in Shop.local_keys():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiTheme.card_box())
		_columns.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		card.add_child(column)
		var title := UiTheme.title_label("Palhaço" if key == "clown" else "Acrobata", 40)
		column.add_child(title)
		var tickets := Label.new()
		tickets.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tickets.text = "Ingressos: %d" % Shop.tickets(key)
		column.add_child(tickets)
		for slot: String in Catalog.SLOTS:
			var label := UiTheme.section_label(Catalog.SLOT_NAMES[slot], 24)
			column.add_child(label)
			var choice := OptionButton.new()
			choice.custom_minimum_size = Vector2(460, 0)
			var options: Array[String] = []
			if slot in Catalog.OPTIONAL_SLOTS:
				options.append("")
			for item_id in Catalog.ids_for_slot(slot):
				if Shop.owns(key, item_id):
					options.append(item_id)
			for item_id in options:
				choice.add_item("—" if item_id.is_empty() else Catalog.item(item_id).name)
			choice.select(maxi(options.find(Shop.equipped(key, slot)), 0))
			choice.item_selected.connect(func(index: int) -> void: Shop.equip(key, slot, options[index]))
			column.add_child(choice)
			if _first == null:
				_first = choice
