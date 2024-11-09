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
	var errors = []
	for handler in _handlers:
		var result = handler.pcallv(args)
		var error = result.get_error()
		if error and error is String and error != "<null>":
			errors.append(error)
	for error in errors:
		print_rich("[color=red]Error in %s event handler: %s[/color]" % [name, error])
	return errors