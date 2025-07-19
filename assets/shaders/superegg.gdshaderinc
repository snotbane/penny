instance uniform vec3 superegg_size = vec3(1.0, 1.0, 1.0);
instance uniform float superegg_power : hint_range(0.0, 10.0) = 2.5;
uniform bool proportional = true;

float signed_pow(float val, float e) {
	return sign(val) * pow(abs(val), e);
}

vec3 superegg(vec3 vertex) {
	vec3 v = normalize(vertex);

	vec3 proportion = proportional ? vec3(
		superegg_size.x > superegg_size.y ? superegg_size.y / superegg_size.x : 1.0,
		superegg_size.y > superegg_size.x ? superegg_size.x / superegg_size.y : 1.0,
		superegg_size.z > superegg_size.y ? superegg_size.y / superegg_size.z : 1.0
	) : vec3(1.0);

    float theta = atan(v.y, v.x);
    float phi = acos(clamp(v.z, -1.0, 1.0));

    float sin_phi = sin(phi);
    float cos_phi = cos(phi);
    float cos_theta = cos(theta);
    float sin_theta = sin(theta);

	float e = (2.0 / superegg_power);

    float px = superegg_size.x * signed_pow(cos_theta * sin_phi, e * proportion.x);
    float py = superegg_size.y * signed_pow(sin_theta * sin_phi, e * proportion.y);
    float pz = superegg_size.z * signed_pow(cos_phi, e * proportion.z);

    return vec3(px, py, pz) * 0.5;
}
