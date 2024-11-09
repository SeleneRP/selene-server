class_name EntityVisual
extends Node

signal tint_changed()
signal removed_by_script()

@export var id: int
@export var visual_name: String
@export var tint: Color = Color.WHITE

func _lua_Remove():
    removed_by_script.emit()

func __lua_set_tint(pvm: LuauVM):
    var vec = pvm.luaL_checkvector(3)
    tint = Color(vec.x, vec.y, vec.z, vec.w)
    tint_changed.emit(tint)