class_name ServerScriptEvents
extends Node

var _server_started_listeners = []
var _client_connected_listeners = []
var _client_disconnected_listeners = []
var _client_authenticated_listeners = []
var _client_authentication_failed_listeners = []
var _client_joined_queue_listeners = []
var _client_ready_to_join_listeners = []
var _client_joined_listeners = []

func get_script_bindings():
	return {
		on_server_started = _register_server_started,
		on_client_connected = _register_client_connected,
		on_client_disconnected = _register_client_disconnected,
		on_client_authenticated = _register_client_authenticated,
		on_client_authentication_failed = _register_client_authentication_failed,
		on_client_joined_queue = _register_client_joined_queue,
		on_client_ready_to_join = _register_client_ready_to_join,
		on_client_joined = _register_client_join,
	}

func _register_server_started(callback):
	_server_started_listeners.append(callback)

func _register_client_connected(callback):
	_client_connected_listeners.append(callback)

func _register_client_disconnected(callback):
	_client_disconnected_listeners.append(callback)

func _register_client_authenticated(callback):
	_client_authenticated_listeners.append(callback)

func _register_client_authentication_failed(callback):
	_client_authentication_failed_listeners.append(callback)

func _register_client_joined_queue(callback):
	_client_joined_queue_listeners.append(callback)

func _register_client_ready_to_join(callback):
	_client_ready_to_join_listeners.append(callback)

func _register_client_join(callback):
	_client_joined_listeners.append(callback)

func _on_network_listener_peer_connected(peer_id: int):
	for handler in _client_connected_listeners:
		handle_lua_errors(handler.call(peer_id))

func _on_network_listener_peer_disconnected(peer_id: int):
	for handler in _client_disconnected_listeners:
		handle_lua_errors(handler.call(peer_id))

func _on_networked_handshake_peer_joined_queue(peer_id: int, set_status: Callable, proceed: Callable, cancel: Callable):
	var proceeded = {}
	for i in range(_client_joined_queue_listeners.size()):
		var handler = _client_joined_queue_listeners[i]
		var new_proceed = func(url: String):
			proceeded[i] = url
		handle_lua_errors(handler.call(peer_id, set_status, new_proceed, cancel))
		while not proceeded.has(i):
			await get_tree().process_frame
	proceed.call(proceeded[_client_joined_queue_listeners.size() - 1] if _client_joined_queue_listeners.size() > 0 else "")

func _on_networked_handshake_peer_authenticated(peer_id:int):
	for handler in _client_authenticated_listeners:
		handle_lua_errors(handler.call(peer_id))

func _on_networked_handshake_peer_authentication_failed(peer_id:int):
	for handler in _client_authentication_failed_listeners:
		handle_lua_errors(handler.call(peer_id))

func _on_networked_handshake_peer_bundles_verified(peer_id:int):
	for handler in _client_ready_to_join_listeners:
		handle_lua_errors(handler.call(peer_id))

func _on_networked_handshake_peer_completed_loading(peer_id:int):
	for handler in _client_joined_listeners:
		handle_lua_errors(handler.call(peer_id))

func _on_server_server_started():
	for handler in _server_started_listeners:
		handle_lua_errors(handler.call())

func handle_lua_errors(result: Variant):
	pass
	# TODO if result is LuaError:
	# TODO 	print_rich("[color=red]", result.message, "[/color]")