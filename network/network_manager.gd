class_name NetworkManager
extends Node

@export var handler_container: Node
@export var state_container: Node

var peer_template = preload ("res://peer_template.tscn")
var provided = {}

func provide(key: String, value: Variant):
	provided[key] = value
	if handler_container:
		for child in handler_container.get_children():
			if key in child:
				child[key] = provided[key]

func _ready():
	provide("network_manager", self)

func for_peer(peer_id: int):
	var peer_node = state_container.get_node_or_null(str(peer_id))
	if peer_node == null:
		peer_node = peer_template.instantiate()
		peer_node.name = str(peer_id)
		for child in peer_node.get_children():
			if "manager" in child:
				child.manager = self
			if "peer_id" in child:
				child.peer_id = peer_id
			for key in provided.keys():
				if key in child:
					child[key] = provided[key]
		state_container.add_child(peer_node)
	return peer_node

func _on_network_listener_peer_connected(id: int):
	for_peer(id)

func _on_network_listener_peer_disconnected(id: int):
	for_peer(id).queue_free()

func get_network_state(peer_id: int, key: String):
	return for_peer(peer_id).get_node_or_null(key)

func get_networked(key: String):
	return handler_container.get_node_or_null(key) if handler_container else null