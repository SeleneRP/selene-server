class_name EntityScriptLibrary
extends Node

var network_manager: NetworkManager
var entity_manager: EntityManager
var chunked_map: ChunkedMap

func get_script_bindings():
    return {
        "create_entity" = _create_entity,
        "add_entity_visual" = _add_entity_visual,
        "spawn_entity" = _spawn_entity,
        "get_entity" = _get_entity,
        "get_entity_data" = _get_entity_data,
    }

func _create_entity(x: float, y: float, z: float) -> int:
    var entity = entity_manager.create_entity()
    entity.position = Vector3(x, y, z)
    entity.cell = chunked_map.get_chunk_cell(x, y, z)
    return entity.id

func _add_entity_visual(entity_id: int, visual: String):
    var entity = entity_manager.get_entity(entity_id)
    if entity:
        entity.add_visual(visual)

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