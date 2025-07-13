

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    // Base scene color
    vec4 sceneColor = Texel(tex, texCoord);

    // Distance from center
    float dist = distance(texCoord, vec2(0.5));
    float t = smoothstep(0.4, 0.8, dist);

    vec3 centerColor = vec3(0.0, 1.0, 0.0); // green
    vec3 edgeColor   = vec3(0.0, .3, .7); // cyan
    vec3 filterColor = mix(centerColor, edgeColor, t);

    float vignetteStrength = 0.1; // adjust this for intensity
    vec3 finalColor = mix(sceneColor.rgb, filterColor, vignetteStrength);

    return vec4(finalColor, sceneColor.a);
}