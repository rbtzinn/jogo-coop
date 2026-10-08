extends SceneTree
## Prepara peças do Gabinete Sem Fundo para renderização. Só recorta a transparência,
## separa o malão da peça-base e reduz a resolução; não redesenha ou repinta a arte.
## Godot --headless --path . --script res://tools/cut_cabinet_art.gd

const SOURCE := "res://docs/referencias/pecas/magico/gabinete_sem_fundo/producao/"
const OUTPUT := "res://bosses/magician/art/cabinet/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var body := Image.load_from_file(SOURCE + "gabinete_base.png")
	if body == null or body.is_empty():
		push_error("Gabinete: imagem-base ausente")
		quit(1)
		return
	body.convert(Image.FORMAT_RGBA8)
	body.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	_save(body, "body.png")
	# Malão inferior da base normalizada; origem própria, independente do painel atingível.
	var trunk := body.get_region(Rect2i(180, 746, 664, 244))
	trunk = trunk.get_region(trunk.get_used_rect())
	trunk.resize(560, roundi(560.0 * trunk.get_height() / trunk.get_width()), Image.INTERPOLATE_LANCZOS)
	_save(trunk, "trunk.png")
	_fit("gaveta.png", "drawer.png", 480)
	_fit("carimbo.png", "stamp.png", 520)
	_fit("rolo_ingressos.png", "roll.png", 320)
	for variant in ["comum", "parry", "perseguidor"]:
		_fit("bilhete_%s.png" % variant, "ticket_%s.png" % variant, 144, 208)
	print("CABINET_ART: 8 peças preparadas; bilhetes em 4x o tamanho final")
	quit()


func _fit(source_name: String, output_name: String, width: int, height := -1) -> void:
	var image := Image.load_from_file(SOURCE + source_name)
	if image == null or image.is_empty():
		push_error("Imagem ausente: " + source_name)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	image = image.get_region(_visible_rect(image))
	var target_height := height if height > 0 else roundi(float(width) * image.get_height() / image.get_width())
	image.resize(width, target_height, Image.INTERPOLATE_LANCZOS)
	_save(image, output_name)


func _visible_rect(image: Image) -> Rect2i:
	# O gerador deixa alguns pixels quase invisíveis longe da peça. Eles não devem
	# reduzir o tamanho visível do carimbo/bilhete ao definir o recorte de produção.
	var pixels := image.get_data()
	var width := image.get_width()
	var min_x := width
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for index in range(3, pixels.size(), 4):
		if pixels[index] < 20:
			continue
		var point := (index - 3) / 4
		var x := point % width
		var y := point / width
		min_x = mini(min_x, x)
		max_x = maxi(max_x, x)
		min_y = mini(min_y, y)
		max_y = maxi(max_y, y)
	if max_x < 0:
		return image.get_used_rect()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _save(image: Image, name: String) -> void:
	var error := image.save_png(OUTPUT + name)
	if error != OK:
		push_error("Falha ao salvar %s: %d" % [name, error])
		quit(1)
	print("ART ", name, " ", image.get_size())
