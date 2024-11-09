class_name GameScriptLibrary
extends Node

@onready var _latest = $Latest

func lua_load_library(vm: LuauVM):
    vm.lua_pushobject(self)
    vm.lua_setglobal("game")

func _resolve_version_holder(version: String) -> Node:
    if version == "Latest":
        return _latest
    
    # TODO pick version based on latest date that is before or equals to

    print_rich("[color=yellow]Unknown version %s, falling back to latest[/color]" % version)
    return _latest

func _get_service(p_name: String, version: String) -> Node:
    var version_holder = _resolve_version_holder(version)
    var service = version_holder.get_node_or_null(p_name)
    if service.get_parent() != self:
        return null
    return service

func _lua_GetService(pvm: LuauVM):
    var name = pvm.luaL_checkstring(1)
    var version = pvm.luaL_checkstring(2) if pvm.lua_isstring(2) else "Latest"
    var service = _get_service(name, version)
    if service:
        pvm.lua_pushobject(service)
    else:
        pvm.lua_pushnil()
    return 1