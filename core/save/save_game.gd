extends Node
## Save do jogo (autoload "SaveGame"), um arquivo JSON no PC de quem hospeda (ou de quem
## joga sozinho): chefões vencidos com a melhor nota e o melhor tempo, área atual, e a
## carteira de ingressos, os itens e o equipamento de cada jogador.
## Salva sozinho ao vencer um chefão e ao voltar para o mapa.
## O cliente online não salva nada: o save é do host, que manda uma cópia para o cliente mostrar
## (notas no mapa, ingressos).

## O save mudou (compra, doação, equipamento ou cópia nova vinda do host).
signal changed

const VERSION := 1
## Ingressos, para cada jogador.
const TICKETS_FIRST_WIN := 3
const TICKETS_FIRST_A := 1
const TICKETS_FIRST_S := 1
## Cada jogador é guardado pelo personagem (palhaço = jogador 1, acrobata = jogador 2).
const PLAYER_KEYS := ["clown", "acrobat"]

## Dois saves para cada jeito de jogar (pedido do usuário em 06/10/2026): o de dupla (no PC de quem hospeda) e o
## de jogar sozinho, cada um com a opção de continuar ou começar do zero. O save 1 de cada jeito é o arquivo que
## já existia antes (save.json e save_solo.json).
const SLOT_FILES := {
	"coop": ["save.json", "save_coop_2.json"],
	"solo": ["save_solo.json", "save_solo_2.json"],
}
const SLOT_COUNT := 2
## Modo de teste (05/10/2026; guardado sem botão desde 06/10/2026, ver MainMenu.SHOW_TEST_MODE): save à parte,
## todas as atrações abertas, ingressos de sobra, muita vida nas lutas e o especial sempre cheio.
const TEST_PATH := "user://test_save.json"
const TEST_TICKETS := 999
## Gravação segura (16/10/2026): o save novo é escrito inteiro em "<save>.tmp" e só depois troca de nome com o
## save; o anterior fica guardado em "<save>.bak". Antes o arquivo era apagado e reescrito no lugar, e fechar o
## jogo nesse instante (queda de luz, Android encerrando o app) deixava o save vazio, que virava jogo novo.
const TMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

## Os testes trocam o caminho para não mexer no save de verdade.
var path := "user://save.json"
## Pasta dos saves (os testes trocam para não mexer nos saves de verdade).
var slot_folder := "user://"
var test_mode := false
var data := {}
## Cópia que veio do host (cliente online): nunca é gravada no disco.
var _borrowed := false


func _ready() -> void:
	load_game()
	Network.peer_ready.connect(_on_peer_ready)
	# O host manda a cópia assim que o parceiro conecta, antes da ordem de carregar a fase:
	# assim os jogadores dele já nascem com o equipamento certo.
	Network.partner_connected.connect(_on_peer_ready)


func load_game() -> void:
	_borrowed = false
	data = _new_game()
	var loaded := _read_save(path)
	if not loaded.is_empty():
		_merge(data, loaded)


func save_game() -> void:
	if _borrowed:
		return
	if not _write_save(path, JSON.stringify(data, "\t")):
		push_warning("Não consegui salvar em %s" % path)


## Arquivo de um save (`mode` = "coop" ou "solo", `slot` = 0 ou 1).
func slot_path(mode: String, slot: int) -> String:
	return slot_folder + SLOT_FILES[mode][slot]


## Resumo de um save para o menu: {"exists", "done" (atrações concluídas)}.
func slot_info(mode: String, slot: int) -> Dictionary:
	var info := {"exists": false, "done": 0}
	var loaded := _read_save(slot_path(mode, slot))
	if loaded.is_empty():
		return info
	info.exists = true
	for entry: Variant in loaded.get("bosses", {}).values():
		if entry is Dictionary and entry.get("defeated", false):
			info.done += 1
	return info


## Troca para um save; com `fresh`, apaga o progresso dele e começa do zero.
func use_slot(mode: String, slot: int, fresh := false) -> void:
	_switch_to(slot_path(mode, slot))
	if fresh:
		reset()


## Modo de teste: troca para o save de teste e enche as carteiras.
func use_test() -> void:
	_switch_to(TEST_PATH)
	test_mode = true
	for key in PLAYER_KEYS:
		data.players[key].tickets = maxi(int(data.players[key].tickets), TEST_TICKETS)
		# Tudo no máximo: todos os itens da loja já comprados (só escolher no camarim).
		for item_id: String in Catalog.items():
			if not data.players[key].items.has(item_id):
				data.players[key].items.append(item_id)
	save_game()


func _switch_to(new_path: String) -> void:
	test_mode = false
	path = new_path
	load_game()
	changed.emit()


## Quem guarda o save nesta partida: o host, ou o jogo sozinho.
func is_keeper() -> bool:
	return not Network.is_online() or Network.is_host()


## Vitória contra um chefão: atualiza recordes, dá ingressos aos dois e salva.
## Retorna o que mudou, para a tela de fim mostrar: {"tickets", "first_win", "best_grade", "best_time"}.
func record_victory(boss_id: String, grade: String, time: float) -> Dictionary:
	var boss: Dictionary = data.bosses.get(boss_id, {"defeated": false, "best_grade": "", "best_time": 0.0})
	var tickets := 0
	var first_win: bool = not boss.defeated
	if first_win:
		tickets += TICKETS_FIRST_WIN
	var old_rank := FightGrade.rank(boss.best_grade)
	var new_rank := FightGrade.rank(grade)
	if new_rank >= FightGrade.rank("A") and old_rank < FightGrade.rank("A"):
		tickets += TICKETS_FIRST_A
	if new_rank >= FightGrade.rank("S") and old_rank < FightGrade.rank("S"):
		tickets += TICKETS_FIRST_S
	var best_grade := new_rank > old_rank
	var best_time: bool = first_win or time < boss.best_time
	boss.defeated = true
	if best_grade:
		boss.best_grade = grade
	if best_time:
		boss.best_time = time
	data.bosses[boss_id] = boss
	for key in PLAYER_KEYS:
		data.players[key].tickets += tickets
	if is_keeper():
		save_game()
		share()
	return {"tickets": tickets, "first_win": first_win, "best_grade": best_grade, "best_time": best_time}


## Fase de plataforma concluída (conta como "vencida" para os cadeados do mapa) e salva.
## Retorna {"first_win"}.
func record_level(level_id: String) -> Dictionary:
	var first_win := not is_defeated(level_id)
	var level: Dictionary = data.bosses.get(level_id, {"defeated": false, "best_grade": "", "best_time": 0.0})
	level.defeated = true
	data.bosses[level_id] = level
	if is_keeper():
		save_game()
		share()
	return {"first_win": first_win}


## Ingresso escondido achado numa fase. Na primeira vez, +1 para cada jogador. Retorna se era novo.
func record_ticket(ticket_id: String) -> bool:
	var found: Array = data.get("found_tickets", [])
	if ticket_id in found:
		return false
	found.append(ticket_id)
	data.found_tickets = found
	for key in PLAYER_KEYS:
		data.players[key].tickets += 1
	if is_keeper():
		save_game()
		share()
	return true


func has_ticket(ticket_id: String) -> bool:
	return ticket_id in data.get("found_tickets", [])


func is_defeated(boss_id: String) -> bool:
	return data.bosses.get(boss_id, {}).get("defeated", false)


## Host: manda a cópia do save para o parceiro.
func share() -> void:
	if Network.is_online() and Network.is_host():
		for peer_id in Network.ready_peers:
			_receive_data.rpc_id(peer_id, data)


func _on_peer_ready(peer_id: int) -> void:
	if Network.is_host():
		_receive_data.rpc_id(peer_id, data)


@rpc("authority", "call_remote", "reliable")
func _receive_data(value: Dictionary) -> void:
	data = value
	_borrowed = true
	changed.emit()


## Apaga o progresso (começar do zero).
func reset() -> void:
	data = _new_game()
	save_game()


static func _new_game() -> Dictionary:
	var players := {}
	for key in PLAYER_KEYS:
		players[key] = {
			"tickets": 0,
			# Itens iniciais: pistola Rolha e truque Cambalhota.
			"items": ["cork_gun", "tumble"],
			"equipped": {"gun": "cork_gun", "trick": "tumble", "prop": "", "duo": ""},
		}
	# solo_character: com quem se joga sozinho (0 = palhaço, 1 = acrobata; Tab no mapa troca).
	return {"version": VERSION, "area": 1, "bosses": {}, "found_tickets": [], "players": players, "solo_character": 0}


## Lê um save: o próprio arquivo; se ele não abrir, o .tmp de uma gravação interrompida (no Windows, a troca de
## nome apaga o save um instante antes de pôr o novo); e, se o arquivo existe mas estragou (ex.: faltou luz logo
## depois de gravar), a cópia anterior. Save apagado continua apagado. Vazio se nada servir.
static func _read_save(save_path: String) -> Dictionary:
	var loaded := _parse_save(save_path)
	if loaded.is_empty():
		loaded = _parse_save(save_path + TMP_SUFFIX)
	if loaded.is_empty() and FileAccess.file_exists(save_path):
		loaded = _parse_save(save_path + BACKUP_SUFFIX)
	return loaded


## Um arquivo de save inteiro e desta versão, ou vazio.
static func _parse_save(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	var loaded: Variant = json.data
	if loaded is Dictionary and loaded.get("version", 0) == VERSION:
		return loaded
	return {}


## Grava sem nunca deixar o save pela metade: escreve tudo no .tmp, guarda o save atual (se ele abre) no .bak e
## só então troca o .tmp pelo save. Retorna se gravou.
static func _write_save(save_path: String, text: String) -> bool:
	var tmp_path := save_path + TMP_SUFFIX
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written:
		return false
	if not _parse_save(save_path).is_empty():
		DirAccess.copy_absolute(save_path, save_path + BACKUP_SUFFIX)
	return DirAccess.rename_absolute(tmp_path, save_path) == OK


## Copia o que veio do arquivo por cima do jogo novo (campos novos ganham o valor padrão).
static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge(target[key], source[key])
		else:
			target[key] = source[key]
