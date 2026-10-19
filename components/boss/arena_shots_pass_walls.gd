extends Node2D
## Raiz de luta em que a parede da direita é só limite do JOGADOR, não um escudo invisível para o chefão
## que fica atrás dela (Madame Carretel, Maestro Ferrugem): os tiros atravessam as paredes da arena.
func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Projectile and node.get_parent()==self:
		# Arena sem obstáculos: rolhas/confetes atravessam o limite cenográfico.
		# O jogador continua bloqueado pela camada normal, inclusive durante dash/descida.
		node.set_collision_mask_value(1,false)

func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
