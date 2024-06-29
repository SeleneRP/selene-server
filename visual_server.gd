class_name VisualServer
extends CanvasLayer

func _ready():
	var is_headless = DisplayServer.get_name() == "headless" or "--headless" in OS.get_cmdline_user_args()
	if is_headless:
		queue_free()

func bind_server(server: Server):
	server.log.connect(_on_server_log)

func _on_server_log(message: String):
	%LogOutput.text = %LogOutput.get_text() + message + "\n"