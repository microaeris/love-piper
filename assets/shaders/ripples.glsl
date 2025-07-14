

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel_coords) {
  float t = time * wave_speed;

  // Ripple in X (add phase offset to cosine)
  uv.x +=
    sin((uv.y + t) * wave_freq)
    
cos((uv.y + t * 0.6) * wave_freq * 0.5 + uv.y * 2.0)
wave_height;

  // Ripple in Y (use slightly different distortion pattern)
  uv.y +=
    sin((uv.x + t * 1.2) * wave_freq * 0.9 + uv.y * 1.5)
    
cos((uv.x + t) * wave_freq * 0.7)
wave_height * 0.9;

  vec4 pixel = Texel(texture, uv);
  return pixel;
}