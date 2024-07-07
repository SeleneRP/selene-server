class_name EntityManager
extends Node

signal entity_spawned(entity: Entity)
signal entity_despawned(entity: Entity)

var last_added_id = 0

func create_entity():
    last_added_id += 1
    var entity = Entity.new()
    entity.id = last_added_id
    entity.name = str(last_added_id)
    add_child(entity)
    return entity

func get_entity(entity_id: int) -> Entity:
    return get_node_or_null(str(entity_id))

func get_entities_in_cell(cell: Vector3i):
    var entities = []
    for child in get_children():
        if child.cell == cell and child.is_spawned():
            entities.append(child)
    return entities

func spawn_entity(entity_id: int, map_id: String):
    var entity = get_entity(entity_id)
    if entity:
        entity.map = map_id
        entity_spawned.emit(entity)

func despawn_entity(entity_id: int):
    var entity = get_entity(entity_id)
    if entity:
        entity.map = ""
        entity_despawned.emit(entity)