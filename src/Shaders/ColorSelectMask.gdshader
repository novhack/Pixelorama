shader_type canvas_item;
render_mode unshaded;

uniform vec4 color;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	float diff = distance(original_color, color);
	// This value seems to be a good boundary to be able to match a color but not match any very similar color
	if (diff <= 0.003)
		COLOR = vec4(1.0);
	else
		COLOR = vec4(0.0);
}
