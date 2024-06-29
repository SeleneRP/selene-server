class_name MapScriptLibrary
extends Node

var script_manager: ScriptManager
var map_manager: MapManager
var chunked_map: ChunkedMap
var id_mappings_cache: IdMappingsCache

func get_script_bindings():
	return {
		"load_map" = _load_map,
		"get_tile" = _get_tile
	}

func _load_map(bundle_id: String, map_name: String):
	var map = map_manager.load_map(bundle_id, map_name)
	if not map:
		return script_manager.create_error("Map not found: %s:%s" % [bundle_id, map_name])

func _get_tile(x: int, y: int, z: int):
	var tile_id = chunked_map.get_tile_at(x, y, z)
	if tile_id == 0:
		return ""
	return id_mappings_cache.get_name_from_id("tiles", tile_id)