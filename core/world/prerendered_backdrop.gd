class_name PrerenderedBackdrop
extends MeshInstance3D
## Cenário renderizado antes (cor + profundidade por pixel) desenhado na frente da câmera ortográfica
## (shaders/prerendered_backdrop.gdshader). Só visual: colisões e chão continuam nos nós de sempre.
## `data` vem do script gerado junto com a imagem: origin (centro da câmera do Blender, mundo),
## size (largura e altura em metros) e depth_range (metros).
## Quem passa atrás de uma peça do cenário aparece como silhueta (silhouette, para material_overlay).

const SHADER := preload("res://shaders/prerendered_backdrop.gdshader")
const SILHOUETTE_SHADER := preload("res://shaders/prerendered_silhouette.gdshader")
## Distância do quadrado à câmera (precisa ficar depois do plano de corte da frente).
const AHEAD := 0.5

var silhouette := ShaderMaterial.new()


func setup(camera: Camera3D, color: Texture2D, depth: Texture2D, data: Dictionary) -> void:
	var quad := QuadMesh.new()
	# Bem maior que a vista: cobre qualquer formato de janela (o que sobra fica fora da tela).
	quad.size = Vector2(camera.size * 4.0, camera.size * 1.2)
	mesh = quad
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 1000.0
	position = Vector3(0, 0, -(camera.near + AHEAD))
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("color_texture", color)
	# Desenha antes de tudo: o resto do mapa (bonecos, placas) testa contra a profundidade gravada.
	material.render_priority = -100
	silhouette.shader = SILHOUETTE_SHADER
	var basis := camera.global_transform.basis
	var origin: Array = data["origin"]
	for target in [material, silhouette]:
		target.set_shader_parameter("depth_texture", depth)
		target.set_shader_parameter("origin", Vector3(origin[0], origin[1], origin[2]))
		target.set_shader_parameter("span", Vector2(data["size"][0], data["size"][1]))
		target.set_shader_parameter("depth_range", Vector2(data["depth_range"][0], data["depth_range"][1]))
		target.set_shader_parameter("axis_right", basis.x)
		target.set_shader_parameter("axis_up", basis.y)
		target.set_shader_parameter("axis_forward", -basis.z)
	material_override = material
	camera.add_child(self)


## Liga a silhueta em todas as malhas de um boneco (as sombras de contato, sem sombra projetada, ficam de fora).
func mark(root: Node) -> void:
	for node: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and not node is Label3D:
			node.material_overlay = silhouette
