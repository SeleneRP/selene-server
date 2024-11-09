class_name GameScriptLibrary
extends Node

@onready var _latest = $Latest

func __lua_load_library(vm: LuauVM):
    print("loaded game lib")
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
    if service and service.get_parent() != version_holder:
        return null
    return service

func _lua_GetService(pvm: LuauVM):
    var service_name = pvm.luaL_checkstring(2)
    var version = pvm.luaL_checkstring(3) if pvm.lua_isstring(3) else "Latest"
    var service = _get_service(service_name, version)
    if service:
        pvm.lua_pushobject(service)
        return 1
    else:
        pvm.luaL_error("Unknown service '%s'" % service_name)
        return 0