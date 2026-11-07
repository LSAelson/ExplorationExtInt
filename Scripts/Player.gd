extends CharacterBody3D

@export_group("Déplacement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 12.0
@export var jump_velocity: float = 4.8
@export var mouse_sensitivity: float = 0.004
@export var gravity: float = 9.8

@export_group("Caméra")
@export var bob_amplitude: float = 0.08
@export var fov_change: float = 0.0

@export_group("Escaliers")
## Hauteur de marche franchie automatiquement (monte les escaliers sans rampe).
@export var step_max_height: float = 0.5
@export var step_enabled: bool = true

@export_group("Intro")
## Clé d'info (InfoData) proposée au 1er contact avec le sol (ex. "temps" dans la pyramide). Vide = rien.
@export var intro_key: String = ""

var speed

const BOB_FREQ = 2.4
const BASE_FOV = 75.0
var t_bob = 0.0

# --- Gestion centralisée du curseur ---
var _near_count := 0   # nb de zones d'interaction où se trouve le joueur
var _focused := true   # la fenêtre de jeu est-elle active ?
var _landed := false   # 1er contact avec le sol (déclenche l'info d'intro)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready():
	add_to_group("player")
	floor_snap_length = step_max_height   # colle aux marches en descente
	_apply_settings()
	_update_mouse()
	call_deferred("_appliquer_retour")


# Mémorise la position actuelle (appelé avant de quitter vers une Observation).
func memoriser_position_retour() -> void:
	if get_tree().current_scene:
		GameState.retour_scene = get_tree().current_scene.scene_file_path
	GameState.retour_position = global_position
	GameState.retour_rotation_y = head.rotation.y
	GameState.a_position_retour = true


# Enregistre le lieu (scène + position) de la stèle activée, pour y revenir depuis le profil.
func enregistrer_lieu(key: String) -> void:
	if key == "":
		return
	var sc := ""
	if get_tree().current_scene:
		sc = get_tree().current_scene.scene_file_path
	GameState.enregistrer_lieu(key, sc, global_position, head.rotation.y)


# Re-place le joueur à l'endroit mémorisé, au chargement de la scène de retour.
func _appliquer_retour() -> void:
	if not GameState.a_position_retour:
		return
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == GameState.retour_scene:
		global_position = GameState.retour_position
		head.rotation.y = GameState.retour_rotation_y
		velocity = Vector3.ZERO
		GameState.a_position_retour = false


# Applique les réglages du GameState (vitesse, sensibilité, focale).
func _apply_settings() -> void:
	walk_speed = GameState.move_speed
	sprint_speed = GameState.sprint_speed
	mouse_sensitivity = GameState.mouse_sensitivity
	camera.fov = GameState.fov


func _notification(what):
	# Perte/retour de focus (dialogue, Alt-Tab, Cmd-Q…)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_update_mouse()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_update_mouse()


# Appelé par les téléporteurs quand le joueur entre/sort de leur zone de proximité.
func set_interaction(active: bool) -> void:
	_near_count = max(0, _near_count + (1 if active else -1))
	_update_mouse()


func _update_mouse() -> void:
	# Curseur visible si on est près d'une interaction OU si la fenêtre n'a pas le focus.
	if _near_count > 0 or not _focused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	# Molette de souris = focale (zoom) entre fov_min et fov_max du GameState.
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			GameState.set_fov(GameState.fov - 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			GameState.set_fov(GameState.fov + 2.0)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var inv := -1.0 if GameState.invert_y else 1.0
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity * inv)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	if GameState.headbob:
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
	else:
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 8.0)

	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2.0)
	var target_fov = GameState.fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()
	_tenter_marche(direction)


# Franchit automatiquement une marche (jusqu'à step_max_height) sans rampe ni blocage.
func _tenter_marche(wish: Vector3) -> void:
	if not step_enabled or not is_on_floor() or not is_on_wall():
		return
	var dir_plat := Vector3(wish.x, 0.0, wish.z)
	if dir_plat.length() < 0.1:
		return
	var dir := dir_plat.normalized() * 0.3
	# 1) surélevé de step_max_height, le chemin devant est-il libre ? (sinon : vrai mur)
	var haut := global_transform
	haut.origin += Vector3.UP * step_max_height
	var p1 := PhysicsTestMotionParameters3D.new()
	p1.from = haut
	p1.motion = dir
	if PhysicsServer3D.body_test_motion(get_rid(), p1):
		return
	# 2) depuis là, redescendre pour trouver la marche
	var avant := haut
	avant.origin += dir
	var p2 := PhysicsTestMotionParameters3D.new()
	p2.from = avant
	p2.motion = Vector3.DOWN * (step_max_height + 0.05)
	var r2 := PhysicsTestMotionResult3D.new()
	if not PhysicsServer3D.body_test_motion(get_rid(), p2, r2):
		return
	# On ne monte que sur une surface quasi plane (vraie marche), jamais une pente (évite de se coincer sur le tertre).
	if r2.get_collision_normal().y < 0.9:
		return
	# 3) poser le joueur sur la marche
	global_position = Vector3(avant.origin.x, avant.origin.y + r2.get_travel().y, avant.origin.z)


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * bob_amplitude
	pos.x = cos(time * BOB_FREQ / 2) * bob_amplitude
	return pos
