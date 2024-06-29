class_name TileDirections
extends Node

enum Keys {
	None,
	SouthEast,
	South,
	SouthWest,
	West,
	NorthWest,
	North,
	NorthEast,
	East,
	Up,
	Down
}

static var horizontal_directions = [Keys.South, Keys.SouthWest, Keys.West, Keys.NorthWest, Keys.North, Keys.NorthEast, Keys.East, Keys.SouthEast]

static func get_direction_name(direction: Keys) -> String:
	return Keys.keys()[direction].to_lower()

static func apply_offset(pos: Vector2i, direction: Keys) -> Vector2i:
	return pos + get_direction_offset(direction)

static func get_direction_offset(direction: Keys) -> Vector2i:
	match direction:
		Keys.SouthEast:
			return Vector2i(1, 1)
		Keys.South:
			return Vector2i(0, 1)
		Keys.SouthWest:
			return Vector2i(-1, 1)
		Keys.East:
			return Vector2i(1, 0)
		Keys.West:
			return Vector2i(-1, 0)
		Keys.NorthEast:
			return Vector2i(1, -1)
		Keys.North:
			return Vector2i(0, -1)
		Keys.NorthWest:
			return Vector2i(-1, -1)
		Keys.Up:
			return Vector2i(0, 0)
		Keys.Down:
			return Vector2i(0, 0)
		_:
			return Vector2i(0, 0)

static func get_iso_offset(direction: Keys) -> Vector2:
	var wf = 1
	var wh = 0.5
	var hf = 1
	var hh = 0.5
	match direction:
		Keys.SouthEast:
			return Vector2(wf, 0)
		Keys.South:
			return Vector2(wh, hh)
		Keys.SouthWest:
			return Vector2(0, hf)
		Keys.East:
			return Vector2(wh, -hh)
		Keys.West:
			return Vector2(-wh, hh)
		Keys.NorthEast:
			return Vector2(0, -hf)
		Keys.North:
			return Vector2(-wh, -hh)
		Keys.NorthWest:
			return Vector2(-wf, 0)
		_:
			return Vector2(0, 0)

static func get_bit_mask(direction: Keys) -> int:
	match direction:
		Keys.SouthEast:
			return 128
		Keys.South:
			return 64
		Keys.SouthWest:
			return 32
		Keys.East:
			return 16
		Keys.West:
			return 8
		Keys.NorthEast:
			return 4
		Keys.North:
			return 2
		Keys.NorthWest:
			return 1
		_:
			return 0

static func create_bit_mask(directions: Array[Keys]):
	var mask = 0
	for dir in directions:
		mask |= get_bit_mask(dir)
	return mask

static func from_offset(vec: Vector2):
	if vec.x == 0 and vec.y == 1:
		return Keys.South
	if vec.x == 0 and vec.y == -1:
		return Keys.North
	if vec.x == 1 and vec.y == 0:
		return Keys.East
	if vec.x == -1 and vec.y == 0:
		return Keys.West
	if vec.x == 1 and vec.y == 1:
		return Keys.SouthEast
	if vec.x == -1 and vec.y == 1:
		return Keys.SouthWest
	if vec.x == 1 and vec.y == -1:
		return Keys.NorthEast
	if vec.x == -1 and vec.y == -1:
		return Keys.NorthWest
	return Keys.None

static func from_input(vec: Vector2):
	if vec.x == 0 and vec.y == -1:
		return Keys.South
	if vec.x == 0 and vec.y == 1:
		return Keys.North
	if vec.x == 1 and vec.y == 0:
		return Keys.East
	if vec.x == -1 and vec.y == 0:
		return Keys.West
	if vec.x == 1 and vec.y == -1:
		return Keys.SouthEast
	if vec.x == -1 and vec.y == -1:
		return Keys.SouthWest
	if vec.x == 1 and vec.y == 1:
		return Keys.NorthEast
	if vec.x == -1 and vec.y == 1:
		return Keys.NorthWest
	return Keys.None

static func get_direction_to(from: Vector2i, to: Vector2i):
	var dir = to - from
	if dir.x != 0:
		dir.x /= abs(dir.x)
	if dir.y != 0:
		dir.y /= abs(dir.y)
	return from_offset(dir)