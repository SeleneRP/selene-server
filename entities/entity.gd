class_name Entity
extends Node

@export var id: int
@export var position: Vector3
@export var map: String
@export var cell: Vector3i
@export var data: Dictionary

var manager: EntityManager
var last_added_visual_id = 0

func clear_visuals():
	for child in get_children():
		if child is EntityVisual:
			remove_child(child)

func add_visual(visual_name: String):
	last_added_visual_id += 1
	var visual = EntityVisual.new()
	visual.id = last_added_visual_id
	visual.name = "visual#" + str(last_added_visual_id)
	visual.visual_name = visual_name
	visual.removed_by_script.connect(func():
		manager.entity_visual_removed.emit(self, visual)
	)
	visual.tint_changed.connect(func(_tint):
		manager.entity_visual_changed.emit(self, visual)
	)
	add_child(visual)
	manager.entity_visual_added.emit(self, visual)
	return visual

func get_visuals():
	var visuals = []
	for child in get_children():
		if child is EntityVisual:
			visuals.append(child)
	return visuals

func get_data():
	return data

func is_spawned():
	return map != ""

func _lua_AddVisual(pvm: LuauVM):
	var visual_name = pvm.luaL_checkstring(2)
	var visual = add_visual(visual_name)
	pvm.lua_pushobject(visual)
	return 1

func _lua_Spawn(pvm: LuauVM):
	var map_id = pvm.luaL_checkstring(2)
	manager.spawn_entity(id, map_id)
	return 0