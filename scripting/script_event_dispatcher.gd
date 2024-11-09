class_name ScriptEventDispatcher
extends Node

var _handlers: Array[LuauFunction] = []

func _lua_Connect(pvm: LuauVM):
    if not pvm.lua_isfunction(-1):
        pvm.luaL_error("expected a function")
        return 0
    var function = pvm.lua_tofunction(-1)
    _handlers.append(function)
    return 0

func invoke(args: Array):
    for handler in _handlers:
        handler.pcallv(args)