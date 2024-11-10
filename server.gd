class_name Server
extends Node

signal server_started

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

	Selene.log("[b]Selene Server v%s[/b]" % ProjectSettings.get_setting("application/config/version"))

	DirAccess.make_dir_recursive_absolute(Selene.path(GlobalPaths.bundles_dir))
	DirAccess.make_dir_recursive_absolute(Selene.path(GlobalPaths.server_scripts_dir))
	Selene.log("Base directory: %s" % Selene.globalize_path("run://"))

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
	Selene.log("Looking for new bundle sources...", ["pending"])
	var bundle_builder = $BundleBuilder
	bundle_builder.bundle_about_to_be_rebuilt.connect(func(bundle_id: String):
		Selene.log("Rebuilding bundle %s..." % bundle_id, ["pending"])
	)
	bundle_builder.bundle_rebuilt.connect(func(bundle_id: String):
		Selene.log("Bundle '%s' rebuilt successfully" % bundle_id, ["success"])
	)
	bundle_builder.bundle_failed_to_rebuild.connect(func(bundle_id: String, output: Array[String]):
		Selene.log_error("Bundle '%s' failed to rebuild" % bundle_id)
		Selene.log_error(str(output))
	)
	var built_any = bundle_builder.rebuild_sources()
	if not built_any:
		Selene.log("No new bundle sources to build.")

func _install_bundles():
	Selene.log("Looking for new bundles...", ["pending"])
	var bundle_installer = $BundleInstaller
	bundle_installer.bundle_about_to_be_installed.connect(func(bundle_id: String):
		Selene.log("Installing bundle %s..." % bundle_id, ["pending"])
	)
	bundle_installer.bundle_installed.connect(func(bundle_id: String):
		Selene.log("Bundle '%s' installed successfully" % bundle_id, ["success"])
	)
	var installed_any = bundle_installer.install_bundles(Selene.path(GlobalPaths.bundles_dir))
	if not installed_any:
		Selene.log("No new bundles to install.")

func _refresh_client_bundle_cache():
	Selene.log("Refreshing client bundle cache...", ["pending"])
	var client_bundle_cache_manager = $ClientBundleCacheManager
	client_bundle_cache_manager.bundle_changes_detected.connect(func(bundle_id: String):
		Selene.log("Detected changes in bundle: '%s', updating cache..." % bundle_id, ["pending"])
	)
	client_bundle_cache_manager.bundle_about_to_be_repacked.connect(func(bundle_id: String):
		Selene.log("Repacking bundle: '%s'..." % bundle_id, ["pending"])
	)
	client_bundle_cache_manager.bundle_repacked.connect(func(bundle_id: String):
		Selene.log("Bundle '%s' repacked successfully" % bundle_id, ["success"])
	)
	var repacked_any = client_bundle_cache_manager.refresh_cache(Selene.path(GlobalPaths.bundles_dir))
	if not repacked_any:
		Selene.log("No changes detected in bundles.")

func _init_map_manager():
	var map_manager = $MapManager
	map_manager.map_about_to_be_loaded.connect(func(bundle_id: String, map_name: String):
		Selene.log("Loading map: %s from %s" % [map_name, bundle_id], ["pending"])
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
		Selene.log("Loading bundle: %s (%s)" % [manifest.name, manifest.id], ["pending"])
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
		Selene.log("Starting local file server on port %d to serve client bundles..." % server_config.client_bundle_port, ["pending"])
		var server = HttpServer.new()
		server.name = "ClientBundleHttpServer"
		server.port = server_config.client_bundle_port
		var router = HttpFileRouter.new(Selene.path(GlobalPaths.client_bundle_cache_dir))
		server.register_router("/", router)
		add_child(server)
		server.start()
		Selene.log("Client bundles will be served from [color=yellow]%s[/color]" % server_config.client_bundle_base_url)
	else:
		Selene.log_warning("No client bundle port set. Client bundles will not be served by this server.")
		Selene.log_warning("Make sure you either set a client_bundle_port in server.lua or serve the client bundles some other way.")

func _start_network_listen():
	var server_config: ServerConfig = $ServerConfig
	var network_listener: NetworkListener = $NetworkListener
	Selene.log("Starting network server at port %d..." % server_config.port, ["success"])
	var network_error = network_listener.start(server_config.port, server_config.max_connections)
	if network_error:
		Selene.log_error("Error starting network server (code GD%03d)" % network_error, ["fatal"])
		return false
	Selene.log("Server started on port %d with max connections %d" % [server_config.port, server_config.max_connections], ["success"])
	return true

func _on_script_manager_script_printed(message: String):
	Selene.log(message)

func _on_server_config_loader_script_printed(message: String):
	Selene.log(message)

func _on_bundle_manifest_loader_script_printed(message: String):
	Selene.log(message)

func _on_bundle_manifest_loader_manifest_error(bundle_id: String, message: String):
	Selene.log_error("Manifest error in %s: %s" % [bundle_id, message])
