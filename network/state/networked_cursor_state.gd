class_name NetworkedCursorState
extends Node

var manager: NetworkManager
@onready var networked_cursor: NetworkedCursor = manager.get_networked("NetworkedCursor")

var peer_id: int