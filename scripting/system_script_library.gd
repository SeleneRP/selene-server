class_name SystemScriptLibrary
extends Node

func get_script_bindings():
    return {
        "create_timeout" = _create_timeout
    }

func _create_timeout(duration: float, handler: Callable):
    await get_tree().create_timer(duration).timeout
    handler.call()