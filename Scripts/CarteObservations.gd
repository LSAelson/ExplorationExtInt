extends Node3D
## Objet "générateur de carte" (l'œuf dans la maison).
## Porte la CALIBRATION de la carte et l'ouvre quand le joueur clique dessus (ou touche M).
## La carte elle-même est l'autoload "Carte".

## --- Calibration image <-> monde (ajuste ces 2 valeurs une seule fois) ---
## Coordonnée MONDE (x, z) au CENTRE de l'image. Ton île est centrée sur l'origine.
@export var monde_centre: Vector2 = Vector2.ZERO
## Largeur couverte par l'image, en unités monde (ex. 600 = l'image montre 600 m de large).
@export var monde_taille: float = 600.0
## Image ortho de l'île (vue de dessus). Vide = fond provisoire.
@export var image_carte: Texture2D
## Si vrai : la carte cadre automatiquement tous les points (ignore centre/taille).
## Mets FAUX quand tu fournis ton image pour contrôler le cadrage à la main.
@export var auto_ajuster: bool = true

## Distance à laquelle on peut interagir avec l'œuf.
@export var proximity_radius: float = 5.0
## Mesh cliquable (enfant de ce nœud).
@export var button_node: String = "oeuf_001"

var _player_near := false

func get_calibration() -> Dictionary:
	return {"centre": monde_centre, "taille": monde_taille, "image": image_carte, "auto": auto_ajuster}

func _ready() -> void:
	add_to_group("carte_source")
	get_viewport().physics_object_picking = true

	var area := Area3D.new()
	area.name = "ProximityArea"
	add_child(area)
	var acol := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = proximity_radius
	acol.shape = sphere
	area.add_child(acol)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	var btn := get_node_or_null(button_node) as Node3D
	if btn:
		var body := _get_click_body(btn)
		body.input_ray_pickable = true
		if not body.input_event.is_connected(_on_button_input):
			body.input_event.connect(_on_button_input)
		if btn is MeshInstance3D:
			var ab := (btn as MeshInstance3D).get_aabb()
			area.global_position = btn.global_transform * (ab.position + ab.size * 0.5)
		else:
			area.global_position = btn.global_position
	else:
		push_warning("CarteObservations : mesh '%s' introuvable depuis %s" % [button_node, name])

func _get_click_body(btn: Node3D) -> StaticBody3D:
	for c in btn.get_children():
		if c is StaticBody3D:
			return c
	var body := StaticBody3D.new()
	body.name = "ClickBody"
	btn.add_child(body)
	var bcol := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var ab := AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1, 1, 1))
	if btn is MeshInstance3D:
		ab = (btn as MeshInstance3D).get_aabb()
	box.size = ab.size
	bcol.shape = box
	bcol.position = ab.position + ab.size * 0.5
	body.add_child(bcol)
	return body

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_near = true
		if body.has_method("set_interaction"):
			body.set_interaction(true)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_near = false
		if body.has_method("set_interaction"):
			body.set_interaction(false)

func _on_button_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	if not _player_near:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	ouvrir_carte()

func ouvrir_carte() -> void:
	var carte := get_node_or_null("/root/Carte")
	if carte and carte.has_method("ouvrir"):
		carte.ouvrir(self)
