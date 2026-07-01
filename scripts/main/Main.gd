class_name Main
extends Node3D
# Hauptszene: setzt Umgebung, Schiff, Kamera, WorldManager, SOITracker,
# Galaxiekarte und Hilfe-Overlay zusammen (siehe Referenz Abschnitte 5, 9-13).

const SAVE_INTERVAL := 2.0

var ship: Node3D
var camera_rig: CameraRig
var world_manager: WorldManager
var soi_tracker: SOITracker
var _save_timer: float = 0.0
var _world_ready: bool = false

func _ready() -> void:
	_setup_environment()

	var ship_scene: PackedScene = preload("res://scenes/Ship.tscn")
	ship = ship_scene.instantiate()
	add_child(ship)

	var camera_scene: PackedScene = preload("res://scenes/CameraRig.tscn")
	camera_rig = camera_scene.instantiate()
	add_child(camera_rig)
	camera_rig.set_target(ship)

	world_manager = WorldManager.new()
	add_child(world_manager)
	world_manager.set_player(ship)

	soi_tracker = SOITracker.new()
	add_child(soi_tracker)
	soi_tracker.set_player(ship)

	var map_scene: PackedScene = preload("res://scenes/UI/GalaxyMap.tscn")
	var map: GalaxyMap = map_scene.instantiate()
	add_child(map)
	map.set_player(ship)

	var help_scene: PackedScene = preload("res://scenes/UI/HelpOverlay.tscn")
	add_child(help_scene.instantiate())

	# Wenn neue Welt: zeige Dialog vor World-Aktivierung
	if GameDatabase.needs_seed_setup:
		world_manager.set_process(false)
		var dialog_scene: PackedScene = preload("res://scenes/UI/WorldSeedDialog.tscn")
		add_child(dialog_scene.instantiate())
		# Warte, bis Seed gesetzt ist (Dialog wird `finish_new_world_setup` aufrufen)
		while GameDatabase.needs_seed_setup:
			await get_tree().process_frame
		world_manager.set_process(true)
	else:
		_world_ready = true

func _setup_environment() -> void:
	# Platzhalter-Weltraum-Sky (ProceduralSkyMaterial), kein externes Asset
	# noetig. Spaeter gegen PanoramaSkyMaterial + Sternenfeld-HDRI tauschbar
	# (siehe Referenz Abschnitt 9).
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.02, 0.02, 0.05)
	sky_material.sky_horizon_color = Color(0.05, 0.05, 0.1)
	sky_material.ground_bottom_color = Color(0.01, 0.01, 0.02)
	sky_material.ground_horizon_color = Color(0.03, 0.03, 0.06)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment = environment
	add_child(env)

func _process(delta: float) -> void:
	_save_timer += delta
	if _save_timer >= SAVE_INTERVAL and ship != null:
		_save_timer = 0.0
		GameDatabase.save_player_position(ship.global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit_game"):
		if ship != null:
			GameDatabase.save_player_position(ship.global_position)
		get_tree().quit()
