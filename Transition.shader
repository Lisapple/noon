shader_type canvas_item;

uniform sampler2D tex;
uniform sampler2D map;

void fragment() {
	float blur = abs(sin(TIME * 0.8));
	//COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	float dist = textureLod(map, UV, 0.6).r;
	float a = 0.3 + blur * 0.5, b = min(a * 1.4, 1.0);
	float factor = smoothstep(b, a, dist);
	COLOR = mix(texture(tex, UV), vec4(factor * (1.0 - blur)), pow(blur, 0.05));
	COLOR.a = 1.0;
}