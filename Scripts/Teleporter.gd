extends Node3D

## Scène vers laquelle téléporter (via le bouton Explorer de la boîte d'info).
@export_file var destination: String = ""
## Distance autour du socle à laquelle le curseur apparaît.
@export var proximity_radius: float = 4.0
## Chemin du mesh-symbole à rendre cliquable (ex: "../star_001").
@export var button_node: String = "coupDePoing"
## Clé de la boîte d'info à ouvrir au clic (dans InfoData). Vide = téléporte directement.
@export var info_key: String = ""

var _player_near := false

func _ready() -> void:
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
		push_warning("Teleporter : symbole '%s' introuvable depuis %s" % [button_node, name])

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
		if info_key != "":
			var hud := get_node_or_null("/root/HUD")
			if hud:
				hud.set_info(info_key, destination)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_near = false
		if body.has_method("set_interaction"):
			body.set_interaction(false)
		if info_key != "":
			var hud := get_node_or_null("/root/HUD")
			if hud:
				hud.clear_info()

func _on_button_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	if not _player_near:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if info_key != "":
		InfoPanel.show_for_stele(info_key, destination)   # ouvre la boîte -> Explorer lancera le monde
	elif destination != "":
		get_tree().change_scene_to_file(destination)       # téléport direct si pas d'info
	else:
		push_warning("Teleporter : ni info_key ni destination sur " + name)
