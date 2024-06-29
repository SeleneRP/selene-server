extends Node

var base_dir = "user://"
var debug_hash_dump = true

func path(p_path: String) -> String:
	if p_path.begins_with("server://"):
		return base_dir.path_join(p_path.trim_prefix("server://"))
	return p_path

func resolve_path(p_path: String) -> String:
	var intermediate: String = path(p_path)
	if not OS.has_feature("editor") and intermediate.begins_with("res://"):
		return OS.get_executable_path().get_base_dir().path_join(intermediate.trim_prefix("res://"))
	else:
		return ProjectSettings.globalize_path(intermediate)