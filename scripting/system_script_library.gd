class_name SystemScriptLibrary
extends Node

func _lua_CreateTimeout(pvm: LuauVM):
    var duration = pvm.luaL_checknumber(1)
    if not pvm.lua_isfunction(2):
        pvm.luaL_typerror(2, "function")
    var handler = pvm.lua_tofunction(2)
    await get_tree().create_timer(duration).timeout
    handler.callp()