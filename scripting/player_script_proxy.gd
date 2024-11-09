class_name PlayerScriptProxy
extends Node

var peer_id: int

func __lua_load_library(pvm: LuauVM):
    pvm.lua_newtable()
    pvm.lua_pushinteger(CameraMode.Keys.Static)
    pvm.lua_setfield(-1, "Static")
    pvm.lua_pushinteger(CameraMode.Keys.Following)
    pvm.lua_setfield(-1, "Following")
    pvm.lua_pushinteger(CameraMode.Keys.FreeFlight)
    pvm.lua_setfield(-1, "FreeFlight")
    pvm.lua_setglobal("CameraMode")

func _lua_ClearCursor(_pvm: LuauVM):
    %NetworkedCursor.clear_cursor(peer_id)
    return 0

func _lua_AddCursorVisual(pvm: LuauVM):
    var visual_name = pvm.luaL_checkstring(1)
    var visual = %NetworkedCursor.add_cursor_visual(peer_id, visual_name)
    visual.removed_by_script.connect(func():
        %NetworkedCursor.remove_cursor_visual(peer_id, visual.id)
    )
    visual.tint_changed.connect(func(tint):
        %NetworkedCursor.set_cursor_visual_tint(peer_id, visual.id, tint)
    )
    pvm.lua_pushobject(visual)
    return 1

func _lua_SetControlledEntity(pvm: LuauVM):
    var entity = pvm.luaL_checkobject(2, true)
    if entity is not Entity:
        pvm.luaL_typerror(2, "entity")
        return 0
    %NetworkedController.set_controlled_entity(peer_id, entity.id)

func _lua_SetCameraMode(pvm: LuauVM):
    var mode = pvm.luaL_checkint(2) as CameraMode.Keys
    %NetworkedCamera.set_camera_mode(peer_id, mode)

func _lua_SetCameraPosition(pvm: LuauVM):
    var position = pvm.luaL_checkvector(2)
    %NetworkedCamera.set_camera_position(peer_id, Vector2(position.x, position.y), position.z)

func _lua_SetCameraTarget(pvm: LuauVM):
    var entity = pvm.luaL_checkobject(2, true)
    if entity is not Entity:
        pvm.luaL_typerror(2, "entity")
        return 0
    %NetworkedCamera.set_camera_target(peer_id, entity.id)