class_name JugglerAttack
extends BossAttack
## Base dos ataques dos Irmãos Malabaristas: põe todo mundo onde o host disse (args) e cuida
## dos objetos de malabares criados pelo ataque (somem quando ele acaba).
## Cada ataque sobrescreve `_start()`, `_tick(t)`, `_stop()` e `_is_done()`.

var _props: Array[JugglerProp] = []

@onready var boss: JugglersBoss = get_parent().get_parent()


func _on_begin() -> void:
	boss.apply_args(args)
	_clear_props()
	_start()


func _on_tick(_delta: float) -> void:
	_tick(elapsed)


func _on_end() -> void:
	_clear_props()
	_stop()


## Cria um objeto de malabares. `index` identifica o objeto nos dois PCs (parry).
func make_prop(kind: StringName, pink: bool, index: int) -> JugglerProp:
	var prop := JugglerProp.new()
	prop.kind = kind
	prop.pink = pink
	prop.parry_id = "%s:%d:%d" % [name, rng.seed, index]
	add_child(prop)
	_props.append(prop)
	return prop


func _clear_props() -> void:
	for prop in _props:
		if is_instance_valid(prop):
			prop.queue_free()
	_props.clear()


func _start() -> void:
	pass


func _tick(_t: float) -> void:
	pass


func _stop() -> void:
	pass
