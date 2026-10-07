extends Node

# ============================================================
#  CONTENU DES BOÎTES D'INFO
#  -> C'est ICI que tu saisis et modifies tous les textes.
#  Chaque entrée : "cle" = { "titre":..., "soustitre":..., "corps":... }
#  Les retours à la ligne se font avec \n.
#  titre  = grand (titre) · soustitre = moyen · corps = texte principal
# ============================================================

const BOXES := {
	"temps": {
		"titre": "Observation primitive sur le Temps",
		"soustitre": "Trois voies seront proposées.\nLe Passé, le Présent et le Futur.",
		"corps": "Il est conseillé de les parcourir dans l'ordre\nchronologique. Compliqué de se projeter dans\nl'avenir sans avoir domestiqué les fantômes\ndu passé. Quant au Présent...\nIl est justement en jeu !",
	},
	"present": {
		"titre": "La Création au cœur du Présent.",
		"soustitre": "Entre les 2 tentations temporelles,\nle Présent équilibre-t-il ?",
		"corps": "Apprendre et Jouer sont-ils si différents ?\nMême les animaux apprennent en jouant.\nSe rappeler que le Présent est aussi un cadeau.",
	},
	"passe": {
		"titre": "Voie de l'histoire",
		"soustitre": "Les Attachements du Passé",
		"corps": "Des grilles de lecture pour décrypter les énergies\nqui ont alimenté notre développement\net notre évolution.\nDes observations sur nos démons, valises, casseroles,\ngri-gris, cailloux dans la chaussure !",
	},
	"futur": {
		"titre": "Le Futur comme Projection ou\nCréation de ligne de temps.",
		"soustitre": "Où nous emmènent nos rêves et désirs ?",
		"corps": "Si on ne connaît pas l'avenir,\non peut sûrement l'influencer.\nMais comment ?",
	},
}

# ============================================================
#  LIBELLÉS LITTÉRAIRES (affichés dans les menus : profil, parallèles…)
# ============================================================
const LABELS := {
	"temps": "Temps",
	"passe": "Passé",
	"present": "Présent",
	"futur": "Futur",
}

# Renvoie le libellé littéraire d'une clé (sinon la clé simplement capitalisée).
func label(cle: String) -> String:
	return LABELS.get(cle, cle.capitalize())

# ============================================================
#  PAGES D'AIDE PAR THÈME (bouton « Aide » du panneau)
#  -> Tu rédiges ici l'aide de chaque thème. Chaîne vide = pas d'aide.
#  Les retours à la ligne se font avec \n.
# ============================================================
const AIDES := {
	"temps": "",
	"passe": "",
	"present": "",
	"futur": "",
}

func aide(cle: String) -> String:
	return AIDES.get(cle, "")
