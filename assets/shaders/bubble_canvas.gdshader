shader_type spatial;
render_mode depth_test_disabled;

global uniform sampler2DArray bubble_cache;
instance uniform int bubble_id;
instance uniform vec2 viewport_ratio;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv = UV * viewport_ratio;
	vec4 color = texture(bubble_cache, vec3(uv.x, uv.y, float(0.0)));
	ALBEDO = color.rgb;
	ALPHA = color.a;
	//vec4 color = texture(bubble_cache, vec3(UV.x, UV.y, float(bubble_id)));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
