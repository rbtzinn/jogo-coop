extends Node
## Player real, colisão real, dois personagens/quatro Truques/início/meio/fim.
const PLAYER := preload("res://core/player/player.tscn")
const ACROBAT := preload("res://core/player/characters/acrobat/acrobat_rig.tscn")
var failures := 0
var fixture: Node2D
var player: Player

func _ready() -> void:
	get_tree().create_timer(150.0,true,false,true).timeout.connect(func() -> void: get_tree().quit(99))
	_run.call_deferred()

func check(ok: bool,label: String) -> void:
	print(("OK " if ok else "FAIL ")+label)
	if not ok: failures += 1

func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame

func setup(slot: int,trick: String,air := true) -> void:
	if fixture!=null:
		fixture.queue_free()
		await frames(2)
	SaveGame.reset()
	SaveGame.data.players["acrobat" if slot==1 else "clown"].equipped.trick = trick
	fixture = Node2D.new()
	get_tree().root.add_child(fixture)
	get_tree().current_scene = fixture
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(5000,180)
	shape.shape = rect
	floor_body.position = Vector2(900,1020)
	floor_body.add_child(shape)
	fixture.add_child(floor_body)
	player = PLAYER.instantiate()
	player.slot = slot
	player.name = "Player_%d" % (slot+1)
	if slot==1: player.character = ACROBAT
	player.position = Vector2(500,930)
	fixture.add_child(player)
	player.input.scripted = true
	await frames(10)
	if air:
		player.position.y = 600
		await frames(2)
		player._coyote_timer = 0
	player.input.dash_pressed = true
	player._try_start_dash()
	player.input.dash_pressed = false

func target(aparable := true) -> EnemyHitbox:
	var hitbox := EnemyHitbox.new()
	hitbox.parryable = aparable
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25
	shape.shape = circle
	hitbox.add_child(shape)
	hitbox.position = player.position+Vector2(0,-85)
	fixture.add_child(hitbox)
	return hitbox

func attempt() -> void:
	player.input.jump_pressed = true
	player._physics_process(1.0/60.0)
	player.input.jump_pressed = false
	await frames(2)

func _run() -> void:
	SaveGame.path = "user://test_dash_parry.json"
	for slot in 2:
		for trick in ["tumble","magic_smoke","cannonball","pirouette"]:
			for air in [false,true]:
				for portion in [0.0,0.5,0.9]:
					await setup(slot,trick,air)
					await frames(int(player._dash_length()*portion*60))
					player.set_physics_process(false)
					var object := target()
					await frames(2)
					var label := "P%d %s %s dash %d%%" % [slot+1,trick,"air" if air else "ground",int(portion*100)]
					check(player.is_dashing(),label+" still active before pressing jump")
					check(player.applause.parries==0,label+" never auto-parries without new jump press")
					await attempt()
					check(player.applause.parries==1 and not object.can_parry(String(player.name)),label+" new jump parries real overlap")
					check(not player.is_dashing() and player.velocity.y<0 and player._air_dash_available,label+" interrupts dash, bounces and restores air dash")
					check(player.parry.is_protected() and player.parry.is_spinning(),label+" keeps normal grace and animation")
					check(player.visual.visible and (player._dash_damage==null or not player._dash_damage.monitoring),label+" clears smoke/cannonball dash effects")
	# Errar não cancela o dash nem dá estrela/proteção extra.
	for aparable in [false,true]:
		await setup(0,"tumble")
		player.set_physics_process(false)
		var object := target(aparable)
		if aparable: object.position.x += 500
		await frames(2)
		await attempt()
		check(player.is_dashing() and player.applause.parries==0 and not player.parry.is_protected(),"missing or non-parry target keeps dash and gives no rewards")
	# Janela real: apertou ANTES de encostar, continua o dash e pega o alvo adiante.
	for air in [false,true]:
		await setup(0,"tumble",air)
		player.set_physics_process(false)
		var ahead := target()
		ahead.position.x += 210
		await frames(2)
		player.input.jump_pressed = true
		player._physics_process(1.0/60.0)
		player.input.jump_pressed = false
		check(player.is_dashing() and player.applause.parries==0,"early jump arms parry without stopping dash")
		player.set_physics_process(true)
		await frames(7)
		check(player.applause.parries==1 and not player.is_dashing(),"live dash reaches target within parry window / "+("air" if air else "ground"))
	# Teclado usa o mesmo aperto de pulo, sem comando ou tecla novos.
	await setup(0,"tumble")
	player.set_physics_process(false)
	player.input.scripted = false
	player.input.clear()
	target()
	await frames(2)
	Input.action_press(&"jump")
	player._physics_process(1.0/60.0)
	Input.action_release(&"jump")
	check(player.applause.parries==1 and not player.is_dashing(),"real keyboard jump action parries mid-dash")
	# No chão, sem dash: continua sendo pulo normal, mesmo sobre objeto aparável.
	await setup(0,"tumble",false)
	player._dash_timer = 0
	player.set_physics_process(false)
	target()
	await frames(2)
	await attempt()
	check(player.applause.parries==0 and player.velocity.y<0,"ordinary grounded jump is unchanged")
	# Celular: dois toques novos de pulo, separados pelo dash, pelo Input real.
	await setup(1,"tumble")
	player.set_physics_process(false)
	player.input.scripted = false
	player.input.clear()
	MobileControls.enable()
	await frames(3)
	var jump := InputEventScreenTouch.new()
	jump.index = 2
	jump.position = MobileControls._buttons[&"jump"].at
	jump.pressed = true
	MobileControls._input(jump)
	player.input.update()
	jump.pressed = false
	MobileControls._input(jump)
	player.input.update()
	target()
	await frames(2)
	jump.pressed = true
	MobileControls._input(jump)
	player._physics_process(1.0/60.0)
	check(player.applause.parries==1 and not player.is_dashing(),"second real touch of jump parries during dash")
	jump.pressed = false
	MobileControls._input(jump)
	MobileControls.release_all()
	fixture.queue_free()
	get_tree().current_scene = self
	await frames(2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ",failures)
	get_tree().quit(failures)
