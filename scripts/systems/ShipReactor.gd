class_name ShipReactor
extends Node
# Schiffsreaktor: Impulsantrieb-Deuteriumverbrauch + Onboard-AM-Produktion.
#
# Impulsantrieb (immer aktiv wenn Schub):
#   0.1 Deuterium/Sek (winziger Verbrauch, Schiff fliegt trotzdem bei Leerstand)
#
# Onboard-AM-Produktion (P zum Ein-/Ausschalten):
#   ~1 AM/Minute aus Deuterium (sehr langsam, Hintergrundproduktion).
#   Braucht >= MIN_DEU_FOR_AM Deuterium. Stoppt automatisch bei Mangel.

const IMPULSE_DEU_RATE := 0.1    # Deuterium/Sek waehrend Schub
const SHIP_AM_RATE     := 0.012  # AM/Sek (≈ 1 AM/Min)
const AM_DEU_COST      := 3.0    # Deuterium pro AM-Einheit
const MIN_DEU_FOR_AM   := 20     # Mindest-Deu fuer AM-Produktion

var ship: Node3D = null
var _hud:  Node  = null
var am_production_enabled: bool = true
var _deu_debt: float = 0.0
var _am_buffer: float = 0.0

func setup(p_ship: Node3D, p_hud: Node = null) -> void:
	ship = p_ship; _hud = p_hud

func _process(delta: float) -> void:
	if ship == null: return
	if Input.is_action_just_pressed("toggle_ship_am"):
		am_production_enabled = not am_production_enabled
		var key: String = "reactor.am_on" if am_production_enabled else "reactor.am_off"
		if _hud: _hud.show_message(Locale.t(key))
	_handle_impulse(delta)
	if am_production_enabled:
		_handle_am_production(delta)

func _handle_impulse(delta: float) -> void:
	var thrusting := (
		Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_back") or
		Input.is_action_pressed("move_left")    or Input.is_action_pressed("move_right") or
		Input.is_action_pressed("move_up")      or Input.is_action_pressed("move_down")
	)
	if not thrusting: return
	_deu_debt += IMPULSE_DEU_RATE * delta
	if _deu_debt >= 1.0:
		var to_spend: int = int(_deu_debt); _deu_debt -= float(to_spend)
		GameDatabase.spend_resource("deuterium", to_spend)  # Schiff fliegt auch ohne Deu

func _handle_am_production(delta: float) -> void:
	if GameDatabase.get_resource("deuterium") < MIN_DEU_FOR_AM: return
	var am_produced: float = SHIP_AM_RATE * delta
	_deu_debt += am_produced * AM_DEU_COST
	_am_buffer += am_produced
	if _am_buffer >= 0.1:
		GameDatabase.add_resource("antimatter", _am_buffer); _am_buffer = 0.0
