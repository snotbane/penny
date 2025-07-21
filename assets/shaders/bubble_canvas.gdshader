shader_type spatial;
render_mode depth_test_disabled;

uniform sampler2D viewport_texture;

//void vertex() {

//}

void fragment() {
	vec4 color = texture(viewport_texture, UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

//void light() {

//}
