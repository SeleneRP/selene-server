class_name MapChunk

var key = ""
var cell_x = 0
var cell_y = 0
var level = 0
var cell_size = 8
var tiles = []
var _tile_indices_by_position = {}

func _init(x: int, y: int, p_level: int, size: int):
    cell_x = x
    cell_y = y
    level = p_level
    cell_size = size

func create_tile(x: int, y: int, tile_id: int):
    var tile_index = tiles.size()
    tiles.append(tile_id)
    tiles.append(x)
    tiles.append(y)
    var coords_key = "%d,%d" % [x, y]
    var tile_indices_by_position = _tile_indices_by_position.get(coords_key, [])
    tile_indices_by_position.append(tile_index)
    _tile_indices_by_position[coords_key] = tile_indices_by_position

func remove_tiles(x: int, y: int):
    var coords_key = "%d,%d" % [x, y]
    var tile_indices_by_position = _tile_indices_by_position.get(coords_key, [])
    for tile_index in tile_indices_by_position:
        tiles[tile_index] = 0

func remove_tile(x: int, y: int, tile_id: int):
    var coords_key = "%d,%d" % [x, y]
    var tile_indices_by_position = _tile_indices_by_position.get(coords_key, [])
    for tile_index in tile_indices_by_position:
        if tiles[tile_index] == tile_id:
            tiles[tile_index] = 0
            break

func get_tile(x: int, y: int):
    var coords_key = "%d,%d" % [x, y]
    var tile_indices_by_position = _tile_indices_by_position.get(coords_key, [])
    for tile_index in tile_indices_by_position:
        if tiles[tile_index] != 0:
            return tiles[tile_index]
    return 0