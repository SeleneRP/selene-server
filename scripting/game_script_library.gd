class_name GameScriptLibrary
extends Node

const LATEST_VERSION = "Latest"

@onready var _latest := $Latest

var date_regex = RegEx.create_from_string("^([0-9]+)-([0-9]+)-([0-9]+)$")

func __lua_load_library(vm: LuauVM):
	vm.lua_pushobject(self)
	vm.lua_setglobal("game")

	for child in $Latest.get_children():
		if child.has_method("__lua_load_library"):
			child.__lua_load_library(vm)

func _resolve_version_holder(version: String) -> Node:
	if version.is_empty() or version == LATEST_VERSION:
		return _latest
	
	var best_holder := _latest
	var best_time := 0
	var request_match = date_regex.search(version)
	if request_match:
		var max_supported_unix_time = Time.get_unix_time_from_datetime_string(version)
		for child in get_children():
			var holder_match = date_regex.search(child.name)
			if holder_match:
				var holder_unix_time = Time.get_unix_time_from_datetime_string(child.name)
				if holder_unix_time <= max_supported_unix_time and holder_unix_time > best_time:
					best_holder = child

	if best_holder:
		return best_holder
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