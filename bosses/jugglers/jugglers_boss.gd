class_name JugglersBoss
extends BossBrain
## Os Irmãos Malabaristas, Tico e Teco (docs/bosses.md). A parte genérica fica no BossBrain;
## aqui fica o que é deles:
## - Cada irmão tem a sua vida (metade do total). Nas fases 1 e 2, um irmão não passa do
##   limite da fase: ao chegar nele fica tonto. Se o outro não chegar ao limite em 3 s, ele
##   joga uma bola de cura (rosa: um parry estoura) que devolve parte da vida do tonto.
##   Para trocar de fase, a dupla precisa derrubar os dois juntos ("Um Não Vive Sem o Outro").
## - Fase 1 separados nos dois lados; fase 2 em totem (um nos ombros do outro); fase 3 no
##   monociclo gigante (aí o dano vai para quem ainda tiver vida).
## O host decide a vida de cada um e manda para o cliente (barras e tontura).

## Metade da vida do chefão (max_health 1200 na cena; era 1500 até 04/10/2026, o usuário achou longa demais).
const BROTHER_MAX := 600
## Tempo tonto até o outro irmão jogar a bola de cura.
const HEAL_DELAY := 3.0
const HEAL_FLIGHT := 1.2
## Quanto a cura devolve (fração da vida da fase de cada irmão).
const HEAL_SHARE := 0.4
const HOME_LEFT := Vector2(190, 1000)
const HOME_RIGHT := Vector2(1730, 1000)
## Altura dos pés de quem fica nos ombros do irmão.
const SHOULDER := 150.0
## No totem desenhado (E7): o meio do de cima a 110 px dos pés da base, medido no desenho (a cabeça da base
## vai até ~115); as áreas seguem o desenho, com o totem crescido em Juggler.TOTEM_GROW (desde 05/10/2026 o de
## cima chega a ~273 px do chão e pega quem está na tábua pendurada, de 216 a 240). O monociclo continua com
## SHOULDER (os dois no boneco de código).
const TOTEM_SHOULDER := 110.0 * Juggler.TOTEM_GROW
const TOTEM_BASE_HIT := 110.0 * Juggler.TOTEM_GROW
const TOTEM_TOP_HIT := 92.0 * Juggler.TOTEM_GROW
const TOTEM_BASE_HURT := Vector2(0, 115) * Juggler.TOTEM_GROW
const TOTEM_TOP_HURT := Vector2(0, 102) * Juggler.TOTEM_GROW
const NAMES := ["Tico", "Teco"]

var hp := {"Tico": BROTHER_MAX, "Teco": BROTHER_MAX}
## Desde quando cada irmão está tonto (relógio do host; -1 = não está).
var dizzy_since := {"Tico": -1.0, "Teco": -1.0}
## split (separados), totem ou unicycle.
var mode := &"split"
## No totem e no monociclo: quem fica embaixo.
var base_name := "Tico"

var _clock := 0.0
var _heal: JugglerProp
var _heal_from := Vector2.ZERO
var _heal_to := ""
var _heal_time := 0.0
var _heal_count := 0
## Tonto no começo do ataque (pelo host, vai nos args): quem está tonto fica parado e não joga nada.
var _start_dizzy := {"Tico": false, "Teco": false}

@onready var tico: Juggler = $Tico
@onready var teco: Juggler = $Teco
@onready var unicycle: Unicycle = $Unicycle


func _init() -> void:
	phase_shares = [0.4, 0.35, 0.25]
	phase_titles = ["Troca-Troca", "Totem!", "Monociclo Gigante!"]
	phase_attacks = [
		[&"JugglePass", &"Swap", &"BounceBalls"],
		[&"TotemWalk", &"Bowling", &"ClubVolley"],
		[&"UnicycleRide", &"TorchRain", &"BounceBalls"],
	]
	phase_intros = [&"", &"IntroTotem", &"IntroUnicycle"]


func _ready() -> void:
	super()
	connect_hurtbox(tico.hurtbox, tico, "Tico")
	connect_hurtbox(teco.hurtbox, teco, "Teco")
	phase_started.connect(func(_phase: int, _title: String) -> void: _clear_dizzy())
	Network.peer_ready.connect(func(_peer_id: int) -> void: _share_brothers())
	tico.facing = 1
	teco.facing = -1
	unicycle.hide()
	unicycle.hitbox.active = false


func _physics_process(delta: float) -> void:
	super(delta)
	_clock += delta
	_update_heal(delta)


func brother(brother_name: String) -> Juggler:
	return tico if brother_name == "Tico" else teco


func other_name(brother_name: String) -> String:
	return "Teco" if brother_name == "Tico" else "Tico"


func base() -> Juggler:
	return brother(base_name)


func top() -> Juggler:
	return brother(other_name(base_name))


## Quem está à esquerda e à direita (fase 1).
func left() -> Juggler:
	return tico if tico.global_position.x <= teco.global_position.x else teco


func right() -> Juggler:
	return teco if left() == tico else tico


## Arruma os dois para o modo atual, com o "conjunto" (totem ou monociclo) em `x`. `reset_poses` falso: só move
## (os ataques que andam com o conjunto a cada quadro; senão o arremesso do de cima voltava a "sentado" no
## começo de cada quadro).
func place_group(x: float, reset_poses := true) -> void:
	match mode:
		&"totem":
			base().global_position = Vector2(x, HOME_LEFT.y)
			top().global_position = Vector2(x, HOME_LEFT.y - TOTEM_SHOULDER)
			if reset_poses:
				base().pose = &"idle"
				top().pose = &"sit"
		&"unicycle":
			unicycle.global_position = Vector2(x, HOME_LEFT.y)
			base().global_position = unicycle.seat_position()
			top().global_position = unicycle.seat_position() - Vector2(0, SHOULDER)
			if reset_poses:
				base().pose = &"ride"
				top().pose = &"sit"


## Estava tonto quando o ataque começou (pelo host).
func started_dizzy(juggler: Juggler) -> bool:
	return _start_dizzy["Tico" if juggler == tico else "Teco"]


## Separados, com um tonto, eles não trocam de lugar (o tonto não pula: fica parado para levar tiro).
func _can_choose(attack_name: StringName) -> bool:
	return not (attack_name == &"Swap" and (tico.dizzy or teco.dizzy))


## Dados de onde todos estão (vai junto com cada ataque: os dois PCs começam iguais).
func _args_for(_attack_name: StringName) -> Array:
	return [tico.global_position.x, tico.global_position.y, teco.global_position.x, teco.global_position.y,
			unicycle.global_position.x, base_name, tico.dizzy, teco.dizzy]


## Coloca todo mundo onde o host disse (começo de cada ataque).
func apply_args(args: Array) -> void:
	if args.size() < 6:
		return
	tico.global_position = Vector2(args[0], args[1])
	teco.global_position = Vector2(args[2], args[3])
	unicycle.global_position.x = args[4]
	base_name = args[5]
	if args.size() >= 8:
		_start_dizzy = {"Tico": args[6], "Teco": args[7]}


func set_mode(new_mode: StringName) -> void:
	mode = new_mode
	for juggler: Juggler in [tico, teco]:
		juggler.carrying = mode != &"split" and juggler == base()
	unicycle.visible = mode == &"unicycle"
	unicycle.hitbox.active = mode == &"unicycle"
	for juggler: Juggler in [tico, teco]:
		juggler.totem_role = Juggler.TotemRole.NONE
		juggler.totem_partner = null
		juggler.set_hurtbox_span(10.0, 180.0)
	if mode == &"totem":
		base().totem_role = Juggler.TotemRole.BASE
		top().totem_role = Juggler.TotemRole.TOP
		base().totem_partner = top()
		top().totem_partner = base()
		top().set_hitbox_height(TOTEM_TOP_HIT)
		base().set_hitbox_height(TOTEM_BASE_HIT)
		base().set_hurtbox_span(TOTEM_BASE_HURT.x, TOTEM_BASE_HURT.y)
		top().set_hurtbox_span(TOTEM_TOP_HURT.x, TOTEM_TOP_HURT.y)
	else:
		top().set_hitbox_height(150.0)
		base().set_hitbox_height(150.0)


## Vida e tontura de cada irmão, para as barras do placar.
func sub_bars() -> Array:
	var bars := []
	for brother_name in NAMES:
		bars.append([brother_name, float(hp[brother_name]) / BROTHER_MAX, brother(brother_name).dizzy])
	return bars


## Dano de um tiro (só no host): vai para o irmão atingido, sem passar do limite da fase.
func apply_damage(amount: int, source := "", part := "") -> void:
	if is_defeated:
		return
	if not source.is_empty():
		_recent_damage[source] = _recent_damage.get(source, 0.0) + amount
	var target: String = part if hp.has(part) else _healthier()
	if phase >= 2 and hp[target] <= 0:
		target = other_name(target)
	var limit := _limit()
	var value := maxi(hp[target] - amount, limit)
	if value == hp[target]:
		return
	hp[target] = value
	if phase < 2 and value == limit and dizzy_since[target] < 0.0:
		dizzy_since[target] = _clock
	_share_brothers()
	health.set_current(hp.Tico + hp.Teco)


func _on_catch_up() -> void:
	_clear_dizzy()
	if phase >= 1:
		set_mode(&"totem" if phase == 1 else &"unicycle")
		place_group(HOME_LEFT.x if phase == 1 else HOME_RIGHT.x - 60)


func _on_defeated() -> void:
	_cancel_heal()
	for juggler: Juggler in [tico, teco]:
		juggler.set_vulnerable(false)
		juggler.dizzy = false
		juggler.spin = 0.0
	unicycle.hitbox.active = false
	# O último malabarismo um com o outro... e caem um em cima do outro.
	var x := clampf(base().global_position.x, 300.0, 1620.0)
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void:
		unicycle.hide()
		tico.global_position = Vector2(x - 40, HOME_LEFT.y)
		teco.global_position = Vector2(x + 30, HOME_LEFT.y - 40)
		tico.pose = &"down"
		teco.pose = &"down"
		# Desenhado, o Teco cai 0,1 s depois, por cima do Tico, com a cabeça na barriga dele (para o lado dos
		# pés do Tico): os dois rostos aparecem. Na posição do boneco (70 px para o lado da cabeça) o Teco
		# tapava o rosto do Tico; virado ao contrário, os pés dele tapavam.
		tico.defeat_delay = 0.0
		teco.defeat_delay = 0.1
		teco.facing = tico.facing
		teco.global_position = Vector2(x - 40 + 120 * tico.facing, HOME_LEFT.y - 35))


# --- Tontura e bola de cura ---

## Vida mínima de cada irmão na fase atual (metade do que sobra no fim da fase).
func _limit() -> int:
	if phase >= phase_shares.size() - 1:
		return 0
	return floori(phase_end_health() / 2.0)


func _healthier() -> String:
	return "Tico" if hp.Tico >= hp.Teco else "Teco"


func _clear_dizzy() -> void:
	for brother_name in NAMES:
		dizzy_since[brother_name] = -1.0
	_cancel_heal()
	_share_brothers()


func _update_heal(delta: float) -> void:
	if _heal != null:
		_heal_time += delta
		# Quem jogou a cura volta ao parado logo depois de soltar (antes ficava na pose de arremesso).
		var healer := brother(other_name(_heal_to))
		if mode == &"split" and _heal_time >= 0.1 and healer.pose == &"throw":
			healer.pose = &"idle"
		var u := minf(_heal_time / HEAL_FLIGHT, 1.0)
		var to := brother(_heal_to).head_position()
		_heal.global_position = BossAttack.arc_point(_heal_from, to, 260.0, u)
		if u >= 1.0:
			_land_heal()
		return
	if not is_brain() or is_defeated or phase >= phase_shares.size() - 1:
		return
	for brother_name in NAMES:
		var since: float = dizzy_since[brother_name]
		var other := other_name(brother_name)
		if since >= 0.0 and _clock - since >= HEAL_DELAY and dizzy_since[other] < 0.0:
			_heal_count += 1
			_start_heal(other, brother_name, _heal_count)
			for peer_id in Network.ready_peers:
				_receive_heal.rpc_id(peer_id, other, brother_name, _heal_count)
			return


@rpc("authority", "call_remote", "reliable")
func _receive_heal(from_name: String, to_name: String, count: int) -> void:
	Network.deliver(_start_heal.bind(from_name, to_name, count), false)


## O irmão `from_name` joga a bola de cura (rosa) no tonto `to_name`.
func _start_heal(from_name: String, to_name: String, count: int) -> void:
	_cancel_heal()
	var healer := brother(from_name)
	if mode == &"split":
		healer.throw_now()
	_heal = JugglerProp.new()
	_heal.kind = &"heal"
	_heal.pink = true
	_heal.parry_id = "jugglers:heal:%d" % count
	add_child(_heal)
	_heal_from = healer.hand_position()
	_heal.global_position = _heal_from
	_heal_to = to_name
	_heal_time = 0.0


func _land_heal() -> void:
	var popped := _heal.popped
	var target := _heal_to
	_cancel_heal()
	if not is_brain() or is_defeated:
		return
	if popped:
		# Estourou com parry: o tonto continua tonto (e o outro tenta de novo daqui a pouco).
		dizzy_since[target] = _clock
		return
	var share: float = phase_shares[phase] * BROTHER_MAX * HEAL_SHARE
	hp[target] = mini(hp[target] + roundi(share), BROTHER_MAX)
	dizzy_since[target] = -1.0
	_share_brothers()
	health.set_current(hp.Tico + hp.Teco)


func _cancel_heal() -> void:
	if _heal != null:
		_heal.queue_free()
		_heal = null


## Host: manda a vida e a tontura dos dois para o cliente (e atualiza o desenho aqui).
func _share_brothers() -> void:
	_show_brothers()
	if not Network.is_online() or not Network.is_host():
		return
	for peer_id in Network.ready_peers:
		_receive_brothers.rpc_id(peer_id, hp.Tico, hp.Teco, dizzy_since.Tico >= 0.0, dizzy_since.Teco >= 0.0)


@rpc("authority", "call_remote", "reliable")
func _receive_brothers(tico_hp: int, teco_hp: int, tico_dizzy: bool, teco_dizzy: bool) -> void:
	Network.deliver(_apply_brothers.bind(tico_hp, teco_hp, tico_dizzy, teco_dizzy), false)


func _apply_brothers(tico_hp: int, teco_hp: int, tico_dizzy: bool, teco_dizzy: bool) -> void:
	hp.Tico = tico_hp
	hp.Teco = teco_hp
	dizzy_since.Tico = 0.0 if tico_dizzy else -1.0
	dizzy_since.Teco = 0.0 if teco_dizzy else -1.0
	_show_brothers()


func _show_brothers() -> void:
	tico.dizzy = dizzy_since.Tico >= 0.0
	teco.dizzy = dizzy_since.Teco >= 0.0
