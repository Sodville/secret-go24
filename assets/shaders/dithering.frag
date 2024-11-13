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
uniform float mouse_x;
uniform float mouse_y;
// default light radius
uniform float radius = 80;
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

	 // Blend the dithered effect onto the background color
	vec3 bg_color = texture2D(texture0, fragTexCoord).rgb;
    vec3 final_color = mix(vec3(0.216, 0.165, 0.224) * 1, bg_color, dithered).rgb;

    // Output the final color with the dithered brightness
    gl_FragColor = vec4(final_color, 1.0);
}

