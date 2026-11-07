shader_type spatial;
render_mode cull_disabled;

// Symbole énergétique : veines lumineuses animées + liseré de Fresnel + pulsation.
uniform vec3 energy_color : source_color = vec3(0.30, 0.70, 1.0);
uniform float speed = 1.2;
uniform float intensity = 2.5;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i), b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	float t = TIME * speed;
	float n = noise(UV * 6.0 + vec2(t, t * 0.5));
	float veins = pow(n, 3.0) * 2.0;
	float pulse = 0.7 + 0.3 * sin(TIME * 2.5);
	float fres = pow(1.0 - abs(dot(normalize(VIEW), normalize(NORMAL))), 2.5);
	EMISSION = energy_color * (veins + fres * 1.5) * intensity * pulse;
	ALBEDO = energy_color * 0.15;
	METALLIC = 0.0;
	ROUGHNESS = 0.4;
}
