uniform float u_Time;
uniform vec4 u_eColor, u_iColor, u_cColor;
uniform sampler2D u_Tex0;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;

const float alphaEpsilon = 0.01;
const int maxOutlineRadius = 2;
// Outline thickness in pixels. Change this value to configure border width.
const float outlineThickness = 4.0;

float sampleAlpha(vec2 uv)
{
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
		return 0.0;

	return texture2D(u_Tex0, uv).a;
}

float outlinePulse()
{
	return (cos(u_Time * 6.3) + 1.0) * 0.1 + 0.8;
}

float getOutlineThickness()
{
	return clamp(outlineThickness, 1.0, float(maxOutlineRadius));
}

float hasTransparentNeighbor(vec2 uv, vec2 texel)
{
	for (int y = -1; y <= 1; ++y) {
		for (int x = -1; x <= 1; ++x) {
			if (x == 0 && y == 0)
				continue;

			vec2 offset = vec2(float(x) * texel.x, float(y) * texel.y);
			if (sampleAlpha(uv + offset) <= alphaEpsilon)
				return 1.0;
		}
	}

	return 0.0;
}

float hasOpaqueNeighbor(vec2 uv, vec2 texel, float radius)
{
	float radiusSquared = radius * radius;

	for (int y = -maxOutlineRadius; y <= maxOutlineRadius; ++y) {
		for (int x = -maxOutlineRadius; x <= maxOutlineRadius; ++x) {
			if (x == 0 && y == 0)
				continue;

			vec2 pixelOffset = vec2(float(x), float(y));
			if (dot(pixelOffset, pixelOffset) > radiusSquared)
				continue;

			vec2 uvOffset = vec2(pixelOffset.x * texel.x, pixelOffset.y * texel.y);
			if (sampleAlpha(uv + uvOffset) > alphaEpsilon)
				return 1.0;
		}
	}

	return 0.0;
}

void main()
{
	vec4 col = texture2D(u_Tex0, v_TexCoord);
	vec2 texel = vec2(abs(u_TextureMatrix[0][0]), abs(u_TextureMatrix[1][1]));
	float thickness = getOutlineThickness();

	// Inside sprite pixels
	if (col.a > alphaEpsilon) {
		// Internal color stays optional, only for the edge pixels of the sprite.
		if (u_iColor.a >= 0.5 && hasTransparentNeighbor(v_TexCoord, texel) > 0.0) {
			gl_FragColor = vec4(mix(col.rgb, u_iColor.rgb, 0.5), col.a);
		} else if (u_cColor.a >= 0.5) {
			gl_FragColor = vec4(mix(col.rgb, u_cColor.rgb, 0.5), col.a);
		} else {
			gl_FragColor = col;
		}
		return;
	}

	// Outside sprite pixels: draw only external outline.
	if (u_eColor.a > alphaEpsilon && hasOpaqueNeighbor(v_TexCoord, texel, thickness) > 0.0) {
		float pulse = outlinePulse();
		gl_FragColor = vec4(pulse * u_eColor.rgb, pulse * u_eColor.a);
	} else {
		gl_FragColor = col;
	}
}
