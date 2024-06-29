class_name ScriptManager
extends Node

signal script_printed(message: String)

@export var bundles_dir = "server://bundles"

var lua: LuaAPI
var provided = {}

func _ready():
	lua = LuaAPI.new()
	lua.bind_libraries(["base", "package", "coroutine", "math", "string", "table", "utf8"])
	lua.push_variant("create_error", create_error)
	lua.push_variant("print", _print)
	lua.push_variant("extend", _extend)

	lua.do_string('package.path = "%s"' % [Selene.path(bundles_dir).path_join("?.lua")])
	lua.push_variant("package", null)

func load_libraries():
	for child in get_children():
		if "get_script_bindings" in child:
			var bindings = child.get_script_bindings()
			bind_lua(bindings)
		if "script_manager" in child:
			child.script_manager = self
		for key in provided.keys():
			if key in child:
				child[key] = provided[key]

func bind_lua(bindings: Dictionary):
	for key in bindings.keys():
		lua.push_variant(key, bindings[key])

func evaluate_package(path: String) -> LuaError:
	return lua.do_string('require("%s")' % path)

func evaluate_file(path: String) -> LuaError:
	return lua.do_file(path)

func get_global(key: String) -> Variant:
	return lua.pull_variant(key)

func get_global_or_default(key: String, default: Variant) -> Variant:
	var value = lua.pull_variant(key)
	if value == null:
		return default
	return value

func create_error(message: String):
	return LuaError.new_error(message, LuaError.ERR_RUNTIME)

func provide(key: String, value: Variant):
	provided[key] = value

func _print(message: String):
	script_printed.emit(message)

func _extend(path: String, handler: Callable):
	var package = evaluate_package(path)
	if package is LuaError:
		return
	handler.call(package)