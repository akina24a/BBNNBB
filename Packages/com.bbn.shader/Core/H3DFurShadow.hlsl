#ifndef H3D_LIT_HLSL
#define H3D_LIT_HLSL

#include "H3DDebug.hlsl"
#include "H3DCommon.hlsl"

// #ifdef  _FURSHADOW
TEXTURE2D_SHADOW(_FurMainLightShadowmapTexture);
SAMPLER_CMP(sampler_FurMainLightShadowmapTexture);
float4x4  _MainLightWorldToFurShadow;
half4  _FurShadowShadowParams;
half4  _FurShadowSplitSpheres;

float4 TransformFurWorldToShadowCoord(float3 positionWS)
{
    float4 shadowCoord = 0;
    #if defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN) 

    float3 fromCenter0 = positionWS - _FurShadowSplitSpheres.xyz;
    float distances2 = dot(fromCenter0, fromCenter0);
    if(distances2 > _FurShadowShadowParams.w)
         shadowCoord = mul(_MainLightWorldToShadow[4], float4(positionWS, 1.0));
    else
        shadowCoord = mul(_MainLightWorldToFurShadow, float4(positionWS, 1.0));
    
    return float4(shadowCoord.xyz, 0);
    #else
    {
        shadowCoord = mul(_MainLightWorldToFurShadow, float4(positionWS, 1.0));  
        return float4(shadowCoord.xyz, 0);
    }
    #endif

    
   
}


half MainLightRealtimeFurShadow(float4 shadowCoord)
{
    #if !defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    return half(1.0);
    #endif
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    return lerp(SampleShadowmap(TEXTURE2D_ARGS(_FurMainLightShadowmapTexture, sampler_FurMainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false),1,_FurShadowShadowParams.x);
}

half GetMainLightFurShadowFade(float3 positionWS)
{
    float3 camToPixel = positionWS - _WorldSpaceCameraPos;
    float distanceCamToPixel2 = dot(camToPixel, camToPixel);

    float fade = saturate(distanceCamToPixel2 * float(_FurShadowShadowParams.y) + float(_FurShadowShadowParams.z));
    return half(fade);
}


// #endif
#endif