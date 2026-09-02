
// Compatibility - Bitwise operators support
#extension GL_EXT_gpu_shader4 : enable



const float PI = 3.1415926535897932;

// Color conversion
#define RGB_to_YIQ mat3( 0.299, 0.595716,  0.211456, 0.587, -0.274453, -0.522591, 0.114, -0.321263, 0.311135 )
#define YIQ_to_RGB mat3( 1.0, 1.0, 1.0, 0.9563, -0.2721, -1.1070, 0.6210, -0.6474, 1.7046 )
#define RGB_to_YUV mat3( 0.299, -0.14713, 0.615, 0.587, -0.28886, -0.514991, 0.114, 0.436, -0.10001 )
#define YUV_to_RGB mat3( 1.0, 1.0, 1.0, 0.0, -0.39465, 2.03211, 1.13983, -0.58060, 0.0 )



uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1; // Clouds
uniform sampler2D u_Tex2; // Fog
uniform sampler2D u_Tex3; // Snow
varying vec2 v_TexCoord;

uniform float u_Time;
uniform vec2 u_Resolution;
uniform vec2 u_WalkOffset;
uniform vec2 u_MapFramebufferResolution;
uniform vec2 u_MapOutputResolution;

uniform int u_DrawCoordFilterShadersFlags;
uniform int u_DrawCoordEffectShadersFlags;
uniform int u_DrawEffectShadersFlags;

// DrawCoordFilterShaderFlags_t
const int DRAWCOORDFILTERSHADER_XBR4X       = 1 << 0;
const int DRAWCOORDFILTERSHADER_2XSAILEVEL2 = 1 << 1;
const int DRAWCOORDFILTERSHADER_2XSAI       = 1 << 2;
const int DRAWCOORDFILTERSHADER_PAINTING    = 1 << 3;


// DrawCoordEffectShaderFlags_t
const int DRAWCOORDEFFECTSHADER_HEAT  = 1 << 0;
const int DRAWCOORDEFFECTSHADER_NOISE = 1 << 1;
const int DRAWCOORDEFFECTSHADER_PAL   = 1 << 2;
const int DRAWCOORDEFFECTSHADER_PULSE = 1 << 3;
const int DRAWCOORDEFFECTSHADER_WATER = 1 << 4;
const int DRAWCOORDEFFECTSHADER_ZOMG  = 1 << 5;

// DrawEffectShaderFlags_t
const int DRAWEFFECTSHADER_GRAYSCALE  = 1 << 0;
const int DRAWEFFECTSHADER_NEGATIVE   = 1 << 1;
const int DRAWEFFECTSHADER_SEPIA      = 1 << 2;
const int DRAWEFFECTSHADER_PARTY      = 1 << 3;
const int DRAWEFFECTSHADER_BLOOM      = 1 << 4;
const int DRAWEFFECTSHADER_CLOUDS     = 1 << 5;
const int DRAWEFFECTSHADER_FOG        = 1 << 6;
const int DRAWEFFECTSHADER_OLDTV      = 1 << 7;
const int DRAWEFFECTSHADER_RADIALBLUR = 1 << 8;
const int DRAWEFFECTSHADER_SNOW       = 1 << 9;

// Precision as COMPAT_PRECISION
#ifdef GL_ES
  #ifdef GL_FRAGMENT_PRECISION_HIGH
    precision highp float;
  #else
    precision mediump float;
  #endif
  #define COMPAT_PRECISION mediump
#else
  #define COMPAT_PRECISION
#endif

vec2 getMapFramebufferResolution()
{
  if (u_MapFramebufferResolution.x > 0.0 && u_MapFramebufferResolution.y > 0.0)
    return u_MapFramebufferResolution;
  return max(u_Resolution, vec2(1.0, 1.0));
}

vec2 getMapOutputResolution()
{
  if (u_MapOutputResolution.x > 0.0 && u_MapOutputResolution.y > 0.0)
    return u_MapOutputResolution;
  return max(u_Resolution, vec2(1.0, 1.0));
}



/* XBR4x */

// Based on libretro xBR-lv2 single-pass:
// https://github.com/libretro/glsl-shaders/blob/master/xbr/shaders/xbr-lv2.glsl

const vec3 XBR4X_RGBW = vec3(14.352, 28.176, 5.472);
const vec4 XBR4X_EQ_THRESHOLD = vec4(15.0, 15.0, 15.0, 15.0);
const float XBR4X_LV2_COEFFICIENT = 2.0;
const float XBR4X_FILTER_SCALE = 3.0;

vec4 xbr4x_df(vec4 a, vec4 b)
{
  return abs(a - b);
}

vec4 xbr4x_diff(vec4 a, vec4 b)
{
  return step(vec4(0.00001, 0.00001, 0.00001, 0.00001), abs(a - b));
}

vec4 xbr4x_eq(vec4 a, vec4 b)
{
  return step(abs(a - b), XBR4X_EQ_THRESHOLD);
}

vec4 xbr4x_neq(vec4 a, vec4 b)
{
  return vec4(1.0, 1.0, 1.0, 1.0) - xbr4x_eq(a, b);
}

vec4 xbr4x_wd(vec4 a, vec4 b, vec4 c, vec4 d, vec4 e, vec4 f, vec4 g, vec4 h)
{
  return xbr4x_df(a, b) + xbr4x_df(a, c) + xbr4x_df(d, e) + xbr4x_df(d, f) + 4.0 * xbr4x_df(g, h);
}

float xbr4x_cdf(vec3 c1, vec3 c2)
{
  vec3 d = abs(c1 - c2);
  return d.r + d.g + d.b;
}

vec4 getXBR4xColor()
{
  vec2 sourceSize = max(getMapFramebufferResolution(), vec2(1.0, 1.0));
  vec2 invSourceSize = 1.0 / sourceSize;

  float dx = invSourceSize.x;
  float dy = invSourceSize.y;
  vec2 tex = v_TexCoord;

  vec3 A1 = texture2D(u_Tex0, tex + vec2(-dx, -2.0 * dy)).xyz;
  vec3 B1 = texture2D(u_Tex0, tex + vec2(0.0, -2.0 * dy)).xyz;
  vec3 C1 = texture2D(u_Tex0, tex + vec2(dx, -2.0 * dy)).xyz;
  vec3 A = texture2D(u_Tex0, tex + vec2(-dx, -dy)).xyz;
  vec3 B = texture2D(u_Tex0, tex + vec2(0.0, -dy)).xyz;
  vec3 C = texture2D(u_Tex0, tex + vec2(dx, -dy)).xyz;
  vec3 D = texture2D(u_Tex0, tex + vec2(-dx, 0.0)).xyz;
  vec3 E = texture2D(u_Tex0, tex).xyz;
  vec3 F = texture2D(u_Tex0, tex + vec2(dx, 0.0)).xyz;
  vec3 G = texture2D(u_Tex0, tex + vec2(-dx, dy)).xyz;
  vec3 H = texture2D(u_Tex0, tex + vec2(0.0, dy)).xyz;
  vec3 I = texture2D(u_Tex0, tex + vec2(dx, dy)).xyz;
  vec3 G5 = texture2D(u_Tex0, tex + vec2(-dx, 2.0 * dy)).xyz;
  vec3 H5 = texture2D(u_Tex0, tex + vec2(0.0, 2.0 * dy)).xyz;
  vec3 I5 = texture2D(u_Tex0, tex + vec2(dx, 2.0 * dy)).xyz;
  vec3 A0 = texture2D(u_Tex0, tex + vec2(-2.0 * dx, -dy)).xyz;
  vec3 D0 = texture2D(u_Tex0, tex + vec2(-2.0 * dx, 0.0)).xyz;
  vec3 G0 = texture2D(u_Tex0, tex + vec2(-2.0 * dx, dy)).xyz;
  vec3 C4 = texture2D(u_Tex0, tex + vec2(2.0 * dx, -dy)).xyz;
  vec3 F4 = texture2D(u_Tex0, tex + vec2(2.0 * dx, 0.0)).xyz;
  vec3 I4 = texture2D(u_Tex0, tex + vec2(2.0 * dx, dy)).xyz;

  vec4 b = vec4(dot(B, XBR4X_RGBW), dot(D, XBR4X_RGBW), dot(H, XBR4X_RGBW), dot(F, XBR4X_RGBW));
  vec4 c = vec4(dot(C, XBR4X_RGBW), dot(A, XBR4X_RGBW), dot(G, XBR4X_RGBW), dot(I, XBR4X_RGBW));
  vec4 d = b.yzwx;
  vec4 e = vec4(dot(E, XBR4X_RGBW));
  vec4 f = b.wxyz;
  vec4 g = c.zwxy;
  vec4 h = b.zwxy;
  vec4 i = c.wxyz;
  vec4 i4 = vec4(dot(I4, XBR4X_RGBW), dot(C1, XBR4X_RGBW), dot(A0, XBR4X_RGBW), dot(G5, XBR4X_RGBW));
  vec4 i5 = vec4(dot(I5, XBR4X_RGBW), dot(C4, XBR4X_RGBW), dot(A1, XBR4X_RGBW), dot(G0, XBR4X_RGBW));
  vec4 h5 = vec4(dot(H5, XBR4X_RGBW), dot(F4, XBR4X_RGBW), dot(B1, XBR4X_RGBW), dot(D0, XBR4X_RGBW));
  vec4 f4 = h5.yzwx;

  vec2 fp = fract(tex * sourceSize);

  vec4 delta = vec4(1.0 / XBR4X_FILTER_SCALE);
  vec4 delta_l = vec4(0.5 / XBR4X_FILTER_SCALE, 1.0 / XBR4X_FILTER_SCALE, 0.5 / XBR4X_FILTER_SCALE, 1.0 / XBR4X_FILTER_SCALE);
  vec4 delta_u = delta_l.yxwz;

  const vec4 Ao = vec4(1.0, -1.0, -1.0, 1.0);
  const vec4 Bo = vec4(1.0, 1.0, -1.0, -1.0);
  const vec4 Co = vec4(1.5, 0.5, -0.5, 0.5);
  const vec4 Ax = vec4(1.0, -1.0, -1.0, 1.0);
  const vec4 Bx = vec4(0.5, 2.0, -0.5, -2.0);
  const vec4 Cx = vec4(1.0, 1.0, -0.5, 0.0);
  const vec4 Ay = vec4(1.0, -1.0, -1.0, 1.0);
  const vec4 By = vec4(2.0, 0.5, -2.0, -0.5);
  const vec4 Cy = vec4(2.0, 0.0, -1.0, 0.5);
  const vec4 Ci = vec4(0.25, 0.25, 0.25, 0.25);

  vec4 fx = Ao * fp.y + Bo * fp.x;
  vec4 fx_l = Ax * fp.y + Bx * fp.x;
  vec4 fx_u = Ay * fp.y + By * fp.x;

  vec4 irlv0 = xbr4x_diff(e, f) * xbr4x_diff(e, h);
  vec4 irlv1 = irlv0 * (
    xbr4x_neq(f, b) * xbr4x_neq(f, c) +
    xbr4x_neq(h, d) * xbr4x_neq(h, g) +
    xbr4x_eq(e, i) * (xbr4x_neq(f, f4) * xbr4x_neq(f, i4) + xbr4x_neq(h, h5) * xbr4x_neq(h, i5)) +
    xbr4x_eq(e, g) + xbr4x_eq(e, c)
  );
  vec4 irlv2l = xbr4x_diff(e, g) * xbr4x_diff(d, g);
  vec4 irlv2u = xbr4x_diff(e, c) * xbr4x_diff(b, c);

  vec4 fx45i = clamp((fx + delta - Co - Ci) / (2.0 * delta), 0.0, 1.0);
  vec4 fx45 = clamp((fx + delta - Co) / (2.0 * delta), 0.0, 1.0);
  vec4 fx30 = clamp((fx_l + delta_l - Cx) / (2.0 * delta_l), 0.0, 1.0);
  vec4 fx60 = clamp((fx_u + delta_u - Cy) / (2.0 * delta_u), 0.0, 1.0);

  vec4 wd1 = xbr4x_wd(e, c, g, i, h5, f4, h, f);
  vec4 wd2 = xbr4x_wd(h, d, i5, f, i4, b, e, i);

  vec4 edri = step(wd1, wd2) * irlv0;
  vec4 edr = step(wd1 + vec4(0.1, 0.1, 0.1, 0.1), wd2) * step(vec4(0.5, 0.5, 0.5, 0.5), irlv1);
  vec4 edr_l = step(XBR4X_LV2_COEFFICIENT * xbr4x_df(f, g), xbr4x_df(h, c)) * irlv2l * edr;
  vec4 edr_u = step(XBR4X_LV2_COEFFICIENT * xbr4x_df(h, c), xbr4x_df(f, g)) * irlv2u * edr;

  fx45 = edr * fx45;
  fx30 = edr_l * fx30;
  fx60 = edr_u * fx60;
  fx45i = edri * fx45i;

  vec4 px = step(xbr4x_df(e, f), xbr4x_df(e, h));
  vec4 maximos = max(max(fx30, fx60), max(fx45, fx45i));

  vec3 res1 = E;
  res1 = mix(res1, mix(H, F, px.x), maximos.x);
  res1 = mix(res1, mix(B, D, px.z), maximos.z);

  vec3 res2 = E;
  res2 = mix(res2, mix(F, B, px.y), maximos.y);
  res2 = mix(res2, mix(D, H, px.w), maximos.w);

  vec3 res = mix(res1, res2, step(xbr4x_cdf(E, res1), xbr4x_cdf(E, res2)));
  return vec4(res, 1.0);
}



/* 2xSaI - Level 2 */

// https://github.com/libretro/glsl-shaders/blob/master/xsal/shaders/2xsal-level2-pass2.glsl

float _2xSaILevel2_intensity = 1.0;

float get2xSaIFilterStrength()
{
  vec2 source = getMapFramebufferResolution();
  vec2 output = getMapOutputResolution();
  // Keep full filter when upscaling, and reduce it when downscaling to avoid excess blur.
  return clamp(min(output.x / source.x, output.y / source.y), 0.35, 1.0);
}

vec4 get2xSaILevel2Color()
{
  vec2 tex = v_TexCoord;
  vec2 sourceSize = max(getMapFramebufferResolution() * _2xSaILevel2_intensity, vec2(1.0, 1.0));
  vec2 invSourceSize = 1.0 / sourceSize;
  float dx = 0.25 * invSourceSize.x;
  float dy = 0.25 * invSourceSize.y;
  vec3  dt = vec3(1.0, 1.0, 1.0);

  vec4 yx = vec4(dx, dy, -dx, -dy);
  vec4 xh = yx*vec4(3.0, 1.0, 3.0, 1.0);
  vec4 yv = yx*vec4(1.0, 3.0, 1.0, 3.0);

  vec3 c11 = texture2D(u_Tex0, tex        ).xyz;
  vec3 s00 = texture2D(u_Tex0, tex + yx.zw).xyz;
  vec3 s20 = texture2D(u_Tex0, tex + yx.xw).xyz;
  vec3 s22 = texture2D(u_Tex0, tex + yx.xy).xyz;
  vec3 s02 = texture2D(u_Tex0, tex + yx.zy).xyz;
  vec3 h00 = texture2D(u_Tex0, tex + xh.zw).xyz;
  vec3 h20 = texture2D(u_Tex0, tex + xh.xw).xyz;
  vec3 h22 = texture2D(u_Tex0, tex + xh.xy).xyz;
  vec3 h02 = texture2D(u_Tex0, tex + xh.zy).xyz;
  vec3 v00 = texture2D(u_Tex0, tex + yv.zw).xyz;
  vec3 v20 = texture2D(u_Tex0, tex + yv.xw).xyz;
  vec3 v22 = texture2D(u_Tex0, tex + yv.xy).xyz;
  vec3 v02 = texture2D(u_Tex0, tex + yv.zy).xyz;

  float m1 = 1.0/(dot(abs(s00 - s22), dt) + 0.00001);
  float m2 = 1.0/(dot(abs(s02 - s20), dt) + 0.00001);
  float h1 = 1.0/(dot(abs(s00 - h22), dt) + 0.00001);
  float h2 = 1.0/(dot(abs(s02 - h20), dt) + 0.00001);
  float h3 = 1.0/(dot(abs(h00 - s22), dt) + 0.00001);
  float h4 = 1.0/(dot(abs(h02 - s20), dt) + 0.00001);
  float v1 = 1.0/(dot(abs(s00 - v22), dt) + 0.00001);
  float v2 = 1.0/(dot(abs(s02 - v20), dt) + 0.00001);
  float v3 = 1.0/(dot(abs(v00 - s22), dt) + 0.00001);
  float v4 = 1.0/(dot(abs(v02 - s20), dt) + 0.00001);

  vec3 t1 = 0.5*(m1*(s00 + s22) + m2*(s02 + s20))/(m1 + m2);
  vec3 t2 = 0.5*(h1*(s00 + h22) + h2*(s02 + h20) + h3*(h00 + s22) + h4*(h02 + s20))/(h1 + h2 + h3 + h4);
  vec3 t3 = 0.5*(v1*(s00 + v22) + v2*(s02 + v20) + v3*(v00 + s22) + v4*(v02 + s20))/(v1 + v2 + v3 + v4);

  float k1 = 1.0/(dot(abs(t1 - c11), dt) + 0.00001);
  float k2 = 1.0/(dot(abs(t2 - c11), dt) + 0.00001);
  float k3 = 1.0/(dot(abs(t3 - c11), dt) + 0.00001);

  vec3 filtered = (k1*t1 + k2*t2 + k3*t3)/(k1 + k2 + k3);
  return vec4(mix(c11, filtered, get2xSaIFilterStrength()), 1.0);
}



/* 2xSaI */

// https://github.com/libretro/glsl-shaders/blob/master/xsal/shaders/2xsal.glsl

float _2xSaI_intensity = 1.0;

vec4 get2xSaIColor()
{
  vec2 texsize = max(getMapFramebufferResolution() * _2xSaI_intensity, vec2(1.0, 1.0));
  float dx     = (1.0 / texsize.x) * 0.25;
  float dy     = (1.0 / texsize.y) * 0.25;
  vec3  dt     = vec3(1.0, 1.0, 1.0);

  vec2 UL = v_TexCoord + vec2(-dx, -dy);
  vec2 UR = v_TexCoord + vec2( dx, -dy);
  vec2 DL = v_TexCoord + vec2(-dx,  dy);
  vec2 DR = v_TexCoord + vec2( dx,  dy);

  vec3 c00 = texture2D(u_Tex0, UL).xyz;
  vec3 c20 = texture2D(u_Tex0, UR).xyz;
  vec3 c02 = texture2D(u_Tex0, DL).xyz;
  vec3 c22 = texture2D(u_Tex0, DR).xyz;

  float m1 = dot(abs(c00 - c22), dt) + 0.001;
  float m2 = dot(abs(c02 - c20), dt) + 0.001;

  vec3 filtered = (m1*(c02 + c20) + m2*(c22 + c00))/(2.0*(m1 + m2));
  vec3 base = texture2D(u_Tex0, v_TexCoord).xyz;
  return vec4(mix(base, filtered, get2xSaIFilterStrength()), 1.0);
}



/* Anti-Aliasing Retro */ // No fragment



/* Anti-Aliasing */ // No fragment



/* No Anti-Aliasing */ // No fragment



/* Bloom */

vec4 getBloomColor(vec4 startColor)
{
  vec2 texOffset = vec2(0.003);
  float kernel[9];
  vec2 offsets[9];

  // Gaussian kernel weights
  kernel[0] = 0.08; offsets[0] = vec2( 0.0,  0.0);
  kernel[1] = 0.08; offsets[1] = vec2(-1.0, -1.0);
  kernel[2] = 0.08; offsets[2] = vec2(-1.0,  1.0);
  kernel[3] = 0.08; offsets[3] = vec2( 1.0, -1.0);
  kernel[4] = 0.08; offsets[4] = vec2( 1.0,  1.0);
  kernel[5] = 0.08; offsets[5] = vec2(-1.0,  0.0);
  kernel[6] = 0.08; offsets[6] = vec2( 1.0,  0.0);
  kernel[7] = 0.08; offsets[7] = vec2( 0.0, -1.0);
  kernel[8] = 0.08; offsets[8] = vec2( 0.0,  1.0);

  for (int i = 0; i < 9; i++)
    startColor += texture2D(u_Tex0, v_TexCoord + offsets[i] * texOffset) * kernel[i];

  return startColor;
}



/* Clouds */

float clouds_speed = 0.01;
float clouds_time_scale = 0.05; // Multiplies cyclic clouds time to reduce peak movement speed
float clouds_cycle_time = 18000.0; // Seconds for a full 360-degree direction rotation
float clouds_inverse_direction_time = 3600.0; // Seconds for smooth direction inversion cycle
float clouds_zoom = 1.5;
float clouds_alpha = 1.0; // 0.0 = invisible, 1.0 = full clouds effect
float clouds_shadow_strength = 0.85; // 0.0 = no shading, 1.0 = maximum shadow contribution
vec3 clouds_shadow_tint = vec3(0.40, 0.45, 0.55); // Shadow color tint
float clouds_eps = 0.0001;

vec2 getCloudsDynamicDirection()
{
  float cycleTime = max(clouds_cycle_time, clouds_eps);
  float inverseTime = max(clouds_inverse_direction_time, clouds_eps);

  float theta = 2.0 * PI * fract(u_Time / cycleTime);
  vec2 dir = vec2(sin(theta), -cos(theta));

  float inverseFactor = sin(2.0 * PI * u_Time / inverseTime);
  return dir * inverseFactor;
}

vec4 getCloudsColor(vec4 startColor)
{
  vec3 bgcol = startColor.xyz;
  vec2 clouds_direction = getCloudsDynamicDirection();
  float inverseTime = max(clouds_inverse_direction_time, clouds_eps);
  // Cyclic time without hard reset: 0 -> peak -> 0 in each inverse cycle
  float phase = 2.0 * PI * u_Time / inverseTime;
  float clouds_time = (0.5 * inverseTime * (1.0 - cos(phase))) * clouds_time_scale;
  vec2 cloudsHandler = (v_TexCoord + vec2(u_WalkOffset.x, u_WalkOffset.y) + (clouds_direction * clouds_time * clouds_speed)) / clouds_zoom;

  vec3 cloudsSample = texture2D(u_Tex1, cloudsHandler).xyz;
  float cloudMaskRaw = clamp((cloudsSample.r + cloudsSample.g + cloudsSample.b) / 3.0, 0.0, 1.0);
  float cloudMask = smoothstep(0.05, 0.65, cloudMaskRaw);

  float shadowStrength = clamp(clouds_shadow_strength, 0.0, 1.0);
  float alpha = clamp(clouds_alpha, 0.0, 1.0);
  float shadowAmount = cloudMask * shadowStrength * alpha;
  vec3 shadowedBg = bgcol * clouds_shadow_tint;
  vec3 col = mix(bgcol, shadowedBg, shadowAmount);
  return vec4(col, 1.0);
}



/* Fog */

vec2 fog_direction = vec2(1.1, 1.0);
float fog_speed = 0.03;
float fog_pressure = 0.6; // Positive gives a light effect; Negative gives a darken effect

vec4 getFogColor(vec4 startColor)
{
  vec3 bgcol = startColor.xyz;

  vec2 fogHandler = v_TexCoord + vec2(u_WalkOffset.x, u_WalkOffset.y) + (fog_direction * u_Time * fog_speed);
  vec3 fogcol = texture2D(u_Tex2, fogHandler).xyz;

  vec3 col = bgcol + fogcol * fog_pressure;
  return vec4(col, 1.0);
}



/* Grayscale */

vec4 getGrayscaleColor(vec4 startColor)
{
  float gray = dot(startColor.rgb, vec3(0.299, 0.587, 0.114));
  return vec4(gray, gray, gray, 1);
}



/* Heat */

// speed
const float heat_speed = 0.06;
const float heat_speed_x = 0.03;
const float heat_speed_y = 0.02;

// geometry
const float heat_intensity = 30.;
const int heat_steps = 5;
const float heat_frequency = 3.0;
const int heat_angle = 7; // better when a prime

// reflection and emboss
const float heat_delta = 100.;
const float heat_intence = 1.2;
const float heat_emboss = 0.1;

// crystals effect
float heat_col(vec2 coord)
{
  float delta_theta = 2.0 * PI / float(heat_angle);
  float col = 0.0;
  float theta = 0.0;
  for (int i = 0; i < heat_steps; i++) {
    vec2 adjc = coord;
    theta = delta_theta * float(i);
    adjc.x += cos(theta) * u_Time * heat_speed + u_Time * heat_speed_x;
    adjc.y -= sin(theta) * u_Time * heat_speed - u_Time * heat_speed_y;
    col = col + cos((adjc.x * cos(theta) - adjc.y * sin(theta)) * heat_frequency) * heat_intensity;
  }
  return cos(col);
}

vec4 getHeatColor()
{
  vec2 p = v_TexCoord, c1 = p, c2 = p;
  float cc1 = heat_col(c1);

  c2.x += u_Resolution.x / heat_delta;
  float dx = heat_emboss * (cc1 - heat_col(c2)) / heat_delta;

  c2.x = p.x;
  c2.y += u_Resolution.y / heat_delta;
  float dy = heat_emboss * (cc1 - heat_col(c2)) / heat_delta;

  c1.x += dx;
  c1.y += dy;

  float alpha = 1. + dot(dx, dy) * heat_intence;

  return texture2D(u_Tex0, c1) * (alpha);
}



/* Negative */

vec4 getNegativeColor(vec4 startColor)
{
  return vec4(1.0 - startColor.rgb, startColor.a); // negative only rgb
}



/* Noise */

// speed
const float noise_speed = 0.16;
const float noise_speed_x = 0.13;
const float noise_speed_y = 0.12;

// geometry
const float noise_intensity = 100.;
const int noise_steps = 3;
const float noise_frequency = 100.0;
const int noise_angle = 7; // better when a prime

// reflection and emboss
const float noise_delta = 1000.;
const float noise_intence = 10.2;
const float noise_emboss = 1.;

// crystals effect
float noise_col(vec2 coord)
{
  float delta_theta = 2.0 * PI / float(noise_angle);
  float col = 0.0;
  float theta = 0.0;
  for (int i = 0; i < noise_steps; i++) {
    vec2 adjc = coord;
    theta = delta_theta * float(i);
    adjc.x += cos(theta) * u_Time * noise_speed + u_Time * noise_speed_x;
    adjc.y -= sin(theta) * u_Time * noise_speed - u_Time * noise_speed_y;
    col = col + cos((adjc.x * cos(theta) - adjc.y * sin(theta)) * noise_frequency) * noise_intensity;
  }
  return cos(col);
}

vec4 getNoiseColor()
{
  vec2 p = v_TexCoord, c1 = p, c2 = p;
  float cc1 = noise_col(c1);

  c2.x += u_Resolution.x / noise_delta;
  float dx = noise_emboss * (cc1 - noise_col(c2)) / noise_delta;

  c2.x = p.x;
  c2.y += u_Resolution.y / noise_delta;
  float dy = noise_emboss * (cc1 - noise_col(c2)) / noise_delta;

  c1.x += dx;
  c1.y += dy;

  float alpha = 1. + dot(dx, dy) * noise_intence;
  return texture2D(u_Tex0, c1) * (alpha);
}



/* Old Tv */

vec4 getOldTvColor(vec4 startColor)
{
  vec2 q = v_TexCoord;
  vec2 uv = 0.5 + (q - 0.5) * (0.9 + 0.1 * sin(0.2 * u_Time));

  vec3 oricol = startColor.xyz; // texture2D(u_Tex0, vec2(q.x, q.y)).xyz;
  vec3 col = oricol;

  col = clamp(col * 0.5 + 0.5 * col * col * 1.2, 0.0, 1.0);

  col *= 0.5 + 0.5 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);

  col *= vec3(0.8, 1.0, 0.7);

  col *= 0.9 + 0.1 * sin(10.0 * u_Time + uv.y * 1000.0);

  col *= 0.97 + 0.03 * sin(110.0 * u_Time);

  return vec4(col, 1.0);
}



/* Painting */

#define PAINTING_BLEND_NONE 0
#define PAINTING_BLEND_NORMAL 1
#define PAINTING_BLEND_DOMINANT 2
#define PAINTING_LUMINANCE_WEIGHT 1.0
#define PAINTING_EQUAL_COLOR_TOLERANCE 1.0
#define PAINTING_STEEP_DIRECTION_THRESHOLD 2.2
#define PAINTING_DOMINANT_DIRECTION_THRESHOLD 3.6

#define painting_InputSize max(getMapFramebufferResolution() * 0.5, vec2(1.0, 1.0)) // Width and height in pixels of map framebuffer
#define painting_OutputSize max(getMapOutputResolution() * 0.5, vec2(1.0, 1.0)) // Width and height in pixels of map on screen
#define painting_SourceSize vec4(painting_InputSize, 1.0 / painting_InputSize) //either TextureSize or painting_InputSize

#define painting_P(x,y) texture2D(u_Tex0, coord + painting_SourceSize.zw * vec2(x, y)).rgb

float painting_distYCbCr(vec3 pixA, vec3 pixB)
{
  const vec3 w = vec3(0.2627, 0.6780, 0.0593);
  const float scaleB = 0.5 / (1.0 - w.b);
  const float scaleR = 0.5 / (1.0 - w.r);
  vec3 diff = pixA - pixB;
  float Y = dot(diff.rgb, w);
  float Cb = scaleB * (diff.b - Y);
  float Cr = scaleR * (diff.r - Y);

  return sqrt(((PAINTING_LUMINANCE_WEIGHT * Y) * (PAINTING_LUMINANCE_WEIGHT * Y)) + (Cb * Cb) + (Cr * Cr));
}

bool painting_isPixEqual(const vec3 pixA, const vec3 pixB)
{
  return (painting_distYCbCr(pixA, pixB) < PAINTING_EQUAL_COLOR_TOLERANCE);
}

float painting_getLeftRatio(vec2 center, vec2 origin, vec2 direction, vec2 scale)
{
  vec2 P0 = center - origin;
  vec2 proj = direction * (dot(P0, direction) / dot(direction, direction));
  vec2 distv = P0 - proj;
  vec2 orth = vec2(-direction.y, direction.x);
  float side = sign(dot(P0, orth));
  float v = side * length(distv * scale);

  // return step(0, v);
  return smoothstep(-sqrt(2.0)/2.0, sqrt(2.0)/2.0, v);
}

vec4 getPaintingColor()
{
  //---------------------------------------
  // Input Pixel Mapping:  -|x|x|x|-
  //                       x|A|B|C|x
  //                       x|D|E|F|x
  //                       x|G|H|I|x
  //                       -|x|x|x|-

  vec2 scale = painting_OutputSize.xy * painting_SourceSize.zw;
  vec2 pos = fract(v_TexCoord * painting_SourceSize.xy) - vec2(0.5, 0.5);
  vec2 coord = v_TexCoord - pos * painting_SourceSize.zw;

  vec3 A = painting_P(-1.,-1.);
  vec3 B = painting_P( 0.,-1.);
  vec3 C = painting_P( 1.,-1.);
  vec3 D = painting_P(-1., 0.);
  vec3 E = painting_P( 0., 0.);
  vec3 F = painting_P( 1., 0.);
  vec3 G = painting_P(-1., 1.);
  vec3 H = painting_P( 0., 1.);
  vec3 I = painting_P( 1., 1.);

  // blendResult Mapping: x|y|
  //                      w|z|
  ivec4 blendResult = ivec4(PAINTING_BLEND_NONE,PAINTING_BLEND_NONE,PAINTING_BLEND_NONE,PAINTING_BLEND_NONE);

  // Preprocess corners
  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|-|B|C|-
  //                    -|D|E|F|x
  //                    -|G|H|I|x
  //                    -|-|x|x|-
  if (!((E == F && H == I) || (E == H && F == I))) {
    float dist_H_F = painting_distYCbCr(G, E) + painting_distYCbCr(E, C) + painting_distYCbCr(painting_P(0,2), I) + painting_distYCbCr(I, painting_P(2.,0.)) + (4.0 * painting_distYCbCr(H, F));
    float dist_E_I = painting_distYCbCr(D, H) + painting_distYCbCr(H, painting_P(1,2)) + painting_distYCbCr(B, F) + painting_distYCbCr(F, painting_P(2.,1.)) + (4.0 * painting_distYCbCr(E, I));
    bool dominantGradient = (PAINTING_DOMINANT_DIRECTION_THRESHOLD * dist_H_F) < dist_E_I;
    blendResult.z = ((dist_H_F < dist_E_I) && E != F && E != H) ? ((dominantGradient) ? PAINTING_BLEND_DOMINANT : PAINTING_BLEND_NORMAL) : PAINTING_BLEND_NONE;
  }


  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|A|B|-|-
  //                    x|D|E|F|-
  //                    x|G|H|I|-
  //                    -|x|x|-|-
  if (!((D == E && G == H) || (D == G && E == H))) {
    float dist_G_E = painting_distYCbCr(painting_P(-2.,1.)  , D) + painting_distYCbCr(D, B) + painting_distYCbCr(painting_P(-1.,2.), H) + painting_distYCbCr(H, F) + (4.0 * painting_distYCbCr(G, E));
    float dist_D_H = painting_distYCbCr(painting_P(-2.,0.)  , G) + painting_distYCbCr(G, painting_P(0.,2.)) + painting_distYCbCr(A, E) + painting_distYCbCr(E, I) + (4.0 * painting_distYCbCr(D, H));
    bool dominantGradient = (PAINTING_DOMINANT_DIRECTION_THRESHOLD * dist_D_H) < dist_G_E;
    blendResult.w = ((dist_G_E > dist_D_H) && E != D && E != H) ? ((dominantGradient) ? PAINTING_BLEND_DOMINANT : PAINTING_BLEND_NORMAL) : PAINTING_BLEND_NONE;
  }

  // Pixel Tap Mapping: -|-|x|x|-
  //                    -|A|B|C|x
  //                    -|D|E|F|x
  //                    -|-|H|I|-
  //                    -|-|-|-|-
  if (!((B == C && E == F) || (B == E && C == F))) {
    float dist_E_C = painting_distYCbCr(D, B) + painting_distYCbCr(B, painting_P(1.,-2.)) + painting_distYCbCr(H, F) + painting_distYCbCr(F, painting_P(2.,-1.)) + (4.0 * painting_distYCbCr(E, C));
    float dist_B_F = painting_distYCbCr(A, E) + painting_distYCbCr(E, I) + painting_distYCbCr(painting_P(0.,-2.), C) + painting_distYCbCr(C, painting_P(2.,0.)) + (4.0 * painting_distYCbCr(B, F));
    bool dominantGradient = (PAINTING_DOMINANT_DIRECTION_THRESHOLD * dist_B_F) < dist_E_C;
    blendResult.y = ((dist_E_C > dist_B_F) && E != B && E != F) ? ((dominantGradient) ? PAINTING_BLEND_DOMINANT : PAINTING_BLEND_NORMAL) : PAINTING_BLEND_NONE;
  }

  // Pixel Tap Mapping: -|x|x|-|-
  //                    x|A|B|C|-
  //                    x|D|E|F|-
  //                    -|G|H|-|-
  //                    -|-|-|-|-
  if (!((A == B && D == E) || (A == D && B == E))) {
    float dist_D_B = painting_distYCbCr(painting_P(-2.,0.), A) + painting_distYCbCr(A, painting_P(0.,-2.)) + painting_distYCbCr(G, E) + painting_distYCbCr(E, C) + (4.0 * painting_distYCbCr(D, B));
    float dist_A_E = painting_distYCbCr(painting_P(-2.,-1.), D) + painting_distYCbCr(D, H) + painting_distYCbCr(painting_P(-1.,-2.), B) + painting_distYCbCr(B, F) + (4.0 * painting_distYCbCr(A, E));
    bool dominantGradient = (PAINTING_DOMINANT_DIRECTION_THRESHOLD * dist_D_B) < dist_A_E;
    blendResult.x = ((dist_D_B < dist_A_E) && E != D && E != B) ? ((dominantGradient) ? PAINTING_BLEND_DOMINANT : PAINTING_BLEND_NORMAL) : PAINTING_BLEND_NONE;
  }

  vec3 res = E;

  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|-|B|C|-
  //                    -|D|E|F|x
  //                    -|G|H|I|x
  //                    -|-|x|x|-
  if (blendResult.z != PAINTING_BLEND_NONE) {
    float dist_F_G = painting_distYCbCr(F, G);
    float dist_H_C = painting_distYCbCr(H, C);
    bool doLineBlend = (blendResult.z == PAINTING_BLEND_DOMINANT ||
                        !((blendResult.y != PAINTING_BLEND_NONE && !painting_isPixEqual(E, G)) || (blendResult.w != PAINTING_BLEND_NONE && !painting_isPixEqual(E, C)) ||
                          (painting_isPixEqual(G, H) && painting_isPixEqual(H, I) && painting_isPixEqual(I, F) && painting_isPixEqual(F, C) && !painting_isPixEqual(E, I))));

    vec2 origin = vec2(0.0, 1.0 / sqrt(2.0));
    vec2 direction = vec2(1.0, -1.0);
    if (doLineBlend) {
      bool haveShallowLine = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_F_G <= dist_H_C) && E != G && D != G;
      bool haveSteepLine = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_H_C <= dist_F_G) && E != C && B != C;
      origin = haveShallowLine? vec2(0.0, 0.25) : vec2(0.0, 0.5);
      direction.x += haveShallowLine? 1.0: 0.0;
      direction.y -= haveSteepLine? 1.0: 0.0;
    }

    vec3 blendPix = mix(H,F, step(painting_distYCbCr(E, F), painting_distYCbCr(E, H)));
    res = mix(res, blendPix, painting_getLeftRatio(pos, origin, direction, scale));
  }

  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|A|B|-|-
  //                    x|D|E|F|-
  //                    x|G|H|I|-
  //                    -|x|x|-|-
  if (blendResult.w != PAINTING_BLEND_NONE) {
    float dist_H_A = painting_distYCbCr(H, A);
    float dist_D_I = painting_distYCbCr(D, I);
    bool doLineBlend = (blendResult.w == PAINTING_BLEND_DOMINANT ||
                        !((blendResult.z != PAINTING_BLEND_NONE && !painting_isPixEqual(E, A)) || (blendResult.x != PAINTING_BLEND_NONE && !painting_isPixEqual(E, I)) ||
                          (painting_isPixEqual(A, D) && painting_isPixEqual(D, G) && painting_isPixEqual(G, H) && painting_isPixEqual(H, I) && !painting_isPixEqual(E, G))));

    vec2 origin = vec2(-1.0 / sqrt(2.0), 0.0);
    vec2 direction = vec2(1.0, 1.0);
    if (doLineBlend) {
      bool haveShallowLine = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_H_A <= dist_D_I) && E != A && B != A;
      bool haveSteepLine  = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_D_I <= dist_H_A) && E != I && F != I;
      origin = haveShallowLine? vec2(-0.25, 0.0) : vec2(-0.5, 0.0);
      direction.y += haveShallowLine? 1.0: 0.0;
      direction.x += haveSteepLine? 1.0: 0.0;
    }
    origin = origin;
    direction = direction;

    vec3 blendPix = mix(H,D, step(painting_distYCbCr(E, D), painting_distYCbCr(E, H)));
    res = mix(res, blendPix, painting_getLeftRatio(pos, origin, direction, scale));
  }

  // Pixel Tap Mapping: -|-|x|x|-
  //                    -|A|B|C|x
  //                    -|D|E|F|x
  //                    -|-|H|I|-
  //                    -|-|-|-|-
  if (blendResult.y != PAINTING_BLEND_NONE) {
    float dist_B_I = painting_distYCbCr(B, I);
    float dist_F_A = painting_distYCbCr(F, A);
    bool doLineBlend = (blendResult.y == PAINTING_BLEND_DOMINANT ||
                        !((blendResult.x != PAINTING_BLEND_NONE && !painting_isPixEqual(E, I)) || (blendResult.z != PAINTING_BLEND_NONE && !painting_isPixEqual(E, A)) ||
                          (painting_isPixEqual(I, F) && painting_isPixEqual(F, C) && painting_isPixEqual(C, B) && painting_isPixEqual(B, A) && !painting_isPixEqual(E, C))));

    vec2 origin = vec2(1.0 / sqrt(2.0), 0.0);
    vec2 direction = vec2(-1.0, -1.0);

    if (doLineBlend) {
      bool haveShallowLine = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_B_I <= dist_F_A) && E != I && H != I;
      bool haveSteepLine  = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_F_A <= dist_B_I) && E != A && D != A;
      origin = haveShallowLine? vec2(0.25, 0.0) : vec2(0.5, 0.0);
      direction.y -= haveShallowLine? 1.0: 0.0;
      direction.x -= haveSteepLine? 1.0: 0.0;
    }

    vec3 blendPix = mix(F,B, step(painting_distYCbCr(E, B), painting_distYCbCr(E, F)));
    res = mix(res, blendPix, painting_getLeftRatio(pos, origin, direction, scale));
  }

  // Pixel Tap Mapping: -|x|x|-|-
  //                    x|A|B|C|-
  //                    x|D|E|F|-
  //                    -|G|H|-|-
  //                    -|-|-|-|-
  if (blendResult.x != PAINTING_BLEND_NONE) {
    float dist_D_C = painting_distYCbCr(D, C);
    float dist_B_G = painting_distYCbCr(B, G);
    bool doLineBlend = (blendResult.x == PAINTING_BLEND_DOMINANT ||
                        !((blendResult.w != PAINTING_BLEND_NONE && !painting_isPixEqual(E, C)) || (blendResult.y != PAINTING_BLEND_NONE && !painting_isPixEqual(E, G)) ||
                          (painting_isPixEqual(C, B) && painting_isPixEqual(B, A) && painting_isPixEqual(A, D) && painting_isPixEqual(D, G) && !painting_isPixEqual(E, A))));

    vec2 origin = vec2(0.0, -1.0 / sqrt(2.0));
    vec2 direction = vec2(-1.0, 1.0);
    if (doLineBlend) {
      bool haveShallowLine = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_D_C <= dist_B_G) && E != C && F != C;
      bool haveSteepLine  = (PAINTING_STEEP_DIRECTION_THRESHOLD * dist_B_G <= dist_D_C) && E != G && H != G;
      origin = haveShallowLine? vec2(0.0, -0.25) : vec2(0.0, -0.5);
      direction.x -= haveShallowLine? 1.0: 0.0;
      direction.y += haveSteepLine? 1.0: 0.0;
    }

    vec3 blendPix = mix(D,B, step(painting_distYCbCr(E, B), painting_distYCbCr(E, D)));
    res = mix(res, blendPix, painting_getLeftRatio(pos, origin, direction, scale));
  }

  return vec4(res, 1.0);
}



/* PAL */

// Original name: pal-singlepass (Phase Alternating Line)
// https://github.com/libretro/glsl-shaders/blob/master/pal/shaders/pal-singlepass.glsl

uniform COMPAT_PRECISION int FrameCount;

#define pal_InputSize u_Resolution // Width and height in pixels of game screen
#define pal_SourceSize vec4(pal_InputSize, 1.0 / pal_InputSize) //either TextureSize or pal_InputSize

#define pal_FIR_GAIN 1.5
#define pal_FIR_INVGAIN 1.1
#define pal_PHASE_NOISE 1.0

#define pal_FSC 4433618.75 // Subcarrier frequency
#define pal_FLINE 15625. // Line frequency

#define pal_VISIBLELINES 312.

#define pal_fetch(ofs,center,pal_invx) texture2D(u_Tex0, vec2((ofs) * (pal_invx) + center.x, center.y))

#define pal_FIRTAPS 20.
float pal_FIR1 = -0.008030271,
      pal_FIR2 = 0.003107906,
      pal_FIR3 = 0.016841352,
      pal_FIR4 = 0.032545161,
      pal_FIR5 = 0.049360136,
      pal_FIR6 = 0.066256720,
      pal_FIR7 = 0.082120150,
      pal_FIR8 = 0.095848433,
      pal_FIR9 = 0.106453014,
      pal_FIR10 = 0.113151423,
      pal_FIR11 = 0.115441842,
      pal_FIR12 = 0.113151423,
      pal_FIR13 = 0.106453014,
      pal_FIR14 = 0.095848433,
      pal_FIR15 = 0.082120150,
      pal_FIR16 = 0.066256720,
      pal_FIR17 = 0.049360136,
      pal_FIR18 = 0.032545161,
      pal_FIR19 = 0.016841352,
      pal_FIR20 = 0.003107906;

// Subcarrier counts per scan line = pal_FSC/pal_FLINE = 283.7516
// We save the reciprocal of this only to optimize it
float pal_counts_per_scanline_reciprocal = 1.0 / (pal_FSC/pal_FLINE);

float pal_width_ratio;
float pal_height_ratio;
float pal_altv;
float pal_invx;

// http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
float pal_rand(vec2 co)
{
  float a  = 12.9898;
  float b  = 78.233;
  float c  = 43758.5453;
  float dt = dot(co.xy, vec2(a, b));
  float sn = mod(dt,3.14);

  return fract(sin(sn) * c);
}

float pal_modulated(vec2 xy, float sinwt, float coswt)
{
  vec3 rgb = pal_fetch(0., xy, pal_invx).xyz;
  vec3 yuv = RGB_to_YUV * rgb;

  return clamp(yuv.x + yuv.y * sinwt + yuv.z * coswt, 0.0, 1.0);
}

vec2 pal_modem_uv(vec2 xy, float ofs) {
  float t  = (xy.x + ofs * pal_invx) * pal_SourceSize.x;
  float wt = t * 2. * PI / pal_width_ratio;

  float sinwt = sin(wt);
  float coswt = cos(wt + pal_altv);

  vec3 rgb = pal_fetch(ofs, xy, pal_invx).xyz;
  vec3 yuv = RGB_to_YUV * rgb;
  float signal = clamp(yuv.x + yuv.y * sinwt + yuv.z * coswt, 0.0, 1.0);

  if (pal_PHASE_NOISE != 0.) {
    // .yy is horizontal noise, .xx looks bad, .xy is classic noise
    vec2 seed = xy.yy * float(FrameCount);
    wt        = wt + pal_PHASE_NOISE * (pal_rand(seed) - 0.5);
    sinwt     = sin(wt);
    coswt     = cos(wt + pal_altv);
  }

  return vec2(signal * sinwt, signal * coswt);
}

vec4 getPalColor()
{
  vec2 xy          = v_TexCoord;
  pal_width_ratio  = pal_SourceSize.x * (pal_counts_per_scanline_reciprocal);
  pal_height_ratio = pal_SourceSize.y / pal_VISIBLELINES;
  pal_altv         = mod(floor(xy.y * pal_VISIBLELINES + 0.5), 2.0) * PI;
  pal_invx         = 0.25 * (pal_counts_per_scanline_reciprocal); // equals 4 samples per Fsc period

  // lowpass U/V at baseband
  vec2 filtered = vec2(0.0, 0.0);

  vec2 uv;
  // #define macro_loopz(c)  uv = pal_modem_uv(xy, float(c) - pal_FIRTAPS*0.5); filtered += pal_FIR_GAIN * uv * FIR##c;

  uv = pal_modem_uv(xy, 1. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR1;

  uv = pal_modem_uv(xy, 2. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR2;

  uv = pal_modem_uv(xy, 3. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR3;

  uv = pal_modem_uv(xy, 4. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR4;

  uv = pal_modem_uv(xy, 5. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR5;

  uv = pal_modem_uv(xy, 6. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR6;

  uv = pal_modem_uv(xy, 7. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR7;

  uv = pal_modem_uv(xy, 8. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR8;

  uv = pal_modem_uv(xy, 9. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR9;

  uv = pal_modem_uv(xy, 10. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR10;

  uv = pal_modem_uv(xy, 11. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR11;

  uv = pal_modem_uv(xy, 12. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR12;

  uv = pal_modem_uv(xy, 13. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR13;

  uv = pal_modem_uv(xy, 14. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR14;

  uv = pal_modem_uv(xy, 15. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR15;

  uv = pal_modem_uv(xy, 16. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR16;

  uv = pal_modem_uv(xy, 17. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR17;

  uv = pal_modem_uv(xy, 18. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR18;

  uv = pal_modem_uv(xy, 19. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR19;

  uv = pal_modem_uv(xy, 20. - pal_FIRTAPS*0.5);
  filtered += pal_FIR_GAIN * uv * pal_FIR20;

  // macro_loopz(1)
  // macro_loopz(2)
  // macro_loopz(3)
  // macro_loopz(4)
  // macro_loopz(5)
  // macro_loopz(6)
  // macro_loopz(7)
  // macro_loopz(8)
  // macro_loopz(9)
  // macro_loopz(10)
  // macro_loopz(11)
  // macro_loopz(12)
  // macro_loopz(13)
  // macro_loopz(14)
  // macro_loopz(15)
  // macro_loopz(16)
  // macro_loopz(17)
  // macro_loopz(18)
  // macro_loopz(19)
  // macro_loopz(20)

  float t  = xy.x * pal_SourceSize.x;
  float wt = t * 2. * PI / pal_width_ratio;

  float sinwt = sin(wt);
  float coswt = cos(wt + pal_altv);

  float luma      = pal_modulated(xy, sinwt, coswt) - pal_FIR_INVGAIN * (filtered.x * sinwt + filtered.y * coswt);
  vec3 yuv_result = vec3(luma, filtered.x, filtered.y);

  return vec4(YUV_to_RGB * yuv_result, 1.0);
}



/* Party */

vec4 getPartyColor(vec4 startColor)
{
  float d = u_Time * 2.0;
  startColor.x += (1.0 + sin(d)) * 0.25;
  startColor.y += (1.0 + sin(d * 2.0)) * 0.25;
  startColor.z += (1.0 + sin(d * 4.0)) * 0.25;
  return startColor;
}



/* Pulse */

vec4 getPulseColor()
{
  vec2 halfres = u_Resolution.xy / 2.0;
  vec2 cPos = (v_TexCoord.xy + vec2(u_WalkOffset.x, u_WalkOffset.y)) * u_Resolution;

  cPos.x -= 0.5 * halfres.x * sin(u_Time / 2.0) + 0.3 * halfres.x * cos(u_Time) + halfres.x;
  cPos.y -= 0.4 * halfres.y * sin(u_Time / 5.0) + 0.3 * halfres.y * cos(u_Time) + halfres.y;
  float cLength = length(cPos);

  vec2 uv = v_TexCoord.xy + ((cPos / cLength) * sin(cLength / 30.0 - u_Time * 10.0) / 25.0) * 0.15;
  vec3 col = texture2D(u_Tex0, uv).xyz * 250.0 / cLength;

  return vec4(col, 1.0);
}



/* Radial Blur */

// some const, tweak for best look
const float radialBlur_sampleDist = 1.0;
const float radialBlur_sampleStrength = 2.2;

vec4 getRadialBlurColor(vec4 startColor)
{
  // 0.5,0.5 is the center of the screen
  // so substracting v_TexCoord from it will result in
  // a vector pointing to the middle of the screen
  vec2 dir = 0.5 - v_TexCoord;

  // calculate the distance to the center of the screen
  float dist = sqrt(dir.x * dir.x + dir.y * dir.y);

  // normalize the direction (reuse the distance)
  dir = dir / dist;

  vec4 sum = startColor;

  // take 10 additional blur samples in the direction towards
  // the center of the screen
  sum += texture2D(u_Tex0, v_TexCoord - 0.08 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord - 0.05 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord - 0.03 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord - 0.02 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord - 0.01 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord + 0.01 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord + 0.02 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord + 0.03 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord + 0.05 * dir * radialBlur_sampleDist);
  sum += texture2D(u_Tex0, v_TexCoord + 0.08 * dir * radialBlur_sampleDist);

  // we have taken eleven samples
  sum *= 1.0 / 11.0;

  // weighten the blur effect with the distance to the
  // center of the screen ( further out is blurred more)
  float t = dist * radialBlur_sampleStrength;
  t = clamp(t, 0.0, 1.0); //0 &lt;= t &lt;= 1

  // Blend the original color with the averaged pixels
  return mix(startColor, sum, t);
}



/* Sepia */

vec4 getSepiaColor(vec4 startColor)
{
  return vec4(dot(startColor, vec4(.393, .769, .189, .0)),
              dot(startColor, vec4(.349, .686, .168, .0)),
              dot(startColor, vec4(.272, .534, .131, .0)),
              1);
}



/* Snow */

vec2 snow_direction = vec2(-0.5, 1.0);
float snow_speed = 0.06;
float snow_pressure = 0.6;
float snow_zoom = 0.4;

vec4 getSnowColor(vec4 startColor)
{
  vec3 Game = startColor.xyz;

  vec2 SnowHandler = (v_TexCoord + vec2(u_WalkOffset.x, u_WalkOffset.y) + (snow_direction * u_Time * snow_speed)) / snow_zoom;
  vec3 Snow = texture2D(u_Tex3, SnowHandler).xyz;

  return vec4(Game + Snow * snow_pressure, 1.0);
}



/* Water */

// https://github.com/KhronosGroup/siggraph2012course/blob/master/CanvasCSSAndWebGL/demos/Ninja/rdge0.6.0.4/shaders/Water2.frag.glsl

// speed
const float water_speed = 0.2;
const float water_speed_x = 0.3;
const float water_speed_y = 0.3;

// geometry
const float water_intensity = 3.;
const int water_steps = 8;
const float water_frequency = 4.0;
const int water_angle = 7; // better when a prime

// reflection and emboss
const float water_delta = 20.;
const float water_intence = 400.;
const float water_emboss = 0.01;

// crystals effect
float col(vec2 coord) {
  float delta_theta = 2.0 * PI / float(water_angle);
  float col = 0.0;
  float theta = 0.0;
  for (int i = 0; i < water_steps; i++) {
    vec2 adjc = coord;
    theta = delta_theta*float(i);
    adjc.x += cos(theta)*u_Time*water_speed + u_Time * water_speed_x;
    adjc.y -= sin(theta)*u_Time*water_speed - u_Time * water_speed_y;
    col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*water_frequency)*water_intensity;
  }

  return cos(col);
}

vec4 getWaterColor()
{
  vec2 p = v_TexCoord, c1 = p, c2 = p;
  float cc1 = col(c1);

  c2.x += u_Resolution.x/water_delta;
  float dx = water_emboss*(cc1-col(c2))/water_delta;

  c2.x = p.x;
  c2.y += u_Resolution.y/water_delta;
  float dy = water_emboss*(cc1-col(c2))/water_delta;

  c1.x += dx;
  c1.y = (c1.y+dy);

  float alpha = 1.+dot(dx,dy)*water_intence;
  return texture2D(u_Tex0,c1)*(alpha);
}



/* Zomg */

vec4 getZomgColor()
{
  vec2 dir = 0.5 - v_TexCoord;
  float dist = sqrt(dir.x * dir.x + dir.y * dir.y);
  float scale = 0.8 + dist * 0.5;
  return texture2D(u_Tex0, -(dir * scale - 0.5));
}



/* Main */

void main(void)
{
  bool isFirstChosenCoordShader = true;
  vec4 color;



  /* Coordinate shaders */

  // Coordinate effects (choose few, but they will be mixed; use them rarely)

  if (u_DrawCoordEffectShadersFlags != 0) {
    // Heat
    if ((u_DrawCoordEffectShadersFlags & DRAWCOORDEFFECTSHADER_HEAT) == DRAWCOORDEFFECTSHADER_HEAT) {
      if (isFirstChosenCoordShader) {
        isFirstChosenCoordShader = false;
        color = getHeatColor();
      } else
        color = mix(color, getHeatColor(), 0.5);
    }

    // Noise
    if ((u_DrawCoordEffectShadersFlags & DRAWCOORDEFFECTSHADER_NOISE) == DRAWCOORDEFFECTSHADER_NOISE) {
      if (isFirstChosenCoordShader) {
        isFirstChosenCoordShader = false;
        color = getNoiseColor();
      } else
        color = mix(color, getNoiseColor(), 0.5);
    }

    // PAL
    if ((u_DrawCoordEffectShadersFlags & DRAWCOORDEFFECTSHADER_PAL) == DRAWCOORDEFFECTSHADER_PAL) {
      if (isFirstChosenCoordShader) {
        isFirstChosenCoordShader = false;
        color = getPalColor();
      } else
        color = mix(color, getPalColor(), 0.5);
    }

    // Pulse
    if ((u_DrawCoordEffectShadersFlags & DRAWCOORDEFFECTSHADER_PULSE) == DRAWCOORDEFFECTSHADER_PULSE) {
      if (isFirstChosenCoordShader) {
        isFirstChosenCoordShader = false;
        color = getPulseColor();
      } else
        color = mix(color, getPulseColor(), 0.5);
    }

    // Water
    if ((u_DrawCoordEffectShadersFlags & DRAWCOORDEFFECTSHADER_WATER) == DRAWCOORDEFFECTSHADER_WATER) {
      if (isFirstChosenCoordShader) {
        isFirstChosenCoordShader = false;
        color = getWaterColor();
      } else
        color = mix(color, getWaterColor(), 0.5);
    }

    // Zomg
    if ((u_DrawCoordEffectShadersFlags & DRAWCOORDEFFECTSHADER_ZOMG) == DRAWCOORDEFFECTSHADER_ZOMG) {
      if (isFirstChosenCoordShader) {
        isFirstChosenCoordShader = false;
        color = getZomgColor();
      } else
        color = mix(color, getZomgColor(), 0.5);
    }

  // No coordinate effects
  } else {

    // Filters (choose a single one only!)

    if (u_DrawCoordFilterShadersFlags != 0) {
      // XBR4x
      if ((u_DrawCoordFilterShadersFlags & DRAWCOORDFILTERSHADER_XBR4X) == DRAWCOORDFILTERSHADER_XBR4X) {
        isFirstChosenCoordShader = false;
        color = getXBR4xColor();

      // 2xSaI Level 2
      } else if ((u_DrawCoordFilterShadersFlags & DRAWCOORDFILTERSHADER_2XSAILEVEL2) == DRAWCOORDFILTERSHADER_2XSAILEVEL2) {
        isFirstChosenCoordShader = false;
        color = get2xSaILevel2Color();

      // 2xSaI
      } else if ((u_DrawCoordFilterShadersFlags & DRAWCOORDFILTERSHADER_2XSAI) == DRAWCOORDFILTERSHADER_2XSAI) {
        isFirstChosenCoordShader = false;
        color = get2xSaIColor();

      // Painting
      } else if ((u_DrawCoordFilterShadersFlags & DRAWCOORDFILTERSHADER_PAINTING) == DRAWCOORDFILTERSHADER_PAINTING) {
        isFirstChosenCoordShader = false;
        color = getPaintingColor();
      }
    }
  }



  // Fragment not found, so use original color
  if (isFirstChosenCoordShader)
    color = texture2D(u_Tex0, v_TexCoord); // Original color



  /* Effect shaders (choose multiple) */

  if (u_DrawEffectShadersFlags != 0) {
    // Coloring - Removing color
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_GRAYSCALE) == DRAWEFFECTSHADER_GRAYSCALE) color = getGrayscaleColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_NEGATIVE) == DRAWEFFECTSHADER_NEGATIVE)   color = getNegativeColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_SEPIA) == DRAWEFFECTSHADER_SEPIA)         color = getSepiaColor(color);

    // Coloring - Adding color
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_PARTY) == DRAWEFFECTSHADER_PARTY) color = getPartyColor(color);

    // Effects
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_BLOOM) == DRAWEFFECTSHADER_BLOOM)           color = getBloomColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_CLOUDS) == DRAWEFFECTSHADER_CLOUDS)         color = getCloudsColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_FOG) == DRAWEFFECTSHADER_FOG)               color = getFogColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_OLDTV) == DRAWEFFECTSHADER_OLDTV)           color = getOldTvColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_RADIALBLUR) == DRAWEFFECTSHADER_RADIALBLUR) color = getRadialBlurColor(color);
    if ((u_DrawEffectShadersFlags & DRAWEFFECTSHADER_SNOW) == DRAWEFFECTSHADER_SNOW)             color = getSnowColor(color);
  }

  gl_FragColor = color;
}
