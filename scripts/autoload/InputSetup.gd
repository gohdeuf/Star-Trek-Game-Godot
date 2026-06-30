extends Node
# Autoload: InputSetup
#
# Registriert alle Eingabe-Aktionen zur Laufzeit (siehe Referenz Abschnitt 12),
# damit die project.godot nicht manuell mit InputEventKey-Resourcen gepflegt
# werden muss. Laeuft vor allen Szenen-Skripten, da Autoloads zuerst initialisiert werden.

func _ready() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("pitch_up", KEY_UP)
	_add_key_action("pitch_down", KEY_DOWN)
	_add_key_action("yaw_left", KEY_LEFT)
	_add_key_action("yaw_right", KEY_RIGHT)
	_add_key_action("roll_left", KEY_Q)
	_add_key_action("roll_right", KEY_E)
	_add_key_action("move_up", KEY_SPACE)
	_add_key_action("move_down", KEY_CTRL)
	_add_key_action("toggle_free_cam", KEY_F10)
	_add_key_action("toggle_map", KEY_TAB)
	_add_key_action("quit_game", KEY_ESCAPE)
	_add_key_action("boost", KEY_SHIFT)

func _add_key_action(action_name: String, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)
