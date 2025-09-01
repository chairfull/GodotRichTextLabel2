shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float fade : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = vec4(0.0);
    float amnt = 0.0;

    //for (float x = -3.0; x <= 3.0; x += 1.0) {  // <= instead of >=
        //for (float y = -3.0; y <= 3.0; y += 1.0) {
            //color += texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE * vec2(x, y) * 16.0 * (1.0-fade));
            //amnt += 1.0;
        //}
    //}
	
    //COLOR = color / amnt;
	COLOR.rgb = textureLod(SCREEN_TEXTURE, SCREEN_UV, fade * 8.0).rgb * 2.0;
	COLOR.a *= 1.0 - fade;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
