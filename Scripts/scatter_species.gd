class_name ScatterSpecies
extends Resource

@export var mesh: Mesh                       # le mesh extrait (arbre, buisson, rocher…)
@export var count: int = 200                 # nombre de candidats à tenter
@export var density_threshold: float = 0.5   # 0 = partout, 1 = presque rien
@export var noise_frequency: float = 0.01    # bas = grands îlots, haut = petits bosquets
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2
