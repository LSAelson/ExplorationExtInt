extends Node

# Autoload "RepereData" : TOUTES les citations/repères, au même endroit.
# Chaque Observation pointe vers certains repères par leur id (champ "ids" d'une section "reperes").
# Les "concepts" sont les mots-clés qui alimenteront le futur système de PARALLÈLES :
# deux Observations qui citent des repères partageant un concept seront reliables entre elles.

const REPERES := {
	"heraclite_fleuve": {
		"texte": "On ne se baigne jamais deux fois dans le même fleuve.",
		"auteur": "Héraclite",
		"concepts": ["temps", "impermanence", "changement"],
	},
	"kybalion_rythme": {
		"texte": "Tout s'écoule, au-dedans et au-dehors ; tout a ses marées ; le rythme est la compensation.",
		"auteur": "Le Kybalion",
		"concepts": ["rythme", "grilles", "cycles"],
	},
	"seneque_temps": {
		"texte": "Ce n'est pas que nous ayons peu de temps : c'est que nous en perdons beaucoup.",
		"auteur": "Sénèque",
		"concepts": ["temps", "attention"],
	},
}

func repere(id: String) -> Dictionary:
	return REPERES.get(id, {})

# Liste des ids de repères qui portent un concept donné (utile pour les Parallèles).
func par_concept(concept: String) -> Array:
	var out := []
	for id in REPERES:
		if concept in REPERES[id].get("concepts", []):
			out.append(id)
	return out
