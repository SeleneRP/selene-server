class_name EntityManager
extends Node

var last_added_id = 0

func create_entity(position: Vector3):
    last_added_id += 1
    var entity = Entity.new()
    entity.name = str(last_added_id)
    entity.position = position
    add_child(entity)
    return last_added_id

func get_entity(entity_id: int) -> Entity:
    return get_node_or_null(str(entity_id))