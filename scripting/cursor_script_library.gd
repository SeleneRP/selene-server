class_name CursorScriptLibrary
extends Node

var network_manager: NetworkManager
var networked_cursor: NetworkedCursor

func get_script_bindings():
    return {
        "clear_cursor" = _clear_cursor,
        "add_cursor_visual" = _add_cursor_visual,
        "set_cursor_visual_tint" = _set_cursor_visual_tint,
        "remove_cursor_visual" = _remove_cursor_visual,
    }

func _clear_cursor(peer_id: float):
    networked_cursor.clear_cursor(int(peer_id))

func _add_cursor_visual(peer_id: float, visual_name: String):
    var visual = networked_cursor.add_cursor_visual(int(peer_id), visual_name)
    return visual.id

func _remove_cursor_visual(peer_id: float, visual_id: float):
    networked_cursor.remove_cursor_visual(int(peer_id), int(visual_id))

func _set_cursor_visual_tint(peer_id: float, visual_id: float, r: float, g: float, b: float, a: float):
    networked_cursor.set_cursor_visual_tint(int(peer_id), int(visual_id), Color(r, g, b, a))