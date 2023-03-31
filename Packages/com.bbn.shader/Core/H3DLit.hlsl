#ifndef H3D_LIT_HLSL
#define H3D_LIT_HLSL

#include "H3DDebug.hlsl"
#include "H3DCommon.hlsl"

half3 GetNormalWS(half3 normalTS, VertexOutput input)
{
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3 normal = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
    return normalize(normal);
}

inline half3 IndirectLight(H3DSurfaceData surf, H3DBRDF brdf)
{
    half3 indirectDiffuse = surf.bakedGI * surf.occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(brdf.reflectDir, brdf.perceptualRoughness, surf.occlusion);
    half3 indirectColor = indirectDiffuse * brdf.diffuse;
    float surfaceReduction = 1.0 / (brdf.roughness2 + 1.0);
    half fresnelTerm = Pow4(1.0 - saturate(dot(surf.normal, surf.viewDir)));
    indirectColor += surfaceReduction * indirectSpecular * lerp(brdf.specular, brdf.grazingTerm, fresnelTerm);
    return indirectColor;
}

inline half3 DirectLight(Light light, H3DSurfaceData surf, H3DBRDF brdf)
{
    half3 lightDirectionWS = light.direction;
    half3 lightColor = light.color;
    half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
    
    half NoL = saturate(dot(surf.normal, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NoL);
    
    float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(surf.viewDir));
    float NoH = saturate(dot(surf.normal, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));
    
    float d = NoH * NoH * (brdf.roughness2 - 1.0f) + 1.00001f;
    half LoH2 = LoH * LoH;
    half normalizationTerm = brdf.roughness * 4.0h + 2.0h;
    half specularTerm = brdf.roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);
    
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
    half3 color = specularTerm * brdf.specular + brdf.diffuse;
    return color * radiance;
}

inline half3 StandardLight(H3DSurfaceData surf)
{
    //brdf data
    H3DBRDF brdf = InitBRDFData(surf);
    half3 indirectColor = IndirectLight(surf, brdf);
    DEBUG_PROCESS_INDIRECTLIGHT(indirectColor)
    
    Light mainLight;

#if SPE && defined(DIRLIGHTMAP_COMBINED)
    mainLight = surf.ahdLight;
#else
    mainLight = GetMainLight(surf.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, surf.normal, surf.bakedGI, 0);
#endif
    half3 directColor = DirectLight(mainLight, surf, brdf);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surf.positionWS);
        directColor += DirectLight(light, surf, brdf);
    }
#endif
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    directColor += surf.vertexLighting * brdf.diffuse;
#endif

    DEBUG_PROCESS_DIRECTLIGHT(directColor)
    
    return indirectColor + directColor;
}


inline half3 StandardLightSpecular(H3DSurfaceData surf)
{
    //brdf data
    H3DBRDF brdf = InitBRDFDataSpecular(surf);
    half3 indirectColor = IndirectLight(surf, brdf);
    DEBUG_PROCESS_INDIRECTLIGHT(indirectColor)
    
    Light mainLight;

    #if SPE && defined(DIRLIGHTMAP_COMBINED)
    mainLight = surf.ahdLight;
    #else
    mainLight = GetMainLight(surf.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, surf.normal, surf.bakedGI, 0);
    #endif
    half3 directColor = DirectLight(mainLight, surf, brdf);
    #ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surf.positionWS, 1);
        directColor += DirectLight(light, surf, brdf);
    }
    #endif
    
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    directColor += surf.vertexLighting * brdf.diffuse;
    #endif
    
    #ifdef _ADDITIONAL_LIGHTS_FORWARD_PLUS
    uint GridIndex = ComputeLightGridCellIndex(surf.svPostion);
    uint lightCount = _NumCulledLightsGrid[GridIndex];
    if(lightCount > 0)
    {
        uint value = _CulledLightDataGrid[GridIndex];
        UNITY_LOOP
        for(uint i = 0u; i < lightCount; ++i)
        {
            uint lightIndex = (value >> (24 - i * 8)) & 0xFF;
            Light light = GetAdditionalLight(lightIndex, surf.positionWS, 1);
            directColor += DirectLight(light, surf, brdf);
        }
    }
    #endif

    DEBUG_PROCESS_DIRECTLIGHT(directColor)
    
    return indirectColor + directColor;
}

inline half4 SurfaceStandard(H3DSurfaceData surf)
{
    DEBUG_PROCESS_SURFACE(surf)
    half3 color = StandardLight(surf);
    return MixColor(color, surf);
}

inline half4 SurfaceStandardSpecular(H3DSurfaceData surf)
{
    DEBUG_PROCESS_SURFACE(surf)
    half3 color = StandardLightSpecular(surf);
    return MixColor(color, surf);  
}

//
// inline half4 SurfaceSpecular(H3DSurfaceData surf)
// {
//     DEBUG_PROCESS_SURFACE(surf)
//     half3 color = StandardLight(surf);
//     return MixColor(color, surf);
// }

#endif