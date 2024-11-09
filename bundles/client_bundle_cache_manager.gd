class_name ClientBundleCacheManager
extends Node

signal bundle_changes_detected(bundle_id: String)
signal bundle_about_to_be_repacked(bundle_id: String)
signal bundle_repacked(bundle_id: String)

@export var ignore_dirs: Array[String] = ['server']

func refresh_cache(bundle_dir: String):
	var found = false
	var hash_db = FileHashDatabase.new(Selene.path(GlobalPaths.client_bundle_hash_database_path))
	var dir_access = DirAccess.open(bundle_dir)
	if dir_access:
		dir_access.list_dir_begin()
		var file = dir_access.get_next()
		while file != "":
			if dir_access.current_is_dir():
				var bundle_path = bundle_dir.path_join(file)
				if _cache_bundle(hash_db, bundle_path):
					found = true
			file = dir_access.get_next()
		dir_access.list_dir_end()
	return found

func _cache_bundle(hash_db: FileHashDatabase, bundle_path: StringName):
	var file_hash_generator = FileHashGenerator.new(ignore_dirs)
	var current_hashes = file_hash_generator.hash_file(bundle_path)
	if Selene.debug_hash_dump:
		var file = FileAccess.open(bundle_path.get_base_dir().path_join("%s.hash_dump.json" % bundle_path.get_file()), FileAccess.WRITE)
		file.store_string(JSON.stringify(current_hashes))
	var current_hash = current_hashes["hash"].hex_encode()
	var cached_hash = hash_db.get_hash(bundle_path.get_file())
	if (current_hash != cached_hash):
		bundle_changes_detected.emit(bundle_path.get_file())
		_repack_client_bundle(bundle_path)
		hash_db.cache_hashes(current_hashes, bundle_path.get_file())
		return true
	return false

func _repack_client_bundle(bundle_path):
	DirAccess.make_dir_recursive_absolute(Selene.path(GlobalPaths.client_bundle_cache_dir))
	var zip_file = Selene.path(GlobalPaths.client_bundle_cache_dir).path_join(bundle_path.get_file() + ".zip")
	bundle_about_to_be_repacked.emit(bundle_path.get_file())
	FileUtils.zip(zip_file, bundle_path, ignore_dirs)
	bundle_repacked.emit(bundle_path.get_file())