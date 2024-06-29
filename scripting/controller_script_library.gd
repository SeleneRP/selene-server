class_name ControllerScriptLibrary
extends Node

var network_manager: NetworkManager
var networked_controller: NetworkedController

func get_script_bindings():
    return {
        "set_controlled_entity" = _set_controlled_entity,
    }

func _set_controlled_entity(id: float, entity_id: float):
    networked_controller.set_controlled_entity(int(id), int(entity_id))