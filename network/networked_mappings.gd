class_name NetworkedMappings
extends Node

var id_mappings_cache: IdMappingsCache

func bind():
	id_mappings_cache.mappings_changed.connect(_on_mappings_changed)

@rpc("authority", "call_remote", "reliable")
func c_set_mappings(_scope: String, _new_mappings: Dictionary):
	pass

func _on_mappings_changed(scope: String, mappings: Dictionary):
	for peer_id in multiplayer.get_peers():
		c_set_mappings.rpc_id(peer_id, scope, mappings)

func _on_networked_handshake_peer_bundles_verified(peer_id: int):
	for scope in id_mappings_cache.get_scopes():
		c_set_mappings.rpc_id(peer_id, scope, id_mappings_cache.get_id_mappings(scope))