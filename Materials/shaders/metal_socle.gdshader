shader_type spatial;

// Métal : couleur unie fortement métallique, léger grain pour casser l'aspect plastique.
uniform vec3 metal_color : source_color = vec3(0.60, 0.62, 0.68);
uniform float roughness_val = 0.25;
uniform float grain_scale = 24.0;
uniform float grain_amount = 0.06;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	float grain = hash(floor(UV * grain_scale)) * grain_amount;
	ALBEDO = metal_color;
	METALLIC = 1.0;
	ROUGHNESS = clamp(roughness_val + grain, 0.0, 1.0);
}
