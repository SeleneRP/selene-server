class_name ServerConfig
extends Node

@export var port = 8147
@export var max_connections = 32
@export var client_bundle_port = 8090
@export var client_bundle_base_url = "http://localhost:%d/" % client_bundle_port
