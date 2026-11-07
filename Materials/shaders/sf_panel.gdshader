shader_type spatial;

// Panneau SF : plaques de tailles variées + rainures en relief + lignes lumineuses
// irrégulières (en paquets) à 3 couleurs tirées au hasard. Normal map procédurale.
uniform float scale = 6.0;
uniform vec3 plate_color : source_color = vec3(0.40, 0.43, 0.50);
uniform float plate_variation : hint_range(0.0, 1.0) = 0.4;   // écart de teinte entre plaques
uniform float metallic_val : hint_range(0.0, 1.0) = 0.9;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.4;
uniform float groove_size : hint_range(0.0, 0.3) = 0.06;      // largeur des rainures
uniform float groove_depth : hint_range(0.0, 1.0) = 0.5;      // assombrissement des rainures
uniform float relief : hint_range(0.0, 1.0) = 0.5;            // force de la normal map

uniform float line_scale = 18.0;
uniform float line_density : hint_range(0.0, 1.0) = 0.4;      // proportion de lignes allumées
uniform float line_clustering : hint_range(0.0, 1.0) = 0.6;  // regroupements (écart-type d'espacement)
uniform vec3 line_color1 : source_color = vec3(0.2, 0.9, 1.0);
uniform vec3 line_color2 : source_color = vec3(1.0, 0.5, 0.1);
uniform vec3 line_color3 : source_color = vec3(0.7, 1.0, 0.5);
uniform float line_glow = 3.0;

float h1(float x) { return fract(sin(x * 127.1) * 43758.5453); }
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(float x) { float i = floor(x); float f = fract(x); f = f*f*(3.0-2.0*f); return mix(h1(i), h1(i+1.0), f); }

void fragment() {
	vec2 uv = UV * scale;
	vec2 coarse = floor(uv);
	float sub = 1.0 + step(0.6, h2(coarse + 3.1)) + step(0.85, h2(coarse + 8.2));  // 1,2,3 -> tailles variées
	vec2 guv = uv * sub;
	vec2 cell = floor(guv);
	float pid = h2(cell + sub * 7.0);
	vec3 albedo = plate_color * clamp(1.0 + (pid - 0.5) * 2.0 * plate_variation, 0.2, 1.8);

	vec2 f = fract(guv);
	vec2 d = min(f, 1.0 - f);
	float groove = smoothstep(groove_size, 0.0, min(d.x, d.y));
	albedo *= (1.0 - groove * groove_depth);

	vec3 emit = vec3(0.0);
	float pxx = max(fwidth(UV.x) * line_scale, 0.00001);
	float pxy = max(fwidth(UV.y) * line_scale, 0.00001);

	// Lignes verticales : paquets (clustering), largeur 1/3/5 px, segments bruités, couleur au hasard.
	float lx = UV.x * line_scale;
	float ix = floor(lx);
	float onV = step(1.0 - line_density, vn(ix * mix(1.0, 0.12, line_clustering) + 1.3));
	float wV = (1.0 + 2.0 * floor(h1(ix + 7.0) * 3.0)) * pxx;
	float segV = step(0.3, vn(floor(UV.y * line_scale * 0.5) * 0.7 + ix));
	float lineV = step(abs(fract(lx) - 0.5), wV) * onV * segV;
	float cV = h1(ix + 3.3);
	emit += (cV < 0.34 ? line_color1 : (cV < 0.67 ? line_color2 : line_color3)) * lineV;

	// Lignes horizontales.
	float ly = UV.y * line_scale;
	float iy = floor(ly);
	float onH = step(1.0 - line_density, vn(iy * mix(1.0, 0.12, line_clustering) + 5.7));
	float wH = (1.0 + 2.0 * floor(h1(iy + 11.0) * 3.0)) * pxy;
	float segH = step(0.3, vn(floor(UV.x * line_scale * 0.5) * 0.7 + iy));
	float lineH = step(abs(fract(ly) - 0.5), wH) * onH * segH;
	float cH = h1(iy + 9.1);
	emit += (cH < 0.34 ? line_color1 : (cH < 0.67 ? line_color2 : line_color3)) * lineH;

	ALBEDO = albedo;
	METALLIC = metallic_val;
	ROUGHNESS = roughness_val;
	EMISSION = emit * line_glow;

	// Relief procédural : les rainures s'enfoncent (normale en tangent-space).
	float nx = (f.x < 0.5 ? 1.0 : -1.0) * smoothstep(groove_size, 0.0, d.x);
	float ny = (f.y < 0.5 ? 1.0 : -1.0) * smoothstep(groove_size, 0.0, d.y);
	NORMAL_MAP = normalize(vec3(nx * relief, ny * relief, 1.0)) * 0.5 + 0.5;
}
