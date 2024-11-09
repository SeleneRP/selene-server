class_name BundleManager
extends Node

signal bundle_loaded(bundle)

var client_bundle_hash_database: FileHashDatabase
var _loaded_bundles = {}

func _ready():
	client_bundle_hash_database = FileHashDatabase.new(Selene.path(GlobalPaths.client_bundle_hash_database_path))

func load_bundle(manifest: BundleManifest):
	_loaded_bundles[manifest.id] = manifest
	bundle_loaded.emit(manifest)

func get_loaded_bundle_ids() -> Array[String]:
	var names: Array[String] = []
	names.assign(_loaded_bundles.keys())
	return names

func get_client_bundle_hash(bundle_id: String) -> String:
	return client_bundle_hash_database.get_hash(bundle_id)