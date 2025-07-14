//  These are passed to the shader from the Lua script.
uniform float time;
uniform float wave_height;
uniform float wave_speed;
uniform float wave_freq;
extern vec2 iResolution;


// CC0 license https://creativecommons.org/share-your-work/public-domain/cc0/

//////////////////// 3D OpenSimplex2S noise with derivatives  ////////////////////
//////////////////// Output: vec4(dF/dx, dF/dy, dF/dz, value) ////////////////////

// Permutation polynomial hash credit Stefan Gustavson
vec4 permute(vec4 t) {
    return t * (t * 34.0 + 133.0);
}

// Gradient set is a normalized expanded rhombic dodecahedron
vec3 grad(float hash) {

    // Random vertex of a cube, +/- 1 each
    vec3 cube = mod(floor(hash / vec3(1.0, 2.0, 4.0)), 2.0) * 2.0 - 1.0;

    // Random edge of the three edges connected to that vertex
    // Also a cuboctahedral vertex
    // And corresponds to the face of its dual, the rhombic dodecahedron
    vec3 cuboct = cube;
    cuboct[int(hash / 16.0)] = 0.0;

    // In a funky way, pick one of the four points on the rhombic face
    float type = mod(floor(hash / 8.0), 2.0);
    vec3 rhomb = (1.0 - type) * cube + type * (cuboct + cross(cube, cuboct));

    // Expand it so that the new edges are the same length
    // as the existing ones
    vec3 grad = cuboct * 1.22474487139 + rhomb;

    // To make all gradients the same length, we only need to shorten the
    // second type of vector. We also put in the whole noise scale constant.
    // The compiler should reduce it into the existing floats. I think.
    grad *= (1.0 - 0.042942436724648037 * type) * 3.5946317686139184;

    return grad;
}

// BCC lattice split up into 2 cube lattices
vec4 os2NoiseWithDerivativesPart(vec3 X) {
    vec3 b = floor(X);
    vec4 i4 = vec4(X - b, 2.5);

    // Pick between each pair of oppposite corners in the cube.
    vec3 v1 = b + floor(dot(i4, vec4(.25)));
    vec3 v2 = b + vec3(1, 0, 0) + vec3(-1, 1, 1) * floor(dot(i4, vec4(-.25, .25, .25, .35)));
    vec3 v3 = b + vec3(0, 1, 0) + vec3(1, -1, 1) * floor(dot(i4, vec4(.25, -.25, .25, .35)));
    vec3 v4 = b + vec3(0, 0, 1) + vec3(1, 1, -1) * floor(dot(i4, vec4(.25, .25, -.25, .35)));

    // Gradient hashes for the four vertices in this half-lattice.
    vec4 hashes = permute(mod(vec4(v1.x, v2.x, v3.x, v4.x), 289.0));
    hashes = permute(mod(hashes + vec4(v1.y, v2.y, v3.y, v4.y), 289.0));
    hashes = mod(permute(mod(hashes + vec4(v1.z, v2.z, v3.z, v4.z), 289.0)), 48.0);

    // Gradient extrapolations & kernel function
    vec3 d1 = X - v1; vec3 d2 = X - v2; vec3 d3 = X - v3; vec3 d4 = X - v4;
    vec4 a = max(0.75 - vec4(dot(d1, d1), dot(d2, d2), dot(d3, d3), dot(d4, d4)), 0.0);
    vec4 aa = a * a; vec4 aaaa = aa * aa;
    vec3 g1 = grad(hashes.x); vec3 g2 = grad(hashes.y);
    vec3 g3 = grad(hashes.z); vec3 g4 = grad(hashes.w);
    vec4 extrapolations = vec4(dot(d1, g1), dot(d2, g2), dot(d3, g3), dot(d4, g4));

    // Derivatives of the noise
    vec3 derivative = -8.0 * mat4x3(d1, d2, d3, d4) * (aa * a * extrapolations)
        + mat4x3(g1, g2, g3, g4) * aaaa;

    // Return it all as a vec4
    return vec4(derivative, dot(aaaa, extrapolations));
}

// Rotates domain, but preserve shape. Hides grid better in cardinal slices.
// Good for texturing 3D objects with lots of flat parts along cardinal planes.
vec4 os2NoiseWithDerivatives_Fallback(vec3 X) {
    X = dot(X, vec3(2.0/3.0)) - X;

    vec4 result = os2NoiseWithDerivativesPart(X) + os2NoiseWithDerivativesPart(X + 144.5);

    return vec4(dot(result.xyz, vec3(2.0/3.0)) - result.xyz, result.w);
}

// Gives X and Y a triangular alignment, and lets Z move up the main diagonal.
// Might be good for terrain, or a time varying X/Y plane. Z repeats.
vec4 os2NoiseWithDerivatives_ImproveXY(vec3 X) {

    // Not a skew transform.
    mat3 orthonormalMap = mat3(
        0.788675134594813, -0.211324865405187, -0.577350269189626,
        -0.211324865405187, 0.788675134594813, -0.577350269189626,
        0.577350269189626, 0.577350269189626, 0.577350269189626);

    X = orthonormalMap * X;
    vec4 result = os2NoiseWithDerivativesPart(X) + os2NoiseWithDerivativesPart(X + 144.5);

    return vec4(result.xyz * orthonormalMap, result.w);
}

//////////////////////////////// End noise code ////////////////////////////////

vec3 blendMultiply(vec3 base, vec3 blend) {
	return base*blend;
}

vec3 blendMultiply(vec3 base, vec3 blend, float opacity) {
	return (blendMultiply(base, blend) * opacity + base * (1.0 - opacity));
}


vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    // Normalized pixel coordinates (from 0 to 1 on largest axis)
    vec2 uv = screenCoord / vec2(iResolution.x, iResolution.y) * 4.0;

    // Initial input point
    vec3 X = vec3(uv, mod(time / 2.0, 578.0) * 0.8660254037844386);

    // Evaluate noise once
    vec4 noiseResult = os2NoiseWithDerivatives_ImproveXY(X);

    // Evaluate noise again with the derivative warping the domain
    // Might be able to approximate this by fitting to a curve instead
    noiseResult = os2NoiseWithDerivatives_ImproveXY(X - noiseResult.xyz / 16.0);
    float value = noiseResult.w;
    // Time varying pixel color
    // vec3 col = vec3(.431, .8, 1.0) * (0.5 + 0.5 * value);
    vec3 col = vec3(1.0, 1.0, 1.0) * (value);

    // color = vec4(col, 1.0);
    // return color;

    // return Texel(tex, texCoord);

    // return vec4(Texel(tex, texCoord).xyz, 1.0);

    // vec4 t = Texel(tex, texCoord);
    // vec3 rgb = (t.a > 0.0) ? t.rgb / t.a : t.rgb;
    // return vec4(rgb, 1.0);


    vec4 origin = texture2D(tex, texCoord);
    // return origin;

    // return vec4(Texel(tex, texCoord).xyz, .9);

    // return vec4(origin.rgb, .5);

    // color = vec4(origin.rgb, 1.0);
    // return color;

    // Output to screen
    // color = vec4(blendMultiply(origin.rgb, col, 0.8), 1.0);
    // color = vec4(origin.rgb + col, 1.0);
    // return color;

    // return origin * col;

    vec4 temp = vec4(col, .2);
    // vec3 rgb = (origin.a > 0.0) ? origin.rgb / origin.a : vec3(0.0);
    // return origin * vec4(col.x, col.y, col.z, 1.0);


    uv = texCoord;

    // Displace the `x` coordinate.
    uv.x +=
        sin((uv.y + time * wave_speed) * wave_freq)
        * cos((uv.y + time * wave_speed) * wave_freq * 0.5)
        * wave_height;

    // Displacement in `y` is half that of `x`.
    // Displacing `x` and `y` equally looks unnatural
    uv.y +=
        sin((uv.x + time * wave_speed) * wave_freq)
        * cos((uv.x + time * wave_speed) * wave_freq * 0.9)
        * wave_height * 0.9;

    vec4 pixel = Texel(tex, uv);
    // apply a blue tint to the reflection
    // pixel.b += 0.5;

    if (value > 0.5) {
        return vec4(.55, .89, .62, 1.0) * .99;
    } else {
        return pixel;
    }
}

