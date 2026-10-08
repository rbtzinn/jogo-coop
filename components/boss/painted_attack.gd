class_name PaintedAttack
extends BossAttack
## Objetos e avisos de uma linha do tempo determinística; limpeza também em troca de fase.
var boss
var actor: PaintedBossActor
var _props := {}
var _marks := {}


func _ready() -> void:
	boss = get_parent().get_parent()
	actor = boss.get_node("Actor")


func _on_begin() -> void:
	_props.clear()
	_marks.clear()
	_start()
	_tick(0.0)


func _on_tick(_delta: float) -> void:
	_tick(elapsed)


func prop(key: String, kind: StringName, at: Vector2, pink := false, container: Node = null) -> PaintedProp:
	if not _props.has(key):
		var node := PaintedProp.new()
		node.kind = kind
		node.definitions = boss.prop_kinds()
		node.folder = actor.art_folder
		node.pink = pink
		node.parry_id = "%s:%d:%s" % [name, run_seed, key]
		(container if container != null else self).add_child(node)
		_props[key] = node
		node.global_position = at
		# Nasce direto no lugar: com a interpolação da física ele deslizava do canto de cima da tela (0, 0).
		node.reset_physics_interpolation()
	var result: PaintedProp = _props[key]
	result.global_position = at
	return result


## Aviso no chão; `column` desenha o facho da queda (o que cai do céu).
func warning(key: String, at: Vector2, amount: float, width := 90.0, column := false) -> void:
	if not _marks.has(key):
		var marker := LandingShadow.new()
		marker.radius = Vector2(width, 20)
		marker.column = column
		add_child(marker)
		_marks[key] = marker
		marker.global_position = at
		marker.reset_physics_interpolation()
	var node: LandingShadow = _marks[key]
	node.global_position = at
	node.amount = amount
	node.visible = amount < 1.0


func hide_prop(key: String) -> void:
	if _props.has(key):
		var node: PaintedProp = _props[key]
		node.active = false
		node.hide()


## Ondas e projéteis atravessam o chão e os tampos: as plataformas não são um abrigo fixo.
func surface_levels() -> Array[float]:
	var result: Array[float] = [1000.0]
	for node in boss.get_parent().get_children():
		if node is ClockPlatform and node.visible:
			result.append(node.global_position.y)
	return result


func _on_end() -> void:
	_stop()
	# Efeitos apoiados nas plataformas pertencem a elas, mas terminam com o golpe.
	for effect: PaintedProp in _props.values():
		if effect.get_parent() != self:
			effect.active = false
			effect.queue_free()
	for child in get_children():
		if child is EnemyHitbox:
			child.active = false
		child.queue_free()
	_props.clear()
	_marks.clear()
	queue_redraw()
	if not boss.is_defeated:
		actor.idle()


func _start() -> void:
	pass


func _tick(_t: float) -> void:
	pass


func _stop() -> void:
	pass
