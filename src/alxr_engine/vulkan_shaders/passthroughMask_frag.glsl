#version 460
#ifdef ENABLE_ARB_INCLUDE_EXT
    #extension GL_ARB_shading_language_include : require
#else
    // required by glslangValidator
    #extension GL_GOOGLE_include_directive : require
#endif
#pragma fragment

#include "common/baseVideoFrag.glsl"

layout(constant_id = 9) const float AlphaValue = 0.3f;
layout(constant_id = 10) const float KeyColorR = 0.0f;
layout(constant_id = 11) const float KeyColorG = 0.69f;
layout(constant_id = 12) const float KeyColorB = 0.25f;

// Algo from https://jameshfisher.com/2020/08/11/production-ready-green-screen-in-the-browser/

layout(location = 0) out vec4 FragColor;

// From https://github.com/libretro/glsl-shaders/blob/master/nnedi3/shaders/rgb-to-yuv.glsl
vec2 RGBtoUV(vec3 rgb) {
  return vec2(
    rgb.r * -0.169 + rgb.g * -0.331 + rgb.b *  0.5    + 0.5,
    rgb.r *  0.5   + rgb.g * -0.419 + rgb.b * -0.081  + 0.5
  );
}

void main()
{
    float similarity = 0.05;
    float smoothness = 0.10;
    //float spill = 0.70;
    float spill = 0.20;

    vec4 color = SampleVideoTexture();

    vec3 sphereCenter = vec3(0.0, 0.69, 0.25);
    float sphereRadius = 0.15;
    
    float chromaDist = distance(RGBtoUV(color.rgb), RGBtoUV(sphereCenter));


    float baseMask = chromaDist - similarity;

    float fullMask = pow(clamp(baseMask / smoothness, 0.0, 1.), 1.5);

    color.a = fullMask;
    
    float spillVal = pow(clamp(baseMask / spill, 0.0, 1.), 1.5);
    float desat = clamp(color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722, 0., 1.);

    color.rgb = mix(vec3(desat, desat, desat), color.rgb, spillVal);

    FragColor = color;
}