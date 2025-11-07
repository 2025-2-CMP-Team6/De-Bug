// res://effects/hit_flash.gdshader
shader_type canvas_item;

uniform float flash_mix: hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// 실루엣 
	vec4 silhouette_color = vec4(flash_color.rgb, tex_color.a);

	// flash_mix가 0이면 tex_color, 1이면 silhouette_color.
	vec4 final_color = mix(tex_color, silhouette_color, flash_mix);
	
	COLOR = final_color;
}