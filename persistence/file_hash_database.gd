class_name FileHashDatabase

var db: SQLite = null

func _init(path: String):
	db = SQLite.new()
	db.path = path
	db.verbosity_level = SQLite.QUIET
	db.open_db()
	db.query("CREATE TABLE IF NOT EXISTS files (file TEXT PRIMARY KEY, hash TEXT)")

func cache_hashes(hashes: Dictionary, base_dir: String):
	if hashes.has("hash"):
		set_hash(base_dir, hashes["hash"].hex_encode())
	if hashes.has("children"):
		for child in hashes["children"].keys():
			cache_hashes(hashes["children"][child], base_dir.path_join(child))

func set_hash(path: String, file_hash: String):
	db.query_with_bindings("INSERT OR REPLACE INTO files (file, hash) VALUES (?, ?)", [path, file_hash])

func get_hash(path: String) -> String:
	db.query_with_bindings("SELECT hash FROM files WHERE file = ?", [path])
	var result = db.query_result
	if result.size() == 0:
		return ""
	return result[0]["hash"]