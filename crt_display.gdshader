shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

group_uniforms CRT_Settings;
uniform float warp_amount : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_count : hint_range(10.0, 1080.0) = 320.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.35;
uniform float flicker_speed : hint_range(0.0, 20.0) = 1.5;
uniform float flicker_opacity : hint_range(0.0, 0.1) = 0.015;

group_uniforms TV_Bezel_and_Vignette;

uniform float corner_sharpness : hint_range(1.0, 100.0) = 40.0;

uniform float border_thickness : hint_range(0.0, 0.2) = 0.02;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.7;

group_uniforms; 

// Math function to curve the screen coordinate grid like glass bubbles
vec2 warp_coordinates(vec2 uv) {
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta, delta);
	float delta4 = delta2 * delta2;
	float distortion = 1.0 + (delta2 * warp_amount) + (delta4 * warp_amount * 0.5);
	return (delta * distortion) + 0.5;
}

void fragment() {
	// 1. Apply Lens Curvature Warp
	vec2 warped_uv = warp_coordinates(SCREEN_UV);
	
	// Calculate a smooth mask for the rounded corners (creates the TV bezel shape)
	// Pow functions create a rounded bounding box math shape
	vec2 border_test = abs(warped_uv - 0.5) * 2.0;
	border_test = pow(border_test, vec2(corner_sharpness));
	float mask = clamp(1.0 - (border_test.x + border_test.y), 0.0, 1.0);
	
	// Create an inner shadow (Vignette) that darkens near the edges
	float vignette = warped_uv.x * warped_uv.y * (1.0 - warped_uv.x) * (1.0 - warped_uv.y);
	vignette = clamp(pow(16.0 * vignette, vignette_intensity), 0.0, 1.0);

	// Hard cutoff check: If coordinates warp completely out of bounds or step past the border frame
	if (warped_uv.x < border_thickness || warped_uv.x > (1.0 - border_thickness) || 
	    warped_uv.y < border_thickness || warped_uv.y > (1.0 - border_thickness) || 
	    mask < 0.5) {
		
		COLOR = vec4(0.01, 0.01, 0.01, 1.0); // Renders matte off-black plastic frame
		
	} else {
		// Sample the game's actual screen texture using our curved UV coordinates
		vec4 text_color = texture(SCREEN_TEXTURE, warped_uv);
		
		// 2. Add Horizontal Scanlines
		float scanline = sin(warped_uv.y * scanline_count * PI * 2.0);
		scanline = mix(1.0, (scanline + 1.0) * 0.5, scanline_opacity);
		text_color.rgb *= scanline;
		
		// 3. Add Subtle Scrolling Screen Flicker
		float flicker = sin((warped_uv.y * 2.0) + (TIME * flicker_speed));
		text_color.rgb += flicker * flicker_opacity;
		
		// 4. Apply the inner vignette shadow
		text_color.rgb *= vignette;
		
		// Output the final retro-modified color
		COLOR = text_color;
	}
}
