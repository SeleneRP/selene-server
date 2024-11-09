class_name EntityScriptLibrary
extends Node

func _lua_Create(pvm: LuauVM):
	var position := pvm.luaL_checkvector3(1)
	var entity = %EntityManager.create_entity()
	entity.position = position
	entity.cell = %ChunkedMap.get_chunk_cell(position.x, position.y, position.z)
	pvm.lua_pushobject(entity)
	return 1