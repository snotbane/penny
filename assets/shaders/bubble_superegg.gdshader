shader_type spatial;

#include "uid://bsta8u5ivy4aa"

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 emissive : source_color = vec3(1.0);
uniform float specular : hint_range(0.0, 1.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	VERTEX = superegg(VERTEX);
	//NORMAL = -NORMAL;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
	EMISSION = emissive;
	SPECULAR = specular;
	ROUGHNESS = roughness;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
