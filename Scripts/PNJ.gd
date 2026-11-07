extends Node3D
## PNJ : joue une animation d'attente en boucle.
## Fondation du personnage non-joueur — sera étendue pour le dialogue
## (zone d'interaction, état idle <-> talking, etc.).

## AnimationPlayer qui porte les clips Mixamo (ici : voisin du personnage).
@export var animation_player_path: NodePath = ^"../AnimationPlayer"
## Clip joué en boucle au repos.
@export var idle_anim: String = "veille"
## Vitesse de lecture de l'idle (1.0 = normal ; <1 = plus lent, plus calme).
@export var idle_speed: float = 1.0

@onready var _ap: AnimationPlayer = get_node_or_null(animation_player_path)

func _ready() -> void:
	if _ap == null:
		push_warning("PNJ : AnimationPlayer introuvable (%s)." % str(animation_player_path))
		return
	jouer_idle()

## Lance (ou relance) l'animation d'attente en boucle.
func jouer_idle() -> void:
	if _ap == null or not _ap.has_animation(idle_anim):
		push_warning("PNJ : animation '%s' absente de l'AnimationPlayer." % idle_anim)
		return
	# Les clips Mixamo sont importés en loop_mode=none : on force la boucle.
	var anim := _ap.get_animation(idle_anim)
	anim.loop_mode = Animation.LOOP_LINEAR
	_ap.play(idle_anim, -1, idle_speed)

## Joue un clip ponctuel (ex. 'talking') puis revient à l'idle en boucle.
func jouer_ponctuel(nom: String) -> void:
	if _ap == null or not _ap.has_animation(nom):
		push_warning("PNJ : animation '%s' absente." % nom)
		return
	var anim := _ap.get_animation(nom)
	anim.loop_mode = Animation.LOOP_NONE
	_ap.play(nom)
	if not _ap.animation_finished.is_connected(_on_ponctuel_fini):
		_ap.animation_finished.connect(_on_ponctuel_fini, CONNECT_ONE_SHOT)

func _on_ponctuel_fini(_nom: StringName) -> void:
	jouer_idle()
