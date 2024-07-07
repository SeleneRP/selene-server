class_name Entity
extends Node

@export var id: int
@export var position: Vector3
@export var map: String
@export var cell: Vector3i
@export var data: Dictionary

var last_added_visual_id = 0

func clear_visuals():
    for child in get_children():
        if child is EntityVisual:
            remove_child(child)

func add_visual(visual_name: String):
    last_added_visual_id += 1
    var visual = EntityVisual.new()
    visual.id = last_added_visual_id
    visual.name = visual_name
    add_child(visual)
    return visual

func get_data():
    return data

func is_spawned():
    return map != ""