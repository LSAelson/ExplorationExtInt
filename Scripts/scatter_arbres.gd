extends Node3D

@export var species: Array[ScatterSpecies] = []
@export var area_size: float = 600.0
@export var drop_height: float = 200.0
@export var rng_seed: int = 12345

func _ready() -> void:
	seed(rng_seed)  # répartition reproductible d'un lancement à l'autre
	var space_state := get_world_3d().direct_space_state

	for sp in species:
		if sp == null or sp.mesh == null:
			push_warning("Espèce ignorée : aucun mesh assigné dans la fiche.")
			continue

		var noise := FastNoiseLite.new()
		noise.seed = rng_seed + sp.mesh.get_instance_id()
		noise.frequency = sp.noise_frequency

		var mmi := MultiMeshInstance3D.new()
		add_child(mmi)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sp.mesh
		mm.instance_count = sp.count      # on alloue une fois pour toutes
		mmi.multimesh = mm

		var placed := 0
		for i in sp.count:
			var x := randf_range(-area_size, area_size)
			var z := randf_range(-area_size, area_size)
			var n := (noise.get_noise_2d(x, z) + 1.0) * 0.5
			if n < sp.density_threshold:
				continue

			var params := PhysicsRayQueryParameters3D.create(
				Vector3(x, drop_height, z), Vector3(x, -drop_height, z))
			var hit := space_state.intersect_ray(params)
			if hit.is_empty():
				continue

			var t := Transform3D()
			t = t.rotated(Vector3.UP, randf_range(0, TAU))
			t = t.scaled(Vector3.ONE * randf_range(sp.scale_min, sp.scale_max))
			t.origin = hit.position
			mm.set_instance_transform(placed, t)
			placed += 1

		mm.visible_instance_count = placed   # <-- la correction : on N'EFFACE PLUS le buffer
		print("Espèce posée : %d instances sur %d tentatives." % [placed, sp.count])
