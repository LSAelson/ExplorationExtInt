shader_type spatial;

// Marbre procédural : veines de turbulence (couleurs/échelle réglables).
uniform vec3 base_color : source_color = vec3(0.92, 0.90, 0.86);
uniform vec3 vein_color : source_color = vec3(0.22, 0.20, 0.18);
uniform float vein_scale = 2.5;
uniform float vein_sharpness = 1.8;
uniform float turbulence = 4.0;
uniform float rough : hint_range(0.0, 1.0) = 0.3;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
	               mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
	               mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
	return v;
}

varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec3 p = world_pos * vein_scale;
	float turb = fbm(p);
	float veins = sin(p.x + turb * turbulence);
	veins = pow(abs(veins), vein_sharpness);
	ALBEDO = mix(vein_color, base_color, veins);
	METALLIC = 0.0;
	ROUGHNESS = rough;
}
