extends Node3D

@export var species: Array[ScatterSpecies] = []
@export var area_size: float = 600.0
@export var drop_height: float = 200.0
@export var rng_seed: int = 12345

@export_group("Collision des troncs")
## Ajoute un cylindre de collision autour de chaque tronc posé.
@export var add_collision: bool = true
## Rayon du cylindre de collision (à l'échelle 1).
@export var trunk_radius: float = 0.5
## Hauteur du cylindre de collision (à l'échelle 1).
@export var trunk_height: float = 5.0

func _ready() -> void:
	seed(rng_seed)  # répartition reproductible d'un lancement à l'autre
	var space_state := get_world_3d().direct_space_state

	# Un seul corps statique porte tous les troncs (coordonnées monde comme les MultiMesh).
	var body: StaticBody3D = null
	if add_collision:
		body = StaticBody3D.new()
		body.name = "TreeColliders"
		body.top_level = true
		add_child(body)
	var cyl := CylinderShape3D.new()
	cyl.radius = trunk_radius
	cyl.height = trunk_height

	for sp in species:
		if sp == null or sp.mesh == null:
			push_warning("Espèce ignorée : aucun mesh assigné dans la fiche.")
			continue

		var noise := FastNoiseLite.new()
		noise.seed = rng_seed + sp.mesh.get_instance_id()
		noise.frequency = sp.noise_frequency

		var mmi := MultiMeshInstance3D.new()
		mmi.top_level = true   # ignore la transfo du nœud : instances en coordonnées monde (fin du flottement)
		add_child(mmi)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sp.mesh
		mm.instance_count = sp.count      # on alloue une fois pour toutes
		mmi.multimesh = mm

		var cx := global_position.x   # zone centrée sur le nœud (et non l'origine du monde)
		var cz := global_position.z
		var placed := 0
		for i in sp.count:
			var x := cx + randf_range(-area_size, area_size)
			var z := cz + randf_range(-area_size, area_size)
			var n := (noise.get_noise_2d(x, z) + 1.0) * 0.5
			if n < sp.density_threshold:
				continue

			# rayon long vers le bas : trouve le sol quelle que soit sa hauteur
			var params := PhysicsRayQueryParameters3D.create(
				Vector3(x, global_position.y + drop_height, z), Vector3(x, global_position.y - 1000.0, z))
			var hit := space_state.intersect_ray(params)
			if hit.is_empty():
				continue

			var s := randf_range(sp.scale_min, sp.scale_max)
			var t := Transform3D()
			t = t.rotated(Vector3.UP, randf_range(0, TAU))
			t = t.scaled(Vector3.ONE * s)
			t.origin = hit.position
			mm.set_instance_transform(placed, t)
			placed += 1

			# Collider de tronc, mis à l'échelle de l'arbre, posé sur le sol.
			if body != null:
				var cs := CollisionShape3D.new()
				cs.shape = cyl
				var origin: Vector3 = hit.position + Vector3(0.0, trunk_height * s * 0.5, 0.0)
				cs.transform = Transform3D(Basis().scaled(Vector3(s, s, s)), origin)
				body.add_child(cs)

		mm.visible_instance_count = placed   # <-- la correction : on N'EFFACE PLUS le buffer
		print("Espèce posée : %d instances sur %d tentatives." % [placed, sp.count])
