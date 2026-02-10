#include "common.glsl"

#iChannel0 "bufferA.glsl"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // get the texture color from bufferA
    vec4 color = texture(iChannel0, fragCoord / iResolution.xy);

    color *= 0.5f;

    color.rgb = AGX(color.rgb);

    color.rgb = LinearToSRGB(color.rgb);

    fragColor = color;
}