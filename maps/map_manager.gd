class_name MapManager
extends Node

@export var bundles_dir = "server://bundles"

signal map_about_to_be_loaded(bundle_id: String, map_name: String)
signal map_loaded(map: SourceTileMap)

var _loaded_maps = {}

func load_map(bundle_id: String, map_name: String):
    var map_path = Selene.path(bundles_dir).path_join(bundle_id).path_join("server").path_join("maps").path_join("%s.json" % map_name)
    if FileAccess.file_exists(map_path):
        map_about_to_be_loaded.emit(bundle_id, map_name)
        var map_json = FileAccess.get_file_as_string(map_path)
        var map_data = JSON.parse_string(map_json)
        var map = SourceTileMap.new(bundle_id, map_name)
        map.load_from_json(map_data)
        _loaded_maps[bundle_id + ":" + map_name] = map
        map_loaded.emit(map)
        return map
    return null

func get_loaded_maps():
    return _loaded_maps