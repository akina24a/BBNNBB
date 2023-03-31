#ifndef H3D_LIT_MOBILE_HLSL
#define H3D_LIT_MOBILE_HLSL
#include "Packages/com.h3d.planarreflection/Shaders/PlanarReflection.hlsl"
#include "H3DFurShadow.hlsl"
#include "H3DWorldSpaceCloudsShadow.hlsl"
#include "Packages/com.h3d.shader/Core/H3DKeywordSwitch.hlsl"

inline float3 BoxProjectedCubemapDirection (float3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{
    // Do we have a valid reflection probe?
    UNITY_BRANCH
    if (cubemapCenter.w > 0.0)
    {
        float3 nrdir = normalize(worldRefl);

        #if 1
            float3 rbmax = (boxMax.xyz - worldPos) / nrdir;
            float3 rbmin = (boxMin.xyz - worldPos) / nrdir;

            float3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;

        #else // Optimized version
            float3 rbmax = (boxMax.xyz - worldPos);
            float3 rbmin = (boxMin.xyz - worldPos);

            float3 select = step (float3(0,0,0), nrdir);
            float3 rbminmax = lerp (rbmax, rbmin, select);
            rbminmax /= nrdir;
        #endif

        float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

        worldPos -= cubemapCenter.xyz;
        worldRefl = worldPos + nrdir * fa;
    }
    return worldRefl;
}

half2 EnvBRDFApproxLazarov(half Roughness, half NoV)
{
    // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
    // Adaptation to fit our G term.
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = Roughness * c0 + c1;
    half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    return AB;
}

half4 SamplePlanarReflectionRT(float2 uv, float smoothness)
{
    half3 color = SamplePlanarReflection(uv) * smoothness;
    half intensity = SamplePlanarReflectionIntensity(uv);
        
    half2 vignette = saturate(abs(uv * 2.0 - 1.0) * 5.0 - 4.0);
    half alpha = saturate(1 - dot(vignette, vignette));
    return half4(color, alpha * intensity * smoothness);
}

float2 GetReflectOffsetUV(float2 uv, float3 normalWS, float3 viewDir)
{
    //float depth = SamplePlanarReflectionIntensity(uv);
    float3 reflectOffset = normalWS - float3(0,1,0);
    float2 offsetUV = mul((float3x3)GetWorldToViewMatrix(), reflectOffset).xy;
    return uv + offsetUV * 0.5;
}

//#ifdef  _CAPSULE_OCCLUSION
half _OCStrength;
TEXTURE2D(_CapsuleShadowTexture);
//SAMPLER(sampler_CapsuleShadowTexture);

//#endif

inline half3 IndirectLightMobile(H3DSurfaceData surf, H3DBRDF brdf, float3 worldPos, float indirectAO)
{ 
 
    half3 indirectDiffuse = surf.bakedGI * indirectAO;
    half2 reflectUV = surf.svPostion * _ScreenSize.zw;
    half3 indirectSpecular = GlossyEnvironmentReflection(brdf.reflectDir, worldPos, brdf.perceptualRoughness, indirectAO);
    reflectUV = GetReflectOffsetUV(reflectUV, surf.normal, surf.viewDir);
    UNITY_BRANCH
    if(surf.planeRefelct == 1)
    {
        half4 planeReflection = SamplePlanarReflectionRT(reflectUV, saturate(1-brdf.perceptualRoughness));
        indirectSpecular = lerp(indirectSpecular, planeReflection.rgb, planeReflection.a);
    } 
    //SamplePlanarReflectionResultWithRoughness(reflectUV, worldPos, surf.viewDir,brdf.perceptualRoughness, brdf.reflectDir,surf.planeRefelct);

// #ifdef _RAIN_EFFECT  
//     indirectSpecular = lerp(indirectSpecular,surf.specular,surf.planeRefelct); 
// #endif 
  
    half3 indirectColor = indirectDiffuse * brdf.diffuse;  
    
    indirectColor += indirectSpecular * brdf.specular;
    if(_CAPSULE_OCCLUSION == 1)
    {    
       half capsuleAO = SAMPLE_TEXTURE2D(_CapsuleShadowTexture, sampler_LinearClamp, surf.screenPosition.xy);
       indirectColor *=lerp(1,capsuleAO, _OCStrength);
    }
   
    return indirectColor;
}

// Taken from https://gist.github.com/romainguy/a2e9208f14cae37c579448be99f78f25
// Modified by Epic Games, Inc. To account for premultiplied light color and code style rules.

half GGX_Mobile(half Roughness, float NoH)
{
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float OneMinusNoHSqr = 1.0 - NoH * NoH; 
    half a = Roughness * Roughness;
    half n = NoH * a;
    half p = a / (OneMinusNoHSqr + n * n);
    half d = p * p;
    // clamp to avoid overlfow in a bright env
    return min(d, 2048.0);
}

half CalcSpecular(half Roughness, half NoH)
{
    return (Roughness*0.25 + 0.25) * GGX_Mobile(Roughness, NoH);
}

inline half3 DirectLightMobile(Light light, H3DSurfaceData surf, H3DBRDF brdf,uint meshRenderingLayers, float directAO)
{
    half3 lightDirectionWS = light.direction;

    if (!IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    {
        light.color =0; 
    }
#ifdef LIGHT_SPECULAR_SCALE
    half lightSpecular = light.specularScale;
    half softSpecular = light.softSpecular;
#else
    half lightSpecular = 1;
    half softSpecular = 0;
#endif
        
    half3 lightColor = light.color;
    half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
    
    half NoL = saturate(dot(surf.normal, lightDirectionWS));
    half NoH = saturate(dot(surf.normal, SafeNormalize(lightDirectionWS + surf.viewDir)));
    half3 radiance = lightColor * lightAttenuation * NoL * directAO;
    half3 specular = CalcSpecular(lerp(brdf.perceptualRoughness, 1, softSpecular), NoH) * brdf.specular * lightSpecular;
    half3 diffuse = brdf.diffuse;
    half3 result = radiance * (specular+ diffuse );
        
    return result;
}



inline half3 StandardLightMobile(H3DSurfaceData surf, float3 worldPos)
{
    //brdf data
    H3DBRDF brdf = InitBRDFData(surf);

    half2 AB = EnvBRDFApproxLazarov(saturate(brdf.perceptualRoughness), saturate(dot(surf.normal, surf.viewDir)));
    brdf.specular = brdf.specular * AB.x + AB.y;

    float  directAO = 1.0;

    //改SSAO叠加方式 此处屏蔽代表AO不改变光照，而是最后直接叠加颜色
    //#if _H3DSSAO
    //    half ssao = SampleAmbientOcclusion(surf.screenPosition.xy);
    //
    //    surf.occlusion = min(ssao, surf.occlusion);
    //    directAO = lerp(1.0, ssao, _AmbientOcclusionParams.w);
    //#endif

        
    half3 indirectColor = IndirectLightMobile(surf, brdf, worldPos, surf.occlusion);
        
    DEBUG_PROCESS_INDIRECTLIGHT(indirectColor)
    
    Light mainLight;
  
    #if SPE && defined(DIRLIGHTMAP_COMBINED)
    mainLight = surf.ahdLight;
    #else   
         #if defined(_SHADOW_USE_CASCADE_BLEND)
         mainLight = GetMainLight(surf.shadowCoord,surf.positionWS,surf.depth,surf.shadowMask);
         #else
         mainLight= GetMainLight(surf.shadowCoord, surf.positionWS, surf.shadowMask);    
         #endif
    if (_FURSHADOW == 1)
    {
        half shadowFade = GetMainLightFurShadowFade(surf.positionWS);
        half furShadow = lerp(MainLightRealtimeFurShadow(surf.furShadowCoord), 1, shadowFade);
        mainLight.shadowAttenuation =min( furShadow,mainLight.shadowAttenuation);
    }
    half cloudsShadow = GetCloudShadowAtten(surf.positionWS);
    mainLight.shadowAttenuation = min(cloudsShadow, mainLight.shadowAttenuation);
    MixRealtimeAndBakedGI(mainLight, surf.normal, surf.bakedGI, 0);
    #endif


    uint meshRenderingLayers = GetMeshRenderingLightLayer();

    half3 directColor = DirectLightMobile(mainLight, surf, brdf,meshRenderingLayers, directAO);

    InputData input = (InputData)0;
    input.positionWS = surf.positionWS;
    input.positionCS = surf.svPostion;

    ADDITIONAL_LIGHTS_LOOP_BEGIN(input)
        directColor += DirectLightMobile(light, surf, brdf,meshRenderingLayers, directAO);
    ADDITIONAL_LIGHTS_LOOP_END

    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    directColor += surf.vertexLighting * brdf.diffuse;
#endif
        
    DEBUG_PROCESS_DIRECTLIGHT(directColor)
    return indirectColor +  directColor; 
}


inline half4 SurfaceStandardMobile(H3DSurfaceData surf, float3 worldPos)
{
    DEBUG_PROCESS_SURFACE(surf)
    half3 color = StandardLightMobile(surf, worldPos);
       
    return MixColor(color, surf);
}

  
////////////////////////////////////////////////////////////////////////////////
/// Phong lighting...
////////////////////////////////////////////////////////////////////////////////

half3 H3DLightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half3 specular, half smoothness)
    {
        float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
        half NdotH = half(saturate(dot(normal, halfVec)));
        float3 specularReflection =specular * saturate(pow(NdotH,smoothness) ) ;
        return lightColor* specularReflection;
    }

half3 H3DCalculateBlinnPhong(Light light, VertexOutput inputData, H3DSurfaceData surfaceData,H3DBRDF brdf, float directAO)
{

    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half3 lightColor = LightingLambert(attenuatedLightColor, light.direction, surfaceData.normal);
    half3 baseLightColor=lightColor;
    lightColor *= brdf.diffuse;
    half smoothness = exp2(10 * surfaceData.smoothness+1);//>2
    lightColor += H3DLightingSpecular( baseLightColor ,light.direction,surfaceData.normal,surfaceData.viewDir,brdf.specular,smoothness) ;

    lightColor *= directAO;
    
    return lightColor;
}

half3 SimpleLightMobile(H3DSurfaceData surf, VertexOutput inputData)
{
        //brdf data
        H3DBRDF brdf = InitBRDFData(surf);
        
        half2 AB = EnvBRDFApproxLazarov(saturate(brdf.perceptualRoughness), saturate(dot(surf.normal, surf.viewDir)));
        brdf.specular = brdf.specular * AB.x + AB.y;
        
        float  directAO = 1.0;
        if (_H3DSSAO == 1)
        {
            half ssao = SampleAmbientOcclusion(surf.screenPosition.xy);
    
            surf.occlusion = min(ssao, surf.occlusion);
            directAO = lerp(1.0, ssao, _AmbientOcclusionParams.w);
        }
        
    
        half3 indirectColor = IndirectLightMobile(surf, brdf, inputData.positionWS, surf.occlusion);
        
        DEBUG_PROCESS_INDIRECTLIGHT(indirectColor)
    
        Light mainLight;
        uint meshRenderingLayers = GetMeshRenderingLightLayer();

        #if SPE && defined(DIRLIGHTMAP_COMBINED)
        mainLight = surf.ahdLight;
        #else
        mainLight = GetMainLight(surf.shadowCoord);
        MixRealtimeAndBakedGI(mainLight, surf.normal, surf.bakedGI, 0);
        #endif
        
        half3 directColor=half3(0,0,0);
        if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
        {
           directColor += H3DCalculateBlinnPhong(mainLight,inputData,surf,brdf, directAO);
        }

        InputData input;
        input.positionWS = surf.positionWS;
        input.positionCS = surf.svPostion;

        ADDITIONAL_LIGHTS_LOOP_BEGIN(input)
        directColor += H3DCalculateBlinnPhong(light, inputData, surf, brdf, directAO);
        ADDITIONAL_LIGHTS_LOOP_END
          
        
        DEBUG_PROCESS_DIRECTLIGHT(directColor)
        return indirectColor+ directColor ; 
}


/**
 * \brief 简单光照模型 间接光照不变，直接光照模型修改为blin phong 模型
 * \param surf 
 * \param input 
 * \return 简单光照模型结果 + 混合雾效颜色和自发光颜色
 */
inline half4 SurfaceSimpleMobile(H3DSurfaceData surfaceData, VertexOutput input)
    {
        DEBUG_PROCESS_SURFACE(surfaceData)
        half3 color = SimpleLightMobile(surfaceData, input);
    
        return MixColor(color, surfaceData);
 
    }





#endif