#define PI 3.141592653589

uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

uniform float u_progress;

void main() {
  vec4 col = texture2D(u_Tex0, v_TexCoord);
  float offset = PI / 2;

  float angle = atan(v_TexCoord.y - 0.5, v_TexCoord.x - 0.5) - offset;
  float normalizedAngle = (angle + PI) / (2.0 * PI);
  
  normalizedAngle = normalizedAngle - floor(normalizedAngle);

  gl_FragColor = mix(
    0.5 * col,
    col,
    step(normalizedAngle, u_progress)
    );
}
