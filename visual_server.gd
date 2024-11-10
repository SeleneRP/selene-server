class_name VisualServer
extends CanvasLayer

func _ready():
	SeleneInstance.log.connect(_on_log)

	var is_headless = DisplayServer.get_name() == "headless" or "--headless" in OS.get_cmdline_user_args()
	if is_headless:
		queue_free()

func _on_log(message: String, level: LogLevel.Keys, tags: Array[String]):
	%LogOutput.text = %LogOutput.get_text() + message + "\n"