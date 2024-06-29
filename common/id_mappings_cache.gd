class_name IdMappingsCache
extends Node

signal mappings_changed(scope: String, mappings: Dictionary)

var _mappings_by_scope = {}
var _reverse_mappings_by_scope = {}

func _on_id_mappings_database_id_generated(scope: String, p_name: String, id: int):
	var mappings = _mappings_by_scope.get(scope, {})
	mappings[p_name] = id
	_mappings_by_scope[scope] = mappings
	var reverse_mappings = _reverse_mappings_by_scope.get(scope, {})
	reverse_mappings[id] = p_name
	_reverse_mappings_by_scope[scope] = reverse_mappings

func set_mappings(scope: String, mappings: Dictionary):
	_mappings_by_scope[scope] = mappings
	var reverse_mappings = {}
	for p_name in mappings:
		reverse_mappings[mappings[p_name]] = p_name
	_reverse_mappings_by_scope[scope] = reverse_mappings
	mappings_changed.emit(scope, mappings)

func get_id(scope: String, p_name: String) -> int:
	return _mappings_by_scope[scope][p_name]

func get_name_from_id(scope: String, id: int) -> String:
	return _reverse_mappings_by_scope[scope][id]

func get_id_mappings(scope: String):
	return _mappings_by_scope.get(scope, {})

func get_scopes():
	return _mappings_by_scope.keys()