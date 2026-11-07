shader_type canvas_item;

// Désature la texture (niveaux de gris) — pour un bouton/élément "désactivé".
// À poser comme Material sur un TextureButton quand il est grisé ; retirer pour le réactiver.
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float g = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(g), tex.a) * COLOR;
}
