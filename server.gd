class_name Server
extends Node

signal log(message: String)
signal progress_log(key: String, label: String, progress: float)
signal server_started

func _on_log(message: String):
	print_rich(message)

func _init():
	if OS.has_feature("editor"):
		Selene.base_dir = "run"
		var gd_ignore_file = FileAccess.open(Selene.base_dir.path_join(".gdignore"), FileAccess.WRITE)
		gd_ignore_file.close()
	else:
		Selene.base_dir = ""

func _ready():
	print(" __      _                 ")
	print("/ _\\ ___| | ___ _ __   ___ ")
	print("\\ \\ / _ \\ |/ _ \\ '_ \\ / _ \\")
	print("_\\ \\  __/ |  __/ | | |  __/")
	print("\\__/\\___|_|\\___|_| |_|\\___|")
	print("###########################")
	print()

	log.connect(_on_log)
	$VisualServer.bind_server(self)

	log.emit("[b]Selene Server v%s[/b]" % ProjectSettings.get_setting("application/config/version"))

	DirAccess.make_dir_recursive_absolute(Selene.path(GlobalPaths.bundles_dir))
	DirAccess.make_dir_recursive_absolute(Selene.path(GlobalPaths.server_scripts_dir))
	log.emit("[color=gray]Base directory: %s[/color]" % Selene.globalize_path("run://"))

	#_rebuild_bundles() TODO unfortunately the godot export seems to be failing without error message
	_install_bundles()
	_refresh_client_bundle_cache()
	_init_map_manager()
	_init_bundle_manager($BundleManager)
	if not _load_server_config():
		return
	_load_maps($MapManager, $ServerConfig)
	_load_bundles($BundleManager, $ServerConfig)
	_load_server_scripts($ScriptManager, $ServerConfig)
	_start_client_bundle_server()
	_init_network_manager()
	if not _start_network_listen():
		return

	server_started.emit()

func _rebuild_bundles():
	log.emit("[color=gray]Looking for new bundle sources...[/color]")
	var bundle_builder = $BundleBuilder
	bundle_builder.bundle_about_to_be_rebuilt.connect(func(bundle_id: String):
		log.emit("[color=yellow]Rebuilding bundle %s...[/color]" % bundle_id)
	)
	bundle_builder.bundle_rebuilt.connect(func(bundle_id: String):
		log.emit("[color=green]Bundle '%s' rebuilt successfully[/color]" % bundle_id)
	)
	bundle_builder.bundle_failed_to_rebuild.connect(func(bundle_id: String, output: Array[String]):
		log.emit("[color=error]Bundle '%s' failed to rebuild[/color]" % bundle_id)
		log.emit("[color=error]%s[/color]" % output)
	)
	var built_any = bundle_builder.rebuild_sources()
	if not built_any:
		log.emit("[color=gray]No new bundle sources to build.[/color]")

func _install_bundles():
	log.emit("[color=gray]Looking for new bundles...[/color]")
	var bundle_installer = $BundleInstaller
	bundle_installer.bundle_about_to_be_installed.connect(func(bundle_id: String):
		log.emit("[color=yellow]Installing bundle %s...[/color]" % bundle_id)
	)
	bundle_installer.bundle_installed.connect(func(bundle_id: String):
		log.emit("[color=green]Bundle '%s' installed successfully[/color]" % bundle_id)
	)
	var installed_any = bundle_installer.install_bundles(Selene.path(GlobalPaths.bundles_dir))
	if not installed_any:
		log.emit("[color=gray]No new bundles to install.[/color]")

func _refresh_client_bundle_cache():
	log.emit("[color=gray]Refreshing client bundle cache...[/color]")
	var client_bundle_cache_manager = $ClientBundleCacheManager
	client_bundle_cache_manager.bundle_changes_detected.connect(func(bundle_id: String):
		log.emit("[color=yellow]Detected changes in bundle: '%s', updating cache...[/color]" % bundle_id)
	)
	client_bundle_cache_manager.bundle_about_to_be_repacked.connect(func(bundle_id: String):
		log.emit("[color=yellow]Repacking bundle: '%s'...[/color]" % bundle_id)
	)
	client_bundle_cache_manager.bundle_repacked.connect(func(bundle_id: String):
		log.emit("[color=green]Bundle '%s' repacked successfully[/color]" % bundle_id)
	)
	var repacked_any = client_bundle_cache_manager.refresh_cache(Selene.path(GlobalPaths.bundles_dir))
	if not repacked_any:
		log.emit("[color=gray]No changes detected in bundles.[/color]")

func _init_map_manager():
	var map_manager = $MapManager
	map_manager.map_about_to_be_loaded.connect(func(bundle_id: String, map_name: String):
		log.emit("[color=yellow]Loading map: %s from %s[/color]" % [map_name, bundle_id])
	)
	$IdMappingsCache.set_mappings("tiles", $IdMappingsDatabase.get_all("tiles"))
	$IdMappingsCache.set_mappings("visuals", $IdMappingsDatabase.get_all("visuals"))
	map_manager.map_loaded.connect(func(map: SourceTileMap):
		for internal_id in map.mappings:
			$IdMappingsDatabase.generate_id("tiles", map.mappings[internal_id])
		map.merge_into($ChunkedMap, $IdMappingsCache)
	)

func _init_bundle_manager(bundle_manager: BundleManager):
	bundle_manager.bundle_loaded.connect(func(manifest):
		log.emit("[color=yellow]Loading bundle: %s (%s)[/color]" % [manifest.name, manifest.id])
		for entrypoint in manifest.server_entrypoints:
			%ScriptManager.load_module(entrypoint)
	)

func _load_maps(map_manager: MapManager, config: ServerConfig):
	for map_id in config.maps:
		var parts = map_id.split(":")
		map_manager.load_map(parts[0], parts[1])

func _load_bundles(bundle_manager: BundleManager, config: ServerConfig):
	for bundle_id in config.bundles:
		var manifest = %BundleManifestLoader.load_manifest(bundle_id)
		if manifest:
			bundle_manager.load_bundle(manifest)

func _load_server_scripts(script_manager: ScriptManager, config: ServerConfig):
	for script in config.scripts:
		script_manager.load_module(script)

func _init_network_manager():
	var network_manager: NetworkManager = $NetworkManager
	network_manager.provide("bundle_manager", $BundleManager)
	network_manager.provide("chunked_map", $ChunkedMap)
	network_manager.provide("server_config", $ServerConfig)
	network_manager.provide("id_mappings_cache", $IdMappingsCache)
	network_manager.provide("entity_manager", $EntityManager)
	network_manager.provide("networked_camera", %NetworkHandlers/NetworkedCamera)

func _load_server_config():
	var server_config_loader = $ServerConfigLoader
	var server_config: ServerConfig = $ServerConfig
	return server_config_loader.load_into(server_config)

func _start_client_bundle_server():
	var server_config: ServerConfig = $ServerConfig
	if server_config.client_bundle_port:
		log.emit("[color=gray]Starting local file server on port %d to serve client bundles...[/color]" % server_config.client_bundle_port)
		var server = HttpServer.new()
		server.name = "ClientBundleHttpServer"
		server.port = server_config.client_bundle_port
		var router = HttpFileRouter.new(Selene.path(GlobalPaths.client_bundle_cache_dir))
		server.register_router("/", router)
		add_child(server)
		server.start()
		log.emit("Client bundles will be served from [color=yellow]%s[/color]" % server_config.client_bundle_base_url)
	else:
		log.emit("[color=yellow]No client bundle port set. Client bundles will not be served by this server.[/color]")
		log.emit("[color=yellow]Make sure you either set a client_bundle_port in server.lua or serve the client bundles some other way.[/color]")

func _start_network_listen():
	var server_config: ServerConfig = $ServerConfig
	var network_listener: NetworkListener = $NetworkListener
	log.emit("[color=gray]Starting network server at port %d...[/color]" % server_config.port)
	var network_error = network_listener.start(server_config.port, server_config.max_connections)
	if network_error:
		log.emit("[color=red]FATAL: Error starting network server (code GD%03d)[/color]" % network_error)
		return false
	log.emit("[color=green]Server started on port %d with max connections %d[/color]" % [server_config.port, server_config.max_connections])
	return true

func _on_script_manager_script_printed(message: String):
	log.emit(message)

func _on_server_config_loader_script_printed(message: String):
	log.emit(message)

func _on_server_config_loader_log(message: String):
	log.emit(message)

func _on_bundle_manifest_loader_script_printed(message: String):
	log.emit(message)

func _on_bundle_manifest_loader_log(message: String):
	log.emit(message)

func _on_bundle_manifest_loader_manifest_error(bundle_id: String, message: String):
	log.emit("Manifest error in %s: %s" % [bundle_id, message])
