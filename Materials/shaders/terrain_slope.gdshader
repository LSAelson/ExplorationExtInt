shader_type spatial;

// --- Surfaces PLATES (rocky_terrain_02) ---
uniform sampler2D flat_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D flat_normal : filter_linear_mipmap, repeat_enable;
uniform sampler2D flat_arm    : filter_linear_mipmap, repeat_enable; // R=AO G=Rough B=Metal
// --- Surfaces EN PENTE (cliff_side) ---
uniform sampler2D slope_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D slope_normal : filter_linear_mipmap, repeat_enable;
uniform sampler2D slope_arm    : filter_linear_mipmap, repeat_enable;

uniform float tex_scale = 0.15;
uniform float rock_below : hint_range(0.0, 1.0) = 0.72;
uniform float flat_above : hint_range(0.0, 1.0) = 0.90;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

varying vec3 w_pos;
varying vec3 w_norm;

void vertex() {
	w_pos  = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 tri_col(sampler2D t, vec3 p, vec3 bw) {
	return texture(t, p.zy).rgb * bw.x
	     + texture(t, p.xz).rgb * bw.y
	     + texture(t, p.xy).rgb * bw.z;
}

vec3 tri_normal(sampler2D t, vec3 p, vec3 n, vec3 bw) {
	vec3 tx = texture(t, p.zy).xyz * 2.0 - 1.0;
	vec3 ty = texture(t, p.xz).xyz * 2.0 - 1.0;
	vec3 tz = texture(t, p.xy).xyz * 2.0 - 1.0;
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	return normalize(tx.zyx * bw.x + ty.xzy * bw.y + tz.xyz * bw.z);
}

void fragment() {
	vec3 p  = w_pos * tex_scale;
	vec3 an = abs(w_norm);
	vec3 bw = an / (an.x + an.y + an.z);

	float up   = clamp(w_norm.y, 0.0, 1.0);
	float rock = 1.0 - smoothstep(rock_below, flat_above, up);

	ALBEDO = mix(tri_col(flat_albedo, p, bw), tri_col(slope_albedo, p, bw), rock);

	float fr = tri_col(flat_arm, p, bw).g;
	float sr = tri_col(slope_arm, p, bw).g;
	ROUGHNESS = mix(fr, sr, rock);
	METALLIC = 0.0;

	vec3 fn = tri_normal(flat_normal, p, w_norm, bw);
	vec3 sn = tri_normal(slope_normal, p, w_norm, bw);
	vec3 wn = normalize(mix(fn, sn, rock));
	wn = normalize(mix(w_norm, wn, normal_strength));
	NORMAL = (VIEW_MATRIX * vec4(wn, 0.0)).xyz;
}
