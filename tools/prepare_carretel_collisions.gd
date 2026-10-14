extends SceneTree
const FRAMES := preload("res://bosses/madame_carretel/art/effects/carretel_effects.tres")
func _initialize() -> void:
	var result: Resource = load("res://bosses/madame_carretel/carretel_collision_frames.gd").new()
	for key in FRAMES.get_animation_names():
		for frame in 4:
			var image := FRAMES.get_frame_texture(key,frame).get_image()
			if image.is_compressed(): image.decompress()
			var mask := BitMap.new()
			mask.create_from_image_alpha(image,0.30)
			var bounds := Rect2i(Vector2i.ZERO,image.get_size())
			# Fecha furinhos de grão de até2px no contorno físico, não na pintura.
			# Evita polígonos autoencostados produzidos pela textura pintada.
			mask.grow_mask(2,bounds)
			mask.grow_mask(-2,bounds)
			var shapes: Array[PackedVector2Array] = []
			for polygon in mask.opaque_to_polygons(bounds,1.0):
				var area := 0.0
				for i in polygon.size(): area += polygon[i].cross(polygon[(i+1)%polygon.size()])
				if absf(area)<180.0: continue
				var shifted := PackedVector2Array()
				for point: Vector2 in polygon: shifted.append(point-Vector2(512,512))
				# Decompor aqui evita triangulação durante a física no celular.
				var indices := Geometry2D.triangulate_polygon(shifted)
				if indices.is_empty():
					assert(absf(area)*0.5<1000,"Main silhouette cannot be discarded: "+String(key)+str(frame))
					print("Cosmetic fragment omitted: ",key," frame ",frame," area ",absf(area)*0.5)
					continue
				var convex := Geometry2D.decompose_polygon_in_convex(shifted)
				if not convex.is_empty():
					shapes.append_array(convex)
				else:
					for i in range(0,indices.size(),3):
						shapes.append(PackedVector2Array([shifted[indices[i]],shifted[indices[i+1]],shifted[indices[i+2]]]))
			assert(not shapes.is_empty(),"Empty collision "+String(key))
			result.frames["%s:%d" % [key,frame]] = shapes
	var error := ResourceSaver.save(result,"res://bosses/madame_carretel/art/effects/carretel_collision.tres")
	print("24 precomputed collision frames: ",error)
	quit(error)
