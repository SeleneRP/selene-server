class_name PlayersScriptLibrary
extends Node

@onready var PlayerConnected = $PlayerConnected
@onready var PlayerAuthenticated = $PlayerAuthenticated
@onready var PlayerAuthenticationFailed = $PlayerAuthenticationFailed
@onready var PlayerReadyToJoin = $PlayerReadyToJoin
@onready var PlayerJoined = $PlayerJoined
@onready var PlayerDisconnected = $PlayerDisconnected

func __lua_load_library(pvm: LuauVM):
	pvm.lua_newtable()
	pvm.lua_pushinteger(CameraMode.Keys.Static)
	pvm.lua_setfield(-2, "Static")
	pvm.lua_pushinteger(CameraMode.Keys.Following)
	pvm.lua_setfield(-2, "Following")
	pvm.lua_pushinteger(CameraMode.Keys.FreeFlight)
	pvm.lua_setfield(-2, "FreeFlight")
	pvm.lua_setglobal("CameraMode")

func _get_proxy(peer_id: int):
	return %NetworkManager.get_network_state(peer_id, "PlayerScriptProxy")

func _on_networked_handshake_peer_completed_loading(peer_id: int):
	PlayerJoined.invoke([_get_proxy(peer_id)])

func _on_networked_handshake_peer_bundles_verified(peer_id: int):
	PlayerReadyToJoin.invoke([_get_proxy(peer_id)])

func _on_networked_handshake_peer_authentication_failed(peer_id: int):
	PlayerAuthenticationFailed.invoke([_get_proxy(peer_id)])

func _on_networked_handshake_peer_authenticated(peer_id: int):
	PlayerAuthenticated.invoke([_get_proxy(peer_id)])

func _on_networked_handshake_peer_joined_queue(peer_id: int, set_status: Callable, proceed: Callable, cancel: Callable):
	#var proceeded = {}
	#for i in range(_client_joined_queue_listeners.size()):
	#	var handler = _client_joined_queue_listeners[i]
	#	var new_proceed = func(url: String):
	#		proceeded[i] = url
	#	handle_lua_errors(handler.call(peer_id, set_status, new_proceed, cancel))
	#	while not proceeded.has(i):
	#		await get_tree().process_frame
	#proceed.call(proceeded[_client_joined_queue_listeners.size() - 1] if _client_joined_queue_listeners.size() > 0 else "")
	proceed.call("")

func _on_network_listener_peer_disconnected(peer_id: int):
	PlayerDisconnected.invoke([_get_proxy(peer_id)])

func _on_network_listener_peer_connected(peer_id: int):
	PlayerConnected.invoke([_get_proxy(peer_id)])
