extends Node
## Exporta o leiaute do parque (alturas do terreno, trilhas, portas e colisões) para o Blender montar a
## cenografia em cima do mesmo chão: tools/blender/park_render.py lê build/park/layout.json.
## Godot --headless --path . res://tools/world_layout_export.tscn

func _ready() -> void:
	SaveGame.path = "user://layout_export_save.json"
	SaveGame.reset()
	var world: Node3D = load(Levels.MAP).instantiate()
	add_child(world)
	await get_tree().process_frame
	var terrain: WorldTerrain = world._terrain
	var doors := []
	for door: WorldDoor in world.get_tree().get_nodes_in_group(&"world_doors"):
		var shapes := []
		for body in door.find_children("*", "StaticBody3D", true, false):
			for shape: CollisionShape3D in body.find_children("*", "CollisionShape3D", false, false):
				var p := shape.global_position
				if shape.shape is BoxShape3D:
					shapes.append({"box": _v(shape.shape.size), "at": _v(p)})
				elif shape.shape is CylinderShape3D:
					shapes.append({"cylinder": [shape.shape.radius, shape.shape.height], "at": _v(p)})
		doors.append({"name": door.name, "title": door.title, "landmark": door.landmark, "level": door.level_id,
			"shop": door.opens_shop, "dressing": door.opens_dressing_room, "at": _v(door.global_position),
			"radius": door.radius, "height": door.height, "front": _v(door.front_point()), "shapes": shapes})
	var paths := []
	for samples in terrain._samples:
		var points := []
		for p in samples:
			points.append([p.x, p.y])
		paths.append(points)
	var spawns := []
	for marker in world.get_node("PlayerSpawner").get_children():
		if marker is Marker3D:
			spawns.append(_v(marker.global_position))
	var data := {"size": [terrain.size.x, terrain.size.y], "cells": [terrain.cells.x, terrain.cells.y],
		"heights": Array(terrain._grid), "path_width": terrain.path_width, "paths": paths, "doors": doors,
		"spawns": spawns, "lamps": _pairs(world.LAMPS), "camera_pitch": world.CAMERA_PITCH}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/park"))
	var file := FileAccess.open("res://build/park/layout.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("LAYOUT_EXPORT ok ", doors.size(), " portas")
	get_tree().quit()

func _v(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

func _pairs(list: Array) -> Array:
	return list.map(func(p: Vector2) -> Array: return [p.x, p.y])
