class_name BundleInstaller
extends Node

signal bundle_about_to_be_installed(bundle_id: String)
signal bundle_installed(bundle_id: String)

func install_bundles(bundle_dir: String):
	# TODO We should store the last installed hash and compare it to the current hash to avoid accidentally deleting post-install changes. If the hash does not match previous install, we should fatal.
	var found = false
	DirAccess.make_dir_recursive_absolute(bundle_dir)
	var dir_access = DirAccess.open(bundle_dir)
	if dir_access:
		dir_access.list_dir_begin()
		var file = dir_access.get_next()
		while file != "":
			if file.ends_with(".zip"):
				found = true
				bundle_about_to_be_installed.emit(file.get_basename())
				var zip_file = bundle_dir.path_join(file)
				var extract_folder = zip_file.get_base_dir().path_join(file.get_file().get_basename())
				FileUtils.delete_dir_recursively(extract_folder)
				FileUtils.unzip(zip_file, extract_folder)
				bundle_installed.emit(file.get_basename())
				DirAccess.remove_absolute(zip_file)
			file = dir_access.get_next()
		dir_access.list_dir_end()
	return found