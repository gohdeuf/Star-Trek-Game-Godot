extends Node
# Autoload: StarNames

const PREFIXES := [
	"Vulcan", "Andor", "Risa", "Bajor", "Cardassia", "Romulus",
	"Tellar", "Trill", "Betazed", "Deneva", "Rigel", "Talos",
	"Ceti", "Ferenginar", "Cait", "Benzar", "Denobula", "Ardana",
]

const SUFFIXES := [
	"Prime", "Major", "Minor", "Alpha", "Beta", "Gamma",
	"I", "II", "III", "IV", "V",
]

func random_name(rng: RandomNumberGenerator) -> String:
	var prefix: String = PREFIXES[rng.randi_range(0, PREFIXES.size() - 1)]
	var suffix: String = SUFFIXES[rng.randi_range(0, SUFFIXES.size() - 1)]
	return "%s %s" % [prefix, suffix]
