shader_type canvas_item;
render_mode unshaded;

// Mask pixels are 1,1,1,1 and unmasked 0,0,0,0
uniform sampler2D mask;
uniform vec4 new_color;

// Places pixels of new color into places of mask with alpha set to 1
void fragment() {
	vec4 original_color = texture(TEXTURE, UV);  // The drawing we have to use on
	vec4 mask_color = texture(mask, UV);  // use its alpha to get portion we can ignore
	vec4 col = original_color;

	// Mix selects original color if there is mask or col if there is none
	COLOR = mix(original_color, new_color, mask_color.a);
}
