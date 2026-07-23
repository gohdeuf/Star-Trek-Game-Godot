class_name NPCShip
extends Node3D

var max_health: float = 200.0
var health:     float = 200.0

func _ready() -> void:
	add_to_group("npc_ships")
	var mi := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(4, 2, 6); mi.mesh = bx
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.95, 0.55, 0.1)
	mi.material_override = mat; add_child(mi)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		_on_destroyed()

func _on_destroyed() -> void:
	if get_parent() == null: queue_free(); return
	var light := OmniLight3D.new()
	get_parent().add_child(light)
	light.global_position = global_position
	light.light_color = Color(1.0, 0.5, 0.1)
	light.omni_range = 60.0; light.light_energy = 8.0
	var tween := get_tree().create_tween()
	tween.tween_property(light, "light_energy", 0.0, 1.0)
	tween.tween_callback(light.queue_free)
	queue_free()
