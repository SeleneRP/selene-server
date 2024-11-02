class_name NetworkedCursor
extends Node

var network_manager: NetworkManager

func get_network_state(peer_id: int):
	return network_manager.get_network_state(peer_id, "NetworkedCursorState")

@rpc("authority", "call_remote", "reliable")
func c_add_cursor_visual(_visual_id: int, _visual_name: String, _tint: Color):
	pass
    
@rpc("authority", "call_remote", "reliable")
func c_set_cursor_visual_tint(_visual_id: int, _tint: Color):
	pass

@rpc("authority", "call_remote", "reliable")
func c_remove_cursor_visual(_visual_id: int):
	pass

@rpc("authority", "call_remote", "reliable")
func c_clear_cursor():
	pass

func clear_cursor(peer_id: int):
	print_verbose("[", peer_id, "] clear_cursor")
	c_clear_cursor.rpc_id(peer_id)

func add_cursor_visual(peer_id: int, visual_name: String):
	var visual_id = 0
	print_verbose("[", peer_id, "] add_cursor_visual ", visual_name, " (id: ", visual_id, ")")
	c_add_cursor_visual.rpc_id(peer_id, visual_id, visual_name, Color.WHITE)

func set_cursor_visual_tint(peer_id: int, visual_id: int, tint: Color):
	print_verbose("[", peer_id, "] set_cursor_visual_tint ", visual_id, " ", tint)
	c_set_cursor_visual_tint.rpc_id(peer_id, visual_id, tint)

func remove_cursor_visual(peer_id: int, visual_id: int):
	print_verbose("[", peer_id, "] remove_cursor_visual ", visual_id)
	c_remove_cursor_visual.rpc_id(peer_id, visual_id)