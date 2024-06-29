class_name NetworkedMap
extends Node

var network_manager: NetworkManager
var chunked_map: ChunkedMap

func get_network_state(peer_id: int):
	return network_manager.get_network_state(peer_id, "NetworkedMapState")

@rpc("authority", "call_remote", "reliable")
func c_set_tiles(_level: int, _tiles: Array):
	pass

func _on_networked_camera_camera_moved(peer_id: int, _old_position: Vector2i, position: Vector2i):
	var state = get_network_state(peer_id)
	var camera_state = network_manager.get_network_state(peer_id, "NetworkedCameraState")
	_watch_chunks_around(peer_id, state, position, camera_state.level)

func _watch_chunks_around(peer_id: int, state: NetworkedMapState, position: Vector2i, level: int):
	var center_cell = chunked_map.get_chunk_cell(position.x, position.y, level)
	var watch_range = state.watch_range
	for x in range(-watch_range, watch_range + 1):
		for y in range(-watch_range, watch_range + 1):
			for z in range(-watch_range, watch_range + 1):
				var cell = Vector3i(center_cell.x + x, center_cell.y + y, level + z)
				_watch_chunk(peer_id, state, cell)

func _watch_chunk(peer_id: int, state: NetworkedMapState, cell: Vector3i):
	var watched_chunks = state.watched_chunks
	if not watched_chunks.has(cell):
		watched_chunks[cell] = cell
		var tiles = chunked_map.get_tiles_in_cell(cell)
		if tiles.size() > 0:
			c_set_tiles.rpc_id(peer_id, cell.z, tiles)

func _unwatch_chunk(_peer_id: int, state: NetworkedMapState, cell: Vector3i):
	state.watched_chunks.erase(cell)
