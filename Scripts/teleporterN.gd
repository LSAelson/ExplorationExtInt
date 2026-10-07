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

var speed

const BOB_FREQ = 2.4
const BASE_FOV = 75.0
var t_bob = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
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

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2.0)
	var target_fov = BASE_FOV + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * bob_amplitude
	pos.x = cos(time * BOB_FREQ / 2) * bob_amplitude
	return pos
