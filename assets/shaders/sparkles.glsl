uniform float love_time;
uniform vec2 screenSize;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 sparkleColor(vec2 p) {
    return vec3(1.0); // white sparkle color
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
{
    float sparkleDensity = 100.0;
    float sparkleThreshold = 0.9965;

    vec2 normCoords = screen_coords / screenSize;

    float rnd = hash(floor(normCoords * sparkleDensity));
    float sparklePresence = step(sparkleThreshold, rnd);

    float flicker = 0.5 + 0.5 * sin(screen_coords.x * 20.0 + love_time * 15.0);
    sparklePresence = flicker;

    vec3 sparkleCol = sparkleColor(normCoords sparkleDensity);

    vec3 col = sparklePresence * sparkleCol;

    col = min(col, vec3(1.0));

    return vec4(col, 0.5);
}