extends Node
## Ferramenta (não é teste): abre uma luta com janela, passa por todas as fases e ataques e
## salva uma foto de cada momento, para conferir o desenho sem jogar.
## Rodar (com janela, não headless):
##   Godot --path . res://tests/screenshots.tscn -- <cena da luta> <pasta de saída>

var _out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: -- <cena> <pasta>")
		get_tree().quit(1)
		return
	_out = args[1]
	DirAccess.make_dir_recursive_absolute(_out)
	if args[0] == "loja":
		_shop_shots()
		return
	if args[0] == "parry":
		_parry_strip()
		return
	if args[0] == "parado":
		_idle_strip()
		return
	if args[0] == "pulo":
		_idle_strip(true)
		return
	if args[0] == "dano" or args[0] == "dano2":
		_hurt_strip(1 if args[0] == "dano2" else 0)
		return
	if args[0] == "abaixado" or args[0] == "abaixado2":
		_crouch_strip(1 if args[0] == "abaixado2" else 0)
		return
	if args[0] == "dash" or args[0] == "dash2":
		_dash_strip(1 if args[0] == "dash2" else 0)
		return
	if args[0] == "balao" or args[0] == "balao2":
		_balloon_strip(1 if args[0] == "balao2" else 0)
		return
	if args[0] == "magico_rosto":
		_face_capture()
		return
	if args[0] == "magico_maos":
		_hands_capture()
		return
	if args[0] == "magico_caixas":
		_shell_capture()
		return
	if args[0] == "magico_perseguidoras":
		_homing_capture(args[2], [args[3], args[4]], int(args[5]) if args.size() > 5 else 6)
		return
	if args[0] == "magico_reverencia":
		_magician_bow_capture(args[2] if args.size() > 2 else "")
		return
	if args[0] == "magico_sumir":
		_magician_vanish_capture()
		return
	if args[0] == "magico_parado":
		_magician_idle_capture()
		return
	if args[0] == "malabaristas_derrota":
		_jugglers_defeat_capture()
		return
	if args[0] == "malabaristas_entradas":
		_jugglers_entries_capture()
		return
	if args[0] == "malabaristas_totem":
		_jugglers_totem_capture(args.size() > 2 and args[2] == "teco")
		return
	if args[0] == "malabaristas_salto":
		_jugglers_flip_capture()
		return
	if args[0] == "malabaristas_tonto":
		_jugglers_dizzy_capture()
		return
	if args[0] == "malabaristas_arremesso":
		_jugglers_throw_capture()
		return
	if args[0] == "malabaristas_parado":
		_jugglers_idle_capture()
		return
	if args[0] == "rugido_fogo":
		_fire_roar_capture()
		return
	if args[0] == "menus":
		_menu_shots()
		return
	if args[0] == "dupla":
		_duo_capture()
		return
	if args[0] == "pistolas":
		_guns_capture()
		return
	if args[0] == "monociclo":
		_unicycle_capture()
		return
	if args[0] == "trem_detalhes":
		_train_details()
		return
	if args[0] == "salto_mortal" or args[0] == "salto_mortal2":
		_somersault_capture(args[0] == "salto_mortal2")
		return
	if args[0] == "corrida" or args[0] == "corrida2":
		_run_capture(1 if args[0] == "corrida" else 0)
		return
	if args[0] == "torta_voo":
		_pie_flight_shots()
		return
	if args[0] == "torta":
		_pie_strip()
		return
	if args[0] == "domador":
		_tamer_whip_strip()
		return
	if args[0] == "domador_chicote":
		_tamer_fear_lash_capture()
		return
	if args[0] == "leao_derrota":
		_lion_defeat_strip()
		return
	if args[0] == "leao_fogo":
		_lion_fire_idle_strip()
		return
	if args[0] == "leao":
		_lion_leap_strip()
		return
	_run(args[0])


func seconds(value: float) -> void:
	await get_tree().create_timer(value).timeout


func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(960, 540)
	image.save_png(_out.path_join(label + ".png"))
	print("foto: ", label)


func _run(path: String) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load(path).instantiate()
	add_child(scene)
	if not scene.has_node("Fight"):
		await _run_level_shots(scene)
		return
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(1.0)
	await shot("00_inicio")
	for phase in boss.phase_shares.size():
		if phase > 0:
			var parts: Array = [""]
			if boss.has_method(&"sub_bars"):
				parts = boss.sub_bars().map(func(entry: Array) -> String: return entry[0])
			for part: String in parts:
				boss.apply_damage(boss.health.current - boss.phase_end_health() if part.is_empty() else boss.health.current, "", part)
			await seconds(0.8)
			await shot("%d0_troca_de_fase" % phase)
			await seconds(2.6)
		for attack_name: StringName in boss.phase_attacks[phase]:
			for player: Player in get_tree().get_nodes_in_group(&"players"):
				player.player_health._invincible_timer = 1000.0
			boss.sync.start_attack(attack_name, randi(), boss._args_for(attack_name))
			await seconds(0.9)
			await shot("%d_%s_a" % [phase, attack_name])
			await seconds(0.8)
			await shot("%d_%s_b" % [phase, attack_name])
			while boss._current != null and boss._current.is_running():
				await seconds(0.1)
	boss.apply_damage(100000, "", "")
	for part in ["Tico", "Teco"]:
		boss.apply_damage(100000, "", part)
	await seconds(1.5)
	await shot("99_vitoria")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Fase de plataforma: leva a dupla por vários pontos da fase e tira uma foto em cada um.
func _run_level_shots(scene: Node) -> void:
	var camera := scene.get_node("Camera") as Camera2D
	var players := get_tree().get_nodes_in_group(&"players")
	await seconds(1.0)
	await shot("00_inicio")
	var index := 1
	for x in [1300.0, 2300.0, 3100.0, 3900.0, 4800.0, 5600.0, 6300.0]:
		camera.global_position.x = x
		for i in players.size():
			var player: Player = players[i]
			player.player_health._invincible_timer = 1000.0
			player.global_position = Vector2(x - 120.0 + i * 140.0, 600.0)
			player.reset_physics_interpolation()
		await seconds(1.2)
		await shot("%02d_x%d" % [index, int(x)])
		index += 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Barraca de Curiosidades e Camarim, no mapa.
func _shop_shots() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	SaveGame.data.players.clown.tickets = 7
	SaveGame.data.players.clown.items.append("soap_bubble")
	var map: Node = load(Levels.MAP).instantiate()
	add_child(map)
	await seconds(1.0)
	await shot("mapa")
	var clown: Node = map.get_node("PlayerSpawner/Player_1")
	(map.get_node("DoorShop") as WorldDoor).try_enter(clown)
	await seconds(0.5)
	await shot("loja")
	(get_tree().get_first_node_in_group(&"blocking_ui") as ShopPanel).close()
	await seconds(0.2)
	PauseMenu.open()
	PauseMenu._open_dressing_room()
	await seconds(0.5)
	await shot("camarim")
	PauseMenu.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Parry desenhado: o palhaço e a acrobata parados no ar, uma foto em cada ponto da
## cambalhota, juntas numa tira (alinhamento e transição entre os quadros).
func _parry_strip() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	# Espera o letreiro de abertura sair da tela.
	await seconds(3.5)
	var steps := 10
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		var strip := Image.create(steps * 260, 300, false, Image.FORMAT_RGBA8)
		for i in steps:
			var progress := float(i) / (steps - 1) * 0.999
			for k in 3:
				player.global_position = Vector2(960, 700)
				player.velocity = Vector2.ZERO
				player.parry._spin = PlayerParry.SPIN_TIME * (1.0 - progress)
				await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			var view := get_viewport().get_texture().get_image()
			# A janela pode ter outro tamanho: recorta em volta do jogador na tela.
			var ratio := float(view.get_width()) / 1920.0
			var center := player.get_global_transform_with_canvas().origin
			if view.get_width() != 1920:
				center *= ratio
			var box := Rect2i(Vector2i(center - Vector2(130, 230) * ratio), Vector2i(Vector2(260, 300) * ratio))
			var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
			crop.resize(260, 300)
			strip.blit_rect(crop, Rect2i(0, 0, 260, 300), Vector2i(i * 260, 0))
		strip.save_png(_out.path_join("parry_%s.png" % player.name))
		print("foto: parry_", player.name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Dano ("dano" = 1º jogador, "dano2" = 2º): o jogador leva um golpe parado no chão e a tira
## segue o empurrão (uma foto por quadro de física) até voltar ao chão.
func _hurt_strip(index := 0) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players := get_tree().get_nodes_in_group(&"players")
	var player := players[index] as Player
	player.global_position = Vector2(700, 1000)
	for other: Player in players:
		other.input.local_control = other == player
		if other != player:
			other.global_position = Vector2(1500, 1000)
	await seconds(3.5)
	var shots := [await _player_crop(player)]
	player.player_health.hurt_by(1, player.global_position + Vector2(100, 0))
	for i in 24:
		await get_tree().physics_frame
		shots.append(await _player_crop(player))
	var strip := Image.create(shots.size() * 260, 300, false, Image.FORMAT_RGBA8)
	for i in shots.size():
		strip.blit_rect(shots[i], Rect2i(0, 0, 260, 300), Vector2i(i * 260, 0))
	strip.save_png(_out.path_join("dano_%d.png" % (index + 1)))
	print("foto: dano")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Abaixado ("abaixado" = 1º jogador, "abaixado2" = 2º): o jogador abaixa (uma foto por quadro
## de física), fica abaixado atirando e levanta. Imprime onde fica a boca da pistola em relação
## aos pés, em pé e abaixado, para conferir que a altura do tiro não mudou.
func _crouch_strip(index := 0) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players := get_tree().get_nodes_in_group(&"players")
	var player := players[index] as Player
	player.global_position = Vector2(500, 1000)
	for other: Player in players:
		other.input.local_control = other == player
		if other != player:
			other.global_position = Vector2(1400, 1000)
	await seconds(3.5)
	print("boca da pistola em pé: ", player.rig.get_muzzle_position() - player.global_position)
	var shots := [await _player_crop(player)]
	Input.action_press(&"move_down")
	for i in 8:
		await get_tree().physics_frame
		shots.append(await _player_crop(player))
	Input.action_press(&"shoot")
	for i in 4:
		await seconds(0.12)
		shots.append(await _player_crop(player))
	print("boca da pistola abaixado: ", player.rig.get_muzzle_position() - player.global_position)
	print("mão da pistola abaixado: ", player.rig.gun_hand.global_position - player.global_position,
			", ombro: ", player.rig.shoulder_front.global_position - player.global_position)
	Input.action_release(&"shoot")
	Input.action_release(&"move_down")
	for i in 8:
		await get_tree().physics_frame
		shots.append(await _player_crop(player))
	var strip := Image.create(shots.size() * 260, 300, false, Image.FORMAT_RGBA8)
	for i in shots.size():
		strip.blit_rect(shots[i], Rect2i(0, 0, 260, 300), Vector2i(i * 260, 0))
	strip.save_png(_out.path_join("abaixado_%d.png" % (index + 1)))
	print("foto: abaixado")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Dash ("dash" = 1º jogador, "dash2" = 2º): o jogador corre, dá um dash reto (uma foto por
## quadro de física, até voltar a correr) e depois, com a Pirueta, um dash para cima.
func _dash_strip(index := 0) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players := get_tree().get_nodes_in_group(&"players")
	var player := players[index] as Player
	player.global_position = Vector2(500, 1000)
	# Só o jogador da foto obedece às teclas.
	for other: Player in players:
		other.input.local_control = other == player
	await seconds(3.5)
	var shots := []
	Input.action_press(&"move_right")
	await seconds(0.3)
	shots.append(await _player_crop(player))
	Input.action_press(&"dash")
	for i in 14:
		await get_tree().physics_frame
		if i == 1:
			Input.action_release(&"dash")
		shots.append(await _player_crop(player))
	Input.action_release(&"move_right")
	await seconds(0.8)
	player.loadout.trick = "pirouette"
	Input.action_press(&"lock_aim")
	Input.action_press(&"move_up")
	await get_tree().physics_frame
	Input.action_press(&"dash")
	for i in 12:
		await get_tree().physics_frame
		if i == 1:
			Input.action_release(&"dash")
		shots.append(await _player_crop(player))
	Input.action_release(&"move_up")
	Input.action_release(&"lock_aim")
	var strip := Image.create(shots.size() * 260, 300, false, Image.FORMAT_RGBA8)
	for i in shots.size():
		strip.blit_rect(shots[i], Rect2i(0, 0, 260, 300), Vector2i(i * 260, 0))
	strip.save_png(_out.path_join("dash_%d.png" % (index + 1)))
	print("foto: dash")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Recorte de 260 x 300 em volta do jogador, no próximo quadro desenhado.
func _player_crop(player: Player) -> Image:
	await RenderingServer.frame_post_draw
	var view := get_viewport().get_texture().get_image()
	var ratio := float(view.get_width()) / 1920.0
	var center := player.get_global_transform_with_canvas().origin * ratio
	var box := Rect2i(Vector2i(center - Vector2(130, 200) * ratio), Vector2i(Vector2(260, 300) * ratio))
	var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
	crop.resize(260, 300)
	return crop


## Balão ("balao" = 1º jogador, "balao2" = 2º): o jogador cai e a tira segue o balão: a
## transformação (fotos a cada 0,1 s), um balanço inteiro (a cada 0,25 s) e, depois do
## resgate, o estouro no mesmo lugar (a cada 1/12 s).
func _balloon_strip(index := 0) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var player := get_tree().get_nodes_in_group(&"players")[index] as Player
	player.global_position = Vector2(700, 1000)
	await seconds(3.5)
	player.player_health.hurt_by(99, player.global_position + Vector2(100, 0))
	var waits: Array[float] = [0.1, 0.1, 0.1, 0.1, 0.1]
	for i in 8:
		waits.append(0.25)
	var revive_at := waits.size()
	for i in 5:
		waits.append(1.0 / 12.0)
	var strip := Image.create(waits.size() * 260, 300, false, Image.FORMAT_RGBA8)
	var center := Vector2.ZERO
	for i in waits.size():
		if i == revive_at:
			player.player_health.revive_from_rescue()
		await RenderingServer.frame_post_draw
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / 1920.0
		if i < revive_at:
			center = player.balloon.get_global_transform_with_canvas().origin * ratio
		var box := Rect2i(Vector2i(center - Vector2(130, 150) * ratio), Vector2i(Vector2(260, 300) * ratio))
		var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
		crop.resize(260, 300)
		strip.blit_rect(crop, Rect2i(0, 0, 260, 300), Vector2i(i * 260, 0))
		await seconds(waits[i])
	strip.save_png(_out.path_join("balao_%d.png" % (index + 1)))
	print("foto: balao")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Parado desenhado: os dois parados no chão, 9 fotos a cada 1/8 s (o ciclo inteiro e a
## volta do quadro 8 para o 1), juntas numa tira por jogador.
## `jump`: em vez de parados, os dois pulam e a tira segue o pulo inteiro até o pouso.
func _idle_strip(jump := false) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players := get_tree().get_nodes_in_group(&"players")
	for i in players.size():
		(players[i] as Player).global_position = Vector2(620 + i * 400, 1000)
	await seconds(3.5)
	var count := 13 if jump else 9
	var interval := 0.06 if jump else 0.125
	if jump:
		for player: Player in players:
			player.velocity.y = player._jump_velocity
	var strips := {}
	for player: Player in players:
		strips[player] = Image.create(count * 260, 300, false, Image.FORMAT_RGBA8)
	for i in count:
		await RenderingServer.frame_post_draw
		var view := get_viewport().get_texture().get_image()
		for player: Player in players:
			var ratio := float(view.get_width()) / 1920.0
			var center := player.get_global_transform_with_canvas().origin * ratio
			var box := Rect2i(Vector2i(center - Vector2(130, 270) * ratio), Vector2i(Vector2(260, 300) * ratio))
			var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
			crop.resize(260, 300)
			strips[player].blit_rect(crop, Rect2i(0, 0, 260, 300), Vector2i(i * 260, 0))
		await seconds(interval)
	for player: Player in players:
		strips[player].save_png(_out.path_join("%s_%s.png" % ["pulo" if jump else "parado", player.name]))
		print("foto: ", "pulo_" if jump else "parado_", player.name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Salto do leão: agachado, um arco inteiro (como nos ataques: posição no arco e tilt_along)
## e o pouso, uma foto por ponto, numa tira; a segunda fila com a juba em fogo (fase 3).
func _lion_leap_strip() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var lion: TamerLion = boss.get_node("Lion")
	await seconds(3.5)
	var from := Vector2(1350, 1000)
	var to := Vector2(650, 1000)
	var height := 300.0
	var flight := 0.7
	var steps := 15
	var count := steps + 4
	var strip := Image.create(count * 350, 2 * 260, false, Image.FORMAT_RGBA8)
	for row in 2:
		lion.set_on_fire(row == 1)
		lion.place(from)
		lion.set_facing(-1)
		for i in count:
			var k := i - 2
			if i < 2:
				lion.global_position = from
				lion.pose_crouch(1.0)
			elif k < steps:
				var u := float(k) / (steps - 1) * 0.98
				var at := BossAttack.arc_point(from, to, height, u)
				lion.global_position = at
				lion.tilt_along(BossAttack.arc_point(from, to, height, minf(u + 0.02, 1.0)) - at)
				lion._pose_time = u * flight
			else:
				lion.global_position = to
				lion.rotation = 0.0
				if k == steps:
					lion.pose_land()
			lion._show_frame()
			await RenderingServer.frame_post_draw
			var view := get_viewport().get_texture().get_image()
			var ratio := float(view.get_width()) / 1920.0
			var center := lion.get_global_transform_with_canvas().origin * ratio
			var box := Rect2i(Vector2i(center - Vector2(350, 420) * ratio), Vector2i(Vector2(700, 520) * ratio))
			var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
			crop.resize(350, 260)
			strip.blit_rect(crop, Rect2i(0, 0, 350, 260), Vector2i(i * 350, row * 260))
	strip.save_png(_out.path_join("leao_salto.png"))
	print("foto: leao_salto")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Leão "em fogo" (fase 3), duas filas: (1) parado normal virando parado em fogo, 6 fotos antes e 10
## depois, a cada 0,1 s (troca sem salto, chamas mudando); (2) parado em fogo, correndo em fogo a
## 1/14 s por foto (o ciclo inteiro e a volta do 8 para o 1) e parando de novo.
func _lion_fire_idle_strip() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var lion: TamerLion = boss.get_node("Lion")
	await seconds(3.5)
	lion.place(Vector2(1000, 1000))
	lion.set_facing(-1)
	var count := 16
	var strip := Image.create(count * 300, 2 * 260, false, Image.FORMAT_RGBA8)
	for row in 2:
		for i in count:
			if row == 0 and i == 6:
				lion.set_on_fire(true)
			if row == 1 and i == 2:
				lion.set_running(true)
			if row == 1 and i == 12:
				lion.set_running(false)
			await RenderingServer.frame_post_draw
			var view := get_viewport().get_texture().get_image()
			var ratio := float(view.get_width()) / 1920.0
			var center := lion.get_global_transform_with_canvas().origin * ratio
			var box := Rect2i(Vector2i(center - Vector2(300, 440) * ratio), Vector2i(Vector2(600, 520) * ratio))
			var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
			crop.resize(300, 260)
			strip.blit_rect(crop, Rect2i(0, 0, 300, 260), Vector2i(i * 300, row * 260))
			await seconds(0.1 if row == 0 else 1.0 / 14.0)
	strip.save_png(_out.path_join("leao_parado_fogo.png"))
	print("foto: leao_parado_fogo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Derrota do leão: parado em fogo, depois lie_down() (apaga o fogo e deita até dormir),
## uma foto a cada 0,15 s (a sequência inteira e a respiração dormindo).
func _lion_defeat_strip() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var lion: TamerLion = boss.get_node("Lion")
	await seconds(3.5)
	lion.place(Vector2(1000, 1000))
	lion.set_facing(-1)
	lion.set_on_fire(true)
	var count := 16
	var strip := Image.create(count * 300, 260, false, Image.FORMAT_RGBA8)
	for i in count:
		if i == 2:
			lion.lie_down()
		await RenderingServer.frame_post_draw
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / 1920.0
		var center := lion.get_global_transform_with_canvas().origin * ratio
		var box := Rect2i(Vector2i(center - Vector2(300, 440) * ratio), Vector2i(Vector2(600, 520) * ratio))
		var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
		crop.resize(300, 260)
		strip.blit_rect(crop, Rect2i(0, 0, 300, 260), Vector2i(i * 300, 0))
		await seconds(0.15)
	strip.save_png(_out.path_join("leao_derrota.png"))
	print("foto: leao_derrota")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Domador, duas filas: (1) a pose do chicote passa por caído, erguendo, erguido, estalando,
## estalado e de volta (o "depois do estalo"), uma foto a cada 0,1 s (quadros, mão e chicote
## juntos); (2) com medo, uma foto a cada 0,17 s (o tremor e uma espiada), e no fim de pé de novo;
## (3) a reverência do fim da luta (o `bow` de 0 a 1), com as botas paradas.
func _tamer_whip_strip() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var tamer: Tamer = boss.get_node("Tamer")
	await seconds(3.5)
	var poses := [0.0, 0.0, 0.3, 0.6, 1.0, 1.0, 1.5, 2.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var strip := Image.create(poses.size() * 250, 3 * 260, false, Image.FORMAT_RGBA8)
	for i in poses.size() * 3:
		var row := i / poses.size()
		if row == 0:
			tamer.whip_pose = poses[i]
		elif row == 1:
			tamer.cowering = i < poses.size() * 2 - 2
		else:
			tamer.bow = clampf(float(i - poses.size() * 2 - 2) / 9.0, 0.0, 1.0)
		await RenderingServer.frame_post_draw
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / 1920.0
		var center := tamer.get_global_transform_with_canvas().origin * ratio
		var box := Rect2i(Vector2i(center - Vector2(330, 420) * ratio), Vector2i(Vector2(500, 520) * ratio))
		var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
		crop.resize(250, 260)
		strip.blit_rect(crop, Rect2i(0, 0, 250, 260), Vector2i(i % poses.size() * 250, row * 260))
		await seconds(0.1 if row == 0 else 0.17)
	strip.save_png(_out.path_join("domador_chicote.png"))
	print("foto: domador_chicote")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Torta na Cara desenhada: o palhaço solta o Grande Número (cópia só visual, sem dano), uma foto
## a cada 0,06 s até a torta sair da tela; fila 1 no chão, fila 2 parado no ar.
func _pie_strip() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(3.5)
	var clown: Player
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.rig.special_animation != null:
			clown = player
		else:
			player.global_position = Vector2(1500, 1000)
	var count := 16
	var strip := Image.create(count * 300, 2 * 260, false, Image.FORMAT_RGBA8)
	for row in 2:
		clown.global_position = Vector2(500, 1000 if row == 0 else 760)
		clown.velocity = Vector2.ZERO
		for k in 20:
			await get_tree().physics_frame
		clown.special.play_remote(&"grand", Vector2.RIGHT)
		for i in count:
			await RenderingServer.frame_post_draw
			var view := get_viewport().get_texture().get_image()
			var ratio := float(view.get_width()) / 1920.0
			var center := clown.get_global_transform_with_canvas().origin * ratio
			var box := Rect2i(Vector2i(center - Vector2(150, 260) * ratio), Vector2i(Vector2(450, 390) * ratio))
			var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
			crop.resize(300, 260)
			strip.blit_rect(crop, Rect2i(0, 0, 300, 260), Vector2i(i * 300, row * 260))
			await seconds(0.06)
	strip.save_png(_out.path_join("torta.png"))
	print("foto: torta")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Torta voando e esborrachando: a tela inteira a cada 0,08 s depois do Grande Número do palhaço
## (cópia só visual), até a torta bater na parede; uma foto por arquivo.
func _pie_flight_shots() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(3.5)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.rig.special_animation != null:
			player.global_position = Vector2(400, 1000)
			player.special.play_remote(&"grand", Vector2.RIGHT)
	for i in 44:
		await seconds(0.08)
		await shot("torta_voo_%02d" % i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Corrida em movimento real ("corrida" = acrobata, "corrida2" = palhaço): um roteiro de controle
## (parado, corre, para, corre e atira, pula correndo, dash, abaixa, levanta e corre), uma foto do
## jogador a cada quadro de física (60 por segundo, no tamanho real da tela) e um registro por
## quadro: tempo, x, velocidade, no chão e o quadro desenhado na tela (para medir o deslize do pé).
func _run_capture(index: int) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players := get_tree().get_nodes_in_group(&"players")
	var player := players[index] as Player
	for other: Player in players:
		other.input.local_control = other == player
		other.global_position = Vector2(100, 1000) if other == player else Vector2(1750, 1000)
	await seconds(3.5)
	# [quadro de física em que começa, ação, apertar (true) ou soltar]
	var script := [
		[20, &"move_right", true], [70, &"move_right", false],
		[100, &"move_right", true], [105, &"shoot", true], [140, &"jump", true], [146, &"jump", false],
		[175, &"shoot", false], [185, &"dash", true], [188, &"dash", false],
		[200, &"move_right", false], [225, &"move_down", true], [265, &"move_down", false],
		[285, &"move_left", true], [380, &"move_left", false],
	]
	var log := FileAccess.open(_out.path_join("corrida.csv"), FileAccess.WRITE)
	log.store_line("quadro;tempo;x;y;vx;no_chao;desenho")
	var rig := player.rig
	for tick in 450:
		for step in script:
			if step[0] == tick:
				if step[2]:
					Input.action_press(step[1])
				else:
					Input.action_release(step[1])
		await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var sprite: Sprite2D = rig._frame_sprite
		var drawn := sprite.texture.resource_path.get_file() if sprite.visible and sprite.texture != null else "pecas"
		log.store_line("%d;%.4f;%.2f;%.2f;%.1f;%s;%s" % [tick, tick / 60.0, player.global_position.x,
				player.global_position.y, player.velocity.x, player.is_on_floor(), drawn])
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / 1920.0
		var center := player.get_global_transform_with_canvas().origin * ratio
		var box := Rect2i(Vector2i(center - Vector2(120, 250) * ratio), Vector2i(Vector2(240, 280) * ratio))
		var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
		crop.resize(240, 280)
		crop.save_png(_out.path_join("q_%03d.png" % tick))
	log.close()
	for action in [&"move_right", &"move_left", &"shoot", &"jump", &"dash", &"move_down"]:
		Input.action_release(action)
	print("foto: corrida")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Salto Mortal da acrobata em movimento real (rodar com --fixed-fps 60): parada, solta o Grande
## Número de verdade (controle local), uma foto a cada quadro de física em volta dela e o quadro
## desenhado no registro `salto_mortal.csv`; depois do pouso, segue alguns quadros parada.
## "salto_mortal2": sai de x 900 para a esquerda e pousa no chão, em x 140 (antes do pedestal).
func _somersault_capture(to_floor := false) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players := get_tree().get_nodes_in_group(&"players")
	var acro := players[1] as Player
	for other: Player in players:
		other.input.local_control = other == acro
		other.global_position = (Vector2(900, 1000) if to_floor else Vector2(250, 1000)) if other == acro else Vector2(1750, 1000)
	acro.facing = -1 if to_floor else 1
	await seconds(3.5)
	acro.applause.stars = 5.0
	var log := FileAccess.open(_out.path_join("salto_mortal.csv"), FileAccess.WRITE)
	log.store_line("quadro;x;y;no_chao;desenho;giro")
	for tick in 95:
		if tick == 5:
			Input.action_press(&"special")
		if tick == 7:
			Input.action_release(&"special")
		await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var sprite: Sprite2D = acro.rig._frame_sprite
		var drawn := sprite.texture.resource_path.get_file() if sprite.visible and sprite.texture != null else "pecas"
		log.store_line("%d;%.1f;%.1f;%s;%s;%.2f" % [tick, acro.global_position.x, acro.global_position.y,
				acro.is_on_floor(), drawn, acro.visual.rotation])
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / 1920.0
		var center := acro.get_global_transform_with_canvas().origin * ratio
		var box := Rect2i(Vector2i(center - Vector2(160, 300) * ratio), Vector2i(Vector2(320, 360) * ratio))
		var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
		if crop.get_width() > 0:
			crop.resize(240, 270)
			crop.save_png(_out.path_join("s_%03d.png" % tick))
	log.close()
	print("foto: salto_mortal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Grande Número em Dupla (só o desenho, sem dano; rodar com --fixed-fps 60): a Torta de Ouro com a
## acrobata chutando sai da esquerda do chefão e depois da direita (o desenho espelha); a tela a
## cada 2 quadros de física, reduzida, numa grade por saída.
func _duo_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(3.5)
	for side in 2:
		DuoFinale.spawn(Vector2(600, 820) if side == 0 else Vector2(1850, 760), 0, false)
		var count := 24
		var grid := Image.create(6 * 480, 4 * 270, false, Image.FORMAT_RGBA8)
		for i in count:
			await get_tree().physics_frame
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			var view := get_viewport().get_texture().get_image()
			if i < 8 and side == 0:
				var r := float(view.get_width()) / 1920.0
				view.get_region(Rect2i(Vector2i(Vector2(340, 380) * r), Vector2i(Vector2(560, 560) * r))).save_png(_out.path_join("dupla_perto_%d.png" % i))
			view.resize(480, 270)
			grid.blit_rect(view, Rect2i(0, 0, 480, 270), Vector2i((i % 6) * 480, (i / 6) * 270))
		grid.save_png(_out.path_join("dupla_%d.png" % side))
		await seconds(0.5)
	print("foto: dupla")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Trem (Pedido B) de perto: o aviso da ponte, a ponte passando por cima do palhaço abaixado, uma
## tira de 8 recortes de cada inimigo (fantasma pulando, pombo, canhão atirando) e a derrota do fantasma.
func _train_details() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node2D = load("res://levels/train/train_level.tscn").instantiate()
	add_child(scene)
	var level: RunLevel = scene.get_node("RunLevel")
	var camera := scene.get_node("Camera") as Camera2D
	var players := get_tree().get_nodes_in_group(&"players")
	for player: Player in players:
		player.player_health._invincible_timer = 100000.0
		player.input.scripted = true
	await seconds(1.0)
	var train := scene as Node
	var bridge_speed: float = train.BRIDGE_SPEED
	var spawn: float = train.LEVEL_WIDTH + 600.0
	# Aviso: a ponte ainda fora da tela, à direita.
	camera.global_position.x = 3000.0
	for i in 12:
		level.clock = train.FIRST_BRIDGE + (spawn - 4600.0) / bridge_speed
		await get_tree().physics_frame
		if fmod(train._time, 0.3) < 0.15:
			break
	await shot("trem_aviso")
	# Ponte em cima do palhaço abaixado.
	var clown: Player = players[0]
	clown.global_position = Vector2(3000.0, 700.0)
	clown.reset_physics_interpolation()
	clown.input.move = Vector2(0, 1)
	for i in 30:
		level.clock = train.FIRST_BRIDGE + (spawn - 3010.0) / bridge_speed
		await get_tree().physics_frame
	await shot("trem_ponte")
	clown.input.move = Vector2.ZERO
	level.clock = 0.5
	# Inimigos de perto.
	for kind in [["hopper", Vector2(1380, 660)], ["pigeon", Vector2(3000, 470)], ["cannon", Vector2(2420, 660)]]:
		var enemy: Enemy = null
		for e: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			if e.home.distance_to(kind[1]) < 60.0 or (kind[0] == "pigeon" and e is MagicPigeon and absf(e.home.x - kind[1].x) < 10.0) \
					or (kind[0] == "hopper" and e is GhostHopper and absf(e.home.x - kind[1].x) < 10.0) \
					or (kind[0] == "cannon" and e is ConfettiCannon and absf(e.home.x - kind[1].x) < 10.0):
				enemy = e
				break
		camera.global_position.x = enemy.home.x
		for player: Player in players:
			player.global_position = Vector2(enemy.home.x - 700.0, 700.0)
			player.reset_physics_interpolation()
		await seconds(0.5)
		var grid := Image.create(4 * 320, 2 * 320, false, Image.FORMAT_RGBA8)
		for i in 8:
			for k in 8:
				await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			var view := get_viewport().get_texture().get_image()
			var ratio := float(view.get_width()) / get_viewport().get_visible_rect().size.x
			var focus := enemy.global_position + (Vector2(-150, 0) if kind[0] == "cannon" else Vector2.ZERO)
			var screen := get_viewport().get_canvas_transform() * focus * ratio
			var size := Vector2(320, 320) * ratio
			var at := (screen + Vector2(-160, -220) * ratio).clamp(Vector2.ZERO, Vector2(view.get_size()) - size)
			var crop := view.get_region(Rect2i(Vector2i(at), Vector2i(size)))
			crop.resize(320, 320)
			grid.blit_rect(crop, Rect2i(0, 0, 320, 320), Vector2i((i % 4) * 320, (i / 4) * 320))
		grid.save_png(_out.path_join("trem_%s.png" % kind[0]))
		print("foto: ", kind[0])
		if kind[0] == "hopper":
			enemy.die()
			await seconds(0.25)
			await shot("trem_fantasma_derrota")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Monociclo em peças: a corrida do monociclo (fase 3 dos Malabaristas), 12 recortes de perto, um a cada
## 6 quadros de física (o encaixe do selim e o giro da roda).
func _unicycle_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(1.0)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
	for part in ["Tico", "Teco"]:
		boss.apply_damage(boss.health.current, "", part)
	await seconds(3.5)
	for part in ["Tico", "Teco"]:
		boss.apply_damage(boss.health.current, "", part)
	await seconds(3.5)
	boss.sync.start_attack(&"UnicycleRide", 1, boss._args_for(&"UnicycleRide"))
	var unicycle: Unicycle = boss.unicycle
	var grid := Image.create(4 * 360, 3 * 480, false, Image.FORMAT_RGBA8)
	for i in 12:
		for k in 6:
			await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / get_viewport().get_visible_rect().size.x
		var screen := get_viewport().get_canvas_transform() * unicycle.global_position * ratio
		var size := Vector2(360, 480) * ratio
		var at := (screen + Vector2(-180, -470) * ratio).clamp(Vector2.ZERO, Vector2(view.get_size()) - size)
		var crop := view.get_region(Rect2i(Vector2i(at), Vector2i(size)))
		crop.resize(360, 480)
		grid.blit_rect(crop, Rect2i(0, 0, 360, 480), Vector2i((i % 4) * 360, (i / 4) * 480))
	grid.save_png(_out.path_join("monociclo.png"))
	print("foto: monociclo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Pistolas (Pedido A): o palhaço atira com cada pistola e solta o Tiro EX dela. Para cada uma,
## uma tira de 12 recortes (perto da mão e do caminho do tiro), a cada 3 quadros de física.
func _guns_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(3.5)
	var player: Player = get_tree().get_nodes_in_group(&"players")[0]
	player.input.scripted = true
	player.global_position.x = 560.0
	player.reset_physics_interpolation()
	var partner: Player = get_tree().get_nodes_in_group(&"players")[1]
	partner.input.scripted = true
	partner.input.clear()
	partner.global_position.x = 1500.0
	partner.reset_physics_interpolation()
	for weapon in ["cork_gun", "confetti_fan", "juggling_club", "soap_bubble"]:
		player.gun.weapon = weapon
		player.rig.set_weapon(weapon)
		for mode in ["tiro", "ex"]:
			player.input.clear()
			await seconds(1.5)
			var grid := Image.create(4 * 480, 3 * 270, false, Image.FORMAT_RGBA8)
			if mode == "tiro":
				player.input.shoot_held = true
			else:
				player.applause.stars = 1.0
				player.input.special_pressed = true
			for i in 12:
				for k in 3:
					await get_tree().physics_frame
				player.input.special_pressed = false
				await RenderingServer.frame_post_draw
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / get_viewport().get_visible_rect().size.x
				var screen := get_viewport().get_canvas_transform() * player.global_position * ratio
				var size := (Vector2(600, 338) if mode == "tiro" else Vector2(960, 540)) * ratio
				var at := (screen + Vector2(-120, -250) * ratio).clamp(Vector2.ZERO, Vector2(view.get_size()) - size)
				var crop := view.get_region(Rect2i(Vector2i(at), Vector2i(size)))
				crop.resize(480, 270)
				grid.blit_rect(crop, Rect2i(0, 0, 480, 270), Vector2i((i % 4) * 480, (i / 4) * 270))
			grid.save_png(_out.path_join("%s_%s.png" % [weapon, mode]))
			print("foto: ", weapon, " ", mode)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Auditoria das telas (M2): menu principal, painel de entrar, configurações (as três abas), pausa
## na luta e cartaz de vitória e de derrota. Uma foto da tela inteira para cada.
func _menu_shots() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var menu: Node = load("res://core/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await seconds(1.0)
	await shot("menu_1_principal")
	menu._show_join_panel()
	await seconds(0.3)
	await shot("menu_2_entrar")
	menu.queue_free()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var fight := scene.get_node("Fight") as Fight
	fight.boss._wait = 100000.0
	fight.boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(3.5)
	await shot("menu_3_luta")
	PauseMenu.open()
	await seconds(0.3)
	await shot("menu_4_pausa")
	PauseMenu._open_settings()
	await seconds(0.3)
	var tabs := PauseMenu._settings_menu.find_children("*", "TabContainer", true, false)
	for t in 3:
		if not tabs.is_empty():
			(tabs[0] as TabContainer).current_tab = t
		await seconds(0.2)
		await shot("menu_5_config_%d" % t)
	PauseMenu.close()
	await seconds(0.3)
	fight._show_end_screen(true, fight._victory_result())
	await seconds(1.5)
	await shot("menu_6_vitoria")
	fight._show_end_screen(false, {})
	await seconds(1.5)
	await shot("menu_7_derrota")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Rugido em fogo (rodar com --fixed-fps 60): toca a entrada da fase 3 (IntroFire: o domador joga a
## tocha, o leão engole, pega fogo e ruge) e depois as Argolas Caindo (ruge avisando as ondas),
## pelo cérebro do chefão como numa luta; uma foto do leão a cada 3 quadros de física, numa grade,
## e o quadro desenhado no registro `rugido_fogo.csv`.
func _fire_roar_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var lion: TamerLion = boss.get_node("Lion")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(3.5)
	var log := FileAccess.open(_out.path_join("rugido_fogo.csv"), FileAccess.WRITE)
	log.store_line("ataque;quadro;fogo;desenho;chamas_soltas")
	for attack in [&"IntroFire", &"FallingRings"]:
		boss.play_attack(attack, 7, 0.0, boss._args_for(attack))
		var grid := Image.create(10 * 300, 6 * 200, false, Image.FORMAT_RGBA8)
		for i in 180:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			log.store_line("%s;%d;%s;%s;%s" % [attack, i, lion.on_fire, lion.frames.texture.resource_path.get_file(), lion.fire_mane.visible])
			if i % 3 == 0:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := lion.get_global_transform_with_canvas().origin * ratio
				var box := Rect2i(Vector2i(center - Vector2(300, 400) * ratio), Vector2i(Vector2(600, 400) * ratio))
				var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(300, 200)
					grid.blit_rect(crop, Rect2i(0, 0, 300, 200), Vector2i((i / 3 % 10) * 300, (i / 30) * 200))
		grid.save_png(_out.path_join("rugido_%s.png" % attack))
	log.close()
	print("foto: rugido_fogo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto do parado dos Malabaristas (rodar com --fixed-fps 60): a luta parada (o cérebro não ataca),
## os dois irmãos malabarizando, o palhaço ao lado do Tico e a acrobata ao lado do Teco (escala).
## `-- malabaristas_parado <pasta> [8]`: com "8", a versão antiga de 8 desenhos, para comparar.
## Grava `malabaristas.csv` a cada quadro do jogo por 3 s (quadro, irmão, desenho, objeto, estado,
## pegada, posição) e imprime, por irmão, o quanto cada objeto anda de um quadro do jogo para o outro,
## separado pela causa:
## - "mao": na mão, sem troca de desenho (deve ser 0);
## - "mao_troca": na mão, quando o desenho troca (a luva desenhada pulou);
## - "voo_alto" e "voo_baixo": no ar (a velocidade do arco, legítima);
## - "fronteira": o quadro em que o estado muda (soltar, pegar, passar).
## E a própria luva da frente desenhada (`luva`): quanto ela pula entre dois quadros do jogo.
## Fotos: a arena e uma grade de recortes de cada irmão a cada 2 quadros (2 s).
func _jugglers_idle_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var old_version := OS.get_cmdline_user_args().size() > 2 and OS.get_cmdline_user_args()[2] == "8"
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var brothers: Array[Juggler] = [boss.get_node("Tico"), boss.get_node("Teco")]
	for brother in brothers:
		brother.smooth_idle = not old_version
	var players := get_tree().get_nodes_in_group(&"players")
	for player: Player in players:
		player.player_health._invincible_timer = 1000.0
	await seconds(1.0)
	for k in players.size():
		var player: Player = players[k]
		var beside := brothers[k].global_position + Vector2(170 if k == 0 else -170, 0)
		player.global_position = Vector2(beside.x, player.global_position.y)
	await seconds(1.0)
	await shot("malabaristas_arena")
	var log := FileAccess.open(_out.path_join("malabaristas.csv"), FileAccess.WRITE)
	log.store_line("quadro;irmao;desenho;obj;estado;pegada;x;y")
	var last := {}
	var steps := {}
	var events: Array[String] = []
	var grids := [Image.create(10 * 240, 6 * 300, false, Image.FORMAT_RGBA8), Image.create(10 * 240, 6 * 300, false, Image.FORMAT_RGBA8)]
	for f in 180:
		await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		for b in 2:
			var brother := brothers[b]
			var drawing := brother.idle_frame()
			# A luva da frente desenhada (o objeto que está nela segue esse ponto).
			var glove: Vector2 = brother.global_position + brother._front_palm(brother._time) * Vector2(brother.facing, 1)
			var glove_key := "%s_luva" % brother.name
			if last.has(glove_key):
				_add_step(steps, "%s|luva" % brother.name, glove.distance_to(last[glove_key]))
			last[glove_key] = glove
			for i in 3:
				var state := brother.prop_state(i)
				var at: Vector2 = brother.global_position + (state[0] as Vector2)
				var phase := _prop_phase(brother, i)
				log.store_line("%d;%s;%d;%d;%s;%.2f;%.1f;%.1f" % [f, brother.name, drawing + 1, i, phase, state[2], at.x, at.y])
				var key := "%s%d" % [brother.name, i]
				if last.has(key):
					var prev: Array = last[key]
					var d: float = at.distance_to(prev[0])
					var cause: String = phase
					if phase != prev[1]:
						cause = "fronteira"
					elif phase.begins_with("mao"):
						cause = "mao_troca" if drawing != prev[2] else "mao"
					_add_step(steps, "%s|%s" % [brother.name, cause], d)
					if d > 25.0:
						events.append("quadro %d %s objeto %d: %.1f px, %s (desenho %d -> %d, %s -> %s)" % [f, brother.name, i, d, cause, prev[2] + 1, drawing + 1, prev[1], phase])
				last[key] = [at, phase, drawing]
			if f % 2 == 0:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := brother.get_global_transform_with_canvas().origin * ratio
				var box := Rect2i(Vector2i(center - Vector2(160, 380) * ratio), Vector2i(Vector2(320, 400) * ratio))
				var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(240, 300)
					(grids[b] as Image).blit_rect(crop, Rect2i(0, 0, 240, 300), Vector2i((f / 2 % 10) * 240, (f / 20) * 300))
	log.close()
	for b in 2:
		(grids[b] as Image).save_png(_out.path_join("malabaristas_%s.png" % brothers[b].name))
	print("versão: %s" % ("8 desenhos" if old_version else "12 desenhos"))
	var keys := steps.keys()
	keys.sort()
	for key: String in keys:
		var list: Array = steps[key]
		list.sort()
		print("passo %s: %d quadros, máximo %.1f px, P95 %.1f px, mediana %.1f px" % [key, list.size(), list.back(), list[mini(int(list.size() * 0.95), list.size() - 1)], list[list.size() / 2]])
	for line in events:
		print("evento ", line)
	await shot("malabaristas_arena_fim")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


func _add_step(steps: Dictionary, key: String, value: float) -> void:
	var list: Array = steps.get(key, [])
	list.append(value)
	steps[key] = list


## Em que parte do ciclo está o objeto `i`: voo_alto, mao_tras, voo_baixo ou mao_frente.
func _prop_phase(brother: Juggler, i: int) -> String:
	var since := fposmod(brother._time - Juggler.FIRST_RELEASE - i * Juggler.PROP_CYCLE / 3.0, Juggler.PROP_CYCLE)
	if since < Juggler.HIGH_FLIGHT:
		return "voo_alto"
	if since < Juggler.HIGH_FLIGHT + Juggler.BACK_HOLD:
		return "mao_tras"
	if since < Juggler.HIGH_FLIGHT + Juggler.BACK_HOLD + Juggler.LOW_FLIGHT:
		return "voo_baixo"
	return "mao_frente"


## Piloto do arremesso desenhado (E3), rodar com --fixed-fps 60: a luta dos Malabaristas com o Troca-Troca
## e as Bolas Quicando de verdade (os dois irmãos, cada um olhando para um lado). Grava
## `arremesso.csv` a cada quadro do jogo (pose, desenho, pés, nariz desenhado) e imprime:
## - em cada objeto que aparece: o desenho do arremesso naquele instante e a distância entre o objeto e
##   o meio da palma desenhada;
## - o pulo do nariz desenhado entre dois quadros do jogo, separado entre "parado" (troca dentro do
##   parado), "entrada" (parado → arremesso), "arremesso" (dentro dele) e "saida" (arremesso → parado);
## - se os pés andaram.
## Fotos: recortes do arremessador a cada quadro do jogo em volta de cada arremesso.
const _IDLE12_NOSES: Array[Vector2] = [Vector2(326, 173), Vector2(298, 178), Vector2(298, 178), Vector2(288, 187),
		Vector2(310, 168), Vector2(310, 168), Vector2(329, 168), Vector2(329, 168), Vector2(324, 157), Vector2(294, 179),
		Vector2(336, 173), Vector2(336, 173)]
const _THROW_NOSES: Array[Vector2] = [Vector2(382, 189), Vector2(314, 154), Vector2(301, 143), Vector2(331, 180)]


func _jugglers_throw_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var brothers: Array[Juggler] = [boss.get_node("Tico"), boss.get_node("Teco")]
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("arremesso.csv"), FileAccess.WRITE)
	log.store_line("ataque;quadro;irmao;pose;arte;desenho;pes_x;pes_y;nariz_x;nariz_y")
	var seen := {}
	var spawns: Array[String] = []
	var jumps := {}
	var feet := {}
	var last := {}
	var tick := 0
	for attack in [&"JugglePass", &"BounceBalls"]:
		boss.play_attack(attack, 11, 0.0, boss._args_for(attack))
		var strip := Image.create(12 * 200, 2 * 260, false, Image.FORMAT_RGBA8)
		var strip_count := 0
		for f in 300:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			for brother in brothers:
				var throwing := brother._throw_art()
				var drawn := brother._uses_art()
				var drawing := brother.throw_frame() if throwing else brother.idle_frame()
				var nose_cell: Vector2 = (_THROW_NOSES if throwing else _IDLE12_NOSES)[drawing]
				var nose := brother.global_position + Vector2((nose_cell.x - 256.0) * 0.5 * brother.facing, (nose_cell.y - 486.0) * 0.5)
				log.store_line("%s;%d;%s;%s;%s;%d;%.1f;%.1f;%.1f;%.1f" % [attack, tick, brother.name, brother.pose, drawn, drawing + 1,
						brother.global_position.x, brother.global_position.y, nose.x, nose.y])
				var key: String = brother.name
				if not feet.has(key):
					feet[key] = brother.global_position
				elif brother.global_position.distance_to(feet[key]) > 0.5:
					spawns.append("AVISO %s: os pés andaram para %s" % [key, brother.global_position])
					feet[key] = brother.global_position
				if drawn and last.has(key) and last[key][2]:
					var was_throw: bool = last[key][1]
					var cause := "parado"
					if throwing and not was_throw:
						cause = "entrada"
					elif throwing:
						cause = "arremesso"
					elif was_throw:
						cause = "saida"
					var list: Array = jumps.get(cause, [])
					list.append(nose.distance_to(last[key][0]))
					jumps[cause] = list
				last[key] = [nose, throwing, drawn]
			# Objetos novos: onde apareceram e onde estava a palma desenhada de quem arremessou.
			for prop: Node in scene.find_children("*", "JugglerProp", true, false):
				if seen.has(prop.get_instance_id()):
					continue
				seen[prop.get_instance_id()] = true
				var thrower: Juggler = brothers[0] if (prop as Node2D).global_position.distance_to(brothers[0].global_position) < (prop as Node2D).global_position.distance_to(brothers[1].global_position) else brothers[1]
				var palm_local: Vector2 = Juggler.THROW_PALMS[thrower.throw_frame()] if thrower._throw_art() else Vector2.INF
				var text := "%s quadro %d %s: objeto em %s" % [attack, tick, thrower.name, (prop as Node2D).global_position]
				if palm_local != Vector2.INF:
					var palm := thrower.global_position + Vector2(palm_local.x * thrower.facing, palm_local.y)
					text += ", desenho %d, palma em %s, distância %.1f px" % [thrower.throw_frame() + 1, palm, palm.distance_to((prop as Node2D).global_position)]
				else:
					text += ", sem arremesso desenhado (pose %s)" % thrower.pose
				spawns.append(text)
			# Recortes do arremessador enquanto o desenho do arremesso aparece (até 24).
			for brother in brothers:
				if brother._throw_art() and strip_count < 24:
					var view := get_viewport().get_texture().get_image()
					var ratio := float(view.get_width()) / 1920.0
					var center := brother.get_global_transform_with_canvas().origin * ratio
					var box := Rect2i(Vector2i(center - Vector2(150, 300) * ratio), Vector2i(Vector2(300, 330) * ratio))
					var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
					if crop.get_width() > 0:
						crop.resize(200, 260)
						strip.blit_rect(crop, Rect2i(0, 0, 200, 260), Vector2i((strip_count % 12) * 200, (strip_count / 12) * 260))
						strip_count += 1
		strip.save_png(_out.path_join("arremesso_%s.png" % attack))
	log.close()
	for line in spawns:
		print("arremesso ", line)
	for cause in jumps:
		var list: Array = jumps[cause]
		list.sort()
		print("nariz %s: %d quadros, máximo %.1f px, P95 %.1f px, mediana %.1f px" % [cause, list.size(), list.back(), list[mini(int(list.size() * 0.95), list.size() - 1)], list[list.size() / 2]])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto do tonto desenhado (E4), rodar com --fixed-fps 60 (`-- malabaristas_tonto <pasta> [antes]`; com
## "antes", sem a suavização do pêndulo): a luta dos Malabaristas parada; o Tico leva
## dano até o limite da fase (fica tonto) e o Teco joga a bola de cura de verdade; depois o contrário.
## O dano entra 0,5 s depois do começo (para medir a entrada). Grava `tonto.csv` a cada quadro do jogo e
## imprime, para cada irmão: quanto tempo ficou tonto até a cura
## pousar, onde a bola pousou contra o meio da cabeça desenhada (e contra o ponto fixo antigo, 180 px acima
## dos pés), o maior passo da bola no último 0,2 s, e o pulo do nariz desenhado ao entrar no tonto, dentro
## dele (inclusive do 4 para o 1) e ao sair; e se os pés andaram. Fotos: recortes a cada 4 quadros.
const _DIZZY_NOSES: Array[Vector2] = [Vector2(269, 173), Vector2(333, 144), Vector2(376, 202), Vector2(321, 161)]


func _jugglers_dizzy_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("tonto.csv"), FileAccess.WRITE)
	log.store_line("irmao;quadro;tonto;desenho;cabeca_x;cabeca_y;bola_x;bola_y;nariz_x;nariz_y")
	for target_name in ["Tico", "Teco"]:
		var target: Juggler = boss.get_node(target_name)
		target.smooth_dizzy = not (OS.get_cmdline_user_args().size() > 2 and OS.get_cmdline_user_args()[2] == "antes")
		var feet := target.global_position
		var start := -1
		var last_ball := Vector2.INF
		var ball_steps: Array[float] = []
		var last_nose := Vector2.INF
		var last_dizzy := false
		var jumps := {}
		var strip := Image.create(12 * 200, 3 * 260, false, Image.FORMAT_RGBA8)
		var shots := 0
		var landed_text := "a cura não pousou"
		var max_tilt := 0.0
		for f in 450:
			if f == 30:
				boss.apply_damage(1000, "", target_name)
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			var dizzy_art := target._dizzy_art()
			if dizzy_art and start < 0:
				start = f
			var drawing := target.dizzy_frame() if dizzy_art else target.idle_frame()
			var nose_cell: Vector2 = (_DIZZY_NOSES if dizzy_art else _IDLE12_NOSES)[drawing]
			var nose_local := Vector2((nose_cell.x - 256.0) * 0.5, (nose_cell.y - 486.0) * 0.5)
			if dizzy_art:
				nose_local = nose_local.rotated(target.dizzy_rotation())
				max_tilt = maxf(max_tilt, absf(target.dizzy_rotation()))
			var nose := target.global_position + Vector2(nose_local.x * target.facing, nose_local.y)
			if last_nose != Vector2.INF and target._uses_art():
				var cause := "parado"
				if dizzy_art and not last_dizzy:
					cause = "entrada"
				elif dizzy_art:
					cause = "tonto"
				elif last_dizzy:
					cause = "saida"
				var list: Array = jumps.get(cause, [])
				list.append(nose.distance_to(last_nose))
				jumps[cause] = list
			last_nose = nose
			last_dizzy = dizzy_art
			var head := target.head_position()
			var ball := Vector2.INF
			var heal: Node2D = boss._heal
			if heal != null and is_instance_valid(heal):
				ball = heal.global_position
				if last_ball != Vector2.INF and boss._heal_time > JugglersBoss.HEAL_FLIGHT - 0.2:
					ball_steps.append(ball.distance_to(last_ball))
				last_ball = ball
				if boss._heal_time >= JugglersBoss.HEAL_FLIGHT - 1.0 / 60.0:
					var old_point := target.global_position + Vector2(0, -180)
					landed_text = "%s: tonto por %.2f s até a cura pousar; bola em %s, meio da cabeça desenhada em %s (desenho %d): %.1f px; do ponto fixo antigo: %.1f px" % [
							target_name, (f - start) / 60.0, ball, head, drawing + 1, ball.distance_to(head), head.distance_to(old_point)]
			log.store_line("%s;%d;%s;%d;%.1f;%.1f;%.1f;%.1f;%.1f;%.1f" % [target_name, f, dizzy_art, drawing + 1, head.x, head.y, ball.x, ball.y, nose.x, nose.y])
			if target.global_position.distance_to(feet) > 0.5:
				print("tonto AVISO %s: os pés andaram" % target_name)
				feet = target.global_position
			if f % 4 == 0 and shots < 36 and start >= 0:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := target.get_global_transform_with_canvas().origin * ratio
				var box := Rect2i(Vector2i(center - Vector2(150, 330) * ratio), Vector2i(Vector2(300, 360) * ratio))
				var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(200, 260)
					strip.blit_rect(crop, Rect2i(0, 0, 200, 260), Vector2i((shots % 12) * 200, (shots / 12) * 260))
					shots += 1
		strip.save_png(_out.path_join("tonto_%s.png" % target_name))
		print("tonto ", landed_text)
		print("tonto %s: inclinação máxima %.1f°, a ponta do sapato (95 px dos pés) sobe até %.1f px" % [target_name, rad_to_deg(max_tilt), 95.0 * sin(max_tilt)])
		ball_steps.sort()
		if not ball_steps.is_empty():
			print("tonto %s: passo da bola no último 0,2 s, máximo %.1f px" % [target_name, ball_steps.back()])
		for cause in jumps:
			var list: Array = jumps[cause]
			list.sort()
			print("tonto %s nariz %s: %d quadros, máximo %.1f px, P95 %.1f px" % [target_name, cause, list.size(), list.back(), list[mini(int(list.size() * 0.95), list.size() - 1)]])
		await seconds(1.0)
	log.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto do salto mortal desenhado (E5), rodar com --fixed-fps 60: a Troca de Lugar de verdade, duas
## vezes (cada irmão passa uma vez por cima, 2 voltas, e uma vez rolando por baixo, 3 voltas para o outro
## lado). Grava `salto.csv` a cada quadro do jogo e imprime: quantas vezes a orientação desenhada andou para
## trás em relação ao giro (deve ser 0), quantos desenhos diferentes apareceram por volta, o pulo do meio
## de massa do desenho entre quadros (separado: agachado, entrada no giro, giro, aterrissagem, parado) e se o
## meio da bolinha seguiu o meio do giro do boneco antigo. Fotos: recortes de cada irmão a cada 2 quadros.
const _FLIP_MASS: Array[Vector2] = [Vector2(265, 306), Vector2(256, 291), Vector2(256, 276), Vector2(247, 281),
		Vector2(251, 285), Vector2(256, 263), Vector2(256, 278), Vector2(260, 273), Vector2(248, 287), Vector2(247, 277)]
const _IDLE12_MASS: Array[Vector2] = [Vector2(259, 281), Vector2(253, 274), Vector2(255, 271), Vector2(254, 264),
		Vector2(258, 270), Vector2(255, 274), Vector2(262, 276), Vector2(262, 274), Vector2(260, 268), Vector2(255, 265),
		Vector2(261, 278), Vector2(258, 282)]


func _jugglers_flip_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var brothers: Array[Juggler] = [boss.get_node("Tico"), boss.get_node("Teco")]
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("salto.csv"), FileAccess.WRITE)
	log.store_line("rodada;quadro;irmao;pose;giro;desenho;pes_x;pes_y;massa_x;massa_y")
	var steps := {}
	var backwards := 0
	var last := {}
	var grids := [Image.create(10 * 200, 6 * 240, false, Image.FORMAT_RGBA8), Image.create(10 * 200, 6 * 240, false, Image.FORMAT_RGBA8)]
	var shots := [0, 0]
	var turns := {}
	for round_index in 2:
		boss.play_attack(&"Swap", 5, 0.0, boss._args_for(&"Swap"))
		for f in 150:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			for b in 2:
				var brother := brothers[b]
				var flip := brother._flip_art()
				var drawing := brother.flip_frame() if flip else brother.idle_frame()
				var mass_cell: Vector2 = (_FLIP_MASS if flip else _IDLE12_MASS)[drawing]
				var mass := brother.global_position + Vector2((mass_cell.x - 256.0) * 0.5 * brother.facing, (mass_cell.y - 486.0) * 0.5)
				log.store_line("%d;%d;%s;%s;%.3f;%d;%.1f;%.1f;%.1f;%.1f" % [round_index, f, brother.name, brother.pose, brother.spin, drawing + 1,
						brother.global_position.x, brother.global_position.y, mass.x, mass.y])
				var key := "%s%d" % [brother.name, round_index]
				if last.has(key):
					var prev: Array = last[key]
					var cause := "parado"
					if brother.pose == &"crouch":
						cause = "agachado"
					elif brother.pose == &"spin" and prev[1] != &"spin":
						cause = "entrada_giro"
					elif brother.pose == &"spin":
						cause = "giro"
						# A orientação desenhada anda no mesmo sentido do giro (ou fica).
						var d_spin: float = brother.spin - prev[2]
						var d_draw := posmod(drawing - int(prev[3]), 8) if drawing >= 1 and int(prev[3]) >= 1 else 0
						if d_draw != 0 and signf(d_spin) > 0 and d_draw > 4:
							backwards += 1
						if d_draw != 0 and signf(d_spin) < 0 and d_draw < 4:
							backwards += 1
						turns[key] = (turns.get(key, {}) as Dictionary)
						(turns[key] as Dictionary)[drawing] = true
					elif flip:
						cause = "aterrissagem"
					var list: Array = steps.get(cause, [])
					list.append(mass.distance_to(prev[0]))
					steps[cause] = list
				last[key] = [mass, brother.pose, brother.spin, drawing]
				if f % 2 == 0 and f >= 20 and shots[b] < 60:
					var view := get_viewport().get_texture().get_image()
					var ratio := float(view.get_width()) / 1920.0
					var center := brother.get_global_transform_with_canvas().origin * ratio
					var box := Rect2i(Vector2i(center - Vector2(150, 300) * ratio), Vector2i(Vector2(300, 360) * ratio))
					var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
					if crop.get_width() > 0:
						crop.resize(200, 240)
						(grids[b] as Image).blit_rect(crop, Rect2i(0, 0, 200, 240), Vector2i((shots[b] % 10) * 200, (shots[b] / 10) * 240))
						shots[b] += 1
		await seconds(0.5)
	log.close()
	for b in 2:
		(grids[b] as Image).save_png(_out.path_join("salto_%s.png" % brothers[b].name))
	print("salto orientação para trás: %d vezes" % backwards)
	for key in turns:
		print("salto %s: %d orientações diferentes durante o giro" % [key, (turns[key] as Dictionary).size()])
	for cause in steps:
		var list: Array = steps[cause]
		list.sort()
		print("salto meio de massa %s: %d quadros, máximo %.1f px, P95 %.1f px" % [cause, list.size(), list.back(), list[mini(int(list.size() * 0.95), list.size() - 1)]])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto das ENTRADAS de verdade com os desenhos (rodar com --fixed-fps 60): a troca para o totem
## (IntroTotem: o da direita agacha, dá o salto e cai sentado nos ombros do outro), 1,5 s de totem parado e
## a troca para o monociclo (IntroUnicycle: os dois saltam do totem para o selim). Grava `entradas.csv` a
## cada quadro do jogo (pose, desenho ou boneco, giro, pés, meio do desenho, altura da caixa de dano,
## objetos do parado desenhados) e imprime o pulo do meio do corpo por momento (entrada no giro, giro,
## saída do giro para sentado/montado), em relação aos pés; e quantas vezes o desenho do parado apareceu
## com o outro irmão sentado nos ombros. Fotos: os dois a cada 3 quadros.
func _jugglers_entries_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: JugglersBoss = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var brothers: Array[Juggler] = [boss.tico, boss.teco]
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("entradas.csv"), FileAccess.WRITE)
	log.store_line("etapa;quadro;irmao;pose;arte;desenho;giro;pes_x;pes_y;meio_x;meio_y;caixa_dano;objetos")
	var steps := {}
	var last := {}
	var base_art_with_top := 0
	var grid := Image.create(12 * 160, 10 * 200, false, Image.FORMAT_RGBA8)
	var shots := 0
	var tick := 0
	for stage in [[&"IntroTotem", 150], [&"", 90], [&"IntroUnicycle", 150]]:
		if stage[0] != &"":
			boss.play_attack(stage[0], 3, 0.0, boss._args_for(stage[0]))
		for f in int(stage[1]):
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			for brother in brothers:
				var art := brother._uses_art()
				var drawing := -1
				var mid_cell := Vector2(256, 270)
				if brother._flip_art():
					drawing = brother.flip_frame()
					mid_cell = _FLIP_MASS[drawing]
				elif brother._dizzy_art():
					drawing = brother.dizzy_frame()
				elif brother._throw_art():
					drawing = brother.throw_frame()
				elif art:
					drawing = brother.idle_frame()
					mid_cell = _IDLE12_MASS[drawing]
				# Boneco de código: o meio do tronco fica 105 px acima dos pés.
				var mid_local := Vector2((mid_cell.x - 256.0) * 0.5 * brother.facing, (mid_cell.y - 486.0) * 0.5) if art else Vector2(0, -105)
				var mid := brother.global_position + mid_local
				var hit_shape := brother.hitbox.get_child(0) as CollisionShape2D
				var props := art and brother.juggling and not brother._throw_art() and not brother._flip_art() and not brother._dizzy_art()
				log.store_line("%s;%d;%s;%s;%s;%d;%.3f;%.1f;%.1f;%.1f;%.1f;%.0f;%s" % [stage[0], tick, brother.name, brother.pose, art, drawing + 1,
						brother.spin, brother.global_position.x, brother.global_position.y, mid.x, mid.y, (hit_shape.shape as RectangleShape2D).size.y, props])
				if boss.mode == &"totem" and brother == boss.base() and art and not brother._throw_art():
					base_art_with_top += 1
				var key: String = brother.name
				if last.has(key):
					var prev: Array = last[key]
					var cause := ""
					if brother.pose == &"spin" and prev[1] != &"spin":
						cause = "entrada_giro"
					elif brother.pose == &"spin":
						cause = "giro"
					elif prev[1] == &"spin":
						cause = "saida_giro_para_" + String(brother.pose)
					if cause != "":
						var rel_now := mid - brother.global_position
						var rel_prev: Vector2 = prev[2]
						var list: Array = steps.get(cause, [])
						# Pulo do meio do corpo em relação aos pés (o caminho do ataque fica de fora) e o caminho.
						list.append([rel_now.distance_to(rel_prev), brother.global_position.distance_to(prev[0])])
						steps[cause] = list
				last[key] = [brother.global_position, brother.pose, mid - brother.global_position]
			if tick % 3 == 0 and shots < 120:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := (boss.base().get_global_transform_with_canvas().origin + boss.top().get_global_transform_with_canvas().origin) * 0.5 * ratio
				var box := Rect2i(Vector2i(center - Vector2(300, 450) * ratio), Vector2i(Vector2(600, 600) * ratio))
				var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(160, 200)
					grid.blit_rect(crop, Rect2i(0, 0, 160, 200), Vector2i((shots % 12) * 160, (shots / 12) * 200))
					shots += 1
	log.close()
	grid.save_png(_out.path_join("entradas.png"))
	for cause in steps:
		var list: Array = steps[cause]
		var worst := 0.0
		var worst_path := 0.0
		for item in list:
			worst = maxf(worst, item[0])
			worst_path = maxf(worst_path, item[1])
		print("entradas %s: %d quadros, meio do corpo (em relação aos pés) máximo %.1f px; caminho máximo %.1f px" % [cause, list.size(), worst, worst_path])
	print("entradas: quadros com a base do totem desenhada (parado) e o outro sentado em cima: %d" % base_art_with_top)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Medida da derrota de verdade (rodar com --fixed-fps 60), antes de pedir a folha: leva a luta até a fase
## 3 (monociclo) pelo dano, derruba os dois e grava `derrota.csv` a cada quadro (pose, desenho ou boneco,
## pés, modo) até a tela de fim, com fotos a cada 6 quadros.
func _jugglers_defeat_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: JugglersBoss = (scene.get_node("Fight") as Fight).boss
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	for i in 2:
		boss.apply_damage(1000, "", "Tico")
		boss.apply_damage(1000, "", "Teco")
		await seconds(3.5)
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	await seconds(1.0)
	var log := FileAccess.open(_out.path_join("derrota.csv"), FileAccess.WRITE)
	log.store_line("quadro;irmao;modo;pose;arte;desenho;pes_x;pes_y;facing;caixa_dano_ligada")
	var end_frame := -1
	boss.apply_damage(5000, "", "Tico")
	boss.apply_damage(5000, "", "Teco")
	print("derrota: fase %d, derrotado %s" % [boss.phase, boss.is_defeated])
	var grid := Image.create(10 * 240, 3 * 200, false, Image.FORMAT_RGBA8)
	for f in 170:
		await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		for brother: Juggler in [boss.tico, boss.teco]:
			log.store_line("%d;%s;%s;%s;%s;%d;%.1f;%.1f;%d;%s" % [f, brother.name, boss.mode, brother.pose, brother._uses_art(), brother.defeat_frame() + 1 if brother._defeat_art() else 0,
					brother.global_position.x, brother.global_position.y, brother.facing, brother.hitbox.active])
		if end_frame < 0:
			for node in scene.find_children("*", "", true, false):
				if node.get_script() == preload("res://core/ui/fight_end_screen.gd"):
					end_frame = f
					print("derrota: tela de fim no quadro %d (%.2f s)" % [f, f / 60.0])
					break
		if f == 100:
			get_viewport().get_texture().get_image().save_png(_out.path_join("derrota_tela.png"))
		if f % 5 == 0 and f / 5 < 30:
			var view := get_viewport().get_texture().get_image()
			var ratio := float(view.get_width()) / 1920.0
			var center := boss.tico.get_global_transform_with_canvas().origin * ratio
			var box := Rect2i(Vector2i(center - Vector2(300, 400) * ratio), Vector2i(Vector2(600, 500) * ratio))
			var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
			if crop.get_width() > 0:
				crop.resize(240, 200)
				grid.blit_rect(crop, Rect2i(0, 0, 240, 200), Vector2i((f / 5 % 10) * 240, (f / 50) * 200))
	log.close()
	grid.save_png(_out.path_join("derrota.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto do parado desenhado do Mágico (M2), rodar com --fixed-fps 60: a luta do Mágico de verdade, com
## o Leque de Cartas, o Teleporte, os Coelhos e o Blackout em seguida, e o parado entre eles. Grava
## `magico.csv` a cada quadro do jogo (ataque, pose, desenho ou boneco, quadro, pés, facing, vanish,
## eyes_only, caixas de dano) e imprime: quantas trocas boneco→desenho e desenho→boneco, se os pés
## andaram enquanto parado, os facing vistos com o desenho, e as caixas de dano. Fotos: a arena com os
## jogadores ao lado (escala) e uma grade do Mágico a cada 6 quadros.
func _magician_idle_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var zaratan: Magician = boss.get_node("Zaratan")
	var players := get_tree().get_nodes_in_group(&"players")
	for player: Player in players:
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	(players[0] as Player).global_position.x = zaratan.global_position.x - 220.0
	await seconds(0.5)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join("magico_arena.png"))
	var log := FileAccess.open(_out.path_join("magico.csv"), FileAccess.WRITE)
	log.store_line("ataque;quadro;pose;arte;desenho;pes_x;pes_y;facing;vanish;eyes_only;leva_tiro;machuca")
	var to_art := 0
	var to_puppet := 0
	var last_art := false
	var last_feet := Vector2.INF
	var foot_moves := 0
	var facings := {}
	var tick := 0
	var seen_cards := {}
	var card_lines: Array[String] = []
	var rabbit_grid := Image.create(12 * 200, 3 * 192, false, Image.FORMAT_RGBA8)
	var rabbit_shots := 0
	var grid := Image.create(12 * 200, 6 * 260, false, Image.FORMAT_RGBA8)
	var shots := 0
	for attack in [&"", &"CardFan", &"Teleport", &"Rabbits", &"Blackout", &"SawBoxes"]:
		if attack != &"":
			boss.play_attack(attack, 9, 0.0, boss._args_for(attack))
		for f in (90 if attack == &"" else 300):
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			var art := zaratan.uses_art()
			log.store_line("%s;%d;%s;%s;%d;%.1f;%.1f;%d;%.2f;%s;%s;%s" % [attack, tick, zaratan.pose, art, zaratan.art_frame() + 1 if art else 0,
					zaratan.global_position.x, zaratan.global_position.y, zaratan.facing, zaratan.vanish, zaratan.eyes_only,
					zaratan.hurtbox.monitorable, zaratan.hitbox.active])
			if art and not last_art:
				to_art += 1
			elif last_art and not art:
				to_puppet += 1
			if art:
				facings[zaratan.facing] = true
				if last_art and last_feet != Vector2.INF and zaratan.global_position.distance_to(last_feet) > 0.5:
					foot_moves += 1
			last_art = art
			last_feet = zaratan.global_position
			# Cartas novas: o desenho na tela e a distância até a palma desenhada do lançamento (M3b: meio da
			# luva em (130, 225) da célula de 512, sola em 486; no jogo × 330/465).
			for prop: Node in scene.find_children("*", "MagicProp", true, false):
				if seen_cards.has(prop.get_instance_id()) or prop.get("kind") != &"card":
					continue
				seen_cards[prop.get_instance_id()] = true
				var palm := zaratan.global_position + Vector2((130.0 - 256.0) * 330.0 / 465.0 * -zaratan.facing, (225.0 - 486.0) * 330.0 / 465.0)
				card_lines.append("%s quadro %d: pose %s, desenho %d, carta em %s, palma desenhada em %s: %.1f px; hand_position %s" % [attack, tick, zaratan.pose,
						zaratan.art_frame() + 1 if art else 0, (prop as Node2D).global_position, palm, palm.distance_to((prop as Node2D).global_position), zaratan.hand_position()])
			if attack == &"Rabbits" and tick % 3 == 0 and rabbit_shots < 36:
				var view2 := get_viewport().get_texture().get_image()
				var ratio2 := float(view2.get_width()) / 1920.0
				var center2 := zaratan.get_global_transform_with_canvas().origin * ratio2
				var crop2 := view2.get_region(Rect2i(Vector2i(center2 - Vector2(250, 440) * ratio2), Vector2i(Vector2(500, 480) * ratio2)).intersection(Rect2i(Vector2i.ZERO, view2.get_size())))
				if crop2.get_width() > 0:
					crop2.resize(200, 192)
					rabbit_grid.blit_rect(crop2, Rect2i(0, 0, 200, 192), Vector2i((rabbit_shots % 12) * 200, (rabbit_shots / 12) * 192))
					rabbit_shots += 1
			if tick % 6 == 0 and shots < 72:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := zaratan.get_global_transform_with_canvas().origin * ratio
				var box := Rect2i(Vector2i(center - Vector2(200, 420) * ratio), Vector2i(Vector2(400, 460) * ratio))
				var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(200, 260)
					grid.blit_rect(crop, Rect2i(0, 0, 200, 260), Vector2i((shots % 12) * 200, (shots / 12) * 260))
					shots += 1
	log.close()
	grid.save_png(_out.path_join("magico.png"))
	rabbit_grid.save_png(_out.path_join("magico_coelhos.png"))
	var hurt := (zaratan.hurtbox.get_child(0) as CollisionShape2D).shape as RectangleShape2D
	var hit := (zaratan.hitbox.get_child(0) as CollisionShape2D).shape as RectangleShape2D
	for line in card_lines:
		print("carta ", line)
	print("magico: trocas boneco→desenho %d, desenho→boneco %d; pés andando com o desenho %d quadros; facing com desenho %s; caixas %s e %s" % [
			to_art, to_puppet, foot_moves, facings.keys(), hurt.size, hit.size])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto do sumir (M5) e dos Coelhos dos dois lados (M4), rodar com --fixed-fps 60: a luta do Mágico de
## verdade com Coelhos (olhando para a esquerda, do lugar de início), Teleporte, Coelhos de novo (agora do
## outro lado, olhando para a direita), Teleporte e o Jogo das Três Caixas. Grava `sumir.csv` a cada quadro
## (ataque, pose, vanish, desenho, facing, pés, à vista, leva tiro) e imprime: a ordem dos desenhos do
## sumir em cada ida e volta, se os pés andaram com o desenho visível (vanish < 1), quantos quadros de
## `tap` em cada lado e as trocas para o boneco. Fotos: o Mágico a cada 2 quadros enquanto some e a cada 3
## nos Coelhos.
func _magician_vanish_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var zaratan: Magician = boss.get_node("Zaratan")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("sumir.csv"), FileAccess.WRITE)
	log.store_line("ataque;quadro;pose;vanish;arte;desenho;facing;pes_x;pes_y;leva_tiro")
	var tick := 0
	var orders := []
	var current: Array = []
	var tap_sides := {}
	var visible_moves := 0
	var to_puppet := 0
	var last_art := true
	var last_feet := zaratan.global_position
	var grid := Image.create(12 * 180, 8 * 220, false, Image.FORMAT_RGBA8)
	var shots := 0
	for attack in [&"Rabbits", &"Teleport", &"Rabbits", &"Teleport", &"ShellGame"]:
		boss.play_attack(attack, 4, 0.0, boss._args_for(attack))
		for f in 360:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			var art := zaratan.uses_art()
			var drawing := zaratan.art_frame() + 1 if art else 0
			log.store_line("%s;%d;%s;%.2f;%s;%d;%d;%.1f;%.1f;%s" % [attack, tick, zaratan.pose, zaratan.vanish, art, drawing, zaratan.facing,
					zaratan.global_position.x, zaratan.global_position.y, zaratan.hurtbox.monitorable])
			if zaratan.vanish > 0.0:
				if current.is_empty() or current.back() != drawing:
					current.append(drawing)
			elif not current.is_empty():
				orders.append("%s: %s" % [attack, current])
				current = []
			if zaratan.pose == &"tap":
				tap_sides[zaratan.facing] = int(tap_sides.get(zaratan.facing, 0)) + 1
			if zaratan.vanish < 1.0 and zaratan.global_position.distance_to(last_feet) > 0.5:
				visible_moves += 1
			if last_art and not art:
				to_puppet += 1
			last_art = art
			last_feet = zaratan.global_position
			var want := (zaratan.vanish > 0.0 and tick % 2 == 0) or (zaratan.pose == &"tap" and tick % 3 == 0)
			if want and shots < 96:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := zaratan.get_global_transform_with_canvas().origin * ratio
				var crop := view.get_region(Rect2i(Vector2i(center - Vector2(220, 440) * ratio), Vector2i(Vector2(440, 480) * ratio)).intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(180, 220)
					grid.blit_rect(crop, Rect2i(0, 0, 180, 220), Vector2i((shots % 12) * 180, (shots / 12) * 220))
					shots += 1
	log.close()
	grid.save_png(_out.path_join("sumir.png"))
	for line in orders:
		print("sumir ordem ", line)
	print("sumir: tap por lado %s; pés andando com ele à vista %d; trocas para o boneco %d" % [tap_sides, visible_moves, to_puppet])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto da reverência e do medo (M6), rodar com --fixed-fps 60: a luta do Mágico de verdade com a entrada
## da fase 2 (olhando para a esquerda), Teleporte, a entrada da fase 2 de novo (agora olhando para a
## direita), o Jogo das Três Caixas inteiro até ele reaparecer (sem ninguém abrir caixa), Teleporte, o Jogo
## das Três Caixas de novo e, no fim, a entrada da fase 3 (`-- magico_reverencia <pasta>`; com `virado`, ele é
## virado para a direita antes, à mão, porque na luta ele chega olhando para a esquerda, para ver o medo do
## outro lado) ou a derrota ainda pequeno (`fim`). Grava `reverencia.csv` a cada quadro (ataque, pose, vanish, desenho, facing, pés, alto do desenho) e imprime,
## por ataque, a sequência de desenhos com quantos quadros cada um, o maior salto do alto do desenho numa
## troca, os pés andando com ele à vista e as trocas para o boneco. Fotos: o Mágico a cada 3 quadros em
## reverência ou com medo, e a arena inteira no meio da reverência e do medo.
func _magician_bow_capture(ending: String) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var zaratan: Magician = boss.get_node("Zaratan")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("reverencia.csv"), FileAccess.WRITE)
	log.store_line("ataque;quadro;pose;vanish;desenho;facing;pes_x;pes_y;alto")
	var plan: Array = [[&"IntroSawing", 200], [&"Teleport", 120], [&"IntroSawing", 200], [&"ShellGame", 660],
			[&"Teleport", 120], [&"ShellGame", 660]]
	if ending == "virado":
		plan.append([&"Virar", 0])
	plan.append([&"Defeat", 160] if ending == "fim" else [&"IntroGiant", 170])
	var tops := {}
	var tick := 0
	var to_puppet := 0
	var visible_moves := 0
	var last_art := true
	var last_feet := zaratan.global_position
	var grid := Image.create(12 * 180, 8 * 220, false, Image.FORMAT_RGBA8)
	var shots := 0
	var arena := {}
	for step: Array in plan:
		var attack: StringName = step[0]
		if attack == &"Defeat":
			boss._on_defeated()
		elif attack == &"Virar":
			zaratan.facing = 1
			continue
		else:
			boss.play_attack(attack, 4, 0.0, boss._args_for(attack))
		var runs := []
		var worst_jump := 0.0
		var worst_at := ""
		var last_label := ""
		var last_top := NAN
		for f: int in step[1]:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			var art := zaratan.uses_art() and zaratan.visible
			var label := "escondido" if not zaratan.visible else ("boneco" if not art else _magician_label(zaratan))
			var top := NAN
			if art:
				var texture: Texture2D = zaratan._art.texture
				if not tops.has(texture):
					tops[texture] = texture.get_image().get_used_rect().position.y
				top = zaratan._art.position.y + float(tops[texture]) * zaratan._art.scale.y
			log.store_line("%s;%d;%s;%.2f;%s;%d;%.1f;%.1f;%.1f" % [attack, tick, zaratan.pose, zaratan.vanish, label, zaratan.facing,
					zaratan.global_position.x, zaratan.global_position.y, top])
			if runs.is_empty() or runs.back()[0] != label:
				runs.append([label, 1])
				if last_label != "" and not is_nan(top) and not is_nan(last_top) and absf(top - last_top) > worst_jump:
					worst_jump = absf(top - last_top)
					worst_at = "%s→%s" % [last_label, label]
			else:
				runs.back()[1] += 1
			last_label = label
			last_top = top
			if zaratan.vanish < 1.0 and zaratan.visible and zaratan.global_position.distance_to(last_feet) > 0.5:
				visible_moves += 1
			if last_art and not art and zaratan.visible:
				to_puppet += 1
			last_art = art
			last_feet = zaratan.global_position
			var posed := label.begins_with("rev") or label.begins_with("medo")
			if posed and tick % 3 == 0 and shots < 96:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := zaratan.get_global_transform_with_canvas().origin * ratio
				var crop := view.get_region(Rect2i(Vector2i(center - Vector2(240, 440) * ratio), Vector2i(Vector2(480, 480) * ratio)).intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(180, 220)
					grid.blit_rect(crop, Rect2i(0, 0, 180, 220), Vector2i((shots % 12) * 180, (shots / 12) * 220))
					shots += 1
			for want: String in ["rev2", "medo3"]:
				if label == want and not arena.has(want):
					arena[want] = true
					var full := get_viewport().get_texture().get_image()
					full.resize(960, 540)
					full.save_png(_out.path_join("arena_%s.png" % want))
		var text := []
		for run: Array in runs:
			text.append("%s×%d" % run)
		print("reverencia %s (facing %d): %s; maior salto do alto numa troca %.1f px (%s)" % [attack, zaratan.facing, ", ".join(text), worst_jump, worst_at])
	log.close()
	grid.save_png(_out.path_join("reverencia.png"))
	print("reverencia: pés andando com ele à vista %d quadros; trocas para o boneco %d" % [visible_moves, to_puppet])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Nome curto do desenho que o Mágico mostra agora (folha + número), para os pilotos.
func _magician_label(zaratan: Magician) -> String:
	var number := zaratan.art_frame() + 1
	if zaratan.vanish > 0.0:
		return "sumir%d" % number
	if zaratan._bow_settle > 0.0:
		return "rev1"
	match zaratan.pose:
		&"bow":
			return "rev%d" % number
		&"scared":
			return "medo%d" % number
		&"tap":
			return "cartola%d" % number
		&"idle":
			return "cartola4" if zaratan._tap_settle > 0.0 else "parado"
	return "varinha%d" % number


## Piloto das cartas que perseguem (marco de gameplay do Mágico), rodar com --fixed-fps 60:
## `-- magico_perseguidoras <pasta> <conjunto> <P1> <P2> [ataques]`. A luta do Mágico de verdade, com o Leque
## de Cartas repetido `ataques` vezes (sementes fixas 100, 101..., para comparar conjuntos) e os dois jogadores
## dirigidos por bots: `parado`, `anda` (vai e volta entre x 250 e 1000) ou `pula`, `dash` `dash_tras`, `dash_volta` ou `parry` (`parry` pula na rosa e dá parry nela;
## os outros pulam, ou dá dash
## para o lado de onde ela vem ou para longe dela; `dash_volta` atravessa e volta a pé para o lugar de início, quando a carta preta está a menos de ~0,3 s; o dash atravessa ataques). `conjunto`: A (480 px/s, 90°/s), B (560, 120°/s) ou C (640, 180°/s, janela de
## 1 s). Os jogadores não perdem vida (só se mede o contato com a área de dano). Grava `perseguidoras.csv`
## (uma linha por carta preta: salva, alvo, menor distância ao alvo, acertou o alvo, acertou o outro, giro
## total) e imprime os alvos na ordem, a taxa de acerto da preta por estratégia e os contatos das retas.
func _homing_capture(set_name: String, bots: Array, attacks: int) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: MagicianBoss = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var fan = boss.get_node("Attacks/CardFan")
	match set_name:
		"A":
			fan.homing_speed = 480.0
			fan.homing_turn = deg_to_rad(90.0)
		"C":
			fan.homing_speed = 640.0
			fan.homing_turn = deg_to_rad(180.0)
			fan.homing_delay = 0.15
			fan.homing_steps = 10
	var players: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
		player.input.scripted = true
		player.player_health._blink_timer = 1000000.0
		players.append(player)
	players.sort_custom(func(a: Player, b: Player) -> bool: return a.slot < b.slot)
	var home_x := [players[0].global_position.x, players[1].global_position.x]
	## Altura (px acima do chão, y 1000) de cada rosa quando passa por cima de um jogador.
	var pink_heights := []
	var parry_log := FileAccess.open(_out.path_join("parry.csv"), FileAccess.WRITE)
	parry_log.store_line("ataque;quadro;jogador;evento;dist_area_rosa;x;y;parries")
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("perseguidoras.csv"), FileAccess.WRITE)
	log.store_line("ataque;salva;alvo;estrategia_alvo;menor_dist;acertou_alvo;acertou_outro;giro_graus;parou")
	var order := []
	var stats := {}
	var straight_hits := [0, 0]
	var last_pos := {}
	var walk_dir := [1, -1]
	var jump_left := [0, 0]
	var shots := 0
	var grid := Image.create(6 * 480, 4 * 270, false, Image.FORMAT_RGBA8)
	for n in attacks:
		boss.sync.start_attack(&"CardFan", 100 + n, boss._args_for(&"CardFan"))
		var closest := {}
		var touched := {}
		# O ataque limpa as cartas no fim: guarda as pretas e os alvos durante o voo.
		var seen := {}
		var targets: Array = []
		for f in 290:
			await get_tree().physics_frame
			if fan.is_running():
				targets = fan.salvo_targets()
			for id: int in fan._homing:
				if not seen.has(id) and is_instance_valid(fan._homing[id].prop):
					seen[id] = [fan._homing[id], fan._homing[id].prop.get_instance_id()]
			var cards: Array[MagicProp] = []
			for child in fan.get_children():
				if child is MagicProp and child.kind == &"card" and child.visible:
					cards.append(child)
			for p in players.size():
				var me := players[p]
				me.input.jump_pressed = false
				me.input.dash_pressed = false
				me.input.move = Vector2.ZERO
				match bots[p]:
					"anda":
						if me.global_position.x < 250.0:
							walk_dir[p] = 1
						elif me.global_position.x > 1000.0:
							walk_dir[p] = -1
						me.input.move.x = walk_dir[p]
					"parry":
						var body := me.global_position + Vector2(0, -60)
						# Em cima de um trapézio as rosas baixas passam por baixo: desce (abaixar + dash), como um jogador faria.
						if me.is_on_floor() and me.global_position.y < 990.0:
							me.input.move.y = 1.0
							me.input.dash_pressed = f % 2 == 0
						for card in cards:
							if not card.pink or not card.active:
								continue
							var velocity: Vector2 = (card.global_position - last_pos.get(card.get_instance_id(), card.global_position)) * 60.0
							var gap_x := body.x - card.global_position.x
							if velocity.x == 0.0 or signf(velocity.x) != signf(gap_x):
								continue
							# Quando a rosa chega e a que altura dos pés (o jogador pode estar num trapézio): rosa baixa (na altura da cabeça) pede pulo curto e tarde;
							# rosa alta, pulo inteiro e mais cedo.
							var arrive := absf(gap_x) / absf(velocity.x)
							var height := me.global_position.y - (card.global_position.y + velocity.y * arrive)
							var low := height < 230.0
							if me.is_on_floor() and arrive < (0.2 if low else 0.42) and height > 60.0 and height < 420.0:
								me.input.jump_pressed = true
								jump_left[p] = 6 if low else 22
								parry_log.store_line("%d;%d;%d;pulo;%.1f;%.1f;%.1f;%d" % [n, f, p, height, me.global_position.x, me.global_position.y, me.applause.parries])
							elif not me.is_on_floor() and card.global_position.distance_to(me.global_position + Vector2(0, -85)) < 110.0:
								me.input.jump_pressed = true
								parry_log.store_line("%d;%d;%d;tentativa;%.1f;%.1f;%.1f;%d" % [n, f, p, card.global_position.distance_to((me.get_node("ParryArea/CollisionShape2D") as Node2D).global_position), me.global_position.x, me.global_position.y, me.applause.parries])
					"pula", "dash", "dash_tras", "dash_volta":
						if bots[p] == "dash_volta" and not me.is_dashing() and absf(me.global_position.x - home_x[p]) > 20.0:
							me.input.move.x = signf(home_x[p] - me.global_position.x)
						var center := me.global_position + Vector2(0, -60)
						for card in cards:
							if not card.homing:
								continue
							var id := card.get_instance_id()
							var velocity: Vector2 = (card.global_position - last_pos.get(id, card.global_position)) * 60.0
							var dx := center.x - card.global_position.x
							if velocity.x != 0.0 and signf(velocity.x) == signf(dx) and absf(dx) / absf(velocity.x) < 0.3 \
									and absf(center.y - card.global_position.y) < 150.0 and me.is_on_floor():
								if bots[p] != "pula":
									me.input.move.x = signf(dx) if bots[p] == "dash_tras" else -signf(dx)
									me.input.dash_pressed = true
								else:
									me.input.jump_pressed = true
									jump_left[p] = 22
				if jump_left[p] > 0:
					jump_left[p] -= 1
					me.input.jump_held = true
				else:
					me.input.jump_held = false
			for card in cards:
				if card.pink:
					for p in players.size():
						var key_pink := [card.get_instance_id(), p, "rosa"]
						if absf(card.global_position.x - players[p].global_position.x) < 14.0 and not touched.has(key_pink):
							touched[key_pink] = true
							pink_heights.append(roundi(1000.0 - card.global_position.y))
			for card in cards:
				last_pos[card.get_instance_id()] = card.global_position
				for p in players.size():
					var hurt: CollisionShape2D = players[p].hurt_shape
					var size: Vector2 = (hurt.shape as RectangleShape2D).size
					var rect := Rect2(hurt.global_position - size * 0.5, size)
					var nearest := card.global_position.clamp(rect.position, rect.end)
					var dist := nearest.distance_to(card.global_position)
					var key := [card.get_instance_id(), p]
					if card.homing:
						closest[key] = minf(closest.get(key, INF), dist)
					if dist <= card.radius() and not touched.has(key) and players[p]._can_be_hit():
						touched[key] = true
						if not card.homing:
							straight_hits[p] += 1
			if n == 0 and f in [40, 100]:
				get_viewport().get_texture().get_image().save_png(_out.path_join("perseguidoras_quadro_%d.png" % f))
			if f % 20 == 10 and shots < 24 and n < 2:
				var view := get_viewport().get_texture().get_image()
				view.resize(480, 270)
				grid.blit_rect(view, Rect2i(0, 0, 480, 270), Vector2i((shots % 6) * 480, (shots / 6) * 270))
				shots += 1
		for salvo in targets.size():
			var id: int = salvo * 10 + fan._homers[salvo]
			if not seen.has(id):
				continue
			var h: Dictionary = seen[id][0]
			var card_id: int = seen[id][1]
			var slot: int = targets[salvo]
			order.append("P%d" % (slot + 1) if slot >= 0 else "-")
			var turned := 0.0
			for turn: float in h.turns:
				turned += absf(turn) * MagicianAttack.STEER_STEP
			var hit_target := false
			var hit_other := false
			var nearest_target := INF
			for p in players.size():
				var key := [card_id, p]
				if p == slot:
					nearest_target = closest.get(key, INF)
					hit_target = touched.has(key)
				elif touched.has(key):
					hit_other = true
			var strategy: String = bots[slot] if slot >= 0 else "-"
			var entry: Array = stats.get(strategy, [0, 0])
			entry[0] += 1
			entry[1] += 1 if hit_target else 0
			stats[strategy] = entry
			log.store_line("%d;%d;%s;%s;%.1f;%s;%s;%.0f;%s" % [n, salvo, order.back(), strategy, nearest_target, hit_target, hit_other,
					rad_to_deg(turned), h.stopped])
	log.close()
	grid.save_png(_out.path_join("perseguidoras.png"))
	print("perseguidoras %s: alvos em ordem %s" % [set_name, " ".join(order)])
	for strategy in stats:
		print("perseguidoras %s: alvo %s, %d de %d pretas acertaram (%.0f%%)" % [set_name, strategy, stats[strategy][1], stats[strategy][0],
				100.0 * stats[strategy][1] / maxf(stats[strategy][0], 1.0)])
	print("perseguidoras %s: rosas passando pelos jogadores, altura acima do chão (y 1000): %s" % [set_name, pink_heights])
	print("perseguidoras %s: parries P1 %d, P2 %d" % [set_name, players[0].applause.parries, players[1].applause.parries])
	print("perseguidoras %s: contatos das retas P1 (%s) %d, P2 (%s) %d" % [set_name, bots[0], straight_hits[0], bots[1], straight_hits[1]])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto das Três Caixas (revisão do marco do Mágico), rodar com --fixed-fps 60: `-- magico_caixas <pasta>`.
## A luta de verdade com o Jogo das Três Caixas 4 vezes seguidas (sementes 11 a 14, sem ninguém abrir caixa;
## cada rodada começa onde a anterior terminou, então ele aparece olhando para os dois lados). Grava
## `caixas.csv` a cada quadro e imprime, por rodada: o lado, a sequência de desenhos, quanto ele andou com
## algo dele à vista (vanish < 1), o maior salto do alto do desenho numa troca, quais caixas abriram a tampa
## antes do embaralhar e se ele reapareceu na caixa certa (pela identidade do nó).
func _shell_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: MagicianBoss = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var zaratan: Magician = boss.zaratan
	var shell = boss.shell_game
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
		player.player_health._blink_timer = 1000000.0
	await seconds(1.5)
	var log := FileAccess.open(_out.path_join("caixas.csv"), FileAccess.WRITE)
	log.store_line("rodada;quadro;tempo;pose;vanish;desenho;facing;x;y;alto;tampas")
	var tops := {}
	var grid := Image.create(12 * 180, 8 * 220, false, Image.FORMAT_RGBA8)
	var shots := 0
	for n in 4:
		boss.sync.start_attack(&"ShellGame", 11 + n, boss._args_for(&"ShellGame"))
		var start_x := zaratan.global_position.x
		var start_facing := zaratan.facing
		var runs := []
		var walked := 0.0
		var worst_jump := 0.0
		var worst_at := ""
		var last_label := ""
		var last_top := NAN
		var last_pos := zaratan.global_position
		var opened_before := {}
		var right_box := true
		var frame := 0
		while shell.is_running() or frame == 0:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			frame += 1
			var art := zaratan.uses_art() and zaratan.visible and zaratan.vanish < 1.0
			var label := "invisivel" if not art else _magician_label(zaratan)
			var top := NAN
			if art:
				var texture: Texture2D = zaratan._art.texture
				if not tops.has(texture):
					tops[texture] = texture.get_image().get_used_rect().position.y
				top = zaratan._art.position.y + float(tops[texture]) * zaratan._art.scale.y
			var lids := ""
			for i in 3:
				lids += "%d" % i if boss.boxes[i].open > 0.5 else "-"
				if boss.boxes[i].open > 0.5 and shell.elapsed < shell.SHUFFLE:
					opened_before[i] = true
			log.store_line("%d;%d;%.3f;%s;%.2f;%s;%d;%.1f;%.1f;%.1f;%s" % [n, frame, shell.elapsed, zaratan.pose, zaratan.vanish, label,
					zaratan.facing, zaratan.global_position.x, zaratan.global_position.y, top, lids])
			if art and zaratan.global_position.distance_to(last_pos) > 0.5:
				walked += zaratan.global_position.distance_to(last_pos)
			last_pos = zaratan.global_position
			if runs.is_empty() or runs.back()[0] != label:
				runs.append([label, 1])
				if not is_nan(top) and not is_nan(last_top) and absf(top - last_top) > worst_jump:
					worst_jump = absf(top - last_top)
					worst_at = "%s→%s" % [last_label, label]
			else:
				runs.back()[1] += 1
			if shell._revealed and art:
				right_box = right_box and absf(zaratan.global_position.x - boss.boxes[shell.correct_box()].global_position.x) < 1.0
			last_label = label
			if not is_nan(top):
				last_top = top
			if art and frame % 3 == 0 and shots < 96:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := zaratan.get_global_transform_with_canvas().origin * ratio
				var crop := view.get_region(Rect2i(Vector2i(center - Vector2(240, 440) * ratio), Vector2i(Vector2(480, 480) * ratio)).intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(180, 220)
					grid.blit_rect(crop, Rect2i(0, 0, 180, 220), Vector2i((shots % 12) * 180, (shots / 12) * 220))
					shots += 1
			if frame == 20 and n < 2:
				var full := get_viewport().get_texture().get_image()
				full.resize(960, 540)
				full.save_png(_out.path_join("caixas_tampa_rodada%d.png" % n))
		var text := []
		for run: Array in runs:
			text.append("%s×%d" % run)
		print("caixas %d: começa em x %.0f olhando %d, entra na caixa %d; tampas abertas antes do embaralhar %s; andou à vista %.1f px; maior salto do alto %.1f px (%s); reapareceu na caixa certa %s" % [
				n, start_x, start_facing, shell.correct_box(), opened_before.keys(), walked, worst_jump, worst_at, right_box])
		print("caixas %d: %s" % [n, ", ".join(text)])
	log.close()
	grid.save_png(_out.path_join("caixas.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto das mãos gigantes (M7), rodar com --fixed-fps 60: `-- magico_maos <pasta>`. A luta do Mágico de
## verdade levada à fase 3 pelo dano (entrada do gigante: as mãos surgem do escuro), depois Mãos que Agarram
## duas vezes e Cartas Gigantes. Grava `maos.csv` a cada quadro (ataque, mão, closed, desenho, golpe ligado,
## posição, presence) e imprime, por ataque e por mão, a sequência de desenhos com quantos quadros cada um, se
## o golpe ligou fora dos desenhos 3 e 4, quanto da área de dano acima do chão caiu no desenho nos quadros de
## golpe e se o espelho bate com o lado. Fotos: as duas mãos a cada 4 quadros e a arena no golpe.
func _hands_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: MagicianBoss = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
		player.player_health._blink_timer = 1000000.0
	await seconds(1.0)
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(3.5)
	boss._wait = 100000.0
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	var log := FileAccess.open(_out.path_join("maos.csv"), FileAccess.WRITE)
	log.store_line("ataque;quadro;mao;closed;desenho;golpe;x;y;presence;espelho")
	var hands: Array[GiantHand] = [boss.left_hand, boss.right_hand]
	var images := {}
	var grid := Image.create(12 * 240, 8 * 200, false, Image.FORMAT_RGBA8)
	var shots := 0
	var arena_saved := false
	var tick := 0
	for step: Array in [[&"IntroGiant", 175], [&"GrabHands", 230], [&"GrabHands", 230], [&"GiantCards", 400]]:
		var attack: StringName = step[0]
		if attack != &"IntroGiant":
			boss.sync.start_attack(attack, 70 + tick, boss._args_for(attack))
		var runs := [[], []]
		var hit_wrong := [0, 0]
		var cover := [[], []]
		var mirror_ok := [true, true]
		for f: int in step[1]:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			for h in 2:
				var hand := hands[h]
				var frame := hand.art_frame()
				var label := "%d" % (frame + 1)
				var mirrored: bool = hand._art_holder.scale.x < 0.0
				mirror_ok[h] = mirror_ok[h] and mirrored == (hand.side > 0.0)
				if runs[h].is_empty() or runs[h].back()[0] != label:
					runs[h].append([label, 1])
				else:
					runs[h].back()[1] += 1
				if hand.hitbox.active and frame < 2:
					hit_wrong[h] += 1
				if hand.hitbox.active:
					cover[h].append(_hand_cover(hand, images))
				log.store_line("%s;%d;%d;%.2f;%d;%s;%.1f;%.1f;%.2f;%s" % [attack, tick, h, hand.closed, frame + 1, hand.hitbox.active,
						hand.global_position.x, hand.global_position.y, hand.presence, mirrored])
			if tick % 4 == 0 and shots < 96:
				var view := get_viewport().get_texture().get_image()
				view.resize(240, 135)
				grid.blit_rect(view, Rect2i(0, 0, 240, 135), Vector2i((shots % 12) * 240, (shots / 12) * 200))
				shots += 1
			if not arena_saved and attack == &"GrabHands" and (boss.left_hand.hitbox.active or boss.right_hand.hitbox.active):
				arena_saved = true
				get_viewport().get_texture().get_image().save_png(_out.path_join("maos_golpe.png"))
		for h in 2:
			var text := []
			for run: Array in runs[h]:
				text.append("%s×%d" % run)
			var mean := 0.0
			for value: float in cover[h]:
				mean += value
			var least := 100.0
			for value: float in cover[h]:
				least = minf(least, value)
			print("maos %s, %s: %s; golpe fora dos desenhos 3-4: %d quadros; área de dano acima do chão no desenho: média %.0f%%, mínimo %.0f%% (%d quadros de golpe); espelho certo %s" % [
					attack, "esquerda" if h == 0 else "direita", ", ".join(text), hit_wrong[h], mean / maxf(cover[h].size(), 1),
					least if not cover[h].is_empty() else 0.0, cover[h].size(), mirror_ok[h]])
	log.close()
	grid.save_png(_out.path_join("maos.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Porcentagem da área de dano da mão (só a parte acima do chão, y < 1000) que cai em pixels do desenho.
func _hand_cover(hand: GiantHand, images: Dictionary) -> float:
	var texture: Texture2D = hand._art.texture
	if not images.has(texture):
		images[texture] = texture.get_image()
	var img: Image = images[texture]
	var shape := hand.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	var size: Vector2 = (shape.shape as RectangleShape2D).size
	var center := shape.global_position
	var to_art := hand._art.get_global_transform().affine_inverse()
	var inside := 0
	var total := 0
	for y in range(int(center.y - size.y / 2.0), int(minf(center.y + size.y / 2.0, 1000.0)), 4):
		for x in range(int(center.x - size.x / 2.0), int(center.x + size.x / 2.0), 4):
			total += 1
			var p := to_art * Vector2(x, y)
			if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and img.get_pixel(int(p.x), int(p.y)).a > 0.5:
				inside += 1
	return 100.0 * inside / maxf(total, 1)


## Piloto do rosto gigante (M8), rodar com --fixed-fps 60: `-- magico_rosto <pasta>`. A luta do Mágico de
## verdade levada à fase 3 (entrada do gigante), Mãos que Agarram, Cartola Despejando e Cartas Gigantes, com
## tiros na cabeça (1 a cada 0,2 s durante as Cartas Gigantes, pelo Hurtbox de verdade) e, no fim, a derrota
## (encolhe para dentro da cartola). Grava `rosto.csv` a cada quadro e imprime, por trecho, a sequência de
## desenhos com quantos quadros cada um, quantas vezes ficou bravo, o giro da cartola e se a cartola seguiu a
## cabeça (a aba 170 px acima do meio da cabeça, na escala do encolher). Fotos: o gigante a cada 4 quadros.
func _face_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: MagicianBoss = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
		player.player_health._blink_timer = 1000000.0
	await seconds(1.0)
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(3.5)
	boss._wait = 100000.0
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	var giant: GiantMagician = boss.giant
	var log := FileAccess.open(_out.path_join("rosto.csv"), FileAccess.WRITE)
	log.store_line("trecho;quadro;desenho;laugh;shrink;hat_tilt;cabeca_y;aba_x;aba_y;visivel")
	var grid := Image.create(12 * 240, 8 * 200, false, Image.FORMAT_RGBA8)
	var shots := 0
	var tick := 0
	for step: Array in [[&"IntroGiant", 175], [&"GrabHands", 230], [&"HatPour", 300], [&"GiantCards", 300], [&"Derrota", 150]]:
		var part: StringName = step[0]
		if part == &"Derrota":
			boss.apply_damage(boss.health.current)
		elif part != &"IntroGiant":
			boss.sync.start_attack(part, 90 + tick, boss._args_for(part))
		var runs := []
		var angry_count := 0
		var last_frame := -1
		var max_tilt := 0.0
		var hat_off := 0.0
		for f: int in step[1]:
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			if part == &"GiantCards" and f % 12 == 0:
				giant.hurtbox.take_hit(1, "Player_1")
			var frame := giant.face_frame()
			if frame == 2 and last_frame != 2:
				angry_count += 1
			last_frame = frame
			var label := "%d" % (frame + 1) if giant._face_holder.visible else "-"
			if runs.is_empty() or runs.back()[0] != label:
				runs.append([label, 1])
			else:
				runs.back()[1] += 1
			max_tilt = maxf(max_tilt, absf(giant.hat_tilt))
			var expected := giant._face_holder.position + Vector2(0, -170) * giant._face_holder.scale.x
			hat_off = maxf(hat_off, giant._hat_holder.position.distance_to(expected))
			log.store_line("%s;%d;%d;%.2f;%.2f;%.2f;%.1f;%.1f;%.1f;%s" % [part, tick, frame + 1, giant.laugh, giant.shrink, giant.hat_tilt,
					giant._face_holder.position.y, giant._hat_holder.position.x, giant._hat_holder.position.y, giant._face_holder.visible])
			if tick % 4 == 0 and shots < 96:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := giant.get_global_transform_with_canvas().origin * ratio
				var crop := view.get_region(Rect2i(Vector2i(center - Vector2(300, 520) * ratio), Vector2i(Vector2(600, 860) * ratio)).intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(240, 200)
					grid.blit_rect(crop, Rect2i(0, 0, 240, 200), Vector2i((shots % 12) * 240, (shots / 12) * 200))
					shots += 1
			if part == &"HatPour" and f == 120:
				get_viewport().get_texture().get_image().save_png(_out.path_join("rosto_cartola.png"))
		var text := []
		for run: Array in runs:
			text.append("%s×%d" % run)
		print("rosto %s: %s; bravo %d vez(es); giro máximo da cartola %.2f rad; cartola fora do lugar até %.2f px" % [part, ", ".join(text), angry_count, max_tilt, hat_off])
	log.close()
	grid.save_png(_out.path_join("rosto.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Chicote de medo do Domador (fases 2 e 3, 04/10/2026): leva a luta à fase 2 e fotografa, nos dois lados,
## o chicote erguido (aviso) e o estalo, com a área do golpe em vermelho e a do corpo em amarelo.
## Rodar com --fixed-fps 60: `-- domador_chicote <pasta>`.
func _tamer_fear_lash_capture() -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: TamerBoss = scene.get_node("TamerBoss")
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
	await seconds(3.5)
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(4.0)
	boss._wait = 100000.0
	var tamer := boss.tamer
	var strip := Image.create(4 * 480, 400, false, Image.FORMAT_RGBA8)
	var shots := 0
	var prev := 0.0
	for f in 480:
		await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var key := ""
		if tamer.whip_pose >= 0.95 and tamer.whip_pose < 1.5 and prev < 0.95:
			key = "erguido"
		elif tamer.is_lashing() and prev < 1.5:
			key = "estalo"
		prev = tamer.whip_pose
		if key == "" or shots >= 4:
			continue
		var view := get_viewport().get_texture().get_image()
		var ratio := float(view.get_width()) / 1920.0
		for area: Array in [[tamer.lash_hitbox(), Color(1, 0, 0)], [tamer.hitbox, Color(1, 1, 0)]]:
			if area[0] == tamer.lash_hitbox() and not tamer.is_lashing():
				continue
			var shape_node := (area[0] as Node).get_child(0) as CollisionShape2D
			var size: Vector2 = (shape_node.shape as RectangleShape2D).size
			var a := shape_node.get_global_transform_with_canvas() * (-size / 2.0) * ratio
			var b := shape_node.get_global_transform_with_canvas() * (size / 2.0) * ratio
			var rect := Rect2i(Rect2(a, Vector2.ZERO).expand(b))
			for x in range(rect.position.x, rect.end.x):
				for y in [rect.position.y, rect.end.y - 1]:
					if x >= 0 and x < view.get_width() and y >= 0 and y < view.get_height():
						view.set_pixel(x, y, area[1])
			for y in range(rect.position.y, rect.end.y):
				for x in [rect.position.x, rect.end.x - 1]:
					if x >= 0 and x < view.get_width() and y >= 0 and y < view.get_height():
						view.set_pixel(x, y, area[1])
		var center := tamer.get_global_transform_with_canvas().origin * ratio
		var box := Rect2i(Vector2i(center - Vector2(240, 300) * ratio), Vector2i(Vector2(480, 400) * ratio))
		var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
		crop.resize(480, 400)
		strip.blit_rect(crop, Rect2i(0, 0, 480, 400), Vector2i(shots * 480, 0))
		print("foto %d: %s, lado %d" % [shots, key, int(tamer.lash_side())])
		shots += 1
	strip.save_png(_out.path_join("domador_chicote.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()


## Piloto do TOTEM desenhado (E7), rodar com --fixed-fps 60: `-- malabaristas_totem <pasta> [teco]` ("teco": o
## Teco fica embaixo, com a folha de cores trocadas). A luta de verdade, com os ataques pelo cérebro: a entrada
## do totem, 1 s parado, o Totem Andante com o 1º jogador parado em cima da tábua pendurada por onde o totem
## passa (sem invencibilidade), as Claves em Linha, o Boliche, o tonto no totem com a bola de cura e a saída
## para o monociclo. Grava `totem.csv` a cada quadro e imprime, por trecho: a sequência de desenhos, o desenho
## em cada objeto novo, a distância da mão à clave quando ela nasce, a distância da bola de cura à cabeça, o
## topo do desenho e das áreas e se o jogador da tábua levou dano. Fotos: o totem a cada 3 quadros e a arena
## com o totem passando por baixo da tábua.
func _jugglers_totem_capture(teco_base: bool) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: JugglersBoss = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var players: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 100000.0
		players.append(player)
	await seconds(1.5)
	if teco_base:
		boss.tico.global_position = JugglersBoss.HOME_RIGHT
		boss.teco.global_position = JugglersBoss.HOME_LEFT
		boss.tico.facing = -1
		boss.teco.facing = 1
	# Fase 2 de verdade (os dois no limite): a entrada do totem pelo cérebro.
	boss.apply_damage(1000, "", "Tico")
	boss.apply_damage(1000, "", "Teco")
	var log := FileAccess.open(_out.path_join("totem.csv"), FileAccess.WRITE)
	log.store_line("trecho;quadro;base;desenho;base_x;base_y;topo_x;topo_y;topo_dano_y;topo_tiro_y;cabeca_cima_x;cabeca_cima_y;jogador_vida")
	var grid := Image.create(12 * 160, 12 * 200, false, Image.FORMAT_RGBA8)
	var shots := 0
	var tick := 0
	var platform := scene.get_node("PlatformRight") as Node2D
	var board_bottom := platform.global_position.y + 12.0
	var arena_saved := false
	var stages := [[&"IntroTotem", 0], [&"", 60], [&"TotemWalk", 0], [&"ClubVolley", 0], [&"Bowling", 0], [&"Tonto", 300], [&"IntroUnicycle", 0]]
	for stage: Array in stages:
		var part: StringName = stage[0]
		var attack: BossAttack = null
		if part != &"" and part != &"Tonto":
			attack = boss.get_node("Attacks/%s" % part)
		var on_board: Player = null
		if part == &"TotemWalk":
			on_board = players[0]
			on_board.player_health._invincible_timer = 0.0
			on_board.visual.visible = true
			on_board.player_health.health.current = on_board.player_health.health.maximum
		if part == &"Tonto":
			boss.apply_damage(1000, "", boss.base_name)
		if attack != null and part != &"IntroTotem":
			boss.sync.start_attack(part, 40 + tick, boss._args_for(part))
		var runs := []
		var releases := []
		var hand_gaps: Array[float] = []
		var heal_gap := -1.0
		var hp_before := on_board.player_health.health.current if on_board != null else 0
		var top_hit_min := 99999.0
		var art_top_min := 99999.0
		var known := {}
		var frames: int = stage[1] if stage[1] > 0 else 600
		var started := false
		for f in frames:
			if on_board != null:
				on_board.global_position = Vector2(platform.global_position.x, platform.global_position.y - 13.0)
				on_board.velocity = Vector2.ZERO
			await get_tree().physics_frame
			await RenderingServer.frame_post_draw
			tick += 1
			if attack != null:
				started = started or attack.is_running()
				if started and not attack.is_running():
					break
			var base := boss.base()
			var top := boss.top()
			var frame := base.totem_frame() if base._totem_art() else -1
			var label := "%d" % (frame + 1) if frame >= 0 else ("giro" if base.spin != 0.0 or top.spin != 0.0 else String(base.pose))
			if runs.is_empty() or runs.back()[0] != label:
				runs.append([label, 1])
			else:
				runs.back()[1] += 1
			if attack != null:
				for child in attack.get_children():
					if child is JugglerProp and not known.has(child.get_instance_id()):
						known[child.get_instance_id()] = true
						releases.append(label)
						if frame >= 0 and part != &"Bowling":
							hand_gaps.append((child as Node2D).global_position.distance_to(top.hand_position()))
			if part == &"Tonto" and boss._heal != null:
				heal_gap = boss._heal.global_position.distance_to(boss.brother(boss._heal_to).head_position())
			var top_hit := top.hitbox.get_child(0) as CollisionShape2D
			var top_hurt := top.hurtbox.get_child(0) as CollisionShape2D
			var hit_top_y := top_hit.global_position.y - (top_hit.shape as RectangleShape2D).size.y * 0.5
			var hurt_top_y := top_hurt.global_position.y - (top_hurt.shape as RectangleShape2D).size.y * 0.5
			if frame >= 0:
				top_hit_min = minf(top_hit_min, hit_top_y)
				var tex: Texture2D = base._art.texture
				# Escala e posição locais (com o espelho, a escala global sai negativa em y).
				var art_top := base.global_position.y + base._art.position.y + tex.get_image().get_used_rect().position.y * absf(base._art.scale.y)
				art_top_min = minf(art_top_min, art_top)
			var head_top := top.head_position()
			log.store_line("%s;%d;%s;%s;%.1f;%.1f;%.1f;%.1f;%.1f;%.1f;%.1f;%.1f;%d" % [part, tick, base.name, label, base.global_position.x,
					base.global_position.y, top.global_position.x, top.global_position.y, hit_top_y, hurt_top_y, head_top.x, head_top.y,
					on_board.player_health.health.current if on_board != null else -1])
			if tick % 3 == 0 and shots < 144:
				var view := get_viewport().get_texture().get_image()
				var ratio := float(view.get_width()) / 1920.0
				var center := base.get_global_transform_with_canvas().origin * ratio
				var box := Rect2i(Vector2i(center - Vector2(240, 340) * ratio), Vector2i(Vector2(480, 400) * ratio))
				var crop := view.get_region(box.intersection(Rect2i(Vector2i.ZERO, view.get_size())))
				if crop.get_width() > 0:
					crop.resize(160, 200)
					grid.blit_rect(crop, Rect2i(0, 0, 160, 200), Vector2i((shots % 12) * 160, (shots / 12) * 200))
					shots += 1
			if part == &"TotemWalk" and not arena_saved and absf(base.global_position.x - platform.global_position.x) < 20.0:
				arena_saved = true
				get_viewport().get_texture().get_image().save_png(_out.path_join("totem_tabua%s.png" % ("_teco" if teco_base else "")))
		var text := []
		for run: Array in runs:
			text.append("%s×%d" % run)
		var line := "totem %s (base %s): %s" % [part if part != &"" else &"parado", boss.base_name, ", ".join(text)]
		if not releases.is_empty():
			line += "; desenho em cada objeto novo %s" % [releases]
		if not hand_gaps.is_empty():
			line += "; mão→clave ao nascer até %.1f px" % hand_gaps.max()
		if heal_gap >= 0.0:
			line += "; bola de cura→cabeça no último quadro %.1f px" % heal_gap
		if top_hit_min < 99999.0:
			line += "; topo do desenho y %.1f, topo da área de dano y %.1f (fundo da tábua %.1f)" % [art_top_min, top_hit_min, board_bottom]
		if on_board != null:
			line += "; jogador na tábua: vida %d -> %d" % [hp_before, on_board.player_health.health.current]
			on_board.player_health._invincible_timer = 100000.0
		print(line)
	log.close()
	grid.save_png(_out.path_join("totem%s.png" % ("_teco" if teco_base else "")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()

