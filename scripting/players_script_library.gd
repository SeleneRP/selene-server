class_name PlayersScriptLibrary
extends Node

@onready var PlayerJoined = $PlayerJoined

func _on_networked_handshake_peer_completed_loading(peer_id: int):
    var proxy = %NetworkManager.get_network_state(peer_id, "PlayerScriptProxy")
    PlayerJoined.invoke([proxy])
