#version 120
#extension GL_EXT_gpu_shader4 : enable

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
// default light radius
uniform float radius = 150;
// the number of unique bayer layers, more equal smoother transition
// up to NxN in the bayer_matrix
// aka. 0 -> 4.
uniform int granularity = 4;
// increase 'scale' of the dither to make more pixelated
// lower number -> more pixelated
// from 0 -> 1.
uniform float dither_scale = 0.3;

const float bayer_matrix[4][4] = float[4][4](
    float[](0.0 / 16.0, 12.0 / 16.0, 3.0 / 16.0, 15.0 / 16.0),
    float[](8.0 / 16.0, 4.0 / 16.0, 11.0 / 16.0, 7.0 / 16.0),
    float[](2.0 / 16.0, 14.0 / 16.0, 1.0 / 16.0, 13.0 / 16.0),
    float[](10.0 / 16.0, 6.0 / 16.0, 9.0 / 16.0, 5.0 / 16.0)
);

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

// Main fragment shader function
void main() {
	vec2 resolution = vec2(width, height);
	float uv_x = fragTexCoord.x * width;
	float uv_y = (1.0 - fragTexCoord.y) * height;

	vec2 uv = vec2(uv_x, uv_y);
	vec2 mouse_pos = vec2(mouse_x, mouse_y) * 2;
    // Compute the distance from the mouse position to this pixel
    float distance = length(uv - mouse_pos);

    // Invert the distance so that closer pixels are brighter
    float brightness = 1.0 - distance / radius;

    // Scale brightness to control the light radius and intensity
    brightness = clamp(brightness * 3.0, 0.0, 1.0);  // Adjust `3.0` as a radius factor

    // Get pixel coordinates in the Bayer matrix
	vec2 grid_coord = floor(gl_FragCoord.xy * dither_scale) / dither_scale;

	// granularity can not be > len(bayer_matrix)
    ivec2 pixel_coords = ivec2(grid_coord) % granularity;

    // Lookup the threshold from the Bayer matrix
    float threshold = bayer_matrix[pixel_coords.x][pixel_coords.y];

    // Apply dithering: if brightness is above the threshold, set pixel to white; otherwise, keep it dark
    float dithered = brightness > threshold ? 1.0 : 0.0;

	vec4 n[9];
	make_kernel(n, texture0, fragTexCoord);

	vec4 sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
  	vec4 sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));

	float edge_intensity = length(sobel.rgb);
	float edge = step(0.2, edge_intensity);
	vec4 s = texture2D(texture0, fragTexCoord) * edge * .2;

	 // Blend the dithered effect onto the background color
	vec3 bg_color = vec3(texture2D(texture0, fragTexCoord).rgb * 1);
    vec3 final_color = mix(s.rgb, bg_color, dithered).rgb;  // Adjust 0.2 as the "darkness factor"

    // Output the final color with the dithered brightness
    gl_FragColor = vec4(final_color, 1.0);
}


