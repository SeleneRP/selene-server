class_name FileHashGenerator 

var _ignore_dirs = []

func _init(ignore_dirs: Array):
	_ignore_dirs = ignore_dirs

func hash_file(path: String) -> Dictionary:
	var hashes = {}
	if path.get_file() in _ignore_dirs:
		return hashes
	if DirAccess.dir_exists_absolute(path):
		hashes["children"] = {}
		var dir_access = DirAccess.open(path)
		dir_access.list_dir_begin()
		var file = dir_access.get_next()
		while file != "":
			if not file in _ignore_dirs:
				hashes["children"][file] = hash_file(path.path_join(file))
			file = dir_access.get_next()
		dir_access.list_dir_end()
		var dir_hash = HashingContext.new()
		dir_hash.start(HashingContext.HASH_MD5)
		for child in hashes["children"]:
			var child_hashes = hashes["children"][child]
			if child_hashes.has("hash"):
				dir_hash.update(child_hashes["hash"])
		hashes["hash"] = dir_hash.finish()
	elif FileAccess.file_exists(path):
		hashes["hash"] = FileAccess.get_md5(path).hex_decode()
	return hashes