class_name BundleManager
extends Node

signal bundle_loaded(bundle)

@export var client_bundle_hash_database_path = "server://client_bundle_hashes.db"
var client_bundle_hash_database: FileHashDatabase
var _loaded_bundles = {}

func _ready():
	client_bundle_hash_database = FileHashDatabase.new(Selene.path(client_bundle_hash_database_path))

func load(bundle):
	if bundle.id in _loaded_bundles:
		return
	_loaded_bundles[bundle.id] = bundle
	bundle_loaded.emit(bundle)

func get_loaded_bundle_ids() -> Array[String]:
	var names: Array[String] = []
	names.assign(_loaded_bundles.keys())
	return names

func get_client_bundle_hash(bundle_id: String) -> String:
	return client_bundle_hash_database.get_hash(bundle_id)