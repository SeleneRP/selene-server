extends RefCounted
class_name SourceTileMap

class MapLayer:
	var level = 0
	var tiles = []

var bundle_id = ""
var name = ""
var x = 0
var y = 0
var width = 0
var height = 0
var mappings = {}
var layers: Array[MapLayer] = []

func _init(p_bundle_id: String, p_name: String):
	bundle_id = p_bundle_id
	name = p_name

func load_from_json(json):
	x = json["x"]
	y = json["y"]
	width = json["width"]
	height = json["height"]
	mappings = json["mappings"]
	for layer in json["layers"]:
		var map_layer = MapLayer.new()
		map_layer.level = layer["level"]
		map_layer.tiles = layer["tiles"]
		layers.append(map_layer)

func merge_into(chunked_map: ChunkedMap, id_mappings_cache: IdMappingsCache):
	chunked_map.maps.append(self)
	var changed_chunks = {}
	var invalid_tiles = []
	for layer in layers:
		var level = layer.level
		for tile in layer.tiles:
			if tile.id == null or tile.x == null or tile.y == null:
				Selene.log_error("Error when merging map. Map '%s' seems to be corrupt." % name)
				return
				
			var tile_name = mappings.get(str(tile.id))
			if not tile_name:
				invalid_tiles.append(tile)
				continue
			var tile_id = id_mappings_cache.get_id("tiles", tile_name)
			var tile_op = tile.op if "op" in tile else ChunkedMap.TileOperation.CREATE
			var abs_x = tile.x + x
			var abs_y = tile.y + y
			var chunk_x = abs_x / chunked_map.chunk_size
			var chunk_y = abs_y / chunked_map.chunk_size
			var chunk = chunked_map.ensure_chunk_at_cell(chunk_x, chunk_y, level)
			if tile_op == ChunkedMap.TileOperation.REPLACE:
				chunk.remove_tiles(abs_x, abs_y)
			if tile_op == ChunkedMap.TileOperation.CREATE or tile_op == ChunkedMap.TileOperation.REPLACE:
				chunk.create_tile(abs_x, abs_y, tile_id)
			elif tile_op == ChunkedMap.TileOperation.REMOVE:
				chunk.remove_tile(abs_x, abs_y, tile_id)
			changed_chunks[chunk.key] = chunk
	var invalid_tiles_by_id = {}
	for invalid_tile in invalid_tiles:
		if not invalid_tiles_by_id.has(invalid_tile.id):
			invalid_tiles_by_id[invalid_tile.id] = []
		invalid_tiles_by_id[invalid_tile.id].append(invalid_tile)
	for invalid_tile_id in invalid_tiles_by_id.keys():
		var invalid_tiles_of_id = invalid_tiles_by_id[invalid_tile_id]
		var example_tile = invalid_tiles_of_id[0]
		if invalid_tiles_of_id.size() > 1:
			Selene.log_error("Invalid tile id %d at (%d, %d) (%d more)" % [example_tile.id, x + example_tile.x, y + example_tile.y, invalid_tiles_of_id.size() - 1])
		else:
			Selene.log_error("Invalid tile id %d at (%d, %d)" % [example_tile.id, x + example_tile.x, y + example_tile.y])
	for chunk in changed_chunks.values():
		chunked_map.tiles_changed.emit(chunk.tiles, chunk.level)
	Selene.log("Merged %d chunks of map '%s'" % [changed_chunks.size(), name], ["success"])