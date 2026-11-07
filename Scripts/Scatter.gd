extends Node3D

## Dossier contenant les .glb d'arbres (chargés automatiquement).
@export_dir var trees_folder: String = "res://importsGLB/trees/"
## Terrain cible. Laisse vide : le script cherche un mesh nommé "...andscape...".
@export var terrain_path: NodePath
## Nombre de tentatives de placement (le résultat final est plus faible : pente + densité filtrent).
@export var instance_count: int = 3000
## Pente maximale acceptée, en degrés (0 = seulement le plat).
@export_range(0.0, 89.0) var max_slope_deg: float = 25.0
## Fréquence du bruit de densité (plus petit = grandes plaques).
@export var noise_frequency: float = 0.008
## Seuil de densité (-1 = partout, 1 = nulle part).
@export_range(-1.0, 1.0) var noise_threshold: float = -0.1
@export var scale_min: float = 0.8
@export var scale_max: float = 1.4
@export var random_seed: int = 1234
## Rayon de dispersion AUTOUR de la position de ce nœud (0 = tout le terrain).
@export var zone_radius: float = 0.0
## Rayon à laisser libre autour des objets listés (0 = aucune exclusion). Mets 4 pour 4 m.
@export var exclusion_radius: float = 0.0
## Noms (partiels) des objets à éviter. Les futurs bien nommés seront exclus automatiquement.
@export var exclusion_names: Array[String] = ["stele", "symbole", "socle", "teleport"]

@export_group("Collision des troncs")
## Ajoute un cylindre de collision autour de chaque tronc.
@export var add_collision: bool = true
## Rayon du cylindre de collision (à l'échelle 1).
@export var trunk_radius: float = 0.6
## Hauteur du cylindre de collision (à l'échelle 1).
@export var trunk_height: float = 5.0

func _ready() -> void:
	await get_tree().physics_frame
	_scatter()

func _scatter() -> void:
	var terrain := _get_terrain()
	if terrain == null:
		push_warning("TreeScatter : terrain introuvable (règle terrain_path).")
		return
	var wa := _world_aabb(terrain)
	var cx := wa.position.x + wa.size.x * 0.5
	var cz := wa.position.z + wa.size.z * 0.5
	var hx := wa.size.x * 0.5
	var hz := wa.size.z * 0.5
	if zone_radius > 0.0:
		cx = global_position.x   # dispersion autour de ce nœud
		cz = global_position.z
		hx = zone_radius
		hz = zone_radius
	var ray_top := wa.position.y + wa.size.y + 10.0
	var ray_bot := wa.position.y - 10.0

	var species := _load_trees()
	if species.is_empty():
		push_warning("TreeScatter : aucun arbre chargé depuis " + trees_folder)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var noise := FastNoiseLite.new()
	noise.seed = random_seed
	noise.frequency = noise_frequency
	var space := get_world_3d().direct_space_state
	var min_up := cos(deg_to_rad(max_slope_deg))
	var terrain_body := _find_static_body(terrain)   # pour ne semer QUE sur le sol
	var inv := global_transform.affine_inverse()     # monde -> local (ce nœud peut être déplacé)
	var exclusions := _collect_exclusions()           # points à laisser libres (stèles, téléporteur…)

	var transforms := []
	for sp in species.size():
		var subs := []
		for k in species[sp].size():
			subs.append([])
		transforms.append(subs)

	var col_pos := []
	var col_scale := []

	var placed := 0
	for i in instance_count:
		var x := cx + rng.randf_range(-hx, hx)
		var z := cz + rng.randf_range(-hz, hz)
		if zone_radius > 0.0 and Vector2(x - cx, z - cz).length() > zone_radius:
			continue   # garde un disque autour du point
		if noise.get_noise_2d(x, z) < noise_threshold:
			continue
		if exclusion_radius > 0.0 and _dans_exclusion(x, z, exclusions):
			continue   # trop près d'une stèle / du téléporteur
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, ray_top, z), Vector3(x, ray_bot, z))
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit.normal.y < min_up:
			continue
		if terrain_body != null and hit.collider != terrain_body:
			continue   # rayon tombé sur un bâtiment/meuble, pas sur le sol
		var yaw := rng.randf_range(0.0, TAU)
		var s := rng.randf_range(scale_min, scale_max)
		var base := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), hit.position)
		var sp := rng.randi() % species.size()
		for k in species[sp].size():
			transforms[sp][k].append(base * species[sp][k].xform)
		col_pos.append(hit.position)
		col_scale.append(s)
		placed += 1

	for sp in species.size():
		for k in species[sp].size():
			var xs: Array = transforms[sp][k]
			if xs.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = species[sp][k].mesh
			mm.instance_count = xs.size()
			for j in xs.size():
				mm.set_instance_transform(j, inv * xs[j])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			add_child(mmi)

	if add_collision and not col_pos.is_empty():
		var body := StaticBody3D.new()
		body.name = "TreeColliders"
		add_child(body)
		var cyl := CylinderShape3D.new()
		cyl.radius = trunk_radius
		cyl.height = trunk_height
		for idx in col_pos.size():
			var cs := CollisionShape3D.new()
			cs.shape = cyl
			var sc: float = col_scale[idx]
			var origin: Vector3 = col_pos[idx] + Vector3(0.0, trunk_height * sc * 0.5, 0.0)
			cs.transform = inv * Transform3D(Basis().scaled(Vector3(sc, sc, sc)), origin)
			body.add_child(cs)

	print("TreeScatter : %d arbres semés." % placed)

func _get_terrain() -> VisualInstance3D:
	if not terrain_path.is_empty():
		return get_node_or_null(terrain_path) as VisualInstance3D
	return _find_by_name(get_tree().current_scene, "andscape")

func _find_by_name(node: Node, needle: String) -> VisualInstance3D:
	if node is MeshInstance3D and String(node.name).to_lower().contains(needle):
		return node
	for c in node.get_children():
		var r := _find_by_name(c, needle)
		if r:
			return r
	return null

func _collect_exclusions() -> Array:
	var pts := []
	if exclusion_radius <= 0.0 or exclusion_names.is_empty():
		return pts
	_walk_exclusions(get_tree().current_scene, pts)
	return pts

func _walk_exclusions(node: Node, pts: Array) -> void:
	if node is Node3D:
		var n := String(node.name).to_lower()
		for pat in exclusion_names:
			if not pat.is_empty() and n.contains(pat.to_lower()):
				pts.append((node as Node3D).global_position)
				break
	for c in node.get_children():
		_walk_exclusions(c, pts)

func _dans_exclusion(x: float, z: float, pts: Array) -> bool:
	for p in pts:
		if Vector2(x - p.x, z - p.z).length() < exclusion_radius:
			return true
	return false

func _find_static_body(node: Node) -> Node:
	if node is StaticBody3D:
		return node
	for c in node.get_children():
		var r := _find_static_body(c)
		if r != null:
			return r
	return null

func _world_aabb(vi: VisualInstance3D) -> AABB:
	var a := vi.get_aabb()
	var gt := vi.global_transform
	var mn := Vector3(INF, INF, INF)
	var mx := -mn
	for i in 8:
		var corner := a.position + Vector3(a.size.x * (i & 1), a.size.y * ((i >> 1) & 1), a.size.z * ((i >> 2) & 1))
		var w := gt * corner
		mn = mn.min(w)
		mx = mx.max(w)
	return AABB(mn, mx - mn)

func _load_trees() -> Array:
	var species := []
	var dir := DirAccess.open(trees_folder)
	if dir == null:
		return species
	for f in dir.get_files():
		if f.get_extension().to_lower() != "glb":
			continue
		var ps := load(trees_folder.path_join(f)) as PackedScene
		if ps == null:
			continue
		var inst := ps.instantiate()
		var subs := []
		_collect_meshes(inst, Transform3D.IDENTITY, subs)
		inst.free()
		if not subs.is_empty():
			species.append(subs)
	return species

func _collect_meshes(node: Node, xform: Transform3D, out: Array) -> void:
	var t := xform
	if node is Node3D:
		t = xform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append({"mesh": (node as MeshInstance3D).mesh, "xform": t})
	for c in node.get_children():
		_collect_meshes(c, t, out)
