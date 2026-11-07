shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

// Cristal / diamant : réfraction de l'arrière-plan + liseré de Fresnel + spéculaire fort.
uniform vec3 crystal_color : source_color = vec3(0.60, 0.85, 1.0);
uniform float tint : hint_range(0.0, 1.0) = 0.35;      // teinte vs transparence
uniform float fresnel_power = 2.5;
uniform float refraction : hint_range(0.0, 0.3) = 0.06;
uniform float rough : hint_range(0.0, 1.0) = 0.03;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	float fres = pow(1.0 - abs(dot(normalize(VIEW), normalize(NORMAL))), fresnel_power);
	vec2 ref_uv = SCREEN_UV + NORMAL.xy * refraction;   // décale l'écran = réfraction
	vec3 bg = texture(screen_tex, ref_uv).rgb;
	ALBEDO = mix(bg, crystal_color, tint + fres * (1.0 - tint));
	METALLIC = 0.0;
	ROUGHNESS = rough;
	SPECULAR = 1.0;
	RIM = 1.0;
	EMISSION = crystal_color * fres * 0.3;
}
