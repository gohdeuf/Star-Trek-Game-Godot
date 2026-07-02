class_name WorldSeedDialog
extends Control
# Optionaler World-Seed-Dialog beim allerersten Start (Minecraft-Stil, siehe
# Referenz Abschnitt 3.4). Wird von Main.gd nur angezeigt, wenn noch keine
# gespeicherte Welt existiert (GameDatabase.needs_seed_setup == true). Der
# Spieler kann einen eigenen Seed-Text eingeben oder leer lassen fuer einen
# zufaelligen Seed.
#
# Texte kommen aus dem Locale-Autoload; F9 schaltet auch hier schon die
# Sprache um, damit man selbst diesen allerersten Bildschirm testen kann.

signal seed_confirmed(custom_seed_text: String)

var _line_edit: LineEdit
var _title_label: Label
var _info_label: Label
var _random_button: Button
var _confirm_button: Button

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

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_title_label)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_info_label)

	_line_edit = LineEdit.new()
	_line_edit.text_submitted.connect(func(_t: String) -> void: _on_confirm_pressed())
	vbox.add_child(_line_edit)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	vbox.add_child(button_row)

	_random_button = Button.new()
	_random_button.pressed.connect(_on_random_pressed)
	button_row.add_child(_random_button)

	_confirm_button = Button.new()
	_confirm_button.pressed.connect(_on_confirm_pressed)
	button_row.add_child(_confirm_button)

	_refresh_text()
	Locale.language_changed.connect(func(_lang: String) -> void: _refresh_text())

	_line_edit.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_language"):
		Locale.cycle_language()

func _refresh_text() -> void:
	_title_label.text = Locale.t("seed_dialog.title")
	_info_label.text = Locale.t("seed_dialog.info")
	_line_edit.placeholder_text = Locale.t("seed_dialog.placeholder")
	_random_button.text = Locale.t("seed_dialog.random_button")
	_confirm_button.text = Locale.t("seed_dialog.confirm_button")

func _on_random_pressed() -> void:
	seed_confirmed.emit("")

func _on_confirm_pressed() -> void:
	seed_confirmed.emit(_line_edit.text)
