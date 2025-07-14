extern number time;
extern number delta_time;
extern number curvature = .2;
extern number scanlines = 0.05;
extern number vignette = 0.1;
extern vec2 iResolution;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord) {
  // Normalize coordinates
  vec2 uv = texCoord;

  // Apply barrel distortion (CRT curvature)
  vec2 offset = uv - 0.5;
  float offsetDot = dot(offset, offset);
  uv = uv + offset * (offsetDot * curvature);

  // Discard pixels outside the curved screen
  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }

  // Get the color from the distorted position
  vec4 col = Texel(tex, uv);

  // Add scanlines
  float scanline = sin(uv.y * 200.0) * 0.5 + 0.5;
  scanline = scanline * scanlines + (1.0 - scanlines);
  col.rgb *= scanline;

  // Add vignette effect
  float vignetteEffect = 1.0 - dot(offset, offset) * vignette;
  col.rgb *= vignetteEffect;

  // Add subtle flicker
  float flicker = sin(time * 10.0) * 0.02 + 0.98;
  col.rgb *= flicker;

  return col * color;
}