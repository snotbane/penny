shader_type spatial;

#include "uid://bsta8u5ivy4aa"

uniform float sss_strength : hint_range(0.0, 1.0) = 0.5;
uniform vec4 sss_color : source_color = vec4(1.0, 0.6, 0.5, 1.0);

void vertex() {
	VERTEX = superegg(VERTEX);
	//NORMAL = -NORMAL;
}

void fragment() {
	SSS_STRENGTH = sss_strength;
	SSS_TRANSMITTANCE_COLOR = sss_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
