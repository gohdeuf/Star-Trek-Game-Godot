extends Node
const SECTOR_SIZE := 2000
static func world_to_sector_coords(pos: Vector3) -> Vector3i:
	return Vector3i(int(floor(pos.x/SECTOR_SIZE)),int(floor(pos.y/SECTOR_SIZE)),int(floor(pos.z/SECTOR_SIZE)))
static func sector_coords_to_id(sx:int,sy:int,sz:int)->String:
	return "Sector_Alpha_%d_%d_%d"%[sx,sy,sz]
static func sector_id_to_coords(sector_id:String)->Vector3i:
	var p:=sector_id.split("_"); return Vector3i(int(p[2]),int(p[3]),int(p[4]))
static func neighbor_sector_ids(sector_id:String)->Array:
	var c:=sector_id_to_coords(sector_id); var r:Array=[]
	for dx in range(-1,2):
		for dy in range(-1,2):
			for dz in range(-1,2):
				r.append(sector_coords_to_id(c.x+dx,c.y+dy,c.z+dz))
	return r
static func distance_3d(a:Vector3,b:Vector3)->float: return a.distance_to(b)
static func seed_for_sector(world_seed:int,sector_id:String)->int:
	var sha:=( str(world_seed)+sector_id ).sha256_buffer()
	var s:int=0
	for i in range(8): s=(s<<8)|sha[i]
	return s
