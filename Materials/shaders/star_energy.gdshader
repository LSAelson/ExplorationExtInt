shader_type spatial;
render_mode cull_back;

uniform vec3 energy_color : source_color = vec3(0.3, 0.7, 1.0);   // couleur des arcs
uniform vec3 core_color : source_color = vec3(0.02, 0.05, 0.15);  // base sombre
uniform float arc_scale = 6.0;          // densité des veines
uniform float arc_speed = 4.0;          // vitesse de parcours
uniform float arc_sharpness = 16.0;     // finesse des arcs (plus grand = plus fins)
uniform float fresnel_power = 2.5;      // netteté du halo de bord
uniform float pulse_speed = 2.0;        // vitesse de pulsation
uniform float emission_strength = 4.0;  // intensité lumineuse (Glow recommandé)

varying vec3 world_pos;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash13(i + vec3(0.0, 0.0, 0.0));
	float b = hash13(i + vec3(1.0, 0.0, 0.0));
	float c = hash13(i + vec3(0.0, 1.0, 0.0));
	float d = hash13(i + vec3(1.0, 1.0, 0.0));
	float e = hash13(i + vec3(0.0, 0.0, 1.0));
	float g = hash13(i + vec3(1.0, 0.0, 1.0));
	float h = hash13(i + vec3(0.0, 1.0, 1.0));
	float k = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(a, b, f.x), mix(c, d, f.x), f.y),
			   mix(mix(e, g, f.x), mix(h, k, f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 p = world_pos * arc_scale;
	float t = TIME * arc_speed;
	// deux couches de bruit qui défilent -> veines mouvantes
	float n = vnoise(p + vec3(0.0, t, 0.0)) * 0.6 + vnoise(p * 2.1 + vec3(-t, t * 0.5, 0.0)) * 0.4;
	// fines lignes lumineuses le long des contours du bruit
	float arc = pow(1.0 - abs(n - 0.5) * 2.0, arc_sharpness);
	// pulsation globale
	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed);
	// halo de bord (Fresnel)
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);

	ALBEDO = core_color;
	float glow = clamp(arc * pulse + fres * 0.6, 0.0, 2.0);
	EMISSION = energy_color * glow * emission_strength;
	METALLIC = 0.0;
	ROUGHNESS = 0.5;
}
