class_name ServerConfig
extends Node

@export var port = 8147
@export var max_connections = 32
@export var client_bundle_port = 8090
@export var client_bundle_base_url = "http://localhost:%d/" % client_bundle_port

func load_from_script_globals(script_manager: ScriptManager):
    var errors = []
    var fatal = false
    port = int(script_manager.get_global_or_default("port", port))
    if port == 0:
        errors.append("Invalid port, check server.lua")
        fatal = true
    max_connections = int(script_manager.get_global_or_default("max_connections", max_connections))
    if max_connections == 0:
        errors.append("Invalid max_connections, check server.lua")
        max_connections = 32
    client_bundle_port = int(script_manager.get_global_or_default("client_bundle_port", client_bundle_port))
    client_bundle_base_url = script_manager.get_global_or_default("client_bundle_base_url", client_bundle_base_url)
    return {
        "errors": errors,
        "fatal": fatal
    }