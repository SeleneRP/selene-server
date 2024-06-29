class_name Entity
extends Node

@export var id: int
@export var position: Vector3
@export var map: String
@export var cell: Vector3i
@export var data: Dictionary

func clear_visuals():
    for child in get_children():
        if child is EntityVisual:
            remove_child(child)

func add_visual(name: String):
    var visual = EntityVisual.new()
    visual.name = name
    add_child(visual)

func get_data():
    return data

func is_spawned():
    return map != ""