extends Control
# Dialog zum Erstellen einer neuen Welt beim allerersten Start.
# Wenn GameDatabase.needs_seed_setup == true, wird dieser Dialog angezeigt
# und der Spieler kann optional einen eigenen Seed eingeben oder den Standard
# verwenden (siehe Referenz Abschnitt 3, Punkt 1+4).

var seed_input: LineEdit

func _ready() -> void:
	# Nur zeigen, wenn neue Welt nötig ist
	if not GameDatabase.needs_seed_setup:
		queue_free()
		return

	# UI-Baum aufbauen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Halb-transparentes Overlay
	var overlay := ColorRect.new()
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.5)
	add_child(overlay)

	# Zentrale Dialog-Box
	var dialog_bg := PanelContainer.new()
	dialog_bg.anchor_left = 0.5
	dialog_bg.anchor_top = 0.5
	dialog_bg.anchor_right = 0.5
	dialog_bg.anchor_bottom = 0.5
	dialog_bg.offset_left = -150
	dialog_bg.offset_top = -100
	dialog_bg.offset_right = 150
	dialog_bg.offset_bottom = 100
	add_child(dialog_bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_bg.add_child(vbox)

	var title := Label.new()
	title.text = "Neue Welt erstellen"
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Optional: Gib einen Seed ein (Zahl oder Text).\nFür zufälligen Seed: leeres Feld lassen."
	desc.custom_minimum_size.y = 50
	vbox.add_child(desc)

	seed_input = LineEdit.new()
	seed_input.placeholder_text = "Seed (optional)"
	seed_input.custom_minimum_size.y = 30
	vbox.add_child(seed_input)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var ok_btn := Button.new()
	ok_btn.text = "OK"
	hbox.add_child(ok_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size.x = 20
	hbox.add_child(spacer)

	var random_btn := Button.new()
	random_btn.text = "Zufall"
	hbox.add_child(random_btn)

	ok_btn.pressed.connect(_on_ok_pressed)
	random_btn.pressed.connect(_on_random_pressed)
	seed_input.text_submitted.connect(_on_ok_pressed)

func _on_ok_pressed() -> void:
	var custom_seed := seed_input.text.strip_edges()
	GameDatabase.finish_new_world_setup(custom_seed)
	queue_free()

func _on_random_pressed() -> void:
	GameDatabase.finish_new_world_setup("")
	queue_free()
