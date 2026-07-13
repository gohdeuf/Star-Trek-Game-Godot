extends Node
# Autoload: PlanetClassDB
# Jede Klasse hat ein "deuterium"-Feld [min, max].
#   Gesteinsplaneten: geringe Mengen (20-300)
#   Gasriesen:        grosse Mengen (2000-12000)

var classes: Dictionary = {
	"D": {"type":"rocky","radius":[4.0, 8.0], "weight":12,"color":Color(0.47,0.43,0.39),"resources":[2000,5000],"deuterium":[20, 80]},
	"H": {"type":"rocky","radius":[5.0,10.0], "weight":12,"color":Color(0.75,0.59,0.35),"resources":[ 500,1500],"deuterium":[30,100]},
	"K": {"type":"rocky","radius":[5.0, 9.0], "weight":12,"color":Color(0.67,0.35,0.24),"resources":[ 800,2000],"deuterium":[40,120]},
	"L": {"type":"rocky","radius":[6.0,10.0], "weight":12,"color":Color(0.47,0.55,0.31),"resources":[ 600,1800],"deuterium":[50,150]},
	"M": {"type":"rocky","radius":[6.0,12.0], "weight":12,"color":Color(0.27,0.51,0.71),"resources":[ 300,1000],"deuterium":[80,200]},
	"N": {"type":"rocky","radius":[6.0,11.0], "weight":10,"color":Color(0.78,0.67,0.35),"resources":[1000,2500],"deuterium":[60,180]},
	"Y": {"type":"rocky","radius":[4.0, 9.0], "weight": 6,"color":Color(0.35,0.24,0.24),"resources":[1500,4000],"deuterium":[100,300]},
	"J": {"type":"gas",  "radius":[15.0,30.0],"weight": 5,"color":Color(0.82,0.71,0.55),"resources":[0,0],"deuterium":[3000, 8000]},
	"T": {"type":"gas",  "radius":[12.0,25.0],"weight": 5,"color":Color(0.71,0.59,0.78),"resources":[0,0],"deuterium":[4000,10000]},
	"6": {"type":"gas",  "radius":[10.0,20.0],"weight": 4,"color":Color(0.59,0.71,0.82),"resources":[0,0],"deuterium":[2000, 6000]},
	"7": {"type":"gas",  "radius":[10.0,22.0],"weight": 4,"color":Color(0.78,0.55,0.55),"resources":[0,0],"deuterium":[2000, 7000]},
	"9": {"type":"gas",  "radius":[14.0,28.0],"weight": 4,"color":Color(0.63,0.63,0.47),"resources":[0,0],"deuterium":[5000,12000]},
}

func weighted_random_class(rng: RandomNumberGenerator) -> String:
	var total_weight := 0
	for key in classes.keys():
		total_weight += int(classes[key]["weight"])
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for key in classes.keys():
		cumulative += int(classes[key]["weight"])
		if roll <= cumulative:
			return key
	return "M"

func random_resources(rng: RandomNumberGenerator, cls: String) -> Dictionary:
	var range_vals: Array = classes[cls]["resources"]
	var max_val: int
	# GDScript-Ternary: wert_wenn_true if bedingung else wert_wenn_false
	if int(range_vals[1]) > int(range_vals[0]):
		max_val = rng.randi_range(int(range_vals[0]), int(range_vals[1]))
	else:
		max_val = int(range_vals[0])
	return {"max": max_val, "current": max_val}

func random_deuterium(rng: RandomNumberGenerator, cls: String) -> Dictionary:
	var range_vals: Array = classes[cls]["deuterium"]
	var max_val: int
	if int(range_vals[1]) > int(range_vals[0]):
		max_val = rng.randi_range(int(range_vals[0]), int(range_vals[1]))
	else:
		max_val = int(range_vals[0])
	return {"max": max_val, "current": max_val}
