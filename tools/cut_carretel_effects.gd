extends SceneTree
## Recorte técnico das folhas Imagegen; não redesenha os efeitos.
const SOURCE := "res://docs/referencias/pecas/oficinas/carretel/efeitos/"
const OUT := "res://bosses/madame_carretel/art/effects/"
const CLIPS := {
	"needle": [12.0, true], "needle_parry": [12.0, true],
	"cut": [14.0, false], "tape": [12.0, true],
	"cloth": [8.0, false], "button": [12.0, true],
}
const SIZE := Vector2i(1024,1024)
const CENTER := Vector2i(512,512)

func division(source: Image, rect: Rect2i, vertical: bool, expected: int) -> int:
	var extent := source.get_width() if vertical else source.get_height()
	var best := expected
	var distance := INF
	for line in range(maxi(1,expected-extent/4),mini(extent-1,expected+extent/4)):
		var clear := true
		for at in range(rect.position.y if vertical else rect.position.x,rect.end.y if vertical else rect.end.x):
			if source.get_pixel(line if vertical else at,at if vertical else line).a>0.04:
				clear = false
				break
		if clear and absf(line-expected)<distance:
			distance = absf(line-expected)
			best = line
	assert(distance<INF, "Sprites touch: regenerate rather than crop drawing")
	return best

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var report := []
	for key: String in CLIPS:
		var source := Image.load_from_file(SOURCE+key+".png")
		assert(source != null, "Missing source "+key)
		source.convert(Image.FORMAT_RGBA8)
		var half := source.get_size()/2
		var split_y := division(source,Rect2i(Vector2i.ZERO,source.get_size()),false,half.y)
		var rectangles: Array[Rect2i] = []
		for row in 2:
			var strip := Rect2i(0,0 if row==0 else split_y,source.get_width(),split_y if row==0 else source.get_height()-split_y)
			var split_x := division(source,strip,true,half.x)
			rectangles.append(Rect2i(0,strip.position.y,split_x,strip.size.y))
			rectangles.append(Rect2i(split_x,strip.position.y,source.get_width()-split_x,strip.size.y))
		var cells: Array[Image] = []
		var pivots: Array[Vector2i] = []
		var fit := 1.0
		for i in 4:
			var cell := source.get_region(rectangles[i])
			# Zero RGB in almost-transparent pixels avoids dark/white fringes.
			for y in cell.get_height():
				for x in cell.get_width():
					if cell.get_pixel(x,y).a < 0.04:
						cell.set_pixel(x,y,Color(0,0,0,0))
			var bounds := cell.get_used_rect()
			assert(bounds.has_area(), "Empty frame "+key)
			# Anchors belong to the rigid tool, not its changing tail/hem.
			var pivot := half/2
			if key.begins_with("needle"):
				pivot = Vector2i([394,367,393,369][i], [428,428,307,307][i])
			elif key == "tape":
				pivot = Vector2i([808,832,828,833][i], [242,246,196,210][i])
			elif key == "cloth":
				# Only the rail fixes x; the unfolding lower hem must not move it.
				var rail := cell.get_region(Rect2i(0,bounds.position.y,cell.get_width(),80)).get_used_rect()
				pivot = Vector2i(rail.get_center().x,bounds.position.y+30)
			elif key == "button":
				pivot = Vector2i([500,512,502,512][i],[265,265,253,253][i])
			if key != "cloth":
				pivot += Vector2i(i%2,i/2)*half-rectangles[i].position
			var extent := maxi(maxi(pivot.x-bounds.position.x,bounds.end.x-pivot.x),
				maxi(pivot.y-bounds.position.y,bounds.end.y-pivot.y))
			fit = minf(fit,470.0/maxi(extent,1))
			cells.append(cell)
			pivots.append(pivot)
		frames.add_animation(StringName(key))
		frames.set_animation_speed(StringName(key),CLIPS[key][0])
		frames.set_animation_loop(StringName(key),CLIPS[key][1])
		for i in 4:
			var cell := cells[i]
			if fit<1.0:
				var resized := Vector2i((Vector2(cell.get_size())*fit).round())
				cell.resize(resized.x,resized.y,Image.INTERPOLATE_LANCZOS)
			var out := Image.create_empty(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
			out.fill(Color(0,0,0,0))
			out.blit_rect(cell,Rect2i(Vector2i.ZERO,cell.get_size()),CENTER-Vector2i((Vector2(pivots[i])*fit).round()))
			var path := OUT+"%s_%d.png" % [key,i+1]
			out.save_png(path)
			var texture := ImageTexture.create_from_image(out)
			texture.resource_path = path
			frames.add_frame(StringName(key),texture)
		report.append({"clip":key,"source_size":source.get_size(),"pivots":pivots,"uniform_scale":fit,"frames":4})
	var error := ResourceSaver.save(frames,OUT+"carretel_effects.tres")
	var log := FileAccess.open(OUT+"preparation.json",FileAccess.WRITE)
	log.store_string(JSON.stringify(report,"\t"))
	print("Carretel effects: ",report.size()," sequences / 24 frames, save = ",error)
	quit(0 if error==OK else 1)
