class_name NetworkedMap
extends Node

@onready var network_manager: NetworkManager = %NetworkManager
@onready var chunked_map: ChunkedMap = %ChunkedMap
@onready var entity_manager: EntityManager = %EntityManager

func _ready():
	entity_manager.entity_spawned.connect(_on_entity_spawned)
	entity_manager.entity_despawned.connect(_on_entity_despawned)
	entity_manager.entity_visual_added.connect(_on_entity_visual_added)
	entity_manager.entity_visual_changed.connect(_on_entity_visual_changed)
	entity_manager.entity_visual_removed.connect(_on_entity_visual_removed)

func get_network_state(peer_id: int):
	return network_manager.get_network_state(peer_id, "NetworkedMapState")

@rpc("authority", "call_remote", "reliable")
func c_set_tiles(level: int, tiles: Array):
	pass

@rpc("authority", "call_remote", "reliable")
func c_spawn_entity(_entity_id: int, _position: Vector3):
	pass

@rpc("authority", "call_remote", "reliable")
func c_despawn_entity(_entity_id: int):
	pass

@rpc("authority", "call_remote", "reliable")
func c_add_entity_visual(_entity_id: int, _visual_name: String):
	pass

@rpc("authority", "call_remote", "reliable")
func c_set_entity_visual_tint(_entity_id: int, _visual_id: int, _color: Color):
	pass

@rpc("authority", "call_remote", "reliable")
func c_remove_entity_visual(_entity_id: int, _visual_id: int):
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
			var level = cell.z
			print_verbose("[", peer_id, "] set_tiles ", level, " (", tiles.size(), " tiles)")
			c_set_tiles.rpc_id(peer_id, level, tiles)
		var entities = entity_manager.get_entities_in_cell(cell)
		for entity in entities:
			print_verbose("[", peer_id, "] spawn_entity ", entity.id, " ", entity.position)
			c_spawn_entity.rpc_id(peer_id, entity.id, entity.position)
			for visual in entity.get_visuals():
				print_verbose("[", peer_id, "] add_entity_visual ", entity.id, " ", visual.id, " ", visual.visual_name, " ", visual.tint)
				c_add_entity_visual.rpc_id(peer_id, entity.id, visual.id, visual.visual_name, visual.tint)

func _unwatch_chunk(_peer_id: int, state: NetworkedMapState, cell: Vector3i):
	state.watched_chunks.erase(cell)

func _on_entity_spawned(entity: Entity):
	for peer_id in multiplayer.get_peers():
		var state = get_network_state(peer_id)
		var watched_chunks = state.watched_chunks
		if watched_chunks.has(entity.cell):
			print_verbose("[", peer_id, "] spawn_entity ", entity.id, " ", entity.position)
			c_spawn_entity.rpc_id(peer_id, entity.id, entity.position)
			for visual in entity.get_visuals():
				print_verbose("[", peer_id, "] add_entity_visual ", entity.id, " ", visual.id, " ", visual.visual_name, " ", visual.tint)
				c_add_entity_visual.rpc_id(peer_id, entity.id, visual.id, visual.visual_name, visual.tint)

func _on_entity_despawned(entity: Entity):
	for peer_id in multiplayer.get_peers():
		var state = get_network_state(peer_id)
		var watched_chunks = state.watched_chunks
		if watched_chunks.has(entity.cell):
			print_verbose("[", peer_id, "] despawn_entity ", entity.id)
			c_despawn_entity.rpc_id(peer_id, entity.id)

func _on_entity_visual_added(entity: Entity, visual: EntityVisual):
	for peer_id in multiplayer.get_peers():
		var state = get_network_state(peer_id)
		var watched_chunks = state.watched_chunks
		if watched_chunks.has(entity.cell):
			print_verbose("[", peer_id, "] add_entity_visual ", entity.id, " ", visual.id, " ", visual.visual_name, " ", visual.tint)
			c_add_entity_visual.rpc_id(peer_id, entity.id, visual.id, visual.visual_name, visual.tint)

func _on_entity_visual_changed(entity: Entity, visual: EntityVisual):
	for peer_id in multiplayer.get_peers():
		var state = get_network_state(peer_id)
		var watched_chunks = state.watched_chunks
		if watched_chunks.has(entity.cell):
			print_verbose("[", peer_id, "] set_entity_visual_tint ", entity.id, " ", visual.id, " ", visual.tint)
			c_set_entity_visual_tint.rpc_id(peer_id, entity.id, visual.id, visual.tint)

func _on_entity_visual_removed(entity: Entity, visual: EntityVisual):
	for peer_id in multiplayer.get_peers():
		var state = get_network_state(peer_id)
		var watched_chunks = state.watched_chunks
		if watched_chunks.has(entity.cell):
			print_verbose("[", peer_id, "] remove_entity_visual ", entity.id, " ", visual.id)
			c_remove_entity_visual.rpc_id(peer_id, entity.id, visual.id)
