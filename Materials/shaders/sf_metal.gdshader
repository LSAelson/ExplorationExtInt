shader_type spatial;

// Plaque métallique SF : rainures de panneaux + veines lumineuses rectilignes optionnelles.
uniform vec3 metal_color : source_color = vec3(0.45, 0.48, 0.55);
uniform float metallic_val : hint_range(0.0, 1.0) = 0.9;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.35;

// Rainures de panneaux (grille creuse)
uniform float panel_scale = 4.0;
uniform float groove_width : hint_range(0.0, 0.1) = 0.03;

// Veines lumineuses (0 = aucune). Petit vein_spacing = veines serrées.
uniform vec3 vein_color : source_color = vec3(0.2, 0.9, 1.0);
uniform float vein_spacing = 0.0;
uniform float vein_width : hint_range(0.0, 0.1) = 0.02;
uniform float vein_glow = 3.0;
uniform float vein_pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV * panel_scale;
	vec2 g = abs(fract(uv) - 0.5);
	float groove = step(0.5 - groove_width, max(g.x, g.y));
	ALBEDO = metal_color * (1.0 - groove * 0.5);
	METALLIC = metallic_val;
	ROUGHNESS = clamp(roughness_val + groove * 0.3, 0.0, 1.0);

	if (vein_spacing > 0.0) {
		float line = abs(fract(UV.x / vein_spacing) - 0.5);
		float vein = smoothstep(vein_width, 0.0, line);
		float pulse = 1.0 + vein_pulse * 0.5 * sin(TIME * 2.0);
		EMISSION = vein_color * vein * vein_glow * pulse;
	}
}
