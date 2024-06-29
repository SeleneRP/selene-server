class_name NetworkListener
extends Node

signal peer_connected(id: int)
signal peer_disconnected(id: int)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func start(port: int, max_connections: int) -> int:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_connections)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	return error

func _on_peer_connected(id):
	peer_connected.emit(id)

func _on_peer_disconnected(id):
	peer_disconnected.emit(id)
