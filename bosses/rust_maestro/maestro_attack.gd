extends BossAttack
## Ataques do Maestro no mesmo relógio nos dois PCs: cada perigo é função do tempo desde o começo do ataque e
## da semente, sem decisões locais. Tudo é contado em tempos do compasso (RustMaestroBoss.BEAT).
## Nos combos, o segundo perigo começa um tempo depois do primeiro (como os 0,6 s da Madame).
## Na fase 3, toda "música" termina com a reverência: a caixa de música do peito abre (ponto fraco).

enum Pattern { STAFF, BATON, METRONOME, WAVES, EIGHTHS, PIPES, STAFF_WAVES, STAFF_EIGHTHS, BATON_WAVES,
	INTRO_ORGAN, INTRO_FINALE }

const B := RustMaestroBoss.BEAT
## Duração de cada padrão, em tempos (sem a reverência da fase 3).
const BEATS := [11, 9, 9, 10, 7, 8, 12, 11, 12, 4, 4]
## Reverência no fim de cada ataque da fase 3, em tempos; a caixa abre dentro dela.
const BOW_BEATS := 4
const BOW_OPEN := Vector2(0.3, 2.2)
## Faixas da pauta (y do centro da nota): chão (pular), meio (abaixar ou pular) e alto (só pega quem pula).
enum Lane { LOW, MID, HIGH }
const LANES := [895.0, 800.0, 640.0]
## Velocidade das notas, ondas e lâminas (iguais: nos combos, a distância entre elas não muda).
const SPEED := 780.0
## Fase 3 (Fortíssimo): tudo um pouco mais rápido; os avisos continuam do mesmo tamanho.
const FAST := 1.12
## Onde notas, ondas e lâminas nascem (a parede do jogador fica em 1500).
const SPAWN_X := 1490.0
const FLOOR := 930.0
const LEFT_OUT := -90.0
## Metrônomo: pivô no teto, comprimento até o peso e abertura do balanço.
const PENDULUM_PIVOT := Vector2(760, -60)
const PENDULUM_LENGTH := 950.0
const PENDULUM_SWING := 0.785
## Tempo de queda das colcheias até o chão (o aviso dura o resto dos dois tempos).
const EIGHTH_FALL := 0.3

@export var pattern := Pattern.STAFF

var boss: RustMaestroBoss
var actor: MaestroActor
var targets: Array[Vector2] = []
## Notas da pauta: [tempo em que sai, faixa, é de parry].
var notes: Array = []
## Lado para onde a segunda colcheia/tubo de cada alvo vai (+1 ou -1) e quanto.
var shifts: Array[float] = []
var _speed := SPEED
var _duration := 0.0
var _bows := false
var _props := {}
var _warnings: Array[Dictionary] = []
var _staff_glow := 0.0
var _rod := Vector2.INF


func _ready() -> void:
	boss = get_parent().get_parent()


func _on_begin() -> void:
	actor = boss.get_node("Actor")
	targets.clear()
	for target in args:
		if target is Vector2:
			targets.append(target)
	if targets.is_empty():
		targets.append(Vector2(700, 875))
	_speed = SPEED * (FAST if boss.phase == 2 else 1.0)
	_bows = boss.phase == 2 and pattern < Pattern.INTRO_ORGAN
	_duration = (BEATS[pattern] + (BOW_BEATS if _bows else 0)) * B
	shifts.clear()
	for i in 4:
		shifts.append((1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(190.0, 260.0))
	notes = _build_notes()
	_tick(0.0)


## Partitura sorteada pela semente (igual nos dois PCs). Garante as três faixas na pauta simples, para que
## ninguém fique parado num ponto seguro.
func _build_notes() -> Array:
	var result: Array = []
	match pattern:
		Pattern.STAFF, Pattern.STAFF_EIGHTHS:
			var first := [Lane.LOW, Lane.MID, Lane.HIGH]
			for i in range(first.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var swap: int = first[i]
				first[i] = first[j]
				first[j] = swap
			var parry := rng.randi_range(1, 4)
			for i in 6:
				var lane: int = first[i] if i < 3 else _random_lane()
				if i == parry:
					lane = Lane.LOW if rng.randf() < 0.5 else Lane.MID
					result.append([2 + i, lane, true])
					continue
				result.append([2 + i, lane, false])
				# Às vezes um acorde: chão + meio (um pulo passa) ou meio + alto (abaixar passa).
				if rng.randf() < 0.3 and lane != Lane.HIGH:
					result.append([2 + i, lane + 1, false])
		Pattern.STAFF_WAVES:
			# Ondas saem nos tempos 3 e 6, na mesma velocidade: nota no mesmo tempo da onda (ou logo depois)
			# só no meio, que o mesmo pulo da onda passa; nota alta só longe das ondas.
			for beat in range(2, 9):
				var near_wave := beat in [3, 4, 6, 7]
				var lane: int = Lane.MID if near_wave or rng.randf() < 0.4 else Lane.HIGH
				if beat == 5:
					lane = Lane.HIGH
				result.append([beat, lane, beat == 4])
	return result


func _random_lane() -> int:
	var roll := rng.randf()
	return Lane.LOW if roll < 0.45 else (Lane.MID if roll < 0.8 else Lane.HIGH)


func prop(key: String, kind: StringName, at: Vector2, hot := true, parry := false) -> MaestroThreat:
	if not _props.has(key):
		var node := MaestroThreat.new()
		node.kind = kind
		node.parryable = parry
		node.parry_id = "Maestro:%s:%d:%s" % [name, run_seed, key]
		node.active = false
		add_child(node)
		_props[key] = node
		node.position = at
		node.reset_physics_interpolation()
	var node: MaestroThreat = _props[key]
	node.position = at
	node.active = hot and not node.popped
	node.visible = not node.popped
	return node


func hide_prop(key: String) -> void:
	if _props.has(key):
		_props[key].retire()


## Aviso âmbar (nunca machuca). `shape`: "line" (rastro até o alvo), "column", "floor" ou "sector".
func warn(shape: StringName, from: Vector2, to: Vector2, width: float) -> void:
	_warnings.append({"shape": shape, "from": from, "to": to, "width": width})


func _on_tick(_delta: float) -> void:
	_tick(elapsed)


func _tick(t: float) -> void:
	_warnings.clear()
	_staff_glow = 0.0
	_rod = Vector2.INF
	actor.position = RustMaestroBoss.HOME
	var main := t
	match pattern:
		Pattern.STAFF:
			_conduct(t, 2)
			_staff(t)
		Pattern.BATON:
			_baton(t, [2, 5])
		Pattern.METRONOME:
			if t < 2 * B: actor.pose(&"raise")
			else: actor.idle()
			_metronome(t)
		Pattern.WAVES:
			actor.pose(&"organ")
			_waves(t, [2, 4, 6])
		Pattern.EIGHTHS:
			actor.pose(&"raise" if t < 2 * B else &"point")
			_eighths(t)
		Pattern.PIPES:
			actor.pose(&"organ")
			_pipes(t)
		Pattern.STAFF_WAVES:
			_conduct(t, 2)
			_staff(t)
			if t >= B: _waves(t - B, [2, 5])
		Pattern.STAFF_EIGHTHS:
			_conduct(t, 2)
			_staff(t)
			if t >= B: _eighths(t - B)
		Pattern.BATON_WAVES:
			_baton(t, [2, 6])
			if t >= B: _waves(t - B, [3, 7])
		Pattern.INTRO_ORGAN:
			boss.set_stage(1)
			actor.pose(&"organ")
			actor.blast(0.2)
		Pattern.INTRO_FINALE:
			boss.set_stage(2)
			actor.pose(&"bow" if t < 2 * B else &"raise")
			actor.blast(0.2)
	if _bows:
		_bow(main - BEATS[pattern] * B)
	queue_redraw()


## Pose de reger: braço erguido no aviso, depois a batuta "solta" uma nota a cada tempo.
func _conduct(t: float, warn_beats: int) -> void:
	if t < warn_beats * B:
		actor.pose(&"raise")
	else:
		actor.pose(&"strike" if fposmod(t, B) < 0.15 else &"point")


func _staff(t: float) -> void:
	var last := 0.0
	for note: Array in notes:
		last = maxf(last, note[0] * B)
	var end := last + (SPAWN_X - LEFT_OUT) / _speed
	if t < end:
		# As linhas da pauta ficam acesas enquanto houver nota; fortes no aviso.
		_staff_glow = 1.0 if t < 2 * B else 0.35
	for i in notes.size():
		var note: Array = notes[i]
		var launch: float = note[0] * B
		var y: float = LANES[note[1]]
		var key := "note:%d" % i
		var s := t - launch
		if s < -B:
			continue
		if s < 0.0:
			# Um tempo antes de sair, a nota aparece crescendo na beira da pauta (sem machucar).
			var grow := prop(key, &"note_parry" if note[2] else &"note", Vector2(SPAWN_X, y), false, note[2])
			grow.scale = Vector2.ONE * lerpf(0.3, 1.0, (s + B) / B)
			continue
		var x := SPAWN_X - s * _speed
		if x > LEFT_OUT:
			var node := prop(key, &"note_parry" if note[2] else &"note", Vector2(x, y), true, note[2])
			node.scale = Vector2.ONE
		else:
			hide_prop(key)


## Golpes da batuta nos tempos `strikes`: leque na frente dele e uma lâmina de som correndo pelo chão.
func _baton(t: float, strikes: Array) -> void:
	var shoulder := actor.position + (MaestroActor.PIECES[&"baton_arm"][1] - MaestroActor.FEET) * MaestroActor.ART_SCALE
	var posed := false
	for i in strikes.size():
		var hit: float = strikes[i] * B
		var s := t - hit
		if s >= -1.6 * B and s < 0.0:
			warn(&"sector", shoulder, shoulder, MaestroThreat.REACH)
			warn(&"floor", Vector2(SPAWN_X - 190, FLOOR), Vector2(LEFT_OUT, FLOOR), 36)
			actor.pose(&"raise")
			posed = true
		elif s >= 0.0 and s < 0.45:
			actor.pose(&"strike")
			posed = true
		var arc_key := "arc%d" % i
		if s >= 0.0 and s < 0.4:
			prop(arc_key, &"arc", shoulder, s < 0.22).set_amount(s / 0.4)
		elif s >= 0.4:
			hide_prop(arc_key)
		var blade_key := "crescent%d" % i
		var x := SPAWN_X - 190 - (s - 0.1) * _speed
		if s >= 0.1 and x > LEFT_OUT:
			prop(blade_key, &"crescent", Vector2(x, FLOOR))
		elif s >= 0.1:
			hide_prop(blade_key)
	if not posed and t < strikes[-1] * B + 0.45:
		actor.pose(&"point")
	elif not posed:
		actor.idle()


## Peso do metrônomo balançando do teto: baixo no meio (pular), alto perto das paredes.
func _metronome(t: float) -> void:
	var angle := PENDULUM_SWING
	var length := PENDULUM_LENGTH
	var hot := false
	if t < 2 * B:
		# Desce do teto já no ângulo de saída; o caminho do peso fica marcado.
		length = lerpf(200.0, PENDULUM_LENGTH, ease(t / (2 * B), 0.4))
		warn(&"swing", PENDULUM_PIVOT, PENDULUM_PIVOT, PENDULUM_LENGTH)
	elif t < 8 * B:
		angle = PENDULUM_SWING * cos(PI * (t - 2 * B) / (3 * B))
		hot = true
	else:
		angle = PENDULUM_SWING
		length = lerpf(PENDULUM_LENGTH, 200.0, clampf((t - 8 * B) / B, 0.0, 1.0))
	var bob := PENDULUM_PIVOT + Vector2(sin(angle), cos(angle)) * length
	var node := prop("blade", &"blade", bob, hot)
	node.rotation = -angle
	_rod = bob


## Ondas graves saindo dos tubos nos tempos `beats`, correndo pelo chão (pular cada uma).
func _waves(t: float, beats: Array) -> void:
	if t < beats[0] * B:
		warn(&"floor", Vector2(SPAWN_X, FLOOR), Vector2(LEFT_OUT, FLOOR), 40)
	for i in beats.size():
		var s: float = t - beats[i] * B
		var key := "wave%d" % i
		if s >= -0.2 and s < 0.1:
			actor.blast(0.25)
		var x := SPAWN_X - s * _speed
		if s >= 0.0 and x > LEFT_OUT:
			prop(key, &"wave", Vector2(x, FLOOR))
		elif s >= 0.0:
			hide_prop(key)


## Pares de colcheias caindo onde cada jogador estava (e depois ao lado), com a marca no chão antes.
func _eighths(t: float) -> void:
	for i in targets.size():
		for k in 3:
			var x := targets[i].x + (shifts[i] if k == 1 else (-shifts[i] * 0.5 if k == 2 else 0.0))
			x = clampf(x, 60.0, 1440.0)
			var land := (2 * k + 2) * B
			var s := t - land
			var key := "eighths%d:%d" % [i, k]
			if s < -2 * B:
				continue
			if s < -EIGHTH_FALL:
				warn(&"floor", Vector2(x - 80, FLOOR), Vector2(x + 80, FLOOR), 30)
			elif s < 0.0:
				var u := 1.0 - (-s / EIGHTH_FALL)
				prop(key, &"eighths", Vector2(x, lerpf(-120.0, FLOOR - 30.0, u * u)))
				warn(&"floor", Vector2(x - 80, FLOOR), Vector2(x + 80, FLOOR), 30)
			elif s < 0.45:
				prop(key, &"eighths", Vector2(x, FLOOR - 30.0)).scale = Vector2(1.0 + 0.15 * (1.0 - s / 0.45), 1.0)
			else:
				hide_prop(key)


## Tubos de órgão subindo do chão sob cada jogador (duas rodadas): vapor e coluna marcada antes.
func _pipes(t: float) -> void:
	for i in targets.size():
		for r in 2:
			var x := clampf(targets[i].x + (shifts[i] if r == 1 else 0.0), 60.0, 1440.0)
			var s := t - r * 3 * B
			var key := "pipe%d:%d" % [i, r]
			if s < 0.0:
				continue
			if s < 2 * B:
				warn(&"column", Vector2(x, 230), Vector2(x, FLOOR), 54)
				continue
			var height := 0.0
			if s < 2 * B + 0.15:
				height = 700.0 * (s - 2 * B) / 0.15
			elif s < 4 * B:
				height = 700.0
			elif s < 4.5 * B:
				height = 700.0 * (1.0 - (s - 4 * B) / (0.5 * B))
			if height > 0.0:
				prop(key, &"pipe", Vector2(x, FLOOR), height > 40.0).set_amount(height)
			else:
				hide_prop(key)


## Reverência no fim de cada música da fase 3: curva, abre a caixa de música (dano dobrado) e fecha.
func _bow(s: float) -> void:
	if s < 0.0:
		return
	actor.pose(&"bow")
	actor.set_chest(s >= BOW_OPEN.x and s < BOW_OPEN.y)


func _is_done() -> bool:
	return elapsed >= _duration


func _on_end() -> void:
	for node: MaestroThreat in _props.values():
		node.retire()
		node.queue_free()
	_props.clear()
	_warnings.clear()
	_staff_glow = 0.0
	_rod = Vector2.INF
	actor.set_chest(false)
	if not boss.is_defeated:
		actor.idle()
	queue_redraw()


func _draw() -> void:
	var amber := Color("ffd987")
	if _staff_glow > 0.0:
		for lane: float in LANES:
			draw_line(Vector2(0, lane), Vector2(SPAWN_X, lane), Color(amber, 0.8 * _staff_glow), 4.0, true)
			draw_line(Vector2(0, lane - 7), Vector2(SPAWN_X, lane - 7), Color(amber, 0.2 * _staff_glow), 1.5, true)
			draw_line(Vector2(0, lane + 7), Vector2(SPAWN_X, lane + 7), Color(amber, 0.2 * _staff_glow), 1.5, true)
	if _rod != Vector2.INF:
		draw_line(PENDULUM_PIVOT, _rod, Color("2a1a10"), 12.0, true)
		draw_line(PENDULUM_PIVOT, _rod, Color("b8862f"), 6.0, true)
	for marker in _warnings:
		var from: Vector2 = marker.from
		var to: Vector2 = marker.to
		var width: float = marker.width
		match marker.shape:
			&"floor":
				draw_rect(Rect2(Vector2(minf(from.x, to.x), from.y - width), Vector2(absf(to.x - from.x), width)), Color(amber, 0.12), true)
				for x in range(int(minf(from.x, to.x)), int(maxf(from.x, to.x)), 42):
					draw_line(Vector2(x, from.y - 4), Vector2(x + 20, from.y - 4), Color(amber, 0.8), 3.0, true)
			&"column":
				var rect := Rect2(Vector2(from.x - width, from.y), Vector2(width * 2, to.y - from.y))
				draw_rect(rect, Color(amber, 0.1), true)
				draw_rect(rect, amber, false, 2.0)
				# Vapor escapando do chão onde o tubo vai subir.
				for k in 3:
					var puff := fposmod(elapsed * 1.6 + k * 0.33, 1.0)
					draw_circle(Vector2(from.x + (k - 1) * 26, to.y - 10 - puff * 70), 10 + puff * 16, Color(0.9, 0.88, 0.84, 0.5 * (1.0 - puff)))
			&"sector":
				var points := PackedVector2Array([from])
				for i in 9:
					var a := lerpf(-PI * 0.5, -PI * 0.98, i / 8.0)
					points.append(from + Vector2(cos(a), -sin(a)) * width)
				draw_colored_polygon(points, Color(amber, 0.1))
				draw_polyline(points + PackedVector2Array([from]), amber, 2.5, true)
			&"swing":
				# Caminho do peso: arco pontilhado de um lado ao outro.
				for i in 24:
					var a := lerpf(-PENDULUM_SWING, PENDULUM_SWING, i / 23.0)
					var point := from + Vector2(sin(a), cos(a)) * width
					draw_circle(point, 5.0, Color(amber, 0.75))
