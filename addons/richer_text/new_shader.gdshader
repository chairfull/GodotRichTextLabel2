shader_type canvas_item;

 uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR.rgb = textureLod(SCREEN_TEXTURE, SCREEN_UV, 1.0).rgb * 2.0;
	COLOR.rgb = textureLod(SCREEN_TEXTURE, SCREEN_UV, 1.0).rgb * 2.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
