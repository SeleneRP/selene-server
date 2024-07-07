class_name EntityScriptLibrary
extends Node

var network_manager: NetworkManager
var entity_manager: EntityManager
var chunked_map: ChunkedMap

func get_script_bindings():
	return {
		"create_entity" = _create_entity,
		"add_entity_visual" = _add_entity_visual,
		"remove_entity_visual" = _remove_entity_visual,
		"set_entity_visual_tint" = _set_entity_visual_tint,
		"spawn_entity" = _spawn_entity,
		"get_entity" = _get_entity,
		"get_entity_data" = _get_entity_data,
	}

func _create_entity(x: float, y: float, z: float) -> int:
	var entity = entity_manager.create_entity()
	entity.position = Vector3(x, y, z)
	entity.cell = chunked_map.get_chunk_cell(x, y, z)
	return entity.id

func _add_entity_visual(entity_id: int, visual_name: String):
	var entity = entity_manager.get_entity(entity_id)
	if entity:
		var visual = entity.add_visual(visual_name)
		entity_manager.entity_visual_added.emit(entity, visual)
		return visual.id

func _remove_entity_visual(entity_id:int, visual_id: int):
	var entity = entity_manager.get_entity(entity_id)
	if entity:
		var visual = entity.remove_visual(visual_id)
		if visual:
			entity_manager.entity_visual_removed.emit(entity, visual)

func _set_entity_visual_tint(entity_id: int, visual_id: int, r: float, g: float, b: float, a: float):
	var entity = entity_manager.get_entity(entity_id)
	if entity:
		var visual = entity.get_visual(visual_id)
		if visual:
			visual.color = Color(r, g, b, a)
			entity_manager.entity_visual_changed.emit(entity, visual)

func _spawn_entity(entity_id: int, map_id: String):
	entity_manager.spawn_entity(entity_id, map_id)

func _get_entity(entity_id: int):
	return entity_manager.get_entity(entity_id)

func _get_entity_data(entity_id: int) -> Dictionary:
	var entity = entity_manager.get_entity(entity_id)
	if entity:
		return entity.get_data()
	else:
		return {}
