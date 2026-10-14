extends Node2D
## Encenação reutilizável de ataques: gesto, aviso e efeito na mesma linha de tempo.
## Não aplica dano, não altera save e não substitui a futura lógica da luta.
signal phase_changed(phase: StringName)
signal finished(attack: StringName)

const BODY := preload("res://bosses/madame_carretel/carretel_visual.tscn")
const FX := preload("res://bosses/madame_carretel/art/effects/carretel_effects.tres")
const ATTACKS := {
	&"scissors": {"body":&"scissors", "warning":0.85, "active":0.62},
	&"tape": {"body":&"tape", "warning":0.90, "active":1.05},
	&"needles": {"body":&"needles", "warning":0.90, "active":1.55},
	&"parry": {"body":&"needles", "warning":0.90, "active":1.55},
	&"cloth": {"body":&"cloth", "warning":1.0, "active":2.25},
	&"armor_attack": {"body":&"armor_attack", "warning":1.0, "active":1.85},
}
var visual: Node2D
var effects: Array[AnimatedSprite2D] = []
var attack: StringName = &"scissors"
var phase: StringName = &"warning"
var elapsed := 0.0
var paused := false
var show_guides := true
var _finished := false

func _ready() -> void:
	visual = BODY.instantiate()
	add_child(visual)
	for i in 3:
		var effect := AnimatedSprite2D.new()
		effect.sprite_frames = FX
		effect.z_index = 1
		add_child(effect)
		effects.append(effect)
	seek(0.0)

func duration(key: StringName) -> float:
	return ATTACKS[key].warning+ATTACKS[key].active+0.85

func play_attack(key: StringName) -> void:
	assert(ATTACKS.has(key), "Unknown Carretel attack")
	attack = key
	_finished = false
	seek(0.0)

func _process(delta: float) -> void:
	if paused or _finished:
		return
	seek(elapsed+delta)
	if elapsed>=duration(attack):
		_finished = true
		finished.emit(attack)

func _pose(key: StringName, frame: int) -> void:
	visual.sprite.pause()
	visual.sprite.animation = key
	visual.sprite.frame = frame

func seek(time: float) -> void:
	elapsed = maxf(time,0.0)
	var data: Dictionary = ATTACKS[attack]
	var u: float = elapsed-data.warning
	var next: StringName = &"warning" if u<0.0 else (&"active" if u<data.active else &"recovery")
	if next!=phase:
		phase = next
		phase_changed.emit(phase)
	for effect in effects:
		effect.visible = false
		effect.modulate = Color.WHITE
		effect.rotation = 0.0
	if u<0.0:
		_pose(data.body,0 if elapsed<data.warning*0.55 else 1)
	elif u<data.active:
		_pose(data.body,2 if u<0.26 or attack==&"cloth" else 3)
	else:
		_pose(data.body,3)
	if u>=0.0 and u<data.active:
		match attack:
			&"scissors":
				_effect(0,&"cut",mini(3,int(u/0.155)),Vector2(-500,-335),Vector2.ONE*1.10)
			&"tape":
				var extension := smoothstep(0.0,0.20,u)
				var retract := 1.0-smoothstep(0.78,1.05,u)
				_effect(0,&"tape",int(u*12.0)%4,Vector2(-310,-315),Vector2(1.72*maxf(0.08,extension*retract),1.72))
			&"needles", &"parry":
				var count := 1 if attack==&"parry" else 3
				for i in count:
					var flight := u-float(i)*0.12
					if flight<0.0 or flight>1.25:
						continue
					var from := Vector2(-280,-390 if count==1 else -440+i*65)
					var travel := Vector2(-920,0 if count==1 else [-45,30,105][i])
					_effect(i,&"needle_parry" if count==1 else &"needle",int(flight*12.0)%4,from+travel*flight/1.25,Vector2.ONE*0.43)
			&"cloth":
				var frame := 0 if u<0.16 else (1 if u<0.36 else (2 if u<1.80 else 3))
				_effect(0,&"cloth",frame,Vector2(-820,-570),Vector2.ONE*1.19)
			&"armor_attack":
				for i in 3:
					var flight := u-float(i)*0.18
					if flight<0.0 or flight>1.40:
						continue
					var p := Vector2(-235-980*flight/1.40,-185+float(i)*10)
					# Full visible arcs in the air; no fake floor impacts.
					p.y -= sin(flight/1.40*PI)*(120.0+float(i)*55.0)
					_effect(i,&"button",int(flight*12.0)%4,p,Vector2.ONE*0.30)
					effects[i].rotation = -flight*TAU*1.5
	queue_redraw()

func _effect(index: int, key: StringName, frame: int, at: Vector2, size: Vector2) -> void:
	var sprite := effects[index]
	sprite.pause()
	sprite.animation = key
	sprite.frame = frame
	sprite.position = at
	sprite.scale = size
	sprite.visible = true

func _draw() -> void:
	if visual==null:
		return
	if attack==&"cloth":
		# Curtain is attached to the same visible rail for the entire action.
		draw_line(Vector2(-1160,-570),Vector2(-480,-570),Color("5c4953"),8.0,true)
	if phase!=&"warning" or not show_guides:
		return
	var color := Color("ffd987")
	color.a = 0.65+sin(elapsed*7.0)*0.15
	if attack==&"cloth":
		draw_rect(Rect2(-1110,-575,580,560),Color(color,0.06),true)
		draw_rect(Rect2(-1110,-575,580,560),color,false,3.0)
	elif attack==&"scissors":
		_warning_line(Vector2(-785,-320),Vector2(-315,-320),color)
	elif attack==&"tape":
		_warning_line(Vector2(-1140,-315),Vector2(-310,-315),color)
	elif attack==&"armor_attack":
		for i in 3:
			_warning_line(Vector2(-1190,-230-i*40),Vector2(-235,-185),color)
	else:
		var count := 1 if attack==&"parry" else 3
		for i in count:
			var y := -390.0 if count==1 else -440.0+i*65.0
			_warning_line(Vector2(-1200,y+(0 if count==1 else [-45,30,105][i])),Vector2(-280,y),color)

func _warning_line(from: Vector2,to: Vector2,color: Color) -> void:
	var distance := from.distance_to(to)
	var direction := (to-from).normalized()
	for step in range(0,int(distance),32):
		var start := from+direction*step
		draw_line(start,start+direction*minf(16.0,distance-step),color,2.5,true)
	# Chevrons point left, matching the coming projectile, and are warning only.
	for offset in [0.25,0.55,0.85]:
		var p := from.lerp(to,offset)
		draw_polyline(PackedVector2Array([p+Vector2(11,-8),p,p+Vector2(11,8)]),color,2.5,true)
