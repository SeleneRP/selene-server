class_name ChunkedMap
extends Node

enum TileOperation {
	CREATE,
	REPLACE,
	REMOVE
}

var chunk_size = 8
var maps = []

var _chunks = {}

signal tiles_changed(tiles: Array, level: int)

func replace(tiles: Array, level: int):
	var changed_chunks = {}
	var changed_coords = {}
	for i in range(0, tiles.size(), 3):
		var tile_id = tiles[i]
		if tile_id == 0:
			continue
		var x = tiles[i + 1]
		var y = tiles[i + 2]
		var coords_key = "%d,%d" % [x, y]
		var chunk_x = x / chunk_size
		var chunk_y = y / chunk_size
		var chunk = ensure_chunk_at_cell(chunk_x, chunk_y, level)
		if not changed_coords.has(coords_key):
			chunk.remove_tiles(x, y)
		chunk.create_tile(x, y, tile_id)
		changed_chunks[chunk.key] = chunk
		changed_coords[coords_key] = true
	for chunk in changed_chunks.values():
		tiles_changed.emit(chunk.tiles, chunk.level)

func get_tiles_in_cell(cell: Vector3i):
	var chunk = get_chunk_at_cell(cell.x, cell.y, cell.z)
	return chunk.tiles if chunk else []

func get_tile_at(x: int, y: int, z: int):
	var chunk = get_chunk_at(x, y, z)
	return chunk.get_tile(x, y) if chunk else 0

func _get_chunk_key(x: int, y: int, z: int):
	return "%d,%d,%d" % [x, y, z]

func get_chunk_cell(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(floor(x / float(chunk_size)), floor(y / float(chunk_size)), z)

func get_chunk_at(x: int, y: int, z: int):
	var chunk_cell = get_chunk_cell(x, y, z)
	return get_chunk_at_cell(chunk_cell.x, chunk_cell.y, chunk_cell.z)

func get_chunk_at_cell(x: int, y: int, z: int):
	return _chunks.get(_get_chunk_key(x, y, z))

func ensure_chunk_at(x: int, y: int, z: int) -> MapChunk:
	var chunk_x = floor(x / float(chunk_size))
	var chunk_y = floor(y / float(chunk_size))
	return ensure_chunk_at_cell(chunk_x, chunk_y, z)

func ensure_chunk_at_cell(x: int, y: int, z: int) -> MapChunk:
	var chunk_key = _get_chunk_key(x, y, z)
	if not _chunks.has(chunk_key):
		var chunk = MapChunk.new(x, y, z, chunk_size)
		chunk.key = chunk_key
		_chunks[chunk_key] = chunk
		return chunk
	return _chunks[chunk_key]
