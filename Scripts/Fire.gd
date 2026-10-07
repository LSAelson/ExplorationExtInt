extends Node3D

@export_group("Lumière")
@export var light_color: Color = Color(1.0, 0.6, 0.25)
@export var light_energy: float = 2.5
@export var light_range: float = 9.0
## 0 = stable, 1 = très tremblant
@export_range(0.0, 1.0) var flicker_amount: float = 0.35
@export var flicker_speed: float = 8.0
@export var cast_shadows: bool = true

@export_group("Flammes")
@export var enable_flames: bool = true
@export var flame_amount: int = 24
@export var flame_size: float = 0.5
## Vitesse/hauteur de montée des flammes
@export var flame_height: float = 1.2
@export var flame_lifetime: float = 0.9

var _light: OmniLight3D
var _noise := FastNoiseLite.new()
var _t := 0.0

func _ready() -> void:
	_noise.frequency = 1.0

	_light = OmniLight3D.new()
	_light.light_color = light_color
	_light.light_energy = light_energy
	_light.omni_range = light_range
	_light.shadow_enabled = cast_shadows
	add_child(_light)

	if enable_flames:
		_build_flames()

func _process(delta: float) -> void:
	_t += delta * flicker_speed
	var f := _noise.get_noise_1d(_t) * 0.5 + 0.5
	_light.light_energy = light_energy * (1.0 - flicker_amount + flicker_amount * (0.6 + 0.8 * f))
	_light.position = Vector3(_noise.get_noise_1d(_t + 10.0), 0.0, _noise.get_noise_1d(_t + 20.0)) * flicker_amount * 0.15

func _build_flames() -> void:
	var p := CPUParticles3D.new()
	p.amount = flame_amount
	p.lifetime = flame_lifetime
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = flame_size * 0.4
	p.direction = Vector3(0, 1, 0)
	p.spread = 15.0
	p.initial_velocity_min = flame_height * 0.6
	p.initial_velocity_max = flame_height
	p.gravity = Vector3(0, flame_height * 0.8, 0)
	p.scale_amount_min = flame_size
	p.scale_amount_max = flame_size * 1.4
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.4, 1.0))
	g.add_point(0.4, Color(1.0, 0.45, 0.1, 1.0))
	g.set_color(1, Color(0.4, 0.03, 0.0, 0.0))
	p.color_ramp = g
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _radial_tex()
	quad.material = mat
	p.mesh = quad
	p.emitting = true
	add_child(p)

func _radial_tex() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t
