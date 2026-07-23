extends Node
const PREFIXES:=["Vulcan","Andor","Risa","Bajor","Cardassia","Romulus","Tellar","Trill","Betazed","Deneva","Rigel","Talos","Ceti","Ferenginar","Cait","Benzar","Denobula","Ardana"]
const SUFFIXES:=["Prime","Major","Minor","Alpha","Beta","Gamma","I","II","III","IV","V"]
func random_name(rng:RandomNumberGenerator)->String:
	return "%s %s"%[PREFIXES[rng.randi_range(0,PREFIXES.size()-1)],SUFFIXES[rng.randi_range(0,SUFFIXES.size()-1)]]
