extends SceneTree
## Separa as sequências 2x2, preserva pés/pivô e prepara SpriteFrames nativo.
const SOURCE := "res://docs/referencias/pecas/oficinas/carretel/"
const OUT := "res://bosses/madame_carretel/art/"
const CLIPS := {
	"idle": [6.0, true], "scissors": [8.0, false], "tape": [8.0, false],
	"needles": [8.0, false], "cloth": [7.0, false], "hurt": [10.0, false],
	"armor": [6.0, false], "armor_attack": [8.0, false], "defeat": [5.0, false],
}
const CANVAS := Vector2i(1024, 1024)
const FEET := Vector2i(512, 950)

func row_characters(image: Image, row: Rect2i) -> Array:
	var seen := PackedByteArray()
	seen.resize(row.size.x*row.size.y)
	seen.fill(0)
	var pieces := []
	for y in row.size.y:
		for x in row.size.x:
			var index := y*row.size.x+x
			if seen[index] or image.get_pixel(x,y+row.position.y).a < 0.2:
				continue
			var stack: Array[int] = [index]
			var pixels := PackedInt32Array()
			var bounds := Rect2i(x,y,1,1)
			seen[index] = 1
			while not stack.is_empty():
				var at: int = stack.pop_back()
				pixels.append(at)
				var p := Vector2i(at%row.size.x,at/row.size.x)
				bounds = bounds.expand(p)
				for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var q: Vector2i = p+delta
					if q.x<0 or q.y<0 or q.x>=row.size.x or q.y>=row.size.y:
						continue
					var k := q.y*row.size.x+q.x
					if not seen[k] and image.get_pixel(q.x,q.y+row.position.y).a >= 0.2:
						seen[k] = 1
						stack.append(k)
			if pixels.size()>500:
				pieces.append({"pixels":pixels,"bounds":bounds.grow(3).intersection(Rect2i(Vector2i.ZERO,row.size))})
	pieces.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.pixels.size()>b.pixels.size())
	if pieces.size()<2:
		push_error("Faltam poses separadas na linha")
		return []
	pieces.resize(2)
	pieces.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.bounds.get_center().x<b.bounds.get_center().x)
	var result := []
	for piece: Dictionary in pieces:
		var bounds: Rect2i = piece.bounds
		var out := Image.create_empty(bounds.size.x,bounds.size.y,false,Image.FORMAT_RGBA8)
		out.fill(Color(0,0,0,0))
		var mask := PackedByteArray()
		mask.resize(bounds.size.x*bounds.size.y)
		mask.fill(0)
		for at: int in piece.pixels:
			var p := Vector2i(at%row.size.x,at/row.size.x)-bounds.position
			for dy in range(-2,3):
				for dx in range(-2,3):
					var q := p+Vector2i(dx,dy)
					if q.x>=0 and q.y>=0 and q.x<bounds.size.x and q.y<bounds.size.y:
						mask[q.y*bounds.size.x+q.x] = 1
		for y in bounds.size.y:
			for x in bounds.size.x:
				if mask[y*bounds.size.x+x]:
					out.set_pixel(x,y,image.get_pixel(x+bounds.position.x,y+bounds.position.y+row.position.y))
		result.append(out)
	return result

# As folhas podem deslocar poses largas entre as colunas. Separar no vazio real,
# por linha, evita cortar a tesoura, luvas ou a saia como numa grade rígida.
func division(image: Image, region: Rect2i, vertical: bool, expected: int) -> int:
	var extent := image.get_width() if vertical else image.get_height()
	var low := maxi(1,expected-extent/5)
	var high := mini(extent-1,expected+extent/5)
	var scores := []
	var minimum := 2147483647
	for line in range(low,high):
		var count := 0
		var begin := region.position.y if vertical else region.position.x
		var end := region.end.y if vertical else region.end.x
		for at in range(begin,end):
			if image.get_pixel(line if vertical else at, at if vertical else line).a > 0.04:
				count += 1
		scores.append(count)
		minimum = mini(minimum,count)
	var best := expected
	var distance := INF
	var i := 0
	while i < scores.size():
		if scores[i] != minimum:
			i += 1
			continue
		var start := i
		while i < scores.size() and scores[i] == minimum:
			i += 1
		var middle := low+(start+i-1)/2
		if absf(middle-expected) < distance:
			distance = absf(middle-expected)
			best = middle
	assert(minimum == 0, "Poses touching: regenerate sheet instead of cutting through drawing")
	return best

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var resources := SpriteFrames.new()
	resources.remove_animation(&"default")
	var report := []
	for key: String in CLIPS:
		var path := SOURCE + "anim_" + key + ".png"
		if not FileAccess.file_exists(path):
			continue
		var source := Image.load_from_file(path)
		source.convert(Image.FORMAT_RGBA8)
		var y_cut := division(source,Rect2i(Vector2i.ZERO,source.get_size()),false,source.get_height()/2)
		var cells: Array[Image] = []
		var feet: Array[Vector2i] = []
		var scale := 1.0
		var upper := row_characters(source,Rect2i(0,0,source.get_width(),y_cut))
		var lower := row_characters(source,Rect2i(0,y_cut,source.get_width(),source.get_height()-y_cut))
		if upper.size()!=2 or lower.size()!=2:
			quit(1)
			return
		var extracted := upper+lower
		for i in 4:
			var cell: Image = extracted[i]
			var bounds := Rect2i()
			var found := false
			for y in cell.get_height():
				for x in cell.get_width():
					if cell.get_pixel(x,y).a < 0.04:
						cell.set_pixel(x,y,Color(0,0,0,0))
						continue
					if not found:
						bounds = Rect2i(x,y,1,1)
						found = true
					else:
						bounds = bounds.expand(Vector2i(x,y))
			assert(found, "Empty frame " + key)
			bounds.size += Vector2i.ONE
			# Pivô horizontal no centro dos sapatos, sem mudar com braços/tesoura.
			var foot_low := cell.get_width()
			var foot_high := 0
			for y in range(maxi(0,bounds.end.y-14),bounds.end.y):
				for x in cell.get_width():
					if cell.get_pixel(x,y).a > 0.25:
						foot_low = mini(foot_low,x)
						foot_high = maxi(foot_high,x)
			var foot := Vector2i((foot_low+foot_high)/2,bounds.end.y)
			cells.append(cell)
			feet.append(foot)
			# Uma escala por folha: não estica a personagem a cada quadro.
			scale = minf(scale, 860.0/bounds.size.y)
			scale = minf(scale, 900.0/maxi(1,2*maxi(foot.x-bounds.position.x,bounds.end.x-foot.x)))
		resources.add_animation(StringName(key))
		resources.set_animation_speed(StringName(key),CLIPS[key][0])
		resources.set_animation_loop(StringName(key),CLIPS[key][1])
		for i in 4:
			var cell: Image = cells[i]
			if scale < 1.0:
				var size := Vector2i((Vector2(cell.get_size())*scale).round())
				cell.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
			var origin := FEET - Vector2i((Vector2(feet[i])*scale).round())
			var out := Image.create_empty(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8)
			out.fill(Color(0,0,0,0))
			out.blit_rect(cell,Rect2i(Vector2i.ZERO,cell.get_size()),origin)
			var png := OUT + "%s_%d.png" % [key,i+1]
			out.save_png(png)
			var texture := ImageTexture.create_from_image(out)
			texture.resource_path = png
			var duration := 1.0
			if key == "idle":
				duration = 0.5 if i == 2 else 2.0
			else:
				duration = [4.0, 2.0, 1.0, 3.0][i]
			resources.add_frame(StringName(key),texture,duration)
		report.append({"clip":key,"source":source.get_size(),"scale":scale,"frames":4})
	var error := ResourceSaver.save(resources,OUT+"carretel_frames.tres")
	var log := FileAccess.open(OUT+"preparation.json",FileAccess.WRITE)
	log.store_string(JSON.stringify(report,"\t"))
	print("Carretel: ",report.size()," clips; SpriteFrames save = ",error)
	quit(0 if error == OK else 1)
