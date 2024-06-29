class_name CameraMode

enum Keys {
    Static,
    Following,
    FreeFlight
}

static func is_authorative_on_client(mode: CameraMode.Keys) -> bool:
    return mode == CameraMode.Keys.FreeFlight
