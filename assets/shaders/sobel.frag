#version 100

precision mediump float;

// Input vertex attributes (from vertex shader)
varying vec2 fragTexCoord;
varying vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;

uniform float width;
uniform float height;
uniform float threshold;
uniform float mouse_x;
uniform float mouse_y;

void make_kernel(inout vec4 n[9], sampler2D tex, vec2 coord)
{
	float w = 1.0 / width;
	float h = 1.0 / height;

	n[0] = texture2D(tex, coord + vec2( -w, -h));
	n[1] = texture2D(tex, coord + vec2(0.0, -h));
	n[2] = texture2D(tex, coord + vec2(  w, -h));
	n[3] = texture2D(tex, coord + vec2( -w, 0.0));
	n[4] = texture2D(tex, coord);
	n[5] = texture2D(tex, coord + vec2(  w, 0.0));
	n[6] = texture2D(tex, coord + vec2( -w, h));
	n[7] = texture2D(tex, coord + vec2(0.0, h));
	n[8] = texture2D(tex, coord + vec2(  w, h));
}

void main(void)
{
	float uv_x = fragTexCoord.x * width;
	float uv_y = (1.0 - fragTexCoord.y) * height;

	float dist_x = uv_x - mouse_x * 2.0;
	float dist_y = uv_y - mouse_y * 2.0;

	float abs_dist = sqrt((dist_x * dist_x) + (dist_y * dist_y));
	if (abs_dist < 60.0) {
		gl_FragColor = texture2D(texture0, fragTexCoord);
		return;
	}

	if (abs_dist > 150.0) {
		gl_FragColor = vec4(vec3(0), 1);
		return;
	}

	vec4 n[9];
	make_kernel( n, texture0, fragTexCoord );

	vec4 sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
  	vec4 sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));

	float edge_intensity = length(sobel.rgb);
	float edge = step(threshold, edge_intensity);
	vec4 s = texture2D(texture0, fragTexCoord) * edge;

	gl_FragColor = s;
}
