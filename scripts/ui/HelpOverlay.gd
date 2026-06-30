class_name HelpOverlay
extends Control
# Hilfetext-Overlay mit Steuerungsuebersicht (siehe Referenz Abschnitt 12 + 13).
#
# Hinweis fuer die spaeter geplante JSON-Lokalisierung: Der Text ist hier
# bewusst in EINER Funktion (_help_text) zentralisiert, damit er spaeter
# leicht durch einen Lookup wie Locale.get("help.controls") ersetzt werden kann.

func _ready() -> void:
	var label := Label.new()
	label.text = _help_text()
	label.position = Vector2(10, 10)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	add_child(label)

func _help_text() -> String:
	return "STEUERUNG\n" \
		+ "W/A/S/D - Schiff bewegen\n" \
		+ "Pfeiltasten - Pitch/Yaw\n" \
		+ "Q/E - Roll\n" \
		+ "Leertaste/Strg - Hoch/Runter\n" \
		+ "F10 - Freie Kamera umschalten\n" \
		+ "Tab - Galaxiekarte\n" \
		+ "Esc - Spiel beenden (speichert Position)"
