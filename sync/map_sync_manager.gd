class_name MapSyncManager
extends Node

var _chunked_map: ChunkedMap
var default_watch_range = 3
var watch_range_by_peer = {}
var watched_chunks_by_peer = {}

func _init(chunked_map: ChunkedMap):
    _chunked_map = chunked_map

#func bind_camera(networked_camera: NetworkedCamera):
#    networked_camera.camera_moved.connect(_on_camera_moved)

func _on_camera_moved(id: int, position: Vector2i, level: int):
    watch_chunks_around(id, position, level)

func watch_chunks_around(peer_id: int, position: Vector2i, level: int):
    var center_cell = _chunked_map.get_chunk_cell(position.x, position.y, level)
    var watch_range = watch_range_by_peer.get(peer_id, default_watch_range)
    for x in range(-watch_range, watch_range + 1):
        for y in range(-watch_range, watch_range + 1):
            for z in range(-watch_range, watch_range + 1):
                var cell = Vector3i(center_cell.x + x, center_cell.y + y, level + z)
                watch_chunk(peer_id, cell)

func watch_chunk(peer_id: int, cell: Vector3i):
    var watched_chunks = watched_chunks_by_peer.get(peer_id, {})
    if not watched_chunks.has(cell):
        watched_chunks[cell] = cell
        watched_chunks_by_peer[peer_id] = watched_chunks
        send_chunk(peer_id, cell)

func unwatch_chunk(peer_id: int, cell: Vector3i):
    var watched_chunks = watched_chunks_by_peer.get(peer_id, {})
    watched_chunks.erase(cell)
    watched_chunks_by_peer[peer_id] = watched_chunks

func send_chunk(peer_id: int, cell: Vector3i):
    var networked_map = Selene.get_networked_map()
    var tiles = _chunked_map.get_tiles_in_cell(cell)
    if not tiles.is_empty():
        networked_map.c_set_tiles.rpc_id(peer_id, tiles, cell.z)
