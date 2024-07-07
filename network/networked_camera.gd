class_name NetworkedCamera
extends Node

var network_manager: NetworkManager

signal camera_moved(peer_id: int, old_position: Vector2i, position: Vector2i)
signal camera_level_changed(peer_id: int, old_level: int, level: int)

func get_network_state(peer_id: int) -> NetworkedCameraState:
	return network_manager.get_network_state(peer_id, "NetworkedCameraState")

@rpc("authority", "call_remote", "reliable")
func c_set_camera_position(_position: Vector2i, _level: int):
	pass

@rpc("authority", "call_remote", "reliable")
func c_set_camera_mode(_mode: CameraMode.Keys):
	pass

@rpc("authority", "call_remote", "reliable")
func c_set_camera_target(_entity_id: int):
	pass

@rpc("any_peer", "call_remote", "reliable")
func s_set_camera_position(position: Vector2i, level: int):
	_try_set_camera_position_from_client(multiplayer.get_remote_sender_id(), position, level)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func s_sync_camera_position(position: Vector2i, level: int):
	_try_set_camera_position_from_client(multiplayer.get_remote_sender_id(), position, level)

func set_camera_position(peer_id: int, position: Vector2i, level: int):
	var state = get_network_state(peer_id)
	if _set_camera_position_if_changed(peer_id, state, position, level):
		c_set_camera_position.rpc_id(peer_id, position, level)

func set_camera_mode(peer_id: int, mode: CameraMode.Keys):
	var state = get_network_state(peer_id)
	state.mode = mode
	c_set_camera_mode.rpc_id(peer_id, mode)

func set_camera_target(peer_id: int, entity_id: int):
	var state = get_network_state(peer_id)
	state.target_entity_id = entity_id
	c_set_camera_target.rpc_id(peer_id, entity_id)

func _try_set_camera_position_from_client(peer_id: int, position: Vector2i, level: int):
	var state = get_network_state(peer_id)
	if not CameraMode.is_authorative_on_client(state.mode):
		c_set_camera_position.rpc_id(peer_id, state.position, state.level)
		c_set_camera_mode.rpc_id(peer_id, state.mode)
		return
	
	_set_camera_position_if_changed(peer_id, state, position, level)

func _set_camera_position_if_changed(peer_id: int, state: NetworkedCameraState, position: Vector2i, level: int):
	var old_position = state.position
	var old_level = state.level
	state.position = position
	state.level = level
	if old_level != level:
		camera_level_changed.emit(peer_id, old_level, level)
	if old_position != position:
		camera_moved.emit(peer_id, old_position, position)
	return old_position != position or old_level != level