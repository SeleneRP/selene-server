class_name FileUtils

static func unzip(zip_file: String, extract_folder: String):
	var reader := ZIPReader.new()
	var err := reader.open(zip_file)
	if err != OK:
		return
	var files = reader.get_files()
	for file in files:
		var path = extract_folder.path_join(file)
		var absolute_path = ProjectSettings.globalize_path(path)
		if !absolute_path.begins_with(extract_folder):
			push_error("Invalid path in zipped bundle: %s" % path)
			continue
		var dir = path.get_base_dir()
		DirAccess.make_dir_recursive_absolute(dir)
		var file_access = FileAccess.open(path, FileAccess.WRITE)
		if file_access:
			file_access.store_buffer(reader.read_file(file))
			file_access.close()

static func delete_dir_recursively(path: String):
	var dir_access = DirAccess.open(path)
	if dir_access:
		dir_access.list_dir_begin()
		var file = dir_access.get_next()
		while file != "":
			if dir_access.current_is_dir():
				delete_dir_recursively(path.path_join(file))
			else:
				dir_access.remove(file)
			file = dir_access.get_next()
		dir_access.list_dir_end()
	DirAccess.remove_absolute(path)

static func zip(zip_file: String, folder_path: String, ignore_dirs: Array[String] = []):
	var writer = ZIPPacker.new()
	var err = writer.open(zip_file)
	if err != OK:
		return
	_zip_directory(writer, folder_path, folder_path, ignore_dirs)
	writer.close()
	
static func _zip_directory(writer: ZIPPacker, root_path: String, current_path: String, ignore_dirs: Array[String] = []):
	const CHUNK_SIZE = 1024
	var dir = DirAccess.open(current_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var file_path = current_path.path_join(file_name)
				if dir.current_is_dir() and not file_name in ignore_dirs:
					_zip_directory(writer, root_path, file_path, ignore_dirs)
				else:
					var file = FileAccess.open(file_path, FileAccess.READ)
					if file:
						writer.start_file(file_path.replace(root_path + "/", ""))
						while not file.eof_reached():
							var buffer = file.get_buffer(CHUNK_SIZE)
							# minizip bug causes wrong CRC if we pass an empty buffer (which can happen if file size is a multiple of chunk size), so we check
							if not buffer.is_empty():
								writer.write_file(buffer)
						writer.close_file()
						file.close()
			file_name = dir.get_next()
		dir.list_dir_end()