class_name PlayerScriptProxy
extends Node

var peer_id: int
var manager: NetworkManager

@onready var networked_cursor = manager.get_networked("NetworkedCursor")
@onready var networked_camera = manager.get_networked("NetworkedCamera")
@onready var networked_controller = manager.get_networked("NetworkedController")

func _lua_ClearCursor(_pvm: LuauVM):
    networked_cursor.clear_cursor(peer_id)
    return 0

func _lua_AddCursorVisual(pvm: LuauVM):
    var visual_name = pvm.luaL_checkstring(2)
    var visual = networked_cursor.add_cursor_visual(peer_id, visual_name)
    pvm.lua_pushobject(visual)
    return 1

func _lua_SetControlledEntity(pvm: LuauVM):
    var entity = pvm.lua_toobject(2)
    if entity is not Entity:
        pvm.luaL_typerror(2, "entity")
        return 0
    networked_controller.set_controlled_entity(peer_id, entity.id)
    return 0

func _lua_SetCameraMode(pvm: LuauVM):
    var mode = pvm.luaL_checkint(2) as CameraMode.Keys
    networked_camera.set_camera_mode(peer_id, mode)
    return 0

func _lua_SetCameraPosition(pvm: LuauVM):
    var position = pvm.luaL_checkvector(2)
    networked_camera.set_camera_position(peer_id, Vector2(position.x, position.y), position.z)
    return 0

func _lua_SetCameraTarget(pvm: LuauVM):
    var entity = pvm.lua_toobject(2)
    if entity is not Entity:
        pvm.luaL_typerror(2, "entity")
        return 0
    networked_camera.set_camera_target(peer_id, entity.id)
    return 0