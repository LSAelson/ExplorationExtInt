shader_type sky;

uniform samplerCube skybox : source_color;

void sky() {
    COLOR = texture(skybox, EYEDIR).rgb;
}
