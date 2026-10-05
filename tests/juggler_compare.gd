extends Node2D
## Ferramenta (não é teste): os desenhos dos Malabaristas em movimento, lado a lado, para comparar a
## versão de antes (coluna da esquerda) com a atual (direita). De cima para baixo: Tico e Teco.
## Três partes, que se alternam a cada 6 s (ou teclas 1, 2 e 3 para escolher; 0 volta a alternar):
## 1. Parado e arremesso: 8 desenhos (antes) x 12 desenhos com a clave pelo cabo (atual); a cada 1,5 s os
##    quatro fazem o arremesso desenhado (E3) por 0,35 s, como nos ataques (sem o objeto).
## 2. Tonto: o pêndulo sem a suavização (antes) x com o assentamento da E4b (atual), com as estrelas.
## 3. Salto mortal (E5), sem comparação (não havia desenho antes): agachado 0,6 s, giro de 1,0 s (em cima
##    2 voltas para a frente, embaixo 3 para trás, como na Troca de Lugar), aterrissagem e parado.
## Para ver o movimento de verdade, abrir esta cena na Godot e rodar (F6), ou `tools/ver_malabaristas.bat`.
## Para gravar a sequência de quadros (60 por segundo, 3 s de uma parte, dá para montar um vídeo):
##   Godot --fixed-fps 60 --path . res://tests/juggler_compare.tscn -- <pasta> [parado|tonto|salto]
## grava `comparar_###.png` e sai.
## Para abrir já numa parte, sem gravar: `Godot --path . res://tests/juggler_compare.tscn -- tonto`.

const JUGGLER := preload("res://bosses/jugglers/juggler.tscn")
const SCALE := 1.6
const PART_TIME := 6.0
const PARTS := ["parado", "tonto", "salto"]

var _out := ""
var _frame := 0
var _time := 0.0
var _part := 0
var _auto := true
var _jugglers: Array[Juggler] = []
var _labels: Array[Label] = []
var _title := Label.new()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] in PARTS:
		# Só a parte, sem gravar (para assistir): `-- tonto`.
		_part = PARTS.find(args[0])
		_auto = false
	elif not args.is_empty():
		_out = args[0]
		DirAccess.make_dir_recursive_absolute(_out)
		if args.size() > 1 and args[1] in PARTS:
			_part = PARTS.find(args[1])
		_auto = false
	var background := ColorRect.new()
	background.color = Color("2a2030")
	background.size = Vector2(1920, 1080)
	add_child(background)
	_title.position = Vector2(40, 20)
	_title.add_theme_font_size_override("font_size", 32)
	add_child(_title)
	for row in 2:
		for column in 2:
			var juggler: Juggler = JUGGLER.instantiate()
			juggler.teco = row == 1
			juggler.scale = Vector2.ONE * SCALE
			juggler.position = Vector2(560 + column * 800, 500 + row * 500)
			add_child(juggler)
			juggler.facing = 1 if row == 0 else -1
			juggler.set_vulnerable(false)
			_jugglers.append(juggler)
			var label := Label.new()
			label.position = juggler.position + Vector2(-160, 10)
			label.add_theme_font_size_override("font_size", 28)
			add_child(label)
			_labels.append(label)
	_apply_part()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match (event as InputEventKey).keycode:
			KEY_1, KEY_2, KEY_3:
				_part = (event as InputEventKey).keycode - KEY_1
				_auto = false
				_time = 0.0
				_apply_part()
			KEY_0:
				_auto = true


func _apply_part() -> void:
	_title.text = "%d. %s   (teclas 1, 2, 3; 0 alterna sozinho)" % [_part + 1, ["Parado e arremesso", "Tonto", "Salto mortal"][_part]]
	for i in _jugglers.size():
		var juggler := _jugglers[i]
		var row := i / 2
		var current := i % 2 == 1
		juggler.smooth_idle = current or _part != 0
		juggler.smooth_dizzy = current or _part != 1
		juggler.dizzy = _part == 1
		juggler.pose = &"idle"
		juggler.spin = 0.0
		var who := "Teco" if row == 1 else "Tico"
		match _part:
			0:
				_labels[i].text = "%s, %s" % [who, "12 desenhos (atual)" if current else "8 desenhos (antes)"]
			1:
				_labels[i].text = "%s, %s" % [who, "tonto com assentamento (atual)" if current else "tonto sem suavizar (antes)"]
			2:
				_labels[i].text = "%s, salto (%s)" % [who, "2 voltas, por cima" if row == 0 else "3 voltas, por baixo"]


func _process(delta: float) -> void:
	_time += delta
	if _auto and _time >= PART_TIME:
		_time = 0.0
		_part = (_part + 1) % PARTS.size()
		_apply_part()
	match _part:
		0:
			var throwing := fmod(_time, 1.5) >= 1.0 and fmod(_time, 1.5) < 1.35
			for juggler in _jugglers:
				juggler.pose = &"throw" if throwing else &"idle"
		2:
			# Como na Troca de Lugar: 0,6 s agachado, 1,0 s girando, depois o parado (com a aterrissagem).
			var t := fmod(_time, 2.5)
			for i in _jugglers.size():
				var juggler := _jugglers[i]
				var turns := 2.0 if i / 2 == 0 else -3.0
				if t < 0.6:
					juggler.pose = &"crouch"
					juggler.spin = 0.0
				elif t < 1.6:
					juggler.pose = &"spin"
					juggler.spin = (t - 0.6) * turns
				else:
					juggler.pose = &"idle"
					juggler.spin = 0.0
	if _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(960, 540)
	image.save_png(_out.path_join("comparar_%03d.png" % _frame))
	_frame += 1
	if _frame >= 180:
		get_tree().quit()
