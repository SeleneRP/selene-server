class_name CameraScriptLibrary
extends Node

var network_manager: NetworkManager

func get_script_bindings():
    return {
        "CameraMode" = {
            "Static" = CameraMode.Keys.Static,
            "Following" = CameraMode.Keys.Following,
            "FreeFlight" = CameraMode.Keys.FreeFlight
        },
        "set_camera_mode" = _set_camera_mode,
        "set_camera_position" = _set_camera_position,
        "set_camera_target" = _set_camera_target,
    }

func _set_camera_mode(id: float, mode: float):
    var networked_camera = network_manager.get_networked("NetworkedCamera")
    networked_camera.set_camera_mode(int(id), int(mode) as CameraMode.Keys)

func _set_camera_position(id: float, x: float, y: float, z: float):
    var networked_camera = network_manager.get_networked("NetworkedCamera")
    networked_camera.set_camera_position(int(id), Vector2(x, y), z)

func _set_camera_target(id: float, entity_id: float):
    var networked_camera = network_manager.get_networked("NetworkedCamera")
    networked_camera.set_camera_target(int(id), int(entity_id))