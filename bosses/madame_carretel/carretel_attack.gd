extends BossAttack
## Ataques no mesmo relógio nos dois PCs. Sem decisões locais de mira.
enum Pattern { NEEDLES, SCISSORS, TAPE, CURTAINS, BUTTONS, INTRO_CLOTH, INTRO_ARMOR,
	NEEDLES_TAPE, CURTAINS_NEEDLES, BUTTONS_SCISSORS }
const DURATIONS := [4.6,4.1,4.9,3.8,4.9,1.6,1.8,5.35,4.95,4.9]
@export var pattern := Pattern.NEEDLES
var boss: MadameCarretelBoss
var actor: CarretelActor
var targets: Array[Vector2] = []
var _props := {}
var _warnings: Array[Dictionary] = []

func _ready() -> void:
	boss = get_parent().get_parent()
	actor = boss.actor

func _on_begin() -> void:
	# Actor também está disponível durante _ready dos filhos, antes do @onready do pai.
	actor = boss.get_node("Actor")
	targets.clear()
	for target in args:
		if target is Vector2: targets.append(target)
	if targets.is_empty(): targets.append(Vector2(700,875))
	_tick(0.0)

func prop(key: String,kind: StringName,at: Vector2,size: Vector2,frame: int,hot := true,parry := false) -> CarretelThreat:
	if not _props.has(key):
		var node := CarretelThreat.new()
		node.kind = kind
		node.parryable = parry
		node.parry_id = "Carretel:%s:%d:%s" % [name,run_seed,key]
		node.active = false
		add_child(node)
		_props[key] = node
		node.position = at
		node.reset_physics_interpolation()
	var node: CarretelThreat = _props[key]
	node.position = at
	node.scale = size
	node.set_frame(frame)
	node.active = hot and not node.popped
	node.visible = not node.popped
	return node

func hide_prop(key: String) -> void:
	if _props.has(key): _props[key].retire()

func warn(from: Vector2,to: Vector2,width: float,t: float,until: float,vertical := false) -> void:
	if t<until:
		_warnings.append({"from":from,"to":to,"width":width,"vertical":vertical})

func _on_tick(_delta: float) -> void:
	_tick(elapsed)

func _pose(clip: StringName,t: float,launch := 0.9) -> void:
	if boss.phase==2: clip = &"armor_attack"
	actor.pose(clip,0 if t<launch*0.55 else (1 if t<launch else (2 if t<launch+0.3 else 3)))

func _tick(t: float) -> void:
	_warnings.clear()
	actor.position = MadameCarretelBoss.HOME
	match pattern:
		Pattern.NEEDLES:
			_pose(&"needles",t)
			_needles(t)
		Pattern.SCISSORS:
			_pose(&"scissors",t)
			_scissors(t)
		Pattern.TAPE:
			_pose(&"tape",t)
			_tape(t)
		Pattern.CURTAINS:
			_pose(&"cloth",t,1.0)
			_curtains(t)
		Pattern.BUTTONS:
			_pose(&"armor_attack",t)
			_buttons(t)
		Pattern.INTRO_CLOTH:
			boss.set_stage(1)
			actor.pose(&"cloth",mini(int(t/0.4),3))
		Pattern.INTRO_ARMOR:
			boss.set_stage(2)
			actor.pose(&"armor",mini(int(t/0.45),3))
		Pattern.NEEDLES_TAPE:
			_pose(&"needles",t)
			_needles(t)
			# Aviso do chão começa 0,60s depois. Parry e primeira onda coexistem.
			if t>=0.6: _tape(t-0.6)
		Pattern.CURTAINS_NEEDLES:
			_pose(&"cloth",t,1.0)
			_curtains(t)
			if t>=0.6: _needles(t-0.6)
		Pattern.BUTTONS_SCISSORS:
			_pose(&"armor_attack",t)
			_buttons(t)
			# Corte termina antes de fechar os botões: resta uma janela de contra-ataque.
			if t>=0.6: _scissors(t-0.6)
	queue_redraw()

func _needles(t: float) -> void:
	for lane in targets.size():
		var origin := actor.position+Vector2(-275,-410+lane*65)
		var direction := (targets[lane]-origin).normalized()
		warn(origin,targets[lane],22,t,0.9)
		for shot in 2:
			var s := t-0.9-shot*0.72
			var key := "needle:%d:%d" % [lane,shot]
			if s>=0 and s<2.65:
				var needle := prop(key,&"needle_parry" if shot==1 else &"needle",origin+direction*s*640,Vector2.ONE*0.43,int(s*12),true,shot==1)
				needle.rotation = direction.angle()-PI
			elif s>=2.65: hide_prop(key)

func _scissors(t: float) -> void:
	warn(Vector2(1200,850),Vector2(35,850),30,t,0.95)
	var s := t-0.95
	if s>=0 and s<2.7:
		# O arco percorre todo o chão, incluindo o canto esquerdo.
		var frame := 0 if s<0.12 else (1 if s<2.38 else (2 if s<2.55 else 3))
		prop("cut",&"cut",Vector2(1160-s*530,765),Vector2.ONE*0.65,frame,s<2.55)
	elif s>=2.7: hide_prop("cut")

func _tape(t: float) -> void:
	warn(Vector2(1320,870),Vector2(30,870),24,t,0.95)
	for i in 2:
		var s := t-0.95-i*1.05
		var key := "tape%d" % i
		if s>=0 and s<2.6:
			prop(key,&"tape",Vector2(1320-s*620,870),Vector2(0.9,0.55),int(s*12))
		elif s>=2.6: hide_prop(key)

func _curtains(t: float) -> void:
	for i in targets.size():
		var x := clampf(targets[i].x,118,1365)
		warn(Vector2(x,530),Vector2(x,930),120,t,1.0,true)
		var frame := 0 if t<1.0 else (1 if t<1.25 else (2 if t<2.85 else 3))
		if t<3.3:
			prop("curtain%d" % i,&"cloth",Vector2(x,530),Vector2(0.45,0.85),frame,t>=1.0 and t<2.85)
		else: hide_prop("curtain%d" % i)

func _buttons(t: float) -> void:
	for i in targets.size():
		var origin := actor.position+Vector2(-240,-230)
		warn(origin,targets[i],48,t,1.0)
		for shot in 2:
			var s := t-1.0-shot*0.75
			var key := "button%d:%d" % [i,shot]
			if s>=0 and s<1.8:
				var u := s/1.8
				var button := prop(key,&"button",arc_point(origin,targets[i],140,u),Vector2.ONE*0.27,int(s*12))
				button.rotation = -s*TAU
			elif s>=1.8: hide_prop(key)
	var open := t>=2.85 and t<4.55
	actor.set_weak(open)
	if open: actor.pose(&"armor",3)

func _is_done() -> bool:
	return elapsed>=DURATIONS[pattern]

func _on_end() -> void:
	for node: CarretelThreat in _props.values():
		node.retire()
		node.queue_free()
	_props.clear()
	_warnings.clear()
	actor.set_weak(false)
	if not boss.is_defeated: actor.idle()
	queue_redraw()

func _draw() -> void:
	var amber := Color("ffd987")
	for marker in _warnings:
		var from: Vector2 = marker.from
		var to: Vector2 = marker.to
		if marker.vertical:
			draw_rect(Rect2(from-Vector2(marker.width,0),Vector2(marker.width*2,to.y-from.y)),Color(amber,0.09),true)
			draw_rect(Rect2(from-Vector2(marker.width,0),Vector2(marker.width*2,to.y-from.y)),amber,false,2.0)
		else:
			var direction := from.direction_to(to)
			for i in range(0,int(from.distance_to(to)),42):
				var point := from+direction*i
				draw_line(point,point+direction*18,Color(amber,0.65),2.0,true)
			draw_arc(to,marker.width,0,TAU,24,amber,2.5,true)
