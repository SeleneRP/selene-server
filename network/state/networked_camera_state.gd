class_name NetworkedCameraState
extends Node

var entity_manager: EntityManager
var networked_camera: NetworkedCamera

var peer_id: int
var position: Vector2i
var level: int
var mode: CameraMode.Keys = CameraMode.Keys.Static
var target_entity_id: int
var cached_target_entity: Entity

func _process(delta: float):
	if mode == CameraMode.Keys.Following and target_entity_id > 0:
		var entity = cached_target_entity if cached_target_entity else entity_manager.get_entity(target_entity_id)
		if entity:
			cached_target_entity = entity
			var old_position = position
			position = Vector2i(entity.position.x, entity.position.y)
			if old_position != position:
				networked_camera.camera_moved.emit(peer_id, old_position, position)