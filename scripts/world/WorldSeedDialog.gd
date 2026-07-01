class_name WorldSeedDialog
extends Control
# Optionaler World-Seed-Dialog beim allerersten Start (Minecraft-Stil, siehe
# Referenz Abschnitt 3.4). Wird von Main.gd nur angezeigt, wenn noch keine
# gespeicherte Welt existiert (GameDatabase.needs_seed_setup == true). Der
# Spieler kann einen eigenen Seed-Text eingeben oder leer lassen fuer einen
# zufaelligen Seed.

signal seed_confirmed(custom_seed_text: String)

var _line_edit: LineEdit

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -110
	panel.offset_bottom = 110
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Neue Welt erstellen"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var info := Label.new()
	info.text = "Optional: eigenen World-Seed eingeben (Text oder Zahl).\nLeer lassen fuer einen zufaelligen Seed."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(info)

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "z. B. MeinSeed123"
	_line_edit.text_submitted.connect(func(_t: String) -> void: _on_confirm_pressed())
	vbox.add_child(_line_edit)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	vbox.add_child(button_row)

	var random_button := Button.new()
	random_button.text = "Zufaelliger Seed"
	random_button.pressed.connect(_on_random_pressed)
	button_row.add_child(random_button)

	var confirm_button := Button.new()
	confirm_button.text = "Welt erstellen"
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_row.add_child(confirm_button)

	_line_edit.grab_focus()

func _on_random_pressed() -> void:
	seed_confirmed.emit("")

func _on_confirm_pressed() -> void:
	seed_confirmed.emit(_line_edit.text)
