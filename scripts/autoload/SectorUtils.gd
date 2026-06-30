extends Node
# Autoload: SectorUtils
#
# Reine Sektor-Koordinaten-Mathematik (siehe Referenz Abschnitt 2 + 3).
# Bewusst zustandslos / statisch nutzbar.

const SECTOR_SIZE := 2000

static func world_to_sector_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(pos.x / SECTOR_SIZE)),
		int(floor(pos.y / SECTOR_SIZE)),
		int(floor(pos.z / SECTOR_SIZE))
	)

static func sector_coords_to_id(sx: int, sy: int, sz: int) -> String:
	return "Sector_Alpha_%d_%d_%d" % [sx, sy, sz]

static func sector_id_to_coords(sector_id: String) -> Vector3i:
	# Format: Sector_Alpha_<sx>_<sy>_<sz>
	var parts := sector_id.split("_")
	var sx := int(parts[2])
	var sy := int(parts[3])
	var sz := int(parts[4])
	return Vector3i(sx, sy, sz)

## Liefert den Sektor selbst plus alle 26 Nachbarn (3x3x3-Block).
static func neighbor_sector_ids(sector_id: String) -> Array:
	var coords := sector_id_to_coords(sector_id)
	var result: Array = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				result.append(sector_coords_to_id(coords.x + dx, coords.y + dy, coords.z + dz))
	return result

static func distance_3d(a: Vector3, b: Vector3) -> float:
	return a.distance_to(b)

## Kombiniert World-Seed + Sektor-ID zu einem stabilen, deterministischen
## Sektor-Seed (siehe Referenz Abschnitt 3, Punkt 3). Nutzt SHA256 wie im
## Original, damit das Ergebnis plattform- und sitzungsunabhaengig identisch bleibt.
static func seed_for_sector(world_seed: int, sector_id: String) -> int:
	var combined := str(world_seed) + sector_id
	var sha := combined.sha256_buffer()
	var seed_int: int = 0
	for i in range(8):
		seed_int = (seed_int << 8) | sha[i]
	return seed_int
