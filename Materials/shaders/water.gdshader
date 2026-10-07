shader_type spatial;
render_mode blend_mix, cull_back;

uniform vec4 deep_color : source_color = vec4(0.06, 0.32, 0.42, 0.55);
uniform vec4 shallow_color : source_color = vec4(0.40, 0.70, 0.75, 0.90);
uniform float wave_scale = 0.4;      // densité des ondulations
uniform float wave_speed = 0.6;      // vitesse
uniform float wave_strength = 0.25;  // amplitude des vaguelettes
uniform float fresnel_power = 4.0;   // netteté du reflet rasant
uniform float water_roughness = 0.06;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float ripple(vec2 p, float t) {
	return sin(p.x + t) * 0.5
		 + sin(p.y * 1.3 - t * 0.8) * 0.5
		 + sin((p.x + p.y) * 0.7 + t * 1.1) * 0.5
		 + sin((p.x - p.y) * 1.7 - t * 0.6) * 0.5;
}

void fragment() {
	vec2 p = world_pos.xz * wave_scale;
	float t = TIME * wave_speed;
	float e = 0.15;
	float nx = ripple(p + vec2(e, 0.0), t) - ripple(p - vec2(e, 0.0), t);
	float nz = ripple(p + vec2(0.0, e), t) - ripple(p - vec2(0.0, e), t);
	// normale d'une nappe horizontale (up = Y) perturbée par les vagues
	vec3 wn = normalize(vec3(-nx * wave_strength, 1.0, -nz * wave_strength));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, fres);
	ALPHA = mix(deep_color.a, shallow_color.a, fres);
	METALLIC = 0.0;
	ROUGHNESS = water_roughness;
	SPECULAR = 0.6;
}
