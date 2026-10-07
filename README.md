# ExplorationExtInt

Jeu d'exploration first-person développé sous **Godot 4.7** (projet INO).

Trois portails temporels (stèles) mènent à trois mondes — **Passé**, **Présent**, **Futur** —
articulés autour d'un contenu narratif/philosophique (valeurs, peurs, principes).

## Organisation du dépôt

Ce dépôt suit **le code et les ressources légères** : scripts GDScript, shaders,
petites scènes, UI et configuration. Les **gros binaires sont hors Git** (voir
`.gitignore`) car ils dépassent les limites de GitHub — ils sont sauvegardés à part :

- meshes source `*.glb` (dossier `importsGLB/`)
- textures 4K / normal maps (`Materials/textures/`)
- skybox `*.exr` / `*.hdr`
- `Scenes/strataWorld.tscn` (113 Mo — à reconvertir en `.scn` binaire)

## Autoloads (ordre important)

`GameState` → `InfoData` → `InfoPanel` → `HUD` → `PauseMenu` → `ProfilReglages`

- **GameState** : profil, progression (étapes visitées), réglages, sauvegarde `user://profil.save`
- **InfoData** : contenu des panneaux + libellés littéraires
- **InfoPanel** : panneau d'info réutilisable
- **HUD** : boutons info / profil
- **PauseMenu** : menu Échap (Continuer / Réglages / Quitter)
- **ProfilReglages** : panneau fusionné Profil + Réglages (onglets)
