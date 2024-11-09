class_name EntityScriptLibrary
extends Node

var network_manager: NetworkManager
var chunked_map: ChunkedMap

func _lua_Create(pvm: LuauVM):
	var position = pvm.luaL_checkvector(1)
	var entity = %EntityManager.create_entity()
	entity.position = position
	entity.cell = chunked_map.get_chunk_cell(position.x, position.y, position.z)
	pvm.lua_pushobject(entity.proxy)
	return 1