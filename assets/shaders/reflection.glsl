extern number reflection_time;
extern Image displacement;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    vec2 uv = screenCoord / resolution;

    // Sample displacement texture
    vec4 disp = Texel(displacement, vec2(uv.x, uv.y +  reflection_time * 0.5));

    // Offset y-coordinate by displacement (red channel)
    float strength = 0.7;
    uv.y += (disp.r - 0.5) * strength;

    return Texel(tex, uv);
}