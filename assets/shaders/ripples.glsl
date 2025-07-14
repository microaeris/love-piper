//  These are passed to the shader from the Lua script.
uniform float time;
uniform float wave_height;
uniform float wave_speed;
uniform float wave_freq;


vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel_coords) { 
  // Displace the `x` coordinate. 
  uv.x +=
    sin((uv.y + time * wave_speed) * wave_freq)
    * cos((uv.y + time * wave_speed) * wave_freq * 0.5)
    * wave_height;

  // Displacement in `y` is half that of `x`.
  // Displacing `x` and `y` equally looks unnatural
  uv.y +=
    sin((uv.x + time * wave_speed) * wave_freq)
    * cos((uv.x + time * wave_speed) * wave_freq * 0.5)
    * wave_height * 0.9;

  vec4 pixel = Texel(texture, uv);
  // apply a blue tint to the reflection
  // pixel.b += 0.5;
  return pixel;
}