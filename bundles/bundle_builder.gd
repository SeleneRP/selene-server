class_name BundleBuilder
extends Node

signal bundle_changes_detected(bundle_id: String)
signal bundle_about_to_be_rebuilt(bundle_id: String)
signal bundle_rebuilt(bundle_id: String)
signal bundle_failed_to_rebuild(bundle_id: String, output: Array[String])

@export var bundles_dir = "run://bundles"
@export var bundle_sources_dir = "run://bundle_sources"
@export var bundle_source_hash_database_path = "run://bundle_source_hashes.db"
@export var ignore_dirs: Array[String] = ['.git', '.godot']

func rebuild_sources():
	var found = false
	var hash_db = FileHashDatabase.new(Selene.path(bundle_source_hash_database_path))
	var dir_access = DirAccess.open(Selene.path(bundle_sources_dir))
	if dir_access:
		dir_access.list_dir_begin()
		var file = dir_access.get_next()
		while file != "":
			if dir_access.current_is_dir():
				var bundle_path = Selene.path(bundle_sources_dir).path_join(file)
				if _rebuild_bundle_if_neccessary(hash_db, bundle_path):
					found = true
			file = dir_access.get_next()
		dir_access.list_dir_end()
	return found

func _rebuild_bundle_if_neccessary(hash_db: FileHashDatabase, bundle_path: StringName):
	var file_hash_generator = FileHashGenerator.new(ignore_dirs)
	var current_hashes = file_hash_generator.hash_file(bundle_path)
	if Selene.debug_hash_dump:
		var file = FileAccess.open(bundle_path.get_base_dir().path_join("%s.hash_dump.json" % bundle_path.get_file()), FileAccess.WRITE)
		file.store_string(JSON.stringify(current_hashes))
	var current_hash = current_hashes["hash"].hex_encode()
	var cached_hash = hash_db.get_hash(bundle_path.get_file())
	if (current_hash != cached_hash):
		bundle_changes_detected.emit(bundle_path.get_file())
		if _rebuild_bundle(bundle_path):
			hash_db.cache_hashes(current_hashes, bundle_path.get_file())
		return true
	return false

func _rebuild_bundle(bundle_path: String):
	DirAccess.make_dir_recursive_absolute(Selene.path(bundles_dir))
	var zip_file = Selene.globalize_path(bundles_dir.path_join(bundle_path.get_file() + ".zip"))
	bundle_about_to_be_rebuilt.emit(bundle_path.get_file())
	var godot_executable = OS.get_executable_path()
	var export_preset = "Selene Bundle"
	var output = []
	var result = OS.execute(godot_executable, ["--path", bundle_path, "--headless", "--export-pack", export_preset, zip_file], output, true, true)
	if result == 0:
		var logs_dir = Selene.path("run://logs")
		DirAccess.make_dir_recursive_absolute(logs_dir)
		var log_file = logs_dir.path_join(bundle_path.get_file() + ".build.log")
		var log_file_access = FileAccess.open(log_file, FileAccess.WRITE)
		if log_file_access:
			for line in output:
				log_file_access.store_string(line + "\n")
			log_file_access.close()
		bundle_rebuilt.emit(bundle_path.get_file())
		return true
	else:
		bundle_failed_to_rebuild.emit(bundle_path.get_file(), output)
	return false