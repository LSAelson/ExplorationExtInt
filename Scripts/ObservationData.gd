extends Node

# Autoload "ObservationData" : contenu des Observations (scènes 2D).
# Même principe qu'InfoData : tu rédiges tout ici.
# Chaque section a un "type" : "texte" (géré), "qcm" / "distribution" (à venir).

# Tailles de police par défaut (surchargeables par Observation via "styles").
const DEFAUT_STYLES := {
	"titre": 60, "soustitre": 40, "texte": 28, "boutons": 30,
}

const OBSERVATIONS := {
	"temps": {
		"etape": "temps",                 # étape marquée à l'ouverture
		"titre": "Le Temps",
		"soustitre": "Linéaire ou cyclique ?",
		"texte": "Prendre un instant pour observer l'impact du Temps\nsur sa vie.",
		"styles": {"titre": 35, "texte": 28},                     # ex. {"titre": 72, "texte": 30}
		"sections": [
			{
				"id": "gestion",
				"bouton": "La relativité du temps",
				"bouton_image": "gestionTempsButton.png",   # dans UI/buttons/ ; "" = bouton texte
				"type": "texte",
				"requiert_etape": "",         # mets "grilles_lecture" pour verrouiller (grisé) jusqu'à cette étape
				"titre": "Quel est le sens qui nus fait percevoir que le temps est long ou court ?",
				"texte": "Le déroulement du Temps serait-il lié à\n notre niveau vibratoire ?",
			},
			{
				"id": "cycles",
				"bouton": "L'apprentissage du temps",
				"bouton_image": "leconsCycles.png",   # dans UI/buttons/ ; "" = bouton texte
				"type": "texte",
				"requiert_etape": "",         # mets "grilles_lecture" pour verrouiller (grisé) jusqu'à cette étape
				"titre": "La vie est parcourue de Cycles révélateurs\nsur les archétypes, les énergies ou les processus.",
				"texte": "Le conditionnement à la linéarité du temps\nnous empêche-t-il de percevoir les récurrences et\nd'en tirer leçon ?",
			},
			{
				"id": "question",
				"bouton": "La question que nous pose le Temps",
				"bouton_image": "questionTempsButton.png",   # dans UI/buttons/ ; "" = bouton texte
				"type": "texte",
				"requiert_etape": "",         # mets "grilles_lecture" pour verrouiller (grisé) jusqu'à cette étape
				"titre": "Prisonnier ou libéré du temps ?",
				"texte": "Une fois libéré de ce qui était à faire...\nvers quel but se focalise notre attention ?",
			},
			{
				"id": "echelle_temps",
				"bouton": "Où te situes-tu ?",
				"bouton_image": "autoObservation.png",
				"type": "echelle",
				"requiert_etape": "",
				"titre": "Auto-observation : Sa relation au temps",
				"pole_gauche": {"label": "Disponibilité permanente", "texte": "Esprit ouvert, mental non actif, à l'écoute de l'instant."},
				"pole_droite": {"label": "Absorbation par des noeuds du Temps", "texte": "le temps manque continuellement, impossibilité de se détacher de sa focalisation."},
				"zones": [
					{"max": 20, "texte": "Pleinement disponible — rare et précieux."},
					{"max": 40, "texte": "Le mental veille à ne pas perdre le contrôle."},
					{"max": 60, "texte": "Je Suis : Être ou Suivre"},
					{"max": 80, "texte": "Quelques instants de paix dans un océan de labeurs."},
					{"max": 100, "texte": "Absorbé : le temps dicte, tu suis."},
				],
			},
			{
				"id": "reperes",
				"bouton": "Points repères",
				"bouton_image": "points_repereButton.png",
				"type": "texte",
				"requiert_etape": "",
				"titre": "Points repères",
				"texte": "Albert Einstein : « La seule raison d'être du temps, c'est que tout n'arrive pas en même temps. »\nJean D'Ormesson : « Le temps est la seule chose au monde que tout le monde connaît et éprouve, et qu'on ne peut ni voir, si sentir, ni toucher, ni diriger ni modifier ni définir... il devrait être interdit d'en parler. »",
			},
		],
	},
	"grilles_lecture": {
		"etape": "grilles",                 # étape marquée à l'ouverture
		"titre": "Des grilles pour des repères",
		"soustitre": "Se déprogrammer en apprenant les schémas.",
		"texte": "L'humanité a toujous cherché les patterns de l'existence.",
		"styles": {},                     # ex. {"titre": 72, "texte": 30}
		"sections": [
			{
				"id": "hermetisme",
				"bouton": "La Connaissance de Soi",
				"bouton_image": "hermetisme.png",   # dans UI/buttons/ ; "" = bouton texte
				"type": "texte",
				"requiert_etape": "temps",         # mets "grilles_lecture" pour verrouiller (grisé) jusqu'à cette étape
				"titre": "Savoir faire le rapprochement entre les éléments extérieurs\net les éléments intérieurs.",
				"texte": "Réaliser la puissance des concepts et\n voir que tout est élémentaire (!) et rythme.",
			},
			{
				"id": "reperes",
				"bouton": "Points repères",
				"bouton_image": "points_repereButton.png",
				"type": "texte",
				"requiert_etape": "",
				"titre": "Points repères",
				"texte": "",
			},
		],
	},
}

func obs(cle: String) -> Dictionary:
	return OBSERVATIONS.get(cle, {})

# Taille de police d'une "partie" (titre/soustitre/texte/boutons), défaut si non surchargée.
func style(data: Dictionary, partie: String) -> int:
	var s: Dictionary = data.get("styles", {})
	return int(s.get(partie, DEFAUT_STYLES.get(partie, 28)))
