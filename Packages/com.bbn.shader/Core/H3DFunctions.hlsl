#ifndef H3D_FUNCTIONS_HLSL
#define H3D_FUNCTIONS_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "H3DCommon.hlsl"
#include "H3DVolumetricFog.hlsl"
#include "H3DFurShadow.hlsl"
#define DECLARE_SAMPLE_2D(TexName)  TEXTURE2D(TexName); SAMPLER(sampler##TexName);

#define SAMPLE_TEXT(TexName, uv)    SAMPLE_TEXTURE2D(TexName, sampler##TexName, uv)

half3 SampleNormal(Texture2D bumpMap, SamplerState dd, float2 uv, half scale)
{
    half4 n = SAMPLE_TEXTURE2D(bumpMap, dd, uv);
    return UnpackNormalScale(n, scale);
}

half3 SampleNormal(Texture2D bumpMap, SamplerState dd, float2 uv)
{
    half4 n = SAMPLE_TEXTURE2D(bumpMap, dd, uv);
    return UnpackNormalScale(n, 1);
}

void InitNormalMap(VertexOutput i, inout H3DSurfaceData surf)
{
    float sgn = i.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);

    surf.normal = TransformTangentToWorld(surf.normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));
    surf.normal = NormalizeNormalPerPixel(surf.normal);
    surf.viewDir = SafeNormalize(i.viewDirWS);
}

void InitInputData(VertexOutput i, inout H3DSurfaceData surf)
{
#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    surf.positionWS = i.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    surf.shadowCoord = i.shadowCoord;   
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    surf.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
#else
    surf.shadowCoord = float4(0, 0, 0, 0);
#endif
    surf.furShadowCoord =TransformFurWorldToShadowCoord(i.positionWS);
    surf.fogCoord = i.fogFactorAndVertexLight.x;
    //获取表面深度
    surf.depth = -TransformWorldToView(i.positionWS).z;
    surf.svPostion = i.positionCS;
    surf.screenPosition = surf.svPostion;
    surf.screenPosition.xy = surf.screenPosition.xy * (_ScreenParams.zw - 1);
    surf.vertexLighting = i.fogFactorAndVertexLight.yzw;

    surf.ahdLight = (Light)0;
    surf.ahdLight.shadowAttenuation = 1.0;
    surf.ahdLight.distanceAttenuation = 1;
    // surf.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, surf.normal);
//     
// #ifdef LIGHTMAP_ON
//     #if SPE
//         surf.bakedGI = SampleLightmapEx(i.lightmapUV, surf.normal, surf.ahdLight);
//     #else
//         surf.bakedGI = SampleLightmap(i.lightmapUV, surf.normal);
//     #endif
// #else
//     surf.bakedGI = SampleSHPixel(i.vertexSH, surf.normal);
// #endif
half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
#if defined (LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    #if defined(DYNAMICLIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
        surf.bakedGI = SampleDirectionalLightmap(TEXTURE2D_ARGS(unity_DynamicLightmap, samplerunity_DynamicLightmap),
        TEXTURE2D_ARGS(unity_DynamicDirectionality, samplerunity_DynamicLightmap),
        i.uv.zw, half4(1, 1, 0, 0), i.normalWS, false, decodeInstructions);
    #elif defined(DYNAMICLIGHTMAP_ON)
        surf.bakedGI = SampleSingleLightmap(TEXTURE2D_ARGS(unity_DynamicLightmap, samplerunity_DynamicLightmap),
        i.uv.zw, half4(1, 1, 0, 0), false, decodeInstructions);
    #else
        surf.bakedGI = SampleLightmap(i.lightmapUV, surf.normal);
    #endif
#else
    surf.bakedGI = SampleSHPixel(i.vertexSH, surf.normal);
#endif
    surf.shadowMask = SAMPLE_SHADOWMASK(i.lightmapUV);


    
}

void InitializeInputData(VertexOutput input, inout H3DSurfaceData surf)
{
    #ifdef _NORMALMAP
    InitNormalMap(input, surf);
    #else
    surf.viewDir = SafeNormalize(input.viewDirWS);
    surf.normal = NormalizeNormalPerPixel(input.normalWS);
    #endif

    InitInputData(input, surf);
}
void InitSimpleInputData(VertexOutput input, inout H3DSurfaceData surf)
{
    
    surf.viewDir = SafeNormalize(input.viewDirWS);
    surf.normal = NormalizeNormalPerPixel(input.normalWS);
    InitInputData(input, surf);
}
///     params.x : Parallax.r
///     params.y : _HeightScale
///     params.z : _Bias
inline void ApplyParallaxUV(float3 params, inout VertexOutput o)
{
    float parallaxStrength = (params.x - 0.5) * params.y;
    o.uv.xy += (o.viewDirTS.xy / (o.viewDirTS.z + params.z)) * parallaxStrength;
}

inline half4 MixColor(half3 color, H3DSurfaceData surf)
{
    color += surf.emission;
    //color.rgb = lerp(color.rgb, surf.detail.rgb, surf.detail.a);
    color.rgb = MixFog(color.rgb, surf.fogCoord);
    #if _TRANSPARENT && _VOLUMETRIC_FOG
        color.rgb = ApplyVolumetricFog(color.rgb, surf.svPostion.xyz);
    #else    
        if (surf.planeRefelct==1)
        {
            #if  _VOLUMETRIC_FOG
             color.rgb = ApplyVolumetricFog(color.rgb, surf.svPostion.xyz);
            #endif
        }    
    #endif
    return half4(color, surf.alpha);
}

 
inline H3DBRDF InitBRDFData(H3DSurfaceData surf)
{
    H3DBRDF brdf = (H3DBRDF) 0 ;
    brdf.oneMinusReflectivity = OneMinusReflectivityMetallic(surf.metallic);
    brdf.diffuse = lerp(surf.albedo, surf.detail, surf.detailMSOMap.a) * brdf.oneMinusReflectivity;
    brdf.perceptualRoughness = 1 - surf.smoothness;
    brdf.roughness = max(PerceptualRoughnessToRoughness(brdf.perceptualRoughness), HALF_MIN);
    brdf.roughness2 = brdf.roughness * brdf.roughness;
    brdf.specular = lerp(kDieletricSpec.rgb, lerp(surf.albedo, surf.detail, surf.detailMSOMap.a), surf.metallic);
    brdf.reflectDir = reflect(-surf.viewDir, surf.normal);

    brdf.grazingTerm = saturate(surf.smoothness + 1.0 - brdf.oneMinusReflectivity);

    return brdf;
}


inline H3DBRDF InitBRDFDataSpecular(H3DSurfaceData surf)
{
    H3DBRDF brdf = (H3DBRDF) 0 ;
    brdf.oneMinusReflectivity = OneMinusReflectivityMetallic(surf.metallic);
    brdf.diffuse = lerp(surf.albedo, surf.detail, surf.detailMSOMap.a) * (half3(1.0h, 1.0h, 1.0h) - surf.specular);;
    brdf.perceptualRoughness = 1 - surf.smoothness;
    brdf.roughness = max(PerceptualRoughnessToRoughness(brdf.perceptualRoughness), HALF_MIN);
    brdf.roughness2 = brdf.roughness * brdf.roughness;
    brdf.specular = surf.specular;
    brdf.reflectDir = reflect(-surf.viewDir, surf.normal);
    
    half reflectivity = ReflectivitySpecular(surf.specular);
    brdf.grazingTerm = saturate(surf.smoothness + reflectivity);


    
    // half oneMinusReflectivity = 1.0 - reflectivity;
    //
    //
    //
    // #ifdef _ALPHAPREMULTIPLY_ON
    // outBRDFData.diffuse *= alpha;
    // alpha = alpha * oneMinusReflectivity + reflectivity;
    // #endif
    //
    return brdf;
}

#endif