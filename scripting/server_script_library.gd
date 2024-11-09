class_name ServerScriptLibrary
extends Node

@onready var ServerStarted = $ServerStarted

func _on_server_server_started():
	ServerStarted.invoke([])
