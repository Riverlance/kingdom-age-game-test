uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{
  vec4 color = texture2D(u_Tex0, v_TexCoord);
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
    color += texture2D(u_Tex0, v_TexCoord + offsets[i] * texOffset) * kernel[i];

  gl_FragColor = color;
}
