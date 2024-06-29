class_name IdMappingsDatabase
extends Node

signal id_generated(scope: String, name: String, id: int)

@export var path: String = "server://id_mappings.db"

var db: SQLite = null

func _ready():
	db = SQLite.new()
	db.path = Selene.path(path)
	db.verbosity_level = SQLite.QUIET
	db.open_db()
	db.query("CREATE TABLE IF NOT EXISTS mappings (id INTEGER PRIMARY KEY, name TEXT, scope TEXT, UNIQUE(name, scope))")

func get_id(scope: String, p_name: String) -> int:
	if db.query_with_bindings("SELECT id FROM mappings WHERE name = ? AND scope = ?", [p_name, scope]) and db.query_result.size() > 0:
		return db.query_result[0]["id"]
	else:
		return -1

func get_key(scope: String, id: int) -> String:
	if db.query_with_bindings("SELECT name FROM mappings WHERE id = ? AND scope = ?", [id, scope]) and db.query_result.size() > 0:
		return db.query_result[0]["name"]
	else:
		return ""

func set_id(scope: String, p_name: String, id: int) -> void:
	db.query_with_bindings("INSERT OR REPLACE INTO mappings (name, scope, id) VALUES (?, ?, ?)", [p_name, scope, id])

func generate_id(scope: String, p_name: String) -> int:
	var id = get_id(scope, p_name)
	if id == -1:
		db.query_with_bindings("INSERT INTO mappings (name, scope) VALUES (?, ?)", [p_name, scope])
		id = db.get_last_insert_rowid()
		id_generated.emit(scope, p_name, id)
	return id

func get_scopes() -> Array:
	var result = []
	if db.query("SELECT DISTINCT scope FROM mappings"):
		for row in db.query_result:
			result.append(row["scope"])
	return result

func get_all(scope: String) -> Dictionary:
	var result = {}
	if db.query_with_bindings("SELECT id, name FROM mappings WHERE scope = ?", [scope]):
		for row in db.query_result:
			result[row["name"]] = row["id"]
	return result

func refresh_all_in_cache(id_mappings_cache: IdMappingsCache):
	var scopes = get_scopes()
	for scope in scopes:
		refresh_in_cache(id_mappings_cache, scope)

func refresh_in_cache(id_mappings_cache: IdMappingsCache, scope: String):
	var mappings = get_all(scope)
	id_mappings_cache.set_mappings(scope, mappings)