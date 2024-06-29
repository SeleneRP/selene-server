class_name BundleScriptLibrary
extends Node

@export var bundles_dir = "server://bundles"

var script_manager: ScriptManager
var bundle_manager: BundleManager

func get_script_bindings():
	return {
		"load_all_bundles" = _load_all_bundles,
		"load_bundle" = _load_bundle
	}

func _load_bundle(bundle_id: String) -> LuaError:
	var bundle_script_path = Selene.path(bundles_dir).path_join(bundle_id).path_join("bundle.lua")
	if not FileAccess.file_exists(bundle_script_path):
		# Load it as a content-only bundle
		bundle_manager.load({
			"id": bundle_id,
			"name": bundle_id,
			"entrypoints": [],
			"server_entrypoints": []
		})
		return null
	var script_error = script_manager.evaluate_file(bundle_script_path)
	if script_error is LuaError:
		return script_error
	var expected_bundle_id = script_manager.get_global_or_default("id", bundle_id)
	if expected_bundle_id != bundle_id:
		return script_manager.create_error("Bundle is defined as '%s', but located within a folder called '%s'. Please rename the folder to match the bundle id." % [expected_bundle_id, bundle_id])
	var bundle_name = script_manager.get_global_or_default("name", bundle_id)
	var entrypoints = script_manager.get_global_or_default("entrypoints", [])
	var server_entrypoints = script_manager.get_global_or_default("server_entrypoints", [])
	# TODO validate that entrypoints and server_entrypoints are arrays of strings
	bundle_manager.load({
		"id": bundle_id,
		"name": bundle_name,
		"entrypoints": entrypoints,
		"server_entrypoints": server_entrypoints
	})
	return null

func _load_all_bundles():
	var bundle_dirs = DirAccess.get_directories_at(Selene.path(bundles_dir))
	for dir in bundle_dirs:
		if dir.begins_with(".") or dir.ends_with(".disabled"):
			continue

		var error = _load_bundle(dir)
		if error is LuaError:
			print_rich("[color=red]Error loading bundle %s (code LUA%03d) %s[/color]" % [dir, error.type, error.message])