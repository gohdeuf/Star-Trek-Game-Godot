class_name Main
extends Node3D
# Hauptszene: setzt Umgebung, Schiff, Kamera, WorldManager, SOITracker,
# Galaxiekarte, Hilfe-Overlay und PlayerActions zusammen
# (siehe Referenz Abschnitte 5, 9-13).
#
# Bei einer brandneuen Welt (noch kein Save vorhanden) wird zuerst der
# WorldSeedDialog gezeigt, damit der Spieler optional einen eigenen
# World-Seed eingeben kann (siehe Referenz Abschnitt 3.4), bevor irgendeine
# Sektorgenerierung stattfindet.

const SAVE_INTERVAL := 2.0

const SKYBOX_ASSET_PATH := "res://assets/skybox/starfield_panorama.png"

var ship: Node3D
var camera_rig: CameraRig
var world_manager: WorldManager
var soi_tracker: SOITracker
var _save_timer: float = 0.0

func _ready() -> void:
	if GameDatabase.needs_seed_setup:
		var dialog_scene: PackedScene = preload("res://scenes/UI/WorldSeedDialog.tscn")
		var dialog: WorldSeedDialog = dialog_scene.instantiate()
		add_child(dialog)
		dialog.seed_confirmed.connect(_on_world_seed_confirmed.bind(dialog))
	else:
		_start_game()

func _on_world_seed_confirmed(custom_seed_text: String, dialog: WorldSeedDialog) -> void:
	GameDatabase.finish_new_world_setup(custom_seed_text)
	dialog.queue_free()
	_start_game()

func _start_game() -> void:
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

	# SOI-Benachrichtigung (wird auch an PlayerActions weitergereicht)
	var soi_notification := SOINotification.new()
	add_child(soi_notification)
	soi_tracker.enter_system.connect(
		func(sys: Dictionary) -> void:
			soi_notification.show_message(
				Locale.t("soi.entering", {"system": sys.get("name", "?")})
			)
	)
	soi_tracker.exit_system.connect(
		func(sys: Dictionary) -> void:
			soi_notification.show_message(
				Locale.t("soi.leaving", {"system": sys.get("name", "?")})
			)
	)

	# Bau- / Abbau-Gameplay (Taste B = Station bauen, M gehalten = Abbauen)
	var player_actions := PlayerActions.new()
	add_child(player_actions)
	player_actions.setup(ship, world_manager, soi_notification)

	var map_scene: PackedScene = preload("res://scenes/UI/GalaxyMap.tscn")
	var map: GalaxyMap = map_scene.instantiate()
	add_child(map)
	map.set_player(ship)

	var help_scene: PackedScene = preload("res://scenes/UI/HelpOverlay.tscn")
	add_child(help_scene.instantiate())

	if TouchControls.should_show():
		var touch_scene: PackedScene = preload("res://scenes/UI/TouchControls.tscn")
		add_child(touch_scene.instantiate())

func _setup_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var pano_mat := PanoramaSkyMaterial.new()
	if ResourceLoader.exists(SKYBOX_ASSET_PATH):
		pano_mat.panorama = load(SKYBOX_ASSET_PATH)
		print("Main: Skybox-Asset geladen (%s)" % [SKYBOX_ASSET_PATH])
	else:
		pano_mat.panorama = _build_procedural_starfield()
		print("Main: Kein Skybox-Asset -> generiere prozedurales Sternenfeld.")
	sky.sky_material = pano_mat

	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color  = Color(0.15, 0.16, 0.25)
	environment.ambient_light_energy = 0.6

	env.environment = environment
	add_child(env)

func _build_procedural_starfield() -> ImageTexture:
	var width  := 512
	var height := 256
	var img := Image.create(width, height, false, Image.FORMAT_RGB8)

	var noise := FastNoiseLite.new()
	noise.seed = int(GameDatabase.world_seed & 0x7fffffff)
	noise.frequency = 0.015
	noise.fractal_octaves = 3

	for y in range(height):
		for x in range(width):
			var n := noise.get_noise_2d(float(x), float(y))
			var nebula: float = clamp(n * 0.08, 0.0, 0.1)
			img.set_pixel(x, y, Color(0.01 + nebula * 0.5, 0.01 + nebula * 0.35, 0.035 + nebula * 0.7))

	var rng := RandomNumberGenerator.new()
	rng.seed = GameDatabase.world_seed
	var star_count := int(width * height * 0.012)
	for i in range(star_count):
		var x := rng.randi_range(0, width - 1)
		var y := rng.randi_range(0, height - 1)
		var brightness := rng.randf_range(0.35, 1.0)
		var tint := rng.randf_range(0.85, 1.0)
		img.set_pixel(x, y, Color(brightness, brightness * tint, brightness))

	return ImageTexture.create_from_image(img)

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
