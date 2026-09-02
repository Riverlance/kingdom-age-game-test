// This is used in the minimap

uniform float u_Time;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1; // Clouds texture
varying vec2 v_TexCoord;
uniform vec2 u_Resolution;
uniform float u_MapZoom;
uniform vec2 u_MapGlobalCoord;
uniform vec2 u_MapCenterCoord;
uniform float u_MapFloor;

const float PI = 3.1415926535897932;

float clouds_speed = 0.01;
float clouds_time_scale = 0.05; // Multiplies cyclic clouds time to reduce peak movement speed
float clouds_cycle_time = 18000.0; // Seconds for a full 360-degree direction rotation
float clouds_inverse_direction_time = 3600.0; // Seconds for smooth direction inversion cycle
float clouds_tiling_base = 5.0; // Higher values make clouds smaller and more repeated
float clouds_alpha = 0.85; // 0.0 = invisible, 1.0 = fully white on cloud mask
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

void main()
{
  vec4 startColor = texture2D(u_Tex0, v_TexCoord);

  // Show clouds only from floor 0 (highest) to 7 (ground).
  if (u_MapFloor > 7.0) {
    gl_FragColor = startColor;
    return;
  }

  vec2 resolution = max(u_Resolution, vec2(1.0, 1.0));
  float zoomScale = max(u_MapZoom, 0.01);
  float centerYGl = resolution.y - u_MapCenterCoord.y;
  vec2 screenDelta = vec2(
    gl_FragCoord.x - u_MapCenterCoord.x,
    centerYGl - gl_FragCoord.y
  );
  vec2 mapCoord = u_MapGlobalCoord + (screenDelta / zoomScale);
  vec2 clouds_direction = getCloudsDynamicDirection();
  float inverseTime = max(clouds_inverse_direction_time, clouds_eps);
  // Cyclic time without hard reset: 0 -> peak -> 0 in each inverse cycle
  float phase = 2.0 * PI * u_Time / inverseTime;
  float clouds_time = (0.5 * inverseTime * (1.0 - cos(phase))) * clouds_time_scale;
  vec2 cloudsHandler = ((mapCoord / resolution) * clouds_tiling_base) + (clouds_direction * clouds_time * clouds_speed);

  vec3 cloudsSample = texture2D(u_Tex1, cloudsHandler).rgb;
  float cloudMask = clamp((cloudsSample.r + cloudsSample.g + cloudsSample.b) / 3.0, 0.0, 1.0);

  float blendAmount = cloudMask * clamp(clouds_alpha, 0.0, 1.0);
  vec3 col = mix(startColor.rgb, vec3(1.0), blendAmount);
  gl_FragColor = vec4(col, startColor.a);
}
