class_name NetworkedController
extends Node

var network_manager: NetworkManager

func get_network_state(peer_id: int) -> NetworkedControllerState:
	return network_manager.get_network_state(peer_id, "NetworkedControllerState")

@rpc("authority", "call_remote", "reliable")
func c_set_controlled_entity(_entity_id: int):
	pass

func set_controlled_entity(peer_id: int, entity_id: int):
	var state = get_network_state(peer_id)
	if state.controlled_entity_id != entity_id:
		state.controlled_entity_id = entity_id
		c_set_controlled_entity.rpc_id(peer_id, entity_id)