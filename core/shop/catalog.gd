class_name Catalog
## Itens da loja (docs/shop.md), lidos de dialogues/items.json (nome, espaço, preço,
## descrição, Tiro EX e o lado ruim). E as falas do lojista, de dialogues/lojista.json.

const ITEMS_PATH := "res://dialogues/items.json"
const LINES_PATH := "res://dialogues/lojista.json"
## Os quatro espaços de equipamento, na ordem do Camarim.
const SLOTS := ["gun", "trick", "prop", "duo"]
const SLOT_NAMES := {"gun": "Pistola", "trick": "Truque", "prop": "Adereço", "duo": "Número de dupla"}
## Espaços que podem ficar vazios.
const OPTIONAL_SLOTS := ["prop", "duo"]

static var _items := {}
static var _lines := {}


static func items() -> Dictionary:
	if _items.is_empty():
		_items = _load(ITEMS_PATH)
	return _items


static func item(item_id: String) -> Dictionary:
	return items().get(item_id, {})


## Ids dos itens de um espaço, mais baratos primeiro.
static func ids_for_slot(slot: String) -> Array[String]:
	var result: Array[String] = []
	for item_id: String in items():
		if items()[item_id].slot == slot:
			result.append(item_id)
	result.sort_custom(func(a: String, b: String) -> bool: return items()[a].price < items()[b].price)
	return result


## Uma fala do lojista do tipo pedido ("boas_vindas", "compra"...), escolhida ao acaso.
static func line(kind: String) -> String:
	if _lines.is_empty():
		_lines = _load(LINES_PATH)
	var options: Array = _lines.get(kind, [""])
	return options[randi() % options.size()]


static func shopkeeper_name() -> String:
	if _lines.is_empty():
		_lines = _load(LINES_PATH)
	return _lines.get("nome", "Lojista")


static func _load(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Não achei %s" % path)
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}
