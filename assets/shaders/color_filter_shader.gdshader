shader_type canvas_item;

uniform vec4 filter_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Get the color of whatever is behind this pixel
    vec4 original = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);

    // Apply the filter
    vec3 filtered = original.rgb * filter_color.rgb;

    // Output the filtered color
    COLOR = vec4(filtered, filter_color.a);
}