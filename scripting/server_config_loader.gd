class_name ServerConfigLoader
extends Node

signal log(message: String)
signal script_printed(message: String)

var vm: LuauVM

var _bundles: Array[String] = []
var _scripts: Array[String] = []
var _maps: Array[String] = []

func _ready():
	vm = LuauVM.new()
	vm.stdout.connect(_on_vm_stdout)
	vm.open_all_libraries()
	add_child(vm)

	vm.lua_pushcallable(_load_all_bundles)
	vm.lua_setglobal("load_all_bundles")

	vm.lua_pushcallable(_load_bundle)
	vm.lua_setglobal("load_bundle")

	vm.lua_pushcallable(_load_all_server_scripts)
	vm.lua_setglobal("load_all_server_scripts")

	vm.lua_pushcallable(_load_server_script)
	vm.lua_setglobal("load_server_script")

	vm.lua_pushcallable(_load_map)
	vm.lua_setglobal("load_map")

func load_into(server_config: ServerConfig):
	var server_script_path = Selene.path(GlobalPaths.server_config_path)
	if FileAccess.file_exists(server_script_path):
		log.emit("[color=yellow]Loading server.lua[/color]")
		if not _evaluate_script(server_script_path):
			return false
	else:
		log.emit("[color=yellow]server.lua does not exist - generating...[/color]")
		return _create_default_config(server_script_path)
	var result = _apply_to(server_config)
	if result.fatal:
		log.emit("[color=red]FATAL: Configuration errors are preventing the server from loading.[/color]")
	elif result.errors.size():
		log.emit("[color=red]There are some issues with your configuration. Things may not work as expected.[/color]")
	for error in result.errors:
		log.emit("[color=red]- %s[/color]" % error)
	return not result.fatal

func _evaluate_script(path: String):
	var script = FileAccess.get_file_as_string(path)
	if vm.lua_dostring(script) == vm.LUA_OK:
		return true
	else:
		var error = vm.lua_tostring(-1)
		log.emit("[color=red]FATAL: Error loading %s: %s[/color]" % [path, error])
		vm.lua_pop(1)
		return false

func _apply_to(server_config: ServerConfig):
	var errors = []
	var fatal = false

	vm.lua_getglobal("port")
	if not vm.lua_isnil(-1):
		server_config.port = vm.luaL_checkint(-1)
	if server_config.port == 0:
		errors.append("port must not be 0, check server.lua")
		fatal = true
	vm.lua_pop(1)

	vm.lua_getglobal("max_connections")
	if not vm.lua_isnil(-1):
		server_config.max_connections = vm.luaL_checkint(-1)
	if server_config.max_connections <= 0:
		errors.append("max_connections must be greater than 0, check server.lua")
		server_config.max_connections = 32
	vm.lua_pop(1)

	vm.lua_getglobal("client_bundle_port")
	if not vm.lua_isnil(-1):
		server_config.client_bundle_port = vm.luaL_checkint(-1)
	vm.lua_pop(1)

	vm.lua_getglobal("client_bundle_base_url")
	if not vm.lua_isnil(-1):
		server_config.client_bundle_base_url = vm.luaL_checkstring(-1)
	vm.lua_pop(1)

	return {
		"errors": errors,
		"fatal": fatal
	}

func _create_default_config(path: String):
	var server_script_dir = path.get_base_dir()
	var make_dir_error = DirAccess.make_dir_recursive_absolute(server_script_dir)
	if make_dir_error != OK:
		log.emit("[color=red]FATAL: Error creating server directory at %s (code GD%03d)[/color]" % [server_script_dir, make_dir_error])
		return false
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var server_script_template = FileAccess.get_file_as_string("res://server.default.lua")
		file.store_string(server_script_template)
		file.close()
		log.emit("[color=green]A fresh server.lua file has been generated at %s. Please review it and make changes as neccessary.[/color]" % path)
		return true
	else:
		var file_open_error = FileAccess.get_open_error()
		log.emit("[color=red]FATAL: Error generating server.lua (code GD%03d)[/color]" % file_open_error)
		return false

func _load_all_bundles(_pvm: LuauVM):
	var bundle_dirs = DirAccess.get_directories_at(Selene.path(GlobalPaths.bundles_dir))
	for dir in bundle_dirs:
		if dir.begins_with(".") or dir.ends_with(".disabled"):
			continue
		_bundles.append(dir)
	return 0

func _load_bundle(pvm: LuauVM):
	var bundle_id = pvm.luaL_checkstring(-1)
	_bundles.append(bundle_id)
	return 0

func _load_all_server_scripts(_pvm: LuauVM):
	var bundle_dirs = DirAccess.get_directories_at(Selene.path(GlobalPaths.server_scripts_dir))
	for dir in bundle_dirs:
		if dir.begins_with("."):
			continue
		if dir.ends_with(".lua") or dir.ends_with(".luau"):
			_bundles.append(dir)
	return 0

func _load_server_script(pvm: LuauVM):
	var script_module = pvm.luaL_checkstring(-1)
	_scripts.append(script_module)
	return 0

func _load_map(pvm: LuauVM):
	var bundle_id = pvm.luaL_checkstring(-2)
	var map_id = pvm.luaL_checkstring(-1)
	_maps.append(bundle_id + ":" + map_id)
	return 0

func _on_vm_stdout(message: String):
	script_printed.emit(message)