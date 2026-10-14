extends SceneTree
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	print(("OK " if ok else "FAIL ")+label)
	if not ok: failures += 1

func key(preview: Control, code: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = code
	preview._input(event)

func _run() -> void:
	var preview: Control = load("res://tools/carretel_arena_preview.tscn").instantiate()
	root.add_child(preview)
	preview.demo.paused = true
	var arena: Node2D = preview.arena
	check(arena!=null and arena.visible,"clean painted arena loads")
	check(arena.get_child_count()==1 and arena.get_child(0) is Sprite2D,"only one static painting: no foreground/clutter/particles")
	check(arena.z_index<preview.demo.z_index,"arena stays behind character and attacks")
	check(not preview.hud.visible and not preview.background.visible,"clean preview has no UI or flat background overlay")
	var painting: Sprite2D = arena.painting
	var extent := painting.get_rect().size*painting.scale
	check(painting.position.x<=0 and painting.position.x+extent.x>=1920 and extent.y>=1080,"painting covers full viewport without borders")
	check(is_equal_approx(painting.scale.x,painting.scale.y),"background not distorted")
	var ground: float = painting.position.y+arena.SOURCE_GROUND_Y*painting.scale.y
	check(absf(ground-preview.demo.position.y)<1.0,"painted floor aligned with boss feet within one pixel")
	for i in preview.keys.size():
		preview._select(i)
		preview.demo.seek(preview.demo.ATTACKS[preview.keys[i]].warning+0.24)
		check(preview.demo.effects[0].visible and arena.visible and not preview.hud.visible,String(preview.keys[i])+" visible over clean arena")
	key(preview,KEY_H)
	check(preview.hud.visible,"H reveals controls")
	key(preview,KEY_H)
	check(not preview.hud.visible,"H hides controls again")
	key(preview,KEY_L)
	check(not arena.visible and preview.background.visible,"light comparison backdrop works")
	key(preview,KEY_L)
	check(arena.visible and not preview.background.visible,"return to atelier backdrop works")
	key(preview,KEY_ENTER)
	check(not preview.demo.paused and is_zero_approx(preview.demo.elapsed),"Enter restarts attack")
	key(preview,KEY_SPACE)
	var held: float = preview.demo.elapsed
	await create_timer(0.1).timeout
	check(preview.demo.paused and preview.demo.elapsed==held,"Space pauses full synchronized action")
	var before: int = preview.index
	key(preview,KEY_RIGHT)
	check(preview.index==posmod(before+1,preview.keys.size()),"arrows select next attack")
	preview.queue_free()
	await process_frame
	print("FAILURES: ",failures)
	quit(failures)
