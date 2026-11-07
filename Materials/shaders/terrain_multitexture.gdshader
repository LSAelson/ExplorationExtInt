shader_type spatial;

// Terrain multi-texture par COULEUR DE VERTEX (peinte dans Blender) :
//   canal R -> tex_r (ex. herbe)   G -> tex_g (ex. roche)   B -> tex_b (ex. sable)
// Projection du dessus (world XZ) pour éviter d'avoir à dépaqueter des UV.
uniform sampler2D tex_r : source_color, hint_default_white;
uniform sampler2D tex_g : source_color, hint_default_white;
uniform sampler2D tex_b : source_color, hint_default_white;
uniform float tex_scale = 0.2;
uniform float rough : hint_range(0.0, 1.0) = 0.9;

varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 uv = world_pos.xz * tex_scale;
	vec3 w = COLOR.rgb;                       // couleur de vertex = poids des 3 textures
	float sum = w.r + w.g + w.b + 1e-4;
	vec3 col = (texture(tex_r, uv).rgb * w.r
	          + texture(tex_g, uv).rgb * w.g
	          + texture(tex_b, uv).rgb * w.b) / sum;
	ALBEDO = col;
	METALLIC = 0.0;
	ROUGHNESS = rough;
}
