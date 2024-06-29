class_name NetworkedHandshake
extends Node

var server_config: ServerConfig
var bundle_manager: BundleManager

signal peer_authenticated(peer_id: int)
signal peer_authentication_failed(peer_id: int)
signal peer_joined_queue(peer_id: int, set_status: Callable, proceed: Callable, cancel: Callable)
signal peer_bundles_outdated(peer_id: int, outdated_bundles: Dictionary)
signal peer_bundles_verified(peer_id: int)
signal peer_completed_loading(peer_id: int)

@rpc("any_peer", "call_remote", "reliable")
func s_authenticate(_token: String):
	var peer_id = multiplayer.get_remote_sender_id()

	# TODO Verify Token
	peer_authenticated.emit(peer_id)

	var set_status = func(status: String):
		c_set_login_status.rpc_id(peer_id, status)

	var proceed = func(load_screen: String):
		# Notify the client of the server's loaded bundles.
		c_set_load_screen.rpc_id(peer_id, load_screen)
		c_set_loaded_bundles.rpc_id(peer_id, bundle_manager.get_loaded_bundle_ids())

	var cancel = func(reason: String):
		c_set_login_status.rpc_id(peer_id, reason)
		multiplayer.disconnect_peer(peer_id)

	peer_joined_queue.emit(peer_id, set_status, proceed, cancel)

@rpc("authority", "call_remote", "reliable")
func c_set_login_status(_message: String):
	pass

@rpc("authority", "call_remote", "reliable")
func c_set_load_screen(_url: String):
	pass

@rpc("authority", "call_remote", "reliable")
func c_set_loaded_bundles(_bundles: Array): # TODO Array[String] #69215
	pass

@rpc("any_peer", "call_remote", "reliable")
func s_verify_bundle_hashes(received_bundle_hashes: Dictionary):
	var peer_id = multiplayer.get_remote_sender_id()

	# Find any outdated bundles by comparing the received client hashes with our cached hashes.
	var outdated_bundles: Dictionary = {}
	for bundle_id in bundle_manager.get_loaded_bundle_ids():
		var expected_hash = bundle_manager.get_client_bundle_hash(bundle_id)
		if not bundle_id in received_bundle_hashes or expected_hash != received_bundle_hashes[bundle_id]:
			print_rich("[color=gray]Outdated bundle %s - expected %s but got %s[/color]" % [bundle_id, expected_hash, received_bundle_hashes.get(bundle_id, "<missing>")])
			outdated_bundles[bundle_id] = "%s/%s.zip" % [server_config.client_bundle_base_url.trim_suffix("/"), bundle_id]

	# If no bundles are outdated, we can proceed to the next step.
	if outdated_bundles.size() == 0:
		c_bundles_verified.rpc_id(peer_id)
		peer_bundles_verified.emit(peer_id)
		c_load_bundles.rpc_id(peer_id)
		return

	# Notify the client of their outdated bundles. From there on, the client can proceed to download the manifest and with that, any (partial) bundles.
	peer_bundles_outdated.emit(peer_id, outdated_bundles)
	c_set_outdated_bundles.rpc_id(peer_id, outdated_bundles)

@rpc("authority", "call_remote", "reliable")
func c_set_outdated_bundles(_outdated_bundles: Dictionary):
	pass

@rpc("authority", "call_remote", "reliable")
func c_bundles_verified():
	pass

@rpc("authority", "call_remote", "reliable")
func c_load_bundles():
	pass

@rpc("any_peer", "call_remote", "reliable")
func s_bundles_loaded():
	var peer_id = multiplayer.get_remote_sender_id()
	peer_completed_loading.emit(peer_id)
	c_set_load_screen.rpc_id(peer_id, "")
