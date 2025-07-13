extern number time;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    // Simple horizontal sine wave
    float wave = sin(texCoord.y * 40.0 + time * 3.0) * 0.01;

    // Distort X UV coordinate to create wave
    vec2 uv = vec2(texCoord.x + wave, texCoord.y);

    return Texel(tex, uv) * color;
}